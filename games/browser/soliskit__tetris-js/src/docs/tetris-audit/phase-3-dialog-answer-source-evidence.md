# New Game Entry and Confirmation

Why opening the new-game prompt and answering it use different routes.

This bounded claim/method record compares the outside New Game entry with the answer inside the dialog. It is not a classified finding, full overlap proof or phase closure. It uses the held "public answer-route assessment", not an original trace replay.

## Requirement and independent comparison

STA-1 says "New Game in the dialog gives the game up" and "any other action before the answer keeps it paused". It distinguishes the outside New Game entry from the inside-dialog answer. Cancel, Escape, an outside click and any other action before an answer keep the game paused. Under the literal public-route reading, a second outside entry is not an inside-dialog affirmative answer. The implementation's reuse of a concrete action enum does not establish that equivalence.

## Held actual relation

The held trace begins paused, with no pending question and the native dialog closed. Two programmatic calls activate the outside newGameButton. The first sets pending before the native dialog opening/focus runs. The second outside entry resets the game to playing and increments boardVersion. No inside confirmNewGameButton activation or native-dialog opening is observed between them.

The implementation comment says a second New Game confirms; both entry handlers use that action. This records implementation intent, not normative permission to equate the two public routes. The observed overlap happens before the native modal opens. Expected native-modal inertness after showModal is a platform premise. This held trace does not examine it. Human reachability of this pre-modal overlap is unknown.

This supplies a bounded outside-entry versus dialog-answer comparison. Programmatic activation does not establish trusted human input frequency, native focus behavior or all overlapping schedules.

## Remaining interpretation domain

If the first opening conceptually completed, the second outside action is still not the named inside-dialog route under this reading. If it remained unfinished, the trace still shows no inside affirmative answer. These observations do not prove that every permitted overlap/abort abstraction is impossible. A broader interpretation that treats a second outside entry as a logical affirmative answer needs reconciliation with the requirement's explicit route words.

No commit point is invented from an engine return. No missing abort rule is treated as proof of impossible linearization. Complete assigned-operation abstraction and native event/focus domains remain separate. The comparison is a candidate relation. It is not a confirmed human defect or an owner decision that the implementation is correct.

## Source binding

Public tree `1e09ad61c19e0b235a231ad8810dae176be4ea77`, unchanged by documentation merge. The distinct outside/inside page handlers are in `public/script.js:509,519 (entry handlers) and 222-229 (modal synchronization)`; the engine action relation is in `public/game/gameManager.js:463-481`. Script SHA-256 `59fcb3343f35d0022c739cce82c5c9601a9e3bc354a9dc991eb1660c4e599ad4`; GameManager SHA-256 `31bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea`. Held trace provenance is privately recoverable; source identity is not a fresh replay.
