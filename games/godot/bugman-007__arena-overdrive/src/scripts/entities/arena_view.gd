class_name ArenaView
extends Node2D
## Draws obstacle pillars and animated hazard zones for a generated layout.

var layout: Dictionary
var theme_data: Dictionary
var t: float = 0.0


static func shock_active(time: float) -> bool:
	return sin(time * 2.2) > 0.2


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if layout.is_empty():
		return
	var accent: Color = theme_data["accent"]
	for h: Dictionary in layout["hazards"]:
		var r: Rect2 = h["rect"]
		match int(h["type"]):
			ArenaGenerator.Hazard.BURN:
				var c := Color(1.0, 0.35, 0.15)
				draw_rect(r, Color(c, 0.16 + 0.06 * sin(t * 3.0)))
				var x := r.position.x + fmod(t * 30.0, 28.0)
				while x < r.end.x:
					draw_line(Vector2(x, r.position.y), Vector2(minf(x + 14.0, r.end.x), r.position.y + minf(14.0, r.size.y)), Color(c, 0.25), 2.0)
					x += 28.0
				draw_rect(r, Color(c, 0.7), false, 2.0)
			ArenaGenerator.Hazard.SLOW:
				var c := Color(0.6, 0.9, 1.0)
				draw_rect(r, Color(c, 0.14))
				for i in 14:
					var p := r.position + Vector2(fmod(i * 73.0 + t * 12.0, r.size.x), fmod(i * 41.0 + t * 8.0, r.size.y))
					draw_circle(p, 2.0, Color(c, 0.5))
				draw_rect(r, Color(c, 0.6), false, 2.0)
			ArenaGenerator.Hazard.SHOCK:
				var c := Color(0.75, 0.45, 1.0)
				var on := shock_active(t)
				draw_rect(r, Color(c, 0.3 if on else 0.08))
				if on:
					for i in 4:
						var y := r.position.y + r.size.y * (i + 0.5) / 4.0
						var pts := PackedVector2Array()
						for k in 9:
							pts.append(Vector2(r.position.x + r.size.x * k / 8.0, y + randf_range(-8, 8)))
						draw_polyline(pts, Color(1, 1, 1, 0.6), 1.5)
				draw_rect(r, Color(c, 0.8 if on else 0.4), false, 2.0)
	for o: Rect2 in layout["obstacles"]:
		draw_rect(o.grow(10.0), Color(accent, 0.07))
		draw_rect(o, Color(0.09, 0.11, 0.18))
		draw_rect(Rect2(o.position, Vector2(o.size.x, 6)), Color(accent, 0.25))
		draw_rect(o, Color(accent, 0.65), false, 2.0)
