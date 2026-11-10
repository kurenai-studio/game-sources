class_name ClimbVine
extends Node2D
# ---------- Лиана (Джунгли) ----------
# Свисает с платформы или с крон. Герой, оказавшись у лианы в воздухе, цепляется:
#   держи прыжок — лезет вверх; отпусти — медленно сползает (висит);
#   вниз — быстро съезжает. С верха лианы можно спрыгнуть на платформу.
# Боты по лианам не лазают. Лиана слегка качается.

var length := 220.0
var climb_speed := 360.0
var _sway := 0.0
var _line: Line2D
var _leaves: Array = []
var _held := {}

const GRAB := 22.0              # насколько близко к лиане надо быть, чтобы зацепиться

func _ready() -> void:
	z_index = -2
	_sway = randf() * TAU
	_line = Line2D.new()
	_line.width = 5.0
	_line.default_color = Color(0.28, 0.52, 0.20)
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_line)
	var shade := Line2D.new()
	shade.width = 2.0
	shade.default_color = Color(0.18, 0.36, 0.14)
	_line.add_child(shade)
	for k in int(length / 34.0):
		var lf := Polygon2D.new()
		lf.polygon = PackedVector2Array([Vector2(0, 0), Vector2(9, -4), Vector2(14, 1), Vector2(6, 5)])
		lf.color = Color(0.35, 0.65, 0.26) if k % 2 == 0 else Color(0.28, 0.56, 0.22)
		lf.scale.x = 1.0 if k % 2 == 0 else -1.0
		add_child(lf)
		_leaves.append([lf, 20.0 + k * 34.0])
	_update_line(0.0)

func _bend(y: float) -> float:
	return sin(_sway) * 10.0 * (y / length)

func _update_line(_delta: float) -> void:
	var pts := PackedVector2Array()
	for k in 9:
		var y := length * k / 8.0
		pts.append(Vector2(_bend(y), y))
	_line.points = pts
	(_line.get_child(0) as Line2D).points = PackedVector2Array([pts[0] + Vector2(1.5, 0), pts[8] + Vector2(1.5, 0)])
	for L in _leaves:
		L[0].position = Vector2(_bend(L[1]), L[1])

func _physics_process(delta: float) -> void:
	_sway += delta * 1.3
	_update_line(delta)
	var world := get_parent()
	for n in world.get_children():
		if not (n is Player) or n.is_bot or not n.is_alive():
			continue
		var rel: Vector2 = n.global_position - global_position
		var on_vine: bool = absf(rel.x - _bend(clampf(rel.y, 0.0, length))) < GRAB + n.body_size.x * 0.25 \
				and rel.y > -n.body_size.y * 0.3 and rel.y < length + n.body_size.y * 0.2
		if not on_vine or n.is_on_floor() or n.frozen or n._forced_time > 0.0:
			_held.erase(n)
			continue
		var up := Input.is_action_pressed(n.prefix + "_jump")
		var down := Input.is_action_pressed(n.prefix + "_down")
		if not _held.has(n):
			_held[n] = true
			Fx.sparks(world, n.global_position, Color(0.4, 0.75, 0.3), 4, 90.0, 3.0)
		if up and rel.y > -n.body_size.y * 0.2:
			n.velocity.y = -climb_speed                  # лезет вверх
		elif down:
			n.velocity.y = maxf(n.velocity.y, 420.0)     # съезжает
		else:
			n.velocity.y = minf(n.velocity.y, 70.0)      # висит, медленно сползая
		# подтягивается к лиане
		n.velocity.x = lerpf(n.velocity.x, (_bend(rel.y) - rel.x) * 8.0 + n.velocity.x * 0.6, 0.3)
