class_name Player
extends Node2D
## The player's ship. Keyboard (WASD / arrows + Space), mouse drag and
## touch drag all work, so the same build plays on Web and mobile.

signal fired(pos: Vector2, dir: Vector2, damage: int)
signal health_changed(hp: int, max_hp: int)
signal died

const TEX := preload("res://assets/sprites/player.svg")
const BASE_FIRE_INTERVAL := 0.22

var max_hp := 100
var hp := 100
var speed := 560.0
var radius := 26.0
var weapon_level := 1
var alive := true

var _fire_timer := 0.0
var _rapid_until := 0
var _shield_until := 0
var _dragging := false
var _drag_target := Vector2.ZERO
var _sprite: Sprite2D
var _flame: Polygon2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.scale = Vector2(0.62, 0.62)
	add_child(_sprite)
	_flame = Polygon2D.new()
	_flame.polygon = PackedVector2Array([Vector2(-9, 30), Vector2(9, 30), Vector2(0, 52)])
	_flame.color = Color(1.0, 0.55, 0.15, 0.9)
	_flame.z_index = -1
	add_child(_flame)
	_drag_target = position

func is_shielded() -> bool:
	return Time.get_ticks_msec() < _shield_until

func fire_interval() -> float:
	if Time.get_ticks_msec() < _rapid_until:
		return 0.11
	return BASE_FIRE_INTERVAL

func _input(event: InputEvent) -> void:
	if not alive:
		return
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		if event.pressed:
			_drag_target = event.position
	elif event is InputEventScreenDrag:
		_drag_target = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_drag_target = event.position
	elif event is InputEventMouseMotion and _dragging:
		_drag_target = event.position

func _process(delta: float) -> void:
	if not alive:
		return
	var view := get_viewport_rect().size
	# Keyboard movement.
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if dir != Vector2.ZERO:
		position += dir.normalized() * speed * delta
		_drag_target = position
	elif _dragging:
		var to_target := _drag_target - position
		var step := speed * 1.9 * delta
		if to_target.length() > 2.0:
			position += to_target.normalized() * minf(step, to_target.length())
	position.x = clampf(position.x, 36.0, view.x - 36.0)
	position.y = clampf(position.y, 60.0, view.y - 46.0)
	_sprite.rotation = clampf(dir.x * 0.18 + (_drag_target.x - position.x) * 0.0006, -0.3, 0.3)
	_flame.scale.y = randf_range(0.8, 1.35)
	# Firing: hold Space, touch, or mouse.
	_fire_timer -= delta
	var wants_fire := Input.is_key_pressed(KEY_SPACE) or _dragging
	if wants_fire and _fire_timer <= 0.0:
		_fire_timer = fire_interval()
		_shoot()
	queue_redraw()  # keeps the shield ring in sync

func _shoot() -> void:
	Sfx.play_shoot()
	var nose := position + Vector2(0, -34)
	match weapon_level:
		1:
			fired.emit(nose, Vector2.UP, 1)
		2:
			fired.emit(nose + Vector2(-13, 6), Vector2.UP, 1)
			fired.emit(nose + Vector2(13, 6), Vector2.UP, 1)
		_:
			fired.emit(nose, Vector2.UP, 1)
			fired.emit(nose + Vector2(-16, 8), Vector2(-0.14, -1).normalized(), 1)
			fired.emit(nose + Vector2(16, 8), Vector2(0.14, -1).normalized(), 1)

func take_damage(amount: int) -> void:
	if not alive:
		return
	if is_shielded():
		Sfx.play_hit()
		return
	hp = maxi(0, hp - amount)
	if weapon_level > 1:
		weapon_level -= 1
	Sfx.play_hit()
	health_changed.emit(hp, max_hp)
	_sprite.modulate = Color(3, 0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.18)
	if hp <= 0:
		alive = false
		visible = false
		died.emit()

func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)

func apply_powerup(kind: String) -> void:
	Sfx.play_powerup()
	match kind:
		"rapid":
			_rapid_until = Time.get_ticks_msec() + 8000
		"triple":
			weapon_level = mini(3, weapon_level + 1)
		"shield":
			_shield_until = Time.get_ticks_msec() + 6000
		"life":
			heal(30)
	queue_redraw()

func _draw() -> void:
	if is_shielded():
		draw_arc(Vector2.ZERO, 40.0, 0, TAU, 40, Color(0.4, 0.7, 1.0, 0.85), 3.0)
		draw_circle(Vector2.ZERO, 40.0, Color(0.3, 0.6, 1.0, 0.10))
