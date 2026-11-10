class_name StoryBolt
extends Node2D
# Снаряд героя Истории: камень пращи или огненный шар.
# Сам сообщает набору героя, каким навыком нанесён урон (для роста навыков).

var kit: StoryKit
var kind := "stone"          # stone, fireball
var velocity := Vector2.ZERO
var gravity := 500.0
var damage := 8
var _life := 2.5
var _vis: Node2D
var _trail: Line2D

func _ready() -> void:
	z_index = 4
	_vis = Node2D.new()
	add_child(_vis)
	if kind == "fireball":
		gravity = 0.0
		for r in [[11.0, Color(1.0, 0.35, 0.05, 0.35)], [8.0, Color(1.0, 0.45, 0.1)], [5.0, Color(1.0, 0.85, 0.35)], [2.5, Color(1, 1, 0.9)]]:
			var c := Polygon2D.new()
			c.polygon = Util.circle(r[0], 14)
			c.color = r[1]
			_vis.add_child(c)
		_trail = Line2D.new()
		_trail.top_level = true
		_trail.width = 12.0
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.3, 0.05, 0.0))
		g.set_color(1, Color(1.0, 0.6, 0.15, 0.7))
		_trail.gradient = g
		add_child(_trail)
	else:
		var s := Polygon2D.new()
		s.polygon = Util.circle(5.0, 8)
		s.color = Color(0.55, 0.55, 0.58)
		_vis.add_child(s)
		var hl := Polygon2D.new()
		hl.polygon = Util.circle(2.0, 6)
		hl.color = Color(0.8, 0.8, 0.82)
		hl.position = Vector2(-1.5, -1.5)
		_vis.add_child(hl)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_boom(null)
		return
	var from := global_position
	velocity.y += gravity * delta
	var to := from + velocity * delta
	if _trail:
		_trail.add_point(to)
		while _trail.get_point_count() > 10:
			_trail.remove_point(0)
		_vis.rotation += delta * 12.0
	var ex: Array[RID] = []
	if kit and is_instance_valid(kit.p):
		ex.append(kit.p.get_rid())
	var space := get_world_2d().direct_space_state
	for i in 6:
		var q := PhysicsRayQueryParameters2D.create(from, to, Layer.WORLD | Layer.FRAME | Layer.BOT | Layer.PLAYER, ex)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var b = hit["collider"]
		var skip := false
		if b is Player:
			skip = b.team == 0 or not b.is_alive()
		elif b is Destructible:
			skip = b.background
		if skip:
			ex.append(hit["rid"])
			continue
		global_position = hit["position"]
		_boom(b)
		return
	global_position = to

func _boom(body) -> void:
	var world := get_parent()
	if kind == "fireball":
		if kit:
			kit.src = "magic"
		for n in world.get_children():
			if n is Player and n.team != 0 and n.is_alive() and n.global_position.distance_to(global_position) < 75.0 + n.body_size.x / 2:
				n.take_damage(damage, kit.p if kit else null)
				n.burn(2.5, 5.0, kit.p if kit else null)
		for n in world.get_children():
			if n is Destructible and not n.background and n.global_position.distance_to(global_position) < 500.0:
				n.hit(global_position, velocity.normalized(), 30, 40.0, 0, {"attacker": kit.p if kit else null, "fire": true})
		Fx.ring(world, global_position, 75.0, Color(1.0, 0.55, 0.15, 0.9), 0.35, 6.0)
		Fx.sparks(world, global_position, Color(1.0, 0.7, 0.25), 14, 260.0, 4.0)
		Util.flash(world, global_position, 40.0, Color(1.0, 0.7, 0.3, 0.8))
	else:
		if body is Player:
			if kit:
				kit.src = kit.ranged_skill()
			body.take_damage(damage, kit.p if kit else null)
		elif body is Destructible:
			body.hit(global_position, velocity.normalized(), 10, 0.0, 0, {"attacker": kit.p if kit else null})
		Fx.sparks(world, global_position, Color(0.7, 0.7, 0.7), 5, 140.0, 3.0)
	queue_free()
