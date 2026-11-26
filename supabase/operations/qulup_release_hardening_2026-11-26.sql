
-- QULUP production hardening reference script — 26 November 2026
-- Replays the three database hardening changes applied to CoolANProject.
-- Apply only to the matching QULUP schema after reviewing the release report.

begin;

-- Restrict the admin helper functions from anonymous/public invocation.
revoke execute on function public.is_admin() from anon, public;
revoke execute on function public.is_challenge_admin() from anon, public;
revoke execute on function public.qulani_is_admin() from anon, public;
revoke execute on function public.qulup_is_admin() from anon, public;

-- Consolidate reward catalogue visibility; admin write/read policies remain.
drop policy if exists "Published rewards are visible to everyone" on public.rewards;
drop policy if exists "View available rewards" on public.rewards;
drop policy if exists "View available rewards public" on public.rewards;
drop policy if exists "View available rewards authenticated" on public.rewards;
drop policy if exists "Rewards visible to users" on public.rewards;
create policy "Rewards visible to users"
on public.rewards
for select to anon, authenticated
using (is_published = true or is_available = true);

-- Business plan public and authenticated reads do not depend on anon calling
-- a staff-only helper. Staff writes are separated by action.
drop policy if exists "business plans active read" on public.qulup_business_plans;
drop policy if exists "business plans public active read" on public.qulup_business_plans;
drop policy if exists "business plans authenticated active read" on public.qulup_business_plans;
drop policy if exists "business plans admin manage" on public.qulup_business_plans;
drop policy if exists "business plans admin insert" on public.qulup_business_plans;
drop policy if exists "business plans admin update" on public.qulup_business_plans;
drop policy if exists "business plans admin delete" on public.qulup_business_plans;
create policy "business plans public active read"
on public.qulup_business_plans for select to anon
using (is_active = true);
create policy "business plans authenticated active read"
on public.qulup_business_plans for select to authenticated
using (is_active = true or public.qulup_business_is_admin());
create policy "business plans admin insert"
on public.qulup_business_plans for insert to authenticated
with check (public.qulup_business_is_admin());
create policy "business plans admin update"
on public.qulup_business_plans for update to authenticated
using (public.qulup_business_is_admin())
with check (public.qulup_business_is_admin());
create policy "business plans admin delete"
on public.qulup_business_plans for delete to authenticated
using (public.qulup_business_is_admin());

-- Payment INSERT must bind the payment to the same company and exact payable
-- amount as the referenced campaign or active subscription plan.
drop policy if exists "business payments create assigned pending"
on public.qulup_business_payments;
create policy "business payments create assigned pending"
on public.qulup_business_payments
for insert to authenticated
with check (
  public.qulup_business_can_manage(business_id)
  and status = 'pending'
  and currency = 'GEL'
  and amount_gel > 0
  and exists (
    select 1 from public.qulup_business_profiles p
    where p.id = public.qulup_business_payments.business_id
      and p.status = 'approved'
  )
  and (
    (
      purpose = 'campaign'
      and exists (
        select 1 from public.qulup_business_campaigns c
        where c.id = public.qulup_business_payments.related_id
          and c.business_id = public.qulup_business_payments.business_id
          and c.status in ('draft', 'pending_payment')
          and c.total_budget_gel = public.qulup_business_payments.amount_gel
      )
    )
    or
    (
      purpose = 'subscription'
      and exists (
        select 1
        from public.qulup_business_subscriptions s
        join public.qulup_business_plans bp on bp.id = s.plan_id
        where s.id = public.qulup_business_payments.related_id
          and s.business_id = public.qulup_business_payments.business_id
          and s.status = 'pending'
          and bp.is_active = true
          and bp.price_gel = public.qulup_business_payments.amount_gel
      )
    )
  )
);

-- Businesses can manage both task and challenge drafts. Admins can moderate
-- any campaign. Public users can view active campaigns only.
drop policy if exists "business campaigns admin delete tasks" on public.qulup_business_campaigns;
drop policy if exists "business campaigns admin insert tasks" on public.qulup_business_campaigns;
drop policy if exists "business campaigns admin update tasks" on public.qulup_business_campaigns;
drop policy if exists "business campaigns admin manage all" on public.qulup_business_campaigns;
drop policy if exists "business campaigns authenticated read active or managed" on public.qulup_business_campaigns;
drop policy if exists "business campaigns public active" on public.qulup_business_campaigns;
drop policy if exists "business campaigns create assigned draft" on public.qulup_business_campaigns;
drop policy if exists "business campaigns update assigned draft or payment" on public.qulup_business_campaigns;
drop policy if exists "business campaigns insert authorized" on public.qulup_business_campaigns;
drop policy if exists "business campaigns update authorized" on public.qulup_business_campaigns;
drop policy if exists "business campaigns delete admin" on public.qulup_business_campaigns;

create policy "business campaigns authenticated read active or managed"
on public.qulup_business_campaigns for select to authenticated
using (status = 'active' or public.qulup_business_can_manage(business_id));
create policy "business campaigns public active"
on public.qulup_business_campaigns for select to anon
using (status = 'active');
create policy "business campaigns insert authorized"
on public.qulup_business_campaigns for insert to authenticated
with check (
  public.qulup_business_is_admin()
  or (
    public.qulup_business_can_manage(business_id)
    and campaign_type in ('task', 'challenge')
    and status = 'draft'
    and exists (
      select 1 from public.qulup_business_profiles p
      where p.id = public.qulup_business_campaigns.business_id
        and p.status = 'approved'
    )
  )
);
create policy "business campaigns update authorized"
on public.qulup_business_campaigns for update to authenticated
using (
  public.qulup_business_is_admin()
  or (
    public.qulup_business_can_manage(business_id)
    and status in ('draft', 'pending_payment')
  )
)
with check (
  public.qulup_business_is_admin()
  or (
    public.qulup_business_can_manage(business_id)
    and campaign_type in ('task', 'challenge')
    and status in ('draft', 'pending_payment')
  )
);
create policy "business campaigns delete admin"
on public.qulup_business_campaigns for delete to authenticated
using (public.qulup_business_is_admin());

-- Add covering indexes to public foreign keys only where an equivalent valid
-- B-tree prefix index does not already exist.
do $$
declare
  r record;
  v_index_name text;
begin
  for r in
    select c.conrelid, c.conname, c.conkey,
           c.conrelid::regclass as table_name,
           string_agg(format('%I', a.attname), ', ' order by k.ord) as column_list
    from pg_constraint c
    join pg_namespace n on n.oid = c.connamespace
    cross join lateral unnest(c.conkey) with ordinality k(attnum, ord)
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
    where c.contype = 'f' and n.nspname = 'public'
      and not exists (
        select 1
        from pg_index i
        join pg_class ix on ix.oid = i.indexrelid
        join pg_am am on am.oid = ix.relam
        where i.indrelid = c.conrelid
          and i.indisvalid and i.indisready
          and am.amname = 'btree'
          and i.indnkeyatts >= cardinality(c.conkey)
          and (
            select array_agg(k2.attnum order by k2.ord)
            from unnest(i.indkey) with ordinality k2(attnum, ord)
            where k2.ord <= cardinality(c.conkey)
          ) = c.conkey
      )
    group by c.conrelid, c.conname, c.conkey
  loop
    v_index_name := 'idx_fk_' ||
      substr(md5(r.conrelid::text || ':' || r.conkey::text), 1, 16);
    execute format('create index if not exists %I on %s (%s)',
                   v_index_name, r.table_name, r.column_list);
  end loop;
end $$;

-- Remove duplicate secondary indexes; equivalent primary/unique indexes remain.
drop index if exists public.moderator_users_user_id_uidx;
drop index if exists public.points_ledger_business_submission_once;

commit;
