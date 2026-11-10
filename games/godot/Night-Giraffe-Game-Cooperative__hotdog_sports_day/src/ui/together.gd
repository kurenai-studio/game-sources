class_name Together
extends Control
## PLAY TOGETHER: up to four players, on this screen's own buttons or on
## their phones. The game's address is on the left as a QR code; a phone on
## the same Wi-Fi scans it, the page opens with BOUNCE and JUMP, and that
## phone's hot dog hops into the next place on the right. Everyone plays as
## one team in the Games (sharing buns and medals), and against each other
## in practice.

signal done
signal join                      ## this tablet joins another's game instead

const SLOT := Vector2(112, 80)

var stadium: StadiumView
var _qr: TextureRect
var _url: Label
var _hint: Label
var _other: Button
var _screen_btn: Button
var _slots: Array = []           ## [{panel, view, num, name, how, x}]
var _shown := ""
var _t := 0.0
var _outer: Control


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 50.0
	stadium.excite = 0.6
	Remote.start()
	Remote.lobby = true
	Remote.set_beat(null)
	Remote.set_turns([])
	Remote.set_screen("PLAY TOGETHER", "WAITING FOR EVERYONE", false)
	Remote.changed.connect(_refresh)
	_build()
	_refresh()
	Sound.music("title")


func _exit_tree() -> void:
	Remote.lobby = false             # (whatever comes next tells the phones what's on)


func _build() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 3)
	add_child(outer)
	_outer = outer
	var title := Kit.label("PLAY TOGETHER", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	outer.add_child(row)
	# the left: the code to scan
	var left := Kit.panel(Color("2a1e3e"))
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 3)
	lbox.custom_minimum_size = Vector2(132, 0)
	left.add_child(lbox)
	var scan := Kit.label("SCAN TO JOIN", "small", Kit.PAPER)
	scan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbox.add_child(scan)
	_qr = TextureRect.new()
	_qr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_qr.custom_minimum_size = Vector2(112, 112)
	lbox.add_child(_qr)
	_url = Kit.label("", "small", Kit.AMBER)
	_url.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbox.add_child(_url)
	_hint = Kit.label("", "small", Kit.GREY)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(128, 0)
	lbox.add_child(_hint)
	_other = Kit.small_button("TRY ANOTHER ADDRESS", Color("4e4a62"), 128)
	_other.pressed.connect(func():
		Remote.next_address()
		_refresh())
	lbox.add_child(_other)
	row.add_child(left)
	# the right: the four places
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	right.add_child(grid)
	for p in Remote.MAX_PLAYERS:
		grid.add_child(_slot(p))
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 4)
	_screen_btn = Kit.small_button("", Color("2a5a7a"), 150)
	_screen_btn.pressed.connect(_cycle_screen)
	foot.add_child(_screen_btn)
	var ok := Kit.small_button("DONE", Kit.KETCHUP, 74)
	ok.pressed.connect(func(): done.emit())
	foot.add_child(ok)
	var other := Kit.small_button("JOIN A GAME ON ANOTHER TABLET", Color("1e8a8a"), 228)
	other.pressed.connect(func(): join.emit())
	right.add_child(other)
	right.add_child(foot)
	ok.grab_focus.call_deferred()


func _slot(p: int) -> Control:
	var panel := Kit.panel(Color("2a1e3e"))
	panel.custom_minimum_size = SLOT
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	top.custom_minimum_size = Vector2(0, 16)
	box.add_child(top)
	var num := Kit.label("P%d" % (p + 1), "small", Kit.player_colour(p))
	top.add_child(num)
	var name := Kit.label("", "small", Kit.PAPER)
	name.clip_text = true
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	var x := Kit.small_button("X", Color("6a2a3a"), 14)
	x.visible = false
	top.add_child(x)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(SLOT.x - 8, 54)
	stage.clip_contents = true
	box.add_child(stage)
	var view := AthleteView.new()
	view.position = Vector2(roundf((SLOT.x - 8) / 2.0), 52)
	stage.add_child(view)
	var how := Kit.label("", "small", Kit.GREY)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(how)
	var entry := {"panel": panel, "view": view, "num": num, "name": name, "how": how, "x": x, "stage": stage}
	x.pressed.connect(func():
		var k := Remote.phone_of(p)
		if k >= 0:
			Remote.remove(k))
	_slots.append(entry)
	return panel


func _cycle_screen() -> void:
	var n := Remote.screen_count()
	n = (n + 1) % (Remote.MAX_PLAYERS + 1)
	if n == 0 and Remote.phones.is_empty():
		n = 1
	Remote.screen_players = n
	if n > 0:
		Profile.players = n
		Profile.save()
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	var u := Remote.url()
	if u != _shown:
		_shown = u
		var img := QR.image(u, 3, 4) if u != "" else null
		_qr.texture = ImageTexture.create_from_image(img) if img else null
	if u == "":
		_url.text = "NO WI-FI"
		_hint.text = "Join this tablet to the home Wi-Fi, then come back here."
	else:
		var addr := u.trim_prefix("http://").trim_suffix("/")
		_url.text = "%s\nTABLET CODE %s" % [addr, addr.get_slice(":", 0).get_slice(".", 3)]
		_hint.text = "Phones: scan this. Tablets: JOIN A GAME, then scan it or type the code."
	_other.visible = Remote.addresses.size() > 1
	var looks := Remote.looks()
	var screens := Remote.screen_count()
	for p in _slots.size():
		var s: Dictionary = _slots[p]
		var view: AthleteView = s.view
		var k := Remote.phone_of(p)
		if p < looks.size():
			view.visible = true
			if str(view.look) != str(looks[p]):
				view.set_look(looks[p])
			(s.name as Label).text = String(looks[p].get("name", "")).to_upper()
			var how := "THIS SCREEN"
			if k >= 0:
				var ph: Dictionary = Remote.phones[k]
				how = "TABLET" if ph.get("kind", "phone") == "tablet" else "PHONE"
				if ph.sock == null and not ph.get("fake", false):
					how += " (AWAY)"
			(s.how as Label).text = how
			(s.how as Label).add_theme_color_override("font_color", Kit.player_colour(p) if k >= 0 else Kit.GREY)
		else:
			view.visible = false
			(s.name as Label).text = ""
			(s.how as Label).text = "SCAN TO JOIN" if u != "" else "-"
			(s.how as Label).add_theme_color_override("font_color", Kit.GREY)
		(s.x as Button).visible = k >= 0
	_screen_btn.text = "BUTTONS ON THIS SCREEN: %d" % screens


func _process(delta: float) -> void:
	_t += delta
	var sz := get_viewport_rect().size
	_outer.position = ((sz - _outer.get_combined_minimum_size()) / 2.0).round().max(Vector2(4, 4))
	var beat := _t * 88.0 / 60.0
	stadium.beat = beat
	for p in _slots.size():
		var v: AthleteView = _slots[p].view
		var ph := fposmod(beat + p * 0.25, 1.0)
		v.lift = 6.0 * 4.0 * ph * (1.0 - ph)
		v.squash = 0.82 if ph < 0.08 or ph > 0.94 else 1.0
		v.mood = "happy"
	# a phone gone quiet comes and goes from the list on its own
	if Engine.get_process_frames() % 30 == 0:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		done.emit()
