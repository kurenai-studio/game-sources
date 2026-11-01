# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name WavePreview
extends BattlePanel
## The wave preview (RULES 9.1): which creatures the next wave brings, how many,
## and from which entrance letter. It is open in build phases, in portrait too, and
## folds into a strip while a wave runs. A tap on the header folds or opens it. A tap
## on a row shows that creature's numbers for this wave. A creature that is new to
## the player has a "New" tag in the open rows and in the folded strip, and a boss
## row always shows its one line. Names, lines and numbers come from the Catalog and
## the Battle.

## A build phase began and the preview opened for it. In portrait the screen then checks that
## the open form fits under the map, and folds it again if it does not (docs/ARCHITECTURE.md 7.4).
signal build_began()

## The wave the preview shows is the next one to start.
var index: int = -1
var expanded: bool = true
var header: TapRow = null
var header_label: Label = null
## The folded strip's one line of chips, or null while the preview is open.
var strip: StripRow = null
var rows: Array[TapRow] = []
var open_rows: Array[StringName] = []

## The waiting risk card (a run): its name and text. Empty strings for none. It shows first.
var risk_name: String = ""
var risk_text: String = ""
## The row of the open preview that shows the waiting risk card, or null.
var risk_row: PanelContainer = null
## The chip at the start of the folded strip, or null.
var risk_chip: Control = null

var _unseen: Array[StringName] = []
var _signature: Array = []
var _last_phase: int = -1


## The creature ids that are new to the player; their rows and chips get a "New" tag.
func set_unseen(ids: Array[StringName]) -> void:
	if ids == _unseen:
		return
	_unseen = ids.duplicate()
	_signature = []
	refresh()


## The risk card waiting for the next wave (RULES 9.1, 14.5), or "" for none. The open preview
## lists it first as a row with its name and text, and the folded strip starts with a chip.
func set_risk(new_name: String, new_text: String) -> void:
	if new_name == risk_name and new_text == risk_text:
		return
	risk_name = new_name
	risk_text = new_text
	_signature = []
	refresh()


## Folds or opens the preview, as a tap on its header does.
func toggle() -> void:
	expanded = not expanded
	_signature = []
	refresh()


## Opens or folds the preview without a tap. The screen uses it after measuring.
func set_open(open: bool) -> void:
	if expanded == open:
		return
	expanded = open
	_signature = []
	refresh()


## Opens or closes the numbers of one creature row.
func toggle_row(enemy: StringName) -> void:
	if open_rows.has(enemy):
		open_rows.erase(enemy)
	else:
		open_rows.append(enemy)
	_signature = []
	refresh()


func refresh() -> void:
	if battle == null:
		return
	if int(battle.phase) != _last_phase:
		# Open in a build phase, folded into a strip during a wave.
		_last_phase = int(battle.phase)
		expanded = battle.phase == Battle.Phase.BUILD
		_signature = []
		if expanded:
			build_began.emit()
	var wave: int = battle.waves_started
	if wave != index:
		index = wave
		open_rows.clear()
		_signature = []
	var preview: Array[Dictionary] = battle.wave_preview(index)
	var signature: Array = [index, expanded, open_rows.duplicate(), _unseen.duplicate(), preview, risk_name, risk_text]
	if signature == _signature:
		return
	_signature = signature
	_rebuild(preview)


func _rebuild(preview: Array[Dictionary]) -> void:
	clear_column()
	rows.clear()
	strip = null
	risk_row = null
	risk_chip = null
	header = TapRow.new()
	header.set_look(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 3, 16)
	header.body.alignment = BoxContainer.ALIGNMENT_CENTER
	header.tapped.connect(toggle)
	var top: HBoxContainer = HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override(&"separation", 12)
	header_label = UiKit.heading(_title(preview))
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(header_label)
	var fold: TextureRect = TextureRect.new()
	fold.texture = IconTex.make(&"arrow", 64)
	fold.custom_minimum_size = Vector2(52.0, 52.0)
	fold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fold.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fold.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fold.rotation_degrees = 90.0 if expanded else 0.0
	fold.pivot_offset = Vector2(26.0, 26.0)
	fold.modulate = Palette.TEXT_SOFT
	fold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fold)
	header.body.add_child(top)
	if not expanded and (not preview.is_empty() or not risk_name.is_empty()):
		# The strip is one line: as many chips as fit, then a "+N" chip for the rest (RULES 9.1).
		# A waiting risk card comes first.
		strip = StripRow.new()
		strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not risk_name.is_empty():
			risk_chip = _risk_chip()
			strip.add_chip(risk_chip)
		for entry: Dictionary in preview:
			strip.add_chip(_chip(entry))
		header.body.add_child(strip)
	column.add_child(header)
	if expanded and not risk_name.is_empty():
		risk_row = _risk_row()
		column.add_child(risk_row)
	if expanded:
		var grid: GridContainer = GridContainer.new()
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var compact: bool = _is_compact(preview)
		grid.columns = _compact_columns(preview) if compact else _columns(preview)
		grid.add_theme_constant_override(&"h_separation", 10 if compact else 12)
		grid.add_theme_constant_override(&"v_separation", 10)
		for entry: Dictionary in preview:
			var row: TapRow = _cell(entry) if compact else _row(entry)
			rows.append(row)
			grid.add_child(row)
		column.add_child(grid)


## Three or more groups in the wide panel use small upright cells, up to four across, so
## even the longest wave takes one line of height. A boss row or an opened row needs the
## width and uses the rows below instead.
func _is_compact(preview: Array[Dictionary]) -> bool:
	if not wide or preview.size() < 3 or not open_rows.is_empty():
		return false
	for entry: Dictionary in preview:
		if battle.catalog.enemy(entry["enemy"]).boss:
			return false
	return true


## As many cells across as the panel holds with every name whole at the small size.
func _compact_columns(preview: Array[Dictionary]) -> int:
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var widest: float = 0.0
	for entry: Dictionary in preview:
		widest = maxf(widest, font.get_string_size(battle.catalog.enemy(entry["enemy"]).name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL).x)
	var inner: float = 1048.0 - 2.0 * 14.0 - 2.0 * 16.0
	var columns: int = mini(4, preview.size())
	while columns > 2 and (inner - 10.0 * float(columns - 1)) / float(columns) - 24.0 < widest:
		columns -= 1
	return columns


## Two rows side by side when the panel is wide and every row is short, so a wave with
## a few groups takes one line of height. A boss row or an opened row needs the width.
func _columns(preview: Array[Dictionary]) -> int:
	if not wide or preview.size() < 2 or not open_rows.is_empty():
		return 1
	for entry: Dictionary in preview:
		if battle.catalog.enemy(entry["enemy"]).boss:
			return 1
	return 2


func _title(preview: Array[Dictionary]) -> String:
	var total: int = battle.wave_count()
	if preview.is_empty():
		return "Every wave is out"
	return "Next: wave %d of %d" % [index + 1, total]


## A folded strip shows each group as a small picture, a count and an entrance letter.
func _chip(entry: Dictionary) -> Control:
	var chip: HBoxContainer = HBoxContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_constant_override(&"separation", 4)
	chip.add_child(GlyphIcon.new(72.0).show_enemy(entry["enemy"]))
	var text: Label = UiKit.label("%d %s" % [int(entry["count"]), BattleText.entrance_letter(int(entry["entrance"]))])
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_child(text)
	if _unseen.has(entry["enemy"]):
		chip.add_child(_new_tag())
	return chip


## The risk card in the folded strip: the moon and the word "Risk", so the chip is a shape and
## a word and not a color.
func _risk_chip() -> Control:
	var chip: HBoxContainer = HBoxContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_constant_override(&"separation", 4)
	chip.add_child(GlyphIcon.new(72.0).show_glyph(&"moon"))
	var text: Label = UiKit.label("Risk", &"Label")
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_child(text)
	return chip


## The risk card at the top of the open preview: its moon, "Risk" and name, and its text.
func _risk_row() -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL_RAISED, Palette.HONEY, 6, 16, 16))
	var line: HBoxContainer = HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", 14)
	line.add_child(GlyphIcon.new(88.0).show_glyph(&"moon"))
	var text: VBoxContainer = VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override(&"separation", 2)
	text.add_child(UiKit.heading("Risk: %s" % risk_name))
	text.add_child(UiKit.label(risk_text, &"SoftLabel"))
	line.add_child(text)
	row.add_child(line)
	return row


## A small upright cell: the picture (with the New tag beside it), the name, and the
## count with the entrance letter. About 190 px tall.
func _cell(entry: Dictionary) -> TapRow:
	var type: EnemyType = battle.catalog.enemy(entry["enemy"])
	var cell: TapRow = TapRow.new()
	cell.set_look(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 3, 12)
	cell.tapped.connect(toggle_row.bind(type.id))
	cell.body.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.body.add_theme_constant_override(&"separation", 0)
	var top: HBoxContainer = HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(GlyphIcon.new(64.0).show_enemy(type.id))
	var gap: Control = UiKit.spacer()
	gap.size_flags_vertical = Control.SIZE_FILL
	top.add_child(gap)
	if _unseen.has(type.id):
		top.add_child(_new_tag())
	cell.body.add_child(top)
	var name_label: Label = UiKit.heading(type.name)
	name_label.add_theme_font_size_override(&"font_size", UiTheme.FONT_SMALL)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	cell.body.add_child(name_label)
	var amount: HFlowContainer = HFlowContainer.new()
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_constant_override(&"h_separation", 10)
	var count: Label = UiKit.heading("x%d" % int(entry["count"]))
	count.add_theme_font_size_override(&"font_size", UiTheme.FONT_SMALL)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.add_child(count)
	var from: Label = UiKit.label("from %s" % BattleText.entrance_letter(int(entry["entrance"])), &"SoftLabel")
	from.add_theme_font_size_override(&"font_size", UiTheme.FONT_SMALL)
	from.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.add_child(from)
	cell.body.add_child(amount)
	return cell


func _row(entry: Dictionary) -> TapRow:
	var type: EnemyType = battle.catalog.enemy(entry["enemy"])
	var row: TapRow = TapRow.new()
	row.set_look(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 3, 16)
	row.tapped.connect(toggle_row.bind(type.id))
	var line: HBoxContainer = HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", 14)
	line.add_child(GlyphIcon.new(88.0).show_enemy(type.id))
	var names: VBoxContainer = VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override(&"separation", 2)
	var name_label: Label = UiKit.heading(type.name)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	names.add_child(name_label)
	# The second line wraps, so the New tag drops to a third line instead of widening a row.
	var amount: HFlowContainer = HFlowContainer.new()
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_constant_override(&"h_separation", 16)
	amount.add_theme_constant_override(&"v_separation", 4)
	var count: Label = UiKit.heading("x%d" % int(entry["count"]))
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.add_child(count)
	var from: Label = UiKit.label("from %s" % BattleText.entrance_letter(int(entry["entrance"])), &"SoftLabel")
	from.autowrap_mode = TextServer.AUTOWRAP_OFF
	from.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount.add_child(from)
	if _unseen.has(type.id):
		amount.add_child(_new_tag())
	names.add_child(amount)
	line.add_child(names)
	row.body.add_child(line)
	if type.boss or open_rows.has(type.id):
		row.body.add_child(UiKit.label(type.info, &"SoftLabel"))
	if open_rows.has(type.id):
		var numbers: String = "Health %d, gold %d when defeated" % [int(entry["health"]), int(entry["bounty"])]
		if int(entry["heal"]) > 0:
			numbers += ", heals %d" % int(entry["heal"])
		row.body.add_child(UiKit.label(numbers, &"Label"))
	return row


## The word "New" in a framed tag: the word and the frame carry it, not a color.
func _new_tag() -> Control:
	var tag: PanelContainer = PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL, Palette.HONEY, 4, 16, 8))
	var l: Label = UiKit.label("New", &"Label")
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_color_override(&"font_color", Palette.HONEY)
	tag.add_child(l)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tag
