# Piece Bag Checks

Bounded checks of seven-piece bags, refill counts, and saved bag order.

At the October 5, 2026 recording (D45), Phase 3 was still open. This is historical status, not a claim about the current phase. Current phase records are in `DECISIONS.md`. This bounded private evidence for PCE5 is Candidate evidence. It is not certification, findings disposition, fairness, or an accepted oracle. There are no production, permanent-test, CI, or clean-author changes.

## Factory v11

The run used Node22.23.3. It enumerated 5040 discrete choice tuples j0..i for i6..1 and supplied midpoint draws (j+.5)/(i+1), under V3 random[0,1). The independent predicates use the seven kinds I,O,T,S,Z,J,L, the remaining complement/cardinality, and draw counts. They do not use production shuffle order as the expected oracle. Each tuple deals 14 pieces across two aligned refills. Actual results: 5040 paths, 5040 unique first bags, 151237 checks, and 0 failures. Supplied remaining-bag lengths 0..7 carry their supplied prefix without draws. The empty refill then uses 6 draws. Supplied arrays become empty by reference; external mutation remains a trust boundary.

An independent Node22 rerun matches the result counts and eight reset rows. Source copies equal reviewer clone 0f4e510. The reviewer separately considers swap-permutation and arithmetic-choice arguments. Finite midpoint enumeration does not enumerate all floating values or prove universal runtime behavior. The constant0 mutant gives 1 unique first bag and one uniqueness-check failure, while multiset, complement, and draw-count checks still pass. The predicates do not prove absence of bias, fairness, entropy, or unpredictability.

## Manager v12

Before handoff, an independent assertion checked failures===0 in the corrected actual JSON. Results: 5040 NewGame choice cases, 10092 checks, and 0 failures. NewGame discards the constructor's remaining bag. The observed current piece, next3, and remaining bag are exactly seven kinds, with 6 new draws. Three public handleAction(drop) calls expose queue tails. The first seven kinds are distinct; the game is playing, with noFaults. The stable, nonfiring scheduler models resource handles, not elapsed deadlines or browser input.

Continue uses the original bytes of two saved fixtures, plus copy-only fixtures missing the bag. It restores paused/saved remaining-bag order with 0 extra draws. Direct factory exhaustion followed by 7 fresh pieces is a permutation with 6 draws. This is adapter projection, not a complete public Continue trajectory or validation proof. Released-fixture historical capture provenance, the absent-reset-count default, and count/lowest restoration remain separate unresolved gaps.

Two initial harness failures are retained. Nonexistent createMemoryStorage(seed) support meant storage was empty. After explicit setItem, undefined A.continue still meant there was no valid Continue. The final script uses A.continueGame. Both failed scripts and JSON are preserved. The premature 0-failure summary was corrected immediately. These were harness defects, not production findings. Confirmed NewGame is separate from failed Continue attempts. Only corrected output supports the final Continue projection.

An independent rerun of corrected v12 under Node22 equals the stored JSON apart from the node field. The reviewer also reproduced the failed action-token attempt and isolated the one-token fix. The reviewer reports that the v11 production-game bundle and corrected v12 production-game bundle equal its clone 0f4e510. There are four Continue rows, not three: two fixtures x bag present/absent. An empty restored bag is an implementation observation, not a new normative default. The three-document v2 batch received an independent wording and internal-consistency review, not independent numeric-run or full-artifact verification. Node reruns and browser source, JSON, and pixel reviews remain separate.

## Limits

The checks cover aligned refill segments, not every sliding window of seven. Factory-level induction and finite manager cases are separate. They do not prove random fairness or unpredictability, the invalid-random domain, external-bag mutation safety, all GM paths, physical input, universal reachability, or full-state correspondence. NewGame/Continue queue accounting, source induction, and session acceptance remain subject to review. There is no source-rule selection or certification.

The two failed JSON artifacts have the same SHA256 despite different scripts. The coordinator reran each preserved script, isolating output to a separate scratch path. Both reproduced their preserved JSON byte for byte. Both still called undefined A.continue, so neither attempted a load. Storage seeding alone could not affect the reported state or deal results. Identical results do not show identical inputs and are not evidence of a production defect. These rechecks did not overwrite the corrected result.
