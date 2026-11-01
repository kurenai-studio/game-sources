class_name Glyphs
extends RefCounted
## The type marks drawn on banners and in the roster.

const K := UnitTypes.Kind


## Draw `kind`'s mark centred on `c`, fitting a circle of radius `r`.
static func draw(ci: CanvasItem, kind: int, c: Vector2, r: float, color: Color) -> void:
	var w := maxf(1.2, r * 0.17)
	match kind:
		K.SWORDS:
			var a := Vector2(r * 0.55, r * 0.55)
			ci.draw_line(c - a, c + a, color, w)
			ci.draw_line(c + Vector2(-a.x, a.y), c + Vector2(a.x, -a.y), color, w)
			ci.draw_line(c + Vector2(-r * 0.62, r * 0.28), c + Vector2(-r * 0.28, r * 0.62), color, w)
			ci.draw_line(c + Vector2(r * 0.62, r * 0.28), c + Vector2(r * 0.28, r * 0.62), color, w)
		K.PIKES:
			ci.draw_line(c + Vector2(0, r * 0.7), c + Vector2(0, -r * 0.25), color, w)
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r * 0.72), c + Vector2(-r * 0.24, -r * 0.2), c + Vector2(r * 0.24, -r * 0.2),
			]), color)
		K.ARCHERS:
			ci.draw_arc(c + Vector2(-r * 0.12, 0), r * 0.62, -PI * 0.42, PI * 0.42, 12, color, w)
			var top := c + Vector2(-r * 0.12, 0) + Vector2.from_angle(-PI * 0.42) * r * 0.62
			var bottom := c + Vector2(-r * 0.12, 0) + Vector2.from_angle(PI * 0.42) * r * 0.62
			ci.draw_line(top, bottom, color, w * 0.6)
			ci.draw_line(c + Vector2(-r * 0.55, 0), c + Vector2(r * 0.62, 0), color, w * 0.8)
		K.CAVALRY:
			ci.draw_arc(c + Vector2(0, r * 0.08), r * 0.5, PI * 0.85, PI * 2.15, 14, color, w * 1.3)
			ci.draw_line(c + Vector2(-r * 0.62, r * 0.5), c + Vector2(-r * 0.3, r * 0.5), color, w)
			ci.draw_line(c + Vector2(r * 0.3, r * 0.5), c + Vector2(r * 0.62, r * 0.5), color, w)
		K.CANNONS:
			ci.draw_arc(c + Vector2(-r * 0.1, r * 0.22), r * 0.36, 0, TAU, 14, color, w)
			ci.draw_circle(c + Vector2(-r * 0.1, r * 0.22), r * 0.1, color)
			ci.draw_line(c + Vector2(-r * 0.2, r * 0.05), c + Vector2(r * 0.66, -r * 0.48), color, w * 1.6)
		K.MUSKETS, K.RIFLES, K.LINE:
			var muzzle := c + Vector2(r * 0.66, -r * 0.5)
			var lock := c + Vector2(-r * 0.2, r * 0.16)
			ci.draw_line(lock, muzzle, color, w)
			ci.draw_line(lock, c + Vector2(-r * 0.62, r * 0.52), color, w * 2.2)
			ci.draw_circle(muzzle + Vector2(-r * 0.04, -r * 0.2), r * 0.13, color)
			if kind != K.MUSKETS:
				# A bayonet past the muzzle.
				ci.draw_line(muzzle, muzzle + Vector2(r * 0.22, -r * 0.17), color, w * 0.7)
		K.GENERAL:
			var pts := PackedVector2Array()
			for i in 10:
				var rad := r * (0.68 if i % 2 == 0 else 0.3)
				pts.append(c + Vector2.from_angle(-PI * 0.5 + i * PI / 5.0) * rad)
			ci.draw_colored_polygon(pts, color)


## A banner: team disc, white rim, the type mark, a ring for strength.
static func banner(ci: CanvasItem, kind: int, team: int, c: Vector2, r: float, strength: float, wavering: bool, routing: bool, selected: bool) -> void:
	var fill: Color = Palette.TEAM[team]
	if routing:
		fill = fill.lerp(Color(0.85, 0.85, 0.85), 0.55)
	elif wavering:
		fill = fill.lerp(Color.WHITE, 0.35 + 0.35 * sin(Time.get_ticks_msec() / 90.0))
	ci.draw_circle(c + Vector2(0, r * 0.12), r + 1.5, Color(0, 0, 0, 0.3))
	ci.draw_circle(c, r + 2.2, Palette.GOLD if selected else Color.WHITE)
	ci.draw_circle(c, r, fill)
	if routing:
		ci.draw_line(c + Vector2(0, r * 0.15), c + Vector2(0, -r * 0.6), Color.WHITE, maxf(1.5, r * 0.22))
		ci.draw_circle(c + Vector2(0, r * 0.5), r * 0.13, Color.WHITE)
	else:
		draw(ci, kind, c, r, Color.WHITE)
	var ring_r := r + 4.5
	ci.draw_arc(c, ring_r, 0, TAU, 28, Color(0, 0, 0, 0.35), 2.2)
	if strength > 0.0:
		ci.draw_arc(c, ring_r, -PI * 0.5, -PI * 0.5 + TAU * strength, 28, Palette.GOLD if selected else Color(1, 1, 1, 0.9), 2.2)
