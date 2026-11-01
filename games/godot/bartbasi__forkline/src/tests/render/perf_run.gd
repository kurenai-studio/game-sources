# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Measures frame time on this PC for the busiest moments: region 1 levels at 3x with early
## calls (two waves on the map), and a synthetic 200 creature crowd. The map is drawn into an
## offscreen viewport with the same pixel count as a Fold5 screen, vsync off. Needs a display:
##
##     godot --path . --script res://tests/render/perf_run.gd
##
## Optional: --only=synthetic (only the crowd), --only=cover (only the cover screen), --only=storm, --only=build (the build phase only), --only=expansion (the new cast, V4).
## Prints one block per run. The numbers are for this PC, not the phone (docs/ARCHITECTURE.md 9.4).

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const MAX_SECONDS: float = 45.0



func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var only: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	if only == "storm":
		await _storm()
		quit(0)
		return
	if only == "expansion":
		for s: Array in [["cover", Vector2i(904, 2316), Fx.COVER], ["inner", Vector2i(1812, 2176), Fx.INNER]]:
			await _measure("%s expansion crowd, two waves of 120, 3x" % s[0], Fx.expansion_crowd(), s[1], s[2], 0, true)
		quit(0)
		return
	if only == "build":
		await _build_phase()
		quit(0)
		return
	var screens: Array[Array] = [["cover", Vector2i(904, 2316), Fx.COVER], ["inner", Vector2i(1812, 2176), Fx.INNER]]
	for s: Array in screens:
		if only == "cover" and s[0] != "cover":
			continue
		for id: String in ["r1_l4", "r1_l5", "r1_l6"]:
			if only == "synthetic":
				continue
			var b: Battle = Fx.battle(id)
			Fx.defend(b)
			var from: int = b.level.waves.size() - 3 if id != "r1_l6" else b.level.waves.size() - 4
			await _measure("%s %s waves %d on, early calls, 3x" % [s[0], id, from + 1], b, s[1], s[2], from, true)
		await _measure("%s synthetic 200 creature crowd, 3x" % s[0], Fx.stress(), s[1], s[2], 0, true)
	await _storm()
	await _build_phase()
	quit(0)


## The build phase: route lines, gates, range and selection all showing.
func _build_phase() -> void:
	for id: String in ["r1_l6", "r1_l5"]:
		var b: Battle = Fx.battle(id)
		Fx.defend(b)
		var host: SubViewport = SubViewport.new()
		host.size = Vector2i(904, 2316)
		host.size_2d_override = Fx.COVER
		host.size_2d_override_stretch = true
		host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(host)
		var view: MapView = MapView.new()
		host.add_child(view)
		view.setup(b)
		view.fit(Rect2(0, 236, 1080, 1080.0 / 7.0 * float(b.level.rows)))
		b.place_gate(b.level.sockets[0])
		view.show_routes(b.routes(b.closed_cells()))
		view.show_range(b.level.spots[0], 300, false)
		view.show_selection(b.level.spots[1])
		view.show_hint(b.level.spots[2])
		var calls: PackedInt32Array = PackedInt32Array()
		var times: PackedInt32Array = PackedInt32Array()
		for i: int in 90:
			await process_frame
			view.sync(0.0)
			if i >= 30:
				calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
				times.append(view.last_sync_usec)
		print("== build phase %s: routes, %d sockets, range, selection, hint" % [id, b.level.sockets.size()])
		print("   draw calls per frame: mean %.1f, max %.0f; sync mean %.2f ms" % [_mean_us(calls) * 1000.0, _max_us(calls) * 1000.0, _mean_us(times)])
		host.queue_free()
		await process_frame


func _measure(label: String, b: Battle, pixels: Vector2i, logical: Vector2i, from_wave: int, early: bool) -> void:
	var host: SubViewport = SubViewport.new()
	host.size = pixels
	host.size_2d_override = logical
	host.size_2d_override_stretch = true
	host.transparent_bg = false
	host.disable_3d = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var back: Backdrop = Backdrop.new()
	host.add_child(back)
	back.size = Vector2(logical)
	var view: MapView = MapView.new()
	host.add_child(view)
	view.setup(b)
	var landscape: bool = logical.y < int(1.5 * float(logical.x))
	if landscape:
		var h: float = float(logical.y) - 120.0
		view.fit(Rect2(40, 60, h * 7.0 / float(b.level.rows), h))
	else:
		view.fit(Rect2(0, 236, float(logical.x), float(logical.x) / 7.0 * float(b.level.rows)))
	Fx.fast_forward(b, from_wave)
	b.start_next_wave()
	var clock: BattleClock = BattleClock.new()
	clock.speed = 3
	var frames: PackedFloat32Array = PackedFloat32Array()
	var syncs: PackedInt32Array = PackedInt32Array()
	var eventus: PackedInt32Array = PackedInt32Array()
	var ticks: PackedInt32Array = PackedInt32Array()
	var draws: PackedInt32Array = PackedInt32Array()
	var peak: int = 0
	await process_frame
	await process_frame
	var last: int = Time.get_ticks_usec()
	var started: int = last
	var tick_frames: int = 0
	while true:
		await process_frame
		var now: int = Time.get_ticks_usec()
		var dt: float = float(now - last) / 1000000.0
		last = now
		if b.phase == Battle.Phase.WAVE:
			for t: int in clock.advance(dt):
				var t0: int = Time.get_ticks_usec()
				b.step()
				ticks.append(Time.get_ticks_usec() - t0)
			if early and b.next_wave_info()["refusal"] == &"":
				b.start_next_wave()
		var events: Array[Dictionary] = b.take_events()
		view.sync(clock.alpha())
		view.play_events(events)
		if b.enemies.size() >= 20:
			frames.append(dt)
			syncs.append(view.last_sync_usec)
			eventus.append(view.last_events_usec)
			draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			tick_frames += 1
		peak = maxi(peak, b.enemies.size())
		var elapsed: float = float(now - started) / 1000000.0
		if b.phase != Battle.Phase.WAVE and b.waves_started >= b.wave_count():
			break
		if b.phase == Battle.Phase.LOST or b.phase == Battle.Phase.WON or elapsed > MAX_SECONDS:
			break
		if b.phase == Battle.Phase.BUILD:
			b.start_next_wave()
	print("== %s" % label)
	if frames.is_empty():
		print("   no frames with 20 or more creatures")
	else:
		var total: float = 0.0
		for f: float in frames:
			total += f
		var mean: float = total / float(frames.size())
		var sorted: PackedFloat32Array = frames.duplicate()
		sorted.sort()
		print("   frames with 20+ creatures: %d, peak live %d, bake scale %.2f" % [frames.size(), peak, view.bake_scale()])
		print("   frame: mean %.2f ms (%.0f fps), p99 %.2f ms, worst %.2f ms" % [mean * 1000.0, 1.0 / mean, sorted[mini(sorted.size() - 1, frames.size() * 99 / 100)] * 1000.0, sorted[sorted.size() - 1] * 1000.0])
		print("   map view scripts: sync mean %.2f ms p99 %.2f ms worst %.2f ms, events mean %.2f ms worst %.2f ms" % [_mean_us(syncs), _p99_us(syncs), _max_us(syncs), _mean_us(eventus), _max_us(eventus)])
		print("   sim: mean %.3f ms per tick, p99 %.3f ms over %d ticks" % [_mean_us(ticks), _p99_us(ticks), ticks.size()])
		print("   draw calls per frame: mean %.1f, p99 %.0f, max %.0f" % [_mean_us(draws) * 1000.0, _p99_us(draws) * 1000.0, _max_us(draws) * 1000.0])
	host.queue_free()
	await process_frame


func _mean_us(a: PackedInt32Array) -> float:
	if a.is_empty():
		return 0.0
	var t: int = 0
	for v: int in a:
		t += v
	return float(t) / float(a.size()) / 1000.0


func _max_us(a: PackedInt32Array) -> float:
	var m: int = 0
	for v: int in a:
		m = maxi(m, v)
	return float(m) / 1000.0


func _p99_us(a: PackedInt32Array) -> float:
	if a.is_empty():
		return 0.0
	var s: PackedInt32Array = a.duplicate()
	s.sort()
	return float(s[mini(s.size() - 1, s.size() * 99 / 100)]) / 1000.0


## The worst case for the shot overlay: it is kept full of shots of every look, so every frame
## draws the cap in shots and as many marks as the cap allows. Cover size, one overlay on its own.
func _storm() -> void:
	var host: SubViewport = SubViewport.new()
	host.size = Vector2i(904, 2316)
	host.size_2d_override = Fx.COVER
	host.size_2d_override_stretch = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var atlas: MapAtlas = MapAtlas.new()
	host.add_child(atlas)
	atlas.add_shot_pieces()
	atlas.bake(1.0)
	var shots: MapShots = MapShots.new()
	shots.atlas = atlas
	var premult: CanvasItemMaterial = CanvasItemMaterial.new()
	premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	shots.material = premult
	host.add_child(shots)
	var looks: int = MapShots.Look.size()
	var clock: float = 0.0
	var frames: PackedFloat32Array = PackedFloat32Array()
	var calls: PackedInt32Array = PackedInt32Array()
	var draws: PackedInt32Array = PackedInt32Array()
	var peak_shots: int = 0
	var peak_marks: int = 0
	await process_frame
	var last: int = Time.get_ticks_usec()
	for frame: int in 600:
		await process_frame
		var now: int = Time.get_ticks_usec()
		var dt: float = float(now - last) / 1000000.0
		last = now
		clock += 1.0 / 60.0
		# 24 towers fire about every 0.35 s at 3x, so a salvo of 8 shots every 3 frames.
		if frame % 3 == 0:
			for i: int in 8:
				var at: Vector2 = Vector2(float(100 + (i * 97 + frame * 13) % 700), float(300 + (i * 211 + frame * 7) % 900))
				shots.launch((frame + i) % looks, at, at + Vector2(220.0, 120.0), i, clock, 96.0)
		var t0: int = Time.get_ticks_usec()
		shots.advance(clock)
		draws.append(Time.get_ticks_usec() - t0)
		peak_shots = maxi(peak_shots, shots.shots.size())
		peak_marks = maxi(peak_marks, shots.flashes.size())
		if frame == 300 and OS.get_environment("STORM_PNG") != "":
			host.get_texture().get_image().save_png(OS.get_environment("STORM_PNG"))
		if frame >= 60:
			frames.append(dt)
			calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	var total: float = 0.0
	for f: float in frames:
		total += f
	var sorted: PackedFloat32Array = frames.duplicate()
	sorted.sort()
	print("== shot storm: a salvo of 8 shots every 3 frames, every look, 60 frames a second pace")
	print("   peak shots %d, peak marks %d" % [peak_shots, peak_marks])
	print("   frame: mean %.2f ms, p99 %.2f ms, worst %.2f ms" % [total / float(frames.size()) * 1000.0, sorted[frames.size() * 99 / 100] * 1000.0, sorted[sorted.size() - 1] * 1000.0])
	print("   draw calls per frame: mean %.1f, max %.0f; advance call mean %.3f ms" % [_mean_us(calls) * 1000.0, _max_us(calls) * 1000.0, _mean_us(draws)])
	host.queue_free()
	await process_frame
