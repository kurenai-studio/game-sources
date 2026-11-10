class_name ScrollPaper
extends Control
# Пергаментный свиток с деревянными валиками сверху и снизу.
# Всё содержимое кладётся в content; если оно длиннее свитка — его можно
# прокручивать пальцем (или колёсиком мыши).
# roll_up() — свиток сворачивается к верхнему валику и уезжает вверх,
# unroll() — разворачивается обратно.

signal rolled_up

const PAPER := Color(0.93, 0.85, 0.66)
const PAPER_EDGE := Color(0.78, 0.64, 0.42)
const WOOD := Color(0.45, 0.27, 0.14)
const INK := Color(0.28, 0.17, 0.08)
const ROLLER_H := 30.0

var paper_rect := Rect2()          # где лежит развёрнутый пергамент
var content: Control               # сюда кладётся содержимое
var content_height := 0.0          # полная высота содержимого (для прокрутки)

var _clip: Control
var _paper: Panel
var _top_roller: Control
var _bottom_roller: Control
var _scroll := 0.0
var _drag := false
var _drag_moved := 0.0
var _tw: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = PAPER
	st.border_color = PAPER_EDGE
	st.border_width_left = 6
	st.border_width_right = 6
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 10
	_paper.add_theme_stylebox_override("panel", st)
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	# пятна старости на пергаменте
	for i in 14:
		var spot := ColorRect.new()
		spot.color = Color(0.7, 0.55, 0.3, 0.08)
		var sz := randf_range(20, 70)
		spot.size = Vector2(sz, sz * randf_range(0.4, 0.9))
		spot.position = Vector2(randf_range(10, paper_rect.size.x - 80), randf_range(10, paper_rect.size.y - 50))
		spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_paper.add_child(spot)
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_clip)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(content)
	_top_roller = _roller()
	_bottom_roller = _roller()
	_layout(1.0, 0.0)

func _roller() -> Control:
	var r := Control.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := paper_rect.size.x + 70.0
	var body := ColorRect.new()
	body.color = WOOD
	body.size = Vector2(w, ROLLER_H)
	body.position = Vector2(-35, -ROLLER_H / 2)
	r.add_child(body)
	var shine := ColorRect.new()
	shine.color = WOOD.lightened(0.25)
	shine.size = Vector2(w, 6)
	shine.position = Vector2(-35, -ROLLER_H / 2 + 5)
	r.add_child(shine)
	for side in [-50.0, paper_rect.size.x + 30.0]:
		var knob := ColorRect.new()
		knob.color = WOOD.darkened(0.3)
		knob.size = Vector2(20, ROLLER_H + 14)
		knob.position = Vector2(side, -ROLLER_H / 2 - 7)
		r.add_child(knob)
	add_child(r)
	return r

# open: 1 — свиток развёрнут, 0 — свёрнут; lift — на сколько свёрнутый свиток поднят вверх
func _layout(open: float, lift: float) -> void:
	var h := paper_rect.size.y * open
	_paper.position = paper_rect.position - Vector2(0, lift)
	_paper.size = Vector2(paper_rect.size.x, maxf(h, 0.0))
	_clip.position = Vector2(20, 12)
	_clip.size = Vector2(paper_rect.size.x - 40, maxf(h - 24.0, 0.0))
	_top_roller.position = paper_rect.position - Vector2(0, lift)
	_bottom_roller.position = paper_rect.position + Vector2(0, h - lift)
	_paper.visible = h > 2.0

func set_open(v: float) -> void:
	_layout(v, 0.0)

func set_lift(v: float) -> void:
	_layout(0.0, v)

func roll_up() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_method(set_open, 1.0, 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tw.tween_method(set_lift, 0.0, paper_rect.position.y + 80.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tw.tween_callback(func(): rolled_up.emit())

func unroll() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_method(set_lift, paper_rect.position.y + 80.0, 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_method(set_open, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# ---------- Прокрутка ----------
func max_scroll() -> float:
	return maxf(0.0, content_height - _clip.size.y)

func scroll_to(y: float, smooth := true) -> void:
	var target := clampf(y, 0.0, max_scroll())
	if smooth:
		var t := create_tween()
		t.tween_method(_set_scroll, _scroll, target, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_set_scroll(target)

func _set_scroll(v: float) -> void:
	_scroll = clampf(v, 0.0, max_scroll())
	content.position.y = -_scroll

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _paper.visible:
		return
	var r := Rect2(_paper.global_position, _paper.size)
	if event is InputEventMouseButton:
		if not r.has_point(event.position):
			if not event.pressed:
				_drag = false
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_scroll(_scroll + 60.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_scroll(_scroll - 60.0)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag = true
				_drag_moved = 0.0
			else:
				# это была прокрутка, а не нажатие — кнопку под пальцем не нажимаем
				if _drag and _drag_moved > 14.0:
					get_viewport().set_input_as_handled()
					_release_buttons(content)
				_drag = false
	elif event is InputEventMouseMotion and _drag:
		_drag_moved += absf(event.relative.y)
		_set_scroll(_scroll - event.relative.y)

func _release_buttons(n: Node) -> void:
	for c in n.get_children():
		if c is BaseButton:
			c.button_pressed = false if c.toggle_mode else c.button_pressed
			c.release_focus()
		_release_buttons(c)
