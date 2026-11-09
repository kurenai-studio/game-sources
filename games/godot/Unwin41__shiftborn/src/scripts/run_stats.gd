class_name RunStats
extends RefCounted
## What happened in one run: the score and the achievements read this.

const KILL_POINTS := 10
const SECOND_POINTS := 5
const PERFECT_POINTS := 100
const WIN_POINTS := 5000

var kills: int = 0
var seconds: float = 0.0
var shifts: int = 0
var perfects: int = 0
var evolutions: int = 0
var mini_bosses_killed: int = 0
var won: bool = false
## Health / max health when the run ended.
var health_share: float = 1.0


func score() -> int:
	return kills * KILL_POINTS + int(seconds) * SECOND_POINTS + perfects * PERFECT_POINTS \
		+ (WIN_POINTS if won else 0)


## One line per score part, e.g. "KILLS 120 x 10   1200".
func breakdown() -> PackedStringArray:
	var lines := PackedStringArray([
		_line("Kills", kills, KILL_POINTS),
		_line("Seconds", int(seconds), SECOND_POINTS),
		_line("Perfect shifts", perfects, PERFECT_POINTS),
	])
	if won:
		lines.append(("Boss defeated   %d" % WIN_POINTS).to_upper())
	return lines


static func _line(title: String, count: int, points: int) -> String:
	return ("%s %d x %d   %d" % [title, count, points, count * points]).to_upper()
