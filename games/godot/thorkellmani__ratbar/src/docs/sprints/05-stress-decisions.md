# Stress From Felt Needs — Decision Log

Historical decisions from the completed stress baseline sprint. Follow-ups are in the [backlog](../RAT_SIMULATION_BACKLOG.md#stress-vice-and-crisis); results remain in this historical record.

- Use the rat's urgency curves to model its current feeling. For stress, an improving need is sampled at full satisfaction; stored need values and location-choice urgency stay unchanged.
- Average all five stress-specific urgency samples. Select a provisional hourly rate from the Inspector-editable `StressTuning` tiers and apply it every game tick.
- Add a flat `+3` stress per game-hour while the rat is actively performing its assigned job. Job assignment and travel alone add no work stress. Clamp stored stress to `0..100`.
- ~~Keep `Rat.apply_game_tick_effects()` as the public tick entry point and move its need and stress implementations out during a later refactor.~~ The subsequent Rat State Ownership design puts tick coordination in `RatManager`. Rats provide detached snapshots and accept validated updates; systems calculate from supplied values. This replacement is planned, pending implementation.
- ~~Create and store a `StressEvaluation` result for every rat on every tick.~~ Cache only the effective average urgency on the rat. `StressEvaluator` derives the tier and rates from that average and current work state when needed; the debug breakdown displays them on demand.
- Use the existing **Statuses → stress** override in the debug panel. The stress breakdown remains a read-only explanation of the rate.
