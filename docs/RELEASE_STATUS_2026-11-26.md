# QULUP — Release audit and progress (26 November 2026)

## Executive status

**Database hardening is applied. A tested Release Candidate has been prepared for the website. Full Production launch remains NO-GO** until payment, NEXORA, hosting/domain and real browser acceptance work is complete.

## Source and frontend changes

- The latest Library source snapshot is `index(1).html` (25 November 2026, about 8.47 MB), containing the V82 desktop baseline and refinements through V87.
- The GitHub `main/index.html` is an older ~610 KB version; it has not been overwritten. The updated 8.47 MB Release Candidate is included in the attached release package. GitHub PR #1 contains the SQL and documentation, not the full large HTML file.
- The existing latest source already had active partner-campaign listing, photo/text submission, private proof storage, admin review and personal-submission fetch logic. The review corrected the previous audit wording.
- The Release Candidate adds a submit action for both task and branded-challenge campaigns, participant-limit display, a visible personal campaign-submission history, cleanup of unlinked proof uploads after failed submission, and authenticated-only campaign view/start event tracking.
- The candidate keeps mobile-specific styling unchanged.

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
4. An AFTER INSERT trigger records the submit event in the same database transaction. The client can no longer forge submit events directly.
5. Users may remove only their own unlinked proof upload; linked evidence cannot be deleted by its owner.
6. The admin review RPC uses the same QULUP superadmin/admin_users registry as the rest of the platform, has a fixed empty search_path, rejects invalid statuses/oversized notes, and awards points only once.

Applied migrations:
- `20261126060739 qulup_release_hardening_20261126`
- `20261126060906 qulup_fk_index_cleanup_20261126`
- `20261126061006 qulup_release_policy_consolidation_20261126`
- `20261126073056 qulup_business_submission_guard_events_20261126`
- The follow-up admin membership review function update was also applied after the 07:30 migration.

## Verification results

- JavaScript syntax: 12/12 non-empty inline scripts passed `node --check`.
- HTML IDs: 412 found, zero duplicates.
- Frontend runtime smoke tests: history rendering, XSS escaping, authenticated tracking, anonymous tracking suppression and submission insert all passed.
- Database transaction tests: automatic submit-event generation passed; duplicate live submissions were rejected; participant-limit overrun was rejected; non-admin review and client-forged submit event were rejected. All test transactions were rolled back.
- Live data after tests: 1 submission, 10 campaign events, 2 campaigns, 2 business profiles — unchanged.
- Security Advisor: 3 RLS-enabled game tables have no direct policies (kept server-RPC-only); 35 authenticated-callable SECURITY DEFINER functions remain for object-by-object review; leaked-password protection remains disabled.
- Performance Advisor: 51 auth RLS init-plan warnings and 62 multiple-permissive-policy warnings remain; 60 unused-index informational notices remain.
- Health Advisor: no lints.
- Edge Functions deployed: 0.
- Headless Chromium did not complete page loading within the test window; no visual/browser E2E pass is claimed.

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
2. NEXORA remains a separate local demo/prototype and spec; its browser-local credits are not connected to QULUP auth or the points ledger. Server-authoritative game sessions and atomic/idempotent ledger settlement are required before enabling it.
3. Canonical domain, DNS, SSL, hosting and Supabase Auth redirect settings were not verified or deployed.
4. Plan prices (99/249/499 GEL), `challenge_limit=0` and 15% fee estimate require commercial approval before selling subscriptions.
5. Full visual QA, sign-in/role-based testing, proof upload with real user accounts, and production payment end-to-end tests remain outstanding.
6. The full V82+ Release Candidate is not yet synchronized to GitHub `main`; it is supplied as a separate file in the release package.

## Release decision

**NO-GO for public Full Launch.** Database protections and the campaign submission flow are improved and transaction-tested. Do not accept payments or award NEXORA points until the remaining server/payment/hosting and acceptance-test work is complete.

## GitHub

Draft PR #1: https://github.com/maisuradzee/qulani-/pull/1
Branch: `codex/qulup-release-hardening-2026-11-26`
