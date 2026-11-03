extends Control

const SLOTS := 3
const MARK_SIZE := 40.0
const GAP := 14.0
const FLASH_TIME := 0.45

const EMPTY_COLOR := Color(0.24, 0.28, 0.44)
const EMPTY_RING_COLOR := Color(0.40, 0.46, 0.66)
const LOST_COLOR := Color(1.0, 0.32, 0.36)
const CROSS_COLOR := Color(1.0, 0.92, 0.92)

var used: int = 0: set = set_used

var _flash: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(SLOTS * MARK_SIZE + (SLOTS - 1) * GAP, MARK_SIZE + 8.0)
	set_process(false)


func set_used(value: int) -> void:
	if value > used:
		_flash = FLASH_TIME
		set_process(true)
	used = value
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if _flash <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var step := MARK_SIZE + GAP
	var total := SLOTS * MARK_SIZE + (SLOTS - 1) * GAP
	var left := (size.x - total) * 0.5 + MARK_SIZE * 0.5
	for i in SLOTS:
		var center := Vector2(left + i * step, size.y * 0.5)
		if i < used:
			_draw_lost(center, i == used - 1)
		else:
			_draw_open(center)


func _draw_open(center: Vector2) -> void:
	draw_circle(center, MARK_SIZE * 0.42, EMPTY_COLOR)
	draw_arc(center, MARK_SIZE * 0.42, 0.0, TAU, 32, EMPTY_RING_COLOR, 2.0, true)


func _draw_lost(center: Vector2, newest: bool) -> void:
	var eased := _flash / FLASH_TIME if newest else 0.0
	var radius := MARK_SIZE * lerpf(0.42, 0.56, eased)
	var glow := LOST_COLOR
	glow.a = lerpf(0.0, 0.45, eased)
	draw_circle(center, radius * 1.5, glow)
	draw_circle(center, radius, LOST_COLOR)
	var arm := radius * 0.46
	draw_line(center - Vector2(arm, arm), center + Vector2(arm, arm), CROSS_COLOR, 4.0, true)
	draw_line(center - Vector2(arm, -arm), center + Vector2(arm, -arm), CROSS_COLOR, 4.0, true)
