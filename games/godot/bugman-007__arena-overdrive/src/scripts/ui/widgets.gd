class_name Widgets
extends RefCounted
## Small custom-drawn controls used across menus and the HUD.


## Rotating polygon preview of a character / enemy with glow.
class ShapeIcon extends Control:
	var sides: int = 6
	var color: Color = Color.WHITE
	var spin: float = 0.6
	var _t: float = 0.0

	func _init(s: int = 6, c: Color = Color.WHITE, min_size: float = 64.0) -> void:
		sides = s
		color = c
		custom_minimum_size = Vector2(min_size, min_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta * spin
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.32
		draw_circle(c, r * 1.5, Color(color, 0.12))
		draw_arc(c, r * 1.45, _t, _t + PI * 1.2, 32, Color(color, 0.5), 2.0, true)
		if sides >= 3:
			var pts := PackedVector2Array()
			for i in sides:
				pts.append(c + Vector2.RIGHT.rotated(-_t + TAU * i / sides) * r)
			draw_colored_polygon(pts, Color(color, 0.85))
			pts.append(pts[0])
			draw_polyline(pts, Color.WHITE, 2.0, true)
		else:
			draw_circle(c, r * 0.8, Color(color, 0.85))
			for i in 3:
				draw_circle(c + Vector2.RIGHT.rotated(_t * 3.0 + TAU * i / 3.0) * r * 1.15, r * 0.16, color.lightened(0.4))
		draw_circle(c, r * 0.25, Color.WHITE)


## Circular cooldown indicator with a key hint.
class RadialCooldown extends Control:
	var ratio: float = 1.0
	var color: Color = Color.WHITE
	var caption: String = ""

	func _init(c: Color = Color.WHITE, text_value: String = "") -> void:
		color = c
		caption = text_value
		custom_minimum_size = Vector2(54, 54)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		var ready := ratio >= 1.0
		draw_circle(c, r, Color(0, 0, 0, 0.55))
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * ratio, 48, Color(color, 1.0 if ready else 0.6), 4.0, true)
		if ready:
			draw_circle(c, r - 6.0, Color(color, 0.18))
		var font := get_theme_default_font()
		var fs := 15
		var tsize := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, c + Vector2(-tsize.x / 2.0, fs * 0.35), caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE if ready else UiTheme.MUTED)


## Symbol for an upgrade's stat.
class UpgradeIcon extends Control:
	var stat: StringName
	var color: Color = Color.WHITE
	var _t: float = 0.0

	func _init(s: StringName = &"", c: Color = Color.WHITE) -> void:
		stat = s
		color = c
		custom_minimum_size = Vector2(96, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := 30.0 + sin(_t * 3.0) * 1.5
		draw_circle(c, r + 12.0, Color(color, 0.1))
		draw_arc(c, r + 6.0, 0.0, TAU, 48, Color(color, 0.6), 2.0, true)
		var w := Color.WHITE
		match stat:
			&"damage", &"crit_mult":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -22), c + Vector2(10, -4), c + Vector2(0, -2), c + Vector2(8, 22), c + Vector2(-10, 2), c + Vector2(0, 0)]), color)
			&"fire_rate", &"projectile_speed":
				for i in 3:
					draw_colored_polygon(PackedVector2Array([c + Vector2(-16 + i * 12, -12), c + Vector2(-4 + i * 12, 0), c + Vector2(-16 + i * 12, 12)]), Color(color, 0.5 + i * 0.25))
			&"projectile_count":
				for i in 3:
					draw_line(c + Vector2(-16, 0), c + Vector2(18, 0).rotated((i - 1) * 0.5), color, 4.0, true)
					draw_circle(c + Vector2(18, 0).rotated((i - 1) * 0.5), 4.0, w)
			&"max_hp", &"regen":
				draw_rect(Rect2(c + Vector2(-6, -18), Vector2(12, 36)), color)
				draw_rect(Rect2(c + Vector2(-18, -6), Vector2(36, 12)), color)
			&"armor":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -16), c + Vector2(16, -16), c + Vector2(14, 6), c + Vector2(0, 20), c + Vector2(-14, 6)]), color)
			&"crit_chance":
				draw_arc(c, 16.0, 0.0, TAU, 32, color, 3.0, true)
				draw_circle(c, 5.0, w)
				for i in 4:
					draw_line(c + Vector2.RIGHT.rotated(i * PI / 2) * 10.0, c + Vector2.RIGHT.rotated(i * PI / 2) * 22.0, color, 3.0)
			&"pierce":
				draw_line(c + Vector2(-22, 0), c + Vector2(22, 0), color, 4.0)
				draw_rect(Rect2(c + Vector2(-6, -14), Vector2(4, 28)), Color(w, 0.6))
				draw_rect(Rect2(c + Vector2(6, -14), Vector2(4, 28)), Color(w, 0.6))
			&"move_speed", &"dash_cooldown":
				for i in 3:
					draw_line(c + Vector2(-20, -10 + i * 10), c + Vector2(14 - i * 6, -10 + i * 10), Color(color, 1.0 - i * 0.25), 4.0, true)
			&"pickup_radius":
				draw_arc(c + Vector2(0, 2), 14.0, PI, TAU, 24, color, 8.0)
				draw_rect(Rect2(c + Vector2(-18, 2), Vector2(8, 12)), color)
				draw_rect(Rect2(c + Vector2(10, 2), Vector2(8, 12)), color)
				draw_rect(Rect2(c + Vector2(-18, 10), Vector2(8, 5)), w)
				draw_rect(Rect2(c + Vector2(10, 10), Vector2(8, 5)), w)
			_:
				for i in 6:
					draw_line(c, c + Vector2.RIGHT.rotated(i * TAU / 6 + _t) * 20.0, color, 3.0, true)
				draw_circle(c, 7.0, w)
