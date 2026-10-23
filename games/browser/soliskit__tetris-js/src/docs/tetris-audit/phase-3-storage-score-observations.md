# Saving and Scoring Checks

Bounded scoring, loaded-save, high-score, and failed-write comparisons.

Status: bounded correspondence and candidate evidence, not findings disposition, certification or Phase 3 closure. Prepared separately from PR77. Production base, public-identical documentation main. No production, permanent test, fixture, CI or frozen model edits.

## Completed-turn scoring

Twenty-four predeclared cases combine 1-4 bottom rows filled except column 4, a vertical I at box row 16 column 2, score/high 0, 900 or 1000, and hard drop or the actual registered lock-expiry callback. The model asserts valid pre/post state and encounters no Undefined. The supplied next-O spawn at (0,4) is a caller reading, not a unique normative choice.

All 24 agree on full board, current piece, score, high score, level, count, mode, outstanding gravity/lock presence and save eligibility. There are zero production faults. Independent Node22 review reproduced both outputs byte-identically and independently checked the score formula, level, surviving I-cell row shifts and callback mapping. This supports bounded SCO-1/SCO-2 correspondence. It does not prove save payload correctness, arbitrary scores, multi-level history, partial gaps, top-out, reachability, bag/queue behavior, storage ordering or deadlines.

## Raw released-format projection

The two unchanged repository fixture byte hashes are:

- `saved-game-current.json`: `5db92314408a59661f17e47887778df96de91e19ae433827b1f74a42227e126e`
- `saved-game-with-level.json`: `c628f4442aab487f185b2ba88c58adce6fbf6c55310c3f0314e1dc1e7abc1ebb`

For each fixture, the raw original plus copy-only ignored-level and missing-bag mutations load paused, with zero timers/faults and preserved board, piece, held/hold-used, queue, score/derived level and bag where supplied. Missing bag produces an empty factory bag awaiting refill. Later fresh refill was not executed. A two-piece queue is rejected and withdrawn in both copies. Copy-only score 150 and a full bottom row are rejected, consistent with the already recorded O-7/O-6 stricter-acceptance candidates from `phase-3-obligations-P3-D.txt`: O-7 is score divisibility by 100 despite B11's no-divisibility rule; O-6 is rejection of a full row despite B15 imposing no such snapshot condition. These are partial source projections, not complete R1 acceptance results.

Both original fixtures lack a reset-count field. The approved pack defines L1 for missing lowest row and L2 for a legacy count 15. It defines no default for an absent reset count. An independent pack-only review confirmed the gap. No absent count is silently mapped to zero, and no frozen-model raw-format comparison is claimed. Source compatibility and complete acceptance remain unresolved. For the fixtures' T rotation 1, the production raw lowest value 0 maps to greatest occupied row 2 under a declared box-to-block adapter; this alone is not a behavioral deviation.

The fixtures' README and addition commit claim release capture. Historical serializers include level/bag and remove level. Field compatibility and repository claims do not independently prove the exact captures or historical deployments. Neither original fixture was edited or regenerated.

## High-score storage

Forty-two cases use 14 raw values with success, read-throw and write-throw storage: missing, 0, 7, 100, 300, -1, 1.5, NaN, Infinity, 9007199254740992, 1e3, 0x10, surrounding-space 7 and empty text. Each runs a one-line I clear to score 100, then pause and confirmed New Game.

All finish with zero faults; New Game leaves the post-turn stored high score unchanged. Unambiguous bounded decimal values meet the expectation max(current score, valid stored high score), with values outside the non-negative-whole-number domain counted as zero under S8/B11/B16. The whole decimal value 9007199254740992 is read as zero and overwritten by 100, a bounded numeric-limit candidate against B3/B11/B16, not a classified finding. Non-decimal/exponent/space/empty forms remain observational under the existing G9 representation-reading gap. Equal or greater high scores are rewritten without decreasing; the replacement-effect interpretation remains open.

Read failure returns zero and can overwrite a prior larger stored value. Write failure leaves raw bytes and play continues. No general integer proof, real device, cross-tab atomicity, browser display or model A7 timing claim is made.

## Effect-specific persistence cutpoints

Seven cases begin with a public New Game O, three soft drops and a pause saving row 3, then resume and a soft drop to row 4. Exceptions are injected at named effects:

| Cutpoint | Observed result | Limit or candidate |
| --- | --- | --- |
| Pause payload write throws, withdrawal succeeds | Old row-3 bytes kept, flag false, unavailable | Bounded failed-save withdrawal correspondence |
| Both pause writes throw | Old row-3 bytes and true flag remain, runtime eligibility true | Existing S4/S5/S9 candidate |
| Pause payload succeeds, flag write throws | New row-4 bytes, old true flag, runtime eligibility true | Successful-save definition across flag failure unresolved |
| Continue payload read throws | Old bytes kept, flag written false | Existing S7 candidate |
| Continue payload is malformed | Flag false, no timers/faults | Expected withdrawal, not hostile-domain proof |
| Line clear writes high 100, then factory throws | Score/high 100 retained, old row-3 bytes/true flag kept, game over, zero timers, one signal | Bounded no-rollback and fault-stop effects |
| Later row-4 save succeeds, resume registration throws | Later row-4 bytes/true flag kept, game over, zero timers, one signal | Later bytes kept, not loss of the initial save |

The line-clear board is injected; other traces use public engine actions. A plain player-visible T1 message was not assessed. A save's validity under the new R1 rules is not certified while its count content is unresolved. Byte preservation must not be promoted to a universal last-good-save proof. No real storage, concurrent tabs, all cutpoints or hostile cancellation claim is made.

Independent Node22 review reproduced all 12 raw-format, 42 high-score and seven cutpoint outputs, checking source expectations and effect sequences. The flag-failure-after-payload run had an already-true flag. A separate later case explicitly injects an external false flag and invalidates the cache before pause. Its payload write succeeds, true-flag write throws, and runtime eligibility remains false, with paused mode and zero timers/faults. Independent Node22 review reproduced that extra case and checked its effect mapping. It does not settle the successful-save definition. Fixture capture provenance remains asserted, and the reviewer could confirm only normalized trailing-newline identity, not these exact-byte hashes. These reviews support bounded candidates, not full proof. Source/model/implementation/representation issues remain separate. Implementation-exposed results are not clean-author input.
