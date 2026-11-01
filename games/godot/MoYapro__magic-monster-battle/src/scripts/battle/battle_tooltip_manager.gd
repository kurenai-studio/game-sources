class_name BattleTooltipManager extends Node

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const TOOLTIP_DELAY := 1.0

var _mage_displays: Array[MageDisplay] = []
var _enemy_grid: EnemyGrid = null
var _wand_displays: Array[WandDisplay] = []

var _current_state: BattleState = null
var _current_setup: BattleSetup = null

# monster tooltip
var _hover_enemy: EnemyData = null
var _hover_timer: float = 0.0
var _enemy_cursor_pos: Vector2 = Vector2.ZERO
var _monster_tooltip_layer: CanvasLayer = null
var _monster_tooltip_panel: PanelContainer = null
var _monster_tooltip_name: Label = null
var _monster_tooltip_desc: Label = null
var _monster_tooltip_stats: Label = null
var _monster_tooltip_statuses: RichTextLabel = null
var _monster_tooltip_traits: Label = null
var _monster_tooltip_attacks: Label = null

# mage tooltip
var _hover_mage_idx: int = -1
var _mage_cursor_pos: Vector2 = Vector2.ZERO
var _mage_hover_timer: float = 0.0
var _mage_tooltip_layer: CanvasLayer = null
var _mage_tooltip_panel: PanelContainer = null
var _mage_tooltip_name: Label = null
var _mage_tooltip_stats: Label = null
var _mage_tooltip_statuses: RichTextLabel = null

# spell tooltip
var _spell_tooltip: SpellTooltip = null


func setup(parent: Node, mage_displays: Array[MageDisplay], enemy_grid: EnemyGrid, wand_displays: Array[WandDisplay]) -> void:
	_mage_displays = mage_displays
	_enemy_grid = enemy_grid
	_wand_displays = wand_displays
	_build_monster_tooltip(parent)
	_build_mage_tooltip(parent)
	_spell_tooltip = SpellTooltip.new()
	parent.add_child(_spell_tooltip)


func update(pos: Vector2, state: BattleState, setup: BattleSetup) -> void:
	_current_state = state
	_current_setup = setup
	_update_enemy_hover(pos)
	_update_mage_hover(pos)
	_update_spell_hover(pos)


func _process(delta: float) -> void:
	if _current_state == null or _current_setup == null:
		return
	if _hover_enemy != null and not _monster_tooltip_layer.visible:
		_hover_timer += delta
		if _hover_timer >= TOOLTIP_DELAY:
			_show_monster_tooltip(_hover_enemy, _enemy_cursor_pos)
	if _hover_mage_idx >= 0 and not _mage_tooltip_layer.visible:
		_mage_hover_timer += delta
		if _mage_hover_timer >= TOOLTIP_DELAY:
			_show_mage_tooltip(_hover_mage_idx, _mage_cursor_pos)


func _update_enemy_hover(pos: Vector2) -> void:
	_enemy_cursor_pos = pos
	var cell := _enemy_grid.get_cell_at(_enemy_grid.to_local(pos))
	var enemy: EnemyData = null
	if cell.x >= 0:
		enemy = _enemy_grid.get_enemy_at(cell)
	if enemy != _hover_enemy:
		_hover_enemy = enemy
		_hover_timer = 0.0
		_monster_tooltip_layer.visible = false


func _update_mage_hover(pos: Vector2) -> void:
	_mage_cursor_pos = pos
	var idx := -1
	for i in _mage_displays.size():
		var mage: MageDisplay = _mage_displays[i]
		if mage.get_rect().has_point(mage.to_local(pos)):
			idx = i
			break
	if idx != _hover_mage_idx:
		_hover_mage_idx = idx
		_mage_hover_timer = 0.0
		_mage_tooltip_layer.visible = false


func _update_spell_hover(pos: Vector2) -> void:
	var spell: SpellData = null
	for wd: WandDisplay in _wand_displays:
		var slot := wd.get_slot_at(wd.to_local(pos))
		if slot != null and slot.spell != null:
			spell = slot.spell
			break
	_spell_tooltip.notify_hover(pos, spell)


func _show_mage_tooltip(idx: int, pos: Vector2) -> void:
	var mage := _current_setup.mages[idx]
	var ms := _current_state.mages[idx] as MageState
	_mage_tooltip_name.text = mage.name
	var stats_lines: Array[String] = ["HP: %d / %d" % [ms.combatant.hp, mage.max_hp]]
	if ms.combatant.shield > 0:
		stats_lines.append("Shield: %d" % ms.combatant.shield)
	_mage_tooltip_stats.text = "\n".join(stats_lines)
	var active_statuses: Array = (ms.combatant.statuses as Array).filter(
			func(s: StatusData) -> bool: return s.display_name != "")
	if not active_statuses.is_empty():
		_mage_tooltip_statuses.text = _format_statuses_bbcode(active_statuses)
		_mage_tooltip_statuses.visible = true
	else:
		_mage_tooltip_statuses.visible = false
	var tp := pos + Vector2(18.0, 18.0)
	tp.x = clampf(tp.x, 0.0, SCREEN_W - 200.0)
	tp.y = clampf(tp.y, 0.0, SCREEN_H - 120.0)
	_mage_tooltip_panel.position = tp
	_mage_tooltip_layer.visible = true


func _show_monster_tooltip(enemy: EnemyData, pos: Vector2) -> void:
	_monster_tooltip_name.text = enemy.display_name
	_monster_tooltip_desc.text = enemy.description
	_monster_tooltip_desc.visible = not enemy.description.is_empty()
	var stats_lines: Array[String] = ["HP: %d / %d" % [enemy.current_hp, enemy.max_hp]]
	if _current_state.enemies.has(enemy.id):
		var es := _current_state.enemies[enemy.id] as EnemyState
		if es.armor > 0:
			stats_lines.append("🛡 Armor: %d" % es.armor)
		if es.combatant.shield > 0:
			stats_lines.append("◇ Shield: %d" % es.combatant.shield)
		if es.block > 0:
			stats_lines.append("🔲 Block: %d" % es.block)
	stats_lines.append_array(_get_ground_labels_for_enemy(enemy))
	_monster_tooltip_stats.text = "\n".join(stats_lines)
	var active_statuses: Array = []
	if _current_state.enemies.has(enemy.id):
		active_statuses = ((_current_state.enemies[enemy.id] as EnemyState).combatant.statuses as Array).filter(
				func(s: StatusData) -> bool: return s.display_name != "")
	if not active_statuses.is_empty():
		_monster_tooltip_statuses.text = _format_statuses_bbcode(active_statuses)
		_monster_tooltip_statuses.visible = true
	else:
		_monster_tooltip_statuses.visible = false
	if not enemy.traits.is_empty():
		var labels: Array = enemy.traits.map(func(t: MonsterTraitData) -> String: return t.label)
		_monster_tooltip_traits.text = "Traits: " + ", ".join(labels)
		_monster_tooltip_traits.visible = true
	else:
		_monster_tooltip_traits.visible = false
	if not enemy.action_pool.is_empty():
		var lines: Array = enemy.action_pool.map(
				func(a: MonsterActionData) -> String: return _format_action(a))
		_monster_tooltip_attacks.text = "\n".join(lines)
		_monster_tooltip_attacks.visible = true
	else:
		_monster_tooltip_attacks.visible = false
	var tp := pos + Vector2(18.0, 18.0)
	tp.x = clampf(tp.x, 0.0, SCREEN_W - 260.0)
	tp.y = clampf(tp.y, 0.0, SCREEN_H - 240.0)
	_monster_tooltip_panel.position = tp
	_monster_tooltip_layer.visible = true


func _get_ground_labels_for_enemy(enemy: EnemyData) -> Array[String]:
	var idx := _current_setup.enemies.find(enemy)
	if idx < 0:
		return []
	var grid_pos := _current_setup.get_enemy_pos(idx, _current_state)
	var cells := EnemyGrid.get_cells_for_enemy(grid_pos, enemy.grid_size)
	var puddles := cells.filter(
		func(c: Vector2i) -> bool:
			return _current_state.get_cell(c).ground == GroundType.Type.PUDDLE)
	var labels: Array[String] = []
	if puddles.size() > 0:
		labels.append("Puddle (%d cells) — Wet +%d/round" % [puddles.size(), puddles.size() * 2])
	return labels


func _format_action(action: MonsterActionData) -> String:
	if action is MonsterActionAttack:
		var atk := action as MonsterActionAttack
		var parts: Array[String] = ["%s  %d dmg" % [atk.name, atk.damage]]
		if atk.wet_stacks > 0:
			parts.append("Wet %d" % atk.wet_stacks)
		if atk.applies_frozen:
			parts.append("Freeze")
		if atk.applies_web:
			parts.append("Web")
		return "  ".join(parts)
	if action is MonsterActionHeal:
		return "%s  heals %d (lowest HP ally)" % [action.name, (action as MonsterActionHeal).amount]
	if action is MonsterActionDrumsOfWar:
		return "Drums of War  ×2 attack for adjacent allies"
	if action is MonsterActionVineSnare:
		return "Vine Snare  blocks attack; breaking costs 50% HP (heals caster)"
	if action is MonsterActionLeech:
		return "Leech  each mana you spend heals caster by 1"
	return action.name


func _format_statuses_bbcode(statuses: Array) -> String:
	var lines: Array[String] = []
	for status: StatusData in statuses:
		var hex := status.display_color.to_html(false)
		lines.append("[color=#%s]%s[/color] %s" % [hex, status.icon, status.get_label()])
	return "\n".join(lines)


func _build_monster_tooltip(parent: Node) -> void:
	_monster_tooltip_layer = CanvasLayer.new()
	_monster_tooltip_layer.layer = 10
	_monster_tooltip_layer.visible = false
	parent.add_child(_monster_tooltip_layer)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.COLOR_TOOLTIP_BG
	style.border_color = Palette.COLOR_TOOLTIP_BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	_monster_tooltip_panel = PanelContainer.new()
	_monster_tooltip_panel.custom_minimum_size = Vector2(240, 0)
	_monster_tooltip_panel.add_theme_stylebox_override("panel", style)
	_monster_tooltip_layer.add_child(_monster_tooltip_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_monster_tooltip_panel.add_child(vbox)
	_monster_tooltip_name = Label.new()
	_monster_tooltip_name.add_theme_font_size_override("font_size", 14)
	_monster_tooltip_name.modulate = Palette.COLOR_TOOLTIP_NAME
	vbox.add_child(_monster_tooltip_name)
	_monster_tooltip_desc = Label.new()
	_monster_tooltip_desc.add_theme_font_size_override("font_size", 11)
	_monster_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_monster_tooltip_desc.modulate = Palette.COLOR_TOOLTIP_BODY
	vbox.add_child(_monster_tooltip_desc)
	vbox.add_child(HSeparator.new())
	_monster_tooltip_stats = Label.new()
	_monster_tooltip_stats.add_theme_font_size_override("font_size", 11)
	_monster_tooltip_stats.modulate = Palette.COLOR_TOOLTIP_STATS
	vbox.add_child(_monster_tooltip_stats)
	_monster_tooltip_statuses = RichTextLabel.new()
	_monster_tooltip_statuses.bbcode_enabled = true
	_monster_tooltip_statuses.fit_content = true
	_monster_tooltip_statuses.scroll_active = false
	_monster_tooltip_statuses.add_theme_font_size_override("normal_font_size", 11)
	vbox.add_child(_monster_tooltip_statuses)
	_monster_tooltip_traits = Label.new()
	_monster_tooltip_traits.add_theme_font_size_override("font_size", 11)
	_monster_tooltip_traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_monster_tooltip_traits.modulate = Palette.COLOR_TOOLTIP_BODY
	vbox.add_child(_monster_tooltip_traits)
	vbox.add_child(HSeparator.new())
	var attacks_header := Label.new()
	attacks_header.text = "Attacks"
	attacks_header.add_theme_font_size_override("font_size", 11)
	attacks_header.modulate = Palette.COLOR_TOOLTIP_SECTION
	vbox.add_child(attacks_header)
	_monster_tooltip_attacks = Label.new()
	_monster_tooltip_attacks.add_theme_font_size_override("font_size", 11)
	_monster_tooltip_attacks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_monster_tooltip_attacks.modulate = Palette.COLOR_TOOLTIP_STATS
	vbox.add_child(_monster_tooltip_attacks)


func _build_mage_tooltip(parent: Node) -> void:
	_mage_tooltip_layer = CanvasLayer.new()
	_mage_tooltip_layer.layer = 10
	_mage_tooltip_layer.visible = false
	parent.add_child(_mage_tooltip_layer)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.COLOR_TOOLTIP_BG
	style.border_color = Palette.COLOR_TOOLTIP_BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	_mage_tooltip_panel = PanelContainer.new()
	_mage_tooltip_panel.custom_minimum_size = Vector2(180, 0)
	_mage_tooltip_panel.add_theme_stylebox_override("panel", style)
	_mage_tooltip_layer.add_child(_mage_tooltip_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_mage_tooltip_panel.add_child(vbox)
	_mage_tooltip_name = Label.new()
	_mage_tooltip_name.add_theme_font_size_override("font_size", 14)
	_mage_tooltip_name.modulate = Palette.COLOR_TOOLTIP_NAME
	vbox.add_child(_mage_tooltip_name)
	vbox.add_child(HSeparator.new())
	_mage_tooltip_stats = Label.new()
	_mage_tooltip_stats.add_theme_font_size_override("font_size", 11)
	_mage_tooltip_stats.modulate = Palette.COLOR_TOOLTIP_STATS
	vbox.add_child(_mage_tooltip_stats)
	_mage_tooltip_statuses = RichTextLabel.new()
	_mage_tooltip_statuses.bbcode_enabled = true
	_mage_tooltip_statuses.fit_content = true
	_mage_tooltip_statuses.scroll_active = false
	_mage_tooltip_statuses.add_theme_font_size_override("normal_font_size", 11)
	vbox.add_child(_mage_tooltip_statuses)
