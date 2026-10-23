extends Resource
class_name WaveTimeline

@export var id: StringName = &""
@export var display_name: String = ""
@export var waves: Array[Resource] = []
@export var loop_last_wave: bool = true


func is_empty() -> bool:
	return waves.is_empty()


func get_wave_count() -> int:
	return waves.size()


func get_wave(index: int) -> Resource:
	if waves.is_empty():
		return null

	var safe_index := maxi(index, 0)
	if safe_index >= waves.size():
		return waves.back() if loop_last_wave else null

	return waves[safe_index]
