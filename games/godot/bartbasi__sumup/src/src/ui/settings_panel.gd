class_name SettingsPanel extends "res://src/ui/dialog_base.gd"
## Settings (DESIGN_SYSTEM.md 7.7), reached from the splash and Pause:
## - "Settings" with a close icon button;
## - the Sound row with the skin's toggle;
## - a divider, "Skin", then the three skin choices side by side;
## - a divider, then the About row, which opens About (a row that opens a
##   screen: row_height tall, never less than touch_min, "About" in the body
##   role and the chevron on the right; the whole row is the target);
## - the version line.
## Each skin choice is a swatch in that skin's own bg (radius_chip of the
## current skin) holding tiles 2, 4 and 8 drawn by that skin's own tile
## component, and under it a chip with the skin's name in that skin's font.
## A swatch the same color as the panel gets a hairline edge. The current
## skin's chip shows the selected look.
##
## The toggle calls settings.set_sound_on and a choice calls
## settings.set_skin_id. The App listens, switches the game live and saves.

signal closed()
signal about_chosen()

const OpenRow: GDScript = preload("res://src/ui/open_row.gd")
## DESIGN_SYSTEM.md 7.9 fixed component constants.
const PREVIEW_TILE: float = 72.0
const SWATCH_PADDING: float = 0.22    # share of the preview tile side
const SWATCH_EDGE: float = 2.0
const PREVIEW_VALUES: Array[int] = [1, 2, 3]    # the tiles 2, 4 and 8, as exponents
const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")

var _settings: Settings = null
var _toggle: SkinToggle = null
var _chips: Dictionary[StringName, Button] = {}
var _about_row: Control = null


func setup(skin: SkinData, settings: Settings) -> void:
	_settings = settings
	_frame(skin)
	_chips = {}

	var header: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	_content.add_child(header)
	var title: Label = UiParts.label(skin, &"TitleLabel", Copy.SETTINGS)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button: BaseButton = UiParts.icon_button(skin, &"close")
	close_button.name = "Close"
	close_button.pressed.connect(_on_close)
	header.add_child(close_button)

	var sound_row: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	sound_row.custom_minimum_size = Vector2(0.0, skin.num(&"row_height"))
	_content.add_child(sound_row)
	var sound_label: Label = UiParts.label(skin, &"BodyLabel", Copy.SOUND)
	sound_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_row.add_child(sound_label)
	_toggle = UiKit.make_toggle(skin)
	_toggle.name = "Sound"
	_toggle.set_on(settings.sound_on)
	_toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toggle.toggled.connect(_on_sound_toggled)
	sound_row.add_child(_toggle)

	_content.add_child(UiParts.divider())
	_content.add_child(UiParts.label(skin, &"CaptionLabel", Copy.SKIN))
	var choices: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	_content.add_child(choices)
	var panel_bg: Color = UiParts.panel_fill(self, skin)
	for skin_id: StringName in SkinCatalog.IDS:
		choices.add_child(_choice(skin, SkinCatalog.get_skin(skin_id), panel_bg))

	_content.add_child(UiParts.divider())
	_about_row = OpenRow.new()
	_about_row.name = "About"
	_about_row.call(&"setup", skin, Copy.ABOUT, "")
	_about_row.connect(&"tapped", _on_about)
	_content.add_child(_about_row)

	_content.add_child(UiParts.label(skin, &"CaptionLabel", Copy.version_line(), UiParts.block_alignment(skin)))


## Rebuilds the panel in a new skin, still open.
func apply_skin(skin: SkinData) -> void:
	setup(skin, _settings)


## The sound toggle. For tests.
func sound_toggle() -> SkinToggle:
	return _toggle


## The chip of each skin, by id. For tests.
func skin_chips() -> Dictionary[StringName, Button]:
	return _chips


## The About row. For tests.
func about_row() -> Control:
	return _about_row


func _choice(skin: SkinData, choice_skin: SkinData, panel_bg: Color) -> VBoxContainer:
	var column: VBoxContainer = UiParts.vbox(skin.num(&"space_xs"))
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var swatch: PanelContainer = PanelContainer.new()
	swatch.name = "Swatch_%s" % choice_skin.id
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = choice_skin.color(&"bg")
	style.set_corner_radius_all(roundi(skin.num(&"radius_chip")))
	style.corner_detail = ThemeKit.CORNER_DETAIL
	style.anti_aliasing = true
	if choice_skin.color(&"bg") == panel_bg:
		style.border_color = skin.color(&"line")
		style.set_border_width_all(roundi(SWATCH_EDGE))
	var pad: float = PREVIEW_TILE * SWATCH_PADDING
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	swatch.add_theme_stylebox_override(&"panel", style)
	swatch.mouse_filter = Control.MOUSE_FILTER_STOP
	swatch.gui_input.connect(_on_swatch_input.bind(choice_skin.id))
	column.add_child(swatch)
	var tiles: HBoxContainer = UiParts.hbox(skin.num(&"space_xs"))
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	swatch.add_child(tiles)
	for value: int in PREVIEW_VALUES:
		tiles.add_child(UiParts.tile(choice_skin, value, PREVIEW_TILE))

	var chip: Button = UiParts.button(skin, &"ChipButton", choice_skin.display_name)
	chip.name = "Chip_%s" % choice_skin.id
	chip.toggle_mode = true
	chip.button_pressed = _settings != null and _settings.skin_id == choice_skin.id
	chip.add_theme_font_override(&"font", choice_skin.font(&"body"))
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.pressed.connect(_choose.bind(choice_skin.id))
	column.add_child(chip)
	_chips[choice_skin.id] = chip
	return column


func _on_swatch_input(event: InputEvent, skin_id: StringName) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		_choose(skin_id)


## A tap on a choice. Choosing the current skin again keeps it selected.
func _choose(skin_id: StringName) -> void:
	if _closing or _settings == null:
		return
	if _chips.has(skin_id):
		_chips[skin_id].set_pressed_no_signal(true)
	_settings.set_skin_id(skin_id)


func _on_sound_toggled(on: bool) -> void:
	if not _closing and _settings != null:
		_settings.set_sound_on(on)


func _on_close() -> void:
	if not _closing:
		closed.emit()


func _on_about() -> void:
	if not _closing:
		about_chosen.emit()
