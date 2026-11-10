class_name HoverDwell
extends RefCounted
## Decides when a tooltip may show: only once the pointer has rested on the same thing for
## `DELAY_SECONDS`, so sweeping the pointer across the camp or panning never flickers names. Pure
## logic: the view says what is under the pointer and how long it has been.

const DELAY_SECONDS: float = 0.35

## The key of the thing under the pointer, or &"" for nothing.
var target: StringName = &""
var _elapsed: float = 0.0


## Tells it what is under the pointer now; a different thing starts the wait again.
func point_at(key: StringName) -> void:
	if key == target:
		return
	target = key
	_elapsed = 0.0


func clear() -> void:
	point_at(&"")


func advance(delta: float) -> void:
	if target != &"":
		_elapsed += delta


## Whether the pointer has rested long enough on something for its tooltip to be shown.
func is_ready() -> bool:
	return target != &"" and _elapsed >= DELAY_SECONDS
