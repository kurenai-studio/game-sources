extends Control
## Criação de personagem em WIZARD sequencial (REGRAS #15, MECANICAS #11):
## raça -> classe -> atributos (com antecedente e dificuldade) -> nome.
## Nenhum passo pode ser pulado; todos são obrigatórios.
## No fluxo do prólogo (Game.phase == PHASE_PROLOGUE), confirmar chama
## Game.finish_prologue() - o herói acorda no acampamento da raça escolhida.

const STEPS := ["Raça", "Classe", "Atributos", "Nome & Aparência"]
const POINT_BUY_TOTAL := 27
const COST := {8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9}
const TINTS := [
	Color(1, 1, 1), Color(1.0, 0.86, 0.75), Color(0.8, 0.65, 0.5), Color(0.85, 0.95, 1.0),
	Color(0.85, 1.0, 0.85), Color(1.0, 0.8, 0.85), Color(0.8, 0.75, 1.0), Color(1.0, 0.95, 0.65),
]
const NAMES := {
	"default": ["Aldric", "Thalia", "Kael", "Seraphine", "Isolde", "Garrick", "Brienne", "Orin", "Vesper", "Mirela"],
	"elf": ["Aelar", "Lyra", "Faelar", "Sylvaris", "Elowen", "Thaeris", "Naivara", "Galinndan", "Shava", "Ilyana"],
	"dwarf": ["Borin", "Dagna", "Thorgar", "Helja", "Brottor", "Vistra", "Rurik", "Eldeth", "Dorn", "Kildrak"],
	"orc": ["Grommash", "Shura", "Thokk", "Baggi", "Ront", "Emen", "Kansif", "Volen", "Dench", "Engong"],
	"chort": ["Zariel", "Malphas", "Nyx", "Akmenos", "Orianna", "Kallista", "Damakos", "Ekemon", "Morthos", "Rieta"],
	"lizard": ["Arjhan", "Sora", "Kriv", "Biri", "Medrash", "Harann", "Nadarr", "Thava", "Rhogar", "Daar"],
	"wizzard": ["Fonkin", "Nissa", "Boddynock", "Zook", "Ellyjobell", "Orryn", "Bimpnottin", "Wrenn", "Glim", "Tana"],
	"goblin": ["Miau", "Garra", "Bigode", "Cinza", "Ventania", "Pulo", "Sombra", "Brasa", "Neblina", "Raio"],
	"ogre": ["Aukan", "Kuori", "Gae-Al", "Thalai", "Vaunea", "Keothi", "Manneo", "Eglath", "Ilikan", "Nalla"],
}

var race: RaceData
var cls: ClassData
var sex := "m"
var tint_idx := 0
var scores: Dictionary = {"str": 8, "dex": 8, "con": 8, "int": 8, "wis": 8, "cha": 8}
var free_bonus: Dictionary = {}
var background := "soldado"
var difficulty := 0
var hardcore := false
var _running := false
var _step := 0

var _race_buttons: Dictionary = {}
var _class_buttons: Dictionary = {}
var _preview: SpritePreview
var _name_edit: LineEdit
var _points_label: Label
var _ability_rows: Dictionary = {}
var _info: RichTextLabel
var _stats_preview: RichTextLabel
var _free_box: VBoxContainer
var _free_options: Array[OptionButton] = []
var _bg_desc: Label
var _diff_desc: Label
var _sex_btn: Button
var _start_btn: Button
var _back_btn: Button
var _step_label: Label
var _swatches: Array[Button] = []
var _pages: Array[Control] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	race = DB.races[0]
	cls = DB.classes[0]

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.015)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	root.add_child(UIKit.title("Criação de Personagem", 30))
	if Game.phase == Game.PHASE_PROLOGUE:
		# Veio do espelho do prólogo: o vazio devolve não o que você era...
		var sub := UIKit.label("O espelho não devolve o que você era - devolve o que você escolhe ser.", 15, UIKit.TEXT_DIM)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(sub)

	_step_label = UIKit.label("", 17, UIKit.GOLD, true)
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_step_label)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	root.add_child(cols)
	# Coluna esquerda: uma página por passo (só a atual é visível)
	for i in 4:
		var page := _build_page(i)
		page.visible = false
		cols.add_child(page)
		_pages.append(page)
	# Coluna direita: prévia persistente (aparência + informações)
	cols.add_child(_build_side_panel())

	root.add_child(_build_nav_bar())

	_apply_recommended()
	_go_step(0)


# ------------------------------------------------------------------ PAGINAS (passo a passo)

func _build_page(i: int) -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	match i:
		0: scroll.add_child(_build_race_list())
		1: scroll.add_child(_build_class_list())
		2: scroll.add_child(_build_attributes())
		3: scroll.add_child(_build_name_page())
	return scroll


func _build_race_list() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_page_intro("Escolha o povo que corre nas suas veias. Cada raça muda atributos, aparência e um traço único."))
	var rg := GridContainer.new()
	rg.columns = 2
	rg.add_theme_constant_override("h_separation", 8)
	rg.add_theme_constant_override("v_separation", 6)
	rg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(rg)
	for r in DB.races:
		var b := _choice_button(r.display_name, DB.dt2_texture(r.sprite_m + "_idle_anim_f0"))
		b.pressed.connect(func():
			race = r
			if sex == "f" and r.sprite_f == r.sprite_m:
				sex = "m"
			free_bonus.clear()
			_refresh()
		)
		rg.add_child(b)
		_race_buttons[r.id] = b
	return v


func _build_class_list() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_page_intro("Escolha o que suas mãos aprenderão a fazer. A classe define vida, recurso e habilidades."))
	var cg := GridContainer.new()
	cg.columns = 2
	cg.add_theme_constant_override("h_separation", 8)
	cg.add_theme_constant_override("v_separation", 6)
	cg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(cg)
	for c in DB.classes:
		var b := _choice_button(c.display_name, DB.icon(c.icon))
		b.pressed.connect(func():
			cls = c
			_apply_recommended()
			_refresh()
		)
		cg.add_child(b)
		_class_buttons[c.id] = b
	return v


func _build_attributes() -> Control:
	var attr := VBoxContainer.new()
	attr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr.add_child(_page_intro("Distribua os 27 pontos (compra D&D 5e: 8-15). Depois, escolha antecedente e dificuldade."))
	_points_label = UIKit.label("", 15, UIKit.GOLD, true)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr.add_child(_points_label)
	var hdr := HBoxContainer.new()
	attr.add_child(hdr)
	for t in [["", 118], ["Base", 80], ["Bônus", 42], ["Total", 44], ["Mod", 34]]:
		var l := UIKit.label(t[0], 12, UIKit.TEXT_DIM)
		l.custom_minimum_size.x = t[1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hdr.add_child(l)
	for a in DB.ABILITIES:
		var r := HBoxContainer.new()
		attr.add_child(r)
		var n := UIKit.label(DB.ABILITY_NAMES[a], 14, UIKit.TEXT, true)
		n.custom_minimum_size.x = 118
		n.tooltip_text = DB.ABILITY_DESC[a]
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		r.add_child(n)
		var minus := _small_button("-", func(): _change(a, -1))
		r.add_child(minus)
		var base := UIKit.label("", 15, Color.WHITE, true)
		base.custom_minimum_size.x = 26
		base.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(base)
		var plus := _small_button("+", func(): _change(a, 1))
		r.add_child(plus)
		var bonus := UIKit.label("", 14, Color(0.5, 1, 0.5))
		bonus.custom_minimum_size.x = 42
		bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(bonus)
		var total := UIKit.label("", 17, UIKit.GOLD, true)
		total.custom_minimum_size.x = 44
		total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(total)
		var m := UIKit.label("", 14, UIKit.TEXT_DIM)
		m.custom_minimum_size.x = 34
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_child(m)
		_ability_rows[a] = {"base": base, "bonus": bonus, "total": total, "mod": m, "minus": minus, "plus": plus, "name": n}
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	attr.add_child(btns)
	btns.add_child(UIKit.button("Recomendado", func():
		_apply_recommended()
		_refresh()
	))
	btns.add_child(UIKit.button("Zerar", func():
		for k in scores:
			scores[k] = 8
		_refresh()
	))
	_free_box = VBoxContainer.new()
	attr.add_child(_free_box)
	attr.add_child(UIKit.separator())

	attr.add_child(UIKit.label("Antecedente", 17, UIKit.GOLD, true))
	var bg_opt := OptionButton.new()
	bg_opt.focus_mode = Control.FOCUS_NONE
	var keys := DB.BACKGROUNDS.keys()
	for k in keys:
		bg_opt.add_item(DB.BACKGROUNDS[k].name)
	bg_opt.item_selected.connect(func(i: int):
		background = keys[i]
		_refresh()
	)
	attr.add_child(bg_opt)
	_bg_desc = UIKit.label("", 14, UIKit.TEXT_DIM)
	_bg_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	attr.add_child(_bg_desc)
	attr.add_child(UIKit.separator())
	attr.add_child(UIKit.label("Dificuldade", 17, UIKit.GOLD, true))
	var diff_opt := OptionButton.new()
	diff_opt.focus_mode = Control.FOCUS_NONE
	for d in DB.DIFFICULTIES:
		diff_opt.add_item(d.name)
	diff_opt.item_selected.connect(func(i: int):
		difficulty = i
		_refresh()
	)
	attr.add_child(diff_opt)
	_diff_desc = UIKit.label("", 14, UIKit.TEXT_DIM)
	_diff_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	attr.add_child(_diff_desc)
	var hc := CheckButton.new()
	hc.text = "Modo Hardcore (morte permanente)"
	hc.focus_mode = Control.FOCUS_NONE
	hc.toggled.connect(func(on: bool):
		hardcore = on
		Sfx.play(&"click")
	)
	attr.add_child(hc)
	attr.add_child(UIKit.separator())
	_stats_preview = UIKit.rich("", false)
	_stats_preview.custom_minimum_size = Vector2(0, 110)
	attr.add_child(_stats_preview)
	return attr


func _build_name_page() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_page_intro("Por fim, o nome. No Véu, o que não tem nome não pode ser lembrado - nem salvo."))
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(name_row)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome do herói"
	_name_edit.max_length = 18
	_name_edit.custom_minimum_size = Vector2(300, 42)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.text_changed.connect(func(_t): _refresh())
	name_row.add_child(_name_edit)
	var dice := Button.new()
	dice.text = "🎲"
	dice.tooltip_text = "Nome aleatório"
	dice.custom_minimum_size = Vector2(46, 42)
	dice.pressed.connect(func():
		_name_edit.text = _random_name()
		_refresh()
	)
	name_row.add_child(dice)
	v.add_child(UIKit.label("(use os tons de pele e o sexo no painel ao lado)", 13, UIKit.TEXT_DIM))
	return v


func _page_intro(text: String) -> Label:
	var l := UIKit.label(text, 15, UIKit.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size.x = 460
	return l


# ------------------------------------------------------------------ PAINEL LATERAL (prévia persistente)

func _build_side_panel() -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)

	var stage := Panel.new()
	stage.custom_minimum_size = Vector2(0, 210)
	stage.add_theme_stylebox_override("panel", UIKit.box(Color(0.07, 0.05, 0.04), UIKit.GOLD_DIM, 2, 8))
	v.add_child(stage)
	var floor_tex := TextureRect.new()
	floor_tex.texture = _floor_strip()
	floor_tex.stretch_mode = TextureRect.STRETCH_TILE
	floor_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor_tex.offset_left = 4
	floor_tex.offset_right = -4
	floor_tex.offset_top = 4
	floor_tex.offset_bottom = -4
	floor_tex.modulate = Color(0.5, 0.45, 0.45)
	stage.add_child(floor_tex)
	_preview = SpritePreview.new()
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.offset_top = 10
	_preview.offset_bottom = -10
	stage.add_child(_preview)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	_sex_btn = Button.new()
	_sex_btn.focus_mode = Control.FOCUS_NONE
	_sex_btn.custom_minimum_size = Vector2(130, 32)
	_sex_btn.pressed.connect(func():
		sex = "f" if sex == "m" else "m"
		Sfx.play(&"click", -6.0)
		_refresh()
	)
	row.add_child(_sex_btn)
	var run_btn := Button.new()
	run_btn.text = "Animação"
	run_btn.focus_mode = Control.FOCUS_NONE
	run_btn.custom_minimum_size = Vector2(110, 32)
	run_btn.pressed.connect(func():
		_running = not _running
		_preview.animation = "run" if _running else "idle"
	)
	row.add_child(run_btn)
	for i in TINTS.size():
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(26, 26)
		sw.focus_mode = Control.FOCUS_NONE
		sw.tooltip_text = "Tom de pele/cor"
		var sb := UIKit.box(TINTS[i] * Color(0.85, 0.85, 0.85), UIKit.GOLD_DIM, 2, 13)
		sw.add_theme_stylebox_override("normal", sb)
		sw.add_theme_stylebox_override("hover", UIKit.box(TINTS[i], UIKit.GOLD, 2, 13))
		sw.add_theme_stylebox_override("pressed", UIKit.box(TINTS[i], Color.WHITE, 3, 13))
		sw.pressed.connect(func():
			tint_idx = i
			Sfx.play(&"click", -8.0)
			_refresh()
		)
		row.add_child(sw)
		_swatches.append(sw)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_info = UIKit.rich()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_info)
	return p


func _build_nav_bar() -> Control:
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	_back_btn = UIKit.button("◀ Voltar", _on_back, 160)
	bottom.add_child(_back_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp)
	bottom.add_child(UIKit.button("Aleatório", _randomize, 160))
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp2)
	_start_btn = UIKit.button("Continuar ▶", _on_next, 240)
	_start_btn.add_theme_font_size_override("font_size", 20)
	bottom.add_child(_start_btn)
	return bottom


# ------------------------------------------------------------------ NAVEGACAO

func _go_step(s: int) -> void:
	_step = clampi(s, 0, 3)
	for i in _pages.size():
		_pages[i].visible = i == _step
	_step_label.text = "Passo %d de 4 - %s" % [_step + 1, STEPS[_step]]
	_refresh()


func _on_next() -> void:
	if _step < 3:
		Sfx.play(&"ui_open", -6.0)
		_go_step(_step + 1)
	else:
		_on_start()


func _on_back() -> void:
	Sfx.play(&"ui_close", -6.0)
	if _step > 0:
		_go_step(_step - 1)
	else:
		Game.change_scene(Game.MAIN_MENU)


func _can_continue() -> bool:
	match _step:
		0: return race != null
		1: return cls != null
		2: return POINT_BUY_TOTAL - _spent() == 0
		3: return _name_edit.text.strip_edges() != ""
	return false


# ------------------------------------------------------------------ WIDGETS BASE

func _choice_button(text: String, icon: Texture2D) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 34)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 15)
	b.clip_text = true
	if icon:
		b.icon = icon
		b.add_theme_constant_override("icon_max_width", 22)
	b.pressed.connect(func(): Sfx.play(&"click", -6.0))
	return b


func _small_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(26, 26)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(cb)
	b.pressed.connect(func(): Sfx.play(&"click", -10.0))
	return b


func _floor_strip() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var sheet := DB.DT2_SHEET.get_image()
	if sheet.is_compressed():
		sheet.decompress()
	sheet.convert(Image.FORMAT_RGBA8)
	for x in 4:
		for y in 4:
			var n := "floor_1" if randf() > 0.25 else "floor_%d" % randi_range(2, 8)
			img.blit_rect(sheet, DB.dt2_rect(n), Vector2i(x * 16, y * 16))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ LÓGICA

func _spent() -> int:
	var total := 0
	for a in scores:
		total += COST[scores[a]]
	return total


func _change(a: String, d: int) -> void:
	var nv: int = scores[a] + d
	if nv < 8 or nv > 15:
		return
	var old: int = scores[a]
	scores[a] = nv
	if _spent() > POINT_BUY_TOTAL:
		scores[a] = old
		return
	_refresh()


## Distribui 27 pontos seguindo a prioridade da classe (15, 14, 13, 12, 10, 8)
func _apply_recommended() -> void:
	var order: Array = Array(cls.recommended)
	for a in DB.ABILITIES:
		if not order.has(a):
			order.append(a)
	var arr: Array = [15, 14, 13, 12, 10, 8]
	for i in order.size():
		scores[order[i]] = arr[i]


func _random_name() -> String:
	var key := race.sprite_m.split("_")[0]
	var list: Array = NAMES.get(key, NAMES.default)
	return list.pick_random()


func _randomize() -> void:
	race = DB.races.pick_random()
	cls = DB.classes.pick_random()
	sex = ["m", "f"].pick_random() if race.sprite_f != race.sprite_m else "m"
	tint_idx = randi() % TINTS.size()
	free_bonus.clear()
	_apply_recommended()
	if _name_edit:
		_name_edit.text = _random_name()
	Sfx.play(&"magic", -6.0)
	_refresh()


func _current_tint() -> Color:
	return TINTS[tint_idx] * race.tint


func _build_free_bonus() -> void:
	for c in _free_box.get_children():
		c.queue_free()
	_free_options.clear()
	if race.free_bonus_choices <= 0:
		return
	_free_box.add_child(UIKit.label("%s: escolha %d atributos para +1" % [race.display_name, race.free_bonus_choices], 13, Color(0.5, 1, 0.5)))
	var row := HBoxContainer.new()
	_free_box.add_child(row)
	var chosen := free_bonus.keys()
	for i in race.free_bonus_choices:
		var o := OptionButton.new()
		o.focus_mode = Control.FOCUS_NONE
		o.custom_minimum_size.x = 150
		for a in DB.ABILITIES:
			o.add_item(DB.ABILITY_NAMES[a])
		var pick: String = chosen[i] if i < chosen.size() else ["con", "dex"][i % 2]
		o.selected = DB.ABILITIES.find(pick)
		o.item_selected.connect(func(_i): _read_free_bonus())
		row.add_child(o)
		_free_options.append(o)
	_read_free_bonus(false)


func _read_free_bonus(refresh := true) -> void:
	free_bonus.clear()
	for o in _free_options:
		var a: String = DB.ABILITIES[o.selected]
		free_bonus[a] = int(free_bonus.get(a, 0)) + 1
	if refresh:
		_refresh_abilities()


func _make_hero() -> Hero:
	var n := _name_edit.text.strip_edges()
	if n == "":
		n = _random_name()
	return Hero.create(n, race, cls, sex, TINTS[tint_idx], scores, free_bonus, background, difficulty, hardcore)


# ------------------------------------------------------------------ ATUALIZACAO

func _refresh() -> void:
	for id in _race_buttons:
		_race_buttons[id].button_pressed = id == race.id
	for id in _class_buttons:
		_class_buttons[id].button_pressed = id == cls.id
	for i in _swatches.size():
		_swatches[i].button_pressed = i == tint_idx
	var base := race.sprite_f if sex == "f" else race.sprite_m
	_preview.set_sprite(base, _current_tint())
	var w := DB.create_item(cls.starting_weapon, 1, 0)
	_preview.weapon = DB.dt2_texture(w.sprite) if w.sprite != "" else null
	var has_f := race.sprite_f != race.sprite_m
	_sex_btn.text = ("♀ Feminino" if sex == "f" else "♂ Masculino") if has_f else "♂ / ♀"
	_sex_btn.disabled = not has_f
	_build_free_bonus()
	_refresh_abilities()
	var bg: Dictionary = DB.BACKGROUNDS[background]
	_bg_desc.text = bg.desc
	var d: Dictionary = DB.DIFFICULTIES[difficulty]
	_diff_desc.text = "Vida dos monstros x%.1f, dano x%.2f. Itens melhores (+%d%%) e +%d%% de experiência." % [d.hp, d.dmg, roundi(d.loot * 100), roundi((d.xp - 1.0) * 100)]
	_diff_desc.add_theme_color_override("font_color", d.color)

	# Botão de navegação: habilitação e rótulo por passo
	_start_btn.text = "Iniciar Aventura" if _step == 3 else "Continuar ▶"
	_start_btn.disabled = not _can_continue()
	_back_btn.visible = _step > 0 or Game.phase != Game.PHASE_PROLOGUE

	# Painel lateral contextual por passo
	match _step:
		0: _info.text = _race_info_text()
		1: _info.text = _class_info_text()
		2: _info.text = _attr_info_text()
		3: _info.text = _summary_text()


func _bonus_text() -> String:
	var bonus_txt := ""
	for k in race.ability_bonus:
		var v: int = race.ability_bonus[k]
		bonus_txt += "%s%d %s  " % ["+" if v > 0 else "", v, DB.ABILITY_SHORT[k]]
	return bonus_txt


func _skills_text() -> String:
	var skills_txt := ""
	for s in cls.skills:
		skills_txt += "[img=18x18]%s[/img] %s [color=#888888](nv %d)[/color]   " % [_icon_path(s.icon), s.display_name, s.unlock_level]
	return skills_txt


func _race_info_text() -> String:
	return "[font_size=19][color=#e8c060]%s[/color][/font_size]  [color=#80ff80]%s[/color]\n%s\n[color=#e8c060]%s:[/color] %s" % [
		race.display_name, _bonus_text(), race.description, race.trait_name, race.trait_description]


func _class_info_text() -> String:
	var res_hex := cls.resource_color.to_html(false)
	return "[font_size=19][color=#e8c060]%s[/color][/font_size]  [color=#999999]%s[/color]\n%s\n[color=#cccccc]Dado de Vida: d%d  -  Primário: %s  -  Recurso: [color=#%s]%s[/color][/color]\n\n%s" % [
		cls.display_name, cls.role, cls.description, cls.hit_die, DB.ABILITY_NAMES[cls.primary_ability],
		res_hex, cls.resource_label, _skills_text()]


func _attr_info_text() -> String:
	var left := POINT_BUY_TOTAL - _spent()
	var tip := "[color=#80ff80]Todos os pontos gastos - pode continuar.[/color]" if left == 0 else \
		"[color=#ff9070]Distribua todos os %d pontos restantes para continuar.[/color]" % left
	return "[color=#e8c060]Atributos[/color]\n%s\n\n[color=#999999]Compra de pontos (D&D 5e): cada atributo começa em 8 e vai até 15. Valores altos custam mais. O [color=#e8c060]atributo primário[/color] da classe aumenta seu dano.[/color]" % tip


func _summary_text() -> String:
	var h := _make_hero()
	var res_hex := cls.resource_color.to_html(false)
	return "[font_size=19][color=#e8c060]%s[/color][/font_size]  [color=#80ff80]%s[/color]  -  [font_size=19][color=#e8c060]%s[/color][/font_size]\n[color=#e8c060]%s:[/color] %s\n\n[color=#cccccc]Vida: %d  -  %s: %d  -  Dano: %.1f  -  Armadura: %d  -  Crítico: %.1f%%[/color]\n\n%s" % [
		race.display_name, _bonus_text(), cls.display_name, race.trait_name, race.trait_description,
		h.max_hp(), cls.resource_label, h.max_resource(), h.dps_estimate(), h.armor(), h.crit_chance() * 100,
		_skills_text()]


func _icon_path(icon_name: String) -> String:
	return "res://assets/icons/%s.png" % icon_name


func _refresh_abilities() -> void:
	var left := POINT_BUY_TOTAL - _spent()
	_points_label.text = "Pontos restantes: %d / %d" % [left, POINT_BUY_TOTAL]
	_points_label.add_theme_color_override("font_color", UIKit.GOLD if left > 0 else Color(0.5, 1, 0.5))
	for a in DB.ABILITIES:
		var row: Dictionary = _ability_rows[a]
		var b: int = int(race.ability_bonus.get(a, 0)) + int(free_bonus.get(a, 0))
		var total: int = scores[a] + b
		var m := DB.ability_mod(total)
		row.base.text = str(scores[a])
		row.bonus.text = ("%+d" % b) if b != 0 else ""
		row.bonus.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if b > 0 else Color(1, 0.5, 0.5))
		row.total.text = str(total)
		row.mod.text = ("+%d" % m) if m >= 0 else str(m)
		var primary: bool = a == cls.primary_ability
		row.name.add_theme_color_override("font_color", UIKit.GOLD if primary else UIKit.TEXT)
		row.minus.disabled = scores[a] <= 8
		var next_cost: int = COST.get(scores[a] + 1, 999) - COST[scores[a]]
		row.plus.disabled = scores[a] >= 15 or next_cost > left
	# Prévia das estatísticas com um herói temporário
	var h := _make_hero()
	var t := "[font_size=13][table=2]"
	t += _cell("Vida", "%d" % h.max_hp())
	t += _cell(cls.resource_label, "%d" % h.max_resource())
	t += _cell("Dano (DPS)", "%.1f" % h.dps_estimate())
	t += _cell("Armadura", "%d" % h.armor())
	t += _cell("Crítico", "%.1f%%" % (h.crit_chance() * 100))
	t += _cell("Velocidade", "%d%%" % roundi(h.move_speed() / Hero.BASE_MOVE_SPEED * 100))
	_stats_preview.text = t + "[/table][/font_size]"


func _cell(label_text: String, value: String) -> String:
	return "[cell][color=#aaaaaa]%s   [/color][/cell][cell][color=#ffffff]%s[/color][/cell]" % [label_text, value]


# ------------------------------------------------------------------ CONFIRMAR

func _on_start() -> void:
	if not _can_continue():
		return
	var h := _make_hero()
	_start_btn.disabled = true
	if Game.phase == Game.PHASE_PROLOGUE:
		# Fim do prólogo: acorda no acampamento da raça escolhida (REGRAS #13)
		Game.finish_prologue(h)
	else:
		Game.delete_save()
		Game.new_game(h)
