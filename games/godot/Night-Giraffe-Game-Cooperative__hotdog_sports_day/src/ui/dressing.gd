class_name Dressing
extends Control
## The dressing room: dress your hot dog. A big picture of it on the left; on
## the right a tab for each kind of thing (hats, outfits, specs, faces,
## trails, nations, sausages, buns, toppings, colours) and a tile for each
## choice, showing your hot dog wearing it. Locked tiles say what unlocks
## them (game/wardrobe.gd); new ones say NEW. Each player has their own hot
## dog, saved in the profile.

signal done

## Each tab: its name, and the look slots its tiles set.
const TABS := [
	["HATS", ["hat"]], ["OUTFITS", ["outfit"]], ["SPECS", ["specs"]], ["FACE", ["eyes", "hair", "tache"]],
	["TRAILS", ["trail"]], ["NATION", ["nation"]],
	["SAUSAGE", ["sausage"]], ["BUN", ["bun"]], ["TOPPINGS", ["toppings"]], ["BAND", ["band"]], ["STRIPE", ["stripe"]],
]
const TILE := Vector2(36, 46)
const COLS := 8
const TAB_COLOURS := [Color("7a3ad2"), Color("c83a8a"), Color("2a6ab4"), Color("d06a2a"), Color("1e8a8a"),
	Color("38a03a"), Color("b8423d"), Color("b8862e"), Color("6a9a3a"), Color("4e4a62"), Color("4e4a62")]

var player := 0
var look: Dictionary = {}
var view: AthleteView
var stadium: StadiumView
var tab := 0
var _t := 0.0
var _name: LineEdit
var _grid: GridContainer
var _info: Label
var _tabs: Array = []
var _players: Array = []
var _tiles: Array = []           ## {button, slot, id, view}
var _panel: Control
var _over: Control
var _new_here := {}              ## "slot:id" shown as NEW this visit


func _ready() -> void:
	if _panel:
		return                     # (built already)
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 60.0
	stadium.excite = 0.3
	_new_here = {}
	for k in Profile.fresh:
		_new_here[String(k)] = true
	view = AthleteView.new()
	view.scale = Vector2(3, 3)
	add_child(view)
	_over = Control.new()
	Kit.fill(_over)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)
	_build()
	_load_player(player)


func _build() -> void:
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	# who, and their name
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 3)
	var n := clampi(maxi(Profile.players, Remote.total()), 1, 4)
	if n > 1:
		for p in n:
			var pb := Kit.small_button("P%d" % (p + 1), Kit.player_colour(p).darkened(0.35), 24)
			pb.pressed.connect(func():
				_save()
				_load_player(p))
			head.add_child(pb)
			_players.append(pb)
	_name = LineEdit.new()
	_name.max_length = 18
	_name.add_theme_font_override("font", Kit.font("small"))
	_name.add_theme_font_size_override("font_size", 9)
	_name.add_theme_color_override("font_color", Kit.PAPER)
	_name.add_theme_stylebox_override("normal", Kit.box(Color("2a1e3e"), Kit.INK, 1, 0))
	_name.add_theme_stylebox_override("focus", Kit.box(Color("3a2a4a"), Kit.MUSTARD, 1, 0))
	_name.custom_minimum_size = Vector2(120, 15)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.placeholder_text = "Your hot dog's name"
	_name.text_changed.connect(func(t): look["name"] = t)
	head.add_child(_name)
	box.add_child(head)
	# the tabs, in two rows
	for row in [TABS.slice(0, 6), TABS.slice(6)]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 2)
		for t in row:
			var i := TABS.find(t)
			var b := Kit.small_button(String(t[0]), TAB_COLOURS[i], 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func(): _open(i))
			b.draw.connect(func(): _draw_tab_dot(b, i))
			r.add_child(b)
			_tabs.append(b)
		box.add_child(r)
	# the tiles
	var well := PanelContainer.new()
	var ws := Kit.box(Color("120c1a"), Kit.INK, 1, 0)
	ws.content_margin_left = 2
	ws.content_margin_right = 2
	ws.content_margin_top = 2
	ws.content_margin_bottom = 2
	well.add_theme_stylebox_override("panel", ws)
	well.custom_minimum_size = Vector2(COLS * TILE.x + (COLS - 1) * 2 + 4, 3 * TILE.y + 2 * 2 + 4)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	well.add_child(_grid)
	box.add_child(well)
	_info = Kit.label("", "small", Kit.PAPER)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.custom_minimum_size.y = 11
	box.add_child(_info)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 4)
	foot.alignment = BoxContainer.ALIGNMENT_END
	var rnd := Kit.small_button("SURPRISE ME!", Color("7a3ad2"), 86)
	rnd.pressed.connect(_surprise)
	foot.add_child(rnd)
	var ok := Kit.small_button("DONE", Kit.KETCHUP, 60)
	ok.pressed.connect(func():
		_save()
		done.emit())
	foot.add_child(ok)
	box.add_child(foot)
	add_child(panel)
	_panel = panel
	ok.grab_focus.call_deferred()


func _load_player(p: int) -> void:
	player = p
	look = Profile.athlete(player).duplicate(true)
	for i in _players.size():
		var b: Button = _players[i]
		b.modulate = Color.WHITE if i == player else Color(1, 1, 1, 0.55)
	_name.text = String(look.get("name", ""))
	view.set_look(look)
	_open(tab)


## Show a tab's tiles.
func _open(i: int) -> void:
	tab = i
	for k in _tabs.size():
		(_tabs[k] as Button).modulate = Color.WHITE if k == tab else Color(0.75, 0.75, 0.8)
	for t in _tiles:
		(t.button as Node).queue_free()
	_tiles.clear()
	var slots: Array = TABS[tab][1]
	for slot in slots:
		for id in _choices(String(slot)):
			_add_tile(String(slot), String(id))
	_info.text = _tab_hint()
	_info.add_theme_color_override("font_color", Kit.GREY)
	for t in _tabs:
		(t as Button).queue_redraw()


func _choices(slot: String) -> Array:
	match slot:
		"nation":
			return Looks.CHOICES.nation
		"toppings":
			return ["none"] + Looks.TOPPINGS
		"stripe":
			return Wardrobe.choices("band")
		"eyes":
			return Looks.CHOICES.eyes
	return Wardrobe.choices(slot)


func _tab_hint() -> String:
	match String(TABS[tab][0]):
		"TOPPINGS":
			return "PICK UP TO THREE TOPPINGS"
		"NATION":
			return "WHO DO YOU BOUNCE FOR?"
		"BAND", "STRIPE":
			return "YOUR 80s SWEATBAND"
	return "PLAY TO UNLOCK MORE!"


func _add_tile(slot: String, id: String) -> void:
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.clip_contents = true
	b.focus_mode = Control.FOCUS_ALL
	var open := Wardrobe.is_open(slot, id) if slot != "nation" and slot != "toppings" and slot != "eyes" else true
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := Kit.box(Color("2a1e3e") if open else Color("1a1222"), Kit.INK, 1, 0)
		if st == "hover":
			sb.bg_color = sb.bg_color.lightened(0.08)
		if st == "focus":
			sb.draw_center = false
			sb.border_color = Kit.PAPER
		b.add_theme_stylebox_override(st, sb)
	var tile := {"button": b, "slot": slot, "id": id, "open": open, "view": null}
	if slot != "nation":
		var v := AthleteView.new()
		v.shadow = slot == "trail"
		v.trail_on = slot == "trail"
		v.set_look(_try(slot, id))
		v.mood = "happy"
		v.position = Vector2(TILE.x / 2.0 + (7.0 if slot == "trail" else 0.0), _tile_y(slot))   # (room for the trail)
		if not open:
			v.modulate = Color(0.32, 0.28, 0.42)
		b.add_child(v)
		tile.view = v
	b.draw.connect(func(): _draw_tile(b, tile))
	b.pressed.connect(func(): _pick(tile))
	_grid.add_child(b)
	_tiles.append(tile)


## Where a tile's hot dog stands: the head for hats and faces, all of it otherwise.
func _tile_y(slot: String) -> float:
	match slot:
		"hat":
			return TILE.y + 21.0
		"specs", "eyes", "hair", "tache":
			return TILE.y + 14.0
	return TILE.y - 2.0


## The look with one thing changed (for a tile, or when it's picked).
func _try(slot: String, id: String) -> Dictionary:
	var l := look.duplicate(true)
	match slot:
		"band":
			var band: Array = l.get("band", ["red", "white"]).duplicate()
			band[0] = id
			l["band"] = band
		"stripe":
			var band: Array = l.get("band", ["red", "white"]).duplicate()
			band[1] = id
			l["band"] = band
		"toppings":
			var tops: Array = l.get("toppings", []).duplicate()
			if id == "none":
				tops = []
			elif id in tops:
				tops.erase(id)
			else:
				tops.append(id)
				if tops.size() > 3:
					tops.pop_front()
			l["toppings"] = tops
		_:
			l[slot] = id
			if slot == "sausage" and id == "corn":
				l["bun"] = "none"
	return l


func _is_on(slot: String, id: String) -> bool:
	match slot:
		"band":
			return String(look.get("band", ["red", "white"])[0]) == id
		"stripe":
			return String(look.get("band", ["red", "white"])[1]) == id
		"toppings":
			var tops: Array = look.get("toppings", [])
			return (id == "none" and tops.is_empty()) or id in tops
	return String(look.get(slot, "none" if slot in ["hat", "outfit", "trail"] else "")) == id


func _pick(tile: Dictionary) -> void:
	var slot := String(tile.slot)
	var id := String(tile.id)
	if not tile.open:
		_info.text = "LOCKED!  " + Wardrobe.hint(slot, id)
		_info.add_theme_color_override("font_color", Kit.AMBER)
		Sound.play("bounce_miss", 0.6)
		return
	look = _try(slot, id)
	view.set_look(look)
	view.flash = 0.3
	Sound.play("click", 0.7)
	_info.text = _name_of(slot, id).to_upper()
	_info.add_theme_color_override("font_color", Kit.MUSTARD)
	# the tiles show the hot dog as it is now
	for t in _tiles:
		if t.view:
			(t.view as AthleteView).set_look(_try(String(t.slot), String(t.id)))
		(t.button as Button).queue_redraw()


func _name_of(slot: String, id: String) -> String:
	match slot:
		"nation":
			return String(Catalog.nation(id).get("country", Looks.NAMES.get(id, id)))
		"toppings":
			return String(Looks.TOPPING_NAMES.get(id, id.capitalize()))
	return Wardrobe.name_of(slot, id)


func _draw_tile(b: Button, tile: Dictionary) -> void:
	var slot := String(tile.slot)
	var id := String(tile.id)
	if slot == "nation":
		var f := Kit.flag(id, "m")
		b.draw_texture(f, Vector2(roundf((TILE.x - 23) / 2.0), 9))
		var code := id.to_upper()
		var font := Kit.font("small")
		var w := font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		Kit.outlined(b, font, Vector2(roundf((TILE.x - w) / 2.0), 36), code, 9, Kit.PAPER)
	if slot == "band" or slot == "stripe":
		var teams: Dictionary = AthleteView.meta().get("teams", {})
		var c: Array = teams.get(id, [[255, 255, 255], [255, 255, 255], [255, 255, 255]])
		b.draw_rect(Rect2(3, TILE.y - 6, TILE.x - 6, 3), Color8(int(c[1][0]), int(c[1][1]), int(c[1][2])))
	if id == "none" and slot in ["hat", "outfit", "trail", "specs", "hair", "tache", "toppings"]:
		# a cross: wear nothing
		for k in 7:
			b.draw_rect(Rect2(3 + k, 3 + k, 1, 1), Kit.KETCHUP)
			b.draw_rect(Rect2(9 - k, 3 + k, 1, 1), Kit.KETCHUP)
	if not tile.open:
		_draw_lock(b, Vector2(TILE.x - 11, 3))
	elif _new_here.has("%s:%s" % [("band" if slot == "stripe" else slot), id]):
		var r := Rect2(TILE.x - 17, 2, 15, 8)
		b.draw_rect(r, Kit.KETCHUP)
		Kit.outlined(b, Kit.font("small"), Vector2(r.position.x + 1, r.position.y + 7), "NEW", 9, Kit.PAPER)
	if _is_on(slot, id):
		b.draw_rect(Rect2(Vector2(1, 1), TILE - Vector2(2, 2)), Kit.MUSTARD, false, 2.0)


## A padlock, 8 wide.
func _draw_lock(c: CanvasItem, at: Vector2) -> void:
	c.draw_rect(Rect2(at + Vector2(1, 0), Vector2(6, 5)), Kit.INK)
	c.draw_rect(Rect2(at + Vector2(2, 1), Vector2(4, 4)), Kit.GREY)
	c.draw_rect(Rect2(at + Vector2(3, 2), Vector2(2, 3)), Kit.INK)
	c.draw_rect(Rect2(at + Vector2(0, 4), Vector2(8, 7)), Kit.INK)
	c.draw_rect(Rect2(at + Vector2(1, 5), Vector2(6, 5)), Kit.MUSTARD)
	c.draw_rect(Rect2(at + Vector2(3, 6), Vector2(2, 3)), Kit.INK)


## A red dot on a tab that has something new in it.
func _draw_tab_dot(b: Button, i: int) -> void:
	var slots: Array = TABS[i][1]
	for k in Profile.fresh:
		var slot := String(k).split(":")[0]
		if slot in slots or (slot == "band" and "stripe" in slots):
			b.draw_rect(Rect2(b.size.x - 5, 1, 4, 4), Kit.INK)
			b.draw_rect(Rect2(b.size.x - 4, 2, 2, 2), Kit.KETCHUP)
			return


func _surprise() -> void:
	for slot in ["sausage", "bun", "eyes", "hair", "specs", "tache", "hat", "outfit", "trail"]:
		var open := _choices(slot).filter(func(id): return Wardrobe.is_open(slot, String(id)))
		look[slot] = open[randi() % open.size()]
	var bands := _choices("band").filter(func(id): return Wardrobe.is_open("band", String(id)))
	look["band"] = [bands[randi() % bands.size()], bands[randi() % bands.size()]]
	if look.sausage == "corn":
		look["bun"] = "none"
	var tops: Array = Looks.TOPPINGS.duplicate()
	tops.shuffle()
	look["toppings"] = tops.slice(0, randi_range(1, 3))
	view.set_look(look)
	view.flash = 0.4
	Sound.play("boing_big", 0.6)
	_open(tab)


func _save() -> void:
	var i: int = Profile.chosen[player]
	if i >= Profile.athletes.size():
		Profile.athletes.append(look)
		i = Profile.athletes.size() - 1
	Profile.athletes[i] = look.duplicate(true)
	# what's been seen here isn't new any more
	Profile.fresh = Profile.fresh.filter(func(k): return not _new_here.has(String(k)))
	Profile.save()


func _process(delta: float) -> void:
	_t += delta
	var s := get_viewport_rect().size
	var ps := _panel.get_combined_minimum_size()
	_panel.size = ps
	_panel.position = Vector2(roundf(s.x - ps.x - 4), roundf(maxf(2.0, (s.y - ps.y) / 2.0)))
	var ph := fposmod(_t * 1.4, 1.0)
	view.position = Vector2(_px(), roundf(s.y - 26))
	view.lift = 6.0 * 4.0 * ph * (1.0 - ph)
	view.squash = 0.8 if ph < 0.08 or ph > 0.95 else 1.0
	view.mood = "happy" if fposmod(_t, 4.0) < 3.0 else "wink"
	_over.queue_redraw()


func _draw_over() -> void:
	var s := get_viewport_rect().size
	var x := _px()
	# a spotlight on the floor
	for k in 3:
		var w := 44.0 - k * 10.0
		_over.draw_rect(Rect2(x - w, s.y - 28 + k, w * 2, 4 - k), Color(1, 0.95, 0.7, 0.12 + k * 0.05))
	var f := Kit.flag(String(look.get("nation", "ngc")), "l")
	_over.draw_texture(f, Vector2(6, 6))
	var name := String(look.get("name", ""))
	var font := Kit.font("small")
	Kit.outlined(_over, font, Vector2(54, 16), name, 9, Kit.MUSTARD)
	var who := "PLAYER %d" % (player + 1)
	Kit.outlined(_over, font, Vector2(54, 28), who, 9, Kit.player_colour(player))


## Where the big hot dog stands: in the middle of the room left of the panel.
func _px() -> float:
	var pw := _panel.get_combined_minimum_size().x + 8.0 if _panel else 330.0
	return roundf((get_viewport_rect().size.x - pw) / 2.0)
