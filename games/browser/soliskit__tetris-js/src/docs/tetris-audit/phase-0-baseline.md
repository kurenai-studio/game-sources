# Audit Baseline

Recorded measurements before the audit, not a correctness certificate.

Recorded on October 4, 2026 under the audit blueprint `docs/audit-blueprint.txt` (, DECISIONS.md D11). Drafted by the assistant for the owner's review.

This record holds the values Appendix B1 lists, measured from the repository and CI. It does not close Phase 0: under the Audit Advancement Gate the exit needs the owner's approval, which is not given or assumed here. No production code, test, requirement or configuration was changed to make it. The values are baseline evidence at their stated scope, not certification of any requirement (blueprint sections 0 and 9): a green suite and a mutation score of 100 are evidence about the tests, not a proof that the game is correct.

## 1. Audited commit

| Item | Value |
| --- | --- |
| Audited main commit (blueprint) | 30e0085, the merge of PR #42 |
| Main when this record was made | 409faf4, the merge of PR #45 |
| What changed between them | Only `DECISIONS.md`, `docs/audit-blueprint.txt`, `docs/audit-blueprint.pdf` and the four files under `docs/sources/` |
| Same code, tests and configuration | The git tree hashes of `public/`, `test/`, `e2e/`, `scripts/`, `.github/`, `REQUIREMENTS.md`, `package.json`, `package-lock.json`, `playwright.config.js`, `stryker.config.json`, `tsconfig.json`, `tsconfig.sw.json` and `index.js` are identical at both commits (`git rev-parse <commit>:<path>`; for example `public/` is 1e09ad6, `test/` ef5e856, `e2e/` 4c09d1a) |

So every value below measured at 409faf4 is a value for the code, tests and configuration of 30e0085.

Checksums checked before any measurement (`sha256sum`): `docs/audit-blueprint.txt` and `docs/audit-blueprint.pdf` match D11 (f7a8ad1d...6541 and 0ad6fbac...b8d), and the four files under `docs/sources/` match Appendix D.

## 2. Requirement text check (blueprint 1.1, re-run)

Section 1.1 says Phase 0 re-runs the pre-audit check and records the output. A script read each requirement row from `REQUIREMENTS.md` and compared it with the text the blueprint reproduces under that ID, then collected every requirement ID the blueprint cites, ranges such as "PCE-1 to PCE-6" expanded, and looked each one up. Output, identical for `REQUIREMENTS.md` at 409faf4 and at 30e0085:

```
REQUIREMENTS.md rows: 55
SAF-1: exact match
SAF-2: exact match
SAF-3: exact match
SAF-4: exact match
PLY-2: exact match
PLY-7: exact match
STA-1: exact match
STA-4: exact match
APP-6: exact match
Reproduced texts matching exactly: 9 of 9
Distinct IDs cited in the blueprint: 35
Cited IDs: APP-2, APP-3, APP-6, INP-1, INP-2, INP-3, INP-4, PCE-1, PCE-2, PCE-3, PCE-4, PCE-5, PCE-6, PLY-2, PLY-3, PLY-6, PLY-7, QA-1, QA-2, QA-3, QA-4, QA-5, QA-6, SAF-1, SAF-2, SAF-3, SAF-4, SAF-5, SAF-6, SCO-1, SCO-2, STA-1, STA-3, STA-4, STA-6
Cited IDs absent from REQUIREMENTS.md: none
PCE-* in REQUIREMENTS.md: PCE-1, PCE-2, PCE-3, PCE-4, PCE-5, PCE-6
APP-* in REQUIREMENTS.md: APP-1, APP-2, APP-3, APP-4, APP-5, APP-6
```

## 3. Appendix B1 values

| B1 value | Recorded | Source |
| --- | --- | --- |
| Audited commit | 30e0085; measured at 409faf4, which has the same code, tests and configuration (section 1) | git |
| `GameManager` lines | 591 (`public/game/gameManager.js`) | `wc -l` |
| Mutable-state inventory | Section 4 | Code search |
| Test count | 288 reported by the test runner, all passing, 0 fail, 0 skipped: 287 tests defined in the 11 `test/*.test.js` files, plus `test/helpers.js`, which `node --test` also runs as a file (its default file pattern includes everything under `test/`) and counts as one passing test although it defines none | Local run and CI run 37216193410 agree on 288 |
| Browser-test count | 183: 61 tests in each of the three projects (WebKit at iPhone size, Chromium at iPhone size, Chromium at desktop size). In CI: 164 passed, 19 skipped, 0 failed. The 19 skips are declared in the tests: 13 touch tests on the desktop project, which has no touch, and 6 in WebKit (the install check, two Tab focus tests and three tests that need real touch events) | `npx playwright test --list`; CI run 37216193410 |
| Coverage, engine (`public/game/`) | Lines 100% (1,434 of 1,434), branches 100% (465 of 465), functions 100% (138 of 138). The line figure counts physical lines, not executable ones: the lcov output has an entry for every line of every file, blank lines and comments included, and each file's count equals its `wc -l` (1,434 in all; by a simple pattern 133 are blank and 391 comment-only). A line counts as covered when it lies in a range V8 recorded as run; the branch and function figures are counted from V8's blocks and functions | Node 26.10.0 test runner coverage; counts from its lcov output; CI prints the same percentages |
| Coverage, page script (`public/script.js`) | Lines 100% (591 of 591), branches 100% (176 of 176), functions 100% (29 of 29), statements 100% (591 of 591). As for the engine, the line figure counts physical lines: `v8-to-istanbul` maps every one of the file's 591 lines (58 blank, 154 comment-only by a simple pattern, 379 others), so 591 is the file's length, not a count of executable lines, and its statement count is the same per-line figure. `public/sw.js` has no coverage measurement in either suite: browser coverage is collected for `script.js` only (`e2e/fixtures.js`), and unit coverage covers `public/game/` only | Local Chromium projects with `scripts/browser-coverage.js`; its HTML report (`coverage/browser-report/index.html`) shows Statements 591/591, Branches 176/176, Functions 29/29, Lines 591/591; CI prints 100% for all four measures |
| Mutation totals | 1,152 mutants tested, in the engine (`public/game/`) only, plus 2 left out by the documented shuffle exclusion (F10). The same 1,152 in CI. `public/script.js` and `public/sw.js` are not mutated; the page script's only mutation evidence is the historical pilot (section 5) | Section 5 |
| Killed, survived, timed out, errored | Local: 1,128 killed, 0 survived, 24 timed out, 0 errors, 0 without coverage. CI run 37216743885: 1,120 killed, 0 survived, 32 timed out, 0 errors, 0 without coverage | Section 5 |
| Mutation score and repository threshold | 100.00, locally and in CI. Threshold in `stryker.config.json`: break 100 (the run fails below it), high 100, low 95; timeout 20,000 ms; concurrency 4. Timed out mutants count as caught, as QA-6 states | Section 5 |
| Type-check result | Pass: `npm run typecheck` (both `tsconfig.json` and `tsconfig.sw.json`) exits 0 with no errors, locally and in CI | Local run; CI run 37216193410 |
| CI result | Section 6 | GitHub Actions |
| Deployment result | Section 6 | GitHub Actions; live site |
| Dependency and repository configuration facts | Section 7 | `package-lock.json`, workflows, GitHub |
| Service-worker and network observations | Section 8 | Code |
| Hosting and security-header observations (APP-6) | Section 9 | Live site |

## 4. Mutable-state inventory

Where mutable state lives and which code writes it, found by searching the code for assignments and in-place changes. This is a baseline listing only. It does not decide which state is authoritative, derived, a runtime resource, persisted or presentation (that partition is a Phase 1 decision, 1.3), and it is not the Phase 2 route inventory, which is derived from call relationships.

`GameManager` constructor (`gameManager.js` lines 84 to 115) assigns 24 fields. Nine are assigned only there: `storage`, `scheduler`, `factory`, `onFault`, `onChange`, `rows`, `columns`, `maxLockDelayResets`, `lockDelayInterval`; no other file under `public/` assigns them. The other 15 are written after construction:

| Field | Written by (method: line) |
| --- | --- |
| `state` | `resetGameSession`:183, `loadGameSession`:207, `generateNextTetromino`:237, `failSafe`:437, `performAction`:479, 488, 498, `holdTetromino`:567 |
| `gameBoard` | replaced by `resetGameSession`:184, `loadGameSession`:208; cells set by `lockTetrominoInPlace`:329; rows removed and added by `clearFullRows`:343, 346 |
| `boardVersion` | `resetGameSession`:185, `loadGameSession`:209, `lockTetrominoInPlace`:331, `clearFullRows`:347 |
| `score` | `resetGameSession`:186, `loadGameSession`:210, `clearFullRows`:348 |
| `currentTetromino` | replaced by `resetGameSession`:189, `loadGameSession`:211, `generateNextTetromino`:231, `holdTetromino`:571; its `position` set by `dropTetromino`:250, `hardDrop`:542, `moveTetromino`:554; its `rotationState` and `position` set by `Tetromino.rotate` (`tetromino.js`:145, 146), called from `rotateTetromino`:586 |
| `nextTetrominos` | replaced by `resetGameSession`:190, `loadGameSession`:212; shifted and pushed by `generateNextTetromino`:230, 232 |
| `heldTetromino` | `resetGameSession`:191, `loadGameSession`:213, `holdTetromino`:577 |
| `canHoldTetromino` | `resetGameSession`:192, `loadGameSession`:214, `generateNextTetromino`:233, `holdTetromino`:578 |
| `gameLoopTask` | `startGameLoop`:363, its timer callback :364, `stopGameLoop`:371 |
| `lockDelayTask` | `startLockDelay`:266, `cancelLockDelay`:314 |
| `lockDelayResetCount` | `resetLockDelay`:293, 295, `noteLowestRow`:303, `resetLockDelayForNewPiece`:308, `performAction`:491 |
| `lowestRowReached` | `noteLowestRow`:302, `resetLockDelayForNewPiece`:309 |
| `isConfirmingNewGame` | `performAction`:468, 475, `softDrop`:528, `cancelNewGame`:535 |
| `faults` | `failSafe`:444, 445 (push, and shift past 20) |
| `storedIsSessionSaved` | getter `isSessionSaved`:159, `storageChanged`:175 |

Two accessors write storage rather than a field: the `highScore` setter (`tetris.highScore`, set by `clearFullRows`:349) and the `isSessionSaved` setter (`tetris.isSessionSaved`, set by `resetGameSession`:194, `loadGameSession`:204, `saveGameSession`:222, 224, `generateNextTetromino`:238, `holdTetromino`:568). `saveGameSession`:221 writes `tetris.savedGameSession`. These three are the only storage keys the engine uses, and `setItem` is the only storage write in `public/`; the in-memory fallback storage (`createMemoryStorage`, used when `localStorage` is missing or throws) holds a `Map` and also has a `removeItem` the engine never calls. `level` and `standardDropInterval` are getters computed from `score`, not stored.

Other modules:

| Module | Mutable state |
| --- | --- |
| `tetromino.js` | Each piece's `position` and `rotationState` (written in `rotate`, and by `GameManager` as above); `color`, `rotations` and `wallKickData` are set in the constructor only |
| `tetrominoFactory.js` | `bag` (written by `generate` and `resetBag`), `random` (constructor only) |
| `inputController.js` | `movement`, `movementTimer`, `softDropTimer`, `heldKeys`, `heldButtons`, `padDirection`, `padDown`, `polling`; `gameManager` and `questionButtons` are set in the constructor only |
| `script.js` | Module variables `lastState`, `gameEnded`, `wakeLockWanted`, `wakeLock`, `lastSnapshot`, `drawnBoard`, `renderErrorReported`, `drawRequested`; collections `contexts`, `canvasSizes`, `vividColors`, `drawnPreviews` and the `drag` object; the page's one `GameManager` |
| `session.js`, `gameState.js`, `position.js` | No module state (`gameState.js` exports frozen objects) |
| `sw.js` | No variables change; its state is in the browser's caches: one `tetris-version-` cache per download and the `tetris-pins` cache (section 8) |
| Browser storage | `localStorage` keys `tetris.highScore`, `tetris.isSessionSaved`, `tetris.savedGameSession` |

## 5. Mutation results

Scope. Stryker mutates `public/game/**/*.js`, the seven engine files, and nothing else: the page script `public/script.js` and the service worker `public/sw.js` are not mutated, and the browser tests in `e2e/` take no part. Every mutant is judged by one command, from `stryker.config.json`:

```
exec node --test --test-isolation=none test/model.test.js test/tetromino.test.js test/factory.test.js test/game.test.js test/gameManager.test.js test/session.test.js test/safety.test.js test/inputController.test.js
```

These eight files hold 266 of the 287 unit tests (counted by running the same command at 409faf4). The other three test files, `test/server.test.js`, `test/staticFiles.test.js` and `test/traceability.test.js` (21 tests), are not run against mutants. Stryker's command runner treats the whole command as one test (its dry run reports "Ran 1 tests"), so a mutant is killed when any of the 266 fails.

Historical evidence for the page script, not Phase 0 evidence: the only mutation testing of `public/script.js` is the page script mutation pilot of October 3, 2026 (DECISIONS.md D5 and its Baselines row). It mutated the hold box and New Game dialog handlers, 45 mutants, against the Chromium browser tests one mutant at a time: 35 killed, 7 timed out, 3 survived (93.3%), in 29 minutes 15 seconds. Its survivors led to F13 and F14, fixed in PR #39, and F15, rejected as equivalent. D5 estimates about 5.3 hours for all 488 mutants in the page script. The pilot ran before PR #39 and was not re-run for this record. `public/sw.js` has no mutation evidence.

Local full run, `npm run test:mutation` (Stryker 10.0.0, the scope above, 4 workers on a 4 core machine, Node 26.10.0):

| File | Killed | Timed Out | Survived | No Coverage | Errors | Score |
| --- | --- | --- | --- | --- | --- | --- |
| `gameManager.js` | 417 | 6 | 0 | 0 | 0 | 100.00 |
| `gameState.js` | 23 | 1 | 0 | 0 | 0 | 100.00 |
| `inputController.js` | 328 | 0 | 0 | 0 | 0 | 100.00 |
| `position.js` | 4 | 0 | 0 | 0 | 0 | 100.00 |
| `session.js` | 160 | 0 | 0 | 0 | 0 | 100.00 |
| `tetromino.js` | 53 | 6 | 0 | 0 | 0 | 100.00 |
| `tetrominoFactory.js` | 143 | 11 | 0 | 0 | 0 | 100.00 |
| All files | 1,128 | 24 | 0 | 0 | 0 | 100.00 |

The report's JSON also lists the 2 mutants left out by the documented exclusion as Ignored. Stryker reported "Final mutation score of 100.00 is greater than or equal to break threshold 100" and finished in 18 minutes 24 seconds (16:23:53 to 16:42:18 UTC); the command exited 0.

CI full runs on the same code:

| Run | Commit | Killed | Timed Out | Survived | No Coverage | Errors | Score | Time |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 37216743885, the manual run of `mutation.yml` for this record | 409faf4 | 1,120 | 32 | 0 | 0 | 0 | 100.00 | 32 minutes 17 seconds |
| 37173755667, PR #42's full run in `mutation-pr.yml` | aae40ba, whose code trees equal 30e0085's | 1,121 | 31 | 0 | 0 | 0 | 100.00 | 32 minutes 16 seconds |

Per file in run 37216743885: `gameManager.js` 409 killed and 14 timed out, `tetromino.js` 53 and 6, `tetrominoFactory.js` 143 and 11, `gameState.js` 23 and 1; `inputController.js` 328, `session.js` 160 and `position.js` 4 killed, none timed out. Every file scores 100.00, and Stryker reported "Final mutation score of 100.00 is greater than or equal to break threshold 100". Its report is the run's artifact 11309411340.

In all three runs every one of the 1,152 mutants was caught and none survived. Only the split between killed and timed out moved (24, 31 and 32 timed out), and only in `gameManager.js`; the other files have the same counts in all three. The CI run's totals equal the prior local run that B3 records (1,120 killed, 32 timed out).

A mutant that makes the tests run past the fixed 20 second limit counts as timed out, so whether a slow mutant is recorded as killed or timed out can vary with the machine; which mutants moved was not investigated. As B3 notes, a timeout counts as caught under the repository gate but is weaker evidence than a failing assertion.

## 6. CI and deployment

| Run | Commit | Result |
| --- | --- | --- |
| Test and deploy 37216193410 (push to main) | 409faf4 | Success. Test job: type check pass; 288 unit tests reported, all passing (287 tests and `test/helpers.js`, section 3), with 100% engine coverage; 183 browser tests, 164 passed and 19 skipped, page script coverage 100%. Deploy job: success |
| Test and deploy 37175384449 (push to main) | 30e0085 | Success |
| Mutation testing on pull requests 37173755667 (PR #42) | aae40ba, whose code trees equal 30e0085's | Success: full suite, 1,152 mutants, 1,121 killed, 31 timed out, 0 survived, 0 errors, score 100.00 |
| Mutation testing 37216743885 (manual run for this record) | 409faf4 | Success: full suite, 1,152 mutants, 1,120 killed, 32 timed out, 0 survived, 0 errors, score 100.00, 32 minutes 17 seconds |

CI toolchain in run 37216193410: runner image ubuntu-24.04 (version 20260927.320.1), Node 26.10.0, npm 12.2.0, Playwright 1.63.0 with Chrome for Testing 153.0.8010.12 (Chromium build 1243) and WebKit 26.6 (build 2359).

Wall-clock times, from the step start and end times GitHub reports, which are whole seconds, so short steps are approximate:

| Step | Test and deploy, run 37216193410 | Mutation testing, run 37216743885 |
| --- | --- | --- |
| Set up job and checkout | 1 s | 2 s |
| `actions/setup-node` (Node 26, npm cache) | 7 s | 7 s |
| `npm install --global npm@12.2.0` | 2 s | 2 s |
| `npm ci` | 4 s | 3 s |
| `npm run typecheck` | 1 s | |
| `npm test` | 2 s | |
| `npx playwright install --with-deps chromium webkit` | 49 s | |
| `npm run test:e2e` (183 tests on 2 workers, then the coverage report) | 79 s | |
| `npm run test:mutation` | | 32 min 18 s (Stryker reports 32 min 17 s) |
| Upload the mutation report | | 3 s |
| Whole job | Test 2 min 30 s (16:19:21 to 16:21:51 UTC); deploy 16 s (16:21:54 to 16:22:10) | 32 min 39 s (16:26:01 to 16:58:40 UTC) |

Run 37216193410 was created at 16:17:03 UTC, but its test job only began at 16:19:21: the workflow's concurrency group queues pushes to main, and the run for PR #44's merge was still running until 16:19:19. From the start of the test job to the end of the deploy job took 2 minutes 49 seconds. The PR #42 mutation run took 32 minutes 33 seconds for the job, 32 minutes 17 seconds for its mutation step.

Deployment: the deploy job uploaded the `public` folder as the `github-pages` artifact (105,695 bytes) and GitHub Pages reported the deployment of 409faf4 as successful. At 16:24 UTC on October 4, 2026 each of the 16 files under `public/` was fetched from https://soliskit.github.io/tetris-js/ and compared with the file at 409faf4: all 16 are byte for byte identical, and the folder URL itself serves `index.html`. Plain HTTP redirects to HTTPS (301).

## 7. Dependency and repository configuration facts

* Toolchain required by `package.json`: Node 26 or newer and npm 12.2.0 or newer. CI installs Node 26 (26.10.0 in the runs above) and npm 12.2.0.
* Runtime dependency: `express` 5.2.1, used only by `index.js`, the local server. GitHub Pages serves `public/` as static files, so it is not part of the deployed game. `qs` is overridden to 6.16.0 or newer (6.16.0 installed).
* Development dependencies: `@playwright/test` 1.63.0, `@stryker-mutator/core` 10.0.0, `typescript` 7.0.2, `istanbul-lib-coverage` 3.2.2, `istanbul-lib-report` 3.0.1, `istanbul-reports` 3.2.0, `v8-to-istanbul` 9.3.0. The lockfile (version 3) installs 245 packages. `npm audit` reported 0 vulnerabilities on October 4, 2026, for all dependencies and for runtime ones alone.
* Workflows: `pages.yml` runs the type check, unit tests and browser tests on every pull request and push to main, and deploys only after the test job passes on a push or manual run (never on a pull request). `mutation-pr.yml` runs on pull requests that change `public/game/`, `test/` or itself. `mutation.yml` runs Mondays at 06:17 UTC and on demand. The test and mutation jobs have only `contents: read`; the deploy job has `pages: write` and `id-token: write` and uses the `github-pages` environment.
* Actions are referenced by major version tag, not pinned to a commit: `actions/checkout@v7`, `actions/setup-node@v7`, `actions/upload-artifact@v7`, `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`.
* Repository rules on `main`. Evidence from the GitHub API, October 4, 2026:
  * Ruleset 24429848, retrieved through the GitHub API (`/repos/soliskit/tetris-js/rulesets/24429848` and `/repos/soliskit/tetris-js/rules/branches/main`): name "CI must pass before merging", target branch, enforcement active, applies to `~DEFAULT_BRANCH` (`main`), no excluded refs. It contains one rule, `required_status_checks`, with required check context `test` (integration 15368), `strict_required_status_checks_policy` true and `do_not_enforce_on_create` false. The recovered ruleset has no `pull_request` rule. Created 2026-10-03T20:10:30Z, last updated 2026-10-03T20:17:06Z.
  * Bypass: the recovered ruleset reports `bypass_actors` as an empty array and `current_user_can_bypass` as `never`.
  * Independent fact: the branch listing reports `main` as protected (`protected: true`).
  * Classic branch protection: the endpoint was separately attempted and returned HTTP 403, "Resource not accessible by integration". Its details were not visible through the integration. This record infers nothing about classic branch-protection constraints, neither that they exist nor that they do not.
  * Not inferred: whether a pull request is required. Every commit on `main`'s first-parent history after the initial commit of June 28, 2024 is a pull request merge (40 merges, PR #6 to PR #45), but that is repository practice, not evidence of an enforced pull request rule, and the recovered ruleset has none.
  * B2's statement that the rules require the test check but do not necessarily require a PR is confirmed for ruleset 24429848: it requires the `test` check, up to date with `main`, and has no `pull_request` rule.
* Before this record, the weekly mutation workflow had run once (September 28, 2026, at 96fb774), so no scheduled run had covered 30e0085.

## 8. Service worker and network observations

* The page registers the worker with a relative path, `navigator.serviceWorker.register('sw.js')` (`script.js`:590), so its scope is the folder it is served from.
* The only network calls in `public/` are in the worker: the passthrough `fetch(request)` for a GET request with no cached answer (`sw.js`:100), and the download of every app file by `cache.addAll` (`sw.js`:142), which fetches the 16 entries of `APP_SHELL` with `cache: 'no-cache'`. A download starts when the worker installs (line 152) and after every page navigation (line 174). Requests other than GET are not intercepted (line 165).
* No other network interface is used in `public/`: no `XMLHttpRequest`, `WebSocket`, `EventSource`, `sendBeacon`, `importScripts` or dynamic `import()`, and no absolute URL. The page loads its own files only, by relative paths (`index.html` lines 12 to 23 and 75).
* Caches the worker creates: `tetris-version-<number>-<random>` for each download, and `tetris-pins`. Caches it deletes: `tetris` and `tetris-2` when it activates (line 160); `tetris-version-` caches older than the newest complete one that no page opened with in the last 10 minutes, keeping the two newest (line 128); its own download's cache if the download fails (line 144); and pins older than 10 minutes (line 124). The version number is read with `parseInt` (line 46), and any non-empty cache whose name starts with `tetris-version-` counts as a complete version (lines 57 to 64).
* There is no server, account or shared leaderboard: the high score is stored only in the browser.
* HTML sinks: one `innerHTML` assignment, `script.js`:231, which sets one of two constant strings. No `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval` or `new Function`.

## 9. Hosting and security headers (APP-6)

Fetched on October 4, 2026 from this session, whose HTTPS traffic passes through an egress proxy that re-terminates TLS. Everything below is what was observed on that proxy route. It is not generalized to the origin: what the origin sends to other clients was not observed.

* On this route, every file checked (`/tetris-js/`, `sw.js`, `script.js`, `manifest.webmanifest`) arrived with `server: GitHub.com`, `cache-control: max-age=600` and `access-control-allow-origin: *`, and the right content type (`text/html`, `application/javascript`, `application/manifest+json`, each `charset=utf-8`).
* None of these headers was observed on this proxy route: `Content-Security-Policy`, `Strict-Transport-Security`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, `Service-Worker-Allowed`, or any `Cross-Origin-*` policy. Whether the origin sends any of them to other clients was not established.
* Repository fact, separate from the route: `index.html` at 409faf4 has no CSP `meta` element.
* The game is served from `https://soliskit.github.io/tetris-js/`. On this route the origin's root, `https://soliskit.github.io/`, answered 200. APP-6 itself states that GitHub Pages serves every project of an account from one origin that shares storage and caches; which other projects or workers are on the origin was not examined.
* Whether GitHub Pages lets a project set its own response headers was not established here.

## 10. Appendix B2 observations rechecked

| B2 observation from 30e0085 | Now |
| --- | --- |
| `GameManager` is 591 lines | Reproduced: 591 |
| The constructor assigns 24 fields (lines 84 to 115); 9 are dependencies or settings assigned only there | Reproduced (section 4) |
| `findInvariantViolation()` is around lines 411 to 428 | Reproduced: comment at 410 and 411, method at 412 to 428 |
| `parseSession` is the central persisted-state parser | Reproduced as far as call sites go: its only call is `loadGameSession` (`gameManager.js`:201). How complete a parser it is, is for later phases |
| `npm run typecheck` exists | Reproduced, and passes |
| The worker's network calls are `fetch(request)` around line 100 and `cache.addAll` at line 142 | Reproduced (section 8) |
| No server or shared leaderboard | Reproduced (section 8) |
| Main deployment follows CI | Reproduced: the deploy job needs the test job (`pages.yml`), and the 409faf4 deployment followed a passing test job |
| Repository rules require the test check but do not necessarily require a PR | Confirmed for ruleset 24429848: required check `test`, strict up-to-date, no `pull_request` rule. Classic branch-protection details were not visible (HTTP 403) (section 7) |
| `express` is local-development infrastructure | Reproduced (section 7) |
| One constant `innerHTML` use | Reproduced: `script.js`:231 |
| No project-level CSP | Partly: `index.html` has no CSP `meta` element, and no CSP header was observed on this session's proxy route, which is not generalized to the origin (section 9) |
| Hosting-header limits not yet established | Still not established; the headers observed on this session's proxy route are in section 9 |
| GitHub Pages shared origin implications remain relevant to APP-6 | Noted in section 9 |

## 11. Environment, commands, limits and what is not recorded

* Local machine: Linux, 4 cores, Node 26.10.0 and npm 12.2.0 installed for this record (the machine came with Node 22). `npm ci` left the working tree unchanged.

Commands, run from the repository root at 409faf4:

```
# Toolchain: Node 26.10.0 from nodejs.org, checked against its SHASUMS256.txt, then
npm install --global npm@12.2.0
npm ci

# Type check (npm run typecheck)
tsc -p tsconfig.json && tsc -p tsconfig.sw.json

# Unit tests with the 100% coverage gate (npm test)
node --test --experimental-test-coverage --test-coverage-include="public/game/**" --test-coverage-lines=100 --test-coverage-branches=100 --test-coverage-functions=100

# Engine coverage counts: the same run with the lcov reporter; LF/LH, BRF/BRH and FNF/FNH summed over the files
node --test --experimental-test-coverage --test-coverage-include="public/game/**" --test-reporter=lcov --test-reporter-destination=unit.lcov

# Tests run against mutants, counted
node --test --test-isolation=none test/model.test.js test/tetromino.test.js test/factory.test.js test/game.test.js test/gameManager.test.js test/session.test.js test/safety.test.js test/inputController.test.js

# Browser test count (no browser needed)
npx playwright test --list

# Chromium browser tests, local, then the page script coverage report and its 100% check
npx playwright test -c pw-local.config.mjs
node scripts/browser-coverage.js

# Mutation testing (npm run test:mutation), with stryker.config.json
stryker run
```

`pw-local.config.mjs`, kept outside the repository, verbatim:

```js
// Scratch only: runs the repository's Chromium projects with the preinstalled
// Chromium, since this machine has no Playwright 1.63 browser builds.
import base from '/home/user/tetris-js/playwright.config.js';
const repo = '/home/user/tetris-js';
export default {
  ...base,
  testDir: `${repo}/e2e`,
  globalSetup: `${repo}/e2e/global-setup.js`,
  outputDir: `${repo}/test-results`,
  webServer: { ...base.webServer, cwd: repo },
  projects: base.projects
    .filter(p => p.use.browserName === 'chromium')
    .map(p => ({ ...p, use: { ...p.use, launchOptions: { executablePath: '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell' } } }))
};
```

It keeps everything else from `playwright.config.js`: the two Chromium projects with their viewports, touch and scale settings, `fullyParallel`, no retries, and the web server (`node index.js` on port 4173). The paths are absolute because the file lives outside the repository. The executable is the Chromium headless shell, build 1194, which reports Chromium 141.0.7390.37; Playwright chose 2 workers. The page script's absolute coverage counts come from a scratch script that loads the per-test files in `coverage/browser/` with `v8-to-istanbul` and `istanbul-lib-coverage`, as `scripts/browser-coverage.js` does, and prints the covered and total counts of the merged map.
* Playwright 1.63.0 expects Chromium build 1243 and WebKit build 2359. This machine has neither, and no browser was downloaded. The two Chromium projects ran locally with the preinstalled Chromium 141 headless shell, through the configuration above: 122 tests, 109 passed, 13 skipped (the desktop touch tests), 0 failed, and page script coverage 100%. WebKit was not run locally (B4); the WebKit result is the CI result. The page script coverage counts in section 3 come from this local Chromium 141 run; CI, with Chromium 153, prints only percentages, all 100%.
* A first local attempt used the full Chromium 141 browser instead of its headless shell. The install check (APP-1, `e2e/app.spec.js`:103) failed in both Chromium projects: that browser reported the installability error `in-incognito`. The same test passed with the headless shell and in CI. Why the full browser reports it was not investigated. It is recorded so the failure is not lost; no conclusion about the game is drawn from it. That attempt used the same configuration with `executablePath: '/opt/pw-browsers/chromium'`, the full browser, Chromium 141.0.7390.37.
* Not visible here: the details of classic branch protection on `main` (HTTP 403 from the integration). The ruleset facts are in section 7.
* B5's prior evidence (the fault-injection matrix, persistence write detector, random-play probe, browser fault probes and timing measurements) was not re-run; the blueprint places its reproduction in later phases.

## 12. Phase 0 exit

The blueprint: "Phase 0 closes only when the required Appendix B values, including the CI result, are actually recorded." Every B1 value is recorded above, including the CI result. For the repository rules, section 7 records ruleset 24429848 and its one remaining limit: classic branch-protection details were not visible through the integration (HTTP 403). Phase 0 exit, and with it the start of Phase 1, is the owner's decision under the Audit Advancement Gate and is not approved by this record.
