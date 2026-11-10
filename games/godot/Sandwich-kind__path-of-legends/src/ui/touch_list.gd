class_name TouchList
extends Control
# ---------- Прокрутка списка пальцем ----------
# Лежит прозрачной плёнкой поверх ScrollContainer и решает, что делает палец:
#   • провёл вверх-вниз — список едет за пальцем (и катится дальше по инерции);
#   • коснулся и отпустил почти на месте — нажимается кнопка под пальцем;
#   • колёсико мыши — тоже крутит список.
# Так кнопки в списке не «перехватывают» палец и не выделяются, пока листаешь.
# Геймпад и клавиатура работают как раньше (кнопкам можно ставить фокус).

const DRAG := 14.0            # на сколько пикселей сдвинуть палец, чтобы это была прокрутка

var scroll: ScrollContainer
var _down := false
var _start := Vector2.ZERO
var _v0 := 0.0
var _moved := false
var _vel := 0.0
var _last_y := 0.0
var _last_ms := 0
var _hot: BaseButton
var _pos := 0.0

# Накрыть плёнкой список sc (плёнка — соседний узел поверх, того же размера)
static func attach(sc: ScrollContainer) -> TouchList:
	var t := TouchList.new()
	t.scroll = sc
	t.position = sc.position
	t.size = sc.size - Vector2(16, 0)      # полоса прокрутки справа остаётся — её можно тянуть мышью
	sc.get_parent().add_child(t)
	return t

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_vel = 0.0
			scroll.scroll_vertical += -70 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else 70
			accept_event()
			return
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_press(ev.position)
			else:
				_release(ev.position)
			accept_event()
	elif ev is InputEventMouseMotion and _down:
		_drag(ev.position)
		accept_event()

func _press(at: Vector2) -> void:
	_down = true
	_moved = false
	_start = at
	_vel = 0.0
	_pos = float(scroll.scroll_vertical)
	_v0 = _pos
	_last_y = at.y
	_last_ms = Time.get_ticks_msec()
	_set_hot(_button_at(at))

func _drag(at: Vector2) -> void:
	var dy := at.y - _start.y
	if not _moved and absf(dy) > DRAG:
		_moved = true
		_set_hot(null)                     # листаем — кнопка под пальцем не нажимается
	if _moved:
		_pos = clampf(_v0 - dy, 0.0, _max_scroll())
		scroll.scroll_vertical = int(_pos)
		var now := Time.get_ticks_msec()
		var dt := maxf(0.001, (now - _last_ms) / 1000.0)
		_vel = lerpf(_vel, -(at.y - _last_y) / dt, 0.5)
		_last_y = at.y
		_last_ms = now

func _release(at: Vector2) -> void:
	if not _down:
		return
	_down = false
	var b := _hot
	_set_hot(null)
	if _moved:
		if Time.get_ticks_msec() - _last_ms > 90:
			_vel = 0.0                     # палец остановили перед тем, как отпустить
		return
	b = _button_at(at)
	if b and not b.disabled:
		if b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
		b.pressed.emit()

func _process(delta: float) -> void:
	if _down or absf(_vel) < 20.0:
		return
	_pos = clampf(float(scroll.scroll_vertical) + _vel * delta, 0.0, _max_scroll())
	scroll.scroll_vertical = int(_pos)
	_vel *= pow(0.04, delta)               # плавно тормозит
	if _pos <= 0.0 or _pos >= _max_scroll():
		_vel = 0.0

func _max_scroll() -> float:
	var bar := scroll.get_v_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page) if bar else 0.0

# Кнопка списка под точкой (координаты плёнки)
func _button_at(at: Vector2) -> BaseButton:
	var g := get_global_transform() * at
	if not scroll.get_global_rect().has_point(g):
		return null
	var stack: Array = [scroll]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is BaseButton and n.is_visible_in_tree() and (n as Control).get_global_rect().has_point(g):
			return n
	return null

# Подсветка кнопки, пока палец на ней (как у обычного нажатия)
func _set_hot(b: BaseButton) -> void:
	if _hot and is_instance_valid(_hot):
		_hot.self_modulate = Color.WHITE
	_hot = b
	if _hot:
		_hot.self_modulate = Color(1.3, 1.3, 1.3)
