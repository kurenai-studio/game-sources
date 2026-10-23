class_name Hud
extends Control
## In-battle interface: right sidebar (stats, shop, selected tower), enemy tooltips, banners, pause & end screens.

const Tooltip = preload("res://scripts/ui/tooltip.gd")
signal quit_to_menu
signal restart
signal continue_after_win

var battle: Node2D

var lives_l: Label
var cash_l: Label
var wave_l: Label
var shop_box: VBoxContainer
var shop_scroll: ScrollContainer
var shop_buttons := {}
var info_box: VBoxContainer
var info_title: Label
var info_level: Label
var info_icon: TextureRect
var info_stats: Label
var info_dealt: Label
var up_btn: Button
var up_desc: Label
var target_btn: Button
var sell_btn: Button
var start_btn: Button
var speed_btn: Button
var auto_btn: Button
var tip: Control
var banner: Label
var banner_t := 0.0
var pause_layer: Control
var end_layer: Control
var cheat_layer: Control
var hint_l: Label
var shop_order: Array = []   # unlocked towers only, in shop order (keys 1..N)
var boss_bar: Control
var settings_layer: Control
var cheats := false


func setup(b: Node2D) -> void:
	battle = b
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_sidebar()
	banner = UI.title("", 16)
	banner.position = Vector2(0, 120)
	banner.size = Vector2(512, 24)
	banner.visible = false
	add_child(banner)
	hint_l = UI.label("", 10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER)
	hint_l.position = Vector2(0, 344)
	hint_l.size = Vector2(512, 12)
	add_child(hint_l)
	boss_bar = Control.new()
	boss_bar.position = Vector2(96, 4)
	boss_bar.size = Vector2(320, 40)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.draw.connect(_draw_boss_bars)
	add_child(boss_bar)
	tip = Tooltip.new()
	add_child(tip)
	battle.stats_changed.connect(_refresh)
	battle.selection_changed.connect(_refresh_selection)
	battle.announce.connect(_announce)
	battle.ended.connect(_on_ended)
	_refresh()
	_refresh_selection()
	_announce("%s - %s" % [battle.map["name"], battle.diff["name"]], battle.diff["color"])


# ---------------------------------------------------------------- sidebar
func _build_sidebar() -> void:
	var side := UI.panel("panel", 5)
	side.position = Vector2(512, 0)
	side.size = Vector2(128, 360)
	side.custom_minimum_size = Vector2(128, 360)
	side.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(side)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	side.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 1)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stats)
	lives_l = _stat_row(stats, "heart", Color("f6757a"))
	cash_l = _stat_row(stats, "coin", Color("fee761"))
	wave_l = _stat_row(stats, "wave", Color.WHITE)
	var pause_b := UI.button("", "gray", Vector2(20, 20))
	pause_b.icon = load("res://assets/ui/icons/pause.png")
	pause_b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pause_b.pressed.connect(toggle_pause)
	pause_b.tooltip_text = "Pause"
	top.add_child(pause_b)

	# shop
	shop_box = VBoxContainer.new()
	shop_box.add_theme_constant_override("separation", 3)
	shop_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_box.size_flags_stretch_ratio = 1000.0   # takes the room of the spacer below while it is shown
	v.add_child(shop_box)
	shop_box.add_child(UI.label("TOWERS", 10, Color("8b9bb4")))
	for t in Defs.TOWER_ORDER:
		if Game.is_tower_unlocked(t):
			shop_order.append(t)
	# up to 7 towers fit above the wave buttons; with more the list scrolls (mouse wheel or the bar)
	var scrolls := shop_order.size() > 7
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_box.add_child(scroll)
	shop_scroll = scroll
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	var bh := 32 if shop_order.size() <= 6 else 28
	UI.style_scrollbar(scroll.get_v_scroll_bar(), bh + 3)   # an arrow click moves the list by one tower
	for t in shop_order:
		var b := UI.button("", "blue", Vector2(110 if scrolls else 118, bh))
		b.icon = Game.tex("res://assets/sprites/towers/%s.png" % Defs.TOWERS[t]["sprite"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("icon_max_width", 22)
		b.pressed.connect(func(): _on_shop(t))
		b.mouse_entered.connect(func(): _shop_tip(t, b))
		b.mouse_exited.connect(func(): tip.hide_tip())
		list.add_child(b)
		shop_buttons[t] = b

	# selected tower info
	info_box = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 2)
	info_box.visible = false
	info_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.size_flags_stretch_ratio = 1000.0   # like the shop: takes the spacer's room while shown
	v.add_child(info_box)
	var head := HBoxContainer.new()
	info_box.add_child(head)
	info_icon = TextureRect.new()
	info_icon.custom_minimum_size = Vector2(22, 26)
	info_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	head.add_child(info_icon)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	info_title = UI.label("", 10, Color("fee761"))
	hv.add_child(info_title)
	info_level = UI.label("", 10, Color("8b9bb4"))
	hv.add_child(info_level)
	var close := UI.button("x", "gray", Vector2(14, 14))
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL | Control.SIZE_SHRINK_END
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(func(): battle.select(null))
	head.add_child(close)
	# stats and the next upgrade's text scroll when they're long; the buttons below always stay on screen
	var info_scroll := ScrollContainer.new()
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.style_scrollbar(info_scroll.get_v_scroll_bar(), 12)   # an arrow click moves one line
	info_box.add_child(info_scroll)
	var info_text := VBoxContainer.new()
	info_text.add_theme_constant_override("separation", 2)
	info_scroll.add_child(info_text)
	info_stats = UI.label("", 10, Color("c0cbdc"))
	info_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_stats.custom_minimum_size = Vector2(108, 0)   # room for the scrollbar
	info_text.add_child(info_stats)
	info_dealt = UI.label("", 10, Color("8b9bb4"))
	info_text.add_child(info_dealt)
	up_desc = UI.label("", 10, Color.WHITE)
	up_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	up_desc.custom_minimum_size = Vector2(108, 0)
	info_text.add_child(up_desc)
	up_btn = UI.button("", "green", Vector2(118, 18))
	up_btn.icon = load("res://assets/ui/icons/up.png")
	up_btn.pressed.connect(_on_upgrade)
	info_box.add_child(up_btn)
	target_btn = UI.button("", "purple", Vector2(118, 16))
	target_btn.pressed.connect(_on_target)
	info_box.add_child(target_btn)
	sell_btn = UI.button("", "red", Vector2(118, 16))
	sell_btn.pressed.connect(_on_sell)
	info_box.add_child(sell_btn)
	for b in [up_btn, target_btn, sell_btn]:   # never wider than the sidebar, whatever the text
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)

	start_btn = UI.button("START WAVE", "green", Vector2(118, 22), 10)
	start_btn.icon = load("res://assets/ui/icons/play.png")
	start_btn.pressed.connect(func(): battle.start_wave())
	v.add_child(start_btn)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	v.add_child(row)
	speed_btn = UI.button("1x", "blue", Vector2(58, 16))
	speed_btn.icon = load("res://assets/ui/icons/ff.png")
	speed_btn.pressed.connect(_on_speed)
	row.add_child(speed_btn)
	auto_btn = UI.button("Auto", "gray", Vector2(58, 16))
	auto_btn.pressed.connect(_on_auto)
	auto_btn.tooltip_text = "Start next wave automatically"
	row.add_child(auto_btn)


func _stat_row(parent: Control, icon_name: String, col: Color) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	parent.add_child(h)
	var ic := UI.icon(icon_name)
	ic.custom_minimum_size = Vector2(10, 10)
	h.add_child(ic)
	var l := UI.label("", 10, col)
	h.add_child(l)
	return l


# ---------------------------------------------------------------- refresh
func _refresh() -> void:
	up_btn.tooltip_text = "Upgrade (%s)" % Game.key_label("upgrade")
	sell_btn.tooltip_text = "Sell (%s)" % Game.key_label("sell")
	target_btn.tooltip_text = "Targeting mode (%s)" % Game.key_label("target")
	lives_l.text = str(battle.lives)
	cash_l.text = "$%d" % battle.cash
	wave_l.text = "Wave %d/%d" % [battle.wave, battle.total_waves]
	for t in shop_buttons:
		var b: Button = shop_buttons[t]
		var cost: int = battle.tower_cost(t)
		var n: int = battle.tower_count(t)
		b.text = "%s\n$%d%s" % [Defs.TOWERS[t]["name"], cost, ("   %d/%d" % [n, battle.type_limit(t)]) if n > 0 else ""]
		b.disabled = battle.cash < cost or battle.limit_reason(t) != ""
	_refresh_selection()


func _refresh_selection() -> void:
	var tw = battle.selected
	var has: bool = tw != null and is_instance_valid(tw)
	info_box.visible = has
	shop_box.visible = not has
	if not has:
		return
	info_icon.texture = tw.sprite.texture
	info_title.text = tw.def["name"]
	info_level.text = "Level %d/%d" % [tw.level + 1, tw.max_level() + 1]
	info_level.add_theme_color_override("font_color", Defs.level_color(tw.level, tw.max_level()))
	info_stats.text = _stats_text(tw.type, tw.stats)
	info_dealt.text = ("Earned $%s" % _short(tw.earned)) if tw.type == "farm" else \
		"Dmg %s  Kills %d" % [_short(tw.damage_dealt), tw.kills]
	var up: Dictionary = tw.next_upgrade()
	if up.is_empty():
		up_btn.text = "MAX LEVEL"
		up_btn.disabled = true
		up_desc.text = "Fully upgraded."
	else:
		var c: int = battle.upgrade_cost(tw)
		up_btn.text = "Upgrade $%d" % c   # the name goes in the text above: long ones widened the panel
		up_btn.disabled = battle.cash < c
		up_desc.text = "Next: %s. %s" % [up["name"], up["desc"]]
	target_btn.text = "Target: %s" % tw.TARGET_NAMES[tw.target_mode]
	target_btn.visible = tw.type != "farm"   # a farm doesn't aim at anything
	if float(battle.diff["sell"]) > 0.0:
		sell_btn.text = "Sell $%d" % battle.sell_value(tw)
		sell_btn.disabled = false
	else:
		sell_btn.text = "No selling"
		sell_btn.disabled = true


func _short(v: float) -> String:
	if v >= 10000:
		return "%.1fk" % (v / 1000.0)
	return str(int(v))


static func _stats_text(t: String, s: Dictionary) -> String:
	var txt := _stats_core(t, s)
	var dps := Defs.tower_dps(t, s)
	if dps > 0.0:
		var note := ""
		if t in ["flamer", "freezer"] or (t == "knight" and s["cleave"]):
			note = " (each enemy hit)"
		elif t == "minigun":
			note = " (spun up)"
		elif t == "gunner" and int(s["targets"]) > 1:   # per target: the sum read like boss damage
			dps /= float(s["targets"])
			note = " x%d targets" % s["targets"]
		elif t == "garage":
			note = " (crashes + turret)" if float(s["gun_dmg"]) > 0.0 else " (crashes)"
		txt = "DPS %s%s\n%s" % [UI.fmt_num(snappedf(dps, 0.1) if dps < 10.0 else roundf(dps)), note, txt]
	var sees: Array = []
	if s.get("camo", false) and t != "garage":
		sees.append("Invisible")
	if s.get("air", false):
		sees.append("Flying")
	if t == "flamer":
		txt += "\nGround only. Can't aim at invisible\nbut the flames still burn them"
	elif t == "freezer":
		txt += "\nGround only. Can't aim at invisible\nbut the water still soaks them"
	elif t == "assassin":
		txt += "\nBlades: ground" + (" + invisible" if s.get("camo", false) else "")
		if int(s["daggers"]) > 0:
			txt += "\nDaggers: ground + flying" + (" + invisible" if s.get("camo", false) else "")
	elif t == "farm":
		return txt
	elif t == "garage":
		txt += "\nRuns over invisible, not flying"
	elif t != "garage":
		txt += "\nHits: " + ("ground" if sees.is_empty() else "ground + " + ", ".join(sees).to_lower())
	txt += "\nPierces LEAD" if s.get("lead", false) else "\nCan't hurt LEAD"
	return txt


static func _acid_text(s: Dictionary) -> String:
	return "Acid %s dps %ss, eats %d armor" % [UI.fmt_num(s["acid_dps"]), UI.fmt_num(s["acid_time"]), s["acid_shred"]]


static func _stats_core(t: String, s: Dictionary) -> String:
	match t:
		"gunner":
			var txt := "Dmg %s  Rate %s/s\nRange %d" % [UI.fmt_num(s["damage"]), UI.fmt_num(s["rate"]), s["range"]]
			if int(s["targets"]) > 1:
				txt += "  Targets %d" % s["targets"]
			if s["slow"] > 0.0:
				txt += "\nSlow %d%% %ss (control)" % [int(s["slow"] * 100), UI.fmt_num(s["slow_time"])]
			return txt
		"knight":
			var txt := "Dmg %s  Rate %s/s\nRange %d  Armor pierce %d%%" % [UI.fmt_num(s["damage"]),
				UI.fmt_num(s["rate"]), s["range"], int(s["armor_pierce"] * 100)]
			txt += "\nStun %ss every %d hits" % [UI.fmt_num(s["stun"]), s["stun_every"]]
			if s["cleave"]:
				txt += "\nCleave: hits all in range"
			if s["aura"] > 0.0:
				txt += "\nAura: towers nearby +%d%% dmg" % int(s["aura"] * 100)
			return txt
		"soldier":
			var txt := "Dmg %s x%d burst  %s/s\nRange %d" % [UI.fmt_num(s["damage"]), s["burst"],
				UI.fmt_num(s["rate"]), s["range"]]
			if s["armor_pierce"] > 0.0:
				txt += "  Armor pierce %d%%" % int(s["armor_pierce"] * 100)
			if int(s["grenade_every"]) > 0:
				txt += "\nGrenade %d dmg every %d bursts" % [s["grenade_dmg"], s["grenade_every"]]
			return txt
		"farm":
			return "Pays $%d at the end\nof every wave" % s["income"]
		"minigun":
			var txt := "Dmg %s  %s > %s shots/s\nSpins up in %ss  Range %d" % [UI.fmt_num(s["damage"]),
				UI.fmt_num(s["min_rate"]), UI.fmt_num(s["max_rate"]), UI.fmt_num(s["spin_time"]), s["range"]]
			if s["armor_pierce"] > 0.0:
				txt += "\nArmor pierce %d%%" % int(s["armor_pierce"] * 100)
			return txt
		"garage":
			var txt := "%s every %ss\nCar HP %d (crash: both lose\nthe weaker one's HP)" % [
				String(s["vehicle"]).capitalize(), UI.fmt_num(s["interval"]), s["car_hp"]]
			if s["gun_dmg"] > 0:
				txt += "\nTurret %d dmg x%s/s" % [s["gun_dmg"], UI.fmt_num(s["gun_rate"])]
			return txt
		"flamer":
			var txt := "Spray %s dps  Range %d\nBurn %s dps for %ss" % [UI.fmt_num(s["damage"] * 10.0), s["range"],
				UI.fmt_num(s["burn"]), UI.fmt_num(s["burn_time"])]
			if s["fire_pierce"] > 0.0:
				txt += "\nIgnores %d%% fire resist" % int(s["fire_pierce"] * 100)
			return txt
		"freezer":
			var txt := "Chill %d%%/s  Range %d\nSlow up to %d%%, frozen %ss" % [int(s["chill"] * 100), s["range"],
				int(s["chill_slow"] * 100), UI.fmt_num(s["freeze"])]
			if s["damage"] > 0.0:
				txt += "\nCold %s dps, ignores armor" % UI.fmt_num(s["damage"] * 10.0)
			if s["brittle"] > 0.0:
				txt += "\nFrozen take +%d%% damage" % int(s["brittle"] * 100)
			txt += "\nPuts out fire, fire melts ice"
			return txt
		"toxic":
			var txt := "Dmg %s  Rate %s/s\nRange %d" % [UI.fmt_num(s["damage"]), UI.fmt_num(s["rate"]), s["range"]]
			txt += "\n" + _acid_text(s)
			if s["splash"] > 0.0:
				txt += "\nSplash %d px" % s["splash"]
			return txt
		"assassin":
			var txt := "Dmg %s  Rate %s/s\nRange %d  Armor pierce %d%%" % [UI.fmt_num(s["damage"]),
				UI.fmt_num(s["rate"]), s["range"], int(s["armor_pierce"] * 100)]
			txt += "\n" + _acid_text(s)
			if int(s["daggers"]) > 0:
				txt += "\nDaggers %d x%d, %s/s, range %d" % [s["dagger_dmg"], s["daggers"], UI.fmt_num(s["dagger_rate"]),
					s["dagger_range"]]
			return txt
		"sniper":
			var txt := "Dmg %s  Rate %s/s\nRange %d  Armor pierce %d%%" % [UI.fmt_num(s["damage"]),
				UI.fmt_num(s["rate"]), s["range"], int(s["armor_pierce"] * 100)]
			if s["headshot"] > 0.0:
				txt += "\nHeadshot %d%% (non-boss)" % int(s["headshot"] * 100)
			return txt
		"necro":
			var txt := "Dmg %s  Rate %s/s\nRange %d  Armor pierce %d%%" % [UI.fmt_num(s["damage"]),
				UI.fmt_num(s["rate"]), s["range"], int(s["armor_pierce"] * 100)]
			txt += "\nRaises class I-%s with %d%% HP" % [Defs.CLASS_ROMAN[int(s["raise_class"])],
				int(s["raise_hp"] * 100)]
			return txt
	return ""


# ---------------------------------------------------------------- actions
func _on_shop(t: String) -> void:
	if not shop_order.has(t):
		return
	if battle.placing == t:
		battle.placing = ""
	else:
		battle.begin_place(t)


func _on_upgrade() -> void:
	var tw = battle.selected
	if tw and battle.upgrade_tower(tw):
		_refresh_selection()
	else:
		Sfx.play("error")


func _on_target() -> void:
	var tw = battle.selected
	if tw:
		tw.target_mode = (tw.target_mode + 1) % 4
		Sfx.play("click")
		_refresh_selection()


func _on_sell() -> void:
	var tw = battle.selected
	if tw:
		battle.sell_tower(tw)


func _on_speed() -> void:
	battle.speed = 1 if battle.speed >= 3 else battle.speed + 1
	speed_btn.text = "%dx" % battle.speed


func _on_auto() -> void:
	battle.auto_start = not battle.auto_start
	UI.color_button(auto_btn, "green" if battle.auto_start else "gray")
	if battle.auto_start and battle.can_start_wave() and not battle.has_hostiles() and battle.wave > 0:
		battle.auto_t = 0.5


func toggle_pause() -> void:
	if battle.over:
		return
	if settings_layer or cheat_layer:
		return
	battle.paused = not battle.paused
	if battle.paused:
		_show_pause()
	elif pause_layer:
		pause_layer.queue_free()
		pause_layer = null


func _announce(text: String, col: Color) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", col)
	banner.visible = true
	banner_t = 2.0


# ---------------------------------------------------------------- per-frame
func _process(delta: float) -> void:
	if banner_t > 0.0:
		banner_t -= delta
		banner.visible = banner_t > 0.0
		banner.modulate.a = clampf(banner_t * 2.0, 0.0, 1.0)
	start_btn.disabled = not battle.can_start_wave()
	speed_btn.text = "%dx" % battle.speed
	if battle.wave == 0:
		start_btn.text = "START"
	elif battle.spawning:
		start_btn.text = "WAVE %d..." % battle.wave
	else:
		start_btn.text = "NEXT WAVE"
	# live refresh of affordability / info
	if Engine.get_process_frames() % 10 == 0:
		_refresh()
	if battle.placing != "":
		hint_l.text = "Click to place %s  -  Right click to cancel" % Defs.TOWERS[battle.placing]["name"]
	elif battle.wave == 0:
		hint_l.text = "Buy towers on the right, then press START"
	else:
		hint_l.text = ""
	_update_tooltip()
	boss_bar.queue_redraw()


func _draw_boss_bars() -> void:
	var f := UI.font()
	var y := 0.0
	for e in battle.enemies:
		if not e.alive or not e.final_boss:
			continue
		var w := 320.0
		var name: String = e.display_name().to_upper()
		boss_bar.draw_style_box(UI.box("panel_dark"), Rect2(0, y, w, 20))
		boss_bar.draw_string(f, Vector2(6, y + 9), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fee761"))
		var cls_t: String = "Class " + Defs.CLASS_ROMAN[e.cls]
		var hp_t := "%d / %d" % [ceili(e.hp), int(e.max_hp)]
		var hw := f.get_string_size(hp_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		boss_bar.draw_string(f, Vector2(w - 6 - hw, y + 9), hp_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		var cw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		boss_bar.draw_string(f, Vector2(12 + cw, y + 9), cls_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Defs.CLASS_COLORS[e.cls])
		var bw := w - 12
		var frac := clampf(e.hp / e.max_hp, 0.0, 1.0)
		boss_bar.draw_rect(Rect2(6, y + 12, bw, 5), Color("181425"))
		boss_bar.draw_rect(Rect2(7, y + 13, bw - 2, 3), Color("3a4466"))
		var col := Color("e43b44") if e.flash_t <= 0.0 else Color.WHITE
		boss_bar.draw_rect(Rect2(7, y + 13, roundf((bw - 2) * frac), 3), col)
		boss_bar.draw_rect(Rect2(7, y + 13, roundf((bw - 2) * frac), 1), Color("f6757a") if e.flash_t <= 0.0 else Color.WHITE)
		y += 22


func _update_tooltip() -> void:
	if battle.paused or battle.over:
		if tip.visible and not _shop_hovered():
			tip.hide_tip()
		return
	var m := get_global_mouse_position()
	if m.x >= 512:
		return
	var e = battle.enemy_at(battle.get_local_mouse_position())
	if e:
		tip.show_lines(enemy_lines(e), m)
		return
	var tw = battle.hovered_tower
	if tw and is_instance_valid(tw) and battle.placing == "":
		tip.show_lines([{"t": tw.def["name"], "c": Color("fee761"), "r": "Lv. %d" % (tw.level + 1),
			"rc": Color("8b9bb4")}, {"t": "Click to select", "c": Color("8b9bb4")}], m)
		return
	tip.hide_tip()


func _shop_hovered() -> bool:
	for b in shop_buttons.values():
		if b.is_hovered():
			return true
	return false


static func enemy_lines(e) -> Array:
	if e.is_friendly:
		return _friendly_lines(e)
	var cls: int = e.cls
	var lines: Array = []
	lines.append({"t": e.display_name(), "c": Color.WHITE, "r": "Class " + Defs.CLASS_ROMAN[cls],
		"rc": Defs.CLASS_COLORS[cls]})
	var f: float = clampf(e.hp / e.max_hp, 0, 1)
	lines.append({"t": "HP", "c": Color("8b9bb4"), "r": "%d / %d" % [ceili(e.hp), int(e.max_hp)],
		"rc": Color("63c74d")})
	lines.append({"bar": f, "bc": Color("63c74d") if f > 0.5 else (Color("feae34") if f > 0.25 else Color("e43b44"))})
	lines.append({"t": "Speed", "c": Color("8b9bb4"), "r": str(int(e.speed)), "rc": Color.WHITE})
	if e.armor > 0:
		var eaten: bool = e.cur_armor() < e.armor
		lines.append({"t": "Armor", "c": Color("8b9bb4"),
			"r": ("%d (of %d)" % [int(e.cur_armor()), int(e.armor)]) if eaten else str(int(e.armor)),
			"rc": Color("63c74d") if eaten else Color("c0cbdc")})
	if e.fire_res > 0:
		lines.append({"t": "Fire resist", "c": Color("8b9bb4"),
			"r": "IMMUNE" if e.fire_res >= 1.0 else "%d%%" % int(e.fire_res * 100), "rc": Color("f77622")})
	lines.append({"t": "Control effects", "c": Color("8b9bb4"), "r": "%d%%" % int(Defs.CLASS_EFFECT[cls] * 100),
		"rc": Defs.CLASS_COLORS[cls]})
	if e.bloated:
		lines.append({"t": "+ BLOATED: x%s HP" % UI.fmt_num(Defs.BLOATED_HP), "c": Color("b55088")})
	if e.lead:
		lines.append({"t": "+ LEAD: only lead-piercing towers,", "c": Color("c0cbdc")})
		lines.append({"t": "  fire and acid hurt it", "c": Color("c0cbdc")})
	if e.flying:
		lines.append({"t": "+ FLYING", "c": Color("c0cbdc")})
	if e.invisible:
		lines.append({"t": "+ INVISIBLE", "c": Color("8bc8e8")})
	if e.def.has("revive"):
		lines.append({"t": "+ Gets back up once" if e.revives > 0 else "+ Already got back up", "c": Color("ead4aa")})
	if e.rage > 0.0:
		lines.append({"t": "+ ENRAGED: x%s speed" % UI.fmt_num(e.rage) if e.is_enraged() else "+ Enrages below 50% HP",
			"c": Color("e43b44")})
	if e.def.has("heal"):
		lines.append({"t": "+ Heals nearby enemies", "c": Color("63c74d")})
	if e.def.has("regen"):
		lines.append({"t": "+ Regenerates %d%%/s (not burning or in acid)" % int(float(e.def["regen"]) * 100),
			"c": Color("63c74d")})
	if e.def.has("split"):
		lines.append({"t": "+ Splits into %d slimes" % e.def["split"], "c": Color("0099db")})
	var st: Array = []
	if e.stun_t > 0:
		st.append({"t": "STUNNED %.1fs" % e.stun_t, "c": Color("fee761")})
	if e.slow_t > 0:
		st.append({"t": "SLOWED %d%%" % int(e.slow_f * 100), "c": Color("2ce8f5")})
	if e.frozen_t > 0:
		st.append({"t": "FROZEN %.1fs" % e.frozen_t, "c": Color("8bd8f0")})
	elif e.chill > 0:
		st.append({"t": "CHILLED %d%% (slow %d%%)" % [int(e.chill * 100), int(e.chill * e.chill_slow * 100)],
			"c": Color("8bd8f0")})
	if e.acid_t > 0:
		st.append({"t": "ACID %s/s, armor -%d" % [UI.fmt_num(e.acid_dps), int(e.acid_shred)], "c": Color("63c74d")})
	if e.burn_t > 0:
		st.append({"t": "BURNING %s/s" % UI.fmt_num(e.burn_dps * (1.0 - e.fire_res * (1.0 - e.burn_pierce))),
			"c": Color("f77622")})
	if not st.is_empty():
		lines.append({"t": ""})
		lines.append_array(st)
	lines.append({"t": ""})
	lines.append({"t": e.def["desc"], "c": Color("5a6988"), "wrap": true})
	return lines


static func _friendly_lines(e) -> Array:
	var f: float = clampf(e.hp / e.max_hp, 0, 1)
	var nm: String = ("Undead " + e.display_name()) if e.undead else e.def["name"]
	var lines: Array = [{"t": nm, "c": Color.WHITE, "r": "FRIENDLY", "rc": Color("63c74d")}]
	lines.append({"t": "HP", "c": Color("8b9bb4"), "r": "%d / %d" % [ceili(e.hp), int(e.max_hp)],
		"rc": Color("63c74d")})
	lines.append({"bar": f, "bc": Color("0099db")})
	lines.append({"t": "Speed", "c": Color("8b9bb4"), "r": str(int(e.speed)), "rc": Color.WHITE})
	if float(e.stats.get("gun_dmg", 0)) > 0:
		lines.append({"t": "Turret", "c": Color("8b9bb4"), "r": "%d dmg" % int(e.stats["gun_dmg"]), "rc": Color.WHITE})
	lines.append({"t": ""})
	if e.undead:
		lines.append({"t": "Raised by a Necromancer. Walks back and crashes into enemies.", "c": Color("63c74d"),
			"wrap": true})
	lines.append({"t": "Crash: both lose the HP of the weaker one.", "c": Color("5a6988"), "wrap": true})
	return lines


func _shop_tip(t: String, b: Button) -> void:
	var d: Dictionary = Defs.TOWERS[t]
	var lines: Array = [{"t": d["name"], "c": Color("fee761"), "r": "$%d" % battle.tower_cost(t),
		"rc": Color("feae34")}, {"t": d["role"], "c": Color("8b9bb4")}, {"t": ""},
		{"t": d["desc"], "c": Color.WHITE, "wrap": true}, {"t": ""}]
	for l in _stats_text(t, d["base"]).split("\n"):
		lines.append({"t": l, "c": Color("c0cbdc")})
	tip.show_lines(lines, Vector2(b.global_position.x - 140, b.global_position.y))
	tip.position.x = b.global_position.x - tip.size.x - 6


# ---------------------------------------------------------------- input
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:   # fixed: cancel -> deselect -> pause
		if battle.placing != "":
			battle.placing = ""
		elif battle.selected:
			battle.select(null)
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	var action := Game.action_for(event)
	if action == "":
		return
	if battle.paused and action != "pause":
		return
	match action:
		"pause":
			toggle_pause()
		"next_wave":
			battle.start_wave()
		"speed":
			_on_speed()
		"upgrade":
			if battle.selected:
				_on_upgrade()
		"sell":
			if battle.selected:
				_on_sell()
		"target":
			if battle.selected:
				_on_target()
		_:
			if action.begins_with("tower_"):
				var k := int(action.substr(6)) - 1
				if k < shop_order.size():
					_on_shop(shop_order[k])
	get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- overlays
func _overlay() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(UI.dim_rect(0.6))
	add_child(root)
	return root


func _center_panel(root: Control, w: float) -> VBoxContainer:
	var p := UI.panel("panel", 10)
	p.custom_minimum_size = Vector2(w, 0)
	root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	p.resized.connect(func(): p.position = ((Vector2(640, 360) - p.size) / 2.0).round())
	return v


func _open_settings() -> void:
	pause_layer.visible = false
	settings_layer = SettingsScreen.new()
	add_child(settings_layer)
	settings_layer.closed.connect(func():
		settings_layer.queue_free()
		settings_layer = null
		if pause_layer:
			pause_layer.visible = true
		_refresh())

func _open_cheats() -> void:
	pause_layer.visible = false
	cheat_layer = _overlay()
	var v := _center_panel(cheat_layer, 250)
	v.add_child(UI.title("Cheats", 16))
	v.add_child(UI.label("Wins after cheating are not saved", 10, Color("8b9bb4"), HORIZONTAL_ALIGNMENT_CENTER))
	# jump to any wave
	var target := [mini(battle.wave + 1, battle.total_waves)]
	var wave_l := UI.label("", 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	wave_l.custom_minimum_size.x = 60
	var show_wave := func(): wave_l.text = "Wave %d/%d" % [target[0], battle.total_waves]
	var wr := _cheat_row(v)
	for d in [-10, -1]:
		_cheat_btn(wr, "%d" % d, "gray", func():
			target[0] = clampi(target[0] + d, 1, battle.total_waves)
			show_wave.call())
	wr.add_child(wave_l)
	for d in [1, 10]:
		_cheat_btn(wr, "+%d" % d, "gray", func():
			target[0] = clampi(target[0] + d, 1, battle.total_waves)
			show_wave.call())
	show_wave.call()
	_cheat_btn(_cheat_row(v), "Go to wave", "green", func():
		battle.cheat_jump_to_wave(target[0])
		battle.stats_changed.emit())
	# money and lives
	var mr := _cheat_row(v)
	mr.add_child(UI.label("Money", 10, Color("fee761")))
	for amt in [100, 1000, 10000]:
		_cheat_btn(mr, "+%d" % amt, "gold", func():
			battle.cash += amt
			battle.cheated = true
			battle.stats_changed.emit())
	var lr := _cheat_row(v)
	lr.add_child(UI.label("Lives", 10, Color("f6757a")))
	for amt in [10, 100]:
		_cheat_btn(lr, "+%d" % amt, "red", func():
			battle.lives += amt
			battle.cheated = true
			battle.stats_changed.emit())
	# the rest
	var ar := _cheat_row(v)
	_cheat_btn(ar, "Next wave now", "blue", func(): battle.start_wave(true))
	_cheat_btn(ar, "Clear enemies", "blue", func(): battle.cheat_clear_enemies())
	_cheat_btn(_cheat_row(v), "Win battle", "purple", func():
		toggle_cheats()
		toggle_pause()
		battle.cheat_win())
	var q := UI.button("Back", "red", Vector2(0, 20))
	q.pressed.connect(toggle_cheats)
	v.add_child(q)


func _cheat_row(v: VBoxContainer) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", 3)
	v.add_child(r)
	return r


func _cheat_btn(row: HBoxContainer, text: String, color: String, fn: Callable) -> void:
	var b := UI.button(text, color, Vector2(0, 18))
	b.custom_minimum_size.x = maxf(34.0, UI.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0)
	b.pressed.connect(fn)
	row.add_child(b)


func toggle_cheats() -> void:
	if cheat_layer:
		cheat_layer.queue_free()
		cheat_layer = null
		pause_layer.visible = true
	else:
		_open_cheats()

func _show_pause() -> void:
	pause_layer = _overlay()
	var v := _center_panel(pause_layer, 180)
	v.add_child(UI.title("PAUSED", 16))
	v.add_child(UI.label("%s - %s" % [battle.map["name"], battle.diff["name"]], 10, Color("8b9bb4"),
		HORIZONTAL_ALIGNMENT_CENTER))
	var r := UI.button("Resume", "green", Vector2(0, 20))
	r.pressed.connect(toggle_pause)
	v.add_child(r)
	var rs := UI.button("Restart", "blue", Vector2(0, 20))
	rs.pressed.connect(func(): restart.emit())
	v.add_child(rs)
	var st := UI.button("Settings", "gray", Vector2(0, 20))
	st.pressed.connect(_open_settings)
	v.add_child(st)
	var q := UI.button("Quit to menu", "red", Vector2(0, 20))
	q.pressed.connect(func(): quit_to_menu.emit())
	v.add_child(q)
	if cheats:
		var c := UI.button("Cheats", "purple", Vector2(0, 20))
		c.pressed.connect(_open_cheats)
		v.add_child(c)


func _on_ended(win: bool, newly: Array) -> void:
	tip.hide_tip()
	await get_tree().create_timer(0.8).timeout
	end_layer = _overlay()
	var v := _center_panel(end_layer, 240)
	if win:
		v.add_child(UI.title("VICTORY!", 16, Color("fee761")))
		var cnt := UI.button("Continue", "green", Vector2(90, 20))
		cnt.pressed.connect(func(): continue_after_win.emit())
		v.add_child(cnt)
	else:
		v.add_child(UI.title("DEFEAT", 16, Color("e43b44")))
	v.add_child(UI.label("%s - %s" % [battle.map["name"], battle.diff["name"]], 10, battle.diff["color"],
		HORIZONTAL_ALIGNMENT_CENTER))
	var info := "Waves survived: %d/%d\nEnemies defeated: %d" % [battle.wave if win else maxi(0, battle.wave - 1),
		battle.total_waves, battle.kills]
	v.add_child(UI.label(info, 10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER))
	if win:
		var medals := HBoxContainer.new()
		medals.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(medals)
		for d in Defs.DIFFICULTIES.size():
			var ic := UI.icon("star" if Game.is_beaten(battle.map_id, d) else "star_off")
			if Game.is_beaten(battle.map_id, d):
				ic.modulate = Defs.DIFFICULTIES[d]["color"].lightened(0.3)
			medals.add_child(ic)
	if Game.last_reward > 0:
		var rh := HBoxContainer.new()
		rh.alignment = BoxContainer.ALIGNMENT_CENTER
		rh.add_theme_constant_override("separation", 3)
		v.add_child(rh)
		rh.add_child(UI.label("+%d" % Game.last_reward, 10, Color("fee761")))
		rh.add_child(UI.icon("map"))
		rh.add_child(UI.label("paper maps (%d total)" % Game.paper_maps, 10, Color("c0cbdc")))
	for t in newly:
		Sfx.play("unlock")
		var box := UI.panel("card_selected", 6)
		v.add_child(box)
		var h := HBoxContainer.new()
		box.add_child(h)
		h.add_child(UI.sprite_rect("res://assets/sprites/towers/%s.png" % Defs.TOWERS[t]["sprite"], 2))
		var tv := VBoxContainer.new()
		h.add_child(tv)
		tv.add_child(UI.label("NEW TOWER FOR SALE!", 10, Color("fee761")))
		tv.add_child(UI.label("%s: buy it in the Armory for %d paper maps" % [Defs.TOWERS[t]["name"],
			Game.tower_price(t)], 10, Color.WHITE))
		tv.add_child(UI.label(Defs.TOWERS[t]["role"], 10, Color("c0cbdc")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var again := UI.button("Play again", "blue", Vector2(90, 20))
	again.pressed.connect(func(): restart.emit())
	row.add_child(again)
	var menu := UI.button("Menu", "green", Vector2(90, 20))
	menu.pressed.connect(func(): quit_to_menu.emit())
	row.add_child(menu)
