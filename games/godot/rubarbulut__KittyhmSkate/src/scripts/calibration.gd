extends RefCounted
## Robust tap-to-audio calibration. Positive measured lateness requires a
## negative input offset, because game judgement adds offset to song time.

const BEAT: float = 0.6
const DURATION: float = 24.0*BEAT
var errors: Array[float] = []
var seen: Dictionary = {}
var done: bool = false
var flash: float = 0.0
var last_error: float = 0.0

func reset() -> void:
	errors.clear()
	seen.clear()
	done = false
	flash = 0.0
	last_error = 0.0

func tap(seconds: float) -> void:
	if done:
		return
	var beat: int = roundi(seconds/BEAT)
	if beat < 4 or beat >= 20 or seen.has(beat):
		return
	var error: float = seconds-beat*BEAT
	if absf(error) > 0.26:
		return
	seen[beat] = true
	errors.append(error)
	last_error = error
	flash = 1.0

func valid() -> bool:
	return errors.size() >= 8 and spread() < 0.080

func offset() -> float:
	return clampf(-_median(errors),-0.2,0.2)

func spread() -> float:
	if errors.is_empty():
		return 1.0
	var center: float = _median(errors)
	var deviations: Array[float] = []
	for value in errors:
		deviations.append(absf(value-center))
	return _median(deviations)

func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var middle: int = sorted.size()/2
	return sorted[middle] if sorted.size()%2 else (sorted[middle-1]+sorted[middle])*0.5
