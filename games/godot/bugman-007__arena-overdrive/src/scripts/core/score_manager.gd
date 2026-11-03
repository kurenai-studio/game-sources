class_name ScoreManager
extends RefCounted
## Score with a decaying kill combo. Multiplier grows 5% per combo step up to x3.

signal score_changed(score: int)
signal combo_changed(combo: int, multiplier: float)

const COMBO_WINDOW := 2.5
const MAX_COMBO_STEPS := 40

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var _timer: float = 0.0


func multiplier() -> float:
	return 1.0 + minf(combo, MAX_COMBO_STEPS) * 0.05


func add_kill(base_points: int) -> int:
	combo += 1
	max_combo = maxi(max_combo, combo)
	_timer = COMBO_WINDOW
	var gained := int(round(base_points * multiplier()))
	score += gained
	combo_changed.emit(combo, multiplier())
	score_changed.emit(score)
	return gained


func add_bonus(points: int) -> void:
	score += points
	score_changed.emit(score)


func combo_time_ratio() -> float:
	return clampf(_timer / COMBO_WINDOW, 0.0, 1.0)


func tick(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer -= delta
	if _timer <= 0.0:
		combo = 0
		combo_changed.emit(combo, multiplier())


func reset() -> void:
	score = 0
	combo = 0
	max_combo = 0
	_timer = 0.0
	score_changed.emit(score)
	combo_changed.emit(combo, multiplier())
