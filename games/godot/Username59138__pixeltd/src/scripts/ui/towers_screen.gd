class_name TowersScreen
extends Control
## Armory: tower portraits (click one for the full tower view with its upgrade path) and an enemy bestiary.

const COLS := 5
const PER_PAGE := 10   # two rows of five cards, the rest go to the next pages
const CARD := Vector2(96, 128)
const GAP := 6

static var page := 0         # tower page, remembered while the game runs
static var enemy_page := 0

var main: Node
var content: Control
var tab_towers: Button
var tab_enemies: Button
var detail: Control

# tower view state
var cur_tower := ""
var cur_level := 0
var view_sprite: TextureRect
var view_stats: Label
var up_title: Label
var up_cost: Label
var up_desc: Label
var up_diff: Label
var circles: Array = []
var prev_btn: Button
var next_btn: Button
var page_label: Label
var showing_towers := true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UI.dim_rect(0.6))
	var title := UI.title("ARMORY", 16)
	title.position = Vector2(0, 8)
	title.size = Vector2(640, 20)
	add_child(title)
	tab_towers = UI.button("Towers", "blue", Vector2(80, 16))
	tab_towers.position = Vector2(236, 30)
	tab_towers.pressed.connect(func(): _show(true))
	add_child(tab_towers)
	tab_enemies = UI.button("Enemies", "gray", Vector2(80, 16))
	tab_enemies.position = Vector2(324, 30)
	tab_enemies.pressed.connect(func(): _show(false))
	add_child(tab_enemies)
	var back := UI.button("Back", "red", Vector2(70, 18))
	back.position = Vector2(8, 336)
	back.pressed.connect(func(): main.show_menu())
	add_child(back)
	prev_btn = UI.button("<", "blue", Vector2(24, 40))
	prev_btn.position = Vector2(36, 166)
	prev_btn.pressed.connect(func(): _show_page(page - 1))
	add_child(prev_btn)
	next_btn = UI.button(">", "blue", Vector2(24, 40))
	next_btn.position = Vector2(580, 166)
	next_btn.pressed.connect(func(): _show_page(page + 1))
	add_child(next_btn)
	page_label = UI.label("", 10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER)
	page_label.position = Vector2(270, 338)
	page_label.size = Vector2(100, 14)
	add_child(page_label)
	_show(true)


func _show(towers: bool) -> void:
	showing_towers = towers
	if content:
		content.queue_free()
	content = Control.new()
	content.position = Vector2(0, 52)
	content.size = Vector2(640, 280)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	UI.color_button(tab_towers, "blue" if towers else "gray")
	UI.color_button(tab_enemies, "gray" if towers else "blue")
	if towers:
		_build_towers()
	else:
		_build_enemies()
	_update_pager()


func _page_count() -> int:
	var n := Defs.TOWER_ORDER.size() if showing_towers else Defs.ENEMY_ORDER.size()
	return maxi(1, ceili(n / float(PER_PAGE)))


func _cur_page() -> int:
	return clampi(page if showing_towers else enemy_page, 0, _page_count() - 1)


func _show_page(p: int) -> void:
	var np := clampi(p, 0, _page_count() - 1)
	if np == _cur_page():
		return
	if showing_towers:
		page = np
	else:
		enemy_page = np
	Sfx.play("click")
	_show(showing_towers)


## The page arrows only show up when the cards of the open tab don't fit on one page.
func _update_pager() -> void:
	var many := _page_count() > 1
	prev_btn.visible = many
	next_btn.visible = many
	prev_btn.disabled = _cur_page() == 0
	next_btn.disabled = _cur_page() == _page_count() - 1
	page_label.visible = many
	page_label.text = "Page %d/%d" % [_cur_page() + 1, _page_count()]


## Top-left corner of card i (0..9) of the 5x2 grid.
static func _card_pos(i: int) -> Vector2:
	var x0 := (640 - (COLS * CARD.x + (COLS - 1) * GAP)) / 2
	return Vector2(x0 + (i % COLS) * (CARD.x + GAP), 2 + (i / COLS) * (CARD.y + GAP))


# ---------------------------------------------------------------- portrait grid
func _build_towers() -> void:
	page = _cur_page()
	var ids: Array = Defs.TOWER_ORDER.slice(page * PER_PAGE, (page + 1) * PER_PAGE)
	var cw := int(CARD.x)
	for i in ids.size():
		var t: String = ids[i]
		var d: Dictionary = Defs.TOWERS[t]
		var unlocked := Game.is_tower_unlocked(t)
		var for_sale := Game.is_tower_for_sale(t)
		var b := UI.button("", "blue", CARD)
		b.position = _card_pos(i)
		b.size = CARD
		b.add_theme_stylebox_override("normal", UI.box("card", 4, Vector4(4, 4, 4, 4)))
		b.add_theme_stylebox_override("hover", UI.box("card_hover", 4, Vector4(4, 4, 4, 4)))
		b.add_theme_stylebox_override("pressed", UI.box("card_selected", 4, Vector4(4, 4, 4, 4)))
		b.pressed.connect(func(): _open_tower(t))
		content.add_child(b)
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UI.box("panel_dark", 4, Vector4(3, 3, 3, 3)))
		frame.position = Vector2(8, 8)
		frame.size = Vector2(cw - 16, 92)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(frame)
		var spr := UI.sprite_rect("res://assets/sprites/towers/%s.png" % d["sprite"], 3)
		if not unlocked and not for_sale:
			spr.modulate = Color(0, 0, 0, 0.9)
		frame.add_child(spr)
		if not unlocked:
			var lock := UI.sprite_rect("res://assets/ui/icons/lock.png", 2)
			lock.position = Vector2(cw - 34, 12)
			b.add_child(lock)
		var nl := UI.label(d["name"] if unlocked or for_sale else "???", 10,
			Color("fee761") if unlocked or for_sale else Color("8b9bb4"), HORIZONTAL_ALIGNMENT_CENTER)
		nl.position = Vector2(0, 106)
		nl.size = Vector2(cw, 12)
		b.add_child(nl)
		if for_sale:   # beaten its map: buy it for paper maps
			var ph := HBoxContainer.new()
			ph.alignment = BoxContainer.ALIGNMENT_CENTER
			ph.add_theme_constant_override("separation", 2)
			ph.position = Vector2(0, 88)
			ph.size = Vector2(cw, 12)
			ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ph)
			var afford := Game.paper_maps >= Game.tower_price(t)
			ph.add_child(UI.label("BUY %d" % Game.tower_price(t), 10, Color("fee761") if afford else Color("8b9bb4")))
			ph.add_child(UI.icon("map"))
	var hint := UI.label("Click a tower to see everything about it.  You have %d paper maps." % Game.paper_maps, 10,
		Color("8b9bb4"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(0, 2 * CARD.y + GAP + 8)
	hint.size = Vector2(640, 12)
	content.add_child(hint)


# ---------------------------------------------------------------- tower view
func _stats_at(t: String, level: int) -> Dictionary:
	var d: Dictionary = Defs.TOWERS[t]
	var st: Dictionary = (d["base"] as Dictionary).duplicate()
	for i in level:
		for k in d["upgrades"][i]["set"]:
			st[k] = d["upgrades"][i]["set"][k]
	return st


static func _fmt(key: String, v) -> String:
	if typeof(v) == TYPE_BOOL:
		return "Yes" if v else "No"
	if typeof(v) == TYPE_STRING:
		return String(v).capitalize()
	if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and float(v) == 0.0:
		return "-"
	if Defs.PERCENT_STATS.has(key):
		return "%d%%" % int(float(v) * 100)
	return UI.fmt_num(float(v))


func _open_tower(t: String) -> void:
	Sfx.play("click")
	cur_tower = t
	var d: Dictionary = Defs.TOWERS[t]
	var unlocked := Game.is_tower_unlocked(t)
	detail = Control.new()
	detail.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail.mouse_filter = Control.MOUSE_FILTER_STOP
	detail.add_child(UI.dim_rect(0.65))
	add_child(detail)
	var p := UI.panel("panel", 8)
	p.position = Vector2(16, 20)
	p.size = Vector2(608, 320)
	detail.add_child(p)
	var root := Control.new()
	root.custom_minimum_size = Vector2(592, 304)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(root)

	var close := UI.button("X", "red", Vector2(18, 18))
	close.position = Vector2(574, 0)
	close.pressed.connect(_close_tower)
	root.add_child(close)

	# left column: portrait + identity
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box("panel_dark", 4, Vector4(4, 4, 4, 4)))
	frame.position = Vector2(0, 0)
	frame.size = Vector2(150, 140)
	root.add_child(frame)
	var for_sale := Game.is_tower_for_sale(t)
	view_sprite = UI.sprite_rect("res://assets/sprites/towers/%s.png" % d["sprite"], 5)
	if not unlocked and not for_sale:
		view_sprite.modulate = Color(0, 0, 0, 0.9)
	frame.add_child(view_sprite)
	var name_l := UI.label(d["name"] if unlocked or for_sale else "???", 20, Color("fee761"))
	name_l.position = Vector2(0, 146)
	root.add_child(name_l)
	var role_l := UI.label(d["role"], 10, Color("c0cbdc"))
	role_l.position = Vector2(0, 170)
	root.add_child(role_l)
	var cost_row := HBoxContainer.new()
	cost_row.position = Vector2(0, 184)
	root.add_child(cost_row)
	cost_row.add_child(UI.icon("coin"))
	cost_row.add_child(UI.label("$%d" % d["cost"], 10, Color("feae34")))

	if for_sale:
		var price := Game.tower_price(t)
		var afford := Game.paper_maps >= price
		var sdesc := UI.label(d["desc"], 10, Color.WHITE)
		sdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sdesc.position = Vector2(166, 0)
		sdesc.custom_minimum_size = Vector2(400, 0)
		root.add_child(sdesc)
		var l := UI.label("FOR SALE", 20, Color("fee761"), HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(170, 90)
		l.size = Vector2(400, 20)
		root.add_child(l)
		var buy := UI.button("Buy for %d paper maps" % price, "gold" if afford else "gray", Vector2(200, 28))
		buy.position = Vector2(270, 120)
		buy.disabled = not afford
		buy.pressed.connect(func():
			if Game.buy_tower(t):
				Sfx.play("unlock")
				_close_tower()
				_show(true)
				_open_tower(t))
		root.add_child(buy)
		var have := UI.label("You have %d paper maps" % Game.paper_maps, 10, Color("c0cbdc") if afford else Color("e43b44"),
			HORIZONTAL_ALIGNMENT_CENTER)
		have.position = Vector2(170, 154)
		have.size = Vector2(400, 12)
		root.add_child(have)
		return
	if not unlocked:
		var lock := UI.sprite_rect("res://assets/ui/icons/lock.png", 4)
		lock.position = Vector2(340, 60)
		root.add_child(lock)
		var l := UI.label("LOCKED", 20, Color("e43b44"), HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(170, 110)
		l.size = Vector2(400, 20)
		root.add_child(l)
		var how := UI.label(Game.unlock_text(t), 10, Color("feae34"), HORIZONTAL_ALIGNMENT_CENTER)
		how.position = Vector2(170, 136)
		how.size = Vector2(400, 12)
		root.add_child(how)
		return

	# right column: description + stats of the selected level
	var desc := UI.label(d["desc"], 10, Color.WHITE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(166, 0)
	desc.size = Vector2(400, 24)
	desc.custom_minimum_size = Vector2(400, 0)
	root.add_child(desc)
	view_stats = UI.label("", 10, Color("c0cbdc"))
	view_stats.position = Vector2(166, 34)
	root.add_child(view_stats)

	# upgrade path: circles connected by a line
	var path_y := 210.0
	var line := Control.new()
	line.position = Vector2(0, 0)
	line.size = Vector2(592, 304)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)
	var n: int = d["upgrades"].size() + 1
	var cx0 := 40.0
	var step := minf(60.0, 230.0 / (n - 1))   # 6 levels still end left of the info panel
	line.draw.connect(func():
		for i in n - 1:
			var a := Vector2(cx0 + i * step + 17, path_y)
			var b := Vector2(cx0 + (i + 1) * step - 17, path_y)
			line.draw_rect(Rect2(a - Vector2(0, 2), Vector2(b.x - a.x, 4)), Color("181425"))
			line.draw_rect(Rect2(a - Vector2(0, 1), Vector2(b.x - a.x, 2)),
				Defs.level_color(i + 1, n - 1) if i < cur_level else Color("3a4466")))
	circles.clear()
	for i in n:
		var c := Button.new()
		c.flat = true
		c.focus_mode = Control.FOCUS_NONE
		c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		c.position = Vector2(cx0 + i * step - 18, path_y - 18)
		c.size = Vector2(36, 36)
		for st in ["normal", "hover", "pressed", "focus"]:
			c.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var idx := i
		var icon_path := "res://assets/sprites/towers/%s.png" % d["sprite"] if i == 0 else \
			"res://assets/ui/upgrades/%s.png" % d["upgrades"][i - 1]["icon"]
		var icon_tex: Texture2D = load(icon_path)
		c.draw.connect(func():
			var center := Vector2(18, 18)
			var sel := idx == cur_level
			var col: Color = Defs.level_color(idx, n - 1)
			c.draw_circle(center, 17, Color("181425"), true, -1.0, false)
			c.draw_circle(center, 15, col if sel else col.darkened(0.45), true, -1.0, false)
			c.draw_circle(center, 12, Color("262b44") if not sel else Color("3a4466"), true, -1.0, false)
			if c.is_hovered() and not sel:
				c.draw_arc(center, 16, 0, TAU, 32, Color.WHITE, 1.0, false)
			var sz := icon_tex.get_size() * (1 if icon_tex.get_width() > 12 else 2)
			c.draw_texture_rect(icon_tex, Rect2((center - sz / 2.0).round(), sz), false))
		c.mouse_entered.connect(c.queue_redraw)
		c.mouse_exited.connect(c.queue_redraw)
		c.pressed.connect(func(): _select_level(idx))
		root.add_child(c)
		circles.append(c)
		var cap := UI.label("Base" if i == 0 else "Lv%d" % (i + 1), 10, Defs.level_color(i, n - 1),
			HORIZONTAL_ALIGNMENT_CENTER)
		cap.position = Vector2(cx0 + i * step - 30, path_y + 20)
		cap.size = Vector2(60, 12)
		root.add_child(cap)
	circles.append(line)

	# selected upgrade info (right of the path)
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UI.box("panel_dark", 4, Vector4(6, 4, 6, 4)))
	info.position = Vector2(300, 150)
	info.size = Vector2(292, 120)
	info.custom_minimum_size = Vector2(292, 120)
	root.add_child(info)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 2)
	info.add_child(iv)
	var head := HBoxContainer.new()
	iv.add_child(head)
	up_title = UI.label("", 10, Color("fee761"))
	up_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(up_title)
	up_cost = UI.label("", 10, Color("feae34"))
	head.add_child(up_cost)
	up_desc = UI.label("", 10, Color.WHITE)
	up_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	up_desc.custom_minimum_size = Vector2(278, 0)
	iv.add_child(up_desc)
	up_diff = UI.label("", 10, Color("63c74d"))
	iv.add_child(up_diff)
	_select_level(0)


func _select_level(lv: int) -> void:
	cur_level = lv
	var d: Dictionary = Defs.TOWERS[cur_tower]
	var elite: bool = lv >= d["upgrades"].size()
	view_sprite.texture = load("res://assets/sprites/towers/%s%s.png" % [d["sprite"], "_elite" if elite else ""])
	var st := _stats_at(cur_tower, lv)
	view_stats.text = "Level %d stats:\n%s" % [lv + 1, Hud._stats_text(cur_tower, st)]
	if lv == 0:
		up_title.text = "Base - " + d["name"]
		up_cost.text = "$%d" % d["cost"]
		up_desc.text = d["role"] + "."
		up_diff.text = "Click a circle to see an upgrade."
		up_diff.add_theme_color_override("font_color", Color("8b9bb4"))
	else:
		var up: Dictionary = d["upgrades"][lv - 1]
		up_title.text = "Lv%d - %s" % [lv + 1, up["name"]]
		up_cost.text = "$%d" % up["cost"]
		up_desc.text = up["desc"]
		var prev := _stats_at(cur_tower, lv - 1)
		var lines: Array = []
		for k in up["set"]:
			if prev.get(k) == st[k]:
				continue
			lines.append("%s  %s > %s" % [Defs.STAT_LABELS.get(k, k), _fmt(k, prev[k]), _fmt(k, st[k])])
		up_diff.text = "\n".join(lines)
		up_diff.add_theme_color_override("font_color", Color("63c74d"))
	for c in circles:
		c.queue_redraw()
	Sfx.play("click")


func _close_tower() -> void:
	if detail:
		detail.queue_free()
		detail = null


# ---------------------------------------------------------------- bestiary
func _build_enemies() -> void:
	enemy_page = _cur_page()
	var ids: Array = Defs.ENEMY_ORDER.slice(enemy_page * PER_PAGE, (enemy_page + 1) * PER_PAGE)
	for i in ids.size():
		var id: String = ids[i]
		var e: Dictionary = Defs.ENEMIES[id]
		var cls: int = e["class"]
		var p := Panel.new()
		p.add_theme_stylebox_override("panel", UI.box("card", 4))
		p.position = _card_pos(i)
		p.size = CARD
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(p)
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UI.box("panel_dark", 4, Vector4(3, 3, 3, 3)))
		frame.position = Vector2(8, 6)
		frame.size = Vector2(CARD.x - 16, 58)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(frame)
		var path := "res://assets/sprites/enemies/%s_down.png" % id
		var tex_h: float = (load(path) as Texture2D).get_height()
		frame.add_child(UI.sprite_rect(path, 2 if tex_h <= 24 else 1))   # bosses are big enough at 1x
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override("separation", 0)
		lines.position = Vector2(4, 66)
		lines.size = Vector2(CARD.x - 8, 60)
		p.add_child(lines)
		lines.add_child(UI.label(e["name"], 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
		lines.add_child(UI.label("Class %s  ctrl %d%%" % [Defs.CLASS_ROMAN[cls], int(Defs.CLASS_EFFECT[cls] * 100)],
			10, Defs.CLASS_COLORS[cls], HORIZONTAL_ALIGNMENT_CENTER))
		lines.add_child(UI.label("HP %d  Spd %d" % [e["hp"], e["speed"]], 10, Color("c0cbdc"),
			HORIZONTAL_ALIGNMENT_CENTER))
		var traits := UI.label(", ".join(_traits(e)) if _traits(e).size() else "-", 10, Color("feae34"),
			HORIZONTAL_ALIGNMENT_CENTER)
		traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		traits.custom_minimum_size.x = CARD.x - 8
		lines.add_child(traits)
	var foot := UI.label("Class weakens CONTROL (stun, slow, chill): I 100%% II 70%% III 40%% IV 20%%.  Bloated: x%s HP."
		% UI.fmt_num(Defs.BLOATED_HP),
		10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER)
	foot.position = Vector2(0, 2 * CARD.y + GAP + 8)
	foot.size = Vector2(640, 12)
	content.add_child(foot)


static func _traits(e: Dictionary) -> Array:
	var tr: Array = []
	if e.get("flying", false):
		tr.append("Flying")
	if e.get("invisible", false):
		tr.append("Invisible")
	if e.has("revive"):
		tr.append("Revives")
	if e.has("rage"):
		tr.append("Enrages")
	if e.has("armor"):
		tr.append("Armor %d" % e["armor"])
	if e.get("fire_res", 0.0) >= 1.0:
		tr.append("Fireproof")
	elif e.has("fire_res"):
		tr.append("Fire res %d%%" % int(e["fire_res"] * 100))
	if e.has("heal"):
		tr.append("Heals")
	if e.has("regen"):
		tr.append("Regenerates")
	if e.has("split"):
		tr.append("Splits")
	return tr


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if detail:
			_close_tower()
		else:
			main.show_menu()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and not detail and prev_btn.visible:
		if event.keycode in [KEY_LEFT, KEY_A]:
			_show_page(page - 1)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_RIGHT, KEY_D]:
			_show_page(page + 1)
			get_viewport().set_input_as_handled()
