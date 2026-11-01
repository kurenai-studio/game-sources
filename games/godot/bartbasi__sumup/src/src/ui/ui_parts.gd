extends RefCounted
## Small builders the screens and panels share. Every color, size and font
## comes from the Theme's type variations (docs/ARCHITECTURE.md section 7) or
## from SkinData tokens; nothing here holds a value of its own.
##
## A Theme cannot set text case or alignment, so the builders case text with
## the skin's rule for the variation's type role, and the two Slate rules of
## the contract live here: SignalLabel takes the label role in Slate (the title
## role elsewhere), and Slate left aligns the text of every button but a chip,
## and its text blocks (DESIGN_SYSTEM.md 5.7 and 7, Alignment).

## The type role behind each variation the screens use.
const ROLES: Dictionary[StringName, StringName] = {
	&"DisplayLabel": &"display",
	&"TitleLabel": &"title",
	&"BodyLabel": &"body",
	&"MutedLabel": &"body",
	&"CaptionLabel": &"label",
	&"BadgeLabel": &"label",
	&"HintLabel": &"label",
	&"PrimaryButton": &"body",
	&"SecondaryButton": &"body",
	&"ChipButton": &"body",
	&"HeadingLabel": &"heading",
	&"ReadingLabel": &"reading",
	&"RowDetailLabel": &"label",
}

const _LEFT_ALIGNED_SKIN: StringName = &"slate"
const _FREE_SECTIONS_SKIN: StringName = &"nova"
const _CASE_UPPER: String = "upper"


## The type role of a variation in this skin.
static func role(skin: SkinData, variation: StringName) -> StringName:
	if variation == &"SignalLabel":
		return &"label" if skin.id == _LEFT_ALIGNED_SKIN else &"title"
	return ROLES.get(variation, &"body")


## True for the skin that left aligns (Slate).
static func align_start(skin: SkinData) -> bool:
	return skin.id == _LEFT_ALIGNED_SKIN


## Centered, or left for Slate.
static func block_alignment(skin: SkinData) -> HorizontalAlignment:
	return HORIZONTAL_ALIGNMENT_LEFT if align_start(skin) else HORIZONTAL_ALIGNMENT_CENTER


## True for the skin that rules its screens with hairlines (Slate): under the
## reading screen header, and between reading screen sections with no gap
## (DESIGN_SYSTEM.md 7.11).
static func ruled(skin: SkinData) -> bool:
	return skin.id == _LEFT_ALIGNED_SKIN


## The gap between reading screen sections (DESIGN_SYSTEM.md 7.11): Gumdrop's
## cards space_s apart, Slate's ruled sections none, Nova's space_l apart.
static func section_gap(skin: SkinData) -> float:
	if ruled(skin):
		return 0.0
	return skin.num(&"space_l") if floats_free(skin) else skin.num(&"space_s")


## True for the skin whose reading screen sections stand free on the
## backdrop with no box and no rule (Nova).
static func floats_free(skin: SkinData) -> bool:
	return skin.id == _FREE_SECTIONS_SKIN


## A label in a variation, its text cased for the variation's role.
static func label(skin: SkinData, variation: StringName, text: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var made: Label = Label.new()
	made.theme_type_variation = variation
	made.text = skin.cased(role(skin, variation), text)
	made.horizontal_alignment = align
	made.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return made


## A label that wraps to the width it is given.
static func paragraph(skin: SkinData, variation: StringName, text: String, align: HorizontalAlignment) -> Label:
	var made: Label = label(skin, variation, text, align)
	made.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	made.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return made


## A label for a name in a role whose rule may be lowercase (DESIGN_SYSTEM.md
## 3.4: names keep their capitals). Capitals may apply; any other rule leaves
## the text as written.
static func name_label(skin: SkinData, variation: StringName, text: String) -> Label:
	var made: Label = label(skin, variation, text)
	made.text = text.to_upper() if case_rule(skin, role(skin, variation)) == _CASE_UPPER else text
	return made


## The case rule of a type role: "none", "upper" or "lower".
static func case_rule(skin: SkinData, type_role: StringName) -> String:
	if not skin.type_roles.has(type_role):
		return ""
	return String(skin.type_roles[type_role].get("case", ""))


## A chain as a one row board in the skin's own board view (DESIGN_SYSTEM.md
## 7.2 and 7.12): every cell chained in drag order, no preview and no
## highlight, sized for side px tiles. values are exponents.
static func chain_board(skin: SkinData, values: PackedInt64Array, side: float) -> SkinBoardView:
	var count: int = values.size()
	var board: SkinBoardView = SkinCatalog.make_board_view(skin)
	board.name = "Chain"
	board.setup(skin, count, 1)
	var width: float = chain_width(skin, count, side)
	board.custom_minimum_size = Vector2(width, board.preferred_height(width))
	board.size = board.custom_minimum_size
	board.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	board.set_board(values)
	board.set_chain(row_cells(count), Vector2(-1.0, -1.0))
	return board


## A one row board's width for count tiles of side px: the tiles, the gaps
## and the tray padding, or for orbs the pitch (the tile over orb_scale).
static func chain_width(skin: SkinData, count: int, side: float) -> float:
	if skin.numbers.has(&"orb_scale"):
		return float(count) * side / skin.num(&"orb_scale")
	var padding: float = skin.numbers.get(&"board_padding", 0.0)
	return float(count) * side + float(count - 1) * skin.num(&"board_gap") + 2.0 * padding


## The cells of a one row board, left to right.
static func row_cells(count: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for index: int in count:
		cells.append(Vector2i(index, 0))
	return cells


## The skin's arrow icon, side px, in ink_muted, as in the example rows.
static func arrow(skin: SkinData, side: float) -> SkinIcon:
	var made: SkinIcon = UiKit.make_icon(skin)
	made.name = "Arrow"
	made.custom_minimum_size = Vector2(side, side)
	made.size = Vector2(side, side)
	made.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	made.set_icon(&"arrow")
	made.set_color(skin.color(&"ink_muted"))
	return made


## text's advance width in the font of variation's role at font_px, rounded
## up to whole px as a Label's minimum width is.
static func text_width(skin: SkinData, variation: StringName, text: String, font_px: int) -> float:
	var face: Font = skin.font(role(skin, variation))
	return ceilf(face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_px).x)


## The largest font size, from start_px down, at which text in variation is
## no wider than width. A number shrinks as far as it must, so its panel never
## grows past the content column (QA6-10); 1 px is only the loop's end.
static func fit_size(skin: SkinData, variation: StringName, text: String, width: float, start_px: int) -> int:
	var size: int = start_px
	var at_start: float = text_width(skin, variation, text, size)
	if at_start <= width or size <= 1:
		return size
	size = clampi(floori(float(size) * maxf(width, 0.0) / at_start), 1, size)
	while size > 1 and text_width(skin, variation, text, size) > width:
		size -= 1
	return size


## Sets label's font size to the largest, from start_px down, at which its
## text fits width. At the role's own size it carries no override.
static func fit_label(skin: SkinData, label: Label, width: float, start_px: int) -> void:
	var size: int = fit_size(skin, label.theme_type_variation, label.text, width, start_px)
	if size == skin.font_size(role(skin, label.theme_type_variation)):
		label.remove_theme_font_size_override(&"font_size")
	else:
		label.add_theme_font_size_override(&"font_size", size)


## The panel stylebox of a type variation, from the Theme resource of the
## nearest ancestor that has one, so it can be read before the panel enters
## the tree (headless tests). Inside the tree with no such ancestor, the
## usual lookup. Null when there is none.
static func panel_style(context: Control, type: StringName) -> StyleBox:
	var node: Node = context
	while node != null:
		if node is Control:
			var own: Theme = (node as Control).theme
			if own != null and own.has_stylebox(&"panel", type):
				return own.get_stylebox(&"panel", type)
		node = node.get_parent()
	if context.is_inside_tree():
		return context.get_theme_stylebox(&"panel", type)
	return null


## The width a panel's padding takes: its stylebox's minimum width, or 0.
static func panel_padding(context: Control, type: StringName) -> float:
	var style: StyleBox = panel_style(context, type)
	return style.get_minimum_size().x if style != null else 0.0


## An empty Control height px tall (and width px wide).
static func spacer(height: float, width: float = 0.0) -> Control:
	var gap: Control = Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.custom_minimum_size = Vector2(width, height)
	return gap


## A button in a variation. In Slate every button but a chip left aligns its
## text (DESIGN_SYSTEM.md 7, Alignment).
static func button(skin: SkinData, variation: StringName, text: String) -> Button:
	var made: Button = Button.new()
	made.theme_type_variation = variation
	made.text = skin.cased(role(skin, variation), text)
	made.focus_mode = Control.FOCUS_NONE
	made.custom_minimum_size = Vector2(0.0, skin.num(&"button_height"))
	if variation != &"ChipButton" and align_start(skin):
		made.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return made


## A touch_min square button with the skin's icon on its face, emitting
## pressed.
static func icon_button(skin: SkinData, icon_name: StringName) -> BaseButton:
	return UiKit.make_icon_button(skin, icon_name)


## The width of an icon button's visible face: Gumdrop's raised face
## (hud_button_face), Nova's ring (hud_ring), or Slate's bare icon (icon_hud).
static func icon_face(skin: SkinData) -> float:
	for token: StringName in [&"hud_button_face", &"hud_ring"]:
		if skin.numbers.has(token):
			return skin.numbers[token]
	return skin.num(&"icon_hud")


## How far an icon button's touch box sits from the screen side, so its
## visible face lines up with board_margin as the HUD's buttons do.
static func icon_button_inset(skin: SkinData) -> float:
	return maxf(0.0, skin.num(&"board_margin") - (skin.num(&"touch_min") - icon_face(skin)) * 0.5)


## One tile drawn by the skin's own tile component, side px square. exponent
## is the tile's exponent (2 is 1, 1024 is 10), as everywhere since
## ARCHITECTURE.md section 17.
static func tile(skin: SkinData, exponent: int, side: float) -> SkinTileView:
	var view: SkinTileView = SkinCatalog.make_tile_view(skin)
	view.custom_minimum_size = Vector2(side, side)
	view.size = Vector2(side, side)
	view.set_value(exponent)
	return view


## A badge pill (DESIGN_SYSTEM.md 7.8): "New best", for example.
static func badge(skin: SkinData, text: String) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.theme_type_variation = &"BadgePanel"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(label(skin, &"BadgeLabel", text))
	return pill


## The skin's divider.
static func divider() -> HSeparator:
	var line: HSeparator = HSeparator.new()
	line.theme_type_variation = &"Hairline"
	return line


static func vbox(separation: float) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", roundi(separation))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


static func hbox(separation: float) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override(&"separation", roundi(separation))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


## A row with a caption on the left and value on the right, row_height tall.
static func record_row(skin: SkinData, caption: String, value: Control) -> HBoxContainer:
	var row: HBoxContainer = hbox(skin.num(&"space_s"))
	row.custom_minimum_size = Vector2(0.0, skin.num(&"row_height"))
	var name_label: Label = label(skin, &"CaptionLabel", caption)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value)
	return row


## True when the skin's dialog panel is a floating card (rounded bottom
## corners, Gumdrop), false when it is a sheet that runs to the screen edges
## (Slate, Nova). DESIGN_SYSTEM.md section 7. context must be in the tree.
static func panel_floats(context: Control) -> bool:
	var style: StyleBoxFlat = context.get_theme_stylebox(&"panel", &"CardPanel") as StyleBoxFlat
	return style != null and style.corner_radius_bottom_left > 0


## The fill of the skin's dialog panel. context must be in the tree.
static func panel_fill(context: Control, skin: SkinData) -> Color:
	var style: StyleBoxFlat = context.get_theme_stylebox(&"panel", &"CardPanel") as StyleBoxFlat
	return style.bg_color if style != null else skin.color(&"surface")


## Frees every child of node now, so a rebuild starts empty.
static func clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()
