# Mutation run, Oct 19, 2026

Evidence for requirement QA-6. Nothing here changes code, tests, requirements, CI (the automated checks that run on each change), or the public site.

Instinct ran mutation testing (small deliberate code changes the tests must catch) on code version `2cacbdf` of the main branch and finished on Oct 19 at 7:46 PM PDT. The tests caught all 1,325 mutants: 1,303 killed, 22 timed out (a timeout counts as caught); none survived.

## How it ran

- Tool: Stryker with its command test runner, mutating `public/game/**/*.js`.
- Tests: the eight engine test files in `stryker.config.json`, all under `test/`: `model.test.js`, `tetromino.test.js`, `factory.test.js`, `game.test.js`, `gameManager.test.js`, `session.test.js`, `safety.test.js` and `inputController.test.js`.
- Node: 22.23.3, not the Node 26 or newer the repo asks for. On Node 22.23.3 Instinct set test isolation with that version's spelling of the option (`--experimental-test-isolation=none`) instead of the repo config's spelling (`--test-isolation=none`).
- Two runs that split the files, at concurrency 1 each, on two copies of the repo, so the work fit the host (2 cores, 2 GB memory).

## Results

| File | Killed | Timed out | Survived |
| --- | --- | --- | --- |
| `gameManager.js` | 430 | 6 | 0 |
| `gameState.js` | 23 | 1 | 0 |
| `position.js` | 4 | 0 | 0 |
| `inputController.js` | 328 | 0 | 0 |
| `session.js` | 159 | 0 | 0 |
| `tetromino.js` | 213 | 7 | 0 |
| `tetrominoFactory.js` | 146 | 8 | 0 |
| Total | 1,303 | 22 | 0 |

No mutant went uncovered or errored. Of the 1,325 mutants, the first run (`gameManager`, `gameState`, `position`) held 464 and the second (the other four files) held 861.

## Limits

- This is one run on Node 22, not Node 26; it does not show the same result on Node 26.
- The raw Stryker reports (HTML and JSON) are not in the repo because of their size. This table is the record.
- This is a separate run, not a re-run or copy of the Oct 16 run, which was never recorded in the repo.
