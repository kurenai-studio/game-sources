class_name StoryHud
extends CanvasLayer
# ---------- Экран Истории поверх игры ----------
# Слева сверху — имя, уровень, здоровье, мана, опыт и текущее задание.
# Справа сверху — «Рюкзак», «Задания», «Меню». Внизу — кнопки управления
# (на телефоне), подсказка взаимодействия, всплывающие сообщения и окна.

signal inv_pressed
signal quests_pressed
signal menu_pressed
signal dialog_closed

var mode
var _vs := Vector2.ZERO
var _name: Label
var _hp_fill: ColorRect
var _hp_text: Label
var _mp_fill: ColorRect
var _mp_text: Label
var _xp_fill: ColorRect
var _xp_text: Label
var _quest: Label
var _quest_bg: Panel
var _toast: Label
var _toast_t := 0.0
var _banner: Label
var _banner_t := 0.0
var _prompt: Label
var _dialog: Panel
var _dialog_box: VBoxContainer
var _btn_layer: Node
var ui := {}
var _keys: Label

const BAR_W := 300.0

func _ready() -> void:
	layer = 6
	_vs = Config.screen(self)
	# ----- панель героя -----
	var panel := Panel.new()
	panel.position = Vector2(12, 10)
	panel.size = Vector2(BAR_W + 28, 112)
	panel.add_theme_stylebox_override("panel", box(Color(0.08, 0.07, 0.09, 0.72), Color(0.75, 0.58, 0.3, 0.9)))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_name = _label(Vector2(26, 14), 20, Color(1.0, 0.9, 0.6))
	var hp := _bar(Vector2(26, 44), 18.0, Color(0.85, 0.2, 0.22))
	_hp_fill = hp[0]
	_hp_text = hp[1]
	var mp := _bar(Vector2(26, 68), 14.0, Color(0.25, 0.45, 1.0))
	_mp_fill = mp[0]
	_mp_text = mp[1]
	var xp := _bar(Vector2(26, 88), 10.0, Color(1.0, 0.78, 0.25))
	_xp_fill = xp[0]
	_xp_text = xp[1]
	var qbg := Panel.new()
	qbg.position = Vector2(12, 126)
	qbg.size = Vector2(BAR_W + 28, 10)
	qbg.add_theme_stylebox_override("panel", box(Color(0.08, 0.07, 0.09, 0.55), Color(0, 0, 0, 0), 8, 0))
	qbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(qbg)
	_quest_bg = qbg
	_quest = _label(Vector2(22, 130), 15, Color(1, 0.96, 0.85))
	_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest.update_minimum_size()
	_quest.size = Vector2(BAR_W + 12, 80)
	# ----- кнопки справа сверху -----
	var x := _vs.x - 12.0
	for b in [["Меню", "menu", 110.0], ["Задания", "quests", 140.0], ["Рюкзак", "inv", 140.0]]:
		x -= b[2]
		var btn := Button.new()
		btn.text = b[0]
		btn.position = Vector2(x, 10)
		btn.size = Vector2(b[2] - 8.0, 52)
		btn.add_theme_font_size_override("font_size", 20)
		btn.focus_mode = Control.FOCUS_NONE
		match b[1]:
			"menu":
				btn.pressed.connect(func(): menu_pressed.emit())
			"quests":
				btn.pressed.connect(func(): quests_pressed.emit())
			"inv":
				btn.pressed.connect(func(): inv_pressed.emit())
		add_child(btn)
	# ----- сообщения -----
	_toast = _label(Vector2(0, 92), 22, Color(1.0, 0.95, 0.8))
	_toast.size = Vector2(_vs.x, 40)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_banner = _label(Vector2(0, _vs.y * 0.3), 46, Color(1.0, 0.85, 0.35))
	_banner.size = Vector2(_vs.x, 70)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.modulate.a = 0.0
	_prompt = _label(Vector2(0, 0), 20, Color(1.0, 0.95, 0.75))
	_prompt.size = Vector2(360, 34)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_keys = _label(Vector2(12, _vs.y - 50), 13, Color(1, 1, 1, 0.6))
	_keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_keys.update_minimum_size()
	_keys.size = Vector2(_vs.x - 330, 44)
	_update_keys()

func _update_keys() -> void:
	_keys.visible = not Config.touch()
	if Pad.connected():
		var b := Pad.binds("story")
		var parts := []
		for fn in ["jump", "shoot", "ranged", "interact", "a1", "a2", "a3", "ult", "inv", "menu"]:
			parts.append(Pad.id_name(String(b[fn])).replace("Крестовина ", "") + " — " + Pad.func_name("story", fn).to_lower())
		_keys.text = "Стик — ходьба · " + " · ".join(parts)
	else:
		_keys.text = "A/D — ходьба · W — прыжок · S — вниз · F — удар · G — выстрел · Q/E/C — умения · X — ульта · T — действие · I — рюкзак · J — задания · Esc — меню"

static func box(bg: Color, border: Color, r := 10, bw := 2) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(bw)
	st.set_corner_radius_all(r)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	return st

func _label(pos: Vector2, size: int, c: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func _bar(pos: Vector2, h: float, c: Color) -> Array:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.position = pos
	bg.size = Vector2(BAR_W, h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var fill := ColorRect.new()
	fill.color = c
	fill.position = pos + Vector2(2, 2)
	fill.size = Vector2(BAR_W - 4, h - 4)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	var hl := ColorRect.new()          # блик сверху полоски
	hl.color = Color(1, 1, 1, 0.18)
	hl.position = pos + Vector2(2, 2)
	hl.size = Vector2(BAR_W - 4, maxf(2.0, (h - 4) * 0.35))
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hl)
	var t := Label.new()
	t.position = pos + Vector2(0, -3)
	t.size = Vector2(BAR_W, h + 4)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", maxi(11, int(h)))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return [fill, t]

# ----- кнопки управления (телефон) -----
func build_buttons(p: Player, kit: StoryKit) -> void:
	if _btn_layer:
		_btn_layer.queue_free()
		_btn_layer = null
	ui = {}
	if _keys:
		_update_keys()
	_btn_layer = Node.new()
	add_child(_btn_layer)
	# значки способностей с перезарядкой (геймпад / клавиатура) — всегда;
	# экранные кнопки — если можно касаться; видно то, чем сейчас играют
	var ind := TouchControls.build_indicators(_btn_layer, "p1", "solo", p, TouchControls.key_names("p1", "story"))
	if not Config.can_touch():
		ui = ind
		return
	ui["_ind"] = ind
	if Config.touch_panel():
		var pl := CanvasLayer.new()
		pl.layer = 4
		pl.add_to_group("touch_ui")
		pl.visible = Config.touch()
		_btn_layer.add_child(pl)
		var panel := ColorRect.new()
		panel.color = Color(0.1, 0.09, 0.12)
		panel.position = Vector2(0, _vs.y - Config.PANEL)
		panel.size = Vector2(_vs.x, Config.PANEL)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pl.add_child(panel)
	var root := TouchControls._root(_btn_layer, 5)
	var BTN := Config.BTN
	var b := Vector2(BTN, BTN)
	var yt := _vs.y - Config.PANEL + 6.0
	var yb := yt + BTN + 6.0
	var MW := TouchControls.MOVE_W
	var stick := TouchControls.use_stick()
	var moves := []
	if stick:
		TouchControls.add_stick(root, "p1", Rect2(0, yt - 150.0, 300.0, _vs.y - yt + 150.0))
	else:
		var tall := Vector2(MW, BTN * 2 + 6)
		var mid := Vector2(MW, BTN)
		moves = [["left", 10.0, yt, "<", tall], ["jump", 16.0 + MW, yt, "^", mid],
				["down", 16.0 + MW, yb, "v", mid], ["right", 22.0 + MW * 2, yt, ">", tall]]
	var icons := {"fist": "h_fist", "sword": "h_sword", "dagger": "h_dagger"}
	var melee_icon: String = icons.get(String(kit.melee_def()["sub"]), "h_sword")
	var r := kit.ranged_def()
	var ranged_icon := "h_noranged" if r.is_empty() else ("h_bow" if r["sub"] == "bow" else "h_sling")
	var W := _vs.x
	var big := Vector2(BTN * 1.6, BTN * 2 + 6)
	var actions := [
			["shoot", W - 10.0 - big.x, yt, "#" + melee_icon, big],
			["ranged", W - 16.0 - big.x - BTN, yb, "#" + ranged_icon, b],
			["interact", W - 22.0 - big.x - BTN * 2, yb, "#h_interact", b],
			["ult", W - 16.0 - big.x - BTN, yt, _icon_label(p.ult), b],
			["a3", W - 22.0 - big.x - BTN * 2, yt, _icon_label(p.abilities[2]), b],
			["a2", W - 28.0 - big.x - BTN * 3, yt, _icon_label(p.abilities[1]), b],
			["a1", W - 34.0 - big.x - BTN * 4, yt, _icon_label(p.abilities[0]), b]]
	if stick:
		actions.append(["jump", W - 28.0 - big.x - BTN * 3, yb, "^", b])
	for a in moves + actions:
		ui[a[0]] = TouchControls._make_button(root, "p1_" + a[0], Vector2(a[1], a[2]), a[3], a[4])
	for k in ["a1", "a2", "a3", "ult"]:
		var ab: String = p.ult if k == "ult" else p.abilities[int(k.substr(1)) - 1]
		if ab == "":
			ui[k]["bg"].modulate = Color(1, 1, 1, 0.45)      # пустая ячейка — тусклая рамка

func _icon_label(ab: String) -> String:
	if ab == "":
		return ""
	var ic: String = StoryAbilities.get_def(ab).get("icon", "")
	return "#" + ic if ic != "" else ab

# ----- обновление каждый кадр -----
func refresh(p: Player, kit: StoryKit, data: Dictionary) -> void:
	_name.text = "%s   ·   Уровень %d" % [data.get("name", "Герой"), int(data.get("level", 1))]
	var hk := clampf(float(p.hp) / maxf(1.0, p.max_hp), 0.0, 1.0)
	_hp_fill.size.x = (BAR_W - 4) * hk
	_hp_text.text = "%d / %d" % [maxi(p.hp, 0), p.max_hp]
	_mp_fill.size.x = (BAR_W - 4) * clampf(kit.mana / maxf(1.0, kit.max_mana), 0.0, 1.0)
	_mp_text.text = "%d / %d" % [int(kit.mana), int(kit.max_mana)]
	var need := StoryStats.level_next(int(data["level"]))
	_xp_fill.size.x = (BAR_W - 4) * clampf(float(data["xp"]) / need, 0.0, 1.0)
	_xp_text.text = "опыт %d / %d" % [int(data["xp"]), need]

func set_quest_text(t: String) -> void:
	_quest.text = t
	_quest_bg.visible = t != ""
	await get_tree().process_frame
	if is_instance_valid(_quest):
		_quest_bg.size.y = _quest.get_line_count() * _quest.get_line_height() + 10.0

func toast(t: String, c := Color(1.0, 0.95, 0.8)) -> void:
	_toast.text = t
	_toast.add_theme_color_override("font_color", c)
	_toast_t = 2.4

func banner(t: String, c := Color(1.0, 0.85, 0.35)) -> void:
	_banner.text = t
	_banner.add_theme_color_override("font_color", c)
	_banner_t = 2.2

func show_prompt(screen_pos: Vector2, t: String) -> void:
	_prompt.visible = t != ""
	_prompt.text = ("[" + Pad.id_name(String(Pad.binds("story")["interact"])) + "]  " if Pad.connected() else ("[T]  " if not Config.touch() else "")) + t
	_prompt.position = screen_pos - Vector2(180, 0)

var _keys_t := 0.0

func _process(delta: float) -> void:
	_keys_t -= delta
	if _keys_t <= 0.0 and _keys:
		_keys_t = 0.5
		_update_keys()
	_toast_t -= delta
	_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_banner_t -= delta
	_banner.modulate.a = clampf(_banner_t / 0.5, 0.0, 1.0)

# ----- окно с текстом и/или списком предметов -----
func is_dialog_open() -> bool:
	return _dialog != null

func show_dialog(title: String, text: String, items := []) -> void:
	close_dialog(false)
	_dialog = Panel.new()
	_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	var cols := 3 if items.size() > 8 else 2
	var w := 560.0 if cols == 2 else 780.0
	var rh := 44.0 if cols == 2 else 38.0
	var h := 150.0 + (ceili(items.size() / float(cols)) * rh if not items.is_empty() else 0.0) + (40.0 if text.length() > 60 else 0.0)
	_dialog.size = Vector2(w, h)
	_dialog.position = Vector2((_vs.x - w) / 2, maxf(8.0, (_vs.y - h) / 2 - 40))
	_dialog.add_theme_stylebox_override("panel", box(Color(0.12, 0.09, 0.07, 0.95), Color(0.85, 0.65, 0.3), 12, 3))
	add_child(_dialog)
	var t := Label.new()
	t.text = title
	t.position = Vector2(0, 10)
	t.size = Vector2(w, 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_dialog.add_child(t)
	var y := 50.0
	if text != "":
		var l := Label.new()
		l.text = text
		l.position = Vector2(24, y)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.update_minimum_size()
		l.size = Vector2(w - 48, 60)
		l.add_theme_font_size_override("font_size", 18)
		_dialog.add_child(l)
		y += 40.0 if text.length() <= 60 else 80.0
	for i in items.size():
		var it: Array = items[i]
		var cx := 30.0 + (i % cols) * 250.0
		var cy := y + (i / cols) * rh
		var ic := AbilityIcons.make(String(it[0]), 34)
		if ic:
			ic.position = Vector2(cx + 17, cy + 17)
			_dialog.add_child(ic)
		var nl := Label.new()
		nl.text = Items.item_name(String(it[0])) + ("  ×%d" % int(it[1]) if int(it[1]) > 1 else "")
		nl.position = Vector2(cx + 42, cy + 4)
		nl.add_theme_font_size_override("font_size", 16)
		nl.add_theme_color_override("font_color", Items.RARITY.get(Items.get_def(String(it[0])).get("rarity", "common"), Color.WHITE))
		_dialog.add_child(nl)
	var ok := Button.new()
	ok.text = "Хорошо"
	ok.size = Vector2(160, 48)
	ok.position = Vector2((w - 160) / 2, h - 60)
	ok.add_theme_font_size_override("font_size", 20)
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(close_dialog)
	_dialog.add_child(ok)

func close_dialog(emit := true) -> void:
	if _dialog:
		_dialog.queue_free()
		_dialog = null
		if emit:
			dialog_closed.emit()
