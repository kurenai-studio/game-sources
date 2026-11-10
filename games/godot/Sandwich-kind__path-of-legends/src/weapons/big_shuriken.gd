class_name BigShuriken
extends Node2D
# ---------- Большой сюрикен (ульта Ассасина) ----------
# Летит прямо. Попал во врага — немного ранит и вонзается в него (метка),
# промахнулся (улетел далеко или врезался в стену) — исчезает.
# Чем закончилось, сообщает через done(hit_player или null).

signal done(target)

var team := 0
var attacker: Player
var dir := Vector2.RIGHT
var speed := 1500.0
var damage := 12
var max_dist := 1350.0
var _dist := 0.0
var _stuck_to: Player
var _stuck_t := 0.0
var _vis: Node2D
var _over := false

func _ready() -> void:
	z_index = 6
	_vis = Node2D.new()
	add_child(_vis)
	var glow := Polygon2D.new()
	glow.polygon = Util.circle(30.0, 16)
	glow.color = Color(0.55, 0.4, 0.75, 0.25)
	_vis.add_child(glow)
	var star := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var r := 26.0 if i % 2 == 0 else 8.0
		pts.append(Vector2.from_angle(TAU * i / 8.0 + 0.2 * float(i % 2)) * r)
	star.polygon = pts
	star.color = Color(0.72, 0.74, 0.82)
	_vis.add_child(star)
	var edge := Polygon2D.new()
	var e2 := PackedVector2Array()
	for i in 8:
		var r2 := 22.0 if i % 2 == 0 else 6.0
		e2.append(Vector2.from_angle(TAU * i / 8.0 + 0.2 * float(i % 2)) * r2)
	edge.polygon = e2
	edge.color = Color(0.9, 0.92, 1.0)
	_vis.add_child(edge)
	var hole := Polygon2D.new()
	hole.polygon = Util.circle(4.0, 10)
	hole.color = Color(0.2, 0.25, 0.22)
	_vis.add_child(hole)

func _physics_process(delta: float) -> void:
	if _over:
		return
	_vis.rotation += delta * 25.0
	if _stuck_to:
		# вонзился в цель и держится на ней, пока идёт ульта
		_stuck_t -= delta
		if is_instance_valid(_stuck_to) and _stuck_to.is_alive() and _stuck_t > 0.0:
			global_position = _stuck_to.global_position + Vector2(0, -6)
			_vis.rotation -= delta * 22.0
		else:
			_finish_fade()
		return
	var step := dir * speed * delta
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step, Layer.WORLD | Layer.FRAME)
	var hit := space.intersect_ray(q)
	if not hit.is_empty() and not Util.is_one_way(hit["collider"]) and not (hit["collider"] is Destructible and hit["collider"].background):
		global_position = hit["position"]
		Fx.sparks(get_parent(), global_position, Color(0.9, 0.9, 1.0), 8, 200.0, 3.0)
		_miss()
		return
	global_position += step
	_dist += step.length()
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
			var dd: Vector2 = n.global_position - global_position
			if absf(dd.x) < n.body_size.x / 2 + 22.0 and absf(dd.y) < n.body_size.y / 2 + 22.0:
				n.take_damage(damage, attacker)
				Fx.sparks(get_parent(), global_position, Color(0.75, 0.55, 1.0), 10, 220.0, 3.0)
				_stuck_to = n
				_stuck_t = 3.3
				done.emit(n)
				return
	if _dist >= max_dist:
		_miss()

func _miss() -> void:
	done.emit(null)
	_finish_fade()

func _finish_fade() -> void:
	_over = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)

func release() -> void:
	_stuck_t = 0.0
