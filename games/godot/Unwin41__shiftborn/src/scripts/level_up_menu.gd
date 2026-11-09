class_name LevelUpMenu
extends CanvasLayer
## Level-up card picker. Shows the offered upgrades as cards; the player
## picks one with arrows/D-pad + accept, the 1-3 keys, or the mouse.
## Runs while the tree is paused. The caller owns pausing: pause before
## [method open], unpause after [signal closed].

## The player picked [param upgrade]. Apply it here.
signal chosen(upgrade: Upgrade)
## The menu is gone and the confirm press can no longer reach gameplay.
signal closed

const LAYER := 10
const CARD_SIZE := Vector2(150, 150)
const CARD_PADDING := 8
const CARD_SEPARATION := 12
const ICON_SIZE := Vector2(32, 32)
## The pixel font is crisp at multiples of 8.
const HEADER_FONT_SIZE := 16
const TITLE_FONT_SIZE := 8
const SMALL_FONT_SIZE := 8
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const CARD_COLOR := Color(0.12, 0.11, 0.16, 0.95)
const CARD_HOVER_COLOR := Color(0.2, 0.18, 0.26, 0.95)
## Evolution cards get a warm background next to the gold border.
const EVOLUTION_CARD_COLOR := Color(0.22, 0.16, 0.08, 0.95)
const BORDER_COLOR := Color(0.45, 0.42, 0.55)
const ACCENT_COLOR := Color(1.0, 0.82, 0.35)
const TEXT_COLOR := Color(0.85, 0.85, 0.9)
## Space and A are bound to both ui_accept and shift_form, and the player
## polls shift_form with is_action_just_pressed. Waiting a few physics
## frames before [signal closed] lets that press expire first.
const CLOSE_DELAY_PHYSICS_FRAMES := 2
## Cards ignore player input this long after opening, so a press meant
## for gameplay does not pick a card blindly.
const INPUT_GRACE := 0.25
const NUMBER_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3]

var _root: Control
var _row: HBoxContainer
var _upgrades: Array[Upgrade] = []
var _cards: Array[Button] = []
var _accepting_input := false
## Bumped on every open so a stale grace timer cannot unlock a newer menu.
var _open_serial := 0


## The line under a card's title: EVOLUTION, NEW or the level step.
static func badge_text(upgrade: Upgrade, current_level: int) -> String:
	if not upgrade.requires_maxed.is_empty():
		return "EVOLUTION"
	return level_text(current_level).to_upper()


static func level_text(current_level: int) -> String:
	if current_level <= 0:
		return "NEW"
	return "Lv %d > %d" % [current_level, current_level + 1]


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frame()
	_set_shown(false)


## Shows one card per upgrade. [param levels] holds each upgrade's
## current level, in the same order.
func open(upgrades: Array[Upgrade], levels: Array[int]) -> void:
	_clear_cards()
	_upgrades = upgrades.duplicate()
	for i in _upgrades.size():
		var level := levels[i] if i < levels.size() else 0
		var card := _make_card(_upgrades[i], level, i)
		_row.add_child(card)
		_cards.append(card)
	_set_shown(true)
	_open_serial += 1
	if not is_inside_tree():
		_accepting_input = true
		return
	_accepting_input = false
	if not _cards.is_empty():
		_cards[0].grab_focus()
	var serial := _open_serial
	get_tree().create_timer(INPUT_GRACE).timeout.connect(func() -> void:
		if serial == _open_serial:
			_accepting_input = true)


## Picks the card at [param index]. Ignored when hidden or out of range.
func choose(index: int) -> void:
	if not visible or index < 0 or index >= _upgrades.size():
		return
	_set_shown(false)
	_accepting_input = false
	chosen.emit(_upgrades[index])
	if is_inside_tree():
		for frame in CLOSE_DELAY_PHYSICS_FRAMES:
			await get_tree().physics_frame
	closed.emit()


## Hides the menu without emitting anything, e.g. when the run ends.
func cancel() -> void:
	_set_shown(false)
	_accepting_input = false


func card_count() -> int:
	return _cards.size()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not _accepting_input:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := NUMBER_KEYS.find(key.keycode)
	if index >= 0 and index < _cards.size():
		get_viewport().set_input_as_handled()
		choose(index)


## Focus moves by keyboard, gamepad or mouse; the first card's automatic
## focus on open happens during the input grace and stays silent.
func _on_card_focused() -> void:
	if _accepting_input:
		AudioManager.play(&"ui_move")


func _on_card_pressed(index: int) -> void:
	if _accepting_input:
		choose(index)


func _set_shown(shown: bool) -> void:
	visible = shown
	_root.visible = shown


func _clear_cards() -> void:
	for card in _cards:
		_row.remove_child(card)
		card.queue_free()
	_cards.clear()


func _build_frame() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", CARD_SEPARATION)
	center.add_child(column)
	column.add_child(_make_label("LEVEL UP", HEADER_FONT_SIZE, ACCENT_COLOR))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", CARD_SEPARATION)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_row)


func _make_card(upgrade: Upgrade, current_level: int, index: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	var evolution := not upgrade.requires_maxed.is_empty()
	card.add_theme_stylebox_override(&"normal", _card_style(EVOLUTION_CARD_COLOR if evolution else CARD_COLOR, ACCENT_COLOR if evolution else BORDER_COLOR))
	card.add_theme_stylebox_override(&"hover", _card_style(CARD_HOVER_COLOR, BORDER_COLOR))
	card.add_theme_stylebox_override(&"pressed", _card_style(CARD_HOVER_COLOR, ACCENT_COLOR))
	card.add_theme_stylebox_override(&"focus", _focus_style())
	card.pressed.connect(_on_card_pressed.bind(index))
	card.mouse_entered.connect(card.grab_focus)
	card.focus_entered.connect(_on_card_focused)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, CARD_PADDING)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(_make_icon(upgrade.icon))
	box.add_child(_make_label("%d. %s" % [index + 1, upgrade.title], TITLE_FONT_SIZE, Color.WHITE))
	box.add_child(_make_label(badge_text(upgrade, current_level), SMALL_FONT_SIZE, ACCENT_COLOR))
	var description := _make_label(upgrade.description, SMALL_FONT_SIZE, TEXT_COLOR)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	return card


func _make_icon(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	# The pixel font's capitals read far better than its lowercase.
	# String.to_upper() ignores the OS locale (Label.uppercase does not:
	# on a Turkish system it turns "i" into "İ").
	label.text = text.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = ACCENT_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
