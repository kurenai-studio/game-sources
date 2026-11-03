extends Control

signal stars_changed(stars: int)
signal star_won(total: int)
signal round_complete()
signal prompt_changed(text: String)
signal region_entered(ring: int, direction: int)
signal holding_changed(active: bool)

const StarShape := preload("res://scripts/star_shape.gd")
const StickRegions := preload("res://scripts/stick_regions.gd")
const StickInput := preload("res://scripts/stick_input.gd")
const ConfettiBurst := preload("res://scripts/confetti_burst.gd")
const AnnularSector := preload("res://scripts/annular_sector.gd")

enum State { EXPLORE, AIM, CELEBRATE, RECENTER }

const RADIUS := 180.0
const DIRECTION_NAMES := ["UP", "RIGHT", "DOWN", "LEFT"]
const GOAL := 5
const HOLD_TIME := 0.8
const CELEBRATE_TIME := 1.5
const ROUND_CELEBRATE_TIME := 2.6
const HOME_RADIUS := 0.16
const DRIFT_DEADZONE := 0.09
const CURSOR_RADIUS := 17.0

const FIELD_COLOR := Color(0.11, 0.14, 0.25)
const BAND_COLOR := Color(0.15, 0.19, 0.33)
const CORE_COLOR := Color(0.09, 0.11, 0.2)
const GUIDE_COLOR := Color(0.22, 0.27, 0.44)
const TARGET_COLOR := Color(1.0, 0.78, 0.28)
const TARGET_HOT_COLOR := Color(0.42, 0.95, 0.6)
const CURSOR_COLOR := Color(0.42, 0.86, 1.0)
const HOME_COLOR := Color(0.55, 0.78, 1.0)
const EXPLORE_COLOR := Color(0.58, 0.72, 1.0)

var device: int = -1
var stick: Vector2 = Vector2.ZERO

var _state: State = State.EXPLORE
var _direction: int = 0
var _ring: int = 1
var _stars: int = 0
var _total: int = 0
var _hold: float = 0.0
var _timer: float = 0.0
var _pulse: float = 0.0
var _burst_point: Vector2 = Vector2.ZERO
var _burst_time: float = 0.0
var _prompt: String = ""
var _explore_ring: int = -2
var _explore_direction: int = -2
var _was_on_target: bool = false
var _confetti: CPUParticles2D


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * (RADIUS * 2.0 + 40.0)
	_confetti = ConfettiBurst.build()
	add_child(_confetti)
	_enter_explore()


func _process(delta: float) -> void:
	_pulse += delta
	stick = StickInput.read(device, DRIFT_DEADZONE)
	match _state:
		State.EXPLORE:
			_process_explore()
		State.AIM:
			_process_aim(delta)
		State.CELEBRATE:
			_timer -= delta
			_burst_time += delta
			if _timer <= 0.0:
				_enter_recenter()
		State.RECENTER:
			_burst_time += delta
			if stick.length() < HOME_RADIUS:
				_next_target()
	queue_redraw()


func current_prompt() -> String:
	return _prompt


func is_exploring() -> bool:
	return _state == State.EXPLORE


func start_from_explore() -> void:
	if _state == State.EXPLORE:
		_next_target()


func reset() -> void:
	_stars = 0
	_total = 0
	stars_changed.emit(_stars)
	_enter_explore()


func _enter_explore() -> void:
	_state = State.EXPLORE
	_explore_ring = -2
	_explore_direction = -2
	_set_prompt("Move the stick around! Press B to start")


func _process_explore() -> void:
	var ring := StickRegions.ring_for(stick.length())
	var direction := -1
	if ring >= 0:
		direction = int(round((stick.angle() + PI * 0.5) / (PI * 0.5)))
		direction = ((direction % 4) + 4) % 4
	if ring != _explore_ring or direction != _explore_direction:
		_explore_ring = ring
		_explore_direction = direction
		region_entered.emit(ring, direction)


func _process_aim(delta: float) -> void:
	var on_target := _on_target()
	if on_target != _was_on_target:
		_was_on_target = on_target
		holding_changed.emit(on_target)
	if on_target:
		_hold = minf(_hold + delta, HOLD_TIME)
		if _hold >= HOLD_TIME:
			_succeed()
	else:
		_hold = maxf(_hold - delta * 0.75, 0.0)


func _on_target() -> bool:
	var magnitude := stick.length()
	if magnitude < StickRegions.EDGES[_ring] or magnitude > StickRegions.EDGES[_ring + 1]:
		return false
	return absf(stick.angle_to(_direction_vector(_direction))) <= PI * 0.25


func _succeed() -> void:
	_was_on_target = false
	holding_changed.emit(false)
	_stars += 1
	_total += 1
	_hold = 0.0
	_state = State.CELEBRATE
	_burst_point = size * 0.5 + stick * RADIUS
	_burst_time = 0.0
	star_won.emit(_total)
	stars_changed.emit(_stars)

	if _stars >= GOAL:
		_timer = ROUND_CELEBRATE_TIME
		_burst(_burst_point, 180)
		_burst_point = size * 0.5
		round_complete.emit()
		_set_prompt("You did it! All five stars!")
	else:
		_timer = CELEBRATE_TIME
		_burst(_burst_point, 70)
		_set_prompt("Great job!")


func _enter_recenter() -> void:
	if _stars >= GOAL:
		_stars = 0
		stars_changed.emit(_stars)
	_state = State.RECENTER
	_set_prompt("Let go, back to the middle")


func _next_target() -> void:
	var direction := _direction
	var ring := _ring
	while direction == _direction and ring == _ring:
		direction = randi() % 4
		ring = randi() % 3
	_direction = direction
	_ring = ring
	_hold = 0.0
	_was_on_target = false
	_state = State.AIM
	_set_prompt("Push %s to the %s ring" % [
		DIRECTION_NAMES[_direction], StickRegions.NAMES[_ring]
	])


func _set_prompt(text: String) -> void:
	_prompt = text
	prompt_changed.emit(text)


func _direction_vector(index: int) -> Vector2:
	return Vector2.from_angle(index * PI * 0.5 - PI * 0.5)


func _target_point() -> Vector2:
	var mid := (StickRegions.EDGES[_ring] + StickRegions.EDGES[_ring + 1]) * 0.5
	return size * 0.5 + _direction_vector(_direction) * mid * RADIUS


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, RADIUS, BAND_COLOR)
	draw_circle(center, StickRegions.EDGES[2] * RADIUS, FIELD_COLOR)
	draw_circle(center, StickRegions.EDGES[1] * RADIUS, BAND_COLOR)
	draw_circle(center, StickRegions.EDGES[0] * RADIUS, CORE_COLOR)

	if _state == State.AIM:
		_draw_target(center)
	elif _state == State.EXPLORE:
		_draw_explore_highlight(center)

	for i in 4:
		var angle := i * PI * 0.5 + PI * 0.25
		var edge := Vector2(cos(angle), sin(angle))
		draw_line(
			center + edge * StickRegions.EDGES[0] * RADIUS, center + edge * RADIUS, GUIDE_COLOR, 2.0
		)
	for i in 3:
		draw_arc(center, StickRegions.EDGES[i + 1] * RADIUS, 0.0, TAU, 72, GUIDE_COLOR, 2.0, true)

	if _state == State.RECENTER:
		_draw_home(center)
	if _state == State.CELEBRATE or _state == State.RECENTER:
		_draw_shockwave()

	_draw_cursor(center)


func _draw_target(center: Vector2) -> void:
	var progress := _hold / HOLD_TIME
	var pulse := 0.5 + 0.5 * sin(_pulse * 4.0)
	var base := TARGET_COLOR.lerp(TARGET_HOT_COLOR, progress)
	var angle := _direction_vector(_direction).angle()
	var fill := base
	fill.a = lerpf(0.34, 0.55, pulse) + progress * 0.35
	draw_colored_polygon(AnnularSector.build(
		center,
		StickRegions.EDGES[_ring] * RADIUS,
		StickRegions.EDGES[_ring + 1] * RADIUS,
		angle - PI * 0.25,
		angle + PI * 0.25
	), fill)

	var marker := _target_point()
	var spin := _pulse * 0.6
	var star_size := lerpf(20.0, 26.0, pulse) + progress * 10.0
	var star_color := base
	star_color.a = 0.75 + progress * 0.25
	draw_colored_polygon(StarShape.points(marker, star_size, star_size * 0.44, spin), star_color)

	if progress > 0.0:
		var ring_center := center + stick * RADIUS
		draw_arc(
			ring_center, CURSOR_RADIUS + 9.0,
			-PI * 0.5, -PI * 0.5 + TAU * progress,
			48, TARGET_HOT_COLOR, 6.0, true
		)


func _draw_explore_highlight(center: Vector2) -> void:
	if _explore_ring < 0:
		return
	var pulse := 0.5 + 0.5 * sin(_pulse * 3.0)
	var angle := _direction_vector(_explore_direction).angle()
	var fill := EXPLORE_COLOR
	fill.a = lerpf(0.26, 0.44, pulse)
	draw_colored_polygon(AnnularSector.build(
		center,
		StickRegions.EDGES[_explore_ring] * RADIUS,
		StickRegions.EDGES[_explore_ring + 1] * RADIUS,
		angle - PI * 0.25,
		angle + PI * 0.25
	), fill)


func _draw_home(center: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(_pulse * 5.0)
	var color := HOME_COLOR
	color.a = lerpf(0.35, 0.8, pulse)
	draw_arc(
		center, StickRegions.EDGES[0] * RADIUS * lerpf(0.75, 1.0, pulse), 0.0, TAU, 48, color, 5.0, true
	)


func _draw_shockwave() -> void:
	var span := 0.7
	if _burst_time > span:
		return
	var t := _burst_time / span
	var color := Color(1.0, 0.95, 0.7, 1.0 - t)
	draw_arc(_burst_point, lerpf(18.0, 190.0, sqrt(t)), 0.0, TAU, 64, color, lerpf(9.0, 1.0, t), true)


func _draw_cursor(center: Vector2) -> void:
	var point := center + stick * RADIUS
	var glow := CURSOR_COLOR
	glow.a = 0.22
	draw_circle(point, CURSOR_RADIUS * 1.9, glow)
	draw_circle(point, CURSOR_RADIUS, CURSOR_COLOR)
	draw_circle(point, CURSOR_RADIUS * 0.45, Color(1, 1, 1, 0.9))


func _burst(at: Vector2, amount: int) -> void:
	_confetti.position = at
	_confetti.amount = amount
	_confetti.restart()
