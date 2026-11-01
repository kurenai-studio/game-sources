# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name InfoCard
extends Modal
## The first sight card (RULES 9.2): the first time a tower is on offer or a creature
## is in the next wave, a card opens by itself with its picture, name, one line and
## real numbers. Several new things at one time page through one card. Names, lines
## and numbers come from the Catalog and the Battle, never from this file.
##
## Each item is {"kind": &"tower" or &"enemy", "id": StringName, "wave": int}. "wave"
## is the wave index whose strength the creature's numbers use.

## Every item has been shown and the player closed the card.
signal finished()

var battle: Battle
var items: Array[Dictionary] = []
var index: int = 0
var next_button: TapButton
var name_label: Label
var info_label: Label
var count_label: Label

var _page: VBoxContainer
## Old pages of a card that is not in a scene tree; freed with the card.
var _trash: Array[Node] = []


func _init(new_battle: Battle = null, new_items: Array[Dictionary] = []) -> void:
	super("New")
	battle = new_battle
	items = new_items.duplicate()
	_page = VBoxContainer.new()
	_page.add_theme_constant_override(&"separation", 14)
	body.add_child(_page)
	count_label = UiKit.label("", &"SoftLabel")
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(count_label)
	next_button = UiKit.button("Got it", &"PrimaryButton")
	next_button.tapped.connect(advance)
	body.add_child(next_button)
	if battle != null and not items.is_empty():
		_show(0)


## Goes to the next item, or closes the card after the last one.
func advance() -> void:
	if index + 1 < items.size():
		_show(index + 1)
		return
	finished.emit()
	closed.emit()


## The back button closes the whole card. Closing it counts as having read it.
func request_close() -> void:
	finished.emit()
	closed.emit()


func _show(at: int) -> void:
	index = at
	for child: Node in _page.get_children():
		_page.remove_child(child)
		if is_inside_tree():
			child.queue_free()
		else:
			_trash.append(child)
	var item: Dictionary = items[at]
	var id: StringName = item["id"]
	if item["kind"] == &"tower":
		_show_tower(id)
	else:
		_show_enemy(id, int(item.get("wave", 0)))
	var more: bool = at + 1 < items.size()
	next_button.text = "Next" if more else "Got it"
	count_label.text = "%d of %d" % [at + 1, items.size()] if items.size() > 1 else ""
	count_label.visible = items.size() > 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for node: Node in _trash:
			if is_instance_valid(node):
				node.free()
		_trash.clear()


func _head(picture: GlyphIcon, name_text: String, sub_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	row.add_child(picture)
	var names: VBoxContainer = VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override(&"separation", 0)
	name_label = UiKit.heading(name_text)
	names.add_child(name_label)
	names.add_child(UiKit.label(sub_text, &"SoftLabel"))
	row.add_child(names)
	_page.add_child(row)


func _show_tower(id: StringName) -> void:
	var type: TowerType = battle.catalog.tower(id)
	if type == null:
		return
	title_label.text = "New tower"
	_head(GlyphIcon.new(180.0).show_tower(id, 1, -1), type.name, "Costs %d" % type.stats(1, -1).cost)
	info_label = UiKit.label(type.info)
	_page.add_child(info_label)
	_page.add_child(_rows(BattleText.tower_rows(type.stats(1, -1).numbers(), type.kind)))


func _show_enemy(id: StringName, wave: int) -> void:
	var type: EnemyType = battle.catalog.enemy(id)
	if type == null:
		return
	title_label.text = "New creature"
	var sub: String = "Boss" if type.boss else ("Flies" if type.flying else "Walks")
	_head(GlyphIcon.new(180.0).show_enemy(id), type.name, sub)
	info_label = UiKit.label(type.info)
	_page.add_child(info_label)
	var health: int = type.health
	var bounty: int = type.bounty
	for entry: Dictionary in battle.wave_preview(wave):
		if entry["enemy"] == id:
			health = int(entry["health"])
			bounty = int(entry["bounty"])
			break
	var rows: Array[PackedStringArray] = [
		PackedStringArray(["Health", str(health)]),
		PackedStringArray(["Armor", str(type.armor)]),
		PackedStringArray(["Speed", "%s tiles/s" % BattleText.speed(type.speed)]),
		PackedStringArray(["Lives lost", str(type.lives)]),
		PackedStringArray(["Gold when defeated", str(bounty)]),
	]
	_page.add_child(_rows(rows))


func _rows(rows: Array[PackedStringArray]) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	for row: PackedStringArray in rows:
		box.add_child(StatRow.pair(row[0], row[1]))
	return box
