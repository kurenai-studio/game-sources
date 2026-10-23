# Shared types

- [`needs/`](needs/README.md) contains `NeedValues`, the shared five numeric need fields and key list, and `NeedRates`, unconstrained changes per game-hour.
- `types/key_value.gd` holds a named numeric value used by location scoring.

Concrete need types own their bounds and notifications: `Needs` belongs to rat attributes, `NeedDecayRate` to rat configuration, and location/job modifiers to their respective entity folders. `LocationPull` also owns normalization for appeal scoring.

Rat-specific `Personality`, `Status`, and `Camaraderie` are standalone Resources under `entities/rat/data/attributes/`. Rat owns a `RatState` Resource under `entities/rat/data/state/`; inspection uses native deep copies. The narrow `RatStateUpdateDraft` under `entities/rat/data/simulation/` is a detached RefCounted object for need/stress calculations. Scalar activity, crisis, currency, and owner relationship values belong to RatState; JobManager owns assignment.

The former `BaseStatGroup` and `field_groups` hierarchy has been removed. Share field declarations where multiple types use them; keep constraints and notifications with the concrete owner.
