# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Makes the before and after contact sheets of the tower shots, at the true size of the Fold5
## cover screen (904 x 2316, one image pixel is one phone pixel). For each tower and each of its
## shot looks it plays the second salvo against a bunched crowd and keeps four frames: the launch,
## the middle of the flight, the landing and the moment after. Needs a display, so no --headless:
##
##     godot --path . --script res://tests/render/contact_sheet.gd -- --out=<folder>
##
## One PNG per tower and look (four frames side by side) and one sheet per tower. Use a scratch
## folder, not the repo. --only=<name> makes one case.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const CELL: float = 128.0
const SIZE: Vector2i = Vector2i(904, 1500)
const SPOT: Vector2i = Vector2i(4, 2)
const SALVO: int = 2
const MAX_TICKS: int = 600
const COLUMNS: Array[String] = ["launch", "flight", "landing", "after"]
## [file name, tower, tier, spec, creature]. Each tower group has a sheet of its own.
const CASES: Array = [
	["sling_post_tier1_pebble", &"sling_post", 1, -1, "scamp"],
	["sling_post_tier2_pebble", &"sling_post", 2, -1, "scamp"],
	["sling_post_quickshot_pebble", &"sling_post", 3, 0, "scamp"],
	["sling_post_stone_sling_stone", &"sling_post", 3, 1, "scamp"],
	["pumpkin_catapult_tier1_pumpkin", &"pumpkin_catapult", 1, -1, "scamp"],
	["pumpkin_catapult_tier2_pumpkin", &"pumpkin_catapult", 2, -1, "scamp"],
	["pumpkin_catapult_prize_pumpkin", &"pumpkin_catapult", 3, 0, "scamp"],
	["pumpkin_catapult_jam_pot_jam", &"pumpkin_catapult", 3, 1, "scamp"],
	["longbow_loft_tier1_arrow", &"longbow_loft", 1, -1, "scamp"],
	["longbow_loft_giant_bow_giant_arrow", &"longbow_loft", 3, 0, "scamp"],
	["longbow_loft_triple_bow_arrow", &"longbow_loft", 3, 1, "scamp"],
	["firework_tower_tier1_rocket", &"firework_tower", 1, -1, "flitter"],
	["firework_tower_star_bloom_bloom", &"firework_tower", 3, 0, "flitter"],
	["firework_tower_skyrocket_skyrocket", &"firework_tower", 3, 1, "flitter"],
]

var _out: String = ""
var _only: String = ""
var _theme: Theme
var _strips: Dictionary[String, Array] = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("contact_sheet.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for c: Array in CASES:
		if _only.is_empty() or _only == c[0]:
			await _play(c)
	await _sheets()
	quit(0)


## Plays one case and saves its strip.
func _play(c: Array) -> void:
	var b: Battle = Fx.arena([[Fx.group(c[4], 5, 100)]], 1000)
	if not Fx.build(b, SPOT, c[1], c[2], c[3]):
		printerr("could not build %s" % c[0])
		return
	b.take_events()
	var host: SubViewport = SubViewport.new()
	host.size = SIZE
	host.transparent_bg = false
	host.disable_3d = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var back: Backdrop = Backdrop.new()
	host.add_child(back)
	var view: MapView = MapView.new()
	host.add_child(view)
	view.setup(b)
	view.fit(Rect2(0.0, 0.0, float(SIZE.x), float(SIZE.x) / 7.0 * 11.0))
	for i: int in 4:
		await process_frame
		view.sync(0.0)
	b.start_next_wave()
	var salvo: Dictionary = {}
	var n: int = 0
	var ticks: int = 0
	while salvo.is_empty() and ticks < MAX_TICKS and b.phase == Battle.Phase.WAVE:
		for e: Dictionary in _tick(b, view):
			if e["kind"] == &"fired" and e["cell"] == SPOT:
				n += 1
				if n == SALVO:
					salvo = e
		ticks += 1
	if salvo.is_empty():
		printerr("%s never fired %d times" % [c[0], SALVO])
		host.queue_free()
		return
	var shots: MapShots = view.get("_shots") as MapShots
	var fired_at: float = float(view.get("_fx_time"))
	var flight: float = 0.1
	if not shots.shots.is_empty():
		flight = shots.shots[shots.shots.size() - 1].t1 - shots.shots[shots.shots.size() - 1].t0
	var crop: Rect2i = _crop(view, b, salvo)
	var times: Array[float] = [fired_at + 0.025, fired_at + maxf(flight * 0.55, 0.06), fired_at + flight + 0.05, fired_at + flight + 0.25]
	var frames: Array[Image] = []
	for k: int in times.size():
		_advance_to(b, view, times[k])
		await process_frame
		await RenderingServer.frame_post_draw
		if k >= 2:
			# The sparkles run on real time, so give them a moment.
			await create_timer(0.04 if k == 2 else 0.2).timeout
			await RenderingServer.frame_post_draw
		frames.append(host.get_texture().get_image().get_region(crop))
	var strip: Image = Image.create(crop.size.x * frames.size() + 8 * (frames.size() - 1), crop.size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.1, 0.08, 0.14))
	for k: int in frames.size():
		frames[k].convert(Image.FORMAT_RGBA8)
		strip.blit_rect(frames[k], Rect2i(Vector2i.ZERO, crop.size), Vector2i(k * (crop.size.x + 8), 0))
	var path: String = _out.path_join("%s.png" % c[0])
	print("%s %dx%d flight %.2f s targets %d: %s" % [path, strip.get_width(), strip.get_height(), flight, (salvo["targets"] as Array).size(), error_string(strip.save_png(path))])
	_strips[c[0]] = frames
	host.queue_free()
	await process_frame


func _tick(b: Battle, view: MapView) -> Array[Dictionary]:
	b.step()
	var events: Array[Dictionary] = b.take_events()
	view.sync(0.0)
	view.play_events(events)
	return events


## Moves the game to time `g` seconds: whole ticks first, then a part of the next one.
func _advance_to(b: Battle, view: MapView, g: float) -> void:
	while float(b.tick + 1) * 0.05 <= g + 0.0001 and b.phase == Battle.Phase.WAVE:
		_tick(b, view)
	view.sync(clampf((g - float(b.tick) * 0.05) / 0.05, 0.0, 1.0))


## The part of the screen that holds the tower, every target and their splash, in pixels.
func _crop(view: MapView, b: Battle, salvo: Dictionary) -> Rect2i:
	var center: Vector2 = (Vector2(SPOT) + Vector2(0.5, 0.5)) * CELL
	var local: Rect2 = Rect2(center - Vector2(0.6, 0.95) * CELL, Vector2(1.2, 1.45) * CELL)
	var state: TowerState = b.tower_at(SPOT)
	var splash: float = float(state.stats.splash) / 100.0 * CELL if state != null and state.stats != null else 0.0
	var ats: Array = salvo["at"]
	for a: Vector2i in ats:
		var p: Vector2 = Vector2(a) * MapView.PX_PER_SUB
		var r: float = maxf(splash, 0.5 * CELL)
		local = local.merge(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0))
	local = local.grow(0.3 * CELL)
	var min_size: Vector2 = Vector2(3.4, 2.8) * CELL
	if local.size.x < min_size.x:
		local = local.grow_individual((min_size.x - local.size.x) * 0.5, 0.0, (min_size.x - local.size.x) * 0.5, 0.0)
	if local.size.y < min_size.y:
		local = local.grow_individual(0.0, (min_size.y - local.size.y) * 0.5, 0.0, (min_size.y - local.size.y) * 0.5)
	var xf: Transform2D = view.get_global_transform()
	var a: Vector2 = xf * local.position
	var z: Vector2 = xf * local.end
	var r: Rect2i = Rect2i(Vector2i(a.floor()), Vector2i((z - a).ceil()))
	return r.intersection(Rect2i(Vector2i.ZERO, SIZE))


## One sheet for each tower: a row for each look, a column for each moment.
func _sheets() -> void:
	var towers: Array[String] = []
	for c: Array in CASES:
		var t: String = String(c[1])
		if not towers.has(t) and _strips.has(c[0]):
			towers.append(t)
	for t: String in towers:
		var host: SubViewport = SubViewport.new()
		host.transparent_bg = false
		host.disable_3d = true
		host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(host)
		var panel: PanelContainer = PanelContainer.new()
		panel.theme = _theme
		host.add_child(panel)
		var rows: VBoxContainer = VBoxContainer.new()
		rows.add_theme_constant_override("separation", 10)
		panel.add_child(rows)
		var head: HBoxContainer = HBoxContainer.new()
		rows.add_child(head)
		var spacer: Label = Label.new()
		spacer.custom_minimum_size = Vector2(230.0, 0.0)
		head.add_child(spacer)
		var first: bool = true
		for c: Array in CASES:
			if String(c[1]) != t or not _strips.has(c[0]):
				continue
			var frames: Array = _strips[c[0]]
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			rows.add_child(row)
			var name_label: Label = Label.new()
			name_label.custom_minimum_size = Vector2(230.0, 0.0)
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.text = String(c[0]).replace("_", " ")
			row.add_child(name_label)
			for k: int in frames.size():
				var tex: TextureRect = TextureRect.new()
				tex.texture = ImageTexture.create_from_image(frames[k] as Image)
				tex.stretch_mode = TextureRect.STRETCH_KEEP
				row.add_child(tex)
				if first:
					var h: Label = Label.new()
					h.custom_minimum_size = Vector2(float((frames[k] as Image).get_width()) + 8.0, 0.0)
					h.text = COLUMNS[k]
					head.add_child(h)
			first = false
		await process_frame
		await process_frame
		host.size = Vector2i(panel.get_combined_minimum_size().ceil())
		await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = host.get_texture().get_image()
		var path: String = _out.path_join("sheet_%s.png" % t)
		print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(img.save_png(path))])
		host.queue_free()
		await process_frame
