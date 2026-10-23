# Design Priorities

The revised order for choosing between designs.

The owner's order for design decisions is now: simplest app first, then avoid an invalid state. This replaces the earlier order of avoiding an invalid state first and choosing the simplest app within that.

This is a priority change, not a rewrite of R1's state-validity predicates, a certification of any implementation, or authorization to ship invalid states. Existing requirement and behavior changes still require their own reviewed authorization. No particular save compatibility, no-label design, field list, marker set, history replacement rule, deletion, storage withdrawal or implementation is selected by this order alone.

Refusing an old save can cost the whole saved position (board, score, pieces), while the high score is stored separately. This record does not assert that this is every possible worst consequence or blanket approval for destroying game progress or high scores.

## Decision record

The owner approved the new decision priority order. This records the decision and its scope, not approval of final document bytes or a code change. Publication follows the separate docs-only review, checks and merge grant.
