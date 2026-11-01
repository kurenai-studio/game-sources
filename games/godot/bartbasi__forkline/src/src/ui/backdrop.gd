# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Backdrop
extends Control
## The dusk sky behind every menu screen: a gradient, a moon, a few stars and
## three rows of hills. The lowest band is flat and dark, so quiet text on it
## keeps its contrast. Drawn in code from the Palette.

const STARS: int = 36


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return
	var sky: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
	var colors: PackedColorArray = PackedColorArray([Palette.SKY_TOP, Palette.SKY_TOP, Palette.SKY_MID, Palette.SKY_MID])
	draw_polygon(sky, colors)
	for i: int in STARS:
		var hash_a: int = (i * 7919 + 13) % 1000
		var hash_b: int = (i * 104729 + 71) % 1000
		var p: Vector2 = Vector2(w * float(hash_a) / 1000.0, h * 0.55 * float(hash_b) / 1000.0)
		draw_circle(p, 2.0 + float(i % 3), Color(Palette.STAR, 0.35 + 0.1 * float(i % 4)))
	draw_circle(Vector2(w * 0.82, h * 0.10), 62.0, Palette.MOON)
	draw_circle(Vector2(w * 0.82 + 22.0, h * 0.10 - 12.0), 52.0, Palette.SKY_TOP.lerp(Palette.SKY_MID, 0.1))
	_hills(w, h, 0.80, 38.0, Palette.HILL_FAR, 0.0)
	_hills(w, h, 0.86, 46.0, Palette.HILL_MID, 1.7)
	_hills(w, h, 0.92, 40.0, Palette.HILL_NEAR, 3.1)
	draw_rect(Rect2(0.0, h * 0.94, w, h * 0.06 + 2.0), Palette.HILL_NEAR)


func _hills(w: float, h: float, base: float, amp: float, col: Color, phase: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 24
	for i: int in steps + 1:
		var x: float = w * float(i) / float(steps)
		pts.append(Vector2(x, h * base + sin(x / w * 5.0 + phase) * amp))
	pts.append(Vector2(w, h))
	pts.append(Vector2(0.0, h))
	draw_colored_polygon(pts, col)
