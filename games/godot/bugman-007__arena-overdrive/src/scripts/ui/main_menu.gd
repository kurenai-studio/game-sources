extends Control
## Main menu with an animated shader background and tweened page transitions:
## main, character select, meta shop, achievements and settings.

var _pages: Dictionary = {}
var _current: String = ""
var _coins: Label
var _best: Label
var _settings: SettingsPanel
var _char_page: Control
var _shop_page: Control
var _ach_page: Control


func _ready() -> void:
	UiKit.full_rect(self)
	var bg := ColorRect.new()
	UiKit.full_rect(bg)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/menu_background.gdshader")
	bg.material = mat
	add_child(bg)
	_add_drift_particles()

	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 40
	top.offset_right = -40
	top.offset_top = 24
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_theme_constant_override("separation", 24)
	add_child(top)
	_best = UiKit.label("", "MutedLabel", 18)
	top.add_child(_best)
	_coins = UiKit.label("", "GoldLabel", 26)
	top.add_child(_coins)

	_pages["main"] = _build_main()
	_char_page = _page()
	_pages["play"] = _char_page
	_shop_page = _page()
	_pages["shop"] = _shop_page
	_ach_page = _page()
	_pages["achievements"] = _ach_page
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.hide()
	_settings.closed.connect(func() -> void: show_page("main"))
	_pages["settings"] = _settings

	var footer := UiKit.label("FOOTER_HINT", "MutedLabel", 15)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(40, -40)
	add_child(footer)
	var version := UiKit.label("v%s" % ProjectSettings.get_setting("application/config/version"), "MutedLabel", 15)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-90, -40)
	add_child(version)

	EventBus.wallet_changed.connect(_on_wallet)
	EventBus.settings_changed.connect(_refresh_header)
	_refresh_header()
	AudioManager.play_music()
	show_page("main", false)


func _add_drift_particles() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(640, 760)
	p.amount = 40
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 10)
	p.direction = Vector2.UP
	p.spread = 15.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(UiTheme.ACCENT, 0.5)
	p.material = Fx.additive()
	add_child(p)


func _on_wallet(_c: int) -> void:
	_refresh_header()


func _refresh_header() -> void:
	_coins.text = "◆ %d" % SaveSystem.get_coins()
	_best.text = tr("BEST_SCORE") % SaveSystem.stat("best_score")


func _page() -> Control:
	var c := Control.new()
	UiKit.full_rect(c)
	c.hide()
	add_child(c)
	return c


func _build_main() -> Control:
	var page := _page()
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	col.position = Vector2(90, -300)
	col.add_theme_constant_override("separation", 12)
	page.add_child(col)
	var title := UiKit.label("ARENA", "TitleLabel", 84)
	col.add_child(title)
	var title2 := UiKit.label("OVERDRIVE", "TitleLabel", 54)
	title2.add_theme_color_override("font_color", UiTheme.ACCENT_2)
	title2.add_theme_color_override("font_outline_color", Color(UiTheme.ACCENT_2, 0.35))
	col.add_child(title2)
	col.add_child(UiKit.label("TAGLINE", "MutedLabel", 19))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	col.add_child(spacer)
	var buttons: Array = []
	for entry in [["PLAY", "play"], ["UPGRADES", "shop"], ["ACHIEVEMENTS", "achievements"], ["SETTINGS", "settings"], ["QUIT", "quit"]]:
		var b := UiKit.button(entry[0])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var target: String = entry[1]
		b.pressed.connect(func() -> void:
			if target == "quit":
				get_tree().quit()
			else:
				show_page(target))
		col.add_child(b)
		buttons.append(b)
	UiKit.focus_chain(buttons)
	var pulse := title.create_tween().set_loops()
	pulse.tween_property(title, "modulate", Color(1.15, 1.15, 1.3), 1.4).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title, "modulate", Color.WHITE, 1.4).set_trans(Tween.TRANS_SINE)
	return page


func show_page(page_name: String, animate: bool = true) -> void:
	if page_name == _current:
		return
	match page_name:
		"play": _build_characters()
		"shop": _build_shop()
		"achievements": _build_achievements()
	var old: Control = _pages.get(_current)
	if old:
		if animate:
			var tw := old.create_tween().set_parallel(true)
			tw.tween_property(old, "modulate:a", 0.0, 0.18)
			tw.chain().tween_callback(old.hide)
		else:
			old.hide()
	_current = page_name
	var page: Control = _pages[page_name]
	if page == _settings:
		_settings.open()
		return
	page.show()
	page.modulate.a = 0.0
	page.position.x = 40.0 if animate else 0.0
	var tw2 := page.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw2.tween_property(page, "modulate:a", 1.0, 0.3).set_delay(0.1 if animate else 0.0)
	tw2.tween_property(page, "position:x", 0.0, 0.4).set_delay(0.1 if animate else 0.0)
	_focus_first.call_deferred(page)


func _focus_first(node: Node) -> void:
	for c in node.find_children("*", "BaseButton", true, false):
		var b := c as BaseButton
		if b.is_visible_in_tree() and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
			return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _current != "main" and _current != "settings":
		AudioManager.play_ui(&"ui_back")
		show_page("main")
		get_viewport().set_input_as_handled()


func _page_frame(page: Control, title_key: String) -> VBoxContainer:
	for c in page.get_children():
		c.queue_free()
	var center := CenterContainer.new()
	UiKit.full_rect(center)
	page.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)
	v.add_child(UiKit.label(title_key, "HeaderLabel", 40, HORIZONTAL_ALIGNMENT_CENTER))
	return v


func _back_button(v: Control) -> Button:
	var back := UiKit.button("BACK", Vector2(220, 52))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: show_page("main"))
	v.add_child(back)
	return back


# ------------------------------------------------------------ characters

func _build_characters() -> void:
	var v := _page_frame(_char_page, "SELECT_CHARACTER")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var cards: Array = []
	var i := 0
	for c in GameState.sorted_characters():
		var card := _character_card(c)
		row.add_child(card)
		cards.append(card)
		UiKit.animate_in(card, 0.05 + i * 0.08, 0.85)
		i += 1
	UiKit.focus_chain(cards, true)
	var back := _back_button(v)
	for card: Control in cards:
		card.focus_neighbor_bottom = card.get_path_to(back)
	back.focus_neighbor_top = back.get_path_to(cards[0])


func _character_card(c: CharacterData) -> Button:
	var unlocked := SaveSystem.is_unlocked(c.id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(320, 440)
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL, 0.92), Color(c.color, 0.3), 2, 18))
	b.add_theme_stylebox_override("hover", UiTheme.box(Color(UiTheme.PANEL_2, 0.97), c.color, 3, 18))
	b.add_theme_stylebox_override("focus", UiTheme.box(Color(UiTheme.PANEL_2, 0.97), c.color, 3, 18))
	b.add_theme_stylebox_override("pressed", UiTheme.box(Color(c.color, 0.3), c.color, 3, 18))
	UiKit.wire_feedback(b, 1.05)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(v)
	v.offset_left = 22
	v.offset_right = -22
	v.offset_top = 18
	v.offset_bottom = -18
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)
	var icon := Widgets.ShapeIcon.new(c.shape_sides, c.color if unlocked else UiTheme.MUTED, 110)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var name_label := UiKit.label(c.name_key, "HeaderLabel", 28, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_color_override("font_color", c.color if unlocked else UiTheme.MUTED)
	v.add_child(name_label)
	var desc := UiKit.label(c.desc_key, "MutedLabel", 16, HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	for s in [["STAT_HP", c.max_hp / 150.0], ["STAT_SPEED", c.move_speed / 300.0], ["STAT_POWER", c.damage * c.fire_rate / 45.0]]:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UiKit.label(s[0], "MutedLabel", 14)
		l.custom_minimum_size = Vector2(80, 0)
		row.add_child(l)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.value = clampf(s[1], 0.05, 1.0)
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("fill", UiTheme.box(c.color, Color.TRANSPARENT, 0, 4, Vector4.ZERO))
		row.add_child(bar)
		v.add_child(row)
	var ability := UiKit.label(c.ability_key, "AccentLabel", 17, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(ability)
	var ability_desc := UiKit.label(c.ability_key + "_DESC", "", 15, HORIZONTAL_ALIGNMENT_CENTER)
	ability_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ability_desc)
	var action := UiKit.label("SELECT" if unlocked else tr("UNLOCK_COST") % c.unlock_cost, "GoldLabel" if not unlocked else "AccentLabel", 18, HORIZONTAL_ALIGNMENT_CENTER)
	action.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	v.add_child(action)
	b.pressed.connect(func() -> void:
		if SaveSystem.is_unlocked(c.id):
			GameState.start_run(c.id)
		elif SaveSystem.spend_coins(c.unlock_cost):
			SaveSystem.unlock_character(c.id)
			SaveSystem.save_data()
			AudioManager.play_ui(&"level_up")
			GameState.check_achievements()
			_current = ""
			show_page("play", false)
		else:
			AudioManager.play_ui(&"error")
			UiKit.shake(b))
	return b


# ------------------------------------------------------------ shop

func _build_shop() -> void:
	var v := _page_frame(_shop_page, "META_SHOP")
	v.add_child(UiKit.label("META_SHOP_DESC", "MutedLabel", 17, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	var buttons: Array = []
	var i := 0
	for id in MetaShop.ids():
		var def: Dictionary = MetaShop.UPGRADES[id]
		var lvl := SaveSystem.get_meta_level(id)
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.custom_minimum_size = Vector2(480, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		panel.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UiKit.label(def["name"], "AccentLabel", 20))
		info.add_child(UiKit.label(def["desc"], "MutedLabel", 15))
		var pips := UiKit.label("■".repeat(lvl) + "□".repeat(int(def["max"]) - lvl), "GoldLabel", 18)
		info.add_child(pips)
		row.add_child(info)
		var maxed := MetaShop.is_maxed(id, lvl)
		var buy := UiKit.button(tr("MAXED") if maxed else "◆ %d" % MetaShop.cost(id, lvl), Vector2(130, 52))
		buy.disabled = maxed
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.pressed.connect(func() -> void:
			if MetaShop.buy(SaveSystem, id):
				SaveSystem.save_data()
				AudioManager.play_ui(&"coin")
				_current = ""
				show_page("shop", false)
			else:
				AudioManager.play_ui(&"error")
				UiKit.shake(panel))
		row.add_child(buy)
		grid.add_child(panel)
		if not maxed:
			buttons.append(buy)
		UiKit.animate_in(panel, i * 0.05, 0.95)
		i += 1
	_back_button(v)


# ------------------------------------------------------------ achievements

func _build_achievements() -> void:
	var v := _page_frame(_ach_page, "ACHIEVEMENTS")
	var snapshot := GameState.lifetime_snapshot()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	var i := 0
	for def in Achievements.DEFS:
		var id: StringName = def["id"]
		var got := SaveSystem.has_achievement(id)
		var panel := PanelContainer.new()
		panel.theme_type_variation = "CardPanel"
		panel.custom_minimum_size = Vector2(470, 0)
		if got:
			panel.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL_2, 0.95), Color(UiTheme.GOLD, 0.6), 2, 14, Vector4(18, 10, 18, 10)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		panel.add_child(row)
		var star := UiKit.label("★" if got else "☆", "GoldLabel", 30)
		if not got:
			star.add_theme_color_override("font_color", UiTheme.MUTED)
		row.add_child(star)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UiKit.label(Achievements.name_key(id), "AccentLabel" if got else "", 18))
		info.add_child(UiKit.label(Achievements.desc_key(id), "MutedLabel", 14))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.value = 1.0 if got else Achievements.progress(id, snapshot)
		bar.custom_minimum_size = Vector2(0, 5)
		bar.add_theme_stylebox_override("fill", UiTheme.box(UiTheme.GOLD, Color.TRANSPARENT, 0, 3, Vector4.ZERO))
		info.add_child(bar)
		row.add_child(info)
		grid.add_child(panel)
		UiKit.animate_in(panel, i * 0.04, 0.95)
		i += 1
	_back_button(v)
