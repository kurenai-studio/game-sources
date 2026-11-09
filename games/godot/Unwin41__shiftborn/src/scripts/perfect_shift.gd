class_name PerfectShift
extends RefCounted
## Perfect shift: shifting while an enemy or a bolt is about to touch the
## player. It grants a moment of invulnerability, a slow-motion beat and
## energy for the new form. A cooldown keeps crowds from making every
## shift perfect.

## Extra reach beyond touching, in px, that still counts as "about to hit".
const DANGER_MARGIN := 10.0
const COOLDOWN := 2.0
const INVULNERABLE_TIME := 0.6
## Real seconds of slow motion and the time scale during it.
const SLOW_TIME := 0.3
const SLOW_SCALE := 0.4
## Energy (0..1) given to the form the player shifts into.
const ENERGY_REFUND := 0.25
const POPUP_TEXT := "PERFECT"
const POPUP_COLOR := Color(0.55, 0.95, 1.0)

var _cooldown: float = 0.0


## True when a threat of [param threat_radius] at [param threat_position]
## is touching the player at [param player_position] or about to.
static func is_threat(player_position: Vector2, threat_position: Vector2, threat_radius: float) -> bool:
	return player_position.distance_to(threat_position) <= threat_radius + Player.BODY_RADIUS + DANGER_MARGIN


## Starts the cooldown and returns true when [param in_danger] and ready.
func try_trigger(in_danger: bool) -> bool:
	if not in_danger or _cooldown > 0.0:
		return false
	_cooldown = COOLDOWN
	return true


func tick(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
