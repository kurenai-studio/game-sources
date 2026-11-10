class_name BearTrap
extends Node2D
# Капкан Охотницы: летит по дуге, ложится на землю и через полсекунды
# взводится. Враг, наступивший на него, получает урон и застревает.
# МЕГА — урон выше и держит дольше.

const GRAVITY := 1400.0

var team := 0
var attacker: Node
var mega := false
var velocity := Vector2.ZERO
var _landed := false
var _armed := 0.5
var _sprung := false
var _life := 25.0
var _jaw_l: Polygon2D
var _jaw_r: Polygon2D
var _victim: Player
var _hold := 0.0

func _ready() -> void:
	z_index = 3
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(14, -4), Vector2(-14, -4)])
	base.color = Color(0.32, 0.30, 0.30)
	add_child(base)
	var plate := Polygon2D.new()
	plate.polygon = Util.circle(5.0, 8)
	plate.position = Vector2(0, -4)
	plate.color = Color(0.75, 0.6, 0.25) if not mega else Color(1.0, 0.35, 0.2)
	add_child(plate)
	_jaw_l = _jaw(-1)
	_jaw_r = _jaw(1)
	_set_open(1.0)

func _jaw(side: int) -> Polygon2D:
	var j := Polygon2D.new()
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(0, -3)])
	for k in 5:                     # зубья
		var x := 2.0 + k * 3.0
		pts.append(Vector2(x, -3))
		pts.append(Vector2(x + 1.5, -7))
	pts.append(Vector2(16, -3))
	pts.append(Vector2(16, 0))
	j.polygon = pts
	j.color = Color(0.68, 0.68, 0.74) if not mega else Color(0.85, 0.55, 0.45)
	j.position = Vector2(-16 * side, -2) if side < 0 else Vector2(16, -2)
	j.scale = Vector2(-1, 1) if side > 0 else Vector2(1, 1)
	add_child(j)
	return j

# 1 — раскрыт (челюсти лежат), 0 — захлопнут (челюсти стоят)
func _set_open(k: float) -> void:
	_jaw_l.rotation = lerpf(-PI / 2, 0.0, k)
	_jaw_r.rotation = lerpf(PI / 2, 0.0, k)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 and not _sprung:
		_vanish()
		return
	if not _landed:
		velocity.y += GRAVITY * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 4), Layer.WORLD))
		if hit.is_empty():
			global_position = to
			rotation += delta * 6.0
			return
		if hit["normal"].y > -0.5:
			velocity.x = -velocity.x * 0.3          # стукнулся о стену — отскок
			return
		global_position = hit["position"]
		rotation = 0.0
		_landed = true
		Fx.sparks(get_parent(), global_position, Color(0.8, 0.8, 0.85), 5, 120.0, 3.0, true)
		return
	if _sprung:
		if is_instance_valid(_victim) and _victim.is_alive() and _hold > 0.0:
			_hold -= delta
			_victim.root(0.1)
			_victim.global_position.x = move_toward(_victim.global_position.x, global_position.x, 300.0 * delta)
		return
	if _armed > 0.0:
		_armed -= delta
		modulate.a = 0.5 + 0.5 * absf(sin(_armed * 20.0))
		if _armed <= 0.0:
			modulate.a = 0.85              # взведён: чуть заметен
		return
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not n.fly_free:
			var feet: Vector2 = n.global_position + Vector2(0, n.body_size.y / 2)
			if absf(feet.x - global_position.x) < 18.0 + n.body_size.x * 0.4 and absf(feet.y - global_position.y) < 16.0:
				_spring(n)
				return

func _spring(v: Player) -> void:
	_sprung = true
	_victim = v
	modulate.a = 1.0
	_hold = 2.6 if mega else 1.5
	v.take_damage(30 if mega else 14, attacker)
	v.root(_hold)
	var t := create_tween()
	t.tween_method(_set_open, 1.0, 0.0, 0.08)
	Fx.sparks(get_parent(), global_position + Vector2(0, -8), Color(0.9, 0.9, 0.95), 10, 200.0, 4.0, true)
	Util.flash(get_parent(), global_position + Vector2(0, -10), 26.0, Color(1.0, 0.4, 0.3, 0.8) if mega else Color(1, 1, 1, 0.7))
	if mega:
		Fx.ring(get_parent(), global_position, 60.0, Color(1.0, 0.4, 0.25, 0.9), 0.35, 5.0, 0.4)
	var t2 := create_tween()
	t2.tween_interval(_hold)
	t2.tween_property(self, "modulate:a", 0.0, 0.4)
	t2.tween_callback(queue_free)

func _vanish() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
