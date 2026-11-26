# QULUP Business Campaign Flow — implementation record (26 November 2026)

## Release Candidate frontend

- Both task and branded-challenge cards now expose the proof-submission action.
- Campaign cards display the configured participant cap.
- The History page shows campaign submission state, review note and awarded QULUP points.
- Proof uploads are removed when submission creation fails and remain protected after being linked.
- View/start events are written only for authenticated users; duplicate events are ignored by the database unique index.
- Submit events are emitted by the database AFTER INSERT trigger, not by a client-side event call.

## Database enforcement

The BEFORE INSERT trigger `qbc_guard_business_submission` enforces:
- authenticated user owns the submission;
- campaign is active, not expired, and is task/challenge;
- either a non-empty description or a proof image is supplied;
- description max length is 1,500 characters;
- proof path is within the submitting user's folder and storage owner matches the session;
- no existing pending/approved submission for the same user/campaign;
- campaign participant limit is not exceeded.

The campaign row is locked before counting pending/approved distinct participants, making the limit check safe under concurrency.

The AFTER INSERT trigger `qbc_log_business_submission_event` records one submit event atomically. Normal clients may only insert view/start events; anonymous event insertion is disabled.

## Tests

- 12/12 embedded JavaScript blocks pass Node syntax check.
- 412 HTML IDs, no duplicates.
- Client smoke tests passed for status history rendering, escaping, authenticated events, anonymous event suppression and submission payload.
- SQL smoke tests passed for successful submission, atomic submit-event write, duplicate rejection, participant-limit rejection, non-admin review rejection and client submit-event spoof rejection. Test transactions rolled back.

## Release caveat

The HTML candidate has not been deployed. Headless Chromium timed out while loading the large local page; real browser and signed-in end-to-end tests remain required.
