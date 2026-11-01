extends Node
## Renders the mockups of the 2026-10-13 additions (DESIGN_SYSTEM.md 7.2,
## 7.3, 7.7, 7.11 to 7.14 and the star sections of 4.7, 5.7 and 6.7) to
## docs/design/additions/<skin>-<page>.png, 1080 by 2400, and prints the
## measurements each page takes (wordmark size, brand position, counter
## extents, scroll heights).
##
## Headless Godot has no renderer, so run it with a window from the repo root:
##     godot --path . res://tools/additions/additions_capture.tscn
## It quits by itself. Options after a lone "--":
##     --skin <id>     only this skin
##     --page <name>   only this page (see additions_page.gd)
## Script and engine errors logged while a page renders count as failures.
## Exits with 0 when every PNG was written without errors, else 1.

const Capture: GDScript = preload("res://tools/capture.gd")
const Page: GDScript = preload("res://tools/additions/additions_page.gd")

const PAGES: PackedStringArray = ["menu", "play_star", "play_free", "pause", "settings", "howto", "howto_end", "about", "license", "icons"]
const OUTPUT_DIR: String = "res://docs/design/additions"
const CANVAS: Vector2i = Vector2i(1080, 2400)
const WAIT_FRAMES: int = 10

var _catcher: Logger = null


func _ready() -> void:
	_catcher = Capture.ErrorCatcher.new()
	OS.add_logger(_catcher)
	var exit_code: int = await _run()
	OS.remove_logger(_catcher)
	get_tree().quit(exit_code)


func _run() -> int:
	var only_skin: String = ""
	var only_page: String = ""
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in range(0, args.size() - 1, 2):
		if args[i] == "--skin":
			only_skin = args[i + 1]
		elif args[i] == "--page":
			only_page = args[i + 1]
		else:
			print("additions: unknown option '%s'" % args[i])
			return 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var written: int = 0
	var failed: int = 0
	for skin_id: StringName in SkinCatalog.IDS:
		if not only_skin.is_empty() and String(skin_id) != only_skin:
			continue
		for page_name: String in PAGES:
			if not only_page.is_empty() and page_name != only_page:
				continue
			if await _render(skin_id, page_name):
				written += 1
			else:
				failed += 1
	print("additions: %d written, %d failed." % [written, failed])
	return 0 if failed == 0 and written > 0 else 1


func _render(skin_id: StringName, page_name: String) -> bool:
	_catcher.call(&"take")
	var viewport: SubViewport = SubViewport.new()
	viewport.size = CANVAS
	viewport.transparent_bg = false
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var page: Control = Page.new()
	page.set(&"skin_id", skin_id)
	page.set(&"page", page_name)
	viewport.add_child(page)
	for _frame: int in WAIT_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	var out_path: String = ProjectSettings.globalize_path("%s/%s-%s.png" % [OUTPUT_DIR, skin_id, page_name])
	var problems: PackedStringArray = _catcher.call(&"take")
	if image == null:
		problems.append("no image")
	elif image.save_png(out_path) != OK:
		problems.append("could not write %s" % out_path)
	var report: PackedStringArray = page.get(&"report")
	viewport.queue_free()
	await get_tree().process_frame
	if not problems.is_empty():
		print("FAIL %s %s" % [skin_id, page_name])
		for problem: String in problems:
			print("       %s" % problem)
		return false
	print("ok   %s %s -> %s" % [skin_id, page_name, out_path])
	for line: String in report:
		print("       %s" % line)
	return true
