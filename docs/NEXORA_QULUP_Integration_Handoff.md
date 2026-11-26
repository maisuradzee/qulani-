# NEXORA ↔ QULUP — integration handoff (26 November 2026)

## Verified starting point

The QULUP main site integrates only the `QULUP LEVEL` game through a same-origin iframe bridge. Its parent exposes a narrow RPC allowlist containing `qulup_game_start_quiz` and `qulup_game_submit_quiz_answer`, and reads level progress from Supabase. The production `qulup_games` catalog currently contains only `QULUP LEVEL`.

The NEXORA assets are separate standalone HTML prototypes. Both contain browser-local balances (`credits` / `demoWallet`) and have no Supabase client, QULUP auth session, RPC, or remote API calls. The Final Boss specification states that server-authoritative gameplay, QULUP ledger integration, anti-cheat and atomic/idempotent point transactions are production requirements, while the current wallet is a local demo.

## Safe implementation boundary

Do not connect the NEXORA demo's client-side balance or a client-reported victory directly to `points_ledger`. Do not accept cashout or reward amounts from browser input.

## Required implementation sequence

1. Keep the current demos in demo mode and label their balances as local-only.
2. Design a server-owned NEXORA session model: authenticated user, game/mode, session ID, issued nonce, state, expiry, server-owned seed/RNG state, stake/points reservation if applicable, and final result.
3. Implement server-side state transitions for each enabled mode. For Final Boss, validate HP, stamina, attacks, boss state, victory, multiplier, and outcome on the server; client sends only player actions.
4. Credit QULUP points only from a trusted server transaction, with one idempotency key per completed session and atomic ledger update + audit event.
5. Add abuse limits, expiry, replay protection, integrity logs, and role-aware authorization tests.
6. Add NEXORA as a catalog entry only once a production-ready mode and server APIs exist. Keep local demo games visually separate from live balance.
7. Run tests for unauthorized users, cross-user session IDs, invalid/replayed nonce, repeated cashout, forged victory, negative/oversized stakes, simultaneous requests, interrupted network, and ledger balance consistency.
8. Only then expose NEXORA under the shared QULUP account and publish it to users.

## Status

**Prototype preserved; production integration not performed.** This is intentional: the current prototype does not provide server-authoritative outcome data and cannot safely award real QULUP points.
