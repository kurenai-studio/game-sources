extends CharacterBody2D

signal bumped(normal: Vector2, at: Vector2)

const StickRegions := preload("res://scripts/stick_regions.gd")
const StickInput := preload("res://scripts/stick_input.gd")
const AnnularSector := preload("res://scripts/annular_sector.gd")

const DRIFT_DEADZONE := 0.09
const REFERENCE_RADIUS := 26.0
const SPEEDS := [95.0, 220.0, 400.0]
const ARROW_SIZES := [16.0, 22.0, 30.0]
const WEDGE_LENGTHS := [30.0, 55.0, 90.0]
const WEDGE_SPAN := PI * 0.28
const BUMP_INTERVAL := 0.35

## The white core is the hitbox. The body around it is translucent padding that
## may overlap a wall, so what counts as a touch is exactly what she can see.
const CORE_SCALE := 0.4
const BODY_ALPHA := 0.45
const ARROW_ALPHA := 0.7

const IDLE_COLOR := Color(0.42, 0.86, 1.0)
const TIER_COLORS := [Color(0.42, 0.86, 1.0), Color(0.55, 1.0, 0.62), Color(1.0, 0.58, 0.32)]
const HURT_COLOR := Color(1.0, 0.26, 0.32)

var device: int = -1
var frozen: bool = false
var radius: float = REFERENCE_RADIUS
var speed_scale: float = 1.0
var stick: Vector2 = Vector2.ZERO

var _pulse: float = 0.0
var _bump_cooldown: float = 0.0
var _hurt: float = 0.0
var _hurt_time: float = 1.0
var _circle: CircleShape2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	_circle = CircleShape2D.new()
	_circle.radius = radius * CORE_SCALE
	var collider := CollisionShape2D.new()
	collider.shape = _circle
	add_child(collider)


func configure(new_radius: float, new_speed_scale: float) -> void:
	radius = new_radius
	speed_scale = new_speed_scale
	_circle.radius = new_radius * CORE_SCALE


func hurt(duration: float) -> void:
	_hurt = duration
	_hurt_time = duration


func knock_back(normal: Vector2) -> void:
	velocity = Vector2.ZERO
	position += normal * radius * 0.85


func _physics_process(delta: float) -> void:
	_pulse += delta
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)
	_hurt = maxf(_hurt - delta, 0.0)
	stick = StickInput.read(device, DRIFT_DEADZONE)
	var ring := StickRegions.ring_for(stick.length())
	if frozen or ring < 0:
		velocity = Vector2.ZERO
	else:
		velocity = stick.normalized() * SPEEDS[ring] * speed_scale
	move_and_slide()
	if velocity != Vector2.ZERO and get_slide_collision_count() > 0 and _bump_cooldown <= 0.0:
		_bump_cooldown = BUMP_INTERVAL
		var hit := get_slide_collision(0)
		bumped.emit(hit.get_normal(), hit.get_position())
	queue_redraw()


func _draw() -> void:
	var ring := StickRegions.ring_for(stick.length())
	var can_move := not frozen
	var is_moving := can_move and ring >= 0

	if _hurt > 0.0:
		_draw_hurt()
		return

	if can_move:
		var tint: Color = TIER_COLORS[ring] if ring >= 0 else IDLE_COLOR
		if is_moving:
			_draw_speed_wedge(ring, tint)
		var glow := tint
		glow.a = 0.22
		draw_circle(Vector2.ZERO, radius * 1.7, glow)
		var body := tint
		body.a = BODY_ALPHA
		draw_circle(Vector2.ZERO, radius, body)
		if is_moving:
			_draw_direction_arrow(ring, tint)

	_draw_core()


func _draw_core() -> void:
	draw_circle(Vector2.ZERO, radius * CORE_SCALE, Color(1, 1, 1, 0.95))


func _draw_hurt() -> void:
	var blink := 0.5 + 0.5 * sin(_hurt * 34.0)
	var glow := HURT_COLOR
	glow.a = lerpf(0.15, 0.5, blink)
	draw_circle(Vector2.ZERO, radius * lerpf(1.7, 2.4, _hurt / _hurt_time), glow)
	var body := HURT_COLOR.lerp(Color.WHITE, blink * 0.35)
	body.a = BODY_ALPHA
	draw_circle(Vector2.ZERO, radius, body)
	_draw_core()


func _draw_speed_wedge(ring: int, tint: Color) -> void:
	var scaling := radius / REFERENCE_RADIUS
	var pulse := 0.5 + 0.5 * sin(_pulse * 6.0)
	var color := tint
	color.a = lerpf(0.14, 0.28, pulse)
	var angle := stick.angle()
	draw_colored_polygon(AnnularSector.build(
		Vector2.ZERO,
		radius * 0.55,
		WEDGE_LENGTHS[ring] * scaling,
		angle - WEDGE_SPAN,
		angle + WEDGE_SPAN
	), color)


func _draw_direction_arrow(ring: int, tint: Color) -> void:
	var dir := stick.normalized()
	var side := Vector2(-dir.y, dir.x)
	var arrow_size: float = ARROW_SIZES[ring] * (radius / REFERENCE_RADIUS)
	var base_center := dir * (radius + 10.0 * (radius / REFERENCE_RADIUS))
	var tip: Vector2 = base_center + dir * arrow_size
	var color := tint
	color.a = ARROW_ALPHA
	draw_colored_polygon(PackedVector2Array([
		tip,
		base_center + side * arrow_size * 0.42,
		base_center - side * arrow_size * 0.42,
	]), color)
