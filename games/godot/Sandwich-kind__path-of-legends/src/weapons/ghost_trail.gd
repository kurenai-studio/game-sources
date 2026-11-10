class_name GhostTrail
extends Node2D
# След МЕГА-зачарованной стрелы Охотницы: светящаяся линия, которая
# разгорается и взрывается по всей длине — волной от начала к концу.

var points := PackedVector2Array()
var team := 0
var attacker: Node
var damage := 30
var delay := 0.35
var _line: Line2D
var _t := 0.0
var _boomed := false

func _ready() -> void:
	z_index = 5
	_line = Line2D.new()
	_line.points = points
	_line.width = 10.0
	_line.default_color = Color(0.55, 1.0, 0.8, 0.6)
	add_child(_line)

func _process(delta: float) -> void:
	_t += delta
	if not _boomed:
		# разгорается: пульсирует всё быстрее и светлеет
		var k := clampf(_t / delay, 0.0, 1.0)
		_line.width = 10.0 + 8.0 * k + 4.0 * sin(_t * (20.0 + 40.0 * k))
		_line.default_color = Color(0.55, 1.0, 0.8, 0.6).lerp(Color(1.0, 1.0, 0.9, 0.95), k)
		if _t >= delay:
			_boom()
		return

func _boom() -> void:
	_boomed = true
	var parent := get_parent()
	# урон каждому врагу у линии — один раз
	for n in parent.get_children():
		if n is Player and n.team != team and n.is_alive():
			for i in range(1, points.size()):
				var c := Geometry2D.get_closest_point_to_segment(n.global_position, points[i - 1], points[i])
				if c.distance_to(n.global_position) < 60.0:
					n.take_damage(damage, attacker)
					break
	# взрывы волной вдоль следа
	var total := 0.0
	var acc := 0.0
	var samples: Array = []
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		acc += seg
		total += seg
		if acc >= 55.0:
			acc = 0.0
			samples.append([points[i], total])
	var dur := 0.35
	for s in samples:
		var at: Vector2 = s[0]
		var when: float = dur * float(s[1]) / maxf(total, 1.0)
		get_tree().create_timer(when).timeout.connect(_blast_at.bind(at))
	var t := _line.create_tween()
	t.tween_property(_line, "modulate:a", 0.0, dur + 0.2)
	t.tween_callback(queue_free)

func _blast_at(at: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	for n in parent.get_children():
		if n is Destructible and n.shield_team != team and not n.background \
				and n.global_position.distance_to(at) < 500.0:
			n.hit(at, Vector2.ZERO, 30, 34.0, team, {"strict": true, "radial": true, "attacker": attacker})
	Util.flash(parent, at, 38.0, Color(0.7, 1.0, 0.85))
	Fx.sparks(parent, at, Color(0.6, 1.0, 0.8), 4, 160.0, 4.0)
