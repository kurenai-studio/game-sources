# Shared need values

`NeedValues` declares the five numeric need fields and their single key list. Its setters prepare a value, store it, then call a notification hook. By default values are unconstrained and no notification is emitted.

`Needs`, `NeedDecayRate`, `LocationModifiers`, `JobModifiers`, and `LocationPull` override the hooks to enforce their own bounds and emit `stat_changed`. `LocationPull` owns appeal normalization for location scoring.

`NeedRates` inherits the default behavior. It holds combined changes per game-hour, preserving their sum without clamping. These are rates, not need satisfaction values.

The former `NeedFields` class has been removed. Consumers use `NeedValues.get_keys()` directly or inherit it; the separate curve container `NeedUrgency` delegates its key list to the same method.
