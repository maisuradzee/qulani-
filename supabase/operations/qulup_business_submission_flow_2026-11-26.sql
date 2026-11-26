-- QULUP Business Campaign Submission Hardening — 26 November 2026
-- Final replay/reference script for the two applied production migrations.
-- No existing campaign, submission, profile, or points rows are deleted.

begin;

revoke all on table public.qulup_business_campaign_submissions from anon, public, authenticated;
grant select, insert on table public.qulup_business_campaign_submissions to authenticated;

revoke all on table public.qulup_business_campaign_events from anon, public, authenticated;
grant select, insert on table public.qulup_business_campaign_events to authenticated;

drop policy if exists "business events anonymous campaign views" on public.qulup_business_campaign_events;
drop policy if exists "business events user activity" on public.qulup_business_campaign_events;
drop policy if exists "business events authenticated view and start" on public.qulup_business_campaign_events;
create policy "business events authenticated view and start"
on public.qulup_business_campaign_events
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and event_type in ('view', 'start')
  and exists (
    select 1 from public.qulup_business_campaigns c
    where c.id = campaign_id
      and c.status = 'active'
      and (c.ends_at is null or c.ends_at >= current_date)
  )
);

create or replace function public.qbc_guard_business_submission()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_campaign_status text;
  v_campaign_type text;
  v_participant_limit integer;
  v_ends_at date;
  v_participant_count integer;
  v_proof_owned boolean;
begin
  if v_user_id is null or new.user_id is distinct from v_user_id then
    raise exception 'Authentication required';
  end if;
  if new.campaign_id is null then
    raise exception 'Campaign is required';
  end if;

  new.status := 'pending';
  new.submitted_at := now();
  new.reviewed_at := null;
  new.reviewed_by := null;
  new.review_note := null;
  new.awarded_points := 0;
  new.awarded_at := null;

  new.description := nullif(btrim(new.description), '');
  if new.description is not null and char_length(new.description) > 1500 then
    raise exception 'Submission description is too long';
  end if;
  if new.description is null and new.proof_path is null then
    raise exception 'A description or proof photo is required';
  end if;

  if new.proof_path is not null then
    if char_length(new.proof_path) > 1024
       or split_part(new.proof_path, '/', 1) <> v_user_id::text
       or new.proof_path !~ ('^' || v_user_id::text || '/[A-Za-z0-9._/-]+$')
       or new.proof_path ~ '(^|/)\.\.?(/|$)' then
      raise exception 'Invalid proof file path';
    end if;

    select exists (
      select 1 from storage.objects o
      where o.bucket_id = 'business-proofs'
        and o.name = new.proof_path
        and (o.owner = v_user_id or o.owner_id = v_user_id::text)
    ) into v_proof_owned;

    if not v_proof_owned then
      raise exception 'Proof file was not uploaded by this user';
    end if;

    if exists (
      select 1 from public.qulup_business_campaign_submissions s
      where s.proof_path = new.proof_path
    ) then
      raise exception 'This proof file has already been submitted';
    end if;
  end if;

  select c.status, c.campaign_type, c.participant_limit, c.ends_at
  into v_campaign_status, v_campaign_type, v_participant_limit, v_ends_at
  from public.qulup_business_campaigns c
  where c.id = new.campaign_id
  for update;

  if not found then
    raise exception 'Campaign not found';
  end if;
  if v_campaign_status <> 'active'
     or (v_ends_at is not null and v_ends_at < current_date) then
    raise exception 'Campaign is not accepting submissions';
  end if;
  if v_campaign_type not in ('task', 'challenge') then
    raise exception 'Unsupported campaign type';
  end if;
  if v_participant_limit is null or v_participant_limit < 1 then
    raise exception 'Campaign participant limit is invalid';
  end if;

  if exists (
    select 1 from public.qulup_business_campaign_submissions s
    where s.campaign_id = new.campaign_id
      and s.user_id = v_user_id
      and s.status in ('pending', 'approved')
  ) then
    raise exception 'You already have an active submission for this campaign';
  end if;

  select count(distinct s.user_id)::integer
  into v_participant_count
  from public.qulup_business_campaign_submissions s
  where s.campaign_id = new.campaign_id
    and s.status in ('pending', 'approved');

  if v_participant_count >= v_participant_limit then
    raise exception 'Campaign participant limit has been reached';
  end if;

  return new;
end;
$function$;

revoke all on function public.qbc_guard_business_submission() from public, anon, authenticated;
drop trigger if exists qbc_guard_business_submission on public.qulup_business_campaign_submissions;
create trigger qbc_guard_business_submission
before insert on public.qulup_business_campaign_submissions
for each row execute function public.qbc_guard_business_submission();

create or replace function public.qbc_log_business_submission_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.qulup_business_campaign_events
    (campaign_id, user_id, event_type)
  values
    (new.campaign_id, new.user_id, 'submit')
  on conflict (campaign_id, user_id, event_type)
    where user_id is not null
    do nothing;
  return null;
end;
$function$;

revoke all on function public.qbc_log_business_submission_event() from public, anon, authenticated;
drop trigger if exists qbc_log_business_submission_event on public.qulup_business_campaign_submissions;
create trigger qbc_log_business_submission_event
after insert on public.qulup_business_campaign_submissions
for each row execute function public.qbc_log_business_submission_event();

drop policy if exists "qbc_proofs_delete_unlinked_own" on storage.objects;
create policy "qbc_proofs_delete_unlinked_own"
on storage.objects
for delete to authenticated
using (
  bucket_id = 'business-proofs'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and not exists (
    select 1 from public.qulup_business_campaign_submissions s
    where s.proof_path = objects.name
  )
);

create or replace function public.qulup_business_review_submission(
  p_submission_id uuid,
  p_status text,
  p_review_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_sub public.qulup_business_campaign_submissions%rowtype;
  v_points integer;
begin
  if not public.qulup_business_is_superadmin() then
    raise exception 'Only a QULUP administrator can review business campaign submissions';
  end if;
  if p_submission_id is null or p_status is null
     or p_status not in ('approved', 'rejected') then
    raise exception 'Invalid review request';
  end if;
  if p_review_note is not null and char_length(p_review_note) > 1000 then
    raise exception 'Review note is too long';
  end if;

  select * into v_sub
  from public.qulup_business_campaign_submissions
  where id = p_submission_id
  for update;

  if not found then
    raise exception 'Submission not found';
  end if;
  if v_sub.status <> 'pending' then
    raise exception 'Submission has already been reviewed';
  end if;

  if p_status = 'approved' then
    select greatest(coalesce(c.reward_points, 0), 0)
    into v_points
    from public.qulup_business_campaigns c
    where c.id = v_sub.campaign_id;

    if v_points is null then
      raise exception 'Campaign not found';
    end if;

    update public.qulup_business_campaign_submissions
    set status = 'approved',
        reviewed_at = now(),
        reviewed_by = auth.uid(),
        review_note = nullif(btrim(p_review_note), ''),
        awarded_points = v_points,
        awarded_at = case when v_points > 0 then now() else null end
    where id = p_submission_id;

    if v_points > 0 then
      insert into public.points_ledger
        (user_id, submission_id, reason, points_delta)
      values
        (v_sub.user_id, p_submission_id, 'ბიზნეს-კამპანიის შესრულება', v_points);
    end if;
  else
    update public.qulup_business_campaign_submissions
    set status = 'rejected',
        reviewed_at = now(),
        reviewed_by = auth.uid(),
        review_note = nullif(btrim(p_review_note), '')
    where id = p_submission_id;
  end if;
end;
$function$;

revoke all on function public.qulup_business_review_submission(uuid, text, text) from public, anon;
grant execute on function public.qulup_business_review_submission(uuid, text, text) to authenticated;

commit;
