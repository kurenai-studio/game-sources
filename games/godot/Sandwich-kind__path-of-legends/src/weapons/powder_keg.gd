class_name PowderKeg
extends Node2D
# ---------- Бочка с порохом (Атаман) ----------
# Катится по земле в сторону героя, фитиль горит. Взрывается, если врежется
# в героя или стену, или когда догорит фитиль. Её можно перепрыгнуть.

const R := 18.0
var dir := 1.0
var speed := 380.0
var team := 1
var attacker: Node
var damage := 22
var fuse := 3.2
var _vis: Node2D
var _spark: Polygon2D
var _vy := 0.0
var _done := false

func _ready() -> void:
	z_index = 2
	_vis = Node2D.new()
	add_child(_vis)
	var body := Polygon2D.new()
	body.polygon = Util.circle(R, 18)
	body.color = Color(0.52, 0.34, 0.18)
	_vis.add_child(body)
	for k in 3:                      # доски
		var l := Line2D.new()
		l.points = PackedVector2Array([Vector2(-R + 3, -R * 0.5 + k * R * 0.5), Vector2(R - 3, -R * 0.5 + k * R * 0.5)])
		l.width = 1.5
		l.default_color = Color(0.38, 0.24, 0.12)
		_vis.add_child(l)
	for x in [-R * 0.55, R * 0.55]:  # железные обручи
		var hoop := Line2D.new()
		hoop.points = PackedVector2Array([Vector2(x, -R * 0.9), Vector2(x, R * 0.9)])
		hoop.width = 3.0
		hoop.default_color = Color(0.3, 0.3, 0.34)
		_vis.add_child(hoop)
	var mark := Polygon2D.new()      # нарисованный череп-предупреждение
	mark.polygon = Util.circle(4.0, 8)
	mark.color = Color(0.9, 0.88, 0.8)
	_vis.add_child(mark)
	_spark = Polygon2D.new()
	_spark.polygon = Util.circle(3.0, 8)
	_spark.color = Color(1.0, 0.85, 0.3)
	_spark.position = Vector2(0, -R - 6)
	add_child(_spark)

func _physics_process(delta: float) -> void:
	if _done:
		return
	fuse -= delta
	_spark.scale = Vector2.ONE * (1.0 + 0.5 * sin(fuse * 30.0))
	if fmod(fuse, 0.12) < delta:
		Fx.sparks(get_parent(), global_position + Vector2(0, -R - 6), Color(1.0, 0.7, 0.3), 2, 80.0, 2.0, true)
	var space := get_world_2d().direct_space_state
	# земля под бочкой
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, R + 6), Layer.WORLD | Layer.FRAME)
	var g := space.intersect_ray(q)
	if g.is_empty():
		_vy += 1400.0 * delta
		position.y += _vy * delta
	else:
		_vy = 0.0
		position.y = g["position"].y - R
	# стена впереди — взрыв
	var w := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(dir * (R + 6), 0), Layer.WORLD | Layer.FRAME))
	if not w.is_empty() and not Util.is_one_way(w["collider"]):
		_boom()
		return
	position.x += dir * speed * delta
	_vis.rotation += dir * speed * delta / R
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive():
			var dd: Vector2 = n.global_position - global_position
			if absf(dd.x) < n.body_size.x / 2 + R and absf(dd.y) < n.body_size.y / 2 + R * 0.6:
				_boom()
				return
	if fuse <= 0.0:
		_boom()

func _boom() -> void:
	_done = true
	var world := get_parent()
	Util.explode(world, global_position, 125.0, damage, 45, team, attacker if is_instance_valid(attacker) else null, true)
	Fx.ring(world, global_position, 130.0, Color(1.0, 0.6, 0.2, 0.9), 0.35, 7.0)
	Fx.sparks(world, global_position, Color(1.0, 0.6, 0.2), 16, 300.0, 5.0)
	queue_free()
