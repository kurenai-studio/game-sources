extends Control
## Nova HUD, centered: the score in a thin, very large numeral with the
## best score ("best 96,520") small and lowercase under it, and the settings
## icon in a small ring at the top right. No containers. Placed full width
## with its top edge at SAFE_TOP. A screen counts the score up with
## Motion.count_up() on score_label().
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal settings_pressed

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const ThemeFactory: GDScript = preload("res://tools/directions/nova/ui/theme_factory.gd")
const IconButton: GDScript = preload("res://tools/directions/nova/ui/icon_button.gd")

## Cap height of the system font as a share of the font size, used to place
## the score's digits. A font metric, not a token.
const CAP_HEIGHT: float = 0.71

var _tokens: DirectionTokens = null
var _settings: IconButton = null
var _score: Label = null
var _best: Label = null


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	theme = ThemeFactory.build(tokens)
	if _settings == null:
		_build()
	_settings.setup(tokens, "settings", tokens.num("hud_ring"), tokens.num("hud_icon"))
	_layout()


func set_scores(score: int, best: int) -> void:
	_score.text = MockState.format_number(score)
	_best.text = _tokens.cased("label", "%s %s" % [MockState.BEST_LABEL, MockState.format_number(best)])
	_layout()


## Nova has no context row.
func set_context(_text: String, _highlight: bool) -> void:
	pass


## Nova shows the chain preview on the board, not in the HUD.
func preview_slot() -> Control:
	return null


## The score label, so a screen can count it up with Motion.count_up().
func score_label() -> Label:
	return _score


func preferred_height() -> float:
	return _best_top() + _tokens.font("label").get_height(_tokens.font_size("label"))


func _build() -> void:
	_settings = IconButton.new()
	_settings.pressed.connect(func() -> void: settings_pressed.emit())
	add_child(_settings)
	# Text pairs: ink on bg_glow for the score, ink_muted on bg_glow for best.
	_score = Label.new()
	_score.name = "ScoreLabel"
	_score.theme_type_variation = "DisplayLabel"
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_score)
	_best = Label.new()
	_best.theme_type_variation = "CaptionLabel"
	_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_best)


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


## Top of the score label box, so its digits start space_m below the HUD top.
func _score_top() -> float:
	var display: Font = _tokens.font("display")
	var display_size: int = _tokens.font_size("display")
	return _tokens.num("space_m") - (display.get_ascent(display_size) - CAP_HEIGHT * float(display_size))


## Top of the best label box: space_xs below the bottom of the score's line,
## which holds the comma's tail, measured to the top of the best line's
## tallest letters.
func _best_top() -> float:
	var display: Font = _tokens.font("display")
	var score_bottom: float = _score_top() + display.get_height(_tokens.font_size("display"))
	var caption: Font = _tokens.font("label")
	var caption_size: int = _tokens.font_size("label")
	var empty_above_letters: float = caption.get_ascent(caption_size) - CAP_HEIGHT * float(caption_size)
	return score_bottom + _tokens.num("space_xs") - empty_above_letters


func _layout() -> void:
	if _tokens == null or _settings == null:
		return
	var margin: float = _tokens.num("board_margin")
	var touch: float = _tokens.num("touch_min")
	# The ring's edge lines up with the right margin; its touch area reaches past it.
	_settings.size = Vector2(touch, touch)
	_settings.position = Vector2(size.x - margin - (touch + _tokens.num("hud_ring")) * 0.5, 0.0)
	_score.position = Vector2(0.0, _score_top())
	_score.size = Vector2(size.x, _score.get_combined_minimum_size().y)
	_best.position = Vector2(0.0, _best_top())
	_best.size = Vector2(size.x, _tokens.font("label").get_height(_tokens.font_size("label")))
