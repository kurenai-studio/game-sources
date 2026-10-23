# Score entry: permanent-suite detection of a weakened safe-integer score predicate

Read-only evidence record. No code, test, requirement or CI change. Prepared by the auditor. This record establishes one observed fact about the permanent suite for the blueprint's Score candidate entry. It classifies nothing, adopts no status word, establishes no requirement violation, and identifies no implementation defect.

## The question

The blueprint's Score entry asks a conditional: "If the permanent suite does not detect the weakened predicate, the result is primarily a test-strength evidence gap unless a requirement violation is separately established." The weakened predicate is `Number.isSafeInteger(score)` replaced by `Number.isInteger(score)` in a scratch mutation, and "An unsafe integer that is a multiple of 100, such as 1e17, is the relevant counterexample class." This record answers the conditional's condition: whether the permanent suite detects that weakening.

## Method

- Source: main at `9db0855fee0c5cd626317eb847f751531df5a027`, on a scratch copy; the repository is unchanged.
- Command for every run: `node --test --experimental-test-isolation=none` with no file arguments - bare test discovery from the copy's root, the same discovery `npm test` uses. (`npm test` adds coverage flags and 100% gates; those were not part of these runs. The Node-22 isolation-option spelling follows `docs/tetris-audit/mutation-run-2026-10-19.md`.)
- What discovery actually found was not assumed from a file list: a module load hook on a bare run recorded every executed file under `test/` (hook source and output in the raw capture, `score-mutation-run-raw.txt`). Fifteen `.test.js` files executed - the eleven directly under `test/` plus `test/audit/d74-N1.test.js`, `test/audit/d74-f21-f22-p7.test.js`, `test/audit/l1-clear-after.test.js` and `test/audit/l1-trace.test.js`. The bare run also executes `test/helpers.js`, which contains no tests.
- Local Node 22.23.3 (caveat in Limits).
- Each mutation and probe below was one targeted edit, applied alone, then reverted; after all runs the scratch copy was verified clean (zero modified files).

## Score guards in scope (Obs, main `9db0855f`)

- `gameManager.js:423` (SAF-4 invariant): `if (!Number.isSafeInteger(this.score) || this.score < 0 || this.score % 100 !== 0) return 'score is invalid';`
- `session.js:162` (saved-game restore): `if (!isSafeInteger(score) || score < 0 || score % 100 !== 0) return null;` (`isSafeInteger` is `Number.isSafeInteger`, `session.js:60`)
- `gameManager.js:145` (stored high-score sanitize): `return Number.isSafeInteger(value) ? Math.max(value, 0) : 0;`

## Results (Obs)

Every run below discovered 374 tests and ended 373 pass, 0 fail, 1 todo. The todo is the F21 test's expected-defect mark ("not ok ... # TODO F21 (D74): Confirmed Defect, injected scope - the invariant check accepts holed boards; the fix PR removes this mark"); it is unrelated to scores and unchanged by every run.

- Baseline, unmutated.
- Mutation A, `gameManager.js:423` `Number.isSafeInteger` to `Number.isInteger`.
- Mutation B, `session.js:162` `isSafeInteger` to `isInteger`.
- Mutation C, `gameManager.js:145` `Number.isSafeInteger` to `Number.isInteger`.

All three mutants survive.

The pass/fail totals alone would not prove the mutated lines executed, so each guard was probed separately: replacing the guard line with a `throw` and re-running fails 179 of 374 tests for the GM:423 guard, 47 for the session.js:162 guard, and 15 for the GM:145 sanitize (runtime evidence that each mutated line executes under the suite). Mutation B's `isInteger` is the alias that already exists at `session.js:54` (`const isInteger = value => Number.isInteger(value);`).

Within this run's scope - the 374 tests bare `node --test` discovers and runs at `9db0855f` across the fifteen executed `.test.js` files, locally on Node 22.23.3 - no test detects the weakened predicate at any of the three score guards. This is a runtime result for that suite on that Node version. It is not a statement about the Playwright end-to-end suite (`npm run test:e2e`) or about Node 26; the typecheck step is not a runtime check. The end-to-end suite was not run and its behavior is not exhaustively established; a static search of its sources found the score literals 0, 100, 300 and 4,200 in `e2e/game.spec.js` and `e2e/helpers.js`, all small safe multiples of 100, and no predicate-isolating case was identified by that search.

## Static inventory of score-validation cases (Obs; a pattern inventory, not a completeness proof)

A static search of the test sources found these score-validation cases:

- `safety.test.js:155-159` (the GM:423 invariant): a negative score (-100), a fraction (12.5), and a non-multiple of 100 (150). Each is still rejected under the weakened predicate by the remaining conjuncts (`< 0`, non-integer, `% 100`).
- `session.test.js:109-113` (restore refusal): -100, 150.5, 150, the text `'1300'`, and 2**60 ("a score too large to be exact"). The 2**60 case is an unsafe integer fed to the restore guard, but it does not isolate the safe-integer predicate: 2**60 % 100 = 76 (node-verified), so the `% 100` conjunct rejects it under both predicates.
- `gameManager.test.js:345-349` (stored high score reads as 0): a missing value and the text `'not a number'` only.

The search identified no case whose outcome depends on `Number.isSafeInteger` versus `Number.isInteger` for a score - in every case found, an unsafe value either never reaches a score guard or meets another conjunct that also rejects it. The runtime result above stands independently of this inventory.

The counterexample class the entry names exists and separates the predicates: 1e17 (the blueprint's example) and 9,007,199,254,741,000 are both integers, zero or more, multiples of 100, and greater than `Number.MAX_SAFE_INTEGER` (9,007,199,254,740,991) - all node-verified. Under the weakened guards such a value is accepted; under the current guards the named values are rejected (node-verified for the named substitutions: the GM:423 form returns invalid; the GM:145 form sanitizes to 0). Acceptance by a hypothetical weakened mutant says nothing about the current implementation. This record assesses only detection of the named substitutions at the named guards; every other behavior of the guards is unassessed here.

## Domain separation (Obs; the classification questions stay open)

- In-session semantic domain, R1 B11: "In every mode, a whole number of zero or more, with no divisibility condition." B11 also records that SAF-4 says "valid score" without defining it.
- Stored domain, R1 B16 as amended: "Accepted saved-game scores and stored high scores are whole numbers from 0 through 9,007,199,254,740,991, with no divisibility condition; this later stored-score ceiling does not change the in-session score domain in B11."
- `gameManager.js:145` and `session.js:162` enforce the stored domain's ceiling, consistent with B16 as written; a weakened predicate would break that alignment for those paths.
- `gameManager.js:423` enforces the safe-integer bound and the `% 100` condition in-session, each narrower than B11's stated in-session domain. The blueprint already records an open R1 question for each: "whether unsafe integers are valid scores is R1's question" (the Score entry itself) for the bound, and "whether SAF-4's \"valid score\" includes it is R1's question" (survey Scoring row) for the multiple-of-100 check. A related note about stored content, "No requirement says high scores must be multiples of 100.", concerns the high score, not the in-session guard. This record adds no new requirement question.

## Limits

- Local Node 22.23.3 is indicative, not authoritative; CI runs Node 26 or newer.
- The Oct 19 mutation run (`docs/tetris-audit/mutation-run-2026-10-19.md`) reports all 1,325 Stryker mutants caught. The raw Stryker reports are not committed, so this record makes no claim about whether the safe-integer substitution was among Stryker's generated mutants; the manual runs above stand on their own as the scratch-mutation check the entry describes.
- One local run per mutation and per probe, on the exact source and mutations named.

## What this record does not do

- The Score entry keeps its Candidate state; its evidence-gap framing becomes an observed suite fact, not a classification.
- It establishes no requirement violation and no implementation defect.
- It proposes no fix, no test change, and no requirement change, and it moves no phase.
- It asks for no owner decision.
