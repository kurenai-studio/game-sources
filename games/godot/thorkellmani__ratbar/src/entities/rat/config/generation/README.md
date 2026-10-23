# Generation configuration

`GenerationDefaults` is an Inspector-editable Resource used by `Rat.initialize(idx)` through Rat's `DEFAULT_VALUES` preload.

- `personality_mean` and `personality_deviation` configure per-trait randomization with `randfn()`.
- `default_needs` and `default_status` are duplicated for each new rat, without randomization. Needs currently start at `80`; health starts at `100`, with other statuses at zero.

The shared defaults remain configuration; each rat owns its independent values. Per-vice tracking and job skills are deferred. Archetype selection is not implemented.
