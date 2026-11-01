extends Control
## Static review sheet for one direction's interface layer, 1080 by 2400.
## Every direction's ui_sheet.tscn uses this script with its direction_id,
## and it builds the sheet only through the shared interface (setup,
## set_look, show_boosters and so on), which also proves that the three
## directions answer to the same calls.
##
## Sections, top to bottom: the HUD, all ten icons in all three looks on the
## surface they sit on, the booster bar normal and targeting, the buttons and
## the sound toggle, the skin chips, one sample of each label variation, and
## a card.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")

## Icon size on the sheet, px, as the brief asks.
const ICON_SIDE: float = 96.0
## Share of a font size by which a label row's box may overlap the row above.
const LINE_OVERLAP: float = 0.2
const ICON_NAMES: PackedStringArray = ["hammer", "swap", "shuffle", "double", "undo", "settings", "sound_on", "sound_off", "close", "check"]

@export var direction_id: String = "gumdrop"

var _tokens: DirectionTokens = null
var _margin: float = 0.0
var _gap: float = 0.0
var _section: float = 0.0
var _width: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tokens = Directions.load_tokens(direction_id)
	if _tokens == null:
		return
	theme = _ui("theme_factory").call("build", _tokens) as Theme
	_margin = _tokens.num("board_margin")
	_gap = _tokens.num("space_s")
	# Sections sit close together: the sheet has a lot to show in 2400 px.
	_section = _tokens.num("space_xs")
	_width = float(MockState.CANVAS_SIZE.x) - _margin * 2.0

	var backdrop: Control = _make("backdrop")
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(MockState.CANVAS_SIZE)

	var y: float = float(MockState.SAFE_TOP)
	y = _hud(y) + _section
	y = _icons(y) + _section
	# The normal bar shows no hint, so its empty hint row may sit under the
	# icon rows; the sheet has no room to spare.
	y = _bar(y - _hint_reserve(), "") + _section
	y = _bar(y, MockState.TARGETING_BOOSTER) + _section
	y = _buttons(y) + _section
	y = _chips(y) + _gap
	y = _labels_and_card(y)
	var limit: float = float(MockState.CANVAS_SIZE.y - MockState.SAFE_BOTTOM)
	if y > limit:
		print("ui_sheet %s: content ends at %d, below the safe area at %d" % [direction_id, roundi(y), roundi(limit)])


## The direction's ui script with this file name.
func _ui(file_name: String) -> GDScript:
	return load("%s/%s/ui/%s.gd" % [Directions.ROOT, direction_id, file_name]) as GDScript


## A new control from the direction's ui script, set up and added.
func _make(file_name: String) -> Control:
	var control: Control = _ui(file_name).new() as Control
	add_child(control)
	control.call("setup", _tokens)
	return control


func _hud(y: float) -> float:
	var hud: Control = _make("hud")
	hud.call("set_scores", MockState.SCORE, MockState.BEST_SCORE)
	hud.call("set_context", "%s %d" % [MockState.CHAIN_LABEL, MockState.chain_cells().size()], false)
	var height: float = float(hud.call("preferred_height"))
	hud.position = Vector2(0.0, y)
	hud.size = Vector2(float(MockState.CANVAS_SIZE.x), height)
	return y + height


func _icons(y: float) -> float:
	var script: GDScript = _ui("icon_button")
	var columns: int = ICON_NAMES.size()
	var step: float = (_width - ICON_SIDE) / float(columns - 1)
	# Room for Gumdrop's lip under the face; its raised active look reaches
	# a little into the row above, which is fine on a review sheet.
	var row_height: float = ICON_SIDE + _tokens.num("space_xs")
	for look: int in 3:
		for i: int in columns:
			var button: Control = script.new() as Control
			add_child(button)
			button.call("setup", _tokens, ICON_NAMES[i], ICON_SIDE, ICON_SIDE)
			button.call("set_look", look)
			# A review cell, not a touch target, so it may be smaller than touch_min.
			button.custom_minimum_size = Vector2.ZERO
			button.position = Vector2(_margin + step * float(i), y + row_height * float(look))
			button.size = Vector2(ICON_SIDE, row_height)
	return y + row_height * 3.0


func _bar(y: float, active_id: String) -> float:
	var bar: Control = _make("booster_bar")
	bar.call("show_boosters", MockState.BOOSTER_IDS, MockState.BOOSTER_COSTS, MockState.board_usable(), active_id)
	bar.call("set_hint", MockState.TARGET_HINT if not active_id.is_empty() else "")
	var height: float = float(bar.call("preferred_height"))
	bar.position = Vector2(0.0, y)
	bar.size = Vector2(float(MockState.CANVAS_SIZE.x), height)
	return y + height


## Height of the empty hint row each direction's bar keeps above its
## boosters. Sheet layout only; it mirrors the bar scripts.
func _hint_reserve() -> float:
	match direction_id:
		"gumdrop":
			return _tokens.num("pill_height") + _tokens.num("space_s")
		"nova":
			return _tokens.font("label").get_height(_tokens.font_size("label")) + _tokens.num("space_xs")
	return 0.0


func _buttons(y: float) -> float:
	var column: float = (_width - _gap) * 0.5
	var shuffle_text: String = MockState.buy_text(MockState.RESCUE_BOOSTER, MockState.booster_cost(MockState.RESCUE_BOOSTER))
	var cells: Array[Control] = [
		_button("PrimaryButton", shuffle_text, false, false),
		_button("PrimaryButton", shuffle_text, true, false),
		_button("PrimaryButton", shuffle_text, false, true),
		_button("SecondaryButton", MockState.GAMEOVER_END, false, false),
		_button("SecondaryButton", MockState.GAMEOVER_END, true, false),
		_sound_row(column),
	]
	var row_y: float = y
	for row: int in 3:
		var row_height: float = 0.0
		for side: int in 2:
			row_height = maxf(row_height, cells[row * 2 + side].get_combined_minimum_size().y)
		for side: int in 2:
			var cell: Control = cells[row * 2 + side]
			cell.position = Vector2(_margin + (column + _gap) * float(side), row_y)
			cell.size = Vector2(column, row_height)
		row_y += row_height + _tokens.num("space_xs")
	return row_y - _tokens.num("space_xs")


func _button(variation: String, text: String, pressed: bool, disabled: bool) -> Button:
	var button: Button = Button.new()
	button.theme_type_variation = variation
	button.text = _tokens.cased("body", text)
	button.focus_mode = Control.FOCUS_NONE
	if direction_id == "slate":
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if pressed:
		# Held down for the review: toggle mode shows the pressed style.
		button.toggle_mode = true
		button.button_pressed = true
	button.disabled = disabled
	add_child(button)
	return button


## "Sound" with the toggle on and off, in one cell.
func _sound_row(width: float) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(_tokens.num("space_xs")))
	add_child(row)
	var label: Label = Label.new()
	label.theme_type_variation = "BodyLabel"
	label.text = _tokens.cased("body", MockState.SOUND_LABEL)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	for on: bool in [true, false]:
		var toggle: Control = _ui("toggle_switch").new() as Control
		row.add_child(toggle)
		toggle.call("setup", _tokens)
		toggle.call("set_on", on, false)
	row.custom_minimum_size.x = width
	return row


func _chips(y: float) -> float:
	var count: int = MockState.SKIN_NAMES.size()
	var gap: float = _tokens.num("space_xs")
	var width: float = (_width - gap * float(count - 1)) / float(count)
	var height: float = 0.0
	var chips: Array[Button] = []
	for i: int in count:
		var chip: Button = Button.new()
		chip.theme_type_variation = "ChipButton"
		chip.text = _tokens.cased("body", MockState.SKIN_NAMES[i])
		chip.toggle_mode = true
		chip.button_pressed = MockState.SKIN_IDS[i] == direction_id
		chip.focus_mode = Control.FOCUS_NONE
		add_child(chip)
		chips.append(chip)
		height = maxf(height, chip.get_combined_minimum_size().y)
	for i: int in count:
		chips[i].position = Vector2(_margin + (width + gap) * float(i), y)
		chips[i].size = Vector2(width, height)
	return y + height


## One sample of each label variation stacked on the left, and a card with
## a title, a divider and body text on the right.
func _labels_and_card(y: float) -> float:
	# Rows of samples. Line boxes overlap a little, by the empty space above
	# each line's capitals, so the stack stays compact without glyphs touching.
	var rows: Array[Array] = [
		[_label("DisplayLabel", MockState.format_number(MockState.SCORE), "display")],
		[_label("TitleLabel", MockState.SETTINGS_TITLE, "title")],
		[_label("BodyLabel", MockState.SOUND_LABEL, "body"), _label("CaptionLabel", MockState.BEST_TILE_LABEL, "label")],
		[_label("MutedLabel", MockState.VERSION_TEXT, "body")],
	]
	var column_width: float = 0.0
	var label_y: float = y
	for row: Array in rows:
		var x: float = _margin
		var row_bottom: float = label_y
		var first: Label = row[0] as Label
		var lift: float = 0.0 if label_y == y else float(first.get_theme_font_size("font_size")) * LINE_OVERLAP
		var baseline: float = label_y - lift + first.get_theme_font("font").get_ascent(first.get_theme_font_size("font_size"))
		for item: Variant in row:
			var label: Label = item as Label
			var label_size: Vector2 = label.get_combined_minimum_size()
			var ascent: float = label.get_theme_font("font").get_ascent(label.get_theme_font_size("font_size"))
			label.position = Vector2(x, baseline - ascent)
			label.size = label_size
			x += label_size.x + _gap
			row_bottom = maxf(row_bottom, label.position.y + label_size.y)
		column_width = maxf(column_width, x - _gap - _margin)
		label_y = row_bottom

	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	add_child(card)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", roundi(_tokens.num("space_xs")))
	card.add_child(stack)
	var title: Label = Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = _tokens.cased("title", MockState.GAMEOVER_TITLE)
	stack.add_child(title)
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = "Hairline"
	stack.add_child(rule)
	var body: Label = Label.new()
	body.theme_type_variation = "BodyLabel"
	body.text = _tokens.cased("body", MockState.GAMEOVER_BODY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	var panel: StyleBox = card.get_theme_stylebox("panel")
	var card_min: float = title.get_combined_minimum_size().x + panel.get_margin(SIDE_LEFT) + panel.get_margin(SIDE_RIGHT)
	var card_x: float = minf(_margin + column_width + _gap, _margin + _width - card_min)
	var card_width: float = _margin + _width - card_x
	var text_width: float = card_width - panel.get_margin(SIDE_LEFT) - panel.get_margin(SIDE_RIGHT)
	body.custom_minimum_size.x = text_width
	card.position = Vector2(card_x, y)
	card.size = Vector2(card_width, 0.0)
	_fit_after_layout(card)
	# The wrapped body only knows its height after a layout pass, so the
	# card height here is worked out from the text for the overflow check.
	var body_font: Font = body.get_theme_font("font")
	var body_size: int = body.get_theme_font_size("font_size")
	var body_height: float = body_font.get_multiline_string_size(body.text, HORIZONTAL_ALIGNMENT_LEFT, text_width, body_size).y
	var card_height: float = panel.get_margin(SIDE_TOP) + panel.get_margin(SIDE_BOTTOM) + title.get_combined_minimum_size().y 		+ rule.get_combined_minimum_size().y + body_height + _tokens.num("space_xs") * 2.0
	return maxf(label_y, y + card_height)


## Shrinks a control to its minimum height once containers have laid it out.
func _fit_after_layout(control: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	control.size = Vector2(control.size.x, control.get_combined_minimum_size().y)


func _label(variation: String, text: String, role: String) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.text = _tokens.cased(role, text)
	add_child(label)
	return label
