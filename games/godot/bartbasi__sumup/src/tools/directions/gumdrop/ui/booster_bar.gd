extends Control
## Gumdrop booster bar: a floating candy dock with five raised booster
## buttons, and a lemon hint pill above it while a booster is targeting.
## Placed full width; the dock keeps board_margin from the screen sides.
## The hint row is always reserved, so the dock never moves.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal booster_pressed(booster_id: String)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconView: GDScript = preload("res://tools/directions/gumdrop/ui/icon_view.gd")
const BoosterButton: GDScript = preload("res://tools/directions/gumdrop/ui/booster_button.gd")
const ThemeKit: GDScript = preload("res://tools/directions/ui_common/theme_kit.gd")

var _tokens: DirectionTokens = null
var _buttons: Array[BoosterButton] = []
var _dock_style: StyleBoxFlat = null
var _hint_style: StyleBoxFlat = null
var _hint_text: String = ""
var _hint_font: Font = null
var _hint_size: int = 16
var _hint_rect: Rect2 = Rect2()
var _hint_origin: Vector2 = Vector2.ZERO


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	var lip: float = tokens.num("button_lip")
	_dock_style = ThemeKit.box(tokens.color("surface"), tokens.num("dock_radius"))
	_dock_style.border_color = tokens.color("surface_lip")
	_dock_style.border_width_bottom = roundi(lip)
	_hint_style = ThemeKit.box(tokens.color("lemon"), tokens.num("pill_radius"))
	_hint_style.border_color = tokens.color("lemon_lip")
	_hint_style.border_width_bottom = roundi(lip)
	_hint_font = tokens.font("label")
	_hint_size = tokens.font_size("label")
	_layout()


## active_id is "" when no booster is targeting.
func show_boosters(ids: PackedStringArray, costs: PackedInt32Array, affordable: Array[bool], active_id: String) -> void:
	while _buttons.size() > ids.size():
		var extra: BoosterButton = _buttons.pop_back()
		extra.queue_free()
	while _buttons.size() < ids.size():
		var button: BoosterButton = BoosterButton.new()
		button.pressed.connect(_on_button_pressed)
		add_child(button)
		_buttons.append(button)
	for i: int in ids.size():
		_buttons[i].setup(_tokens, ids[i], costs[i])
		var look: int = IconView.LOOK_NORMAL
		if ids[i] == active_id:
			look = IconView.LOOK_ACTIVE
		elif not affordable[i]:
			look = IconView.LOOK_DISABLED
		_buttons[i].set_look(look)
	_layout()


## Targeting hint above the bar. "" hides it.
func set_hint(text: String) -> void:
	_hint_text = _tokens.cased("label", text) if _tokens != null else text
	_layout()


func preferred_height() -> float:
	return _tokens.num("pill_height") + _tokens.num("space_s") + _tokens.num("dock_height")


## Local y where the always visible part starts: the dock top. Above it is
## the hint row, empty while no hint shows. Valid once the bar has its size.
func content_top() -> float:
	return _dock_rect().position.y


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _dock_rect() -> Rect2:
	var margin: float = _tokens.num("board_margin")
	var dock_height: float = _tokens.num("dock_height")
	return Rect2(margin, size.y - dock_height, size.x - margin * 2.0, dock_height)


func _layout() -> void:
	if _tokens == null:
		return
	var dock: Rect2 = _dock_rect()
	var pad: float = _tokens.num("space_s")
	var gap: float = _tokens.num("space_xs")
	var face_height: float = dock.size.y - _tokens.num("button_lip")
	var count: int = _buttons.size()
	if count > 0:
		var width: float = (dock.size.x - pad * 2.0 - gap * float(count - 1)) / float(count)
		var height: float = face_height - pad * 2.0
		for i: int in count:
			_buttons[i].position = Vector2(dock.position.x + pad + (width + gap) * float(i), dock.position.y + pad)
			_buttons[i].size = Vector2(width, height)
	if not _hint_text.is_empty():
		var text_width: float = _hint_font.get_string_size(_hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _hint_size).x
		var pill_height: float = _tokens.num("pill_height")
		var pill_width: float = text_width + _tokens.num("space_m") * 2.0
		_hint_rect = Rect2((size.x - pill_width) * 0.5, dock.position.y - pad - pill_height, pill_width, pill_height)
		var face_line: float = pill_height - _tokens.num("button_lip")
		var line: float = _hint_font.get_height(_hint_size)
		_hint_origin = Vector2(_hint_rect.position.x, _hint_rect.position.y + (face_line - line) * 0.5 + _hint_font.get_ascent(_hint_size))
	queue_redraw()


func _draw() -> void:
	if _tokens == null:
		return
	draw_style_box(_dock_style, _dock_rect())
	if not _hint_text.is_empty():
		draw_style_box(_hint_style, _hint_rect)
		# Text pair: ink_dark on lemon.
		draw_string(_hint_font, _hint_origin, _hint_text, HORIZONTAL_ALIGNMENT_CENTER, _hint_rect.size.x, _hint_size, _tokens.color("ink_dark"))


func _on_button_pressed(booster_id: String) -> void:
	booster_pressed.emit(booster_id)
