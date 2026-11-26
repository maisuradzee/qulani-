-- Follow-up hardening for the business campaign review RPC.
-- Keeps review authorization aligned with the existing QULUP superadmin/admin_users registry.

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

revoke all on function public.qulup_business_review_submission(uuid, text, text)
  from public, anon;
grant execute on function public.qulup_business_review_submission(uuid, text, text)
  to authenticated;
