class_name Settings
extends Control
## Settings: how loud, how hard, the helpers, and the timing check (tap along
## to a tick and the game learns how late this screen and these speakers are,
## so a tap on the beat counts as one).

signal done

const TICK := 0.6

var _rows := {}
var _calib: Label
var _taps: Array = []
var _testing := false
var _test_t := 0.0
var _last_tick := -1


func _ready() -> void:
	Kit.fill(self)
	var st := StadiumView.new()
	add_child(st)
	st.cam = 120.0
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Kit.label("SETTINGS", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_row(box, "MUSIC", "music")
	_row(box, "SOUNDS", "sfx")
	_row(box, "COMPUTER", "level")
	_row(box, "HELPERS", "assist")
	_calib = Kit.label("", "small", Kit.AMBER)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 4)
	var cb := Kit.button("TIMING CHECK", Color("2a5a7a"), "small", 110)
	cb.pressed.connect(_start_test)
	crow.add_child(cb)
	crow.add_child(_calib)
	box.add_child(crow)
	box.add_child(Kit.label("Then tap the screen (or space) on each tick.", "small", Kit.GREY))
	var cr := Kit.button("MUSIC AND SOUND CREDITS", Color("2a5a7a"), "small", 200)
	cr.pressed.connect(_credits)
	box.add_child(cr)
	var back := Kit.button("BACK", Color("4e4a62"), "small", 80)
	back.pressed.connect(func():
		Profile.save()
		done.emit())
	box.add_child(back)
	add_child(panel)
	Kit.centre(panel)
	_refresh()
	back.grab_focus.call_deferred()


func _row(box: VBoxContainer, label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var l := Kit.label(label, "small", Kit.GREY)
	l.custom_minimum_size.x = 60
	row.add_child(l)
	var minus := Kit.button("<", Color("4e4a62"), "small", 26)
	minus.pressed.connect(func(): _change(key, -1))
	row.add_child(minus)
	var v := Kit.label("", "small", Kit.PAPER)
	v.custom_minimum_size.x = 90
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(v)
	var plus := Kit.button(">", Color("4e4a62"), "small", 26)
	plus.pressed.connect(func(): _change(key, 1))
	row.add_child(plus)
	_rows[key] = v
	box.add_child(row)


func _change(key: String, d: int) -> void:
	match key:
		"music":
			Profile.music_volume = clampf(Profile.music_volume + d * 0.1, 0.0, 1.0)
			Sound.music_volume = Profile.music_volume
		"sfx":
			Profile.sfx_volume = clampf(Profile.sfx_volume + d * 0.1, 0.0, 1.0)
			Sound.sfx_volume = Profile.sfx_volume
			Sound.play("bounce_perfect")
		"level":
			var r: Array = Championship.RIVALS
			Profile.rivals = r[(r.find(Profile.rivals) + d + r.size()) % r.size()]
		"assist":
			Profile.assist = not Profile.assist
	_refresh()


func _refresh() -> void:
	(_rows.music as Label).text = "%d%%" % roundi(Profile.music_volume * 100)
	(_rows.sfx as Label).text = "%d%%" % roundi(Profile.sfx_volume * 100)
	(_rows.level as Label).text = Championship.age_label(Profile.rivals)
	(_rows.assist as Label).text = "ON" if Profile.assist else "OFF"
	_calib.text = "%+d ms" % roundi(Profile.calibration * 1000.0) if not _testing else "LISTEN..."


func _start_test() -> void:
	_testing = true
	_taps = []
	_test_t = 0.0
	_last_tick = -1
	Sound.stop_music(0.3)
	_refresh()


func _process(delta: float) -> void:
	if not _testing:
		return
	_test_t += delta
	var k := int(floor((_test_t - 1.0) / TICK))
	if k >= 0 and k != _last_tick and k < 12:
		_last_tick = k
		Sound.play("tick", 1.0, 1.25 if k % 4 == 0 else 1.0)
	if _test_t > 1.0 + TICK * 12.5:
		_testing = false
		_finish()


func _input(event: InputEvent) -> void:
	if not _testing:
		return
	var key: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_A, KEY_Z]
	var touch: bool = event is InputEventScreenTouch and event.pressed
	if key or touch:
		_taps.append(_test_t)
		get_viewport().set_input_as_handled()


func _finish() -> void:
	var errs: Array = []
	for t in _taps:
		var k := roundf((float(t) - 1.0) / TICK)
		if k >= 4:
			var e: float = float(t) - (1.0 + k * TICK)
			if absf(e) < 0.25:
				errs.append(e)
	if errs.size() >= 4:
		errs.sort()
		Profile.calibration = clampf(float(errs[errs.size() / 2]), TapTiming.LOW, TapTiming.HIGH)
		Profile.save()
	_refresh()
	Sound.music("title")



## Who made the music and the sounds (every track is credited, though
## Pixabay's licence doesn't ask for it).
func _credits() -> void:
	var c := Kit.panel(Color("1a1424"))
	c.z_index = 50
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	c.add_child(box)
	var t := Kit.label("CREDITS", "big", Kit.MUSTARD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	box.add_child(Kit.label("Music from Pixabay (Pixabay Content License):", "small", Kit.GREY))
	for cr in Sound.credits:
		box.add_child(Kit.label("%s  by %s" % [String(cr.get("title", "")), String(cr.get("artist", ""))], "small", Kit.PAPER))
	box.add_child(Kit.label("Night Giraffe tuning-up: the studio's own.", "small", Kit.GREY))
	box.add_child(Kit.label("Instruments: Versilian Community Sample Library (CC0).", "small", Kit.GREY))
	box.add_child(Kit.label("Everything else made by HotDog Sports Day's own scripts.", "small", Kit.GREY))
	box.add_child(Kit.label("Friends: Unicorn Bounce, Reggie's Neon, Heartwood & Walled Garden.", "small", Kit.GREY))
	var ok := Kit.small_button("CLOSE", Kit.KETCHUP, 70)
	ok.pressed.connect(func(): c.queue_free())
	box.add_child(ok)
	add_child(c)
	ok.grab_focus.call_deferred()
	Kit.centre(c)
