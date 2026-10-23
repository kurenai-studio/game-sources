# Storage, Error Reporting, and Timers

Storage trust, error reporting, and which timers the rules cover.

Status and provenance are recorded in `DECISIONS.md`, row D23. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests.

Baseline: D16 (`docs/phase-1-state-decision.md`, SHA-256 0ca7916f67e1b6a2e784272af15732b018b41ed70f3ec0fe05ceb72a5dcc0bad), whose section 9 left the meaning of "timer" for SAF-4 open, the R2 to R5 decision (`docs/phase-1-r2-r5-decision.md`, D21, SHA-256 2d2de112e371b8b23094652bcb8c991d8d2c6097575a4c61c059a21292b93ed8), and the fault reporting and timer trust decision (`docs/phase-1-fault-timer-decision.md` (deleted, kept in git history), D22, SHA-256 c3de7faf0da3146ec981c35fe6ebd70bede4cdaf1cd757919cad5b1bfab2ae1f; deleted, bytes in git history), which left SAF-5 reporting and the failed cancellation case undecided. This file decides those points and the storage trust boundary. It changes no bytes of those files.

## Decision text

**U1. Storage trust.** When a browser storage operation succeeds, the game trusts that operation. The game never trusts stored contents without validation: contents read back are judged by the rules already decided (R1, D21 S7, S8 and S11), accepted whole or rejected whole. Stored data can be edited or lost, so the game promises no permanent storage and no protection against tampering. A storage failure must not stop gameplay; what the game does about the saved game after a failed write or read is decided in D21 S4 to S7. This records a trust assumption and adds no requirement.

**U2. Fault reported, SAF-5.** When drawing or reading a gamepad fails, the drawing and polling loops keep running (SAF-5). The fault counts as reported when both of these happen: (a) the player is shown a small notice that drawing or controller input had a problem, which does not interrupt play and is not a popup, and (b) a separate signal that a test can observe is raised. No fault record is required to be written to storage. D22 T1 and T2 are unchanged and still govern the SAF-3 stop.

**U3. Failed timer cancellation during a fault stop.** If cancelling a timer fails while the game is stopping safely after a fault, a timer may still fire, but it must not change the stopped game. The game remains over, the last good save is kept and the fault is reported. This is an owner-approved interpretation of "no timers running" in SAF-3 for that case only. It adds no trust in a scheduler that runs a timer after a successful cancellation: D22 T3 still applies to successful cancellation. This text states the outcome and selects no mechanism.

**U4. Timer scope for SAF-3 and SAF-4.** The timers these rules cover are the gravity timer, the lock-delay timer and the held-key repeat timers. The invariant checks of SAF-4, and the safe stop of SAF-3 on a broken invariant, apply after each firing of these timers and to the actions they cause. These timers are stopped when the game is paused or over. The drawing loop and the controller-polling loop are not timers in this sense; they keep running under SAF-5 and U2. This interprets the word "timer" and does not change the check points SAF-4 names.

## Not decided here

- How U3 and the stopping of the timers in U4 are achieved, and whether any change to the code is needed. Some of U1 to U4 may differ from how the code behaves today; that is a later separate decision with its own tests and approval.
- The exact wording and placement of the notice in U2.
- Any change to REQUIREMENTS.md, including whether U1 to U4 should become requirement text, and the class of any later change.
- The remaining trust-ledger entries: the service worker, hosting, repository settings and the random source.
- Closure of the Phase 1 exit items on fault reporting and trust assumptions. This file records decisions toward them and does not close either item.
