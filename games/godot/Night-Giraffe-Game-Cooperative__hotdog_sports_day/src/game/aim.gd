class_name Aim
extends RefCounted
## A player's aim in the jumps and the put, the Track & Field way: hold the
## action button and a needle climbs; let go while it's in the green. How fast
## it climbs and how wide the green is go by the age band (Profile.rivals). At
## ages 5-7 it lets go by itself at the best angle, it takes off by
## itself if the board goes by, and nothing is a foul.
##
## Take-offs are timed to the line, not the beat: JUMP as close to the board
## (or the high jump's take-off spot) as you can.

const BANDS := {
	"gentle": {"speed": 45.0, "green": 10.0},
	"keen": {"speed": 65.0, "green": 7.0},
	"fierce": {"speed": 85.0, "green": 5.0},
	"legendary": {"speed": 105.0, "green": 4.0},
}


## Degrees a second the needle climbs.
static func speed(band: String) -> float:
	return float(BANDS.get(band, BANDS.gentle).speed)


## How far either side of the best angle counts as the green.
static func green(band: String) -> float:
	return float(BANDS.get(band, BANDS.gentle).green)


## The youngest get a hand: no fouls, and it lets go for them.
static func helps(band: String) -> bool:
	return band == "gentle" or not BANDS.has(band)


## How well a take-off was timed to its line: `off` metres from the best spot
## (negative: short of it), `over` whether it went past the line.
static func line_grade(off: float, over: bool) -> String:
	if over:
		return "ok"
	var d := absf(off)
	return "perfect" if d <= 0.35 else ("good" if d <= 0.9 else "ok")
