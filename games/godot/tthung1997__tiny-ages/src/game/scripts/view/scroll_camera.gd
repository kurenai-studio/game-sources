class_name ScrollCamera
extends RefCounted
## A horizontal camera over a world wider than the viewport. Positions are the x of the
## viewport's left edge. Moves glide towards a target; dragging jumps straight to it. Pure
## logic with no nodes, so it is testable headless.

## How quickly a glide closes the gap (per second); higher is snappier.
const SMOOTHING: float = 12.0
## Closer than this to the target counts as arrived.
const SNAP_DISTANCE: float = 0.25

var min_x: float
var max_x: float
var target: float
var shown: float


func _init(p_min_x: float, p_max_x: float, start: float = 0.0) -> void:
	min_x = minf(p_min_x, p_max_x)
	max_x = maxf(p_min_x, p_max_x)
	target = clampf(start, min_x, max_x)
	shown = target


## Glides by `amount` from where the camera is heading.
func pan_by(amount: float) -> void:
	target = clampf(target + amount, min_x, max_x)


func glide_to(x: float) -> void:
	target = clampf(x, min_x, max_x)


## Moves there at once (dragging, and the first frame).
func jump_to(x: float) -> void:
	target = clampf(x, min_x, max_x)
	shown = target


## Advances the glide. Returns whether the shown position changed.
func step(delta: float) -> bool:
	if shown == target:
		return false
	var next: float = shown + (target - shown) * (1.0 - exp(-delta * SMOOTHING))
	if absf(target - next) < SNAP_DISTANCE:
		next = target
	var moved: bool = next != shown
	shown = next
	return moved


## Whether there is more world in that direction (-1 left, 1 right) from where it is heading.
func can_go(direction: int) -> bool:
	if direction < 0:
		return target > min_x + SNAP_DISTANCE
	return target < max_x - SNAP_DISTANCE


## The whole-pixel position to draw at, so pixel art never lands between pixels.
func pixel_x() -> int:
	return roundi(shown)


## Which page of the world the viewport is closest to, counting from 0 at the left.
func page_index(page_width: float) -> int:
	return roundi((shown - min_x) / page_width)
