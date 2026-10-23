# Check Every Upcoming Piece

The selected meaning of the three-piece runtime check.

Each required safety check must verify three real upcoming pieces, not merely a list with three slots. A list with an empty or malformed slot must not pass just because its length is three. This decision settles what the check must detect, not a code change.

## Detector extent

Interpret SAF-4's "three pieces queued" using the existing upcoming-piece semantics in R1 B3/B7: an ordered, complete list of exactly three entries, each denoting a valid semantic upcoming piece of one of the seven adopted kinds. Null entries, holes and non-piece values do not satisfy this criterion. This resolves B7's expressly deferred runtime-check interpretation without editing REQUIREMENTS.md or changing B7's existing valid-state domain.

Waiting pieces do not inherit the current falling piece's board-fit, live position, lowest-row history, lock-delay or timer conditions. No specific class, object layout, checker function or duplicated geometry is required. Representation must denote the adopted semantic piece; recognizable color alone does not certify an otherwise malformed representation without a reviewed reconstruction or representation mapping.

## Pre-correction source comparison

The pre-correction `public/game/gameManager.js` invariant monitor compared `nextTetrominos.length` with `UPCOMING_COUNT`. This distinguishes list size, not element validity. A dense three-entry list of nulls and a sparse list of length three cannot be rejected by that count predicate alone. These are source observations, not new executed findings or proof that ordinary play creates such states.

The later [piece-check implementation in PR171](https://github.com/soliskit/tetris-js/pull/171) is separate from this historical count-only comparison.

The built-in factory and saved waiting-piece reconstruction are separate writer evidence. Their successful-path preservation under stated premises does not demonstrate runtime element checking or cover every writer, hostile alias or custom dependency.

## Audit obligations and limits

Compare each declared Q1 malformed-queue partition with this selected criterion. Record semantic representation, actual detector result, ordinary-writer relation and reachability separately. Preserve missing representation, execution or writer evidence rather than substituting the count check or built-in construction for it.

This decision does not classify every malformed representation, establish ordinary malformed-queue creation, close Q1 or all-state R1, or certify Phase 4. The current-piece detector decision remains separate. Correction and regression proposals retain their independent review and approval gates. No production code, permanent tests, model, CI or public-site change is approved here.
