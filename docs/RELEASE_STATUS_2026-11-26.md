# QULUP — Release audit and status (26 November 2026)

## Executive status

**Release hardening applied to Supabase; full production launch is not yet cleared.** The current source snapshot and database were inspected. Three production migrations were applied and verified. No user data was deleted or rewritten.

## Verified source snapshot

- The newest available website source is the Library file `index(1).html`, dated 25 November 2026, 8,469,925 bytes.
- It contains desktop styling markers through V87, including V82 layout baseline and later desktop refinements V83/V86/V87.
- Node.js syntax checks passed for 12 main-page inline scripts and the embedded business-portal script.
- Static scan found no Supabase Service Role key. The frontend contains a Supabase publishable key only.
- The source snapshot does not contain a NEXORA integration marker or the campaign event bridge.
- GitHub `main` is stale: its `index.html` is about 661 KB and is materially older than the 8.47 MB Library snapshot. The newest source has not been synchronized to `main`.

## Supabase changes applied

Project: `CoolANProject` (`qnqncedovahezxfnlueh`).

1. Revoked `anon` and `PUBLIC` execute rights from `is_admin`, `is_challenge_admin`, `qulani_is_admin`, and `qulup_is_admin`; authenticated execution remains available for existing RLS usage.
2. Split reward and business-plan public reads from staff-only helper calls.
3. Fixed business payment INSERT validation so a payment must match the same business as the related campaign/subscription and the exact campaign total or active plan price; currency is restricted to GEL and amount must be positive.
4. Aligned campaign RLS with the portal: company managers can create/edit task and branded-challenge drafts; public users can read active campaigns; only staff can moderate or delete campaigns.
5. Added covering B-tree indexes for all 47 foreign keys reported by the advisor (post-check: zero unindexed public foreign keys).
6. Removed two duplicate indexes while preserving the primary-key/unique indexes.

Applied migration records:

- `20261126060739 qulup_release_hardening_20261126`
- `20261126060906 qulup_fk_index_cleanup_20261126`
- `20261126061006 qulup_release_policy_consolidation_20261126`

## Current live data snapshot

| Item | Count / state |
|---|---:|
| Public tables | 54 (RLS enabled on all) |
| Business profiles | 2 |
| Business campaigns | 2 (one task, one challenge; both active) |
| Business subscriptions | 0 |
| Business payment requests | 1 |
| Business campaign events | 10 |
| Business campaign submissions | 1 |
| Games in catalog | 1 (`QULUP LEVEL`, active) |

## Verification

- Security advisor: anonymous execute warnings for the four admin helpers cleared.
- Health advisor: no lints.
- Foreign-key advisor check: 0 unindexed public foreign keys.
- Two duplicate indexes removed.
- RLS is enabled on every public table.
- Three game tables intentionally have no direct RLS policies: question bank, reward rules, and game sessions remain server-RPC-only. The quiz start/answer RPCs validate the signed-in user and session nonce.
- Remaining security advisor findings: 35 authenticated-executable SECURITY DEFINER functions (many are app RPCs with internal authorization checks; do not revoke indiscriminately), and leaked-password protection is not enabled.
- Remaining performance advisor findings: 52 auth RLS init-plan warnings and 62 multiple-permissive-policy warnings. These are follow-up optimization/hardening work, not cleared by the migrations above.
- The performance advisor lists 60 currently unused indexes; most newly-added FK indexes have not yet accumulated query workload. They were added for FK lookup and parent-row update/delete support.

## Not yet production-ready — external/product dependencies

1. **Real payments:** the portal only creates a pending payment request. No payment gateway or verified bank-transfer reconciliation is connected. No Edge Functions are deployed. Do not accept money through this flow yet.
2. **Business campaign user flow:** the business portal can manage campaigns and read aggregate metrics, but the main end-user app does not yet expose business-campaign discovery/submission and does not call the campaign event bridge. The current event count is not proof of a complete live funnel.
3. **NEXORA:** not present in the current frontend source or Supabase game catalog. The catalog currently contains only QULUP LEVEL. NEXORA must be integrated as a separate game module/API before this item can be marked done.
4. **Commercial settings:** Start/Business/Premium plans are active at 99/249/499 GEL, but all three currently have `challenge_limit = 0` and there are no active subscriptions. The portal README labels the proposed price points and 15% service-fee estimate as provisional. Approve final pricing/entitlements before selling plans.
5. **Hosting/domain:** the target production domain and current hosting deployment were not available through the connected GitHub/Supabase tools. No deployment was performed.
6. **Browser QA:** syntax checks passed, but real-browser responsive, sign-in, role-based business flows, and payment end-to-end tests have not run. Mobile styles were not changed.

## Release decision

**NO-GO for public full launch at this moment.** Database hardening is applied. Before production release, complete the payment provider, end-user campaign/event pipeline, NEXORA module, plan/pricing approval, hosting/domain deployment and browser acceptance tests.

## Files and branch

- The latest HTML snapshot remains in the user's Library as `index(1).html`; this PR does not overwrite the older `main/index.html`.
- The accompanying SQL file is an operational replay/reference script for the three applied database changes.
- Work branch: `codex/qulup-release-hardening-2026-11-26`.