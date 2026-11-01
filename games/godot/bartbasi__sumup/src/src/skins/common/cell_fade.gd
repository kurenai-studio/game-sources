extends RefCounted
## A per cell highlight that eases on and off: the chained look, the
## joinable highlight, press feedback and Swap's selection. Each cell holds
## a display value from 0 (off) to 1 (on). Turning a cell on eases it toward
## 1 over the skin's in motion, turning it off eases it toward 0 over the out
## motion, from wherever it was. Arrays are made once per board size.

const MotionMath: GDScript = preload("res://src/skins/common/motion_math.gd")

## Display value per cell, 0 to 1, as the painters read it.
var value: PackedFloat32Array = PackedFloat32Array()

var _skin: SkinData = null
var _in_motion: StringName = &""
var _out_motion: StringName = &""
var _in_length: float = 0.0
var _out_length: float = 0.0
var _on: PackedByteArray = PackedByteArray()
var _from: PackedFloat32Array = PackedFloat32Array()
## Linear progress of the current change, 1 when settled.
var _progress: PackedFloat32Array = PackedFloat32Array()
var _moving: bool = false


func setup(skin: SkinData, count: int, in_motion: StringName, out_motion: StringName) -> void:
	_skin = skin
	_in_motion = in_motion
	_out_motion = out_motion
	_in_length = skin.duration(in_motion)
	_out_length = skin.duration(out_motion)
	value.resize(count)
	_on.resize(count)
	_from.resize(count)
	_progress.resize(count)
	value.fill(0.0)
	_on.fill(0)
	_from.fill(0.0)
	_progress.fill(1.0)
	_moving = false


func is_on(index: int) -> bool:
	return _on[index] != 0


## True while any cell is still easing.
func is_moving() -> bool:
	return _moving


## Turns a cell on or off, easing from its current display value.
func set_on(index: int, on: bool) -> void:
	var flag: int = 1 if on else 0
	if _on[index] == flag:
		return
	_on[index] = flag
	_from[index] = value[index]
	var length: float = _in_length if on else _out_length
	if length <= 0.0:
		_progress[index] = 1.0
		value[index] = float(flag)
		return
	_progress[index] = 0.0
	_moving = true


## Turns every cell off at once, with no easing.
func clear_now() -> void:
	value.fill(0.0)
	_on.fill(0)
	_from.fill(0.0)
	_progress.fill(1.0)
	_moving = false


## Turns one cell off at once, with no easing.
func clear_cell_now(index: int) -> void:
	value[index] = 0.0
	_on[index] = 0
	_from[index] = 0.0
	_progress[index] = 1.0


## Advances every change by delta seconds. Returns true while any cell was
## still changing at the start of this step.
func step(delta: float) -> bool:
	if not _moving:
		return false
	var still: bool = false
	for index: int in _progress.size():
		if _progress[index] >= 1.0:
			continue
		var on: bool = _on[index] != 0
		var length: float = _in_length if on else _out_length
		var progress: float = minf(1.0, _progress[index] + delta / length)
		_progress[index] = progress
		var target: float = 1.0 if on else 0.0
		var amount: float = MotionMath.eased(_skin, _in_motion if on else _out_motion, progress)
		value[index] = lerpf(_from[index], target, amount)
		if progress < 1.0:
			still = true
	_moving = still
	return true
