extends Node
## Google Play store graphics, drawn by the game's own code (CLAUDE.md,
## 2026-10-17 store material). Writes to docs/store/graphics/:
##     feature_1024x500.png   the feature graphic: the Gumdrop wordmark over
##                            the splash's sum row (2, 2, 4, 8, the arrow,
##                            16), on the Gumdrop background with a soft glow.
##                            24 bit RGB, no alpha.
##     phone_<n>_<name>.png   phone screenshots, 1080 by 1920, 24 bit RGB:
##                            the real screens (GameScreen, SplashScreen,
##                            InfoPanel, AboutPanel) fed fixed boards with a
##                            seeded RunRandom, so every run is the same.
## The store icon comes from tools/launcher_icon.gd, not from here.
##
## Headless Godot has no renderer, so run it with a window from the repo root:
##     godot --path . --fixed-fps 60 res://tools/store/store_capture.tscn
## It quits by itself. --fixed-fps 60 gives every frame the same time step,
## so looping motion (the active booster's wobble) is at the same point in
## every run and the files repeat byte for byte; the tool refuses to run
## without it. Options after a lone "--":
##     --only <name>   only this file, for example feature or phone_1
## Then check every file's size and format with
##     godot --headless --path . --script res://tools/store/store_check.gd
##
## Chains are drawn by pushing real mouse events into the screen's viewport:
## a press on the first tile and moves through the others, never released,
## so the shot shows the chain line, the preview and the joinable highlight
## the way a finger leaves them mid drag. Nothing is saved.
##
## The safe area is simulated as a small one: SAFE_INSETS on top and at the
## bottom. Script and engine errors logged while a file renders count as
## failures. Exits with 0 when every file was written without errors, else 1.

const Capture: GDScript = preload("res://tools/capture.gd")
const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
const GAME_SCENE: PackedScene = preload("res://scenes/ui/game_screen.tscn")
const SPLASH_SCENE: PackedScene = preload("res://scenes/ui/splash_screen.tscn")
const INFO_SCENE: PackedScene = preload("res://scenes/ui/info_panel.tscn")
const ABOUT_SCENE: PackedScene = preload("res://scenes/ui/about_panel.tscn")

const OUTPUT_DIR: String = "res://docs/store/graphics"
const SHOT_SIZE: Vector2i = Vector2i(1080, 1920)
## The canvas the game lays out on a 9:16 phone. project.godot stretches a
## 1080 by 2400 base with canvas_items and expand, so the canvas is never
## shorter than 2400: on 9:16 it is 1350 by 2400, drawn at 0.8 scale. The
## phone shots do the same, so they show exactly what such a phone shows.
const SHOT_CANVAS: Vector2i = Vector2i(1350, 2400)
const FEATURE_SIZE: Vector2i = Vector2i(1024, 500)
## Top and bottom insets in canvas px (48 and 24 output px): room for a
## status bar and a gesture bar.
const SAFE_INSETS: Vector2 = Vector2(60.0, 30.0)
const WAIT_FRAMES: int = 12
## Info builds its sections over several frames; the most frames to wait.
const INFO_MAX_FRAMES: int = 240
## Pointer moves between two tile centers.
const DRAG_STEPS: int = 4
const SEED: int = 20261017
## The time step --fixed-fps 60 gives, and the frames that check it.
const FIXED_STEP: float = 1.0 / 60.0
const FPS_CHECK_FRAMES: int = 3

## Feature graphic: the sum row's tile side and arrow, and the glow behind
## the brand (surface fading out over bg, like the launcher icon's).
const FEATURE_TILE: float = 84.0
const FEATURE_ARROW: float = 48.0
const GLOW_RADIUS: float = 560.0
const SUM_VALUES: Array[int] = [2, 2, 4, 8]
const SUM_RESULT: int = 16

## Boards, 5 columns by 8 rows, top row first. Every board keeps the window
## floor (GDD section 3): no tile below it, as in real play.
## Gumdrop, highest 4096, floor 8. The chain: 16, 16, 32, 64, 64, 128.
const GUMDROP_BOARD: Array[int] = [
	32, 8, 64, 16, 8,
	8, 256, 16, 32, 64,
	16, 64, 512, 8, 16,
	64, 8, 32, 4096, 32,
	8, 32, 16, 128, 8,
	32, 16, 16, 64, 16,
	8, 64, 32, 64, 8,
	16, 128, 8, 256, 32,
]
const GUMDROP_CHAIN: Array[Vector2i] = [Vector2i(1, 5), Vector2i(2, 5), Vector2i(2, 6), Vector2i(3, 6), Vector2i(3, 5), Vector2i(3, 4)]
## Slate, highest 1024, floor 2. The chain: 4, 4, 8, 16, 32, 32.
const SLATE_BOARD: Array[int] = [
	4, 16, 2, 8, 4,
	2, 8, 64, 4, 16,
	16, 4, 8, 128, 2,
	8, 32, 2, 16, 32,
	2, 1024, 4, 8, 32,
	16, 8, 4, 4, 2,
	4, 2, 8, 16, 8,
	8, 16, 32, 2, 4,
]
const SLATE_CHAIN: Array[Vector2i] = [Vector2i(2, 5), Vector2i(3, 5), Vector2i(3, 4), Vector2i(3, 3), Vector2i(4, 3), Vector2i(4, 4)]
## Nova, highest 8192, floor 16: three stars and one free booster held.
## The chain: 32, 32, 64, 128, 128.
const NOVA_BOARD: Array[int] = [
	64, 16, 128, 32, 16,
	32, 512, 16, 64, 128,
	16, 64, 32, 2048, 32,
	128, 32, 8192, 16, 64,
	16, 64, 32, 256, 16,
	32, 16, 128, 32, 64,
	64, 32, 32, 16, 128,
	16, 1024, 64, 128, 32,
]
const NOVA_CHAIN: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 6)]
## Gumdrop with the Hammer aimed, highest 2048, floor 4.
const TARGET_BOARD: Array[int] = [
	8, 32, 4, 16, 8,
	16, 4, 64, 8, 32,
	4, 128, 16, 32, 4,
	32, 8, 2048, 16, 8,
	8, 16, 4, 256, 32,
	64, 4, 32, 8, 16,
	4, 512, 8, 16, 4,
	16, 8, 32, 4, 64,
]

## The splash's records.
const SPLASH_BEST_SCORE: int = 214880
const SPLASH_BEST_TILE: int = 8192


## One file to write.
class Shot extends RefCounted:
	var file_name: String = ""
	## feature, board, splash, info or about.
	var kind: String = ""
	var skin_id: StringName = &"gumdrop"
	var cells: Array[int] = []
	var score: int = 0
	var best_score: int = 0
	var chain: Array[Vector2i] = []
	var booster: StringName = &""
	var size: Vector2i = Vector2i.ZERO

	func _init(p_file_name: String, p_kind: String, p_skin_id: StringName, p_size: Vector2i) -> void:
		file_name = p_file_name
		kind = p_kind
		skin_id = p_skin_id
		size = p_size


var _catcher: Logger = null
var _audio: AudioService = null


func _ready() -> void:
	_catcher = Capture.ErrorCatcher.new()
	OS.add_logger(_catcher)
	var exit_code: int = await _run()
	OS.remove_logger(_catcher)
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)
	get_tree().quit(exit_code)


func _run() -> int:
	var only: String = ""
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--only":
		only = args[1]
	elif not args.is_empty():
		print("store: unknown options %s" % " ".join(args))
		return 1
	# The engine takes --fixed-fps for itself, so check what it does: every
	# step is exactly 1/60 s.
	for _frame: int in FPS_CHECK_FRAMES:
		await get_tree().process_frame
		if get_process_delta_time() != FIXED_STEP:
			print("store: run with --fixed-fps 60 so the captures repeat (see the top of this script)")
			return 1
	_audio = AudioService.new()
	_audio.set_enabled(false)
	add_child(_audio)
	SafeArea.simulated_insets = SAFE_INSETS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var written: int = 0
	var failed: int = 0
	for shot: Shot in _shots():
		if not only.is_empty() and not shot.file_name.begins_with(only):
			continue
		if await _render(shot):
			written += 1
		else:
			failed += 1
	print("store: %d written, %d failed." % [written, failed])
	return 0 if failed == 0 and written > 0 else 1


func _shots() -> Array[Shot]:
	var shots: Array[Shot] = []
	shots.append(Shot.new("feature_1024x500.png", "feature", &"gumdrop", FEATURE_SIZE))

	var chain: Shot = Shot.new("phone_1_gumdrop_chain.png", "board", &"gumdrop", SHOT_SIZE)
	chain.cells = GUMDROP_BOARD
	chain.score = 58412
	chain.best_score = 96520
	chain.chain = GUMDROP_CHAIN
	shots.append(chain)

	shots.append(Shot.new("phone_2_gumdrop_splash.png", "splash", &"gumdrop", SHOT_SIZE))

	var slate: Shot = Shot.new("phone_3_slate_chain.png", "board", &"slate", SHOT_SIZE)
	slate.cells = SLATE_BOARD
	slate.score = 9640
	slate.best_score = 31208
	slate.chain = SLATE_CHAIN
	shots.append(slate)

	var nova: Shot = Shot.new("phone_4_nova_chain.png", "board", &"nova", SHOT_SIZE)
	nova.cells = NOVA_BOARD
	nova.score = 214880
	nova.best_score = 214880
	nova.chain = NOVA_CHAIN
	shots.append(nova)

	var hammer: Shot = Shot.new("phone_5_gumdrop_hammer.png", "board", &"gumdrop", SHOT_SIZE)
	hammer.cells = TARGET_BOARD
	hammer.score = 31256
	hammer.best_score = 96520
	hammer.booster = &"hammer"
	shots.append(hammer)

	shots.append(Shot.new("phone_6_gumdrop_info.png", "info", &"gumdrop", SHOT_SIZE))
	shots.append(Shot.new("phone_7_gumdrop_about.png", "about", &"gumdrop", SHOT_SIZE))
	return shots


func _render(shot: Shot) -> bool:
	_catcher.call(&"take")
	var skin: SkinData = SkinCatalog.get_skin(shot.skin_id)
	if skin == null or skin.id != shot.skin_id:
		print("FAIL %s: no skin %s" % [shot.file_name, shot.skin_id])
		return false
	var viewport: SubViewport = SubViewport.new()
	viewport.size = shot.size
	if shot.size == SHOT_SIZE:
		viewport.size_2d_override = SHOT_CANVAS
		viewport.size_2d_override_stretch = true
	viewport.transparent_bg = false
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var root: Control = Control.new()
	root.name = "Store"
	root.theme = UiKit.build_theme(skin)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(root)

	var problem: String = ""
	match shot.kind:
		"feature":
			_build_feature(root, skin)
			await _frames(WAIT_FRAMES)
		"board":
			problem = await _build_board(viewport, root, skin, shot)
		"splash":
			var splash: SplashScreen = SPLASH_SCENE.instantiate() as SplashScreen
			root.add_child(splash)
			var records: Records = Records.new()
			records.best_score = BigNum.from_int(SPLASH_BEST_SCORE)
			records.best_tile = _exponent(SPLASH_BEST_TILE)
			splash.setup(skin, records)
			await _frames(WAIT_FRAMES)
		"info":
			var info: InfoPanel = INFO_SCENE.instantiate() as InfoPanel
			root.add_child(info)
			info.setup(skin)
			var waited: int = 0
			while info.stage() != InfoPanel.Stage.DONE and waited < INFO_MAX_FRAMES:
				await get_tree().process_frame
				waited += 1
			if info.stage() != InfoPanel.Stage.DONE:
				problem = "Info did not finish building"
			await _frames(WAIT_FRAMES)
		"about":
			var about: AboutPanel = ABOUT_SCENE.instantiate() as AboutPanel
			root.add_child(about)
			about.setup(skin)
			await _frames(WAIT_FRAMES)
		_:
			problem = "unknown kind %s" % shot.kind

	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	var errors: PackedStringArray = _catcher.call(&"take")
	if not problem.is_empty():
		print("FAIL %s: %s" % [shot.file_name, problem])
		return false
	if not errors.is_empty():
		print("FAIL %s: %s" % [shot.file_name, "; ".join(errors)])
		return false
	if image == null or image.get_size() != shot.size:
		print("FAIL %s: the render is not %dx%d" % [shot.file_name, shot.size.x, shot.size.y])
		return false
	# Play takes 24 bit PNGs for the feature graphic and the screenshots.
	image.convert(Image.FORMAT_RGB8)
	var path: String = ProjectSettings.globalize_path(OUTPUT_DIR.path_join(shot.file_name))
	var err: Error = image.save_png(path)
	if err != OK:
		print("FAIL %s: could not write (error %d)" % [shot.file_name, err])
		return false
	print("ok   %s %dx%d, %d bytes" % [path, image.get_width(), image.get_height(), FileAccess.get_file_as_bytes(path).size()])
	return true


## The feature graphic: the wordmark fitted to the sum row's width, space_m,
## then the row, centered on a glow of surface over the flat bg.
func _build_feature(root: Control, skin: SkinData) -> void:
	var backdrop: SkinBackdrop = UiKit.make_backdrop(skin)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, skin.color(&"surface"))
	gradient.set_color(1, Color(skin.color(&"surface"), 0.0))
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	var glow_texture: GradientTexture2D = GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	glow_texture.width = 512
	glow_texture.height = 512
	var glow: TextureRect = TextureRect.new()
	glow.texture = glow_texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.size = Vector2(GLOW_RADIUS * 2.0, GLOW_RADIUS * 2.0)
	glow.position = Vector2(FEATURE_SIZE) * 0.5 - glow.size * 0.5
	root.add_child(glow)

	var brand: VBoxContainer = UiParts.vbox(skin.num(&"space_m"))
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	var row: HBoxContainer = UiParts.hbox(0.0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiParts.chain_board(skin, _exponents(SUM_VALUES), FEATURE_TILE))
	row.add_child(UiParts.spacer(0.0, skin.num(&"space_m")))
	row.add_child(UiParts.arrow(skin, FEATURE_ARROW))
	row.add_child(UiParts.spacer(0.0, skin.num(&"space_m")))
	var result: SkinTileView = UiParts.tile(skin, _exponent(SUM_RESULT), FEATURE_TILE)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(result)
	var wordmark: SkinWordmark = UiKit.make_wordmark(skin)
	wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wordmark.set_masthead(true)
	wordmark.fit_width(row.get_combined_minimum_size().x)
	brand.add_child(wordmark)
	brand.add_child(row)
	root.add_child(brand)
	var block: Vector2 = brand.get_combined_minimum_size()
	brand.size = block
	brand.position = ((Vector2(FEATURE_SIZE) - block) * 0.5).round()
	print("store: feature brand block %.0f by %.0f at %s; the middle 80%% is %.0f by %.0f" % [block.x, block.y, brand.position, FEATURE_SIZE.x * 0.8, FEATURE_SIZE.y * 0.8])


## The play screen resuming a fixed run, then a chain dragged through it or
## a booster aimed. Returns a problem, or "".
func _build_board(viewport: SubViewport, root: Control, skin: SkinData, shot: Shot) -> String:
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(SEED)
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(shot.best_score)
	var session: GameSession = GameSession.new(null, rng, records)
	var game: GameScreen = GAME_SCENE.instantiate() as GameScreen
	root.add_child(game)
	game.setup(session, Settings.new(), _audio, skin)
	var cells: PackedInt64Array = _exponents(shot.cells)
	var highest: int = 0
	for exponent: int in cells:
		highest = maxi(highest, exponent)
	session.resume(RunState.create(cells, BigNum.from_int(shot.score), PackedInt64Array(), null, highest))
	if session.is_waiting_for_view():
		session.move_shown()
	await _frames(WAIT_FRAMES)

	if shot.booster != &"":
		session.press_booster(shot.booster)
		if session.targeting_booster() != shot.booster:
			return "the %s booster did not enter targeting" % shot.booster
		await _frames(WAIT_FRAMES)
		return ""

	if shot.chain.is_empty():
		return ""
	var view: SkinBoardView = game.board().get_node(^"SkinBoardView") as SkinBoardView
	if view == null:
		return "no board view"
	# The chain the board built, from its own signal.
	var built: Array[Vector2i] = []
	game.board().chain_changed.connect(func(cells_now: Array[Vector2i], _preview: int) -> void:
		built.assign(cells_now))
	var points: Array[Vector2] = []
	for cell: Vector2i in shot.chain:
		points.append(view.get_global_transform() * view.cell_rect(cell).get_center())
	_push_button(viewport, points[0])
	for i: int in range(1, points.size()):
		for step: int in DRAG_STEPS:
			_push_motion(viewport, points[i - 1].lerp(points[i], float(step + 1) / float(DRAG_STEPS)))
			await get_tree().process_frame
	await _frames(WAIT_FRAMES)
	if not session.is_dragging():
		return "the drag did not start"
	if built != shot.chain:
		return "the board built the chain %s, not %s" % [built, shot.chain]
	print("store: %s chain of %d tiles held mid drag, preview %d" % [shot.file_name, built.size(), session.preview_value(built)])
	return ""


## A left button press at point, in the viewport's own coordinates.
func _push_button(viewport: SubViewport, point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = point
	event.global_position = point
	viewport.push_input(event, true)


## A move to point with the left button held.
func _push_motion(viewport: SubViewport, point: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = point
	event.global_position = point
	viewport.push_input(event, true)


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().process_frame


## The exponent k of a tile value 2^k, as boards and skins take it since
## 2026-10-21 (ARCHITECTURE.md 17); 0 for 0 (empty). The shots keep writing
## tile values, which read more plainly.
static func _exponent(value: int) -> int:
	if value <= 0:
		return 0
	var k: int = 0
	while (1 << k) < value:
		k += 1
	return k


static func _exponents(values: Array[int]) -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for value: int in values:
		cells.append(_exponent(value))
	return cells
