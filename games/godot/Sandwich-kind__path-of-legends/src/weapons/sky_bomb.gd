class_name SkyBomb
extends Area2D
# Бомба «Мгновенной смерти» («Два дома») или раскалённый камень («Гора»).
# Падает с неба, на земле заранее видна красная отметка. При касании —
# взрыв, разрушающий постройки, и пожар вокруг.

var rock := false                # камень извержения вместо бомбы
var mark_at := Vector2(INF, INF)
var _vy := 250.0
var _mark: Node2D
var _done := false

func _ready() -> void:
	z_index = 6
	collision_layer = 0
	collision_mask = Layer.WORLD | Layer.PLAYER
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 14.0
	col.shape = cs
	add_child(col)
	if rock:
		var r := Polygon2D.new()
		r.polygon = PackedVector2Array([Vector2(-16, -6), Vector2(-6, -16), Vector2(10, -14), Vector2(17, 0),
				Vector2(8, 15), Vector2(-10, 13)])
		r.color = Color(0.3, 0.18, 0.12)
		add_child(r)
		var hot := Polygon2D.new()
		hot.polygon = Util.circle(7.0, 10)
		hot.color = Color(1.0, 0.55, 0.1)
		add_child(hot)
		var trail := Polygon2D.new()
		trail.polygon = PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(0, -70)])
		trail.color = Color(1.0, 0.5, 0.1, 0.6)
		add_child(trail)
	else:
		var b := Polygon2D.new()
		b.polygon = PackedVector2Array([Vector2(-11, -14), Vector2(11, -14), Vector2(13, 6), Vector2(0, 20), Vector2(-13, 6)])
		b.color = Color(0.2, 0.22, 0.24)
		add_child(b)
		var fin := Polygon2D.new()
		fin.polygon = PackedVector2Array([Vector2(-12, -26), Vector2(12, -26), Vector2(6, -14), Vector2(-6, -14)])
		fin.color = Color(0.5, 0.15, 0.12)
		add_child(fin)
	if mark_at.x != INF:
		_mark = Node2D.new()
		_mark.position = mark_at
		_mark.z_index = 6
		var ring := Line2D.new()
		var pts := Util.circle(36.0, 20)
		for i in pts.size():
			pts[i].y *= 0.35
		pts.append(pts[0])
		ring.points = pts
		ring.width = 4.0
		ring.default_color = Color(1.0, 0.2, 0.15, 0.85)
		_mark.add_child(ring)
		get_parent().call_deferred("add_child", _mark)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	_vy = minf(_vy + 1300.0 * delta, 1400.0)
	position.y += _vy * delta
	rotation += delta * (4.0 if rock else 0.0)
	if _mark and is_instance_valid(_mark):
		_mark.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
	if position.y > 5000.0:
		_boom()

func _on_body(b: Node) -> void:
	if b is Player and not b.is_alive():
		return
	_boom()

func _boom() -> void:
	if _done:
		return
	_done = true
	var parent := get_parent()
	if rock:
		Util.explode(parent, global_position, 90.0, 22, 25, 2, null, true)
	else:
		# мощный взрыв: пробивает стены домов, всё вокруг загорается
		Util.explode(parent, global_position, 175.0, 40, 320, 2, null, true)
		Util.flash(parent, global_position, 230.0, Color(1.0, 0.85, 0.4, 0.7))
		for k in 3:
			var fire := FireZone.new()
			fire.team = 2
			fire.position = global_position + Vector2((k - 1) * 90.0, -10.0)
			parent.call_deferred("add_child", fire)
	if _mark and is_instance_valid(_mark):
		_mark.queue_free()
	queue_free()
