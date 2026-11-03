extends Control

signal stars_changed(stars: int)
signal star_won(total: int)
signal round_complete()
signal holding_changed(active: bool)

const StickRegions := preload("res://scripts/stick_regions.gd")
const StickInput := preload("res://scripts/stick_input.gd")
const ConfettiBurst := preload("res://scripts/confetti_burst.gd")
const AnnularSector := preload("res://scripts/annular_sector.gd")

const GOAL := 5
const HOLD_TIME := 0.9
const CELEBRATE_TIME := 1.3
const ROUND_CELEBRATE_TIME := 2.4
const DRIFT_DEADZONE := 0.09
const AVATAR_RADIUS := 26.0
const TARGET_SIZE := Vector2(170.0, 120.0)
const SPEEDS := [95.0, 220.0, 400.0]
const ARROW_SIZES := [16.0, 22.0, 30.0]
const WEDGE_LENGTHS := [30.0, 55.0, 90.0]
const WEDGE_SPAN := PI * 0.28
const MIN_TARGET_DISTANCE := 160.0
const EDGE_MARGIN := 20.0

const FIELD_COLOR := Color(0.10, 0.12, 0.22)
const BORDER_COLOR := Color(0.24, 0.29, 0.46)
const TARGET_COLOR := Color(1.0, 0.78, 0.28)
const TARGET_HOT_COLOR := Color(0.42, 0.95, 0.6)
const AVATAR_COLOR := Color(0.42, 0.86, 1.0)
const TIER_COLORS := [Color(0.42, 0.86, 1.0), Color(0.55, 1.0, 0.62), Color(1.0, 0.58, 0.32)]

var device: int = -1
var stick: Vector2 = Vector2.ZERO
var avatar_pos: Vector2 = Vector2.ZERO

var _initialized: bool = false
var _celebrating: bool = false
var _stars: int = 0
var _total: int = 0
var _hold: float = 0.0
var _timer: float = 0.0
var _pulse: float = 0.0
var _was_holding: bool = false
var _target_rect: Rect2 = Rect2()
var _burst_point: Vector2 = Vector2.ZERO
var _burst_time: float = 10.0
var _confetti: CPUParticles2D


func _ready() -> void:
	_confetti = ConfettiBurst.build()
	add_child(_confetti)
	resized.connect(_on_resized)


func _process(delta: float) -> void:
	if not _initialized:
		return
	_pulse += delta
	_burst_time += delta
	stick = StickInput.read(device, DRIFT_DEADZONE)
	if _celebrating:
		_timer -= delta
		if _timer <= 0.0:
			_end_celebration()
	else:
		_move_avatar(delta)
		_process_hold(delta)
	queue_redraw()


func _on_resized() -> void:
	if _initialized or size.x <= 0.0 or size.y <= 0.0:
		return
	_initialized = true
	avatar_pos = size * 0.5
	_spawn_target()


func _move_avatar(delta: float) -> void:
	var magnitude := stick.length()
	var ring := StickRegions.ring_for(magnitude)
	if ring < 0:
		return
	avatar_pos += stick.normalized() * SPEEDS[ring] * delta
	avatar_pos.x = clampf(avatar_pos.x, AVATAR_RADIUS, size.x - AVATAR_RADIUS)
	avatar_pos.y = clampf(avatar_pos.y, AVATAR_RADIUS, size.y - AVATAR_RADIUS)


func _process_hold(delta: float) -> void:
	var inside := _target_rect.has_point(avatar_pos)
	if inside != _was_holding:
		_was_holding = inside
		holding_changed.emit(inside)
	if inside:
		_hold = minf(_hold + delta, HOLD_TIME)
		if _hold >= HOLD_TIME:
			_succeed()
	else:
		_hold = maxf(_hold - delta * 0.75, 0.0)


func _succeed() -> void:
	_was_holding = false
	holding_changed.emit(false)
	_stars += 1
	_total += 1
	_hold = 0.0
	_celebrating = true
	_burst_point = avatar_pos
	_burst_time = 0.0
	star_won.emit(_total)
	stars_changed.emit(_stars)

	if _stars >= GOAL:
		_timer = ROUND_CELEBRATE_TIME
		_burst(_burst_point, 180)
		round_complete.emit()
	else:
		_timer = CELEBRATE_TIME
		_burst(_burst_point, 70)


func _end_celebration() -> void:
	if _stars >= GOAL:
		_stars = 0
		stars_changed.emit(_stars)
	_celebrating = false
	_spawn_target()


func _spawn_target() -> void:
	var half := TARGET_SIZE * 0.5
	var min_pos := half + Vector2.ONE * EDGE_MARGIN
	var max_pos := size - half - Vector2.ONE * EDGE_MARGIN
	if max_pos.x <= min_pos.x or max_pos.y <= min_pos.y:
		_target_rect = Rect2(size * 0.5 - half, TARGET_SIZE)
		return
	var center := avatar_pos
	for i in 12:
		center = Vector2(randf_range(min_pos.x, max_pos.x), randf_range(min_pos.y, max_pos.y))
		if center.distance_to(avatar_pos) >= MIN_TARGET_DISTANCE:
			break
	_target_rect = Rect2(center - half, TARGET_SIZE)


func _draw() -> void:
	if not _initialized:
		return
	draw_rect(Rect2(Vector2.ZERO, size), FIELD_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, 2.0)

	_draw_target()
	_draw_shockwave()
	_draw_avatar()


func _draw_target() -> void:
	var progress := _hold / HOLD_TIME
	var pulse := 0.5 + 0.5 * sin(_pulse * 4.0)
	var color := TARGET_COLOR.lerp(TARGET_HOT_COLOR, progress)
	var fill := color
	fill.a = lerpf(0.22, 0.4, pulse) + progress * 0.3
	draw_rect(_target_rect, fill, true)
	var border := color
	border.a = 0.85
	draw_rect(_target_rect, border, false, lerpf(3.0, 5.0, pulse) + progress * 2.0)


func _draw_shockwave() -> void:
	var span := 0.7
	if _burst_time > span:
		return
	var t := _burst_time / span
	var color := Color(1.0, 0.95, 0.7, 1.0 - t)
	draw_arc(_burst_point, lerpf(18.0, 170.0, sqrt(t)), 0.0, TAU, 64, color, lerpf(8.0, 1.0, t), true)


func _draw_avatar() -> void:
	var ring := StickRegions.ring_for(stick.length())
	var can_move := not _celebrating
	var is_moving := can_move and ring >= 0

	if can_move:
		var tint: Color = TIER_COLORS[ring] if ring >= 0 else AVATAR_COLOR
		if is_moving:
			_draw_speed_wedge(ring, tint)
		var glow := tint
		glow.a = 0.22
		draw_circle(avatar_pos, AVATAR_RADIUS * 1.7, glow)
		draw_circle(avatar_pos, AVATAR_RADIUS, tint)
		if is_moving:
			_draw_direction_arrow(ring, tint)

	draw_circle(avatar_pos, AVATAR_RADIUS * 0.4, Color(1, 1, 1, 0.9))

	if _hold > 0.0:
		var progress := _hold / HOLD_TIME
		draw_arc(
			avatar_pos, AVATAR_RADIUS + 9.0,
			-PI * 0.5, -PI * 0.5 + TAU * progress,
			48, TARGET_HOT_COLOR, 5.0, true
		)


func _draw_speed_wedge(ring: int, tint: Color) -> void:
	var angle := stick.angle()
	var pulse := 0.5 + 0.5 * sin(_pulse * 6.0)
	var color := tint
	color.a = lerpf(0.14, 0.28, pulse)
	draw_colored_polygon(AnnularSector.build(
		avatar_pos,
		AVATAR_RADIUS * 0.55,
		WEDGE_LENGTHS[ring],
		angle - WEDGE_SPAN,
		angle + WEDGE_SPAN
	), color)


func _draw_direction_arrow(ring: int, tint: Color) -> void:
	var dir := stick.normalized()
	var side := Vector2(-dir.y, dir.x)
	var arrow_size: float = ARROW_SIZES[ring]
	var base_center := avatar_pos + dir * (AVATAR_RADIUS + 10.0)
	var tip: Vector2 = base_center + dir * arrow_size
	var points := PackedVector2Array([
		tip,
		base_center + side * arrow_size * 0.42,
		base_center - side * arrow_size * 0.42,
	])
	draw_colored_polygon(points, tint)


func _burst(at: Vector2, amount: int) -> void:
	_confetti.position = at
	_confetti.amount = amount
	_confetti.restart()
