# Tetris Audit

What the audit establishes, its limits, and the work still open.

The audit checks whether the game follows its rules when play, saved data,
or browser services behave unexpectedly. Phase 4 is closed, with five
documented limits (D66 and D71 in DECISIONS.md). Its evidence supports
specific results under stated conditions, not a claim that the
whole game is correct.

## What the records support

The Phase 3 records connect the game rules to source code and methods for checking them.
Some methods compare controlled examples with independent expected answers.
Others reason about listed code paths under explicit assumptions.
Publishing those records completed a documentation step, not product certification.

The summary records candidate findings involving saved-game withdrawal, held controls, callback cleanup, and offline caches.
The dated status page that separated those candidates from later narrow confirmed-defect decisions is deleted. Its one retained disposition, the Continue eligibility-read failure, is now in DECISIONS.md under "Eligibility-read failure: Continue withdrawal disposition".
Each result has its own input conditions and limits.
A controlled failure does not show how often players encounter it.
A source argument does not become a physical-device measurement.

## What remains unfinished

The audit did not reconcile every relevant state writer, entry route,
failure combination, and important test expectation; D71 records those
gaps as limits.
Saved-game evidence must show that retained content is a valid saved position, not merely unchanged bytes.

Physical input, timing, display, and cached-file questions retain separate limits.
A recording can show the screen without establishing every contact or every file the device ran.
The records do not establish both quick taps reaching the game, double-tap recovery, recovery after reloading while enlarged, or exact cached-file identity.

## The Next Step

Resolve one remaining claim through suitable evidence or an explicit decision about its limit.
Keep the result, assumptions, and unanswered cases together.

Current source contains the internal-error explanation and piece-check helpers.
Their presence does not certify every related rule.
Further corrections, permanent tests, final certification, and later test removal remain separate work.
The audit has no supported completion date.

## Terms Used in the Records

A source argument reasons from the inspected code and stated assumptions, without claiming a new execution.
A state writer is code that changes part of the game position.
Cached-file identity means knowing the exact game files that a device loaded from its stored copies.
An audit phase is a stage of work with its own completion checks. Phase 3 builds the claim-to-evidence record.
Phase 4 tries to disprove those claims with hostile inputs and controlled failures.
