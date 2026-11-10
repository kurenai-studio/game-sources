class_name SunBeam
extends Node2D
# Луч света с неба (ульта Чемпиона). Копьё воткнулось — 1,5 секунды над ним
# светится столб-предупреждение, потом бьёт луч: ранит врагов и ломает постройки.

const DELAY := 1.5
const HALF := 46.0

var team := 0
var attacker: Node
var big := false
var _t := 0.0
var _done := false
var _warn: Polygon2D
var _beam: Polygon2D

func _ready() -> void:
	z_index = 4
	var h := HALF * (1.4 if big else 1.0)
	_warn = Polygon2D.new()
	_warn.polygon = PackedVector2Array([Vector2(-h * 0.4, -900), Vector2(h * 0.4, -900), Vector2(h * 0.4, 0), Vector2(-h * 0.4, 0)])
	_warn.color = Color(1.0, 0.95, 0.6, 0.0)
	add_child(_warn)
	_beam = Polygon2D.new()
	_beam.polygon = PackedVector2Array([Vector2(-h, -1000), Vector2(h, -1000), Vector2(h * 0.8, 10), Vector2(-h * 0.8, 10)])
	_beam.color = Color(1.0, 0.97, 0.75, 0.95)
	_beam.visible = false
	add_child(_beam)
	var core := Polygon2D.new()          # белая сердцевина луча
	core.polygon = PackedVector2Array([Vector2(-h * 0.35, -1000), Vector2(h * 0.35, -1000), Vector2(h * 0.25, 10), Vector2(-h * 0.25, 10)])
	core.color = Color(1, 1, 1, 0.95)
	_beam.add_child(core)
	# золотой круг на земле — сюда ударит луч
	Fx.rune_circle(get_parent(), global_position, h * 1.3, Color(1.0, 0.82, 0.3, 0.85), DELAY + 0.3, 0.3)

func _process(delta: float) -> void:
	_t += delta
	if _t < DELAY:
		_warn.color.a = 0.12 + 0.25 * (_t / DELAY) * absf(sin(_t * 12.0))
		if randf() < delta * 14.0:       # искорки опускаются по столбу
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-20, 20), -randf_range(80, 500)),
					Color(1.0, 0.9, 0.5), 1, 60.0, 3.0)
		return
	if not _done:
		_done = true
		_warn.visible = false
		_beam.visible = true
		_strike()
	_beam.modulate.a = clampf(1.0 - (_t - DELAY) / 0.45, 0.0, 1.0)
	_beam.scale.x = 1.0 + (_t - DELAY) * 0.6
	if _t > DELAY + 0.5:
		queue_free()

func _strike() -> void:
	var h := HALF * (1.4 if big else 1.0)
	var parent := get_parent()
	for n in parent.get_children():
		if n is Player and n.team != team and n.is_alive():
			var p: Vector2 = n.global_position
			if absf(p.x - global_position.x) < h + n.body_size.x / 2 and p.y < global_position.y + 30 and p.y > global_position.y - 900:
				n.take_damage(38 if big else 32, attacker)
		elif n is Destructible and n.shield_team != team:
			for k in 6:
				n.hit(global_position + Vector2(0, -20 - k * 45), Vector2.DOWN, 70, h, team,
						{"strict": true, "radial": true, "attacker": attacker})
	Util.flash(parent, global_position, h * 1.6, Color(1.0, 0.95, 0.6, 0.8))
	Fx.ring(parent, global_position, h * 3.2, Color(1.0, 0.9, 0.5, 0.9), 0.45, 8.0, 0.35)
	Fx.sparks(parent, global_position, Color(1.0, 0.88, 0.4), 16, 320.0, 6.0, true)
	Fx.cracks(parent, global_position, Color(0.25, 0.18, 0.1), h * 2.0)
