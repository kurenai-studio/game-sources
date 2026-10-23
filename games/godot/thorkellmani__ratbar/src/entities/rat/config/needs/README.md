# Need configuration

- `need_decay_rate.gd` / `.tres`: baseline changes per game-hour for all five needs, currently `-5` each. Configured rates are bounded to `-10..10`.
- `need_urgency.gd`: five Curve fields describing the rat's want. Its key list delegates to `NeedValues.get_keys()`.
- `need_urgencies.gd` / `.tres`: authored curves and the existing effective-average calculation. A need being fulfilled (positive net game-hour rate) is sampled at full satisfaction; stored need values stay unchanged by that sampling rule.

A need value describes satisfaction; urgency describes want. Locations use actual need values for choice. See the [Rat explanation](../../README.md#need-is-condition-urgency-is-want) for the distinction.
