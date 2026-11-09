class_name FormEnergy
extends RefCounted
## Stamina of the two forms. The active form tires while it fights and
## deals less damage; the idle form rests and recovers, so shifting every
## so often keeps damage high.

## Seconds for the active form to drain from full to empty.
const DRAIN_TIME := 12.0
## Seconds for the idle form to recover from empty to full.
const RECOVER_TIME := 6.0
## Damage multiplier of an empty form; a full form deals full damage.
const MIN_DAMAGE := 0.5

var _levels: PackedFloat32Array = [1.0, 1.0]


## Energy of [param form], 0..1.
func level(form: Player.Form) -> float:
	return _levels[form]


func damage_multiplier(form: Player.Form) -> float:
	return lerpf(MIN_DAMAGE, 1.0, _levels[form])


## Adds [param amount] (0..1) of energy to [param form], up to full.
func restore(form: Player.Form, amount: float) -> void:
	_levels[form] = clampf(_levels[form] + amount, 0.0, 1.0)


## Drains [param active] and recovers the other form over [param delta] seconds.
func tick(active: Player.Form, delta: float) -> void:
	for form in _levels.size():
		var change := -delta / DRAIN_TIME if form == active else delta / RECOVER_TIME
		_levels[form] = clampf(_levels[form] + change, 0.0, 1.0)
