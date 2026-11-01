extends RefCounted
## Builders for the mockups of the 2026-10-13 additions (tools/ only). They
## follow DESIGN_SYSTEM.md 7.2, 7.3, 7.7 and 7.11 to 7.14 and use the real
## Theme, tile views and board views; only the new pieces are drawn here.

const Spec: GDScript = preload("res://tools/additions/additions_spec.gd")
const AddedIcon: GDScript = preload("res://tools/additions/additions_icon.gd")
const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")
const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")
const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")


## Adds the new variations to a skin's Theme: HeadingLabel, ReadingLabel,
## SectionPanel, RowButton, and the reading screens' scroll indicator.
static func extend_theme(theme: Theme, skin: SkinData) -> void:
	for pair: Array in [[&"HeadingLabel", &"Label"], [&"ReadingLabel", &"Label"], [&"SectionPanel", &"PanelContainer"], [&"RowButton", &"Button"], [&"RowDetailLabel", &"Label"]]:
		theme.add_type(pair[0])
		theme.set_type_variation(pair[0], pair[1])
	theme.set_font(&"font", &"HeadingLabel", Spec.font(skin, &"heading"))
	theme.set_font_size(&"font_size", &"HeadingLabel", Spec.font_size(skin, &"heading"))
	theme.set_color(&"font_color", &"HeadingLabel", skin.color(&"ink"))
	theme.set_font(&"font", &"ReadingLabel", Spec.font(skin, &"reading"))
	theme.set_font_size(&"font_size", &"ReadingLabel", Spec.font_size(skin, &"reading"))
	theme.set_color(&"font_color", &"ReadingLabel", skin.color(&"ink_muted"))
	theme.set_constant(&"line_spacing", &"ReadingLabel", roundi(Spec.num(skin, &"reading_line_spacing")))

	# Sections: Gumdrop's lipped card; Slate and Nova have no box.
	var section: StyleBox = StyleBoxEmpty.new()
	if skin.id == &"gumdrop":
		var lip: float = skin.num(&"button_lip")
		var pad: float = skin.num(&"space_m")
		var card: StyleBoxFlat = Candy.raised(skin.color(&"surface"), skin.color(&"surface_lip"), skin.num(&"radius_card"), lip)
		ThemeKit.pad(card, pad, pad, pad, pad + lip)
		section = card
	elif skin.id == &"slate":
		ThemeKit.pad(section, 0.0, skin.num(&"space_m"), 0.0, skin.num(&"space_m"))
	theme.set_stylebox(&"panel", &"SectionPanel", section)

	# Rows that open a screen: flat, text left; pressed fills behind the text.
	var flat: StyleBoxEmpty = StyleBoxEmpty.new()
	var pressed_fill: Color = skin.color(&"surface_raised")
	if skin.id == &"slate":
		pressed_fill = skin.color(&"surface")
	var pressed: StyleBoxFlat = ThemeKit.box(pressed_fill, skin.num(&"radius_chip") if skin.id != &"slate" else 0.0)
	var reach: float = skin.num(&"space_s")
	pressed.expand_margin_left = reach
	pressed.expand_margin_right = reach
	for style: StyleBox in [flat, pressed]:
		ThemeKit.pad(style, 0.0, 0.0, 0.0, 0.0)
	ThemeKit.button_type(theme, &"RowButton", ThemeKit.styles(flat, pressed, flat, flat), skin, skin.color(&"ink"), skin.color(&"ink"), skin.color(&"disabled_ink"))
	ThemeKit.label_type(theme, &"RowDetailLabel", skin, &"label", skin.color(&"ink_muted"))

	# The scroll indicator fills the right board_margin and draws scroll_bar
	# wide in its middle.
	var margin: float = skin.num(&"board_margin")
	var bar: float = Spec.num(skin, &"scroll_bar")
	var track: StyleBoxEmpty = StyleBoxEmpty.new()
	ThemeKit.pad(track, margin * 0.5, 0.0, margin * 0.5, 0.0)
	theme.set_stylebox(&"scroll", &"VScrollBar", track)
	theme.set_stylebox(&"scroll_focus", &"VScrollBar", track)
	for item: Array in [[&"grabber", skin.color(&"line")], [&"grabber_highlight", skin.color(&"line")], [&"grabber_pressed", skin.color(&"ink_muted")]]:
		var grab: StyleBoxFlat = ThemeKit.box(item[1], bar * 0.5 if skin.id != &"slate" else 0.0)
		grab.expand_margin_left = -(margin - bar) * 0.5
		grab.expand_margin_right = -(margin - bar) * 0.5
		ThemeKit.pad(grab, 0.0, Spec.SCROLL_BAR_MIN * 0.5, 0.0, Spec.SCROLL_BAR_MIN * 0.5)
		theme.set_stylebox(item[0], &"VScrollBar", grab)
	theme.set_stylebox(&"panel", &"ScrollContainer", StyleBoxEmpty.new())
	theme.set_constant(&"scrollbar_v_separation", &"ScrollContainer", 0)


static func heading(skin: SkinData, text: String) -> Label:
	var made: Label = Label.new()
	made.theme_type_variation = &"HeadingLabel"
	made.text = Spec.cased(skin, &"heading", text)
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	made.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return made


static func reading(text: String) -> Label:
	var made: Label = Label.new()
	made.theme_type_variation = &"ReadingLabel"
	made.text = text
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	made.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return made


## A section: the skin's SectionPanel holding a column, space_xs apart.
static func section(skin: SkinData) -> Array:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"SectionPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column: VBoxContainer = UiParts.vbox(skin.num(&"space_xs"))
	panel.add_child(column)
	return [panel, column]


static func spacer(height: float) -> Control:
	var gap: Control = Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.custom_minimum_size = Vector2(0.0, height)
	return gap


## The wordmark "SumUp": "Sum" in ink, "Up" in accent, in the display role's
## font at font_px.
static func wordmark(skin: SkinData, font_px: int, align_start: bool) -> HBoxContainer:
	var row: HBoxContainer = UiParts.hbox(0.0)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN if align_start else BoxContainer.ALIGNMENT_CENTER
	for part: Array in [["Sum", skin.color(&"ink")], ["Up", skin.color(&"accent")]]:
		var label: Label = Label.new()
		label.theme_type_variation = &"DisplayLabel"
		label.text = part[0]
		label.add_theme_font_size_override(&"font_size", font_px)
		label.add_theme_color_override(&"font_color", part[1])
		row.add_child(label)
	return row


## The menu wordmark size: its advance width equals width.
static func fitted_wordmark_size(skin: SkinData, width: float) -> int:
	var display: Font = skin.font(&"display")
	var base: int = skin.font_size(&"display")
	var at_base: float = display.get_string_size("Sum", HORIZONTAL_ALIGNMENT_LEFT, -1.0, base).x + display.get_string_size("Up", HORIZONTAL_ALIGNMENT_LEFT, -1.0, base).x
	var size: int = floori(float(base) * width / at_base)
	while size > base and _wordmark_width(display, size) > width:
		size -= 1
	return size


static func _wordmark_width(display: Font, size: int) -> float:
	return display.get_string_size("Sum", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x + display.get_string_size("Up", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


## Width of the menu's decorative tile row: four 160 px tiles, space_s apart.
static func menu_row_width(skin: SkinData) -> float:
	return 4.0 * 160.0 + 3.0 * skin.num(&"space_s")


## A How to play example row: the chain as a one row board view in the
## skin's chained look, the arrow, then the result tile.
static func example_row(skin: SkinData, values: Array[int], result: int) -> HBoxContainer:
	var row: HBoxContainer = UiParts.hbox(0.0)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var side: float = Spec.EXAMPLE_TILE
	var count: int = values.size()
	var width: float = float(count) * side + float(count - 1) * skin.num(&"board_gap") + 2.0 * skin.num(&"board_padding")
	if skin.numbers.has(&"orb_scale"):
		width = float(count) * side / skin.num(&"orb_scale")
	var board: SkinBoardView = SkinCatalog.make_board_view(skin)
	board.setup(skin, count, 1)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.custom_minimum_size = Vector2(width, board.preferred_height(width))
	board.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cells: PackedInt64Array = PackedInt64Array()
	var chain: Array[Vector2i] = []
	for i: int in count:
		cells.append(exponent(values[i]))
		chain.append(Vector2i(i, 0))
	board.set_board(cells)
	board.set_chain(chain, Vector2(-1.0, -1.0))
	row.add_child(board)
	row.add_child(_gap(skin.num(&"space_m")))
	var arrow: Control = AddedIcon.new()
	(arrow as AddedIcon).setup(skin, &"arrow", skin.color(&"ink_muted"), Spec.ARROW_ICON)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(arrow)
	row.add_child(_gap(skin.num(&"space_m")))
	var tile: SkinTileView = UiParts.tile(skin, exponent(result), side)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)
	return row


## The exponent k of a tile value 2^k, as boards and skins take it since
## 2026-10-21 (ARCHITECTURE.md 17); 0 for 0 (empty). The mockups keep
## writing tile values, which read more plainly.
static func exponent(value: int) -> int:
	if value <= 0:
		return 0
	var k: int = 0
	while (1 << k) < value:
		k += 1
	return k


static func _gap(width: float) -> Control:
	var gap: Control = Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.custom_minimum_size = Vector2(width, 0.0)
	return gap


## A row that opens a screen: title (body, ink), optional detail (label,
## ink_muted) under it, and the chevron at the right. row_height tall.
static func open_row(skin: SkinData, title: String, detail: String) -> Button:
	var row: Button = Button.new()
	row.theme_type_variation = &"RowButton"
	row.custom_minimum_size = Vector2(0.0, skin.num(&"row_height"))
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var line: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(line)
	var texts: VBoxContainer = UiParts.vbox(0.0)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(texts)
	texts.add_child(UiParts.label(skin, &"BodyLabel", title))
	if not detail.is_empty():
		var detail_label: Label = Label.new()
		detail_label.theme_type_variation = &"RowDetailLabel"
		# Names keep their capitals (DESIGN_SYSTEM.md 3.4): capitals may apply,
		# a lowercase rule may not.
		var upper: bool = String(skin.type_roles[&"label"].get("case", "")) == "upper"
		detail_label.text = detail.to_upper() if upper else detail
		texts.add_child(detail_label)
	var chevron: Control = AddedIcon.new()
	(chevron as AddedIcon).setup(skin, &"chevron", skin.color(&"ink_muted"), skin.num(&"icon_hud"))
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(chevron)
	return row


## Plain text reflowed for reading: blank lines split paragraphs, every
## other line break and run of spaces becomes one space.
static func reflow(text: String) -> PackedStringArray:
	var normalized: String = text.replace("\r\n", "\n")
	var spaces: RegEx = RegEx.create_from_string("[ \\t\\n]+")
	var out: PackedStringArray = PackedStringArray()
	var blank: RegEx = RegEx.create_from_string("\\n[ \\t]*\\n")
	for paragraph: String in blank.sub(normalized, "\u001f", true).split("\u001f"):
		var line: String = spaces.sub(paragraph, " ", true).strip_edges()
		if not line.is_empty():
			out.append(line)
	return out
