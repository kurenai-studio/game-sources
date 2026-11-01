extends RefCounted
## Turns a linear progress value into the eased value a motion token asks
## for. Every board effect goes through here, so the same code runs live in
## the demos and frozen at a fixed progress on the review sheets.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")


## Eased 0 to 1 value of a motion at a linear progress from 0 to 1. Back and
## elastic curves overshoot past 1 on the way, as the token intends.
static func eased(tokens: DirectionTokens, motion_name: String, progress: float) -> float:
	var spec: Dictionary = tokens.motion_spec(motion_name)
	var duration: float = float(spec.get("duration", 0.0))
	var p: float = clampf(progress, 0.0, 1.0)
	if duration <= 0.0 or p >= 1.0:
		return 1.0
	var trans: Tween.TransitionType = int(spec.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType
	var ease_type: Tween.EaseType = int(spec.get("ease", Tween.EASE_IN_OUT)) as Tween.EaseType
	return float(Tween.interpolate_value(0.0, 1.0, p * duration, duration, trans, ease_type))


## An extra number from a motion spec, for example "from_scale".
static func extra(tokens: DirectionTokens, motion_name: String, key: String) -> float:
	var spec: Dictionary = tokens.motion_spec(motion_name)
	if not spec.has(key):
		push_error("%s: motion '%s' has no '%s'" % [tokens.id, motion_name, key])
		return 0.0
	return float(spec[key])


## A looping wave from 0 up to 1 and back to 0 over one period of the motion,
## eased with its curve on the way up and on the way down. Returns 0 when the
## motion has no duration.
static func loop_wave(tokens: DirectionTokens, motion_name: String, time: float) -> float:
	var period: float = tokens.duration(motion_name)
	if period <= 0.0:
		return 0.0
	var phase: float = fposmod(time, period) / period
	if phase < 0.5:
		return eased(tokens, motion_name, phase * 2.0)
	return eased(tokens, motion_name, 2.0 - phase * 2.0)
