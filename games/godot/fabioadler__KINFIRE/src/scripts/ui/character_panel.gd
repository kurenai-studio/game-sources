class_name CharacterPanel
extends PanelContainer
## Ficha do personagem estilo D&D: atributos, modificadores, estatísticas e passivas.

var hud: HUD
var hero: Hero
var _header: RichTextLabel
var _points_label: Label
var _ability_rows: Dictionary = {}
var _derived: RichTextLabel
var _details: RichTextLabel
## Aba Status (Fase 10)
var _status_points_label: Label
var _status_rows: Dictionary = {}
var _status_bonus: RichTextLabel


func setup(p_hud: HUD, p_hero: Hero) -> void:
	hud = p_hud
	hero = p_hero
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var w := UIKit.window_panel("Personagem", Vector2(500, 0), func(): hud.toggle_character())
	add_child(w.panel)
	var body: VBoxContainer = w.body

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	body.add_child(top)
	var portrait := SpritePreview.new()
	portrait.custom_minimum_size = Vector2(64, 72)
	portrait.set_sprite(hero.sprite_base(), hero.tint * hero.race.tint)
	top.add_child(portrait)
	_header = UIKit.rich()
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_header)

	var tabs := TabContainer.new()
	# 330px: retrato (72) + abas cabem na janela de 470px do painel unificado;
	# o conteúdo que passa rola dentro de cada aba (scroll)
	tabs.custom_minimum_size = Vector2(480, 330)
	body.add_child(tabs)

	# Atributos D&D: pontos + grade + derivadas somam mais que a aba - rola
	var attr_scroll := ScrollContainer.new()
	attr_scroll.name = "Atributos"
	attr_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(attr_scroll)
	var attr := VBoxContainer.new()
	attr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr.add_theme_constant_override("separation", 6)
	attr_scroll.add_child(attr)
	_points_label = UIKit.label("", 15, Color(0.5, 1, 0.5), true)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr.add_child(_points_label)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 0)
	attr.add_child(grid)
	for a in DB.ABILITIES:
		var n := UIKit.label(DB.ABILITY_NAMES[a], 16, UIKit.TEXT, true)
		n.custom_minimum_size.x = 170
		n.tooltip_text = DB.ABILITY_DESC[a]
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(n)
		var score := UIKit.label("", 18, Color.WHITE, true)
		score.custom_minimum_size.x = 36
		grid.add_child(score)
		var m := UIKit.label("", 15, UIKit.TEXT_DIM)
		m.custom_minimum_size.x = 40
		grid.add_child(m)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(28, 24)
		var tight := UIKit.box(Color(0.16, 0.3, 0.1), Color(0.4, 0.8, 0.3), 1, 3)
		tight.content_margin_top = 0
		tight.content_margin_bottom = 0
		tight.content_margin_left = 4
		tight.content_margin_right = 4
		plus.add_theme_stylebox_override("normal", tight)
		plus.pressed.connect(func():
			hero.spend_point(a)
			Sfx.play(&"click")
		)
		grid.add_child(plus)
		_ability_rows[a] = {"score": score, "mod": m, "plus": plus}
	attr.add_child(UIKit.separator())
	_derived = UIKit.rich()
	_derived.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr.add_child(_derived)

	# Status ARPG (Fase 10): Força, Agilidade, Mente, Vitalidade
	var status_scroll := ScrollContainer.new()
	status_scroll.name = "Status"
	status_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(status_scroll)
	var status_tab := VBoxContainer.new()
	status_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_tab.add_theme_constant_override("separation", 8)
	status_scroll.add_child(status_tab)
	_status_points_label = UIKit.label("", 15, Color(0.5, 1, 0.5), true)
	_status_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_tab.add_child(_status_points_label)
	var status_grid := GridContainer.new()
	status_grid.columns = 4
	status_grid.add_theme_constant_override("h_separation", 10)
	status_grid.add_theme_constant_override("v_separation", 6)
	status_tab.add_child(status_grid)
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		var s_name: String = s.capitalize()
		var lbl := UIKit.label(s_name, 16, UIKit.TEXT, true)
		lbl.custom_minimum_size.x = 110
		status_grid.add_child(lbl)
		# Total (base + gasto)
		var total_lbl := UIKit.label("", 18, Color.WHITE, true)
		total_lbl.custom_minimum_size.x = 40
		status_grid.add_child(total_lbl)
		# Base da classe
		var base_lbl := UIKit.label("", 14, UIKit.TEXT_DIM)
		base_lbl.custom_minimum_size.x = 40
		base_lbl.tooltip_text = "Base da classe (sobe com o nível, não pode ser respeitado)"
		status_grid.add_child(base_lbl)
		# Botões +/-
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 4)
		var minus := Button.new()
		minus.text = "-"
		minus.custom_minimum_size = Vector2(28, 24)
		var tight_m := UIKit.box(Color(0.3, 0.16, 0.1), Color(0.8, 0.4, 0.3), 1, 3)
		tight_m.content_margin_top = 0
		tight_m.content_margin_bottom = 0
		tight_m.content_margin_left = 4
		tight_m.content_margin_right = 4
		minus.add_theme_stylebox_override("normal", tight_m)
		minus.pressed.connect(func():
			# Respec individual: devolve 1 ponto se acima da base
			var base: int = hero.cls.base_status.get(s, 10)
			var growth: int = hero.cls.status_growth.get(s, 0)
			if hero.level > 1:
				base += growth * (hero.level - 1)
			if hero.status[s] > base:
				hero.status[s] -= 1
				hero.status_points += 1
				hero.stats_changed.emit()
				Sfx.play(&"click")
		)
		btns.add_child(minus)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(28, 24)
		var tight_p := UIKit.box(Color(0.16, 0.3, 0.1), Color(0.4, 0.8, 0.3), 1, 3)
		tight_p.content_margin_top = 0
		tight_p.content_margin_bottom = 0
		tight_p.content_margin_left = 4
		tight_p.content_margin_right = 4
		plus.add_theme_stylebox_override("normal", tight_p)
		plus.pressed.connect(func():
			if hero.spend_status_point(s):
				Sfx.play(&"click")
		)
		btns.add_child(plus)
		status_grid.add_child(btns)
		_status_rows[s] = {"total": total_lbl, "base": base_lbl, "minus": minus, "plus": plus}
	status_tab.add_child(UIKit.separator())
	# Botão Respec Total
	var respec_row := HBoxContainer.new()
	respec_row.add_theme_constant_override("separation", 12)
	respec_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var respec_btn := Button.new()
	respec_btn.text = "Respec Total (devolve pontos gastos)"
	respec_btn.custom_minimum_size = Vector2(220, 32)
	var respec_style := UIKit.box(Color(0.3, 0.16, 0.1), Color(0.8, 0.4, 0.3), 1, 4)
	respec_style.content_margin_top = 4
	respec_style.content_margin_bottom = 4
	respec_btn.add_theme_stylebox_override("normal", respec_style)
	respec_btn.pressed.connect(func():
		hero.respec_status()
		Sfx.play(&"click")
		hud.show_message("Status respecado - %d pontos devolvidos" % hero.status_points, Color(0.4, 1, 0.4), 1.5)
	)
	respec_row.add_child(respec_btn)
	status_tab.add_child(respec_row)
	status_tab.add_child(UIKit.separator())
	# Bônus de combate
	var bonus_lbl := UIKit.label("[font_size=15][color=#e8c060]Bônus de Combate[/color][/font_size]", 15)
	bonus_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_tab.add_child(bonus_lbl)
	_status_bonus = UIKit.rich()
	_status_bonus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_tab.add_child(_status_bonus)

	var det_scroll := ScrollContainer.new()
	det_scroll.name = "Detalhes"
	det_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(det_scroll)
	_details = UIKit.rich()
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	det_scroll.add_child(_details)

	hero.stats_changed.connect(refresh)
	hero.xp_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var diff: Dictionary = hero.difficulty_data()
	_header.text = "[font_size=22][color=#e8c060]%s[/color][/font_size]\n%s %s - Nível %d\n[color=#999999]XP: %d / %d   -   [/color][color=#%s]%s%s[/color]" % [
		hero.hero_name, hero.race.display_name, hero.cls.display_name, hero.level, hero.xp, hero.xp_to_next(),
		diff.color.to_html(false), diff.name, " - Hardcore" if hero.hardcore else ""]
	_points_label.text = ("Pontos de atributo disponíveis: %d" % hero.unspent_points) if hero.unspent_points > 0 else ""
	for a in DB.ABILITIES:
		var row: Dictionary = _ability_rows[a]
		var score := hero.ability(a)
		var m := DB.ability_mod(score)
		row.score.text = str(score)
		row.mod.text = ("+%d" % m) if m >= 0 else str(m)
		# Mantém o botão no grid (invisível) para não desalinhar as colunas
		row.plus.disabled = hero.unspent_points <= 0
		row.plus.modulate.a = 1.0 if hero.unspent_points > 0 else 0.0
		var primary: bool = a == hero.cls.primary_ability
		row.score.add_theme_color_override("font_color", UIKit.GOLD if primary else Color.WHITE)
	var t := "[font_size=14][table=2]"
	var wd := hero.weapon_damage()
	t += _row("Dano da arma", "%.1f - %.1f" % [wd.x * hero.damage_multiplier(), wd.y * hero.damage_multiplier()])
	t += _row("DPS estimado", "%.1f" % hero.dps_estimate())
	t += _row("Velocidade de ataque", "%.2f/s" % hero.attack_speed())
	t += _row("Chance de crítico", "%.1f%%" % (hero.crit_chance() * 100))
	t += _row("Dano crítico", "+%d%%" % roundi(hero.crit_damage() * 100))
	t += _row("Vida máxima", "%.1f" % hero.max_hp())
	t += _row("Armadura", "%.1f (reduz %d%% do dano físico)" % [hero.armor(), roundi(hero.physical_reduction() * 100)])
	t += _row(hero.cls.resource_label + " máximo", "%.1f" % hero.max_resource())
	t += _row("Velocidade de movimento", "%d%%" % roundi(hero.move_speed() / Hero.BASE_MOVE_SPEED * 100))
	t += _row("Atributo primário", DB.ABILITY_NAMES[hero.cls.primary_ability])
	_derived.text = t + "[/table][/font_size]"

	# Aba Status ARPG
	_status_points_label.text = ("Pontos de status disponíveis: %d" % hero.status_points) if hero.status_points > 0 else ""
	for s in ["forca", "agilidade", "mente", "vitalidade"]:
		var row: Dictionary = _status_rows[s]
		var base: int = hero.cls.base_status.get(s, 10)
		var growth: int = hero.cls.status_growth.get(s, 0)
		if hero.level > 1:
			base += growth * (hero.level - 1)
		var total: int = hero.status[s]
		var gasto: int = total - base
		row.total.text = str(total)
		row.total.add_theme_color_override("font_color", UIKit.GOLD if gasto > 0 else Color.WHITE)
		row.base.text = "(base %d)" % base
		var has_points: bool = hero.status_points > 0
		row.plus.disabled = not has_points
		row.plus.modulate.a = 1.0 if has_points else 0.0
		row.minus.disabled = gasto <= 0
		row.minus.modulate.a = 1.0 if gasto > 0 else 0.0
	# Bônus de combate
	var bonus := hero.status_bonus()
	var b := "[font_size=14][table=2]"
	b += _row("Dano corpo a corpo", "+%.1f%%" % (bonus.melee_damage_pct * 100))
	b += _row("Velocidade de movimento", "+%.1f%%" % (bonus.move_speed_pct * 100))
	b += _row("Velocidade de ataque", "+%.1f%%" % (bonus.attack_speed_pct * 100))
	b += _row("Dano mágico", "+%.1f%%" % (bonus.spell_damage_pct * 100))
	b += _row("Mana máxima", "+%d" % bonus.max_mp_bonus)
	b += _row("Vida máxima", "+%d" % bonus.max_hp_bonus)
	b += "[/table][/font_size]"
	_status_bonus.text = b


func cleanup() -> void:
	"""Desconectar signals para evitar memory leak"""
	if hero.stats_changed.is_connected(refresh):
		hero.stats_changed.disconnect(refresh)
	if hero.xp_changed.is_connected(refresh):
		hero.xp_changed.disconnect(refresh)

	var d := "[font_size=15][color=#e8c060]Resistências[/color][/font_size]\n[font_size=14][table=2]"
	for e in ["fire", "ice", "poison", "shadow"]:
		d += _row(DB.ELEMENT_NAMES[e], "%d%%" % roundi(hero.resist(e) * 100))
	d += _row("Chance de bloqueio", "%d%%" % roundi(hero.block_chance() * 100))
	d += _row("Roubo de vida", "%.1f%%" % (hero.lifesteal() * 100))
	d += _row("Redução de recarga", "%d%%" % roundi((1.0 - hero.cooldown_mult()) * 100))
	d += _row("Ouro encontrado", "+%d%%" % roundi(hero.gold_find() * 100))
	d += _row("Bônus de experiência", "+%d%%" % roundi((hero.xp_multiplier() - 1.0) * 100))
	d += "[/table][/font_size]\n\n"
	d += "[font_size=15][color=#e8c060]Raça: %s - %s[/color][/font_size]\n[color=#bbbbbb]%s[/color]\n\n" % [hero.race.display_name, hero.race.trait_name, hero.race.trait_description]
	d += "[font_size=15][color=#e8c060]Classe: %s[/color][/font_size] [color=#999999](%s)[/color]\n[color=#bbbbbb]%s[/color]\n" % [hero.cls.display_name, hero.cls.role, hero.cls.description]
	var weapons := PackedStringArray()
	for c in hero.cls.allowed_weapons:
		weapons.append(DB.CATEGORY_NAMES.get(c, c))
	var offs := PackedStringArray()
	for c in hero.cls.allowed_offhands:
		offs.append(DB.CATEGORY_NAMES.get(c, c))
	d += "[color=#999999]Armas: %s\nMão secundária: %s[/color]\n\n" % [", ".join(weapons), ", ".join(offs) if not offs.is_empty() else "nenhuma"]
	var bg := hero.background_data()
	d += "[font_size=15][color=#e8c060]Antecedente: %s[/color][/font_size]\n[color=#bbbbbb]%s[/color]\n\n" % [bg.name, bg.desc]
	var mins := int(hero.play_time / 60.0)
	d += "[color=#999999]Abates: %d   -   Profundidade máxima: %d   -   Tempo de jogo: %dh%02dm[/color]" % [hero.kills, hero.deepest, mins / 60, mins % 60]
	_details.text = d


func _row(label_text: String, value: String) -> String:
	return "[cell][color=#aaaaaa]%s   [/color][/cell][cell][color=#ffffff]%s[/color][/cell]" % [label_text, value]
