# F24: storage-read failure during save discovery and Continue - evidence record (draft)

Blueprint section 4.7, item 4 (F24); appendix entry `docs/tetris-audit/audit-blueprint.txt:1488`. One indicative local run, not a status. This record adopts no classification. Raw capture: `f24-storage-read-run-raw.txt`.

## Governing texts

- Blueprint section 4.7, item 4 asks, for a storage-read exception during Continue/save discovery: stored bytes/value before and after; cached saved-game availability; whether Continue remains available; whether a later successful read rediscovers the save; whether any write occurs; whether the game continues safely.
- R4 storage-read semantics, decided October 4, 2026, as recorded in `DECISIONS.md` D21 and `docs/tetris-audit/phase-1-r2-r5-decision.md` (Read section): "A storage read failure is not invalid stored content and is not absence established by a successful read. A failed read may make the saved game unavailable, but does not by itself withdraw it or change stored values. Nothing is promised about when availability returns." That is the decision record's formulation, finalized under the owner's October 4, 2026 authorization; the owner's approved choice in the original exchange was that a failed read makes the save unavailable while it cannot be read but does not mark it forgotten. (Blueprint :444 records R4 as decided in D21 and keeps the question text as originally written; the :448 "Until it is made" wording is that retained question text, not the current decision status.)
- SAF-2 (REQUIREMENTS.md:85): "Storage that is missing, blocked, full, or throws on reads or writes never stops the game. Invalid stored values are ignored." How the observations classify against SAF-2 and the decided R4 rule is the audit's later-phase work, not this record's.

## Method

Scratch copy only: the repository tests and requirements are unchanged. `node --test`, Node.js v22.23.3 (measured `node --version`), local shell, against a scratch checkout of commit 0f1e3abd69686914802872c49816fe3026b1a7ff. Storage is an in-memory map wrapped so `getItem` throws `Error("injected storage-read failure")` for armed keys, with read and write call logs; key strings match `gameManager.js:36-37`. Each case is seeded by a real `GameManager` playing a new game and pausing, which writes the real saved session and flag through the production code path. Source basis: `readItem` (`:134-141`) catches a storage-read exception and returns null ("Unreadable storage counts as empty"); `get isSessionSaved` (`:159-162`) reads the flag key through `readItem` and caches the boolean until `storageChanged()` (`:175`) or a write through the setter (`:165-172`); `loadGameSession` (`:200`) returns at `:201` when the cached flag is false and at `:204` when the save-text read returns null, with the source comment "A failed read or a missing save does not change storage" (`:203`). The tests call `loadGameSession()` directly on the manager. The public Continue action - the button or key running `handleAction(PlayerAction.continueGame)` (`script.js:575`, `gameManager.js:464-465`), which routes through `guard` and `performAction` (`gameManager.js:469`, `:487`) to `loadGameSession`, with the guard's invariant checks and the page's `onChange` callback - is not exercised.

## Observations

Case A - the flag-key read throws during discovery:

- Stored bytes before and after: the stored save text compares byte-identical to the seeded text at two measured checkpoints - after the failed discovery (wrapped read) and at the final checkpoint (read from the underlying map). The stored flag reads `true` at the final checkpoint (read from the underlying map). The initial flag value was captured at seeding; the no-write measurement below covers the interval between.
- Cached saved-game availability: `isSessionSaved` reads `false` while the flag read fails.
- Continue availability: `loadGameSession()` is a no-op (state unchanged) while the flag reads false.
- Rediscovery: after the storage recovers, `isSessionSaved` STILL reads `false` - the getter serves the cached answer, and the read log records no new read across that access (measured, not inferred). After `storageChanged()` (the page's handler for another tab's storage event), the read log records exactly one new read, `isSessionSaved` reads `true`, and `loadGameSession()` restores the saved game (state `paused`). Rediscovery requires the cache invalidation; it is not automatic on recovery.
- Writes: none - the write log holds no writes after seeding, checked at two points: in the failure window and again at the final checkpoint (measured, not inferred).
- Safe continuation, measured only as: the game state is unchanged during the failed direct `loadGameSession()` call (initial `gameOver`) and reads `paused` after the recovery load; the `onFault` report callback is not called (spied), `failSafe` is not called (spied), and the faults list stays empty (asserted) - each checked at both checkpoints. Timer behavior, invariant checks, and engine-step correctness are not measured; broader safety is not established.

Case B - the save-text read throws during Continue (flag read succeeds):

- Stored bytes before and after: the stored save text compares byte-identical to the seeded text at the final checkpoint (read from the underlying map), with the write log empty after seeding at that checkpoint (measured).
- Cached saved-game availability: `isSessionSaved` reads `true` before, during, and after - the save remains discoverable.
- Continue availability: `loadGameSession()` no-ops while the save text cannot be read (state unchanged); after the storage recovers, the next `loadGameSession()` restores the saved game (state `paused`) with no cache invalidation needed, because the flag was never cached false.
- Writes: none (measured).
- Safe continuation, measured with the same scope as Case A: state unchanged during the failed direct `loadGameSession()` call, then `paused` after the recovery load; all three fault checks passing at both checkpoints.

## Limits

- Storage is a JavaScript stub over an in-memory map, not a browser `Storage` object; browser-specific failure modes (quota, corruption, private-mode behaviors) are out of scope.
- `storageChanged()` is invoked directly; a real browser storage event's timing and cross-tab delivery are not exercised.
- "Continue availability" is measured through direct `loadGameSession()` calls on the manager, not the rendered button and not the public Continue action (`handleAction` -> `performAction` -> `loadGameSession`, with the guard's invariant checks and the page's `onChange` callback), which this run does not exercise; no DOM was involved. Whether the public action composes the same behavior is unmeasured, and this record neither confirms nor revisits the recorded public-Continue failed-read withdrawal disposition (the eligibility-read case's existing record).
- Node.js v22.23.3 is below the repository's required Node >=26 (package.json `engines`); behavior under the required major version is not measured.
- One indicative run on one commit. Classification of the case-A observations against the decided R4 read rule - including the recorded "Nothing is promised about when availability returns" clause - and SAF-2 is the audit's later-phase work; this record adopts nothing.
