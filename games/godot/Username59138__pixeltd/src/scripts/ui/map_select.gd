class_name MapSelect
extends Control
## Map selection grid followed by a difficulty picker.

const TIER_COLORS := {"Beginner": Color("63c74d"), "Intermediate": Color("feae34"), "Advanced": Color("f77622"),
	"Expert": Color("e43b44")}

const PER_PAGE := 6   # two rows of three, more maps go to the next pages

static var page := 0   # remembered while the game runs

var main: Node
var popup: Control
var cards: Control
var page_label: Label
var prev_btn: Button
var next_btn: Button
var wallet_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UI.dim_rect(0.55))
	var title := UI.title("SELECT MAP", 16)
	title.position = Vector2(0, 8)
	title.size = Vector2(640, 20)
	add_child(title)

	cards = Control.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards)
	prev_btn = UI.button("<", "blue", Vector2(24, 40))
	prev_btn.position = Vector2(40, 162)
	prev_btn.pressed.connect(func(): _show_page(page - 1))
	add_child(prev_btn)
	next_btn = UI.button(">", "blue", Vector2(24, 40))
	next_btn.position = Vector2(576, 162)
	next_btn.pressed.connect(func(): _show_page(page + 1))
	add_child(next_btn)
	page_label = UI.label("", 10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER)
	page_label.position = Vector2(270, 338)
	page_label.size = Vector2(100, 14)
	add_child(page_label)
	var wallet := HBoxContainer.new()
	wallet.alignment = BoxContainer.ALIGNMENT_END
	wallet.add_theme_constant_override("separation", 3)
	wallet.position = Vector2(432, 338)
	wallet.size = Vector2(200, 14)
	wallet.tooltip_text = "Paper maps: win battles to earn them, spend them on new maps"
	add_child(wallet)
	wallet.add_child(UI.icon("map"))
	wallet_label = UI.label("", 10, Color("fee761"))
	wallet.add_child(wallet_label)
	_show_page(page)

	var back := UI.button("Back", "red", Vector2(70, 18))
	back.position = Vector2(8, 336)
	back.pressed.connect(func(): main.show_menu())
	add_child(back)


func _page_count() -> int:
	return maxi(1, ceili(MapsData.ORDER.size() / float(PER_PAGE)))


func _show_page(p: int) -> void:
	page = clampi(p, 0, _page_count() - 1)
	for c in cards.get_children():
		c.queue_free()
	var ids: Array = MapsData.ORDER.slice(page * PER_PAGE, (page + 1) * PER_PAGE)
	var first_row := mini(ids.size(), 3)
	for i in ids.size():
		var row := 0 if i < first_row else 1
		var col := i if i < first_row else i - first_row
		var count := first_row if row == 0 else ids.size() - first_row
		var cw := 150
		var gap := 10
		var x0 := (640 - (count * cw + (count - 1) * gap)) / 2
		var card := _map_card(ids[i])
		card.position = Vector2(x0 + col * (cw + gap), 34 + row * 148)
		cards.add_child(card)
	var many := _page_count() > 1
	prev_btn.visible = many
	next_btn.visible = many
	prev_btn.disabled = page == 0
	next_btn.disabled = page == _page_count() - 1
	page_label.visible = many
	page_label.text = "Page %d/%d" % [page + 1, _page_count()]
	wallet_label.text = "%d paper maps" % Game.paper_maps


func _map_card(id: String) -> Button:
	var m: Dictionary = MapsData.MAPS[id]
	var b := UI.button("", "blue", Vector2(150, 142))
	b.size = Vector2(150, 142)
	b.add_theme_stylebox_override("normal", UI.box("card", 4, Vector4(5, 5, 5, 5)))
	b.add_theme_stylebox_override("hover", UI.box("card_hover", 4, Vector4(5, 5, 5, 5)))
	b.add_theme_stylebox_override("pressed", UI.box("card_selected", 4, Vector4(5, 5, 5, 5)))
	var open := Game.is_map_unlocked(id)
	b.pressed.connect(func(): _open_difficulty(id) if open else _open_unlock(id))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.position = Vector2(5, 5)
	v.size = Vector2(140, 132)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box("panel_dark", 4, Vector4(2, 2, 2, 2)))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(frame)
	var th := UI.sprite_rect(Game.map_thumb(id))
	frame.add_child(th)
	if Game.map_variant(id) == "halloween" and open:
		var badge := UI.panel("panel_dark", 2)
		badge.position = Vector2(2, 2)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(UI.label("HALLOWEEN!", 10, Color("f77622")))
		th.add_child(badge)
	if not open:
		th.self_modulate = Color(0.3, 0.3, 0.38)
		var lk := UI.icon("lock")
		lk.size = Vector2(10, 10)
		lk.scale = Vector2(3, 3)
		lk.position = Vector2(64 - 15, 44 - 15)
		th.add_child(lk)
	var name_row := HBoxContainer.new()
	v.add_child(name_row)
	var nl := UI.label(m["name"], 10, Color.WHITE)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(nl)
	var stars := HBoxContainer.new()
	stars.add_theme_constant_override("separation", 0)
	name_row.add_child(stars)
	for d in Defs.DIFFICULTIES.size():
		var ic := UI.icon("star" if Game.is_beaten(id, d) else "star_off")
		if Game.is_beaten(id, d):
			ic.modulate = Defs.DIFFICULTIES[d]["color"].lightened(0.35)
		stars.add_child(ic)
	v.add_child(UI.label(m["tier"], 10, TIER_COLORS.get(m["tier"], Color.WHITE)))
	if not open:
		var lh := HBoxContainer.new()
		lh.add_theme_constant_override("separation", 2)
		v.add_child(lh)
		lh.add_child(UI.icon("lock"))
		var afford := Game.paper_maps >= Game.map_price(id)
		lh.add_child(UI.label("Unlock: %d" % Game.map_price(id), 10, Color("fee761") if afford else Color("8b9bb4")))
		lh.add_child(UI.icon("map"))
		return b
	# tower unlock reward hint
	for t in Defs.TOWER_ORDER:
		var u: Dictionary = Defs.TOWERS[t]["unlock"]
		if u.get("map", "") == id:
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 2)
			v.add_child(h)
			var unlocked := Game.is_tower_unlocked(t)
			var for_sale := Game.is_tower_for_sale(t)
			h.add_child(UI.icon("trophy" if unlocked else "lock"))
			var txt := "%s %s" % [Defs.TOWERS[t]["name"], "unlocked" if unlocked else ("for sale" if for_sale else
				"on " + Defs.DIFFICULTIES[u["difficulty"]]["name"])]
			h.add_child(UI.label(txt, 10, Color("63c74d") if unlocked else (Color("fee761") if for_sale else Color("feae34"))))
	return b


func _open_difficulty(id: String) -> void:
	var m: Dictionary = MapsData.MAPS[id]
	popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(UI.dim_rect(0.6))
	add_child(popup)
	var p := UI.panel("panel", 8)
	p.position = Vector2(40, 30)
	p.size = Vector2(560, 300)
	popup.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	# left: preview + info
	var left := VBoxContainer.new()
	h.add_child(left)
	left.add_child(UI.title(m["name"].to_upper(), 8, Color("fee761")))
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box("panel_dark", 4, Vector4(2, 2, 2, 2)))
	left.add_child(frame)
	frame.add_child(UI.sprite_rect(Game.map_thumb(id), 2))
	left.add_child(UI.label("Tier: " + m["tier"], 10, TIER_COLORS.get(m["tier"], Color.WHITE)))
	var desc := UI.label(m["desc"], 10, Color("c0cbdc"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(256, 0)
	left.add_child(desc)
	var paths: int = m["paths"].size()
	if paths > 1:
		left.add_child(UI.label("%d enemy paths!" % paths, 10, Color("f77622")))
	# right: difficulties
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	right.add_child(UI.title("DIFFICULTY", 8, Color.WHITE))
	# four difficulties fit, the rest scroll (mouse wheel or the bar)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	UI.style_scrollbar(scroll.get_v_scroll_bar(), 54)   # an arrow click moves the list by one difficulty
	for d in Defs.DIFFICULTIES.size():
		var dd: Dictionary = Defs.DIFFICULTIES[d]
		var open := Game.is_diff_open(id, d)
		var b := UI.button("", dd["btn"] if open else "gray", Vector2(0, 50))
		b.disabled = not open
		b.pressed.connect(func(): Sfx.play("click"); main.start_battle(id, d))
		list.add_child(b)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 0)
		bv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bv.offset_left = 6
		bv.offset_top = 4
		bv.offset_right = -6
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(top)
		var nl := UI.label(dd["name"].to_upper(), 20, Color.WHITE)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(nl)
		if Game.is_beaten(id, d):
			top.add_child(UI.icon("star"))
			top.add_child(UI.label("Beaten", 10, Color("fee761")))
		top.add_child(UI.label("  +%d" % Game.win_reward(id, d), 10, Color("fee761")))
		top.add_child(UI.icon("map"))
		var dl := UI.label(dd["desc"], 10, Color("ead4aa"))
		bv.add_child(dl)
		# reward note
		for t in Defs.TOWER_ORDER:
			var u: Dictionary = Defs.TOWERS[t]["unlock"]
			if u.get("map", "") == id and int(u["difficulty"]) <= d and not Game.is_tower_unlocked(t) \
					and not Game.is_tower_for_sale(t):
				bv.add_child(UI.label("Reward: %s goes on sale" % Defs.TOWERS[t]["name"], 10, Color("fee761")))
	var back := UI.button("Back", "gray", Vector2(0, 18))
	back.pressed.connect(func(): popup.queue_free())
	right.add_child(back)


## Popup for a locked map: buy it with paper maps, or explain how to earn them.
func _open_unlock(id: String) -> void:
	var m: Dictionary = MapsData.MAPS[id]
	popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(UI.dim_rect(0.6))
	add_child(popup)
	var p := UI.panel("panel", 8)
	p.position = Vector2(170, 70)
	p.size = Vector2(300, 0)
	popup.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(UI.title(m["name"].to_upper(), 8, Color("fee761")))
	v.add_child(UI.label("Tier: " + m["tier"], 10, TIER_COLORS.get(m["tier"], Color.WHITE)))
	var price := Game.map_price(id)
	var afford := Game.paper_maps >= price
	var txt := ""
	if afford:
		txt = "Unlock this map for %d paper maps? You have %d." % [price, Game.paper_maps]
	else:
		txt = "Unlocking costs %d paper maps, you have %d. Win battles to earn more: harder maps and difficulties pay more, and even a loss pays a little." % [price, Game.paper_maps]
	var l := UI.label(txt, 10, Color("c0cbdc"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(284, 0)
	v.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	if afford:
		var ub := UI.button("Unlock", "green", Vector2(90, 20))
		ub.pressed.connect(func():
			if Game.buy_map(id):
				Sfx.play("unlock")
			popup.queue_free()
			_show_page(page))
		row.add_child(ub)
	var cb := UI.button("Cancel" if afford else "OK", "gray", Vector2(90, 20))
	cb.pressed.connect(func(): popup.queue_free())
	row.add_child(cb)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if popup and is_instance_valid(popup):
			popup.queue_free()
		else:
			main.show_menu()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and not is_instance_valid(popup):
		if event.keycode in [KEY_LEFT, KEY_A]:
			_show_page(page - 1)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_RIGHT, KEY_D]:
			_show_page(page + 1)
			get_viewport().set_input_as_handled()
