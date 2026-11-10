class_name VirtualStick
extends Node2D
# ---------- Виртуальный стик (телефон) ----------
# Коснись в своей зоне — там появится стик; веди пальцем: влево/вправо — ходьба,
# вверх — прыжок, вниз — спрыгнуть с платформы. Отпустил — стик возвращается.
# Работает с несколькими касаниями: второй палец жмёт кнопки способностей.

var prefix := "p1"
var area := Rect2()           # где можно ставить палец (в пикселях экрана)
var radius := 62.0
var _touch := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO     # смещение -1..1
var _home := Vector2.ZERO
var _held := {}

const DEAD := 0.28

func _ready() -> void:
	_home = Vector2(area.position.x + area.size.x * 0.5, area.end.y - radius - 18.0)
	_center = _home

func _input(event: InputEvent) -> void:
	var idx := -2
	var pos := Vector2.ZERO
	var pressed := false
	var moved := false
	if event is InputEventScreenTouch:
		idx = event.index
		pos = event.position
		pressed = event.pressed
	elif event is InputEventScreenDrag:
		idx = event.index
		pos = event.position
		moved = true
	else:
		return
	if moved:
		if idx == _touch:
			_drag(pos)
		return
	if pressed and _touch == -1 and area.has_point(pos):
		_touch = idx
		_center = pos
		_drag(pos)
	elif not pressed and idx == _touch:
		_release()

func _drag(pos: Vector2) -> void:
	var v := (pos - _center) / radius
	if v.length() > 1.0:
		# палец ушёл дальше края — стик «едет» за ним
		_center = pos - v.normalized() * radius
		v = v.normalized()
	_knob = v
	_hold_action("left", maxf(0.0, -v.x) if v.x < -DEAD else 0.0)
	_hold_action("right", maxf(0.0, v.x) if v.x > DEAD else 0.0)
	_hold_action("jump", 1.0 if v.y < -0.62 else 0.0)
	_hold_action("down", 1.0 if v.y > 0.62 and absf(v.x) < 0.75 else 0.0)
	queue_redraw()

func _release() -> void:
	_touch = -1
	_knob = Vector2.ZERO
	_center = _home
	for a in ["left", "right", "jump", "down"]:
		_hold_action(a, 0.0)
	queue_redraw()

func _hold_action(a: String, strength: float) -> void:
	var action := prefix + "_" + a
	if strength > 0.0:
		Input.action_press(action, strength)
		_held[a] = true
	elif _held.get(a, false):
		Input.action_release(action)
		_held[a] = false

func _exit_tree() -> void:
	_release()

func _draw() -> void:
	draw_circle(_center, radius + 6.0, Color(0, 0, 0, 0.25))
	draw_arc(_center, radius, 0.0, TAU, 40, Color(1, 1, 1, 0.55), 4.0)
	for a in [0.0, PI / 2, PI, PI * 1.5]:            # засечки направлений
		var d := Vector2(cos(a), sin(a))
		draw_line(_center + d * (radius - 14.0), _center + d * (radius - 4.0), Color(1, 1, 1, 0.5), 3.0)
	var k := _center + _knob * radius
	draw_circle(k, radius * 0.45, Color(1, 1, 1, 0.55 if _touch != -1 else 0.35))
	draw_circle(k + Vector2(-4, -5), radius * 0.18, Color(1, 1, 1, 0.35))
