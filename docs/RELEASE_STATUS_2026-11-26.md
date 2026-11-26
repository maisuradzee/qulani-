# QULUP — Release audit and status (26 November 2026)

## Executive status

**Database hardening has been applied and verified. Full production launch is NOT cleared.** The website, business portal, QULUP game module and Supabase project were inspected. Three production migrations were applied. No user data was deleted or rewritten.

## Verified source snapshot

- Latest website source found in the user's Library: `index(1).html`, dated 25 November 2026; source size 8,469,925 bytes.
- Desktop styles include V82 baseline and later desktop refinements through V87. Mobile styling was not changed.
- Node.js syntax checks passed for 12 main-page scripts and the embedded business-portal script.
- Static checks found no Service Role key in browser code; only a publishable Supabase key is present.
- Main website has a QULUP LEVEL game iframe and a whitelisted RPC bridge (`qulup_game_start_quiz`, `qulup_game_submit_quiz_answer`) plus server-backed level progress.
- The main website contains no NEXORA route or reference (`nexora` case-insensitive scan: 0 matches). GitHub `main/index.html` is an older ~661 KB version and is materially behind the Library snapshot. The 8.47 MB source was not copied over `main` because it needs a controlled sync and visual acceptance tests first.
- The business portal exists inside the latest HTML as an embedded document. The separate tracking helper exists as a Library asset but is not included/called by the current main page.

## NEXORA integration assessment — corrected after locating its source files

The separate project assets exist:

- `nexora.html` — standalone 2D browser prototype with Slots, Flight, Cards, World, Arena and Championship demo screens.
- `NEXORA_Final_Boss_Demo.html` — separate Final Boss Challenge playable prototype.
- `MASTER_SPEC_KA.md` — master gameplay and technical specification.

The master specification explicitly states that its current version is a 2D prototype, not final Unreal Engine 5 production; no server or actual QULUP integration is implemented; and the wallet is a local simulation. Both HTML demos use local `credits` / `demoWallet` state, with no Supabase client, `qClient`, QULUP RPC calls, or remote API calls. JavaScript syntax checks passed for their 4 script blocks.

**Therefore NEXORA is an existing prototype/specification, but it is not integrated with QULUP authentication or the real QULUP Points ledger.** It must not be wired to live points by accepting client-reported wins or balances. Next implementation needs server-authoritative game sessions, verified battle/round outcomes, nonce/idempotency, atomic ledger writes, audit log and anti-cheat validation before enabling cashout/points credit. Unreal Engine 5 production and device performance tests are also not complete. See `docs/NEXORA_QULUP_Integration_Handoff.md`.

## Supabase changes applied

Project: `CoolANProject` (`qnqncedovahezxfnlueh`).

1. Revoked `anon` and `PUBLIC` execute rights from `is_admin`, `is_challenge_admin`, `qulani_is_admin`, and `qulup_is_admin`; authenticated execution remains available for existing RLS usage.
2. Split reward and business-plan public reads from staff-only helper calls.
3. Fixed business payment validation so a payment must match the same business as the related campaign/subscription and exact payable amount (campaign total or active plan price); currency is GEL and amount must be positive.
4. Aligned campaign RLS with the portal: company managers can create/edit task and branded-challenge drafts; active campaigns are public-read; staff alone can moderate/delete campaigns.
5. Added covering B-tree indexes for all 47 foreign keys reported by the advisor; post-check: zero unindexed public foreign keys.
6. Removed two identical secondary indexes while preserving primary-key/unique equivalents.
7. Consolidated key business/reward policies to reduce overlapping permissions.

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
| Game catalog | 1 (`QULUP LEVEL`, active) |
| Edge Functions | 0 deployed |

## Verification

- Security advisor: anonymous execute warnings for the four admin helpers cleared.
- Health advisor: no lints.
- Foreign-key advisor check: 0 unindexed public foreign keys.
- Two duplicate indexes removed.
- RLS enabled on every public table.
- Three game tables intentionally have no direct policies: game questions, reward rules and sessions remain server-RPC-only. Quiz start/answer RPCs validate the signed-in user and a session nonce.
- JavaScript syntax: 12 main-site scripts + embedded business portal + 1 NEXORA script + 3 Final Boss scripts passed `node --check`.
- HTML parser check on the main page found no duplicate IDs.
- Browser headless launch timed out; no claim is made that real browser, signed-in E2E, visual, or mobile acceptance tests passed.

## Remaining findings and release blockers

- Security advisor still reports 35 authenticated-callable `SECURITY DEFINER` functions. They must be individually reviewed for internal authorization before any further grant changes; do not revoke them indiscriminately.
- Supabase leaked-password protection is not enabled.
- Performance advisor still reports 52 auth RLS init-plan warnings and 62 multiple-permissive-policy warnings. These require controlled policy optimization and regression tests.
- Advisor also reports 60 currently unused indexes (INFO); do not drop them solely because workload has not used them yet.
- Real payments are not processed. The portal writes pending requests only; no payment gateway or verified bank-transfer reconciliation is connected. Do not accept money through this flow yet.
- Business portal plan prices (99/249/499 GEL) and 15% service-fee estimate are provisional in the README. All three plans currently have `challenge_limit = 0`; no subscriptions exist. Approve final prices and entitlements before sales.
- Business campaign event helper is a separate asset and is not wired into the main website. End-user campaign discovery, participation/submission and end-to-end analytics are incomplete.
- NEXORA exists only as separate local demos and specification. No QULUP account integration, server-backed game session or ledger connection exists.
- Hosting/provider, canonical domain, DNS, SSL and Auth redirect configuration were not verified; no deployment was performed.
- Mobile styling was intentionally left unchanged pending desktop acceptance.
- GitHub `main` remains stale; latest V82+ website source is preserved in the release package but not pushed to `main`.

## Release decision

**NO-GO for public full launch.** The database hardening is live. Before release, complete: source sync + browser acceptance; business campaign/event flow; selected payment provider and verified settlement; NEXORA server-authoritative integration; plan/pricing approval; Auth password protection; remaining function/RLS review; and hosting/domain deployment.

## GitHub work

- Branch: `codex/qulup-release-hardening-2026-11-26`
- Draft PR: https://github.com/maisuradzee/qulani-/pull/1
- PR adds the release audit and a replay/reference SQL script; it deliberately does not merge or overwrite the older `main/index.html`.
