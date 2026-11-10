class_name RootTrap
extends Node2D
# ---------- Хватающие корни (Жуткий лес) ----------
# Узел чёрных корней на тропе. Кто на него наступит — герой или противник, —
# того через мгновение оплетают корни: держат на месте и немного ранят.
# Потом корням нужно время, чтобы снова уползти под землю.

var width := 110.0
var _cd := 0.0
var _vis: Node2D
var _t := 0.0

func _ready() -> void:
	z_index = 1
	_vis = Node2D.new()
	add_child(_vis)
	for k in 7:
		var r := Line2D.new()
		var x0 := -width / 2 + k * width / 6.0
		r.points = PackedVector2Array([Vector2(x0, 2), Vector2(x0 + randf_range(-10, 10), -6 - randf() * 6), Vector2(x0 + randf_range(-16, 16), -2)])
		r.width = 4.0
		r.default_color = Color(0.14, 0.10, 0.10)
		_vis.add_child(r)
	var eye := Polygon2D.new()             # красноватый отсвет в щели
	eye.polygon = Util.circle(4.0, 8)
	eye.color = Color(0.9, 0.2, 0.2, 0.5)
	eye.position = Vector2(0, -2)
	_vis.add_child(eye)

func _physics_process(delta: float) -> void:
	_t += delta
	_cd -= delta
	_vis.modulate.a = 1.0 if _cd <= 0.0 else 0.45
	if _cd > 0.0:
		return
	for n in get_parent().get_children():
		if not (n is Player) or not n.is_alive() or n.flying:
			continue
		var feet: float = n.global_position.y + n.body_size.y / 2
		if absf(n.global_position.x - global_position.x) < width / 2 and absf(feet - global_position.y) < 14.0:
			_cd = 5.0
			var rs := RootSpike.new()
			rs.team = -1                    # корни хватают всех
			rs.damage = 8
			rs.warn = 0.35
			rs.half = width / 2
			rs.root_time = 1.3
			rs.position = global_position
			get_parent().add_child(rs)
			return
