# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name LevelSelect
extends PageFrame
## The campaign: each region with its levels in play order (RULES 12, 16). A level
## shows its number, its name, the stars earned and, when it is not open yet, why.
## A level with a saved game says so. Tapping an open level opens its card. Names
## and numbers come from the data; this file names no region or level.

## The player tapped an open level.
signal level_chosen(id: StringName)

var rows: Dictionary[StringName, TapRow] = {}
var region_labels: Array[Label] = []

var _trash: Array[Node] = []


func _init() -> void:
	super("Campaign")


## Builds the list again from the data and the player's progress. `saved_level` is the
## level that has a saved game, or &"".
func populate(game: GameData, progress: Progress, saved_level: StringName) -> void:
	for child: Node in column.get_children():
		column.remove_child(child)
		if is_inside_tree():
			child.queue_free()
		else:
			_trash.append(child)
	rows.clear()
	region_labels.clear()
	for region_index: int in game.campaign.size():
		_add_region(game, progress, saved_level, region_index)


func _add_region(game: GameData, progress: Progress, saved_level: StringName, index: int) -> void:
	var region: Dictionary = game.campaign[index]
	var open: bool = progress.region_open(game, index)
	var head: Label = UiKit.heading("Region %d: %s" % [index + 1, region["name"]])
	region_labels.append(head)
	column.add_child(head)
	if not open:
		column.add_child(UiKit.label(_region_lock_text(game, index), &"SoftLabel"))
	var list: Array[StringName] = region["levels"]
	for id: StringName in list:
		var row: TapRow = _level_row(game, progress, saved_level, id)
		rows[id] = row
		column.add_child(row)


func _region_lock_text(game: GameData, index: int) -> String:
	var before: Array[StringName] = game.campaign[index - 1]["levels"]
	var needs: Array[int] = game.catalog.rules.region_stars
	var text: String = "Locked. Clear level %s" % CampaignText.number(game, before.back())
	if index < needs.size() and needs[index] > 0:
		text += " and earn %d stars." % needs[index]
	else:
		text += "."
	return text


func _level_row(game: GameData, progress: Progress, saved_level: StringName, id: StringName) -> TapRow:
	var level: LevelData = game.levels[id]
	var open: bool = progress.level_open(game, id)
	var bits: int = progress.levels.get(id, 0)
	var row: TapRow = TapRow.new(&"CardPanel" if open else &"PanelContainer")
	row.set_look(Palette.CARD if open else Palette.PANEL, Palette.INK_LINE if open else Palette.PANEL_EDGE, 4, 24)
	var line: HBoxContainer = HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", 18)
	var number: Label = UiKit.heading(CampaignText.number(game, id))
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	number.add_theme_color_override(&"font_color", Palette.TEXT_DARK if open else Palette.TEXT_LIGHT)
	line.add_child(number)
	var names: VBoxContainer = VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override(&"separation", 0)
	names.add_child(UiKit.label(level.name, &"CardLabel" if open else &"Label"))
	var sub: String = _sub_text(game, progress, saved_level, id, open)
	if not sub.is_empty():
		names.add_child(UiKit.label(sub, &"CardMutedLabel" if open else &"SoftLabel"))
	line.add_child(names)
	if open:
		line.add_child(_stars(bits))
	else:
		var lock: TextureRect = TextureRect.new()
		lock.texture = IconTex.make(&"lock", 72)
		lock.custom_minimum_size = Vector2(60.0, 60.0)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock.modulate = Palette.TEXT_SOFT
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(lock)
	row.body.add_child(line)
	row.overlay.disabled = not open
	row.tapped.connect(level_chosen.emit.bind(id))
	return row


func _sub_text(game: GameData, progress: Progress, saved_level: StringName, id: StringName, open: bool) -> String:
	if not open:
		var list: Array[StringName] = _region_of(game, id)
		var at: int = list.find(id)
		if at > 0:
			return "Clear level %s first." % CampaignText.number(game, list[at - 1])
		return "Locked."
	if saved_level == id:
		return "Saved game"
	if progress.cleared(id):
		return "%d of 3 stars" % StarText.count(progress.levels.get(id, 0))
	return "Not played yet"


func _region_of(game: GameData, id: StringName) -> Array[StringName]:
	for region: Dictionary in game.campaign:
		var list: Array[StringName] = region["levels"]
		if list.has(id):
			return list
	return []


func _stars(bits: int) -> Control:
	var box: HBoxContainer = HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 4)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i: int in 3:
		box.add_child(StarIcon.new(56.0, (bits >> i) & 1 == 1))
	return box


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for node: Node in _trash:
			if is_instance_valid(node):
				node.free()
		_trash.clear()
