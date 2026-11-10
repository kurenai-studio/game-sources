class_name DayNight
extends RefCounted
## The light over the settlement through the day: a smooth tint keyed by the hour, and where the
## sun, the moon and the stars are in the sky.

const HOURS: Array[float] = [0.0, 5.0, 6.5, 8.0, 17.0, 19.0, 21.0, 24.0]
const COLORS: Array[Color] = [
	Color(0.42, 0.48, 0.74),
	Color(0.42, 0.48, 0.74),
	Color(1.0, 0.84, 0.76),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 0.8, 0.66),
	Color(0.5, 0.52, 0.78),
	Color(0.42, 0.48, 0.74),
]
## Without a fire the nights are much darker; this is how much of the night light is left.
const UNLIT_NIGHT_LIGHT: float = 0.6
## The red channel at full night, which is how "how night is it" is read from a tint.
const NIGHT_RED: float = 0.42


## The tint for an hour of the day in [0, 24). Days are the same either way; before the settlement
## has fire the night is darker.
static func tint(hour: float, lit: bool = true) -> Color:
	var base: Color = _base_tint(hour)
	if lit:
		return base
	var night: float = night_amount(hour)
	var light: float = lerpf(1.0, UNLIT_NIGHT_LIGHT, night)
	return Color(base.r * light, base.g * light, base.b * light, base.a)


## 0 in daylight to 1 in the dead of night, read from how far the day's tint has gone towards
## night. Drives the fire's glow.
static func night_amount(hour: float) -> float:
	return clampf((1.0 - _base_tint(hour).r) / (1.0 - NIGHT_RED), 0.0, 1.0)


static func _base_tint(hour: float) -> Color:
	var clamped: float = clampf(hour, 0.0, 24.0)
	for index: int in range(1, HOURS.size()):
		if clamped <= HOURS[index]:
			var span: float = HOURS[index] - HOURS[index - 1]
			var amount: float = (clamped - HOURS[index - 1]) / span if span > 0.0 else 1.0
			return COLORS[index - 1].lerp(COLORS[index], amount)
	return COLORS[COLORS.size() - 1]


## The sky bodies (viewport art pixels, a sprite's centre). The sun crosses the sky from 6:00 to
## 19:30 and the moon from 19:30 to 6:00; both start and end below the horizon, behind the far
## hills, so they rise and set rather than appear.
const SUN_RISE: float = 6.0
const SUN_SET: float = 19.5
const MOON_RISE: float = 19.5
const MOON_SET: float = 30.0
const SKY_X: Vector2 = Vector2(20.0, 364.0)
const HORIZON_Y: float = 46.0
const SKY_PEAK: float = 36.0
## Stars start to show once this much of the way to full night, and are all out by STARS_FULL.
const STARS_FROM: float = 0.3
const STARS_FULL: float = 0.9


## Where the sun is at an hour, or Vector2.INF while it is down.
static func sun_position(hour: float) -> Vector2:
	if hour < SUN_RISE or hour > SUN_SET:
		return Vector2.INF
	return _arc((hour - SUN_RISE) / (SUN_SET - SUN_RISE))


## Where the moon is at an hour, or Vector2.INF while it is down.
static func moon_position(hour: float) -> Vector2:
	var night_hour: float = hour if hour >= MOON_RISE else hour + 24.0
	if night_hour > MOON_SET:
		return Vector2.INF
	return _arc((night_hour - MOON_RISE) / (MOON_SET - MOON_RISE))


## How visible the stars are: 0 by day, 1 at night, fading with the dusk and the dawn.
static func star_alpha(hour: float) -> float:
	return clampf((night_amount(hour) - STARS_FROM) / (STARS_FULL - STARS_FROM), 0.0, 1.0)


static func _arc(progress: float) -> Vector2:
	return Vector2(
		lerpf(SKY_X.x, SKY_X.y, progress), HORIZON_Y - SKY_PEAK * sin(PI * progress)
	)


## Hour of day as a float, including the fraction of the current tick.
static func hour_of_world(world: WorldState, config: SimConfig) -> float:
	var into_day: float = float(posmod(world.tick, config.ticks_per_day)) + world.tick_fraction
	return into_day * 24.0 / float(config.ticks_per_day)
