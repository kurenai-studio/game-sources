class_name FallingBomb
extends Node2D
# Авиабомба Солдата: падает, на касании — мощный взрыв.
# cluster — при взрыве разлетается бомбами поменьше (МЕГА-авиаудар).

const GRAVITY := 1400.0

var team := 0
var attacker: Node
var big := true
var cluster := false
var small := false
var velocity := Vector2.ZERO
var _vis: Node2D
var _life := 6.0

func _ready() -> void:
	z_index = 6
	_vis = Node2D.new()
	add_child(_vis)
	var k := 0.55 if small else 1.0
	var b := Polygon2D.new()
	b.polygon = PackedVector2Array([Vector2(-16, -7), Vector2(14, -7), Vector2(22, 0), Vector2(14, 7), Vector2(-16, 7)])
	b.color = Color(0.25, 0.28, 0.22)
	b.scale = Vector2(k, k)
	_vis.add_child(b)
	var fin := Polygon2D.new()
	fin.polygon = PackedVector2Array([Vector2(-16, -7), Vector2(-24, -12), Vector2(-24, 12), Vector2(-16, 7)])
	fin.color = Color(0.2, 0.22, 0.18)
	fin.scale = Vector2(k, k)
	_vis.add_child(fin)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(4, -7), Vector2(8, -7), Vector2(8, 7), Vector2(4, 7)])
	band.color = Color(0.9, 0.75, 0.2)
	band.scale = Vector2(k, k)
	_vis.add_child(band)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	var from := global_position
	velocity.y += GRAVITY * delta
	var to := from + velocity * delta
	_vis.rotation = velocity.angle()
	var space := get_world_2d().direct_space_state
	var ex: Array[RID] = []
	for i in 4:
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, to,
				Layer.WORLD | Layer.FRAME | Layer.PLAYER | Layer.BOT, ex))
		if hit.is_empty():
			break
		var c = hit["collider"]
		if (c is Player and (c.team == team or not c.is_alive())) or (c is Destructible and (c.background or c.shield_team == team)):
			ex.append(hit["rid"])
			continue
		global_position = hit["position"]
		_boom()
		return
	global_position = to

func _boom() -> void:
	var parent := get_parent()
	var pos := global_position
	var r := 70.0 if small else (130.0 if cluster else 170.0)
	var dmg := 14 if small else (34 if cluster else 55)
	var cells := 40 if small else (80 if cluster else 110)
	Util.explode(parent, pos, r, dmg, cells, team, attacker, not small)
	Fx.ring(parent, pos, r * 1.15, Color(1.0, 0.55, 0.15, 0.95), 0.45, 8.0 if not small else 4.0, 0.4)
	Fx.ring(parent, pos, r * 0.7, Color(1.0, 0.95, 0.75, 0.9), 0.3, 5.0)
	Fx.sparks(parent, pos, Color(1.0, 0.65, 0.25), 8 if small else 22, 340.0, 5.0, true)
	if not small:
		Fx.cracks(parent, pos, Color(0.25, 0.2, 0.16), r * 0.8)
		Fx.glow(parent, pos, r * 0.6, Color(1.0, 0.6, 0.2, 0.35), 0.5)
		for e in parent.get_children():
			if e is Player and e.team != team and e.is_alive() and e.global_position.distance_to(pos) < r:
				e.velocity = Vector2(signf(e.global_position.x - pos.x) * 450.0, -500.0)
	if cluster:
		for i in 4:
			var b := FallingBomb.new()
			b.team = team
			b.attacker = attacker
			b.small = true
			b.velocity = Vector2(randf_range(-420.0, 420.0), randf_range(-620.0, -380.0))
			b.position = pos + Vector2(0, -14)
			parent.add_child(b)
	queue_free()
