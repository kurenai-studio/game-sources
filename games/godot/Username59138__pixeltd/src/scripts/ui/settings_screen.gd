class_name SettingsScreen
extends Control
## Settings overlay: sound, fullscreen and key bindings. Opened from the main menu and from the pause menu.

signal closed

var waiting := ""        # action waiting for a new key
var key_buttons := {}
var vol_label: Label
var music_label: Label
var now_playing: Label
var fs_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UI.dim_rect(0.7))
	var p := UI.panel("panel", 10)
	p.position = Vector2(40, 40)
	p.size = Vector2(560, 0)
	add_child(p)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	p.add_child(root)
	root.add_child(UI.title("SETTINGS", 16))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	root.add_child(cols)

	# ---- left: sound & display
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(180, 0)
	left.add_theme_constant_override("separation", 6)
	cols.add_child(left)
	left.add_child(UI.label("SOUND", 10, Color("8b9bb4")))
	var vol_row := HBoxContainer.new()
	left.add_child(vol_row)
	var el := UI.label("Effects", 10, Color.WHITE)
	el.custom_minimum_size.x = 36
	vol_row.add_child(el)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 1
	sl.step = 0.05
	sl.value = Game.sfx_volume
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(120, 12)
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(_on_volume)
	vol_row.add_child(sl)
	vol_label = UI.label("", 10, Color("fee761"))
	vol_label.custom_minimum_size = Vector2(28, 0)
	vol_row.add_child(vol_label)
	_on_volume(Game.sfx_volume, false)
	var mrow := HBoxContainer.new()
	left.add_child(mrow)
	var ml := UI.label("Music", 10, Color.WHITE)
	ml.custom_minimum_size.x = 36
	mrow.add_child(ml)
	var ms := HSlider.new()
	ms.min_value = 0
	ms.max_value = 1
	ms.step = 0.05
	ms.value = Game.music_volume
	ms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ms.custom_minimum_size = Vector2(120, 12)
	ms.focus_mode = Control.FOCUS_NONE
	ms.value_changed.connect(_on_music_volume)
	mrow.add_child(ms)
	music_label = UI.label("", 10, Color("fee761"))
	music_label.custom_minimum_size = Vector2(28, 0)
	mrow.add_child(music_label)
	_on_music_volume(Game.music_volume, false)
	# music player: what's playing, previous / next track
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 3)
	left.add_child(prow)
	var pb := UI.button("<", "gray", Vector2(18, 16))
	pb.tooltip_text = "Previous track"
	pb.pressed.connect(Music.prev)
	prow.add_child(pb)
	now_playing = UI.label("", 10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER)
	now_playing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	now_playing.clip_text = true
	prow.add_child(now_playing)
	var nb := UI.button(">", "gray", Vector2(18, 16))
	nb.tooltip_text = "Next track"
	nb.pressed.connect(Music.next)
	prow.add_child(nb)
	Music.track_changed.connect(_update_now_playing)
	_update_now_playing()

	left.add_child(UI.label("DISPLAY", 10, Color("8b9bb4")))
	var fs_row := HBoxContainer.new()
	left.add_child(fs_row)
	var fl := UI.label("Fullscreen (F11)", 10, Color.WHITE)
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_row.add_child(fl)
	fs_button = UI.button("", "gray", Vector2(50, 16))
	fs_button.pressed.connect(func():
		Game.set_fullscreen(not Game.fullscreen)
		Game.save_progress()
		_update_fs())
	fs_row.add_child(fs_button)
	_update_fs()

	left.add_child(UI.label("CAMERA", 10, Color("8b9bb4")))
	var cam := UI.label("Mouse wheel: zoom in / out. Hold the wheel and drag to move the map.", 10, Color("c0cbdc"))
	cam.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cam.custom_minimum_size = Vector2(180, 0)
	left.add_child(cam)

	# ---- right: key bindings
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("CONTROLS  (click a key, then press a new one)", 10, Color("8b9bb4")))
	# two columns of name + key so all 12 actions fit on the screen
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	right.add_child(grid)
	var half := ceili(Game.ACTIONS.size() / 2.0)
	for i in half:
		for a in [Game.ACTIONS[i], Game.ACTIONS[i + half] if i + half < Game.ACTIONS.size() else ""]:
			if a == "":
				continue
			var nl := UI.label(Game.ACTION_NAMES[a], 10, Color.WHITE)
			nl.custom_minimum_size = Vector2(80, 0)
			grid.add_child(nl)
			var b := UI.button("", "blue", Vector2(64, 15))
			b.pressed.connect(func(): _start_rebind(a))
			grid.add_child(b)
			key_buttons[a] = b
	var bottom := HBoxContainer.new()
	right.add_child(bottom)
	var fixed := UI.label("Esc / right click: cancel, back", 10, Color("5a6988"))
	fixed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(fixed)
	var reset := UI.button("Reset keys", "red", Vector2(80, 16))
	reset.pressed.connect(func():
		Game.reset_keys()
		waiting = ""
		_update_keys())
	bottom.add_child(reset)
	_update_keys()

	var back := UI.button("Back", "green", Vector2(100, 20))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): closed.emit())
	root.add_child(back)
	# center vertically once the panel knows its height
	p.resized.connect(func(): p.position.y = roundf((360.0 - p.size.y) / 2.0))


func _on_volume(v: float, play := true) -> void:
	Game.sfx_volume = v
	vol_label.text = "%d%%" % int(round(v * 100))
	if play:
		Game.save_progress()
		Sfx.play("click")


func _on_music_volume(v: float, save := true) -> void:
	Game.music_volume = v
	Music.apply_volume()
	music_label.text = "%d%%" % int(round(v * 100))
	if save:
		Game.save_progress()


func _update_now_playing() -> void:
	var t: Dictionary = Music.current()
	now_playing.text = "%s - %s" % [t["title"], t["author"]]
	now_playing.tooltip_text = "Now playing: %s by %s" % [t["title"], t["author"]]


func _update_fs() -> void:
	fs_button.text = "On" if Game.fullscreen else "Off"
	UI.color_button(fs_button, "green" if Game.fullscreen else "gray")


func _update_keys() -> void:
	for a in key_buttons:
		var b: Button = key_buttons[a]
		if a == waiting:
			b.text = "Press a key..."
			UI.color_button(b, "gold")
		else:
			b.text = Game.key_label(a)
			UI.color_button(b, "blue")


func _start_rebind(action: String) -> void:
	waiting = action
	_update_keys()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	get_viewport().set_input_as_handled()
	if waiting == "":
		if event.keycode == KEY_ESCAPE:
			closed.emit()
		return
	if event.keycode != KEY_ESCAPE and event.keycode != KEY_F11:
		var pk: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		Game.bind_key(waiting, pk)
		Sfx.play("place")
	waiting = ""
	_update_keys()
