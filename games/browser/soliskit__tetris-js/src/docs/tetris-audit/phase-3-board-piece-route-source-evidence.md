# Board and Piece Changes

The inspected creation, loading, movement, and game-over routes.

This source check maps the named routes that change the board and piece. It is a bounded static mapping for PCE-1/PCE-6/STA-3, not complete reachable-writer coverage, hostile-state exhaustion, finding classification or phase closure.

## Board shape under named ordinary writers

The constructor fixes rows to 20 and columns to 10, then createBoard makes separate rows and empty cells. New Game uses the same creation route. Accepted Continue assigns the reconstructed parseBoard result, which checks outer and inner lengths against those dimensions. This is an implementation format check, not an independent whole-payload oracle or permission to narrow valid imported content.

Lock writes cell values, not array dimensions, if every piece cell is in bounds and every row exists. The fitted-piece relation must hold before lock to meet those preconditions. A monitor that checks after the operation does not prove them on its own. A throw can retain a partial board under the fault rule, outside this ordinary-completion argument.

clearFullRows removes each collected full row once in descending-index order and prepends the same number of fresh empty rows. The separate row-clear record states the dense ordinary-board and normal-completion premises for its row-transform argument. Surviving cell aliases are not eliminated. The inspected lexical board-write sites are GameManager lines 115, 184, 208, 329, 343 and 346 (constructor/reset/load/lock/clear), but a lexical inventory is not proof that all exposed aliases, direct calls, setters or malformed dependency routes are harmless.

For the named ordinary dense board, cellAt reads board[row]?.[column] (gameState.js 55-57); absent rows or columns return undefined. isFree tests whether that read has isFilled === false (tetromino.js 27-29), so an absent position is not free. This maps the application read relation for positions outside that board; it is not an independent oracle or a proof about arbitrary array properties, aliases or hostile getters.

## Piece admission and semantic absence

| Route | Inspected admission relation | Limit |
| --- | --- | --- |
| Constructor | Generates and spawns a concrete piece while the opening mode is over | The opening concrete piece has no ordinary-over falling-piece semantic value; bootstrap exceptions are not guarded gameplay transitions |
| New Game | Built-in starting geometry on an empty fixed-size board supplies a conditional fit argument | Does not select an independent centering tie rule or certify arbitrary factories |
| Move | fits(board, proposedPosition) is checked before position assignment | Direct-helper exposure and changes between check and assignment remain separate |
| Rotate | Each candidate must fit before rotation state and position are assigned | Admission does not make production kick data the independent expected oracle |
| Fall | isOnSurface is the negation of fit one row below; the successful path assigns that next position without a second fit check | Requires stable board/ordinary getters; later landing/lock/resource effects need composition |
| Hard drop | Starting fit and monotone downward translation lead to the last row before a blocked next row | Requires fixed preboard and termination; the subsequent lock/clear/spawn/save is separate composition |
| Next after lock or empty Hold | Assigns a spawned next piece, then tests fit; no-room sets ordinary over | Concrete nonfitting piece remains in fields, but no ordinary-over falling-piece semantic value is inferred |
| Held swap | Tests the incoming starting piece before current assignment; no-room sets ordinary over | The prior concrete piece is not a semantic falling piece after over; all top-out/resource effects remain separate |
| Continue | Parser assigns orientation/position to a fresh reconstructed piece, checks fit, then accepts it for later assignment into game state | Does not establish complete held/queue/raw-format validity or saved count/lowest restoration |

The engine monitor checks falling-piece fit while playing, not paused/over. Its acceptance is not an independent expected predicate. Commit validity, intermediate assignments and fault-retained contents must not be collapsed into one state claim.

## Ordinary over route distinction

Opening over, fault over and ordinary no-room over have different meanings. The inspected ordinary no-room writers are next-piece generation after lock/empty Hold and incoming held-piece swap. Next-piece no-room retains the assigned nonfitting concrete next piece. Held-swap no-room retains the prior concrete current piece, conditionally fitting under its pre-state premises; neither field is an ordinary-over semantic falling piece. Both assign the stored eligibility flag false. That attempt is not independent proof of successful withdrawal, session history or resource completion. The source next-piece no-room branch calls stopGameLoop; Hold calls stopGameLoop and cancelLockDelay before testing the incoming piece. These call sites provide a partial static STA-3 mapping. They are not independent evidence that native timers stopped, saved data was withdrawn, or all ordinary-over resource effects completed. A malformed factory failure is not silently classified as ordinary top-out.

## Source identity

Public tree `1e09ad61c19e0b235a231ad8810dae176be4ea77`. GameManager SHA-256 `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`. Board creation call anchors: 93-115 and 182-190; the full resetGameSession method is 182-195, including its stored eligibility flag write; load: 199-217; next piece: 230-242; lock/clear: 327-351; move: 550-555; Hold: 560-580. Tetromino and saved-game source, exact anchors: the file public/game/tetromino.js at that tree hashes (SHA-256) to `d99c1bd6cb4a9e255b9ef2840264281e46a9665dcb30f66c6b45e654d1654bfe` - spawn at 59-65 (rotation state 0, centered column), cells at 72-83 (static) and 85-87 (getter), static fits at 95-96 and instance fits at 104-106, dropDistance at 115-121 (monotone downward translation to the last row before a blocked next row), rotate at 131-151 (requested direction's kicks first, opposite direction's kicks second, state and position assigned only on a fitting candidate, unchanged when none fit). The file public/game/session.js at that tree hashes (SHA-256) to `54acbea460218f0e0a827619eae51e265461fe9ac6575dc8bf48727f6483049b` - serializeSession at 29-40, parseBoard at 76-97 (outer/inner length and color checks, full-row rejection), parseActivePiece at 106-114 (kind, integer position, rotation-state range, fit before acceptance), parseWaitingPiece at 123-126, parseBag at 133-137. The file public/game/gameState.js at that tree hashes (SHA-256) to `4d4d88f18f8d2335fac4104e746b972214991df8b1c6e72e0cc5d8d12cb30878`; cellAt is 55-57 and isFree in tetromino.js is 27-29. The independent geometry bindings must still be checked separately before this record can be a complete full-claim mapping. This record makes no new model choice.
