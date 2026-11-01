extends Control
## Gumdrop HUD: a raised settings squircle on the left of the top row, a
## "Best" pill on the right, and below them, centered, the "Score" caption
## over the big score. Placed full width with its top edge at SAFE_TOP.
## A screen counts the score up with Motion.count_up() on score_label().
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal settings_pressed

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const ThemeFactory: GDScript = preload("res://tools/directions/gumdrop/ui/theme_factory.gd")
const IconButton: GDScript = preload("res://tools/directions/gumdrop/ui/icon_button.gd")

## Cap height of the system font as a share of the font size, used to sit
## the score's digits right under the caption. A font metric, not a token.
const CAP_HEIGHT: float = 0.71

var _tokens: DirectionTokens = null
var _settings: IconButton = null
var _pill: PanelContainer = null
var _best_number: Label = null
var _caption: Label = null
var _score: Label = null


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	theme = ThemeFactory.build(tokens)
	if _settings == null:
		_build()
	var face: float = tokens.num("touch_min") - tokens.num("button_lip")
	_settings.setup(tokens, "settings", face, tokens.num("hud_icon"))
	_caption.text = tokens.cased("label", MockState.SCORE_LABEL)
	_layout()


func set_scores(score: int, best: int) -> void:
	_score.text = MockState.format_number(score)
	_best_number.text = MockState.format_number(best)
	_layout()


## Gumdrop has no context row.
func set_context(_text: String, _highlight: bool) -> void:
	pass


## Gumdrop shows the chain preview on the board, not in the HUD.
func preview_slot() -> Control:
	return null


## The score label, so a screen can count it up with Motion.count_up().
func score_label() -> Label:
	return _score


func preferred_height() -> float:
	return _score_top() + _tokens.font("display").get_ascent(_tokens.font_size("display")) + _tokens.num("space_xs")


func _build() -> void:
	_settings = IconButton.new()
	_settings.pressed.connect(func() -> void: settings_pressed.emit())
	add_child(_settings)

	# Best pill. Text pairs: ink_soft on surface, ink on surface.
	_pill = PanelContainer.new()
	_pill.theme_type_variation = "PillPanel"
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(_tokens.num("space_xs")))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_pill.add_child(row)
	var best_label: Label = Label.new()
	best_label.theme_type_variation = "CaptionLabel"
	best_label.text = _tokens.cased("label", MockState.BEST_LABEL)
	best_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(best_label)
	_best_number = Label.new()
	_best_number.theme_type_variation = "BodyLabel"
	_best_number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_best_number)
	add_child(_pill)

	# Score. Text pairs: ink_soft on bg, ink on bg.
	_caption = Label.new()
	_caption.theme_type_variation = "CaptionLabel"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_caption)
	_score = Label.new()
	_score.name = "ScoreLabel"
	_score.theme_type_variation = "DisplayLabel"
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_score)


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


## Top of the score label box, placed so its digits start space_xs under
## the caption.
func _score_top() -> float:
	var row: float = _tokens.num("touch_min")
	var caption_bottom: float = row + _tokens.num("space_xs") + _tokens.font("label").get_height(_tokens.font_size("label"))
	var display: Font = _tokens.font("display")
	var display_size: int = _tokens.font_size("display")
	var empty_above_digits: float = display.get_ascent(display_size) - CAP_HEIGHT * float(display_size)
	return caption_bottom + _tokens.num("space_xs") - empty_above_digits


func _layout() -> void:
	if _tokens == null or _settings == null:
		return
	var margin: float = _tokens.num("board_margin")
	var row: float = _tokens.num("touch_min")
	_settings.position = Vector2(margin, 0.0)
	_settings.size = Vector2(row, row)
	var pill_size: Vector2 = _pill.get_combined_minimum_size()
	pill_size.y = _tokens.num("pill_height")
	_pill.size = pill_size
	# Line the pill's face up with the settings face.
	var settings_face_center: float = (row - _tokens.num("button_lip")) * 0.5
	var pill_face: float = pill_size.y - _tokens.num("button_lip")
	_pill.position = Vector2(size.x - margin - pill_size.x, settings_face_center - pill_face * 0.5)
	var caption_height: float = _tokens.font("label").get_height(_tokens.font_size("label"))
	_caption.position = Vector2(0.0, row + _tokens.num("space_xs"))
	_caption.size = Vector2(size.x, caption_height)
	_score.position = Vector2(0.0, _score_top())
	_score.size = Vector2(size.x, _score.get_combined_minimum_size().y)
