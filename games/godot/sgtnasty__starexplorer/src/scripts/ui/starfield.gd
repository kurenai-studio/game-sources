# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Starfield
extends Control
## Slowly drifting parallax starfield drawn behind every screen.

const COUNT := 140

var _stars: Array[Vector3] = []  # x, y, depth (speed and brightness)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in COUNT:
		_stars.append(Vector3(rng.randf() * 640.0, rng.randf() * 360.0, rng.randf_range(0.2, 1.0)))


func _process(delta: float) -> void:
	var w := maxf(size.x, 1.0)
	for i in _stars.size():
		var s := _stars[i]
		s.x -= s.z * 6.0 * delta
		if s.x < 0.0:
			s.x += w
		_stars[i] = s
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UIKit.BG)
	for s in _stars:
		var c := Color(0.6, 0.7, 1.0, s.z)
		draw_rect(Rect2(floorf(s.x), floorf(s.y), 1, 1), c)
