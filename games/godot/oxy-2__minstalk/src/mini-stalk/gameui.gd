extends CanvasLayer

# start menu + death screen. plain buttons now, swap for png hit-areas later.

const BG_PATH := "res://assets/art/menus/pda/menu_screen_pda.png"      # <<< PUT YOUR MENU/DEATH PDA FILE PATH HERE (e.g. "res://sprites/pda.png")
const INTRO_PATH := "res://assets/art/menus/title screen/menu_screen_pda.png"   # <<< PUT YOUR SECOND (INTRO) SPRITE FILE PATH HERE
const INTRO_TIME := 3.0                      # <<< how long the intro stays on screen (seconds)
const PDA_SCALE := 1.25                      # <<< SIZE: sprite side = screen height * this. Bigger number = bigger PDA

const END_X := 3325.0
const END_Y := -1045
const END_FADE := 2.0

# <<< BUTTON AREA: where the PDA's light screen is, as fractions of the sprite (0.0 - 1.0).
# Nudge these if the buttons don't sit perfectly inside the screen.
const SCREEN_LEFT := 0.12
const SCREEN_RIGHT := 0.70
const SCREEN_TOP := 0.28
const SCREEN_BOTTOM := 0.72

var endscreen: Control
var _ended := false
var menu: Control
var death: Control
var intro: Control
var hpbar: Control
var hpfill: ColorRect
var hplabel: Label
var _panels: Array = []   # every PDA panel, so they can all be resized together
static var _skip_menu := false
static var _intro_done := false   # stays true after the first launch, so restarts skip the intro
var _maxhp := 10

func _ready() -> void:
	add_to_group("gameui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()
	_build_death()
	_build_hp()
	_build_intro()   # built last so it draws on top of everything
	_build_end()
	_resize_panels()
	get_viewport().size_changed.connect(_resize_panels)
	print("gameui ready, skip=", _skip_menu)
	if _skip_menu:
		_skip_menu = false
		intro.visible = false
		start_game()
	elif not _intro_done:
		show_intro()
	else:
		intro.visible = false
		show_menu()

func _process(_delta: float) -> void:
	hpbar.visible = not (intro.visible or menu.visible or death.visible or _ended)
	if _ended:
		return
	_update_hp()
	_check_end()

# ---------- intro ----------

func _build_intro() -> void:
	intro = Control.new()
	intro.name = "Intro"
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.process_mode = Node.PROCESS_MODE_ALWAYS
	intro.mouse_filter = Control.MOUSE_FILTER_STOP   # blocks clicks on the menu underneath

	# no dark overlay here, the menu underneath already has one

	var frame = Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_CENTER)
	intro.add_child(frame)

	var spr = TextureRect.new()
	spr.texture = load(INTRO_PATH)
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_SCALE
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # uncomment for crisp pixel art
	spr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(spr)

	_panels.append({"frame": frame})   # resized together with the other panels
	add_child(intro)

func show_intro() -> void:
	get_tree().paused = true
	menu.visible = true     # menu is drawn underneath the intro
	death.visible = false
	intro.visible = true
	await get_tree().create_timer(INTRO_TIME).timeout
	_intro_done = true
	intro.visible = false   # instant snap to the menu underneath

# ---------- PDA panels (menu + death) ----------

# builds the PDA sprite with a title and buttons inside its screen
# buttons = [["Text", callable], ...]
func _make_pda_panel(parent: Control, title_text: String, buttons: Array) -> void:
	var frame = Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_CENTER)   # anchored to screen center, size set in _resize_panels
	parent.add_child(frame)

	var spr = TextureRect.new()
	spr.texture = load(BG_PATH)
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_SCALE
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # uncomment for crisp pixel art
	spr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(spr)

	# the area inside the PDA's screen
	var screen = Control.new()
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.anchor_left = SCREEN_LEFT
	screen.anchor_right = SCREEN_RIGHT
	screen.anchor_top = SCREEN_TOP
	screen.anchor_bottom = SCREEN_BOTTOM
	frame.add_child(screen)

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(box)

	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))   # dark text on the light screen
	box.add_child(title)

	var btns: Array = []
	for b in buttons:
		var btn = Button.new()
		btn.text = b[0]
		btn.pressed.connect(b[1])
		box.add_child(btn)
		btns.append(btn)

	_panels.append({"frame": frame, "box": box, "title": title, "buttons": btns})

func _resize_panels() -> void:
	var vp := get_viewport().get_visible_rect().size
	var side := vp.y * PDA_SCALE
	var u := side / 800.0   # scale factor for fonts and button sizes
	for p in _panels:
		var f: Control = p["frame"]
		f.offset_left = -side / 2.0
		f.offset_right = side / 2.0
		f.offset_top = -side / 2.0
		f.offset_bottom = side / 2.0
		if not p.has("box"):
			continue   # the intro has no title or buttons
		p["box"].add_theme_constant_override("separation", int(14 * u))
		p["title"].add_theme_font_size_override("font_size", int(46 * u))
		for btn in p["buttons"]:
			btn.custom_minimum_size = Vector2(0, 46 * u)   # width fills the PDA screen
			btn.add_theme_font_size_override("font_size", int(22 * u))

# ---------- HP bar ----------

func _build_hp() -> void:
	hpbar = Control.new()
	hpbar.name = "HPBar"
	hpbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hpbar.offset_left = 16
	hpbar.offset_top = 16
	hpbar.offset_right = 236
	hpbar.offset_bottom = 52
	hpbar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.08, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hpbar.add_child(bg)

	hpfill = ColorRect.new()
	hpfill.color = Color(0.2, 0.85, 0.25, 0.95)
	hpfill.offset_left = 3
	hpfill.offset_top = 3
	hpfill.offset_right = 217
	hpfill.offset_bottom = 33
	hpfill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hpfill)

	hplabel = Label.new()
	hplabel.text = "10 / 10"
	hplabel.add_theme_font_size_override("font_size", 16)
	hplabel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hplabel.offset_left = 8
	hplabel.offset_top = 6
	hplabel.offset_right = -8
	hplabel.offset_bottom = -4
	hplabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hplabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hplabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hplabel)

	add_child(hpbar)

func _update_hp() -> void:
	var hp := 0
	var p = get_tree().get_first_node_in_group("player")
	if p != null and is_instance_valid(p) and "health" in p:
		hp = max(int(p.health), 0)
		_maxhp = max(_maxhp, hp)
	var ratio = float(hp) / float(max(_maxhp, 1))
	hpfill.offset_right = 3 + (214.0 * ratio)
	hpfill.color = Color(0.85, 0.15, 0.15).lerp(Color(0.2, 0.85, 0.25), ratio)
	hplabel.text = "%d / %d" % [hp, _maxhp]

# ---------- menu / death ----------

func _build_menu() -> void:
	menu = Control.new()
	menu.name = "Menu"
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(bg)

	_make_pda_panel(menu, "MiniStalk", [
		["Start", start_game],
		["Quit", quit_game],
	])

	add_child(menu)

func _build_death() -> void:
	death = Control.new()
	death.name = "DeathScreen"
	death.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death.add_child(bg)

	_make_pda_panel(death, "You Died", [
		["Restart", restart],
		["Quit", quit_game],
	])

	add_child(death)

func show_menu() -> void:
	get_tree().paused = true
	menu.visible = true
	death.visible = false
	print("menu shown, paused=", get_tree().paused)

func start_game() -> void:
	menu.visible = false
	death.visible = false
	get_tree().paused = false

func show_death() -> void:
	get_tree().paused = true
	menu.visible = false
	death.visible = true

func restart() -> void:
	_skip_menu = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_game() -> void:
	get_tree().quit()

func _build_end() -> void:
	endscreen = Control.new()
	endscreen.name = "EndScreen"
	endscreen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	endscreen.process_mode = Node.PROCESS_MODE_ALWAYS
	endscreen.mouse_filter = Control.MOUSE_FILTER_STOP
	endscreen.visible = false

	var white = ColorRect.new()
	white.color = Color.WHITE
	white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endscreen.add_child(white)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endscreen.add_child(center)

	var label = Label.new()
	label.text = "Thanks for playing"
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	center.add_child(label)

	add_child(endscreen)   # added last so it draws on top of everything

func _check_end() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector2 = p.global_position
	if pos.x >= END_X or pos.y < END_Y:   # use <= instead if the end is to the left / upward
		start_end()

func start_end() -> void:
	_ended = true
	get_tree().paused = true   # freeze the game (this node still runs, so the fade works)
	endscreen.visible = true
	endscreen.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(endscreen, "modulate:a", 1.0, END_FADE)
