class_name Mortar
extends Area2D
# Снаряд залпа UBER_TESTIK_2 (способность 3).
# Резко взлетает, замедляется в воздухе, потом резко пикирует вперёд-вниз
# в случайную точку на земле от MIN_RANGE до MAX_RANGE впереди героя.
# Пока взлетает и в начале пике — проходит сквозь всё, потом взрывается от касания.

const RADIUS := 50.0
const DIVE_SPEED := 1000.0
const TOP_LIMIT := 60.0      # не залетает выше потолка арены
const DIVE_GHOST := 0.25     # ещё столько секунд после начала пике летит сквозь всё
const MIN_RANGE := 450.0     # ближайшая точка падения (от героя)
const MAX_RANGE := 1500.0    # дальняя точка падения
const BACK_CHIP_CHANCE := 0.4   # шанс выбить клетки дерева или задней стены при пролёте

var shooter: Node
var team := 0
var facing := 1
var velocity := Vector2.ZERO
var ground_y := 0.0          # уровень земли под героем в момент выстрела
var map_w := 1152.0          # чтобы не целиться за стену карты
var target_x := NAN          # если задано (боты) — снаряды ложатся вокруг этой точки
var homing := false          # МЕГА: в пике доворачивает на ближайшего врага
const HOMING_RADIUS := 280.0
var _start_x := 0.0
var _rise_time := 0.5
var _range := 800.0
var _t := 0.0
var _diving := false
var _dive_t := 0.0
var _done := false
var _passed := {}            # фоновые объекты, сквозь которые уже пролетели

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT | Layer.BACK
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	col.shape = cs
	add_child(col)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([Vector2(12, 0), Vector2(4, 6), Vector2(-10, 6),
			Vector2(-10, -6), Vector2(4, -6)])
	vis.color = Color(0.6, 0.4, 1.0)
	add_child(vis)
	modulate.a = 0.45
	# у каждого снаряда свой взлёт и своя точка падения — так залп разлетается шире
	_start_x = global_position.x
	velocity = Vector2(facing * randf_range(100.0, 300.0), -randf_range(950.0, 1200.0))
	_rise_time = randf_range(0.4, 0.7)
	_range = randf_range(MIN_RANGE, MAX_RANGE)
	if not is_nan(target_x):
		_range = clampf(absf(target_x - _start_x) + randf_range(-160.0, 160.0), 80.0, 2000.0)

func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if not _diving:
		velocity = velocity.lerp(Vector2.ZERO, 3.0 * delta)   # замедляется в воздухе
		if _t >= _rise_time or global_position.y < TOP_LIMIT:
			_start_dive()
	else:
		_dive_t += delta
		if homing:
			_steer(delta)
	position += velocity * delta
	rotation = velocity.angle()
	if _t > 5.0:
		queue_free()
		return
	if not _diving or _dive_t < DIVE_GHOST:
		return
	modulate.a = 1.0
	for b in get_overlapping_bodies():
		if b == shooter or b.get("shield_team") == team:
			continue
		if b is Destructible and b.background:
			# фон не останавливает ракету, но иногда она выбивает из него кусок
			if not _passed.has(b.family):
				_passed[b.family] = true
				if randf() < BACK_CHIP_CHANCE:
					b.hit(global_position, velocity.normalized(), 40, 14.0, team,
							{"strict": true, "attacker": shooter})
			continue
		if b is Player and b.team == team:
			continue
		_done = true
		Util.explode(get_parent(), global_position, RADIUS, 15, 40, team, shooter)
		queue_free()
		return

func _start_dive() -> void:
	_diving = true
	var tx := clampf(_start_x + facing * _range, 40.0, map_w - 40.0)
	var dir := (Vector2(tx, ground_y) - global_position).normalized()
	velocity = dir * DIVE_SPEED

func _steer(delta: float) -> void:
	var best = null
	var best_d := HOMING_RADIUS
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive():
			var d := global_position.distance_to(n.global_position)
			if d < best_d:
				best_d = d
				best = n
	if best == null:
		return
	var want: Vector2 = (best.global_position - global_position).normalized()
	var ang := velocity.angle_to(want)
	velocity = velocity.rotated(clampf(ang, -7.0 * delta, 7.0 * delta))
