class_name HUD
extends CanvasLayer
## Interface em jogo estilo Diablo 3: globos, barra de habilidades, XP, alvo, minimapa e painéis.

## Preloads para type hints funcionarem em parse time
const Hero := preload("res://scripts/core/hero.gd")
const VitalsBar := preload("res://scripts/ui/vitals_bar.gd")
const LevelBadge := preload("res://scripts/ui/level_badge.gd")
const SkillSlot := preload("res://scripts/ui/skill_slot.gd")
const InventoryPanel := preload("res://scripts/ui/inventory_panel.gd")
const CharacterPanel := preload("res://scripts/ui/character_panel.gd")
const SkillsPanel := preload("res://scripts/ui/skills_panel.gd")
const QuestPanel := preload("res://scripts/ui/quest_panel.gd")
const UnifiedPanel := preload("res://scripts/ui/unified_panel.gd")
const ClockChip := preload("res://scripts/ui/clock_chip.gd")
const DialogueBox := preload("res://scripts/ui/dialogue_box.gd")
const TradePanel := preload("res://scripts/ui/trade_panel.gd")
const SkillTreePanel := preload("res://scripts/ui/skill_tree_panel.gd")
# World e Player não são preloadados aqui para evitar dependências circulares

const ORB_SHADER := preload("res://shaders/orb.gdshader")
const ConsumableSlotScript := preload("res://scripts/ui/consumable_slot.gd")

var world: World
var player: Player
var hero: Hero

var _root: Control
## Fase 6.1: barras segmentadas (MECANICAS #9.2) no lugar dos orbes
var _hp_bar: VitalsBar
var _res_bar: VitalsBar
var _badge: LevelBadge
var _slots: Array[SkillSlot] = []
var _potion_slot: SkillSlot
var _heal_slot: SkillSlot
var _consumable_slots: Array = []
var _gold_chip: PanelContainer
var _essence_chip: PanelContainer
var _gold: Label
var _essence: Label
var _target_box: PanelContainer
var _target_name: Label
var _target_affixes: Label
var _target_bar: ProgressBar
var _target_fill: StyleBoxFlat
var _location: Label
var _messages: VBoxContainer
var _buff_row: HBoxContainer
var _hover_label: Label
var _vignette: ColorRect
var _held_icon: TextureRect
var _points_hint: Button
## Fase 6.4: letra -> botão da barra inferior (destaque de onboarding)
var _bar_buttons: Dictionary = {}
## Fase 4.2: tracker lateral de quest (minimapa acima); Fase 6.1: recolhível
var _quest_tracker: PanelContainer
var _quest_title: Button
var _quest_obj: Label
var _quest_body: VBoxContainer
var _tracker_collapsed := false

var inventory: InventoryPanel
var character: CharacterPanel
var skills: SkillsPanel
var questlog: QuestPanel
var skill_tree: SkillTreePanel
## Fase 6.2: janela unificada (abas Personagem/Inventário/Habilidades/Missões)
var _unified: UnifiedPanel
## Fase 7.1: chip de relógio HH:MM + arco do dia (MECANICAS #14.1)
var _clock: ClockChip
var _pause_layer: Control
var _death_layer: Control
var _popup: Control
var _dialogue_box: DialogueBox


func setup(p_world: World, p_player: Player) -> void:
	world = p_world
	player = p_player
	hero = p_player.hero
	_build()


func _build() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.color = Color(0.6, 0, 0, 0)
	_root.add_child(_vignette)

	_build_bottom_bar()
	_build_top()
	# Fase 5.5: o diálogo do líder pode liberar a negociação (efeito `comercio`)
	if not Game.trade_requested.is_connected(_on_trade_requested):
		Game.trade_requested.connect(_on_trade_requested)

	_messages = VBoxContainer.new()
	_messages.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_messages.position = Vector2(-300, 120)
	_messages.custom_minimum_size = Vector2(600, 0)
	_messages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_messages.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_child(_messages)

	_hover_label = UIKit.label("", 18, Color.WHITE, true)
	_hover_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hover_label.add_theme_constant_override("outline_size", 5)
	_hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hover_label)

	inventory = InventoryPanel.new()
	inventory.setup(self, hero)
	character = CharacterPanel.new()
	character.setup(self, hero)
	skills = SkillsPanel.new()
	skills.setup(self, hero)
	# Fase 4.2: diário de missões + tracker lateral
	questlog = QuestPanel.new()
	questlog.setup(self)
# Fase 10.4: painel da árvore de habilidades
	skill_tree = SkillTreePanel.new()
	skill_tree.setup(self, hero)
	# Fase 6.2: painel unificado - os painéis viram abas da mesma janela
	_unified = UnifiedPanel.new()
	_root.add_child(_unified)
	_unified.add_page("Personagem", character)
	_unified.add_page("Inventário", inventory)
	_unified.add_page("Habilidades", skills)
	_unified.add_page("Arvore", skill_tree)
	_unified.add_page("Missões", questlog)
	_setup_quest_tracker()
	Game.quest_log.quest_started.connect(_on_quest_started)
	Game.quest_log.quest_completed.connect(_on_quest_completed)

	_held_icon = TextureRect.new()
	_held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_icon.custom_minimum_size = Vector2(40, 40)
	_held_icon.size = Vector2(40, 40)
	_held_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_held_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_held_icon.z_index = 90
	_root.add_child(_held_icon)

	get_viewport().size_changed.connect(_layout)
	_layout()


func _build_bottom_bar() -> void:
	var bar := PanelContainer.new()
	bar.name = "BottomBar"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -100
	bar.add_theme_stylebox_override("panel", UIKit.box(Color(0.05, 0.035, 0.03, 0.92), UIKit.GOLD_DIM, 2, 6))
	_root.add_child(bar)
	var v := VBoxContainer.new()
	bar.add_child(v)

	_buff_row = HBoxContainer.new()
	_buff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_buff_row.custom_minimum_size.y = 0
	v.add_child(_buff_row)

	# Linha principal: consumíveis (1-9) + cura simples (Q) + vida/recurso + skills + raciais + painéis
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)

	# Barra de consumíveis 1-9
	_consumable_slots = []
	for i in 9:
		var slot_idx: int = i  # 0-8 para slots 1-9
		var key_name: String = Game.key_name("consumable_%d" % (i + 1))
		var cs := ConsumableSlotScript.new(slot_idx, key_name)
		cs.player = player
		cs.used.connect(func(s: int): player._use_consumable_slot(s))
		_consumable_slots.append(cs)
		h.add_child(cs)

	# Conecta refresh dos slots de consumíveis quando inventário muda
	hero.inventory.changed.connect(func():
		for i in _consumable_slots.size():
			_consumable_slots[i].queue_redraw()
	)

	h.add_child(_spacer(8))

	# Cura simples (Q) - sempre disponível
	_heal_slot = SkillSlot.new(-2, Game.key_name("heal"))
	_heal_slot.is_potion = true
	_heal_slot.player = player
	_heal_slot.clicked.connect(func(_s): player._use_simple_heal())
	h.add_child(_heal_slot)
	h.add_child(_spacer(8))

	# Fase 6.1: barras segmentadas de vida/recurso (MECANICAS #9.2)
	var vitals := VBoxContainer.new()
	vitals.add_theme_constant_override("separation", 4)
	h.add_child(vitals)
	_hp_bar = VitalsBar.new(Color(0.8, 0.08, 0.08))
	_hp_bar.custom_minimum_size = Vector2(230, 22)
	_hp_bar.tooltip_text = "Vida"
	vitals.add_child(_hp_bar)
	_res_bar = VitalsBar.new(hero.cls.resource_color)
	_res_bar.custom_minimum_size = Vector2(230, 16)
	_res_bar.tooltip_text = hero.cls.resource_label
	vitals.add_child(_res_bar)
	h.add_child(_spacer(10))

	# Skills: Ataque básico (LMB), Ataque pesado (RMB), Skills 1-4 (Z, X, C, V)
	var keys: Array = ["LMB", "RMB", Game.key_name("skill_1"), Game.key_name("skill_2"), Game.key_name("skill_3"), Game.key_name("skill_4")]
	for i in 6:
		var s := SkillSlot.new(i, keys[i])
		s.player = player
		s.clicked.connect(func(_s): toggle_skills())
		_slots.append(s)
		h.add_child(s)
	if hero.racial_skill():
		var rs := SkillSlot.new(Player.RACIAL_SLOT, Game.key_name("racial"))
		rs.player = player
		h.add_child(_spacer(6))
		h.add_child(rs)
	h.add_child(_spacer(10))

	# Botões de painéis: I (Inventário), P (Personagem), K (Habilidades), J (Missões), ≡ (Menu)
	for b in [["I", toggle_inventory, "Inventário (I)"], ["P", toggle_character, "Personagem (P)"], ["K", toggle_skills, "Habilidades (K)"], ["J", toggle_quests, "Missões (J)"], ["≡", toggle_pause, "Menu (Esc)"]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.tooltip_text = b[2]
		btn.custom_minimum_size = Vector2(34, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(b[1])
		_bar_buttons[b[0]] = btn
		h.add_child(btn)
	h.add_child(_spacer(8))

	# Fase 6.1: emblema de nível com anel de XP (MECANICAS #9.2)
	_badge = LevelBadge.new()
	_badge.tooltip_text = "Nível e experiência"
	h.add_child(_badge)

	_points_hint = Button.new()
	_points_hint.text = "+ Pontos de atributo"
	_points_hint.focus_mode = Control.FOCUS_NONE
	_points_hint.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	_points_hint.pressed.connect(toggle_character)
	_root.add_child(_points_hint)


func _spacer(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _refresh_consumable_slot(slot: int) -> void:
	if slot >= 0 and slot < _consumable_slots.size():
		_consumable_slots[slot].queue_redraw()


func _flash_consumable_slot(slot: int) -> void:
	if slot >= 0 and slot < _consumable_slots.size():
		_consumable_slots[slot].flash()


func _build_top() -> void:
	_target_box = PanelContainer.new()
	_target_box.add_theme_stylebox_override("panel", UIKit.box(Color(0.03, 0.02, 0.02, 0.85), UIKit.GOLD_DIM, 1, 3))
	_target_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_box.custom_minimum_size = Vector2(380, 0)
	_root.add_child(_target_box)
	var tv := VBoxContainer.new()
	_target_box.add_child(tv)
	_target_name = UIKit.label("", 17, Color.WHITE, true)
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(_target_name)
	_target_affixes = UIKit.label("", 13, Color(1.0, 0.82, 0.45), true)
	_target_affixes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_affixes.add_theme_color_override("font_outline_color", Color.BLACK)
	_target_affixes.add_theme_constant_override("outline_size", 3)
	tv.add_child(_target_affixes)
	_target_bar = ProgressBar.new()
	_target_bar.show_percentage = false
	_target_bar.custom_minimum_size = Vector2(0, 12)
	_target_bar.add_theme_stylebox_override("background", UIKit.box(Color(0.1, 0.02, 0.02), Color(0.3, 0.1, 0.1), 1, 2))
	# Fase 6.1: cor do preenchimento muda com a raridade do inimigo (#9.2)
	_target_fill = UIKit.box(Color(0.75, 0.08, 0.06), Color(0.75, 0.08, 0.06), 0, 2)
	_target_fill.content_margin_top = 0
	_target_fill.content_margin_bottom = 0
	_target_bar.add_theme_stylebox_override("fill", _target_fill)
	tv.add_child(_target_bar)
	_target_box.visible = false

	var info := VBoxContainer.new()
	info.position = Vector2(16, 12)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(info)
	_location = UIKit.label("", 18, UIKit.GOLD, true)
	_location.add_theme_color_override("font_outline_color", Color.BLACK)
	_location.add_theme_constant_override("outline_size", 4)
	info.add_child(_location)
	# Fase 6.1: chips de moeda (MECANICAS #9.2) - pílulas escuras com borda
	_gold_chip = _make_chip(Color(1, 0.85, 0.3), Color(0.16, 0.12, 0.05))
	_gold = _chip_label(_gold_chip)
	_essence_chip = _make_chip(Color(0.75, 0.55, 1.0), Color(0.10, 0.08, 0.16))
	_essence = _chip_label(_essence_chip)

	var mm := Minimap.new(world)
	mm.name = "Minimap"
	_root.add_child(mm)
	# Fase 7.1: chip de relógio sob o minimapa - HH:MM de Eldara + arco do dia
	_clock = ClockChip.new()
	_clock.name = "ClockChip"
	_root.add_child(_clock)


func _make_chip(border: Color, bg: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", UIKit.box(bg, border, 1, 10))
	chip.add_theme_constant_override("separation", 0)
	return chip


func _chip_label(chip: PanelContainer) -> Label:
	var l := UIKit.label("", 15, Color.WHITE, true)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	chip.add_child(l)
	return l


func _layout() -> void:
	var vs := _root.get_viewport_rect().size
	var bar: Control = _root.get_node("BottomBar")
	bar.reset_size()
	bar.position = Vector2((vs.x - bar.size.x) * 0.5, vs.y - bar.size.y - 6)
	_points_hint.position = Vector2(bar.position.x, bar.position.y - 40)
	_target_box.reset_size()
	_target_box.position = Vector2((vs.x - _target_box.size.x) * 0.5, 12)
	var mm: Control = _root.get_node("Minimap")
	mm.position = Vector2(vs.x - 190 - 14, 14)
	mm.modulate.a = float(Game.settings.minimap_opacity)
	mm.visible = mm.modulate.a > 0.01
	mm.size = Vector2(190, 190)
	# Fase 7.1: relógio colado sob o minimapa (#14.1)
	_clock.reset_size()
	_clock.position = Vector2(vs.x - _clock.size.x - 14, 14 + 190 + 8)
	_messages.position = Vector2(vs.x * 0.5 - 300, vs.y * 0.22)
	# Fase 6.1: chips de moeda no canto inferior esquerdo (#9.2)
	_gold_chip.reset_size()
	_gold_chip.position = Vector2(14, vs.y - _gold_chip.size.y - 14)
	_essence_chip.reset_size()
	_essence_chip.position = Vector2(14, _gold_chip.position.y - _essence_chip.size.y - 4)
	_quest_tracker.reset_size()
	_quest_tracker.position = Vector2(vs.x - _quest_tracker.size.x - 14, 216)
	# Fase 6.2: janela unificada centralizada
	_unified.reset_size()
	_unified.position = (vs - _unified.size) * 0.5


# ------------------------------------------------------------------ LOOP

func _process(delta: float) -> void:
	if player == null:
		return
	# Fase 6.1: barras segmentadas + emblema com anel de XP (#9.2)
	_hp_bar.value = clampf(player.hp / player.max_hp, 0, 1)
	_hp_bar.text = "%d" % ceili(player.hp)
	if hero.cls.costs_life:
		_res_bar.value = clampf(player.hp / player.max_hp, 0, 1)
		_res_bar.text = "Pacto"
	else:
		_res_bar.value = clampf(player.resource / player.max_resource, 0, 1)
		_res_bar.text = "%d" % player.resource
	_badge.set_progress(hero.level, hero.xp, hero.xp_to_next())
	_badge.tooltip_text = "Nível %d  -  %d / %d XP" % [hero.level, hero.xp, hero.xp_to_next()]
	_location.text = world.region_name()
	_gold.text = "● %d" % hero.gold
	_essence.text = "◆ %d" % hero.essence
	# Fase 7.1: o chip de relógio assume o HH:MM (#14.1) - Game.world_time
	# é a fonte da verdade; em masmorra congela no valor salvo
	_clock.set_time(fmod(Game.world_time, 1.0))
	if _popup and is_instance_valid(_popup) and world.player.global_position.distance_to(_popup.get_meta("anchor")) > 40.0:
		close_popup()
	_points_hint.visible = hero.unspent_points > 0 and not character.visible
	_vignette.color.a = maxf(_vignette.color.a - delta * 1.5, 0.0)
	if player.hp / player.max_hp < 0.3 and not player.is_dead():
		_vignette.color.a = maxf(_vignette.color.a, 0.08 + sin(Time.get_ticks_msec() * 0.006) * 0.05)

	_update_target()
	_update_buffs()
	# Containers crescem mas não encolhem sozinhos: reajusta a janela unificada
	if _unified.is_open() and not _unified.size.is_equal_approx(_unified.get_combined_minimum_size()):
		_layout()
	if inventory.held:
		_held_icon.visible = true
		_held_icon.texture = DB.icon(inventory.held.icon)
		_held_icon.size = Vector2(inventory.held.size) * InventoryPanel.CELL
		_held_icon.position = _root.get_local_mouse_position() - _held_icon.size * 0.5
	else:
		_held_icon.visible = false

	# Atalhos de painéis
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	if Input.is_action_just_pressed("character"):
		toggle_character()
	if Input.is_action_just_pressed("skills"):
		toggle_skills()
	if Input.is_action_just_pressed("skill_tree"):
		toggle_skill_tree()
	if Input.is_action_just_pressed("quests"):
		toggle_quests()
	_update_quest_tracker()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _popup and is_instance_valid(_popup):
			close_popup()
			get_viewport().set_input_as_handled()
			return
		if _unified.is_open():
			# 6.2/6.5: ESC fecha a janela unificada inteira (com pop_out),
			# devolvendo item segurado pela aba Inventário
			if _unified.current == 1 and inventory.held:
				if not hero.inventory.add(inventory.held):
					inventory.drop_held_to_world()
				inventory.held = null
			inventory.hide_tooltip()
			_unified.close()
			Sfx.play(&"ui_close")
		elif _death_layer == null:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	# Soltar item segurado no chão
	if inventory.held and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inventory.drop_held_to_world()
		get_viewport().set_input_as_handled()


## Preenche o painel do alvo (nome, cor da raridade, afixos e barra).
## 3.4: extraído de _update_target para ser testável e reutilizado pelo smoke.
func show_target(e: Enemy) -> void:
	_target_box.visible = true
	# Fase 6.1: coroa para campeão+ (#9.2 - "ornamento de coroa")
	var crown := "♛ " if e.rarity >= Enemy.Rarity.ELITE else ""
	_target_name.text = crown + e.display_name
	_target_name.add_theme_color_override("font_color", Color(1, 0.6, 0.2) if e.is_boss() else Enemy.RARITY_COLORS[e.rarity])
	_target_bar.max_value = e.max_hp
	_target_bar.value = e.hp
	# Fase 6.1: barra do inimigo colorida pela raridade (#9.2)
	var col: Color = Color(1, 0.6, 0.2) if e.is_boss() else Enemy.RARITY_COLORS[e.rarity]
	_target_fill.bg_color = col
	# 3.4: afixos do Campeão/Lendário sob o nome (REGRAS #6)
	var afx := e.affix_names()
	_target_affixes.visible = not afx.is_empty()
	if not afx.is_empty():
		_target_affixes.text = " - ".join(afx)


func _update_target() -> void:
	var mouse := world.get_global_mouse_position()
	var e := world.get_enemy_at(mouse)
	if e == null and world.boss and is_instance_valid(world.boss) and not world.boss.is_dead() and world.boss.state != Enemy.State.IDLE:
		e = world.boss
	if e:
		show_target(e)
	else:
		_target_box.visible = false
	# Rótulo de objetos interativos (duck-typed: Interactable OU Npc)
	var it := world.get_interactable_at(mouse)
	if it and it.has_method("display_name"):
		_hover_label.text = it.display_name()
		_hover_label.visible = true
		_hover_label.reset_size()
		_hover_label.position = _root.get_local_mouse_position() + Vector2(-_hover_label.size.x * 0.5, -36)
	else:
		_hover_label.visible = false


func _update_buffs() -> void:
	# Fase 6.1: strip de buffs como chips com anel de tempo restante (#9.2)
	var names := player.buffs.keys()
	while _buff_row.get_child_count() < names.size():
		var chip := BuffChip.new()
		_buff_row.add_child(chip)
	for i in _buff_row.get_child_count():
		var chip: BuffChip = _buff_row.get_child(i)
		if i < names.size():
			var b: Dictionary = player.buffs[names[i]]
			chip.visible = true
			chip.color = b.color
			chip.frac = float(b.time) / float(b.get("total", b.time))
			chip.label = str(ceili(b.time))
		else:
			chip.visible = false


# ------------------------------------------------------------------ API

func show_message(text: String, color: Color = Color.WHITE, time: float = 2.0) -> void:
	for c in _messages.get_children():
		if c is Label and c.text == text:
			return
	var l := UIKit.label(text, 22, color, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_messages.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(time)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
	while _messages.get_child_count() > 5:
		var first := _messages.get_child(0)
		_messages.remove_child(first)
		first.queue_free()


func flash_slot(slot: int) -> void:
	if slot >= 0 and slot < _slots.size():
		_slots[slot].flash()


func damage_vignette() -> void:
	_vignette.color.a = 0.22


## Fase 6.4: pulsa o controle da barra indicado - o onboarding aponta onde olhar (MECANICAS #9).
## Suporta: Q (cura simples), 1-9 (consumíveis), I/P/K/J (painéis), Z/X/C/V (skills)
func pulse_hint(key: String) -> void:
	var target: Control
	if key == "Q":
		target = _heal_slot
	elif key.begins_with("consumable_"):
		var idx: int = int(key.split("_")[1]) - 1
		if idx >= 0 and idx < _consumable_slots.size():
			target = _consumable_slots[idx]
	else:
		target = _bar_buttons.get(key)
	if target == null or not is_instance_valid(target):
		return
	var tw := create_tween().set_loops(5)
	tw.tween_property(target, "modulate", Color(1, 0.8, 0.3), 0.35)
	tw.tween_property(target, "modulate", Color.WHITE, 0.35)


## Fase 6.2: teclas I/P/K/B/J abrem o painel unificado na aba certa -
## abrir na mesma aba fecha, abrir em outra troca (MECANICAS #9.3)
func _toggle_unified(idx: int, on_open: Callable = Callable()) -> void:
	if _unified.is_open() and _unified.current == idx:
		if idx == 1 and inventory.held:
			# inventário fechando com item na mão
			if not hero.inventory.add(inventory.held):
				inventory.drop_held_to_world()
			inventory.held = null
		inventory.hide_tooltip()
		_unified.close()
		Sfx.play(&"ui_close")
	else:
		_unified.open_tab(idx)
		if on_open.is_valid():
			on_open.call()
		Sfx.play(&"ui_open")
	_layout()


func toggle_inventory() -> void:
	_toggle_unified(1)


func toggle_character() -> void:
	_toggle_unified(0)


func toggle_skills() -> void:
	_toggle_unified(2, skills.refresh)


## Fase 4.2: diário de missões (tecla J)
func toggle_quests() -> void:
	_toggle_unified(4, questlog.refresh)


## Fase 10.4: árvore de habilidades (tecla B)
func toggle_skill_tree() -> void:
	_toggle_unified(3, skill_tree.refresh)


## Tracker lateral: quest em destaque + objetivo atual (Fase 4.2)
func _setup_quest_tracker() -> void:
	_quest_tracker = PanelContainer.new()
	_quest_tracker.add_theme_stylebox_override("panel", UIKit.box(Color(0.03, 0.02, 0.02, 0.7), UIKit.GOLD_DIM, 1, 4))
	_quest_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_tracker.custom_minimum_size = Vector2(220, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_quest_tracker.add_child(v)
	# Fase 6.1: cabeçalho clicável recolhe o objetivo (#9.2)
	_quest_title = Button.new()
	_quest_title.flat = true
	_quest_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest_title.focus_mode = Control.FOCUS_NONE
	_quest_title.add_theme_font_override("font", UIKit.FONT_TITLE)
	_quest_title.add_theme_font_size_override("font_size", 15)
	_quest_title.add_theme_color_override("font_color", UIKit.GOLD)
	_quest_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_quest_title.add_theme_constant_override("outline_size", 3)
	_quest_title.pressed.connect(toggle_tracker)
	v.add_child(_quest_title)
	_quest_body = VBoxContainer.new()
	_quest_body.add_theme_constant_override("separation", 2)
	v.add_child(_quest_body)
	_quest_obj = UIKit.label("", 13, Color.WHITE)
	_quest_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_obj.add_theme_color_override("font_outline_color", Color.BLACK)
	_quest_obj.add_theme_constant_override("outline_size", 3)
	_quest_body.add_child(_quest_obj)
	_root.add_child(_quest_tracker)
	_quest_tracker.visible = false


## Fase 6.1: recolhe/expande o tracker de quests
func toggle_tracker() -> void:
	_tracker_collapsed = not _tracker_collapsed
	_quest_body.visible = not _tracker_collapsed


func _update_quest_tracker() -> void:
	var q := Game.quest_log.tracked_quest()
	if q == null:
		_quest_tracker.visible = false
		return
	_quest_tracker.visible = true
	_quest_title.text = "%s ✦ %s" % ["▸" if _tracker_collapsed else "▾", q.title]
	_quest_obj.text = Game.quest_log.tracker_line()


func _on_quest_started(id: StringName) -> void:
	var q: QuestData = DB.quest(id)
	if q != null:
		show_message("✦ Nova missão: %s" % q.title, UIKit.GOLD, 3.0)
	if questlog != null and is_instance_valid(questlog) and questlog.visible:
		questlog.refresh()


func _on_quest_completed(id: StringName) -> void:
	var q: QuestData = DB.quest(id)
	if q != null:
		show_message("✔ Missão concluída: %s" % q.title, Color(0.5, 1, 0.5), 3.5)
	if questlog != null and is_instance_valid(questlog) and questlog.visible:
		questlog.refresh()


# ------------------------------------------------------------------ JANELAS DO MUNDO

func close_popup() -> void:
	if _popup and is_instance_valid(_popup):
		# 6.5: fecha com pop_out e liberta quando a animação termina
		var p := _popup
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.pop_out(p, func():
			if is_instance_valid(p):
				p.queue_free()
		)
	_popup = null


## Abre um diálogo (NPC/Guia) - pausa o mundo enquanto a caixa estiver aberta
func open_dialogue(data: DialogueData, speaker_name: String = "") -> DialogueBox:
	if _dialogue_box and is_instance_valid(_dialogue_box):
		_dialogue_box.queue_free()
		_dialogue_box = null
	var box := DialogueBox.new()
	_root.add_child(box)
	box.closed.connect(func():
		if _dialogue_box == box:
			_dialogue_box = null
	)
	_dialogue_box = box
	box.open(data, speaker_name)
	return box


func _open_popup(title_text: String, width: float) -> VBoxContainer:
	close_popup()
	var w := UIKit.window_panel(title_text, Vector2(width, 0), close_popup)
	_popup = w.panel
	_popup.set_meta("anchor", world.player.global_position)
	_root.add_child(_popup)
	_popup.reset_size()
	var vs := _root.get_viewport_rect().size
	_popup.position = Vector2((vs.x - width) * 0.5, vs.y * 0.18)
	# 6.5: abre com pop (fade + back-ease); pivot central para escalar do meio
	_popup.pivot_offset = _popup.size * 0.5
	UIKit.pop_in(_popup)
	Sfx.play(&"ui_open")
	return w.body


## Fase 5.5: comércio unificado (Comprar/Vender/Leilão) - o diálogo do
## líder da capital abre via efeito `comercio` (Game.trade_requested)
func _on_trade_requested(p_race: StringName) -> void:
	open_trade(p_race)


func open_trade(p_race: StringName) -> TradePanel:
	if hero == null:
		return null
	close_popup()
	var t := TradePanel.new()
	_root.add_child(t)
	_popup = t
	t.set_meta("anchor", world.player.global_position)
	t.closed.connect(func():
		if _popup == t:
			_popup = null
	)
	t.open(p_race, maxi(hero.level, world.level()))
	return t


## Mercador: compra itens misteriosos (aposta estilo Diablo) e vende o lixo
func open_merchant() -> void:
	var body := _open_popup("Mercador Bartolomeu", 460)
	var info := UIKit.rich("[color=#bbbbbb]\"Itens embrulhados, aventureiro! Nunca se sabe o que tem dentro...\"[/color]")
	body.add_child(info)
	var gold_label := UIKit.label("", 18, Color(1, 0.85, 0.3), true)
	body.add_child(gold_label)
	var lvl := maxi(hero.level, world.level())
	var offers: Array = [
		["Arma misteriosa", "weapon", 60 + lvl * 25],
		["Armadura misteriosa", "armor", 50 + lvl * 20],
		["Joia misteriosa", "jewel", 80 + lvl * 30],
	]
	var refresh := func(): gold_label.text = "Seu ouro: %d" % hero.gold
	for o in offers:
		var b := UIKit.button("%s - %d ouro" % [o[0], o[2]], func():
			if hero.gold < o[2]:
				show_message("Ouro insuficiente", Color(1, 0.5, 0.4))
				return
			var it := _merchant_item(o[1], lvl)
			if not hero.inventory.add(it):
				show_message("Inventário cheio", Color(1, 0.5, 0.4))
				return
			hero.add_gold(-int(o[2]))
			Sfx.play(&"coins")
			show_message("Você recebeu: %s" % it.name, it.rarity_color(), 2.5)
			refresh.call()
		, 420)
		b.icon = DB.icon({"weapon": "W_Sword010", "armor": "A_Armour02", "jewel": "Ac_Necklace03"}[o[1]])
		body.add_child(b)
	body.add_child(UIKit.button("Vender todos os itens Comuns e Mágicos", func():
		inventory._sell_junk()
		refresh.call()
	, 420))
	body.add_child(UIKit.button("Fechar", close_popup, 420))
	refresh.call()


func _merchant_item(kind: String, lvl: int) -> Item:
	var bases: Array = []
	for k in DB.BASES:
		var b: Dictionary = DB.BASES[k]
		if k == &"wood_sword":
			continue
		match kind:
			"weapon":
				if b.slot == "weapon" and b.cat in hero.cls.allowed_weapons:
					bases.append(k)
			"armor":
				if b.slot in ["helm", "chest", "boots"] or (b.slot == "offhand" and b.cat in hero.cls.allowed_offhands):
					bases.append(k)
			"jewel":
				if b.slot in ["amulet", "ring"]:
					bases.append(k)
	if bases.is_empty():
		bases = [DB.random_base()]
	return DB.create_item(bases.pick_random(), maxi(1, lvl * 2 - 1), DB.roll_rarity(0.3))


## Viagem rápida entre fogueiras acesas (estilo waypoint do Diablo)
func open_waypoints() -> void:
	## Duck typing (evita ciclo world -> hud -> overworld -> world)
	if not world.has_method("travel_to"):
		return
	var body := _open_popup("Viagem Rápida", 420)
	body.add_child(UIKit.label("Fogueiras descobertas:", 15, UIKit.TEXT_DIM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, mini(Game.waypoints.size(), 6) * 46)
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for w in Game.waypoints:
		var pos: Vector2 = Vector2(w.x, w.y)
		var here := pos.distance_to(world.player.global_position) < 40.0
		var b := UIKit.button(("%s  (você está aqui)" if here else "%s") % w.name, func(): world.travel_to(pos), 380)
		b.disabled = here
		list.add_child(b)
	body.add_child(UIKit.button("Fechar", close_popup, 400))


func toggle_pause() -> void:
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
		get_tree().paused = false
		return
	get_tree().paused = true
	_pause_layer = _overlay(0.6)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(center)
	var p := PanelContainer.new()
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(320, 0)
	p.add_child(v)
	v.add_child(UIKit.title("Pausado", 30))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.button("Continuar", toggle_pause))
	v.add_child(UIKit.button("Opções", func():
		var o := OptionsPanel.new()
		var c2 := CenterContainer.new()
		c2.set_anchors_preset(Control.PRESET_FULL_RECT)
		_pause_layer.add_child(c2)
		c2.add_child(o)
		o.closed.connect(c2.queue_free)
	))
	v.add_child(UIKit.button("Salvar Jogo", func():
		Game.save_game()
		show_message("Jogo salvo", UIKit.GOLD)
	))
	v.add_child(UIKit.button("Salvar e Sair para o Menu", func(): Game.quit_to_menu()))
	v.add_child(UIKit.button("Sair do Jogo", func():
		Game.save_game()
		get_tree().quit()
	))


func show_death_screen() -> void:
	_death_layer = _overlay(0.0)
	var tw := _death_layer.create_tween()
	tw.tween_property(_death_layer, "modulate:a", 1.0, 1.2).from(0.0)
	var bg: ColorRect = _death_layer.get_child(0)
	bg.color = Color(0.25, 0, 0, 0.55)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_layer.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)
	var t := UIKit.title("VOCE MORREU", 56)
	t.add_theme_color_override("font_color", Color(0.85, 0.1, 0.05))
	v.add_child(t)
	var sub := UIKit.label("%s caiu na Profundidade %d." % [hero.hero_name, Game.depth], 18, UIKit.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	if hero.hardcore:
		var hc := UIKit.label("Modo Hardcore: seu herói se foi para sempre.
Nível %d - %d abates - Profundidade máxima %d" % [hero.level, hero.kills, hero.deepest], 16, Color(1, 0.5, 0.4))
		hc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(hc)
		v.add_child(UIKit.button("Voltar ao Menu", func(): Game.change_scene(Game.MAIN_MENU), 380))
		return
	v.add_child(UIKit.button("Ressuscitar no Ponto de Partida (-10% ouro)", func():
		_death_layer.queue_free()
		_death_layer = null
		world.respawn_player()
	, 380))
	v.add_child(UIKit.button("Sair para o Menu", func(): Game.quit_to_menu(), 380))


func _overlay(alpha: float) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(c)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, alpha)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)
	return c


func _exit_tree() -> void:
	"""Desconectar signals para evitar memory leak"""
	if Game.trade_requested.is_connected(_on_trade_requested):
		Game.trade_requested.disconnect(_on_trade_requested)
	if Game.quest_log and Game.quest_log.quest_started.is_connected(_on_quest_started):
		Game.quest_log.quest_started.disconnect(_on_quest_started)
	if Game.quest_log and Game.quest_log.quest_completed.is_connected(_on_quest_completed):
		Game.quest_log.quest_completed.disconnect(_on_quest_completed)
	if get_viewport():
		get_viewport().size_changed.disconnect(_layout)
