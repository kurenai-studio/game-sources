class_name Quality
extends RefCounted
## Effect quality, picked once at startup. Web builds run LOW so the
## browser version stays smooth; desktop builds run HIGH. Pass
## [constant LOW_FLAG] after "--" on the command line to test LOW on desktop.
##
## HIGH: HDR 2D + glow, a light on every bolt, more damage numbers.
## LOW: no HDR or glow, only the player and Shift Burst lights.

enum Tier { LOW, HIGH }

const LOW_FLAG := "--low-quality"

static var tier: Tier = tier_for(OS.has_feature("web"), OS.get_cmdline_user_args())


static func tier_for(is_web: bool, user_args: PackedStringArray) -> Tier:
	if is_web or LOW_FLAG in user_args:
		return Tier.LOW
	return Tier.HIGH


static func is_high() -> bool:
	return tier == Tier.HIGH


## [param color] with RGB scaled by [param boost] on HIGH, so it passes the
## glow threshold. Unchanged on LOW, where values above 1 would just clip.
static func glow(color: Color, boost: float) -> Color:
	if not is_high():
		return color
	return Color(color.r * boost, color.g * boost, color.b * boost, color.a)
