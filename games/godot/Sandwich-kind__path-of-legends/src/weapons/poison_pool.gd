class_name PoisonPool
extends Node2D
# Лужа яда из склянки Терновника: растекается по поверхности, травит всех,
# кроме союзников, и через несколько секунд высыхает.

const LIFE := 5.0
const HALF := 75.0

var team := 0
var attacker: Node
var _t := 0.0
var _tick := 0.0
var _bubbles: Array = []

# Склянка разбилась: ищем поверхность под ней и разливаем лужу
static func spill(parent: Node, at: Vector2, team_: int, attacker_: Node) -> void:
	var space := (parent as Node2D).get_world_2d().direct_space_state if parent is Node2D else null
	var pos := at
	if space:
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(at + Vector2(0, -10), at + Vector2(0, 300), Layer.WORLD))
		if not hit.is_empty():
			pos = hit["position"]
	var pool := PoisonPool.new()
	pool.team = team_
	pool.attacker = attacker_
	pool.position = pos
	parent.call_deferred("add_child", pool)

func _ready() -> void:
	z_index = 3
	var base := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var a := PI + PI * i / 15.0
		pts.append(Vector2(cos(a) * HALF, sin(a) * 9.0 + 2.0))
	base.polygon = pts
	base.color = Color(0.35, 0.85, 0.25, 0.75)
	add_child(base)
	for i in 6:
		var b := Polygon2D.new()
		b.polygon = Util.circle(4.0, 8)
		b.color = Color(0.6, 1.0, 0.45, 0.9)
		b.position = Vector2(randf_range(-HALF * 0.8, HALF * 0.8), -4)
		add_child(b)
		_bubbles.append(b)
	scale = Vector2(0.2, 1)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3)

func _process(delta: float) -> void:
	_t += delta
	for i in _bubbles.size():
		var b: Polygon2D = _bubbles[i]
		b.position.y = -4.0 - absf(sin(_t * 3.0 + i)) * 10.0
	if _t > LIFE - 1.0:
		modulate.a = clampf(LIFE - _t, 0.0, 1.0)
	if _t > LIFE:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive():
				var feet: Vector2 = n.global_position + Vector2(0, n.body_size.y / 2)
				if absf(feet.x - global_position.x) < HALF + n.body_size.x / 2 and absf(feet.y - global_position.y) < 30.0:
					n.take_damage(5, attacker)
					n.poison(1.0, 4.0)
