# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Runs MapView through real frames, which the synchronous test runner cannot, so every
## _draw() body of src/render/ runs and any script error shows. tests/render/test_frames.gd
## starts this script in a second Godot process and reads what it prints:
##
##     godot --headless --path . --script res://tests/render/frames_checks.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when nothing failed.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const WATCHDOG_SECONDS: float = 120.0
const FRAMES_PER_LEVEL: int = 240

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		print("FAIL watchdog: the checks did not finish")
		quit(2))
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL %s" % message)


func _run() -> void:
	for id: String in Fx.REGION_1:
		for size: Vector2i in [Fx.COVER, Fx.INNER]:
			await _play(id, size)
	for size: Vector2i in [Fx.COVER, Fx.INNER]:
		await _play_arena(size)
	for size: Vector2i in [Fx.COVER, Fx.INNER]:
		for grid: Array in [Sx.TUNNEL_GRID, Sx.BRIDGE_GATE_GRID, Sx.STUMP_GRID, Sx.SLIDE_DOWN_GRID, Sx.FEATURE_GRID]:
			await _play_feature_map(grid, size)
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _play(id: String, size: Vector2i) -> void:
	var host: SubViewport = SubViewport.new()
	host.size = size
	host.transparent_bg = false
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var b: Battle = Fx.battle(id)
	var view: MapView = MapView.new()
	host.add_child(view)
	view.setup(b)
	var landscape: bool = size.x * 3 > size.y * 2
	var rect: Rect2 = Rect2(24, 60, float(size.y) * 0.5, float(size.y) - 120.0) if landscape else Rect2(0, 236, float(size.x), float(size.x) / 7.0 * float(b.level.rows))
	view.fit(rect)
	Fx.defend(b)
	view.show_routes(b.routes(b.closed_cells()))
	view.show_range(b.level.spots[0], 300, true)
	view.show_selection(b.level.spots[1])
	view.show_hint(b.level.spots[0])
	for i: int in 3:
		await process_frame
		view.sync(0.0)
	var bakes: int = view.ground_bakes()
	check(bakes <= 2, "%s %s: the map is drawn once, or twice when fit() asked for a sharper one" % [id, size])
	view.show_routes([])
	view.show_range(Vector2i(-1, -1), 0, false)
	Fx.fast_forward(b, b.level.waves.size() / 2)
	b.start_next_wave()
	var clock: BattleClock = BattleClock.new()
	clock.speed = 3
	var seen_shots: int = 0
	var seen_sparks: int = 0
	var worst_sync: int = 0
	for i: int in FRAMES_PER_LEVEL:
		if b.phase == Battle.Phase.WAVE:
			for t: int in clock.advance(1.0 / 60.0):
				b.step()
		else:
			clock.reset()
			if b.waves_started < b.level.waves.size():
				b.start_next_wave()
		var events: Array[Dictionary] = b.take_events()
		view.sync(clock.alpha())
		view.play_events(events)
		await process_frame
		seen_shots = maxi(seen_shots, view.projectile_count())
		seen_sparks = maxi(seen_sparks, view.sparkles().bursts)
		worst_sync = maxi(worst_sync, view.last_sync_usec)
		check(view.creature_count() == b.enemies.size(), "%s %s frame %d: a node for each creature" % [id, size, i])
	check(seen_shots > 0, "%s %s: projectiles flew" % [id, size])
	check(seen_sparks > 0, "%s %s: creatures puffed into sparkles" % [id, size])
	check(view.ground_bakes() == bakes, "%s %s: the map was not drawn again while playing" % [id, size])
	check(view.ground_draws() >= 1 and view.ground_draws() <= bakes, "%s %s: ground draw count %d" % [id, size, view.ground_draws()])
	# The home effect: a heart with no number, a heart with a count and a boss heart, drawn for real.
	view.play_events([
		{"kind": &"leaked", "id": 9001, "enemy": &"scamp", "lives": 1},
	])
	view.advance_effects(0.3)
	view.play_events([
		{"kind": &"leaked", "id": 9002, "enemy": &"grumblesack", "lives": 20},
	])
	view.advance_effects(0.3)
	view.play_events([
		{"kind": &"leaked", "id": 9003, "enemy": &"scamp", "lives": 3},
	])
	for i: int in 3:
		await process_frame
	check(view.leaks().active_count() == 3, "%s %s: three hearts float" % [id, size])
	view.advance_effects(1.0)
	await process_frame
	check(view.leaks().active_count() == 0, "%s %s: the hearts end" % [id, size])
	view.fit(Rect2(0, 0, 500, 900))
	await process_frame
	host.queue_free()
	await process_frame


## The arena with every new tower and path, a mixed wave and a boss wave, drawn through real
## frames, then the one-shot marks made by hand and the six gate looks drawn together.
func _play_arena(size: Vector2i) -> void:
	var host: SubViewport = SubViewport.new()
	host.size = size
	host.transparent_bg = false
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var mixed: Array = [
		Fx.group("scamp", 6, 300), Fx.group("mender", 2, 600, 1000), Fx.group("bubbler", 4, 400, 2000),
		Fx.group("puffball", 3, 500, 3000), Fx.group("gatecrasher", 2, 800, 4000), Fx.group("flitter", 6, 300, 5000),
		Fx.group("dusk_moth", 2, 500, 6000),
	]
	var b: Battle = Fx.arena([mixed, [Fx.group("ironshell", 1, 500), Fx.group("scamp", 8, 400, 2000)]], 50)
	var view: MapView = MapView.new()
	host.add_child(view)
	view.setup(b)
	var landscape: bool = size.x * 3 > size.y * 2
	view.fit(Rect2(24, 60, float(size.y) * 0.5, float(size.y) - 120.0) if landscape else Rect2(0, 236, float(size.x), float(size.x) / 7.0 * 11.0))
	var label: String = "arena %s" % size
	b.place_gate(Fx.ARENA_SOCKETS[0])
	Fx.build(b, Vector2i(2, 4), &"longbow_loft", 3, 1)
	Fx.build(b, Vector2i(4, 4), &"firework_tower", 3, 0)
	Fx.build(b, Vector2i(2, 6), &"sling_post", 3, 0)
	Fx.build(b, Vector2i(4, 6), &"lullaby_bell", 2)
	Fx.build(b, Vector2i(4, 2), &"bakery", 2)
	Fx.build(b, Vector2i(4, 1), &"firework_tower", 3, 1)
	Fx.build(b, Vector2i(1, 2), &"longbow_loft", 3, 0)
	Fx.build(b, Vector2i(1, 9), &"firework_tower", 2)
	Fx.build(b, Vector2i(4, 9), &"pumpkin_catapult", 3, 1)
	for i: int in 3:
		await process_frame
		view.sync(0.0)
	b.start_next_wave()
	var clock: BattleClock = BattleClock.new()
	clock.speed = 3
	var kinds: Dictionary = {}
	for i: int in 1400:
		if b.phase == Battle.Phase.WAVE:
			for t: int in clock.advance(1.0 / 60.0):
				b.step()
		else:
			clock.reset()
			if b.waves_started < b.level.waves.size():
				b.start_next_wave()
		var events: Array[Dictionary] = b.take_events()
		for e: Dictionary in events:
			kinds[e["kind"]] = true
		view.sync(clock.alpha())
		view.play_events(events)
		await process_frame
		check(view.creature_count() == b.enemies.size(), "%s frame %d: a node for each creature" % [label, i])
		if b.phase == Battle.Phase.WON or b.phase == Battle.Phase.LOST:
			break
	for kind: StringName in [&"fired", &"healed", &"released", &"sped_up", &"popped", &"wave_cleared"]:
		check(kinds.has(kind), "%s: the wave made a %s event, so it was drawn" % [label, kind])
	# The marks that need a moment of their own, made by hand, then drawn.
	view.advance_effects(2.0)
	view.sync(0.0)
	var shots: MapShots = view.get("_shots") as MapShots
	for k: int in MapShots.Fx.size():
		check(shots.marked[k] > 0, "%s: mark %d was made" % [label, k])
	view.play_events([
		{"kind": &"healed", "id": 1, "ids": [2]},
		{"kind": &"released", "id": 1, "source": &"old_tusk", "enemy": &"dusk_moth", "count": 4, "pos": Vector2i(50000, 90000)},
		{"kind": &"break_started", "id": 1, "cell": Fx.ARENA_SOCKETS[0]},
		{"kind": &"gate_broken", "cell": Fx.ARENA_SOCKETS[0]},
		{"kind": &"wave_cleared", "wave": 0, "gold": 40},
		{"kind": &"defeated", "id": 7, "enemy": &"scamp", "pos": Vector2i(50000, 90000), "gold": 5},
	])
	var gates: MapGates = view.get("_gates") as MapGates
	var cells: Array[Vector2i] = [Vector2i(1, 5), Vector2i(5, 5), Vector2i(1, 6), Vector2i(4, 7), Vector2i(2, 2), Vector2i(3, 9)]
	var looks: Array[int] = []
	for look: int in MapArt.Gate.size():
		looks.append(look)
	gates.set_gates(cells, looks)
	for i: int in 4:
		await process_frame
	view.advance_effects(2.0)
	await process_frame
	var atlas: MapAtlas = view.get("_atlas") as MapAtlas
	check(atlas.draw_count() >= 1, "%s: the sheet, gate looks included, was drawn" % label)
	check(MapArt.Gate.size() == 6, "%s: six gate looks" % label)
	host.queue_free()
	await process_frame


## A map with features through real frames: the ground by its first feature, the kept feature
## layer, walkers under decks, in tunnels and on twin steps, route lines split and over decks.
func _play_feature_map(grid: Array, size: Vector2i) -> void:
	var host: SubViewport = SubViewport.new()
	host.size = size
	host.transparent_bg = false
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var stats: Catalog = Sx.catalog()
	var groups: Array = [Sx.group("scamp", 6, 0, 500), Sx.group("flitter", 2, 0, 900)]
	if "".join(PackedStringArray(grid)).contains("2"):
		groups.append(Sx.group("scamp", 4, 300, 500, 2))
	var waves: Array = [{"groups": groups}]
	var data: Dictionary = Sx.level_data(grid, waves, {"gates": 1 if "".join(PackedStringArray(grid)).contains("G") else 0, "start_gold": 5000})
	var b: Battle = Battle.create(LevelData.from_data(data, stats), stats, false, [])
	if grid == Sx.BRIDGE_GATE_GRID:
		b.place_gate(Vector2i(4, 1))                       # entrance 1 then goes down and under the deck
	var label: String = "features %s %s" % [grid[0] + grid[grid.size() - 1], size]
	var view: MapView = MapView.new()
	host.add_child(view)
	view.setup(b, &"")
	var landscape: bool = size.x * 3 > size.y * 2
	view.fit(Rect2(24, 60, float(size.y) * 0.5, float(size.y) - 120.0) if landscape else Rect2(0, 236, float(size.x), float(size.x) / 7.0 * float(grid.size())))
	view.show_routes(b.routes(b.closed_cells()))
	for i: int in 3:
		await process_frame
		view.sync(0.0)
	var features: bool = MapGround.feature_area(b.level.grid).has_area()
	check(view.ground_bakes() <= 2, "%s: the ground is drawn once, or twice when fit() asked for a sharper one" % label)
	check(view.feature_draws() >= (1 if features else 0), "%s: the feature layer was drawn" % label)
	var bakes: int = view.feature_bakes()
	var draws: int = view.feature_draws()
	b.start_next_wave()
	var clock: BattleClock = BattleClock.new()
	clock.speed = 3
	var hidden: int = 0
	var under: int = 0
	for i: int in 900:
		if b.phase == Battle.Phase.WAVE:
			for t: int in clock.advance(1.0 / 60.0):
				b.step()
		var events: Array[Dictionary] = b.take_events()
		view.sync(clock.alpha())
		view.play_events(events)
		if i % 90 == 0:
			view.show_routes(b.routes(b.closed_cells()))
		await process_frame
		check(view.creature_count() == b.enemies.size(), "%s frame %d: a node for each creature" % [label, i])
		for e: EnemyState in b.enemies:
			match view.layer_of(e.id):
				&"hidden":
					hidden += 1
				&"under":
					under += 1
		if b.phase == Battle.Phase.WON or b.phase == Battle.Phase.LOST:
			break
	check(view.feature_bakes() == bakes and view.feature_draws() == draws, "%s: the feature layer was not drawn again while playing" % label)
	if grid == Sx.TUNNEL_GRID or grid == Sx.STUMP_GRID or grid == Sx.FEATURE_GRID:
		check(hidden > 0, "%s: a walker was out of sight in a tunnel or on a twin step" % label)
	if grid == Sx.BRIDGE_GATE_GRID or grid == Sx.FEATURE_GRID:
		check(under > 0, "%s: a walker went under a deck" % label)
	view.fit(Rect2(0, 0, 500, 900))
	await process_frame
	host.queue_free()
	await process_frame
