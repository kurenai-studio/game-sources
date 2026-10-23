# Implementation Inventory

The inspected entry points, state changes, storage effects, and safety boundaries.

Status and provenance are recorded in `DECISIONS.md`, row D38. This is evidence material about the implementation, not decision text. It is not independent of the implementation and must not be given to a clean O8 model author (blueprint O8, Phase 3). It states candidate observations only; it assigns no finding status and no certification status, and it adds no requirement.

Base: `main` (D36 merged; `origin/main` was still this commit when the inventory was integrated). All code references are file:line at that commit. Static reading only: nothing was run, no test executed, no scratch mutation made.

Boundary used: D16 section 4 (the conceptual commit of a specified legal operation with its authorized persistence effects), D31 Z1 and the D32 operation assignments, defined independently of the code. Routes were derived from code and call relationships, not from the names of guard functions.

## 1. Partition evidence

Five read-only partition inventories were produced at the base and are kept unedited under `docs/phase-2-inventory/` (SHA-256 below). They hold the route tables with code references. This record integrates them. Remarks inside those files about assignment text or phase status are the readers' own and carry no authority; the ledger governs. The five partition inventory files were later deleted; their bytes remain in git history, and the route tables survive only as integrated in this record.

| Partition | Scope | File | SHA-256 |
| --- | --- | --- | --- |
| P2-A | engine gameplay and timers | `docs/phase-2-inventory-P2-A.txt` (deleted, kept in git history) |  |
| P2-B | persistence and session | `docs/phase-2-inventory-P2-B.txt` (deleted, kept in git history) |  |
| P2-C | input and control | `docs/phase-2-inventory-P2-C.txt` (deleted, kept in git history) |  |
| P2-D | page and outer layer | `docs/phase-2-inventory-P2-D.txt` (deleted, kept in git history) |  |
| P2-E | service worker, app, static exclusion | `docs/phase-2-inventory-P2-E.txt` (deleted, kept in git history) |  |

## 2. Coverage of the blueprint's section 2 list

| Required item | Where inventoried |
| --- | --- |
| every public action entry | P2-A E1 to E8 (`handleAction`, `softDrop`, `togglePause`, `cancelNewGame`, constructor, read-only getters); callers P2-C and P2-D |
| every timer callback | P2-A T1 gravity, T2 lock delay (injectable scheduler); P2-C input repeat timers (inputController.js:268, 270, 291); P2-E has none (no timers in `sw.js`); P2-D none in `script.js` |
| every state mutation route | P2-A section 5 (items 1 to 9, 15, 16 by route); P2-C items 12 to 14; P2-D D13 to D17 for item 14 and D08 for item 11 |
| every persistence route | P2-B (three storage keys, reads R-a to R-c, writes W-a to W-c, call chains per operation); P2-E (cache storage names and pins) |
| every game-over route | P2-A (new piece without room, held piece without room, engine fault stop) with P2-B storage effects |
| every New Game route | P2-B, P2-D D19, P2-C confirmation keys |
| every Continue route | P2-B (`loadGameSession`), P2-D D07 |
| every input route | P2-C (keyboard, gamepad, repeat), P2-D D14 to D18 (touch, visibility, hold box) |
| every drawing callback | P2-D D04 to D11 |
| every gamepad polling route | P2-C (polling loop, first connected pad), P2-D D03 |
| every storage event route | P2-D (`script.js` storage listener), P2-B |
| every route capable of bypassing the boundary | section 3 |

## 3. Cross-partition call-chain pass (performed by the integrator)

- From `public/script.js` and `public/game/inputController.js` the only engine members called are `handleAction`, `softDrop`, `togglePause`, `cancelNewGame` and `storageChanged`, plus read-only getters (`state`, `score`, `highScore`, `isSessionSaved`, `isConfirmingNewGame`, `boardVersion`, `gameBoard`, `nextTetrominos`, `heldTetromino`, `ghostTetromino`, `currentTetromino`, `columns`). No file under `public/` other than `gameManager.js` calls `hardDrop`, `moveTetromino`, `holdTetromino`, `rotateTetromino`, `dropTetromino`, `saveGameSession`, `loadGameSession`, `resetGameSession`, `failSafe` or `generateNextTetromino`. Those methods are public on the class; callers outside `public/` (`test/`, `e2e/`) were not inventoried.
- `script.js` reads `currentTetromino` (including `tryMove` and the touch handlers) but contains no assignment to a piece field; engine movement from touch goes through `handleAction`.
- No write to `localStorage` or `caches` appears outside `gameManager.js` (storage) and `sw.js` (cache storage).
- Hand-offs checked: page registration of the service worker (`script.js` register call) is P2-D and the worker side is P2-E; storage keys read by drawing code are P2-B; the engine calls that input reaches are P2-A.
- Every file in the blueprint's inventory list is represented: the seven `public/game` modules, `public/script.js`, `public/sw.js`, `public/index.html`.

## 4. Excluded files and reasons

`public/icons/`, `public/manifest.webmanifest` and `public/style.css` stay excluded for the reasons the blueprint records. Re-checked at the base: `style.css` has no script, no `@import` and no `url()`; `manifest.webmanifest` is declarative data; `icons/` holds exactly four static image files referenced only by `index.html`, the manifest and the service worker cache list. The exclusion does not remove APP, DSP or INP claims that depend on these bytes from later evidence. `test/`, `e2e/`, the server file, workflows and `REQUIREMENTS.md` are references and not inventory subjects.

## 5. Candidate observations carried to Phase 3 (no status)

Each needs comparison with the governing text in Phase 3. None is a finding.

1. Items 12 to 14 (held controls and order, repeat position, touch drag) are written by input-layer code outside the engine's checked entry (P2-C section 6; P2-D D13 to D16). Item 12 uses a fixed priority (KeyA, KeyD, then pad) and not an ordered token list; D34 E3 left representation open.
2. Held controls are not cleared on pause; blur and gamepad disconnect release them; visibility hidden resets touch drag but does not release input (P2-C 7.3, 7.4b). Relevant to D33 C3 and D34 E2.
3. A touch that moved beyond 10 px is never cleared before reset (P2-C 7.4); `pointerdown` has no mode check; no `lostpointercapture` listener and no `pointercancel` rotation (P2-D D14, D16).
4. The lock-delay callback calls `lockAndSpawnNext` with no state check; correctness relies on cancellation (P2-A O-3, B5), relevant to D23 U3 and U4. Input timers use `setTimeout` directly and not the engine scheduler (P2-C 7.7).
5. The engine invariant check covers board shape, queue length, score validity, piece fit and timers against state; the held piece and hold-used coherence, bag content, reset count range and lowest row are not among them (P2-A O-1).
6. Hold with no room for the held piece ends the game and returns without updating the held piece fields (P2-A O-6); relevant to D18 game-over semantics.
7. Saves with no bag key parse to an empty bag, and `resetBag` receives it (P2-B C9). Reset count and lowest row are not serialized and are recomputed on load (P2-B C10); compare D32 Continue.
8. `softDrop` clears the new-game confirmation before the engine guard (P2-A E2); every action clears it (P2-A E1).
9. Cache names: `tetris` and `tetris-2` are deleted at activate, and version caches are matched by the prefix `tetris-version-`, both in a namespace shared by the site address (P2-E; APP-6). Pin expiry and version order use the clock (D29 K2).
10. Dialog focus policy (autofocus on Cancel) participates in item 11, so the dialog route is not purely presentation (P2-D D08). Drawing and scheduling containment differ: draw execution is caught, scheduler and module-setup paths are not (P2-D D04, D09, D10).

## 6. Limits

Static reading by five partition readers at one commit. No runtime observation. The partition readers did not all read every governing decision file; mapping of each route to its governing D-record is the Phase 3 proof-obligation work. `docs/phase-1-state-decision.md` (D16) still carries its original "CANDIDATE" status header; ledger row D37 states that the ledger row governs.

## Not decided here

- Any finding status, certification status, requirement change, code change or correction.
- Any Phase 3 evidence, model input pack or proof obligation record.
