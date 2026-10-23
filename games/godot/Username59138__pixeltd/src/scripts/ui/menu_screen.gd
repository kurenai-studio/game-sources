class_name MenuScreen
extends Control
## Title screen: logo on top, PLAY / TOWERS at the bottom, live battle diorama behind.


# preload instead of the global class name: works even if the editor class cache is stale
const SettingsScreenScript := preload("res://scripts/ui/settings_screen.gd")
const Changelog := preload("res://scripts/data/changelog.gd")
const CheatsScreenScript := preload("res://scripts/ui/cheats_screen.gd")

var main: Node
var logo: TextureRect
var t := 0.0
var changelog: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# soft darkening bands so the UI reads well on top of the busy map
	var top := ColorRect.new()
	top.color = Color(0.06, 0.05, 0.1, 0.45)
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 104)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var bottom := ColorRect.new()
	bottom.color = Color(0.06, 0.05, 0.1, 0.55)
	bottom.position = Vector2(0, 300)
	bottom.size = Vector2(640, 60)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)

	logo = TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.size = logo.texture.get_size() * 2
	logo.position = Vector2(roundf((640 - logo.size.x) / 2.0), 14)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	var sub := UI.label("A  PIXEL  TOWER  DEFENSE", 10, Color("c0cbdc"), HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, 86)
	sub.size = Vector2(640, 12)
	add_child(sub)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.position = Vector2(320 - 160, 310)
	row.size = Vector2(320, 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	var play := UI.button("PLAY", "green", Vector2(130, 36), 20)
	play.icon = load("res://assets/ui/icons/play.png")
	play.pressed.connect(func(): Sfx.play("click"); main.show_map_select())
	row.add_child(play)
	var towers := UI.button("TOWERS", "blue", Vector2(130, 36), 20)
	towers.icon = load("res://assets/ui/icons/shield.png")
	towers.pressed.connect(func(): Sfx.play("click"); main.show_towers())
	row.add_child(towers)
	var gear := UI.button("", "gray", Vector2(36, 36))
	gear.tooltip_text = "Settings"
	var gear_icon := UI.sprite_rect("res://assets/ui/icons/gear.png", 2)
	gear_icon.position = Vector2(8, 7)
	gear_icon.size = Vector2(18, 18)
	gear.add_child(gear_icon)
	gear.pressed.connect(_open_settings)
	row.add_child(gear)

	var quit := UI.button("Quit", "red", Vector2(40, 16))
	quit.position = Vector2(594, 338)
	quit.pressed.connect(func(): get_tree().quit())
	add_child(quit)
	var news := UI.button("Changelog", "gray", Vector2(76, 16))
	news.position = Vector2(6, 338)
	news.pressed.connect(_open_changelog)
	add_child(news)
	if Game.cheats:
		var ch := UI.button("Cheats", "purple", Vector2(56, 16))
		ch.position = Vector2(88, 338)
		ch.pressed.connect(_open_cheats)
		add_child(ch)
	var ver := UI.label("v%s  -  F11 fullscreen" % Changelog.ENTRIES[0]["version"], 10, Color("8b9bb4"))
	ver.position = Vector2(6, 324)
	add_child(ver)
	# progress summary
	var stars := 0
	for m in Game.beaten:
		stars += (Game.beaten[m] as Array).size()
	var prog := HBoxContainer.new()
	prog.alignment = BoxContainer.ALIGNMENT_END
	prog.position = Vector2(480, 6)
	prog.size = Vector2(154, 12)
	add_child(prog)
	prog.add_child(UI.icon("star"))
	prog.add_child(UI.label("%d/%d" % [stars, Game.MapsData.ORDER.size() * 4], 10, Color("fee761")))
	prog.add_child(UI.label("  ", 10))
	prog.add_child(UI.icon("map"))
	prog.add_child(UI.label(str(Game.paper_maps), 10, Color("fee761")))


func _open_settings() -> void:
	Sfx.play("click")
	var st := SettingsScreenScript.new()
	add_child(st)
	st.closed.connect(st.queue_free)


func _open_cheats() -> void:
	Sfx.play("click")
	var c := CheatsScreenScript.new()
	add_child(c)
	c.closed.connect(func(): main.show_menu())   # rebuilds the menu so the stars and paper maps are current


func _open_changelog() -> void:
	Sfx.play("click")
	changelog = Control.new()
	changelog.set_anchors_preset(Control.PRESET_FULL_RECT)
	changelog.mouse_filter = Control.MOUSE_FILTER_STOP
	changelog.add_child(UI.dim_rect(0.7))
	add_child(changelog)
	var p := UI.panel("panel", 8)
	p.position = Vector2(110, 24)
	p.size = Vector2(420, 312)
	changelog.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(UI.title("CHANGELOG", 16))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(404, 242)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.style_scrollbar(scroll.get_v_scroll_bar())
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	for e in Changelog.ENTRIES:
		list.add_child(UI.label("v%s  -  %s" % [e["version"], e["title"]], 10, Color("fee761")))
		list.add_child(UI.label(e["date"], 10, Color("8b9bb4")))
		for item in e["items"]:
			var l := UI.label("- " + item, 10, Color("f77622") if item.begins_with("HALLOWEEN") else Color("c0cbdc"))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(392, 0)
			list.add_child(l)
		list.add_child(Control.new())
	var close := UI.button("Close", "red", Vector2(90, 20))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_changelog)
	v.add_child(close)


func _close_changelog() -> void:
	if is_instance_valid(changelog):
		changelog.queue_free()
	changelog = null


func _unhandled_key_input(event: InputEvent) -> void:
	if changelog and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_changelog()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	t += delta
	logo.position.y = 14 + roundf(sin(t * 2.0) * 2.0)
