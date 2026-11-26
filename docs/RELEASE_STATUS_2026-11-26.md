# QULUP — Release audit and progress (26 November 2026)

## Executive status

**Database hardening is applied and the V82+ desktop Release Candidate has been updated. Full commercial Production launch remains NO-GO** until payment, hosting/domain, security review and real browser acceptance work is complete. NEXORA is explicitly deferred and is not part of the QULUP launch scope.

## Source and frontend changes

- The latest Library source snapshot is `index(1).html` (25 November 2026, about 8.47 MB), containing the V82 desktop baseline and refinements through V87.
- GitHub `main/index.html` is an older ~610 KB version; it has not been overwritten. The latest 8.47 MB Release Candidate is included in the downloadable v2 release package. GitHub PR #1 contains SQL and documentation, not the full large HTML file.
- The latest source already had active partner-campaign listing, photo/text submission, private proof storage, admin review and personal-submission fetch logic.
- The Release Candidate adds a submit action for both task and branded-challenge campaigns, participant-limit display, visible personal campaign-submission history, cleanup of unlinked proof uploads after failed submission, and authenticated-only campaign view/start event tracking.
- V90 frontend hardening: campaign view/start analytics now skip anonymous sessions; the client no longer attempts a duplicate `submit` event (the database trigger is authoritative); failed submissions remove only the newly uploaded, still-unlinked proof file. Password-reset callbacks (`PASSWORD_RECOVERY`) now open a dedicated recovery mode so users can set a new password without the old password; normal password changes still require current-password verification. New registrations and new/updated passwords require at least 8 characters; sign-in for existing accounts still accepts the previous 6-character minimum.
- V90 verification: 12/12 inline JavaScript blocks pass `node --check`; the parsed document contains 412 IDs with zero duplicates; no Service Role/secret key literal and no NEXORA reference were found. Isolated auth-flow tests passed for the `PASSWORD_RECOVERY` callback, password recovery without the old password, normal password change with current-password verification, and the 8-character new-password guards (7-character signup blocked; existing 6-character sign-in still reaches Supabase).
- Mobile-specific styling is unchanged.

## Supabase work completed

Project: `CoolANProject` (`qnqncedovahezxfnlueh`).

Earlier release hardening:
1. Revoked anonymous/public EXECUTE on `is_admin`, `is_challenge_admin`, `qulani_is_admin`, and `qulup_is_admin`; authenticated use remains.
2. Corrected business payment binding to ensure business ID, related campaign/subscription ID, amount and GEL currency match.
3. Aligned task and branded-challenge draft RLS permissions.
4. Added indexes covering all 47 previously uncovered public foreign keys; post-check: zero unindexed foreign keys.
5. Removed two duplicate indexes and consolidated selected business/reward policies.

Business campaign submission hardening:
1. Anonymous access to campaign-event INSERT and submission table privileges were removed. Authenticated users retain only SELECT/INSERT for submissions and SELECT/INSERT for events; users cannot UPDATE or DELETE their submissions or events.
2. A database BEFORE INSERT trigger validates the authenticated user, active campaign, type, end date, description length, proof-file owner/path, duplicate live submission and participant limit.
3. The campaign row is locked while checking the participant cap, preventing concurrent submissions from exceeding the cap.
4. An AFTER INSERT trigger records the submit event in the same database transaction. The client cannot forge submit events directly.
5. Users may remove only their own unlinked proof upload; linked evidence cannot be deleted by its owner.
6. The admin review RPC uses the QULUP superadmin/admin_users registry, has an empty search_path, rejects invalid statuses/oversized notes, and awards points only once.

Applied migrations:
- `20261126060739 qulup_release_hardening_20261126`
- `20261126060906 qulup_fk_index_cleanup_20261126`
- `20261126061006 qulup_release_policy_consolidation_20261126`
- `20261126073056 qulup_business_submission_guard_events_20261126`
- `20261126073612 qulup_business_review_admin_membership_20261126`

## Verification results

- JavaScript syntax: 12/12 non-empty inline scripts passed `node --check`.
- HTML parser: 412 IDs found, zero duplicates.
- Frontend runtime smoke tests: history rendering, XSS escaping, authenticated tracking, anonymous tracking suppression and submission insert passed.
- Database transaction tests: automatic submit-event generation passed; duplicate live submissions were rejected; participant-limit overrun was rejected; non-admin review and client-forged submit event were rejected. All test transactions were rolled back.
- Live data after tests: 1 submission, 10 campaign events, 2 campaigns, 2 business profiles — unchanged.
- Security Advisor: 3 RLS-enabled game tables have no direct policies (kept server-RPC-only); 35 authenticated-callable SECURITY DEFINER functions remain for object-by-object review; leaked-password protection remains unavailable because the Supabase organization is on the Free plan; Supabase makes this control available on Pro and above.
- Performance Advisor after policy cleanup: 0 auth RLS init-plan warnings (47 policies optimized), 55 multiple-permissive-policy warnings remain, and 59 unused-index informational notices remain.
- Health Advisor: no lints.
- Exact duplicate policy cleanup: 6 groups / 7 redundant permissive policies removed; one further DELETE rule covered by an identical FOR ALL policy was removed. Public policy count reduced from 154 to 146 with effective access predicates unchanged.
- Auth RLS optimization: 47 policies now wrap request-constant `auth.uid()` values in scalar subqueries; Advisor reports 0 auth RLS init-plan warnings.
- The migration history includes a no-op entry `20261126092459 qulup_rls_auth_uid_initplan_optimization_2026_11_26` (empty query, no schema change), followed by the actual 47-policy optimization migration `20261126092512 qulup_rls_auth_uid_initplan_optimization_apply_2026_11_26`.
- SECURITY DEFINER hardening: 20 additional functions now use an empty `search_path`; their application relations were verified as schema-qualified. The remaining internal event-trigger function is restricted to `pg_catalog`.
- SECURITY DEFINER privilege check: 0 of 50 functions are executable by `anon`; 35 remain intentionally executable by `authenticated` for app RPC/RLS helpers and remain individually reviewable.
- Edge Functions deployed: 0.
- Headless Chromium did not complete page loading within the test window in repeated attempts; no visual/browser E2E pass is claimed.

## Current live data snapshot

| Item | Count / state |
|---|---:|
| Public tables | 54 (RLS enabled) |
| Business profiles | 2 |
| Business campaigns | 2 (one task, one challenge; both active) |
| Business subscriptions | 0 |
| Business payment requests | 1 |
| Business campaign events | 10 |
| Business campaign submissions | 1 |
| Game catalog | 1 (QULUP LEVEL) |
| Edge Functions | 0 |

## Remaining production blockers

1. Real payment processing or verified bank-transfer reconciliation is not connected; the business portal currently creates pending requests only.
2. NEXORA is explicitly deferred and is not part of the QULUP launch scope.
3. Canonical domain, DNS, SSL, hosting and Supabase Auth redirect settings were not verified or deployed.
4. Plan prices (99/249/499 GEL), `challenge_limit=0` and 15% fee estimate require commercial approval before selling subscriptions.
5. Full visual QA, sign-in/role-based testing, proof upload with real user accounts, and production payment end-to-end tests remain outstanding.
6. The V82+ V90 Release Candidate is not yet synchronized to GitHub `main`; it is available as a separate tested HTML artifact. Synchronize only after browser acceptance.
7. Review the remaining authenticated-callable SECURITY DEFINER functions individually; do not revoke grants indiscriminately. Leaked-password protection requires a Pro-plan upgrade; do not upgrade without explicit approval. Continue the remaining RLS/performance findings with regression tests.

NEXORA is intentionally deferred until after QULUP is stable. It is not a blocker for launching QULUP without NEXORA.

## Release decision

**NO-GO for public Full Commercial Launch at this checkpoint.** Database protections and campaign submission are improved and transaction-tested, and the V90 frontend fixes pass static/runtime smoke tests. Do not activate paid business packages until payment reconciliation, hosting/Auth configuration, remaining security review and signed-in browser acceptance are complete. NEXORA remains out of scope for this release.

## GitHub

Draft PR #1: https://github.com/maisuradzee/qulani-/pull/1
Branch: `codex/qulup-release-hardening-2026-11-26`


## Cloudflare deployment diagnosis (26 November 2026)

- GitHub PR #1 has repeated Cloudflare Preview Build failures (the PR bot listed failed builds for commits `683260d`, `65a3d2e`, `a148b4d`, `716111f`, `c7261ac`, and `276c4ab`).
- The current `main` root contains only `index.html` (~661 KB), `Qulani_V68_partner_rls_fix-1.html` (~628 KB), `test.html` (~628 KB), and a 43-byte README. It has no `package.json`, lockfile, `wrangler.toml`, `wrangler.jsonc`, or build script.
- PR #1 changes only documentation and SQL files; it does not change the root HTML entrypoint or add V90 to GitHub. The V90 candidate is an 8,472,374-byte local artifact, separately validated (12 inline JS blocks pass `node --check`, 412 unique IDs).
- Cloudflare dashboard build logs are behind the authenticated dashboard and are not accessible through the connected GitHub/Supabase integrations. Therefore the exact build error is not yet confirmed. A missing build manifest/configuration is a plausible cause only if the Cloudflare service expects an npm/Wrangler build; do not assume this without the first failing log line.
- Do not add a speculative build script, deploy V90, or change the Cloudflare production service until its build command, output directory/asset mode, and first failing log line are confirmed.
- Required next diagnostic: open the newest failed build in Cloudflare Dashboard → Workers & Pages → qulani → Builds and capture the first error plus the configured Build command and Deploy command. Then add the matching minimal config and run a preview-only deployment.
