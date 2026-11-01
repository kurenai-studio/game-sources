# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Screenshots of the expansion's cast in play (build step V4) at the Fold5 cover and inner sizes:
## every look of the four new towers, the eight new creatures, the four bosses, each status mark
## and the three new shots, on the sim's test catalog (tests/sim/fixtures/creature_fixtures.gd).
## Needs a display, so no --headless:
##
##     godot --path . --script res://tests/render/shots_expansion.gd -- --out=<folder>
##
## Optional: --only=towers|cast|bosses|status|pulse|line|lure (default all), --size=cover or
## --size=inner. Each picture is named v4_<scene>_<size>.png. It prints the draw calls of the frame.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")

const SCENES: Array[String] = ["towers", "cast", "bosses", "status", "pulse", "line", "lure"]

var _out: String = ""
var _only: String = ""
var _size: String = ""
var _theme: Theme


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--size="):
			_size = arg.trim_prefix("--size=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless" or _out.is_empty():
		printerr("shots_expansion.gd needs a display and --out=<folder>.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_theme = UiTheme.build()
	for scene: String in SCENES:
		if not _only.is_empty() and _only != scene:
			continue
		for size: Vector2i in [Fx.COVER, Fx.INNER]:
			var label: String = "cover" if size == Fx.COVER else "inner"
			if _size.is_empty() or _size == label:
				match scene:
					"towers":
						await _scene_towers(size, label)
					"cast":
						await _scene_cast(size, label)
					"bosses":
						await _scene_bosses(size, label)
					"status":
						await _scene_status(size, label)
					"pulse":
						await _scene_pulse(size, label)
					"line":
						await _scene_line(size, label)
					"lure":
						await _scene_lure(size, label)
	quit(0)


# Staging.

class Stage:
	extends RefCounted
	var host: SubViewport
	var view: MapView
	var battle: Battle
	var note: Label


func _stage(size: Vector2i, b: Battle) -> Stage:
	var s: Stage = Stage.new()
	s.host = SubViewport.new()
	s.host.size = size
	s.host.transparent_bg = false
	s.host.disable_3d = true
	s.host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(s.host)
	var screen: Control = Control.new()
	screen.size = Vector2(size)
	screen.theme = _theme
	s.host.add_child(screen)
	screen.add_child(Backdrop.new())
	s.battle = b
	s.view = MapView.new()
	screen.add_child(s.view)
	s.view.setup(b)
	var rect: Rect2
	s.note = Label.new()
	screen.add_child(s.note)
	if size.y < int(1.5 * float(size.x)):
		var h: float = float(size.y) - 120.0
		rect = Rect2(40, 60, h * 7.0 / float(b.level.rows), h)
		s.note.position = Vector2(rect.end.x + 60.0, 80.0)
	else:
		var w: float = float(size.x)
		rect = Rect2(0, 236, w, w / 7.0 * float(b.level.rows))
		s.note.position = Vector2(40.0, 90.0)
	s.view.fit(rect)
	return s


func _settle(s: Stage, frames: int = 20) -> void:
	for i: int in frames:
		await process_frame
		s.view.sync(0.0)


func _save(s: Stage, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var img: Image = s.host.get_texture().get_image()
	var path: String = _out.path_join("v4_%s.png" % name)
	print("%s %dx%d draw_calls=%d atlas=%s bake=%.2f: %s" % [path, img.get_width(), img.get_height(), calls, (s.view.get("_atlas") as MapAtlas).size, (s.view.get("_atlas") as MapAtlas).texel_scale, error_string(img.save_png(path))])


func _close(s: Stage) -> void:
	s.host.queue_free()
	await process_frame


## One tick, drawn: the sim steps, the view syncs and plays the events. Returns the events.
func _tick(s: Stage) -> Array[Dictionary]:
	s.battle.step()
	var events: Array[Dictionary] = s.battle.take_events()
	s.view.sync(1.0)
	s.view.play_events(events)
	return events


# Scenes.

## Every look of the four new towers, and the old six at tier 3, with some dozing.
func _scene_towers(size: Vector2i, label: String) -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 1)]], 100, Fx.GALLERY_GRID, 0)
	var s: Stage = _stage(size, b)
	var looks: Array = [[1, -1], [2, -1], [3, 0], [3, 1]]
	var i: int = 0
	for id: String in Fx.EXPANSION_TOWER_IDS:
		for look: Array in looks:
			Fx.build(b, b.level.spots[i], StringName(id), look[0], look[1])
			i += 1
	for id: String in Fx.ALL_TOWERS:
		if i < b.level.spots.size():
			Fx.build(b, b.level.spots[i], StringName(id), 3, i % 2)
			i += 1
	b.tower_at(b.level.spots[1]).doze_ticks = 60
	b.tower_at(b.level.spots[6]).doze_ticks = 60
	b.tower_at(b.level.spots[11]).doze_ticks = 60
	s.note.text = "new towers: tier 1, tier 2, path A, path B (three doze)"
	await _settle(s)
	await _save(s, "towers_" + label)
	await _close(s)


## The eight new creatures walking, with a few towers. Natural statuses: hidden, awake, afraid.
func _scene_cast(size: Vector2i, label: String) -> void:
	var groups: Array = []
	var at: int = 0
	for id: String in Fx.EXPANSION_ENEMY_IDS:
		groups.append(Fx.group(id, 2, 700, at))
		at += 450
	var b: Battle = Fx.expansion([groups], 100)
	Fx.build(b, Vector2i(2, 4), &"scarecrow", 2)
	Fx.build(b, Vector2i(4, 4), &"sling_post", 3, 0)
	Fx.build(b, Vector2i(2, 6), &"snow_fort", 1)
	Fx.build(b, Vector2i(4, 6), &"bramble_cottage", 3, 1)
	Fx.build(b, Vector2i(4, 2), &"moth_lantern", 2)
	var s: Stage = _stage(size, b)
	await _settle(s, 10)
	b.start_next_wave()
	var best: int = 0
	var best_tick: int = 0
	for t: int in 700:
		_tick(s)
		if b.enemies.size() > best and t > 150:
			best = b.enemies.size()
			best_tick = t
		if t >= 120:
			break
		if t % 4 == 0:
			await process_frame
	s.note.text = "creatures of regions 5 to 8: %d on the map" % b.enemies.size()
	await _save(s, "cast_" + label)
	await _close(s)


## The four bosses on a long road, each a gap behind the one before.
func _scene_bosses(size: Vector2i, label: String) -> void:
	var groups: Array = []
	var at: int = 0
	for id: String in Fx.EXPANSION_BOSS_IDS:
		groups.append(Fx.group(id, 1, 1000, at))
		at += 4500
	var b: Battle = Fx.expansion([groups], 100, Fx.GALLERY_GRID, 0)
	Fx.build(b, b.level.spots[0], &"sling_post", 3, 0)
	Fx.build(b, b.level.spots[9], &"pumpkin_catapult", 2)
	var s: Stage = _stage(size, b)
	await _settle(s, 10)
	b.start_next_wave()
	for t: int in 520:
		_tick(s)
		if t % 4 == 0:
			await process_frame
	s.note.text = "the four bosses: %d on the map" % b.enemies.size()
	await _save(s, "bosses_" + label)
	await _close(s)


## Every status at once, forced where the rules would take a long time to reach it.
func _scene_status(size: Vector2i, label: String) -> void:
	var groups: Array = [
		Fx.group("scamp", 3, 1100, 0), Fx.group("mistwisp", 1, 1000, 3500), Fx.group("sleepyhead", 1, 1000, 4600),
		Fx.group("hootling", 1, 1000, 5700), Fx.group("flitter", 3, 1200, 0), Fx.group("snowroller", 3, 1100, 6800),
		Fx.group("burrowbelly", 1, 1000, 10500), Fx.group("mossbud", 1, 1000, 11500),
	]
	var b: Battle = Fx.expansion([groups], 100, Fx.GALLERY_GRID, 0)
	Fx.build(b, b.level.spots[2], &"scarecrow", 2)
	Fx.build(b, b.level.spots[3], &"scarecrow", 2)
	Fx.build(b, b.level.spots[0], &"sling_post", 1)
	Fx.build(b, b.level.spots[5], &"sling_post", 1)
	var s: Stage = _stage(size, b)
	await _settle(s, 10)
	b.start_next_wave()
	for t: int in 250:
		_tick(s)
		if t % 5 == 0:
			await process_frame
	var lows: int = 0
	var growers: int = 0
	var scamps: int = 0
	for e: EnemyState in b.enemies:
		match e.type:
			&"sleepyhead":
				e.nap_ticks = 100
				e.napped = true
				e.health = e.max_health / 2
			&"flitter":
				if lows < 2:
					e.low_ticks = 400
					lows += 1
			&"snowroller":
				e.max_health = e.start_health * (1 + growers)
				e.health = e.max_health * 7 / 10
				growers += 1
			&"scamp":
				if scamps == 0:
					e.fright_pct = 25
					e.fright_ticks = 40
				scamps += 1
			&"burrowbelly":
				e.dig_ticks = 40
	b.tower_at(b.level.spots[0]).doze_ticks = 60
	b.tower_at(b.level.spots[5]).doze_ticks = 60
	s.view.sync(1.0)
	s.note.text = "statuses: hidden, napping, afraid, awake, low, dug, growth, doze"
	await _settle(s, 2)
	await _save(s, "status_" + label)
	await _close(s)


## Runs the wave tick by tick until a shot of `look` is `u` of the way, then draws that moment.
func _until_shot(s: Stage, look: int, u: float) -> bool:
	var shots: MapShots = s.view.get("_shots") as MapShots
	for t: int in 1500:
		_tick(s)
		for shot: MapShots.Shot in shots.shots:
			if shot.look == look and shots.now >= shot.t0 + (shot.t1 - shot.t0) * u:
				return true
		if t % 3 == 0:
			await process_frame
		if s.battle.phase != Battle.Phase.WAVE:
			break
	return false


func _scene_pulse(size: Vector2i, label: String) -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 12, 350)]], 100)
	Fx.build(b, Vector2i(2, 4), &"bramble_cottage", 3, 0)
	Fx.build(b, Vector2i(4, 4), &"bramble_cottage", 2)
	var s: Stage = _stage(size, b)
	await _settle(s, 10)
	b.start_next_wave()
	var found: bool = await _until_shot(s, MapShots.Look.THORNS, 0.45)
	s.note.text = "Bramble Cottage pulse (found %s)" % found
	await _save(s, "pulse_" + label)
	await _close(s)


func _scene_line(size: Vector2i, label: String) -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 12, 350)]], 100)
	Fx.build(b, Vector2i(2, 4), &"snow_fort", 3, 0)
	Fx.build(b, Vector2i(4, 4), &"snow_fort", 3, 1)
	var s: Stage = _stage(size, b)
	await _settle(s, 10)
	b.start_next_wave()
	var found: bool = await _until_shot(s, MapShots.Look.BIG_SNOWBALL, 0.4)
	s.note.text = "Snow Fort line (found %s)" % found
	await _save(s, "line_" + label)
	await _close(s)


func _scene_lure(size: Vector2i, label: String) -> void:
	var b: Battle = Fx.expansion([[Fx.group("flitter", 8, 300), Fx.group("dusk_moth", 2, 500, 600)]], 100)
	Fx.build(b, Vector2i(2, 4), &"moth_lantern", 3, 1)
	Fx.build(b, Vector2i(4, 4), &"moth_lantern", 3, 0)
	Fx.build(b, Vector2i(2, 6), &"sling_post", 2)
	var s: Stage = _stage(size, b)
	await _settle(s, 10)
	b.start_next_wave()
	var found: bool = await _until_shot(s, MapShots.Look.BEAM, 0.5)
	s.note.text = "Moth Lantern lure (found %s)" % found
	await _save(s, "lure_" + label)
	await _close(s)
