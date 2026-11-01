extends Control
## Slate booster strip: full width, a hairline on top and vertical hairlines
## between five equal columns. No box, no shadow. The targeting hint lives
## in the HUD's context row, so set_hint() does nothing here.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal booster_pressed(booster_id: String)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconView: GDScript = preload("res://tools/directions/slate/ui/icon_view.gd")
const BoosterButton: GDScript = preload("res://tools/directions/slate/ui/booster_button.gd")

var _tokens: DirectionTokens = null
var _buttons: Array[BoosterButton] = []
## Hairline rects, worked out on layout so _draw() only fills them.
var _rules: Array[Rect2] = []


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
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


## Slate shows the targeting hint in the HUD context row instead.
func set_hint(_text: String) -> void:
	pass


func preferred_height() -> float:
	return _tokens.num("rule_width") + _tokens.num("strip_height")


## Local y where the always visible part starts. Slate keeps no hint row,
## so the whole strip, hairline included, is always visible.
func content_top() -> float:
	return 0.0


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _tokens == null:
		return
	var rule: float = _tokens.num("rule_width")
	_rules.clear()
	_rules.append(Rect2(0.0, 0.0, size.x, rule))
	var count: int = _buttons.size()
	if count == 0:
		queue_redraw()
		return
	var column: float = (size.x - rule * float(count - 1)) / float(count)
	for i: int in count:
		var x: float = roundf((column + rule) * float(i))
		var right: float = roundf((column + rule) * float(i) + column)
		_buttons[i].position = Vector2(x, rule)
		_buttons[i].size = Vector2(right - x, size.y - rule)
		if i < count - 1:
			_rules.append(Rect2(right, rule, rule, size.y - rule))
	queue_redraw()


func _draw() -> void:
	if _tokens == null:
		return
	var color: Color = _tokens.color("rule")
	for rect: Rect2 in _rules:
		draw_rect(rect, color)


func _on_button_pressed(booster_id: String) -> void:
	booster_pressed.emit(booster_id)
