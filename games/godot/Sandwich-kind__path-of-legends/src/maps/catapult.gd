class_name Catapult
extends Node2D
# ---------- Метательная плита (Колизей) ----------
# Деревянная плита на пружинах в полу арены — старая машина для зрелищ.
# Кто встанет на неё (герой или противник), того через мгновение швыряет по
# дуге в заранее заданное место: на верхний ярус, через всю арену или прямо
# в гущу боя. Стрелка над плитой показывает, куда полетишь.

var target := Vector2.ZERO       # куда приземлится
var width := 100.0
var _armed := {}
var _cd := 0.0
var _plate: Node2D
var _arrow: Polygon2D
var _t := 0.0

func _ready() -> void:
	z_index = 1
	var pit := Polygon2D.new()
	pit.polygon = PackedVector2Array([Vector2(-width / 2 - 6, 0), Vector2(width / 2 + 6, 0), Vector2(width / 2 + 6, 10), Vector2(-width / 2 - 6, 10)])
	pit.color = Color(0.22, 0.18, 0.14)
	add_child(pit)
	_plate = Node2D.new()
	add_child(_plate)
	var plank := Polygon2D.new()
	plank.polygon = PackedVector2Array([Vector2(-width / 2, -8), Vector2(width / 2, -8), Vector2(width / 2, 0), Vector2(-width / 2, 0)])
	Tex.apply(plank, "mine_wood", Color(0.56, 0.40, 0.24))
	_plate.add_child(plank)
	for x in [-width / 2 + 8, width / 2 - 14]:
		var bolt := Polygon2D.new()
		bolt.polygon = Util.circle(3.0, 8)
		bolt.color = Color(0.6, 0.58, 0.55)
		bolt.position = Vector2(x + 3, -4)
		_plate.add_child(bolt)
	# стрелка: куда полетишь
	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(6, -22), Vector2(14, -22), Vector2(0, -38), Vector2(-14, -22), Vector2(-6, -22)])
	_arrow.color = Color(1.0, 0.8, 0.3, 0.75)
	_arrow.position = Vector2(0, -20)
	var to := target - global_position
	_arrow.rotation = Vector2(to.x * 0.4, -absf(to.x) * 0.5 - 200.0).angle() + PI / 2
	add_child(_arrow)

func _physics_process(delta: float) -> void:
	_t += delta
	_cd -= delta
	_arrow.modulate.a = 0.5 + 0.5 * sin(_t * 4.0)
	_plate.position.y = move_toward(_plate.position.y, 0.0, delta * 60.0)
	if _cd > 0.0:
		return
	for n in get_parent().get_children():
		if not (n is Player) or not n.is_alive() or n.flying or n.frozen or n.body_size.y > 130.0:
			continue
		var feet: float = n.global_position.y + n.body_size.y / 2
		var on: bool = absf(n.global_position.x - global_position.x) < width / 2 and absf(feet - (global_position.y - 8.0)) < 12.0 and n.is_on_floor()
		if on:
			var t: float = _armed.get(n, 0.0) + delta
			_armed[n] = t
			_plate.position.y = 4.0
			if t >= 0.2:
				_launch(n)
				_armed.clear()
				return
		else:
			_armed.erase(n)

func _launch(n: Player) -> void:
	_cd = 1.2
	var from: Vector2 = n.global_position
	var to: Vector2 = target + Vector2(randf_range(-30.0, 30.0), -n.body_size.y / 2)
	var dist := from.distance_to(to)
	var t := clampf(dist / 900.0, 0.65, 1.25)
	var g: float = n.gravity
	var vx := (to.x - from.x) / t
	var vy := (to.y - from.y) / t - 0.5 * g * t
	n._forced_time = t
	n._forced_vx = vx
	n._forced_no_gravity = false
	n.velocity.y = vy
	n.global_position.y -= 4.0
	_plate.position.y = -16.0
	Fx.ring(get_parent(), global_position, 80.0, Color(1.0, 0.85, 0.45, 0.85), 0.3, 5.0, 0.3)
	Fx.sparks(get_parent(), global_position + Vector2(0, -6), Color(0.8, 0.7, 0.5), 10, 240.0, 4.0, true)
