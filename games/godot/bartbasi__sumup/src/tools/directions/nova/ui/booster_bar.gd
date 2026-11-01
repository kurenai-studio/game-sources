extends Control
## Nova booster bar: five ring buttons in a row with no container, cost
## under each ring, and while targeting a centered ink_muted hint above them
## with no panel. Placed full width; the rings share the width inside
## board_margin. The hint row is always reserved, so the rings never move.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal booster_pressed(booster_id: String)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconView: GDScript = preload("res://tools/directions/nova/ui/icon_view.gd")
const BoosterButton: GDScript = preload("res://tools/directions/nova/ui/booster_button.gd")

var _tokens: DirectionTokens = null
var _buttons: Array[BoosterButton] = []
var _hint_text: String = ""
var _font: Font = null
var _font_size: int = 16
var _hint_origin: Vector2 = Vector2.ZERO


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	_font = tokens.font("label")
	_font_size = tokens.font_size("label")
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


## Targeting hint above the rings. "" hides it.
func set_hint(text: String) -> void:
	_hint_text = _tokens.cased("label", text) if _tokens != null else text
	queue_redraw()


func preferred_height() -> float:
	return _hint_height() + _tokens.num("space_xs") + BoosterButton.needed_height(_tokens)


## Local y where the always visible part starts: the top of the ring row.
## Above it are the hint row, empty while no hint shows, and the room for an
## active ring's glow, which reaches (ring_glow_spread - 1) times the ring
## radius above the rings. Valid once the bar has its size.
func content_top() -> float:
	var radius: float = _tokens.num("ring_button") * 0.5
	var glow_overhang: float = radius * (_tokens.num("ring_glow_spread") - 1.0)
	return size.y - BoosterButton.needed_height(_tokens) + glow_overhang


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _hint_height() -> float:
	return _font.get_height(_font_size)


func _layout() -> void:
	if _tokens == null:
		return
	var margin: float = _tokens.num("board_margin")
	var count: int = _buttons.size()
	var top: float = size.y - BoosterButton.needed_height(_tokens)
	if count > 0:
		var slot: float = (size.x - margin * 2.0) / float(count)
		for i: int in count:
			_buttons[i].position = Vector2(margin + slot * float(i), top)
			_buttons[i].size = Vector2(slot, BoosterButton.needed_height(_tokens))
	_hint_origin = Vector2(0.0, top - _tokens.num("space_xs") - _hint_height() + _font.get_ascent(_font_size))
	queue_redraw()


func _draw() -> void:
	if _tokens == null or _hint_text.is_empty():
		return
	# Text pair: ink_muted on bg_glow, the worst case of the backdrop.
	draw_string(_font, _hint_origin, _hint_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, _font_size, _tokens.color("ink_muted"))


func _on_button_pressed(booster_id: String) -> void:
	booster_pressed.emit(booster_id)
