# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name GateGhost
extends Control
## The gate a finger is carrying. It floats above the finger so the finger never
## hides it, and snaps onto a socket when one is close. It takes no touches.

const HALO_ALPHA: float = 0.3

var active: bool = false
var cell_px: float = 128.0
var across: bool = false
var look: MapArt.Gate = MapArt.Gate.CLOSED

var _center: Vector2 = Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


## Shows the gate with its middle at a global point.
func show_at(global_point: Vector2, cell_size: float, runs_vertically: bool, new_look: MapArt.Gate) -> void:
	_center = get_global_transform().affine_inverse() * global_point
	cell_px = cell_size
	across = runs_vertically
	look = new_look
	active = true
	visible = true
	queue_redraw()


func hide_ghost() -> void:
	if active:
		active = false
		visible = false
		queue_redraw()


func _draw() -> void:
	if not active:
		return
	draw_circle(_center, cell_px * 0.55, Color(Palette.HONEY, HALO_ALPHA))
	MapArt.draw_gate_at(self, _center, cell_px, across, look)
