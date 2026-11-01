extends Control
## Slate HUD, left aligned: "SCORE" in small capitals over the very large
## score; the settings icon and "BEST" with its number on the right, right
## aligned. A hairline under the header, then the context row: plain caps
## text, or a full width vermilion bar while a booster is targeting, with a
## slot for the preview tile at its right. Placed full width with its top
## edge at SAFE_TOP. A screen counts the score up with
## Motion.count_up() on score_label().
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal settings_pressed

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const ThemeFactory: GDScript = preload("res://tools/directions/slate/ui/theme_factory.gd")
const IconButton: GDScript = preload("res://tools/directions/slate/ui/icon_button.gd")

## Cap height of the system font as a share of the font size, used to sit
## the score's digits right under the caption. A font metric, not a token.
const CAP_HEIGHT: float = 0.71

var _tokens: DirectionTokens = null
var _settings: IconButton = null
var _caption: Label = null
var _score: Label = null
var _best_caption: Label = null
var _best_number: Label = null
var _slot: Control = null
var _context: String = ""
var _highlight: bool = false
var _font: Font = null
var _font_size: int = 16
var _rule_rect: Rect2 = Rect2()
var _row_rect: Rect2 = Rect2()
var _context_origin: Vector2 = Vector2.ZERO


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	theme = ThemeFactory.build(tokens)
	_font = tokens.font("label")
	_font_size = tokens.font_size("label")
	if _settings == null:
		_build()
	_settings.setup(tokens, "settings", tokens.num("touch_min"), tokens.num("hud_icon"))
	_caption.text = tokens.cased("label", MockState.SCORE_LABEL)
	_best_caption.text = tokens.cased("label", MockState.BEST_LABEL)
	_slot.custom_minimum_size = Vector2(tokens.num("preview_tile"), tokens.num("preview_tile"))
	_layout()


func set_scores(score: int, best: int) -> void:
	_score.text = MockState.format_number(score)
	_best_number.text = MockState.format_number(best)
	_layout()


## Plain caps text such as "CHAIN 6", or the vermilion hint bar when
## highlight is true. "" hides it.
func set_context(text: String, highlight: bool) -> void:
	_context = _tokens.cased("label", text) if _tokens != null else text
	_highlight = highlight
	queue_redraw()


## An empty square at the right of the context row for the preview tile.
func preview_slot() -> Control:
	return _slot


## The score label, so a screen can count it up with Motion.count_up().
func score_label() -> Label:
	return _score


func preferred_height() -> float:
	return _row_top() + _row_height()


func _build() -> void:
	_settings = IconButton.new()
	_settings.pressed.connect(func() -> void: settings_pressed.emit())
	add_child(_settings)
	# Text pairs: ink_muted on bg for the captions, ink on bg for the numbers.
	_caption = _label("CaptionLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_score = _label("DisplayLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_score.name = "ScoreLabel"
	_best_caption = _label("CaptionLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_best_number = _label("BodyLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_slot = Control.new()
	_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slot)


func _label(variation: String, align: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = align
	add_child(label)
	return label


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _caption_height() -> float:
	return _font.get_height(_font_size)


## Top of the score label box, placed so its digits start space_xs under
## the caption.
func _score_top() -> float:
	var display: Font = _tokens.font("display")
	var display_size: int = _tokens.font_size("display")
	var empty_above_digits: float = display.get_ascent(display_size) - CAP_HEIGHT * float(display_size)
	return _caption_height() + _tokens.num("space_xs") - empty_above_digits


func _score_baseline() -> float:
	return _score_top() + _tokens.font("display").get_ascent(_tokens.font_size("display"))


func _row_top() -> float:
	return roundf(_score_baseline() + _tokens.num("space_m")) + _tokens.num("rule_width")


func _row_height() -> float:
	return _tokens.num("preview_tile") + _tokens.num("space_xs") * 2.0


func _layout() -> void:
	if _tokens == null or _settings == null:
		return
	var margin: float = _tokens.num("board_margin")
	var touch: float = _tokens.num("touch_min")
	# The icon's box lines up with the right margin; its touch area reaches past it.
	_settings.size = Vector2(touch, touch)
	_settings.position = Vector2(size.x - margin - (touch + _tokens.num("hud_icon")) * 0.5, 0.0)
	_caption.position = Vector2(margin, 0.0)
	_caption.size = Vector2(size.x * 0.5, _caption_height())
	_score.position = Vector2(margin, _score_top())
	_score.size = _score.get_combined_minimum_size()
	var baseline: float = _score_baseline()
	var body: Font = _tokens.font("body")
	var body_size: int = _tokens.font_size("body")
	var best_width: float = size.x * 0.4
	_best_number.size = Vector2(best_width, body.get_height(body_size))
	_best_number.position = Vector2(size.x - margin - best_width, baseline - body.get_ascent(body_size))
	_best_caption.size = Vector2(best_width, _caption_height())
	_best_caption.position = Vector2(size.x - margin - best_width, _best_number.position.y - _caption_height())
	var rule: float = _tokens.num("rule_width")
	var row_top: float = _row_top()
	_rule_rect = Rect2(margin, row_top - rule, size.x - margin * 2.0, rule)
	_row_rect = Rect2(0.0, row_top, size.x, _row_height())
	var slot_side: float = _tokens.num("preview_tile")
	_slot.size = Vector2(slot_side, slot_side)
	_slot.position = Vector2(size.x - margin - slot_side, row_top + _tokens.num("space_xs"))
	var line: float = _font.get_height(_font_size)
	_context_origin = Vector2(margin, row_top + (_row_rect.size.y - line) * 0.5 + _font.get_ascent(_font_size))
	queue_redraw()


func _draw() -> void:
	if _tokens == null:
		return
	draw_rect(_rule_rect, _tokens.color("rule"))
	if _context.is_empty():
		return
	if _highlight:
		# Text pair: ink_dark on accent.
		draw_rect(_row_rect, _tokens.color("accent"))
		draw_string(_font, _context_origin, _context, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _tokens.color("ink_dark"))
	else:
		# Text pair: ink on bg.
		draw_string(_font, _context_origin, _context, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _tokens.color("ink"))
