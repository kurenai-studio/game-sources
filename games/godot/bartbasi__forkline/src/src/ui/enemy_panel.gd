# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EnemyPanel
extends BattlePanel
## The panel for a tapped creature (RULES 9.4): health now and at most, armor,
## speed now and base, whether it walks or flies, its one line (the special rule),
## the lives it costs, the gold it pays, and its status. It reads the Battle
## every refresh and updates in place, so a tap on Close is never lost to a rebuild.
## When the creature is gone it says so and announces `gone` once.

## The creature left the map (defeated, or through the gate).
signal gone(enemy_id: int)

var enemy_id: int = -1
var type_id: StringName = &""

var name_label: Label
var move_label: Label
var health_bar: HealthBar
var health_label: Label
var armor_row: StatRow
var speed_row: StatRow
var lives_row: StatRow
var bounty_row: StatRow
var heal_row: StatRow
var info_label: Label
var status_box: VBoxContainer
var picture: GlyphIcon

var _open: bool = false
var _gone_sent: bool = false


func _init() -> void:
	super()
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 16)
	picture = GlyphIcon.new(128.0)
	header.add_child(picture)
	var names: VBoxContainer = VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override(&"separation", 0)
	name_label = UiKit.heading("")
	names.add_child(name_label)
	move_label = UiKit.label("", &"SoftLabel")
	names.add_child(move_label)
	header.add_child(names)
	var close_it: TapButton = UiKit.icon_button(&"close")
	close_it.tapped.connect(close)
	header.add_child(close_it)
	column.add_child(header)
	health_bar = HealthBar.new()
	column.add_child(health_bar)
	health_label = UiKit.label("", &"Label")
	health_label.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
	column.add_child(health_label)
	armor_row = StatRow.pair("Armor", "0")
	speed_row = StatRow.pair("Speed", "")
	lives_row = StatRow.pair("Lives lost", "1")
	bounty_row = StatRow.pair("Gold when defeated", "5")
	heal_row = StatRow.pair("Heals nearby", "")
	for row: StatRow in [armor_row, speed_row, lives_row, bounty_row, heal_row]:
		column.add_child(row)
	info_label = UiKit.label("", &"SoftLabel")
	column.add_child(info_label)
	status_box = VBoxContainer.new()
	status_box.add_theme_constant_override(&"separation", 4)
	column.add_child(status_box)
	column.add_child(feedback_box)


## Opens the panel on the creature with this id.
func show_enemy(id: int) -> void:
	enemy_id = id
	_open = true
	_gone_sent = false
	type_id = &""
	var enemy: EnemyState = battle.enemy_with_id(id) if battle != null else null
	if enemy != null:
		type_id = enemy.type
		var type: EnemyType = battle.catalog.enemy(enemy.type)
		picture.show_enemy(enemy.type)
		name_label.text = type.name
		move_label.text = "Flies" if type.flying else "Walks"
		info_label.text = type.info
		heal_row.visible = type.heal > 0
	refresh()


func is_open() -> bool:
	return _open


func close() -> void:
	if not _open:
		return
	_open = false
	closed.emit()


func refresh() -> void:
	if battle == null or not _open:
		return
	var numbers: Dictionary = battle.enemy_numbers(enemy_id)
	if numbers.is_empty():
		_show_gone()
		return
	var type: EnemyType = battle.catalog.enemy(type_id)
	health_bar.set_values(int(numbers["health"]), int(numbers["max_health"]))
	health_label.text = "Health %d / %d" % [int(numbers["health"]), int(numbers["max_health"])]
	armor_row.value_label.text = str(int(numbers["armor"]))
	var now: int = int(numbers["speed"])
	var base: int = int(numbers["base_speed"])
	var speed_text: String = "%s tiles/s" % BattleText.speed(now)
	if now != base:
		speed_text += " (base %s)" % BattleText.speed(base)
	speed_row.value_label.text = speed_text
	lives_row.value_label.text = str(int(numbers["lives"]))
	bounty_row.value_label.text = str(int(numbers["bounty"]))
	if type.heal > 0:
		heal_row.value_label.text = "%d every %s s" % [int(numbers["heal"]), BattleText.seconds(type.heal_ms)]
	_set_status(BattleText.status_lines(numbers, _more()))


## What the numbers leave out: the time left dug under, and the max health a grower began with.
func _more() -> Dictionary:
	var enemy: EnemyState = battle.enemy_with_id(enemy_id)
	if enemy == null:
		return {}
	var type: EnemyType = battle.catalog.enemy(type_id)
	return {
		"dig_ms": enemy.dig_ticks * Sim.MS_PER_TICK,
		"grown_from": enemy.start_health if type.grow_pct > 0 else 0,
	}


func _show_gone() -> void:
	health_bar.set_values(0, 1)
	health_label.text = "Gone from the map."
	_set_status(PackedStringArray())
	if not _gone_sent:
		_gone_sent = true
		gone.emit(enemy_id)


## Status lines are labels reused in place; extra ones are hidden.
func _set_status(lines: PackedStringArray) -> void:
	while status_box.get_child_count() < lines.size():
		status_box.add_child(UiKit.label("", &"Label"))
	for i: int in status_box.get_child_count():
		var l: Label = status_box.get_child(i) as Label
		l.visible = i < lines.size()
		if i < lines.size():
			l.text = lines[i]
