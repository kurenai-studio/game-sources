class_name FxShape
extends Node2D
## Efeito visual desenhado proceduralmente (golpes, anéis, áreas, telegrafias).

enum Type { ARC, RING, DISC, TELEGRAPH, PILLAR, SPARK, BEAM }

var type: Type = Type.RING
var color := Color.WHITE
var radius := 30.0
var arc_degrees := 120.0
var lifetime := 0.3
var direction := Vector2.RIGHT
var follow: Node2D
var beam_end := Vector2.ZERO
var jagged := false
var _t := 0.0
var _jag_points := PackedVector2Array()


static func spawn(parent: Node, p_type: Type, pos: Vector2, p_color: Color, p_radius: float, p_life: float, dir := Vector2.RIGHT, arc := 120.0) -> FxShape:
	var f := FxShape.new()
	f.type = p_type
	f.color = p_color
	f.radius = p_radius
	f.lifetime = p_life
	f.direction = dir
	f.arc_degrees = arc
	f.position = pos
	f.z_index = 5 if p_type != Type.TELEGRAPH else -1
	parent.add_child(f)
	return f


## Raio entre dois pontos (jagged = relâmpago)
static func spawn_beam(parent: Node, from: Vector2, to: Vector2, p_color: Color, width: float, p_life: float, p_jagged := false) -> FxShape:
	var f := spawn(parent, Type.BEAM, from, p_color, width, p_life)
	f.beam_end = to - from
	f.jagged = p_jagged
	var l := Fx.make_light(p_color, 0.6, 1.0)
	l.position = f.beam_end * 0.5
	f.add_child(l)
	return f


func _process(delta: float) -> void:
	_t += delta
	if follow and is_instance_valid(follow):
		global_position = follow.global_position
	if _t >= lifetime:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / lifetime, 0.0, 1.0)
	match type:
		Type.ARC:
			var a0 := direction.angle() - deg_to_rad(arc_degrees) * 0.5
			var a1 := direction.angle() + deg_to_rad(arc_degrees) * 0.5
			var sweep := lerpf(a0, a1, minf(k * 2.0, 1.0))
			var c := color
			c.a = 1.0 - k
			for i in 3:
				var r := radius * (0.55 + i * 0.2)
				draw_arc(Vector2.ZERO, r, a0, sweep, 24, Color(c, c.a * (0.4 + i * 0.3)), 3.0 - i * 0.5, true)
		Type.RING:
			var c := color
			c.a = 1.0 - k
			draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * ease(k, 0.4)), 0, TAU, 48, c, 3.0 * (1.0 - k) + 1.0, true)
			draw_circle(Vector2.ZERO, radius * (0.3 + 0.7 * ease(k, 0.4)), Color(c, c.a * 0.2))
		Type.DISC:
			var c := color
			c.a = 0.35 * (1.0 - k * k)
			draw_circle(Vector2.ZERO, radius, c)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(color, 0.7 * (1.0 - k)), 1.5, true)
			for i in 6:
				var ang := _t * 2.5 + i * TAU / 6.0
				draw_circle(Vector2(cos(ang), sin(ang)) * radius * 0.8, 2.5, Color(color, 1.0 - k))
		Type.TELEGRAPH:
			draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
			draw_circle(Vector2.ZERO, radius * k, Color(color, 0.25))
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(color, 0.8), 1.5, true)
		Type.PILLAR:
			# Feixe vertical com núcleo brilhante e halo
			var a := 1.0 - k
			var w := maxf(radius * 0.45 * (1.0 - k * 0.6), 2.0)
			for i in 4:
				var ww := w * (1.0 - i * 0.22)
				var col := color.lightened(i * 0.2)
				draw_rect(Rect2(-ww * 0.5, -140, ww, 140), Color(col, a * (0.12 + i * 0.12)))
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
			draw_circle(Vector2.ZERO, radius * (0.4 + k * 0.6), Color(color, a * 0.35))
			draw_arc(Vector2.ZERO, radius * (0.4 + k * 0.6), 0, TAU, 32, Color(color.lightened(0.4), a), 1.5, true)
			draw_set_transform(Vector2.ZERO)
		Type.BEAM:
			var a := 1.0 - k
			if jagged:
				if _jag_points.is_empty() or randf() < 0.3:
					_jag_points.clear()
					var n := maxi(int(beam_end.length() / 8.0), 2)
					var nrm := beam_end.orthogonal().normalized()
					for i in n + 1:
						var off := 0.0 if i == 0 or i == n else randf_range(-4, 4)
						_jag_points.append(beam_end * (float(i) / n) + nrm * off)
				draw_polyline(_jag_points, Color(color, a * 0.5), radius + 2.0, true)
				draw_polyline(_jag_points, Color(color.lightened(0.6), a), maxf(radius * 0.5, 1.0), true)
			else:
				draw_line(Vector2.ZERO, beam_end, Color(color, a * 0.35), radius * 2.0 * (1.0 - k * 0.5), true)
				draw_line(Vector2.ZERO, beam_end, Color(color, a * 0.7), radius, true)
				draw_line(Vector2.ZERO, beam_end, Color(color.lightened(0.7), a), maxf(radius * 0.35, 1.0), true)
		Type.SPARK:
			var c := color
			c.a = 1.0 - k
			for i in 8:
				var ang := i * TAU / 8.0 + 0.3
				var d: Vector2 = Vector2(cos(ang), sin(ang))
				draw_line(d * radius * k * 0.4, d * radius * (0.3 + k), c, 1.5)
