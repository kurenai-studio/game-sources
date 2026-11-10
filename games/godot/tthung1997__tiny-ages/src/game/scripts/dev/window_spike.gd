class_name WindowSpike
extends Node2D
## Dev scene for the desktop-window spike. Lets a human (and tooling) exercise the
## strip / corner / window modes, always-on-top, click-through and frame-rate caps.
##
## Keys: 1/2/3 mode · +/- scale · T on-top · P click-through · F fps cap · L low-processor
##       N next screen · H hide HUD · Esc/Q quit
## Launch args (after `--`): --mode=strip|corner|window --scale=N --fps=N --screen=N
##       --no-ontop --no-passthrough --no-lowproc --no-hud --shot=<png path> (save the
##       rendered viewport, with alpha, after a moment and quit)

const WALK_SHEET: Texture2D = preload("res://assets/preview/villager_walk.png")
const WALK_CELL: Vector2i = Vector2i(28, 30)
const WALK_FRAMES: int = 4
const WALK_FPS: float = 6.0
const WALK_SPEED: float = 18.0
const WALK_Y: float = 46.0
const WALK_MIN_X: float = 14.0
const WALK_MAX_X: float = 280.0
const HUD_INTERVAL: float = 0.5
const FLASH_COLOR: Color = Color(1.5, 1.5, 1.5)
const FLASH_SECONDS: float = 0.25
const SHOT_DELAY_SECONDS: float = 2.0
const HUD_REGION: Rect2i = Rect2i(0, 0, 280, 56)

var _direction: float = 1.0
var _hud_timer: float = 0.0
var _shot_path: String = ""

@onready var _window: DesktopWindow = $DesktopWindow
@onready var _sky: Sprite2D = $World/Sky
@onready var _far_hills: Sprite2D = $World/FarHills
@onready var _world: Node2D = $World
@onready var _walker: AnimatedSprite2D = $World/Walker
@onready var _hud: Label = $World/Hud


func _ready() -> void:
	_walker.sprite_frames = _build_walk_frames()
	_walker.position = Vector2(WALK_MIN_X + 40.0, WALK_Y)
	_walker.play(&"walk")
	_window.layout_changed.connect(_on_layout_changed)
	var show_hud: bool = _apply_cmdline()
	_hud.visible = show_hud
	_update_hud_region()
	_window.apply()
	if not _shot_path.is_empty():
		await get_tree().create_timer(SHOT_DELAY_SECONDS).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


func _process(delta: float) -> void:
	_walker.position.x += WALK_SPEED * _direction * delta
	if _walker.position.x > WALK_MAX_X:
		_direction = -1.0
	elif _walker.position.x < WALK_MIN_X:
		_direction = 1.0
	_walker.flip_h = _direction < 0.0
	_hud_timer -= delta
	if _hud_timer <= 0.0 and _hud.visible:
		_hud_timer = HUD_INTERVAL
		_hud.text = _hud_text()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_flash()
		return
	if event is not InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			_window.set_mode(DesktopWindow.Mode.STRIP)
		KEY_2:
			_window.set_mode(DesktopWindow.Mode.CORNER)
		KEY_3:
			_window.set_mode(DesktopWindow.Mode.WINDOW)
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			_window.set_pixel_scale(_window.pixel_scale + 1)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_window.set_pixel_scale(_window.pixel_scale - 1)
		KEY_T:
			_window.set_always_on_top(not _window.always_on_top)
		KEY_P:
			_window.set_click_through(not _window.click_through)
		KEY_F:
			_window.cycle_fps_cap()
		KEY_L:
			_window.set_low_processor(not _window.low_processor)
		KEY_N:
			_window.move_to_next_screen()
		KEY_H:
			_hud.visible = not _hud.visible
			_update_hud_region()
		KEY_ESCAPE, KEY_Q:
			get_tree().quit()


func _on_layout_changed(_content_size: Vector2i) -> void:
	_world.position = Vector2(_window.art_origin())
	# Only the opaque window shows the full diorama; on the desktop the sky and far hills would
	# cover the user's apps, so strip/corner keep the near hills, tree line and ground.
	var full_scene: bool = _window.mode == DesktopWindow.Mode.WINDOW
	_sky.visible = full_scene
	_far_hills.visible = full_scene


func _update_hud_region() -> void:
	var regions: Array[Rect2i] = []
	if _hud.visible:
		regions.append(HUD_REGION)
	_window.set_extra_regions(regions)


func _flash() -> void:
	_world.modulate = FLASH_COLOR
	create_tween().tween_property(_world, "modulate", Color.WHITE, FLASH_SECONDS)


func _build_walk_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", WALK_FPS)
	frames.set_animation_loop(&"walk", true)
	for index: int in WALK_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = WALK_SHEET
		atlas.region = Rect2(Vector2(WALK_CELL.x * index, 0), Vector2(WALK_CELL))
		frames.add_frame(&"walk", atlas)
	return frames


## Returns whether the HUD should start visible.
func _apply_cmdline() -> bool:
	var show_hud: bool = true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			match arg.trim_prefix("--mode="):
				"strip":
					_window.mode = DesktopWindow.Mode.STRIP
				"corner":
					_window.mode = DesktopWindow.Mode.CORNER
				"window":
					_window.mode = DesktopWindow.Mode.WINDOW
				_:
					push_warning("Unknown mode in %s" % arg)
		elif arg.begins_with("--scale="):
			_window.pixel_scale = clampi(
				arg.trim_prefix("--scale=").to_int(),
				DesktopWindow.MIN_SCALE,
				DesktopWindow.MAX_SCALE,
			)
		elif arg.begins_with("--fps="):
			_window.fps_cap = maxi(arg.trim_prefix("--fps=").to_int(), 0)
		elif arg.begins_with("--screen="):
			get_window().current_screen = clampi(
				arg.trim_prefix("--screen=").to_int(), 0, DisplayServer.get_screen_count() - 1
			)
		elif arg == "--no-ontop":
			_window.always_on_top = false
		elif arg == "--no-passthrough":
			_window.click_through = false
		elif arg == "--no-lowproc":
			_window.low_processor = false
		elif arg == "--no-hud":
			show_hud = false
		elif arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
	return show_hud


func _hud_text() -> String:
	var window: Window = get_window()
	var mode_name: String = DesktopWindow.Mode.keys()[_window.mode]
	return "%s x%d  win %s @ %s  screen %d/%d (usable %s, scale %.2f)\n" % [
		mode_name,
		_window.pixel_scale,
		window.size,
		window.position,
		window.current_screen + 1,
		DisplayServer.get_screen_count(),
		DisplayServer.screen_get_usable_rect(window.current_screen).size,
		DisplayServer.screen_get_scale(window.current_screen),
	] + "top %s [T]  click-thru %s [P]  low-proc %s [L]\n" % [
		_on_off(_window.always_on_top), _on_off(_window.click_through),
		_on_off(_window.low_processor),
	] + "fps cap %d [F]  actual %d\n" % [
		_window.fps_cap, int(Performance.get_monitor(Performance.TIME_FPS))
	] + "[1/2/3] mode  [+/-] scale  [N] screen  [H] hud  [Esc] quit"


func _on_off(value: bool) -> String:
	return "ON" if value else "off"
