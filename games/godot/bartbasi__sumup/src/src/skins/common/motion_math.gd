extends RefCounted
## Turns a linear progress into the eased value a skin's motion token asks
## for. Every board effect goes through here, so the same code runs live and
## frozen at a fixed progress in the review scenes and tests.

## Samples used to find how far a curve overshoots. Only used once per skin.
const CURVE_SAMPLES: int = 64


## Eased 0 to 1 value of a motion at a linear progress from 0 to 1. Back and
## elastic curves overshoot on the way, as the token intends. ease_override
## replaces the token's ease when it is 0 or more.
static func eased(skin: SkinData, motion_name: StringName, progress: float, ease_override: int = -1) -> float:
	var spec: Dictionary = skin.motion_spec(motion_name)
	var length: float = float(spec.get("duration", 0.0))
	var p: float = clampf(progress, 0.0, 1.0)
	if length <= 0.0 or p >= 1.0:
		return 1.0
	var trans: Tween.TransitionType = int(spec.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType
	var ease_value: int = ease_override if ease_override >= 0 else int(spec.get("ease", Tween.EASE_IN_OUT))
	var ease_type: Tween.EaseType = ease_value as Tween.EaseType
	return float(Tween.interpolate_value(0.0, 1.0, p, 1.0, trans, ease_type))


## An extra number from a motion spec, for example "from_scale". A missing
## extra is a bug in the skin data: it is reported and 0 is returned.
static func extra(skin: SkinData, motion_name: StringName, key: String) -> float:
	var spec: Dictionary = skin.motion_spec(motion_name)
	if not spec.has(key):
		push_error("%s: motion '%s' has no '%s'" % [skin.id, motion_name, key])
		return 0.0
	return float(spec[key])


## A loop from 0 up to 1 and back to 0 over one period of the motion, eased
## with its curve both ways. 0 when the motion has no duration (holds still).
static func loop_wave(skin: SkinData, motion_name: StringName, time: float) -> float:
	var period: float = skin.duration(motion_name)
	if period <= 0.0:
		return 0.0
	var phase: float = fposmod(time, period) / period
	if phase < 0.5:
		return eased(skin, motion_name, phase * 2.0)
	return eased(skin, motion_name, 2.0 - phase * 2.0)


## Lowest and highest value a motion's curve reaches between 0 and 1. A back
## ease in dips below 0 first, a back ease out passes 1 before it settles.
static func curve_range(skin: SkinData, motion_name: StringName) -> Vector2:
	var low: float = 0.0
	var high: float = 1.0
	for i: int in CURVE_SAMPLES + 1:
		var value: float = eased(skin, motion_name, float(i) / float(CURVE_SAMPLES))
		low = minf(low, value)
		high = maxf(high, value)
	return Vector2(low, high)
