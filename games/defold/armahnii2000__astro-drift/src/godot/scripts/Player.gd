class_name Player
extends Area2D

signal shoot_requested(pos: Vector2, dir: Vector2)
signal died

const THRUST := 380.0
const ROT_SPEED := 4.2
const DRAG_PER_SEC := 0.55
const BRAKE_DRAG := 0.08
const MAX_SPEED := 520.0
const SHOOT_COOLDOWN := 0.18
const INVULN_TIME := 2.0

var velocity := Vector2.ZERO
var _cooldown := 0.0
var _invuln := INVULN_TIME
var _thrusting := false
var _braking := false

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	collision_layer = 1
	collision_mask = 2
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if _invuln > 0.0:
		_invuln -= delta
		modulate.a = 0.35 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.025))
	else:
		modulate.a = 1.0

	var rot_input := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT):
		rot_input -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		rot_input += 1.0
	rotation += rot_input * ROT_SPEED * delta

	_thrusting = Input.is_physical_key_pressed(KEY_UP)
	_braking = Input.is_physical_key_pressed(KEY_DOWN)
	if _thrusting:
		velocity += Vector2.from_angle(rotation - PI / 2.0) * THRUST * delta
	var damp := BRAKE_DRAG if _braking else DRAG_PER_SEC
	velocity *= pow(damp, delta)
	velocity = velocity.limit_length(MAX_SPEED)
	position += velocity * delta

	_cooldown -= delta
	var firing := Input.is_physical_key_pressed(KEY_DELETE)
	if firing and _cooldown <= 0.0:
		_cooldown = SHOOT_COOLDOWN
		var dir := Vector2.from_angle(rotation - PI / 2.0)
		shoot_requested.emit(position + dir * 18.0, dir)

	_wrap()
	queue_redraw()

func _wrap() -> void:
	var s := get_viewport_rect().size
	if position.x < -20.0: position.x = s.x + 20.0
	if position.x > s.x + 20.0: position.x = -20.0
	if position.y < -20.0: position.y = s.y + 20.0
	if position.y > s.y + 20.0: position.y = -20.0

func _on_area_entered(area: Area2D) -> void:
	if _invuln > 0.0:
		return
	if area is Asteroid:
		died.emit()
		queue_free()

func _draw() -> void:
	var hull := PackedVector2Array([
		Vector2(0, -14),
		Vector2(10, 12),
		Vector2(0, 6),
		Vector2(-10, 12),
	])
	draw_colored_polygon(hull, Color(0.9, 0.95, 1.0))
	var outline := hull.duplicate()
	outline.append(hull[0])
	draw_polyline(outline, Color(0.55, 0.75, 1.0), 1.5)
	if _thrusting:
		var flame := PackedVector2Array([
			Vector2(-5, 8),
			Vector2(0, 18.0 + randf() * 6.0),
			Vector2(5, 8),
		])
		draw_colored_polygon(flame, Color(1.0, 0.6, 0.2))
