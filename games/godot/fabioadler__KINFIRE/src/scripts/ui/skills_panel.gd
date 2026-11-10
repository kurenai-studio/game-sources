class_name SkillsPanel
extends PanelContainer
## Lista de habilidades da classe; selecione uma e clique em um slot para atribuí-la.

var hud: HUD
var hero: Hero
var _list: VBoxContainer
var _slots_row: HBoxContainer
var _selected: StringName = &""
var _info: RichTextLabel
const SLOT_NAMES := ["Botão Esq.", "Botão Dir.", "Tecla 1", "Tecla 2", "Tecla 3", "Tecla 4"]


func setup(p_hud: HUD, p_hero: Hero) -> void:
	hud = p_hud
	hero = p_hero
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var w := UIKit.window_panel("Habilidades - %s" % hero.cls.display_name, Vector2(620, 0), func(): hud.toggle_skills())
	add_child(w.panel)
	var body: VBoxContainer = w.body

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	body.add_child(hb)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_info = UIKit.rich()
	_info.custom_minimum_size = Vector2(280, 0)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.add_child(_info)

	body.add_child(UIKit.separator())
	body.add_child(UIKit.label("Selecione uma habilidade e clique no slot desejado:", 14, UIKit.TEXT_DIM))
	_slots_row = HBoxContainer.new()
	_slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_slots_row)

	hero.stats_changed.connect(refresh)
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for s in hero.cls.skills:
		var unlocked := s.unlock_level <= hero.level
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = DB.icon(s.icon)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 28)
		b.text = s.display_name if unlocked else "%s  (Nível %d)" % [s.display_name, s.unlock_level]
		b.disabled = not unlocked
		b.toggle_mode = true
		b.button_pressed = s.id == _selected
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(func():
			_selected = s.id
			Sfx.play(&"click")
			refresh()
		)
		b.mouse_entered.connect(func(): _show_info(s))
		_list.add_child(b)
	for c in _slots_row.get_children():
		c.queue_free()
	for i in Hero.SKILL_SLOTS:
		var col := VBoxContainer.new()
		var slot := SkillSlot.new(i, "")
		slot.player = hud.player
		slot.clicked.connect(_on_slot_clicked)
		col.add_child(slot)
		var l := UIKit.label(SLOT_NAMES[i], 11, UIKit.TEXT_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		_slots_row.add_child(col)
	if _selected != &"":
		_show_info(DB.get_skill(hero.cls, _selected))


func _show_info(s: SkillData) -> void:
	if s == null:
		return
	var t := "[font_size=20][color=#e8c060]%s[/color][/font_size]\n" % s.display_name
	t += "[color=#999999]Desbloqueia no nível %d[/color]\n\n" % s.unlock_level
	t += s.description + "\n\n"
	if s.damage_mult > 0:
		t += "[color=#ff9060]Dano: %d%% do dano da arma[/color]\n" % roundi(s.damage_mult * 100)
	if s.cost > 0:
		t += "[color=#80a0ff]Custo: %d %s[/color]\n" % [s.cost, hero.cls.resource_label]
	if s.generate > 0:
		t += "[color=#80ff80]Gera: %d %s[/color]\n" % [s.generate, hero.cls.resource_label]
	if s.cooldown > 0:
		t += "Recarga: %.1fs\n" % s.cooldown
	if s.stun > 0:
		t += "Atordoa por %.1fs\n" % s.stun
	_info.text = t


func _on_slot_clicked(slot: int) -> void:
	if _selected == &"":
		hud.show_message("Selecione uma habilidade primeiro", UIKit.TEXT_DIM, 1.0)
		return
	hero.assign_skill(slot, _selected)
	Sfx.play(&"equip")


func cleanup() -> void:
	"""Desconectar signals para evitar memory leak"""
	if hero.stats_changed.is_connected(refresh):
		hero.stats_changed.disconnect(refresh)
