# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Draws the same route lines two ways on a plain background and compares the pictures: with
## MapRoutes (arrows, dashes and dots as quads of the sheet) and with MapArt.draw_route, the
## art director's own drawing, which MapRoutes replaced for speed. Needs a display:
##
##     godot --path . --script res://tests/render/route_compare.gd -- --out=<folder>
##
## Prints the share of pixels that differ and the draw calls of each way (the main window is empty), and saves both pictures
## and the difference in <folder>. The fixture is the sim's bridge map with a gate, its walker
## routes, the same routes as gate breakers' routes, and a flyer's line.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const SIZE: Vector2i = Vector2i(896, 1024)

var _out: String = ""


class Plain:
	extends Node2D
	var routes: Array[Dictionary] = []
	var walk: Array[PackedVector2Array] = []
	var breaker: Array[PackedVector2Array] = []
	var fly: Array[PackedVector2Array] = []

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(896.0, 1024.0)), Color("e8cc9c"))
		for line: PackedVector2Array in fly:
			MapArt.draw_route(self, line, 128.0, MapArt.Route.FLY, 0.0)
		for part: PackedVector2Array in breaker:
			MapArt.draw_route(self, part, 128.0, MapArt.Route.BREAK, 0.0)
		for part: PackedVector2Array in walk:
			MapArt.draw_route(self, part, 128.0, MapArt.Route.WALK, 0.0)


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _viewport() -> SubViewport:
	var host: SubViewport = SubViewport.new()
	host.size = SIZE
	host.transparent_bg = false
	host.disable_3d = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	return host


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("route_compare.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	var stats: Catalog = Sx.catalog()
	var grid: Array = Sx.get_script_constant_map()["BRIDGE_GATE_GRID"]
	var data: Dictionary = Sx.level_data(grid, [{"groups": [Sx.group("scamp", 1)]}], {"gates": 1, "start_gold": 100, "strength": 100})
	var b: Battle = Battle.create(LevelData.from_data(data, stats), stats, false, [])
	b.place_gate(Vector2i(4, 1))
	var routes: Array[Dictionary] = b.routes(b.closed_cells())
	for r: Dictionary in routes:
		r["break"] = r["walk"]
		r["fly"] = true
	# The new way.
	var a_host: SubViewport = _viewport()
	var back: ColorRect = ColorRect.new()
	back.color = Color("e8cc9c")
	back.size = Vector2(SIZE)
	a_host.add_child(back)
	var atlas: MapAtlas = MapAtlas.new()
	a_host.add_child(atlas)
	atlas.add_route_pieces()
	atlas.bake(1.0)
	var premult: CanvasItemMaterial = CanvasItemMaterial.new()
	premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	var layer: MapRoutes = MapRoutes.new()
	a_host.add_child(layer)
	layer.use_atlas(atlas, premult)
	layer.set_routes(routes, b.level)
	# The old way, from the same points.
	var b_host: SubViewport = _viewport()
	var plain: Plain = Plain.new()
	for line: MapRoutes.Line in layer.lines:
		plain.walk.append_array(line.walk)
		plain.breaker.append_array(line.breaker)
		if line.fly.size() >= 2:
			plain.fly.append(line.fly)
	b_host.add_child(plain)
	b_host.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for i: int in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var calls_new: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	a_host.render_target_update_mode = SubViewport.UPDATE_ONCE
	b_host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i: int in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var calls_old: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var img_a: Image = a_host.get_texture().get_image()
	var img_b: Image = b_host.get_texture().get_image()
	img_a.save_png(_out.path_join("route_new.png"))
	img_b.save_png(_out.path_join("route_old.png"))
	var diff: Image = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	var over_12: int = 0
	var over_64: int = 0
	var sum: float = 0.0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var ca: Color = img_a.get_pixel(x, y)
			var cb: Color = img_b.get_pixel(x, y)
			var d: float = maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b)))
			sum += d
			if d > 12.0 / 255.0:
				over_12 += 1
			if d > 64.0 / 255.0:
				over_64 += 1
			diff.set_pixel(x, y, Color(d, d, d))
	diff.save_png(_out.path_join("route_diff.png"))
	var total: float = float(SIZE.x * SIZE.y)
	print("pixels differing by over 12 of 255: %d (%.3f%%), by over 64: %d (%.3f%%), mean difference %.4f" % [over_12, 100.0 * float(over_12) / total, over_64, 100.0 * float(over_64) / total, sum / total])
	print("draw calls: MapRoutes %d, MapArt.draw_route %d" % [calls_new, calls_old])
	quit(0)
