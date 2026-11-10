class_name GhostSword
extends Node2D
# Призрачный меч Короля (ульта Мортиса). Появляется над врагом, через 0,5 с
# вонзается в землю, ломая всё на пути. МЕГА: комбо из трёх ударов —
# вонзается, взмахивает из-под земли к врагу и рубит сверху (без гарантированных
# разрушений: блоки ломаются лишь с шансом).

var team := 0
var attacker: Node
var target: Node
var mega := false
var ground_y := INF           # уровень, на котором стоит враг: сюда меч точно вонзится
const SIZE := 1.5             # меч крупнее
var _blade: Polygon2D
var _hit := {}

func _ready() -> void:
	z_index = 6
	scale = Vector2(SIZE, SIZE)
	_blade = Polygon2D.new()
	# остриё вниз: рукоять сверху
	_blade.polygon = PackedVector2Array([Vector2(-6, -230), Vector2(6, -230), Vector2(6, -200), Vector2(34, -200),
			Vector2(34, -188), Vector2(16, -188), Vector2(16, 40), Vector2(0, 80), Vector2(-16, 40), Vector2(-16, -188),
			Vector2(-34, -188), Vector2(-34, -200), Vector2(-6, -200)])
	_blade.color = Color(0.7, 0.55, 1.0, 0.75)
	add_child(_blade)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(-6, -180), Vector2(6, -180), Vector2(6, 50), Vector2(0, 66), Vector2(-6, 50)])
	glow.color = Color(0.95, 0.9, 1.0, 0.8)
	_blade.add_child(glow)
	# призрачный туман вокруг меча и круг на земле — сюда он ударит
	Fx.sparks(get_parent(), position, Color(0.7, 0.5, 1.0), 16, 160.0, 5.0)
	Fx.rune_circle(get_parent(), Vector2(position.x, _end_y()), 80.0 * SIZE,
			Color(0.75, 0.45, 1.0, 0.85), 0.9, 0.3)
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property(self, "position:y", position.y - 20.0, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_plunge)

func _end_y() -> float:
	if ground_y < INF:
		return ground_y
	return _ground_below(position.x, position.y + 90.0)

func _ground_below(x: float, from_y: float) -> float:
	var hit := get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 1500.0), Layer.WORLD | Layer.FRAME))
	return hit["position"].y if not hit.is_empty() else from_y + 600.0

# 1. Удар вниз: всё по пути разрушается
func _plunge() -> void:
	var start := position
	var end_y := _end_y()              # сквозь платформы над врагом — до его уровня
	var t := create_tween()
	t.tween_method(_plunge_step, start.y, end_y - 70.0 * SIZE, 0.2)
	t.tween_callback(func():
		var g := Vector2(position.x, end_y)
		Util.flash(get_parent(), g, 110.0, Color(0.75, 0.6, 1.0, 0.8))
		Fx.ring(get_parent(), g, 260.0, Color(0.8, 0.6, 1.0, 0.9), 0.5, 10.0, 0.35)
		_strike_at(g + Vector2(0, -20), 50, 120, 1.0)
		Fx.sparks(get_parent(), g, Color(0.8, 0.6, 1.0), 20, 360.0, 6.0, true)
		Fx.cracks(get_parent(), g, Color(0.3, 0.15, 0.45), 140.0)
		_hit.clear())
	if mega:
		t.tween_interval(0.35)
		t.tween_callback(_upswing)
	else:
		t.tween_interval(0.4)
		t.tween_property(self, "modulate:a", 0.0, 0.3)
		t.tween_callback(queue_free)

func _target_pos() -> Vector2:
	if target and is_instance_valid(target):
		return target.global_position
	return global_position + Vector2(200, 0)

# 2. Взмах из-под земли в сторону врага
func _upswing() -> void:
	var to := _target_pos()
	var dirx := signf(to.x - position.x) if to.x != position.x else 1.0
	rotation = dirx * 2.6
	var t := create_tween()
	var from := position
	var dest := Vector2(to.x - dirx * 40.0, to.y - 60.0)
	t.tween_method(_up_step.bind(from, dest, dirx), 0.0, 1.0, 0.25)
	t.tween_callback(func(): _hit.clear())
	t.tween_interval(0.3)
	t.tween_callback(_chop)

# 3. Рубящий удар сверху по врагу
func _chop() -> void:
	var to := _target_pos()
	var from := Vector2(to.x, to.y - 260.0)
	position = from
	rotation = 0.0
	var t := create_tween()
	t.tween_method(_chop_step.bind(from, Vector2(to.x, to.y + 40.0)), 0.0, 1.0, 0.18)
	t.tween_interval(0.25)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)

func _plunge_step(y: float) -> void:
	position.y = y
	_afterimage()
	_strike_at(global_position + Vector2(0, 60 * SIZE), 50, 120, 1.0)

func _up_step(k: float, from: Vector2, dest: Vector2, dirx: float) -> void:
	position = from.lerp(dest, k)
	rotation = lerpf(dirx * 2.6, dirx * 1.2, k)
	_afterimage()
	_strike_at(global_position, 30, 60, 0.5)

func _chop_step(k: float, from: Vector2, dest: Vector2) -> void:
	position = from.lerp(dest, k)
	rotation = lerpf(-0.8, 0.3, k)
	_afterimage()
	if k >= 1.0:
		Fx.ring(get_parent(), global_position + Vector2(0, 40), 130.0, Color(0.8, 0.6, 1.0, 0.8), 0.4, 7.0, 0.4)

# След-отражение меча в полёте
var _ai_t := 0.0
func _afterimage() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _ai_t < 0.03:
		return
	_ai_t = now
	var ghost := _blade.duplicate() as Polygon2D
	ghost.color = Color(0.6, 0.4, 1.0, 0.35)
	ghost.position = global_position
	ghost.rotation = global_rotation
	ghost.scale = scale
	ghost.z_index = 5
	get_parent().add_child(ghost)
	var t := ghost.create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.25)
	t.tween_callback(ghost.queue_free)
	_strike_at(global_position + Vector2(0, 50), 35, 60, 0.5)

func _strike_at(p: Vector2, dmg: int, cell_dmg: int, chance: float) -> void:
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not _hit.has(n):
			if n.global_position.distance_to(p) < 70.0 * SIZE + n.body_size.x * 0.5:
				_hit[n] = true
				n.take_damage(dmg, attacker)
		elif n is Destructible and n.shield_team != team:
			if n.global_position.distance_to(p) < 400.0:
				n.hit(p, Vector2.DOWN, cell_dmg, 40.0 * SIZE, team,
						{"strict": true, "radial": true, "attacker": attacker, "chance": chance})
