class_name Title
extends Control
## The title: the stadium, every nation's athlete lined up on the track
## bouncing to the music, the name in lights, the menu, and front and centre
## the players' own hot dogs with a big DRESS UP! button.

signal chosen(what: String)

var stadium: StadiumView
var lineup: Array = []
var logo: Control
var menu: VBoxContainer
var _t := 0.0
var _players_btn: Button
var _logo_tex: Texture2D = preload("res://assets/art/ui/logo.png")
var _level_btn: Button
var stars: Array = []            ## the players' own hot dogs, big, in the middle
var _star_btns: Array = []
var dress: Button


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = -2.0
	stadium.excite = 0.45
	stadium.lines = [{"x": 0.0, "kind": "start"}]
	var ns := Catalog.nations()
	for i in ns.size():
		var v := AthleteView.new()
		v.set_look(Championship.look_of(ns[i]))
		add_child(v)
		lineup.append(v)
	_build_logo()
	_build_menu()
	_build_stars()
	Sound.music("title")


func _build_logo() -> void:
	logo = Control.new()
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Kit.fill(logo)
	logo.draw.connect(_draw_logo)
	logo.z_index = 50
	add_child(logo)


func _draw_logo() -> void:
	var s := get_viewport_rect().size
	var tex: Texture2D = _logo_tex
	if tex == null:
		return
	var area := s.x - 150.0
	var bob := roundf(sin(_t * 2.2) * 1.5)
	logo.draw_texture(tex, Vector2(roundf(area / 2.0 - tex.get_width() / 2.0), 6 + bob))
	var f := Kit.font("small")
	var sub := "A NIGHT GIRAFFE GAME"
	var w := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	Kit.outlined(logo, f, Vector2(roundf(area / 2.0 - w / 2.0), 6 + tex.get_height() + 2), sub, 9, Kit.PAPER)


func _build_menu() -> void:
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 3)
	menu.z_index = 60
	add_child(menu)
	var items := [["THE GAMES", "championship", Kit.KETCHUP], ["LEARN TO PLAY", "learn", Color("d06a2a")],
		["PRACTICE", "practice", Kit.SKY.darkened(0.2)], ["PLAY TOGETHER", "together", Color("1e8a8a")],
		["RECORDS", "records", Color("38a03a")], ["SETTINGS", "settings", Color("4e4a62")]]
	for it in items:
		var b := Kit.button(String(it[0]), it[2], "small", 130)
		b.pressed.connect(func(): chosen.emit(String(it[1])))
		menu.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_players_btn = Kit.button("", Color("2a5a7a"), "small", 63)
	_players_btn.pressed.connect(func():
		Profile.players = Remote.screen_count() % Remote.MAX_PLAYERS + 1   # 1, 2, 3, 4 on this tablet
		Remote.screen_players = -1
		Profile.save()
		_refresh())
	_level_btn = Kit.button("", Color("2a5a7a"), "small", 63)
	_level_btn.pressed.connect(func():
		var r: Array = Championship.RIVALS
		Profile.rivals = r[(r.find(Profile.rivals) + 1) % r.size()]
		Profile.save()
		_refresh())
	row.add_child(_players_btn)
	row.add_child(_level_btn)
	menu.add_child(row)
	_refresh()
	(menu.get_child(0) as Button).grab_focus.call_deferred()


## The players' hot dogs, big, and the DRESS UP! button under them. Tap a hot
## dog to dress that one.
func _build_stars() -> void:
	for v in stars:
		(v as Node).queue_free()
	for b in _star_btns:
		(b as Node).queue_free()
	stars.clear()
	_star_btns.clear()
	var n := clampi(Remote.total(), 1, 4)
	for p in n:
		var v := AthleteView.new()
		v.set_look(Profile.athlete(p))
		v.scale = Vector2(2, 2)
		v.z_index = 55
		add_child(v)
		stars.append(v)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.z_index = 56
		var clear := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, clear)
		b.pressed.connect(func(): chosen.emit("dress:%d" % p))
		add_child(b)
		_star_btns.append(b)
	if dress == null:
		dress = Kit.button("DRESS UP!", Color("7a3ad2"), "small", 100)
		dress.z_index = 57
		dress.pressed.connect(func(): chosen.emit("dress"))
		dress.draw.connect(_draw_new_badge)
		add_child(dress)


## NEW on the DRESS UP! button when playing has unlocked something.
func _draw_new_badge() -> void:
	if Profile.fresh.is_empty():
		return
	var f := Kit.font("small")
	var text := "%d NEW!" % Profile.fresh.size()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	var r := Rect2(dress.size.x - w - 2, -8, w + 6, 11)
	var pulse := 0.5 + 0.5 * sin(_t * 6.0)
	dress.draw_rect(r.grow(1), Kit.INK)
	dress.draw_rect(r, Kit.KETCHUP.lightened(0.15 * pulse))
	Kit.outlined(dress, f, Vector2(r.position.x + 3, r.position.y + 9), text, 9, Kit.PAPER)


func _refresh() -> void:
	_players_btn.text = "%d PLAYER%s" % [Remote.total(), "S" if Remote.total() > 1 else ""]
	_level_btn.text = Championship.age_label(Profile.rivals)
	if dress != null:
		_build_stars()


func _process(delta: float) -> void:
	_t += delta
	var s := get_viewport_rect().size
	menu.position = Vector2(roundf(s.x - 142), roundf(maxf(6.0, s.y * 0.5 - 104)))
	stadium.cam = -2.0 + sin(_t * 0.05) * 3.0
	var bpm := 88.0
	var beat := _t * bpm / 60.0
	stadium.beat = beat
	var n := lineup.size()
	var room := s.x - 160.0
	for i in n:
		var v: AthleteView = lineup[i]
		var lane := 1.0 + float(i % 3)
		var y := stadium.lane_y(lane)
		var col := i / 3
		var x := 22.0 + col * (room / ceilf(n / 3.0)) + (i % 3) * 13.0
		v.position = Vector2(x, y).round()
		var ph := fposmod(beat + i * 0.13, 1.0)
		v.lift = 10.0 * 4.0 * ph * (1.0 - ph)
		v.squash = 0.78 if ph < 0.1 or ph > 0.93 else (1.12 if ph < 0.25 else 1.0)
		v.mood = "happy" if ph > 0.2 and ph < 0.8 else "ready"
		v.z_index = int(lane * 10)
	_place_stars(s, beat)
	logo.queue_redraw()


## The big hot dogs stand in the middle of the room left of the menu, the
## DRESS UP! button under them.
func _place_stars(s: Vector2, beat: float) -> void:
	var area := s.x - 150.0
	var n := stars.size()
	var gap := 66.0 if n > 2 else 84.0
	var feet := roundf(s.y - 38.0)
	for i in n:
		var v: AthleteView = stars[i]
		var x := roundf(area / 2.0 + (i - (n - 1) / 2.0) * gap)
		var ph := fposmod(beat * 0.5 + i * 0.25, 1.0)
		v.position = Vector2(x, feet)
		v.lift = 5.0 * 4.0 * ph * (1.0 - ph)
		v.squash = 0.85 if ph < 0.07 or ph > 0.95 else 1.0
		v.mood = "wink" if fposmod(_t + i * 1.3, 5.0) < 0.5 else "happy"
		var b: Button = _star_btns[i]
		b.position = Vector2(x - 34, feet - 122)
		b.size = Vector2(68, 126)
	if dress:
		var ds := dress.get_combined_minimum_size()
		dress.size = ds
		dress.position = Vector2(roundf(area / 2.0 - ds.x / 2.0), roundf(s.y - ds.y - 6))
		dress.queue_redraw()
