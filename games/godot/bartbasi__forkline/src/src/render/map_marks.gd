# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapMarks
extends Node2D
## The range circle, the towers a Bakery would boost, the selection ring and the hint
## ring. They sit under the towers and creatures. Internal to src/render/.

const CELL: float = 128.0

var range_cell: Vector2i = Vector2i(-1, -1)
var range_radius: float = 0.0
var boost_cells: Array[Vector2i] = []
var selection: Vector2i = Vector2i(-1, -1)
var hint: Vector2i = Vector2i(-1, -1)
var pulse: float = 1.0


func is_animated() -> bool:
	return hint.x >= 0


func set_pulse(value: float) -> void:
	pulse = value
	if hint.x >= 0:
		queue_redraw()


func _draw() -> void:
	if range_cell.x >= 0 and range_radius > 0.0:
		var c: Vector2 = (Vector2(range_cell) + Vector2(0.5, 0.5)) * CELL
		draw_circle(c, range_radius, Color(Palette.LANTERN, 0.13))
		draw_arc(c, range_radius, 0.0, TAU, 96, Palette.INK_LINE, CELL * 0.07, true)
		draw_arc(c, range_radius, 0.0, TAU, 96, Palette.ROUTE, CELL * 0.03, true)
	for b: Vector2i in boost_cells:
		MapArt.draw_highlight(self, b, CELL, 0.5)
	if selection.x >= 0:
		MapArt.draw_highlight(self, selection, CELL, 1.0)
	if hint.x >= 0:
		MapArt.draw_highlight(self, hint, CELL, pulse)
