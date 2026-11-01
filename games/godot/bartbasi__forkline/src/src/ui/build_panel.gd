# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name BuildPanel
extends BattlePanel
## The build panel for an empty build spot (RULES 4.6, 9.5). Each tower the level
## offers is a card with its silhouette and its price. Names do not fit a card on
## the cover screen, so the chosen tower's name, line and numbers show below the
## cards. Choosing a card shows its range (`range_changed`, for the map's ring),
## and a separate Build button confirms.

## The map should draw a range ring: a cell, the range in hundredths of a tile,
## and whether it is a boost reach. Cell (-1, -1) hides it.
signal range_changed(cell: Vector2i, reach: int, boost: bool)
## A tower was built.
signal built(cell: Vector2i, type: StringName)

const NO_CELL: Vector2i = Vector2i(-1, -1)
## The space between cards, both ways.
const CARD_GAP: int = 14
## The same in the landscape side column. With its scroll bar showing, the column has room
## for four 160 px cards only at this gap.
const SIDE_GAP: int = 8
## Most cards in one row. Ten towers make two rows of five in the roomy portrait sheet.
const MAX_COLUMNS: int = 5
## Most cards in one row in the landscape side column: 4 x 160 + 3 x 8 = 664 px, which is all
## the room the column leaves (760 less the margins, the panel's padding and the scroll bar).
## A fixed cap, not read from the panel's width: a panel that starts with no width must not
## ask for five columns, grow to fit them and then think it has the room.
const SIDE_COLUMNS: int = 4

var cell: Vector2i = NO_CELL
var selected: StringName = &""
var card_buttons: Dictionary[StringName, TapButton] = {}
## The "Need N" line of each card that costs more than the gold in hand. It is updated in
## place as gold changes, so a card is never rebuilt under a finger.
var need_labels: Dictionary[StringName, Label] = {}
var name_label: Label = null
var info_label: Label = null
var build_button: TapButton = null
## The warning label above the Build button, or null when the chosen tower is safe.
var star_warning_label: Label = null

var _signature: Array = []
var _open: bool = false


func _init() -> void:
	super()
	resized.connect(_on_resized)


## Opens the panel on a free build spot and chooses the first tower the level offers.
func show_spot(new_cell: Vector2i) -> void:
	cell = new_cell
	selected = &""
	_signature = []
	_open = true
	clear_feedback()
	var options: Array[Dictionary] = battle.build_options(cell) if battle != null else []
	if not options.is_empty():
		selected = options[0]["tower"]
	refresh()
	_announce_range()


func is_open() -> bool:
	return _open


## Cards in one row or a grid, and the numbers in two columns when wide.
func set_wide(value: bool) -> void:
	if value != wide:
		super(value)
		_signature = []
		refresh()


## Chooses a card, as a tap on it does.
func select_tower(type: StringName) -> void:
	if battle == null or not card_buttons.has(type):
		return
	selected = type
	clear_feedback()
	refresh()
	_announce_range()


## Builds the chosen tower, as a tap on the Build button does.
func confirm() -> void:
	if battle == null or not _open or selected == &"":
		return
	var type: StringName = selected
	var price: int = _price(type)
	var result: StringName = battle.place_tower(cell, type)
	if finish(result, BattleText.shortfall(result, price, battle.gold)):
		built.emit(cell, type)
		close()


## Closes the panel and hides the range ring.
func close() -> void:
	if not _open:
		return
	_open = false
	range_changed.emit(NO_CELL, 0, false)
	closed.emit()


func refresh() -> void:
	if battle == null or not _open:
		return
	var options: Array[Dictionary] = battle.build_options(cell)
	if options.is_empty():
		# The spot is taken or gone: nothing left to build here.
		close()
		return
	var ids: Array[StringName] = []
	for option: Dictionary in options:
		ids.append(option["tower"])
	if not ids.has(selected):
		selected = ids[0]
	var signature: Array = [cell, selected, wide, options, warns(&"build", selected), _columns(options.size())]
	if signature != _signature:
		_signature = signature
		_rebuild(options)
	_update_needs(options)


## "Need N" is the gold still missing now.
func _update_needs(options: Array[Dictionary]) -> void:
	for option: Dictionary in options:
		var label: Label = need_labels.get(option["tower"])
		if label != null and not bool(option["affordable"]):
			label.text = _need_text(option)


func _need_text(option: Dictionary) -> String:
	return "Need %d" % maxi(0, int(option["cost"]) - battle.gold)


func _rebuild(options: Array[Dictionary]) -> void:
	clear_column()
	card_buttons.clear()
	need_labels.clear()
	var header: HBoxContainer = HBoxContainer.new()
	var title: Label = UiKit.heading("Build a tower")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	var close_it: TapButton = UiKit.icon_button(&"close")
	close_it.tapped.connect(close)
	header.add_child(close_it)
	column.add_child(header)
	var grid: GridContainer = GridContainer.new()
	grid.columns = _columns(options.size())
	grid.add_theme_constant_override(&"h_separation", _gap())
	grid.add_theme_constant_override(&"v_separation", _gap())
	for option: Dictionary in options:
		var button: TapButton = _card(option)
		card_buttons[option["tower"]] = button
		grid.add_child(button)
	column.add_child(grid)
	var type: TowerType = battle.catalog.tower(selected)
	var chosen: Dictionary = {}
	for option: Dictionary in options:
		if option["tower"] == selected:
			chosen = option
	name_label = UiKit.heading(type.name)
	column.add_child(name_label)
	info_label = UiKit.label(type.info, &"SoftLabel")
	column.add_child(info_label)
	column.add_child(_rows(BattleText.tower_rows(chosen["numbers"], type.kind)))
	star_warning_label = null
	if warns(&"build", selected):
		# A tower over the limit, a banned tower, or a kind over the limit (RULES 10.6).
		var note: StarNote = StarNote.new()
		star_warning_label = note.label
		column.add_child(note)
	var cost: int = int(chosen["cost"])
	var affordable: bool = chosen["affordable"]
	build_button = UiKit.wrapped(UiKit.button("Build for %d" % cost, &"PrimaryButton" if affordable else &"Button"))
	if not affordable:
		# Gold is short: the button stays tappable (it explains why) and wears a lock.
		build_button.icon = IconTex.make(&"lock", 56)
		for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color"]:
			build_button.add_theme_color_override(state, Palette.TEXT_SOFT)
	build_button.tapped.connect(confirm)
	column.add_child(build_button)
	column.add_child(feedback_box)


func _card(option: Dictionary) -> TapButton:
	var type: StringName = option["tower"]
	var affordable: bool = option["affordable"]
	var button: TapButton = UiKit.button("", &"CardButton")
	button.custom_minimum_size = Vector2(Layout.MIN_TOUCH, 270.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill: Color = Palette.CARD if affordable else Palette.CARD_DIM
	var edge: Color = Palette.HONEY if type == selected else Palette.INK_LINE
	var border: int = 12 if type == selected else 4
	var box: StyleBoxFlat = UiKit.box(fill, edge, border, UiTheme.RADIUS, 8)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, box)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override(&"separation", 2)
	inner.add_child(GlyphIcon.new(128.0).show_tower(type, 1, -1))
	var cost: Label = UiKit.label(str(int(option["cost"])), &"CardLabel")
	cost.add_theme_font_size_override(&"font_size", UiTheme.FONT_BUTTON)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(cost)
	var need: Label = UiKit.label("" if affordable else _need_text(option), &"CardMutedLabel")
	need.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(need)
	if not affordable:
		need_labels[type] = need
	button.add_child(inner)
	button.tapped.connect(select_tower.bind(type))
	return button


func _rows(rows: Array[PackedStringArray]) -> Control:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 48)
	grid.add_theme_constant_override(&"v_separation", 6)
	for row: PackedStringArray in rows:
		var r: StatRow = StatRow.pair(row[0], row[1])
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(r)
	return grid


## Cards per row for `count` towers when the panel is `room` px wide inside its margins
## (0 when it has no width yet). Two rows is the aim, and a card is never narrower than
## MIN_TOUCH, so a narrow side panel gets fewer columns and more rows.
static func columns_for(count: int, room: float, gap: int = CARD_GAP, most: int = MAX_COLUMNS) -> int:
	var wanted: int = maxi(1, count)
	if count == 4:
		wanted = 2
	elif count > 3:
		wanted = mini(most, ceili(float(count) / 2.0))
	if room <= 0.0:
		return wanted
	var fit: int = maxi(1, int((room + float(gap)) / (Layout.MIN_TOUCH + float(gap))))
	return mini(wanted, fit)


func _columns(count: int) -> int:
	return columns_for(count, _room(), _gap(), MAX_COLUMNS if wide else SIDE_COLUMNS)


## Portrait keeps the roomy gap; the side column has no width to spare.
func _gap() -> int:
	return CARD_GAP if wide else SIDE_GAP


## The width the cards have, inside the panel's margins. 0 before the panel has been laid out.
func _room() -> float:
	if size.x <= 0.0:
		return 0.0
	var box: StyleBox = get_theme_stylebox(&"panel")
	return size.x - box.get_margin(SIDE_LEFT) - box.get_margin(SIDE_RIGHT)


## The panel got its width or changed it: the cards may need another number of columns.
func _on_resized() -> void:
	if _open:
		refresh.call_deferred()


func _price(type: StringName) -> int:
	for option: Dictionary in battle.build_options(cell):
		if option["tower"] == type:
			return int(option["cost"])
	return 0


## Tells the map which range to draw: the chosen tower's reach.
func _announce_range() -> void:
	if battle == null or selected == &"":
		return
	for option: Dictionary in battle.build_options(cell):
		if option["tower"] == selected:
			var kind: StringName = battle.catalog.tower(selected).kind
			range_changed.emit(cell, int(option["numbers"]["reach"]), kind == &"boost")
