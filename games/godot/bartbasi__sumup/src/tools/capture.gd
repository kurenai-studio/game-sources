extends Node
## Screenshot capture for the design directions.
##
## Headless Godot has no renderer, so this runs with a window and quits by
## itself when done. From the repo root:
##     godot --path . res://tools/capture.tscn
## captures every direction's four screens (twelve PNGs) to
## docs/design/<direction id>-<screen>.png.
##
## Options go after a lone "--":
##     --direction <id>      only this direction
##     --screen <name>       only this screen (board, targeting, gameover, settings)
##     --scene <res path>    capture this one scene instead, needs --out
##     --out <path>          output PNG, relative to the repo root or absolute
##     --font <path>         render all type with this font file (absolute path,
##                           outside the repo), for the font comparison
##     --suffix <text>       added to the default file names, for example -outfit
##     --frames <n>          frames to wait before grabbing, default 12
##     --size <w>x<h>        canvas size, default 1080x2400
##     --safe <top>,<bottom> simulated safe area in px, default 120,66
## Examples:
##     godot --path . res://tools/capture.tscn -- --direction nova --screen board
##     godot --path . res://tools/capture.tscn -- --scene res://tools/directions/slate/board/board_sheet.tscn --out docs/design/review/board-slate-sheet.png
##
## Every scene renders into its own SubViewport (1080 by 2400 unless --size) with no MSAA,
## the same as the game will. Script errors and engine errors logged while a
## scene loads or renders count as failures. Exits with code 0 when every PNG
## was written and nothing failed, and 1 otherwise.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")

const DEFAULT_WAIT_FRAMES: int = 12
const OUTPUT_DIR: String = "res://docs/design"


## Collects errors logged while a capture runs. Godot can log from any thread,
## so access goes through a mutex.
class ErrorCatcher extends Logger:
	var _mutex: Mutex = Mutex.new()
	var _errors: PackedStringArray = PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		var text: String = rationale if not rationale.is_empty() else code
		_mutex.lock()
		_errors.append("%s in %s() at %s:%d: %s" % [_kind(error_type), function, file, line, text])
		_mutex.unlock()

	## Returns the errors logged since the last call and clears the list.
	func take() -> PackedStringArray:
		_mutex.lock()
		var result: PackedStringArray = _errors
		_errors = PackedStringArray()
		_mutex.unlock()
		return result

	func _kind(error_type: int) -> String:
		match error_type:
			Logger.ERROR_TYPE_SCRIPT:
				return "script error"
			Logger.ERROR_TYPE_SHADER:
				return "shader error"
		return "error"


## One scene to render and the file to write.
class CaptureJob extends RefCounted:
	var scene_path: String
	var out_path: String

	func _init(p_scene_path: String, p_out_path: String) -> void:
		scene_path = p_scene_path
		out_path = p_out_path


var _catcher: ErrorCatcher = ErrorCatcher.new()
var _preview: TextureRect = null
var _canvas: Vector2i = MockState.CANVAS_SIZE


func _ready() -> void:
	OS.add_logger(_catcher)
	_preview = TextureRect.new()
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_preview)
	var exit_code: int = await _run()
	OS.remove_logger(_catcher)
	get_tree().quit(exit_code)


func _run() -> int:
	var options: Dictionary = _parse_options(OS.get_cmdline_user_args())
	if options.has("error"):
		print("capture: %s" % options["error"])
		return 1
	var font_path: String = String(options.get("font", ""))
	if not font_path.is_empty():
		if not FileAccess.file_exists(font_path):
			print("capture: font file not found: %s" % font_path)
			return 1
		DirectionTokens.use_font_file(font_path)
		print("capture: all type uses %s" % font_path)
	var jobs: Array[CaptureJob] = _build_jobs(options)
	if jobs.is_empty():
		print("capture: nothing to capture")
		return 1
	var wait_frames: int = int(options.get("frames", DEFAULT_WAIT_FRAMES))
	if options.has("safe"):
		var insets: PackedStringArray = String(options["safe"]).split(",")
		MockState.use_safe_area(insets[0].to_int(), insets[1].to_int())
	_canvas = MockState.CANVAS_SIZE
	if options.has("size"):
		var parts: PackedStringArray = String(options["size"]).split("x")
		_canvas = Vector2i(parts[0].to_int(), parts[1].to_int())
	var failed: int = 0
	for job: CaptureJob in jobs:
		var ok: bool = await _capture(job, wait_frames)
		if not ok:
			failed += 1
	print("capture: %d of %d written without errors." % [jobs.size() - failed, jobs.size()])
	return 0 if failed == 0 else 1


func _parse_options(args: PackedStringArray) -> Dictionary:
	var options: Dictionary = {}
	var keys: PackedStringArray = ["direction", "screen", "scene", "out", "font", "suffix", "frames", "size", "safe"]
	var i: int = 0
	while i < args.size():
		var arg: String = args[i]
		var key: String = arg.trim_prefix("--")
		if not arg.begins_with("--") or not keys.has(key):
			return {"error": "unknown option '%s'" % arg}
		if i + 1 >= args.size():
			return {"error": "option '%s' needs a value" % arg}
		options[key] = args[i + 1]
		i += 2
	if options.has("scene") != options.has("out"):
		return {"error": "--scene and --out go together"}
	if options.has("direction") and not Directions.IDS.has(String(options["direction"])):
		return {"error": "unknown direction '%s'" % options["direction"]}
	if options.has("screen") and not Directions.SCREENS.has(String(options["screen"])):
		return {"error": "unknown screen '%s'" % options["screen"]}
	if options.has("frames") and int(options["frames"]) < 1:
		return {"error": "--frames needs a whole number of at least 1"}
	if options.has("size"):
		var parts: PackedStringArray = String(options["size"]).split("x")
		if parts.size() != 2 or parts[0].to_int() < 100 or parts[1].to_int() < 100:
			return {"error": "--size looks like 1080x1920"}
	if options.has("safe"):
		var insets: PackedStringArray = String(options["safe"]).split(",")
		if insets.size() != 2 or not insets[0].is_valid_int() or not insets[1].is_valid_int():
			return {"error": "--safe looks like 72,144"}
	return options


func _build_jobs(options: Dictionary) -> Array[CaptureJob]:
	var jobs: Array[CaptureJob] = []
	if options.has("scene"):
		jobs.append(CaptureJob.new(String(options["scene"]), _absolute(String(options["out"]))))
		return jobs
	var suffix: String = String(options.get("suffix", ""))
	for direction_id: String in Directions.IDS:
		if options.has("direction") and direction_id != String(options["direction"]):
			continue
		for screen: String in Directions.SCREENS:
			if options.has("screen") and screen != String(options["screen"]):
				continue
			var out_path: String = ProjectSettings.globalize_path("%s/%s-%s%s.png" % [OUTPUT_DIR, direction_id, screen, suffix])
			jobs.append(CaptureJob.new(Directions.screen_path(direction_id, screen), out_path))
	return jobs


func _capture(job: CaptureJob, wait_frames: int) -> bool:
	_catcher.take()
	if not ResourceLoader.exists(job.scene_path):
		print("FAIL %s: scene not found" % job.scene_path)
		return false
	var packed: PackedScene = load(job.scene_path) as PackedScene
	if packed == null:
		_print_failure(job, PackedStringArray(["could not load the scene"]) + _catcher.take())
		return false
	var viewport: SubViewport = SubViewport.new()
	viewport.size = _canvas
	viewport.transparent_bg = false
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	viewport.add_child(packed.instantiate())
	_preview.texture = viewport.get_texture()
	for _frame: int in wait_frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	_preview.texture = null
	viewport.queue_free()
	var problems: PackedStringArray = _catcher.take()
	if image == null or image.get_size() != _canvas:
		problems.append("rendered image is missing or not %dx%d" % [_canvas.x, _canvas.y])
	else:
		DirAccess.make_dir_recursive_absolute(job.out_path.get_base_dir())
		var err: Error = image.save_png(job.out_path)
		if err != OK:
			problems.append("could not write the PNG (error %d)" % err)
	if not problems.is_empty():
		_print_failure(job, problems)
		return false
	print("ok   %s -> %s (%dx%d)" % [job.scene_path, job.out_path, image.get_width(), image.get_height()])
	return true


func _print_failure(job: CaptureJob, problems: PackedStringArray) -> void:
	print("FAIL %s" % job.scene_path)
	for problem: String in problems:
		print("       %s" % problem)


## An output path relative to the repo root, or an absolute one, as an
## absolute file system path.
func _absolute(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():
		return path
	return ProjectSettings.globalize_path("res://").path_join(path)
