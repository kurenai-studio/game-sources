# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## MapView on real region 1 levels and real Battle objects: it builds, maps cells to pixels and
## back, keeps its cache across frames, never changes the Battle, frees what it adds, and caps
## projectiles and particles. Drawing itself runs in tests/render/frames_checks.gd.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")

var _views: Array[MapView] = []


func after_each() -> void:
	for v: MapView in _views:
		if is_instance_valid(v):
			if v.get_parent() != null:
				v.get_parent().remove_child(v)
			v.free()
	_views.clear()


func _view(b: Battle) -> MapView:
	var v: MapView = MapView.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(v)
	v.setup(b)
	_views.append(v)
	return v


func test_builds_for_every_region_1_level() -> void:
	for id: String in Fx.REGION_1:
		var b: Battle = Fx.battle(id)
		assert_not_null(b, id)
		var v: MapView = _view(b)
		var towers: int = Fx.defend(b)
		v.sync(0.0)
		assert_eq(v.tower_count(), towers, "%s: a node for every tower" % id)
		assert_eq(v.ground_bakes(), 1, "%s: the map is drawn once" % id)
		assert_true(v.atlas_bakes() >= 1)


func test_cells_map_to_pixels_and_back() -> void:
	var b: Battle = Fx.battle("r1_l4")
	var v: MapView = _view(b)
	var rects: Array[Rect2] = [Rect2(0, 236, 1080, 1700), Rect2(24, 60, 1100, 2000), Rect2(10, 10, 700, 1500)]
	for rect: Rect2 in rects:
		v.fit(rect)
		var map_px: Vector2 = Vector2(float(Sim.MAP_COLUMNS), float(b.level.rows)) * MapView.CELL * v.scale.x
		assert_true(map_px.x <= rect.size.x + 0.01 and map_px.y <= rect.size.y + 0.01, "fits inside %s" % rect)
		assert_true(absf(map_px.x - rect.size.x) < 0.01 or absf(map_px.y - rect.size.y) < 0.01, "fills one side of %s" % rect)
		for r: int in b.level.rows:
			for c: int in Sim.MAP_COLUMNS:
				var local: Vector2 = (Vector2(c, r) + Vector2(0.5, 0.5)) * MapView.CELL
				assert_eq(v.cell_at(v.get_global_transform() * local), Vector2i(c, r))
		assert_eq(v.cell_at(v.get_global_transform() * Vector2(-5.0, 10.0)), Vector2i(-1, -1))
		assert_eq(v.cell_at(v.get_global_transform() * Vector2(10.0, float(b.level.rows) * MapView.CELL + 5.0)), Vector2i(-1, -1))
		assert_eq(v.cell_at(v.get_global_transform() * Vector2(float(Sim.MAP_COLUMNS) * MapView.CELL + 1.0, 10.0)), Vector2i(-1, -1))


func test_cache_stays_across_frames() -> void:
	var b: Battle = Fx.battle("r1_l2")
	var v: MapView = _view(b)
	Fx.defend(b)
	v.fit(Rect2(0, 0, 1080, 1700))
	var ground: int = v.ground_bakes()
	var atlas: int = v.atlas_bakes()
	b.start_next_wave()
	for i: int in 400:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(0.5)
		v.play_events(events)
	assert_eq(v.ground_bakes(), ground, "the map is not redrawn while playing")
	assert_eq(v.atlas_bakes(), atlas, "the sheet is not redrawn while playing")
	v.fit(Rect2(0, 0, 1080, 1750))
	assert_eq(v.ground_bakes(), ground, "a resize only moves and scales the node")


func test_never_changes_the_battle() -> void:
	var b: Battle = Fx.battle("r1_l5")
	var v: MapView = _view(b)
	Fx.defend(b)
	b.start_next_wave()
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 6000:
		var before: String = JSON.stringify(b.to_data())
		var events: Array[Dictionary] = Fx.tick(b)
		var after_step: String = JSON.stringify(b.to_data())
		v.sync(0.3)
		v.play_events(events)
		v.show_routes(b.routes(b.closed_cells()))
		v.show_range(b.level.spots[0], 300, true)
		v.show_selection(b.level.spots[0])
		v.show_hint(b.level.spots[1])
		v.show_refused(b.level.spots[1])
		assert_eq(JSON.stringify(b.to_data()), after_step, "tick %d: the view left the battle alone" % b.tick)
		assert_true(before.length() > 0)
		guard += 1
		if guard % 40 != 0:
			continue
	assert_true(guard > 100)


func test_nodes_follow_creatures_and_nothing_leaks() -> void:
	# Plays every wave of the level through one view. The pool must stay near the largest crowd
	# ever on the map, however the waves are sized, while many more creatures than that pass through.
	var b: Battle = Fx.battle("r1_l5")
	var v: MapView = _view(b)
	Fx.defend(b)
	var seen: Dictionary = {}
	var peak: int = 0
	var guard: int = 0
	while b.phase == Battle.Phase.BUILD and b.waves_started < b.wave_count():
		b.start_next_wave()
		while b.phase == Battle.Phase.WAVE and guard < 40000:
			var events: Array[Dictionary] = Fx.tick(b)
			v.sync(1.0)
			v.play_events(events)
			assert_eq(v.creature_count(), b.enemies.size(), "tick %d: one node per live creature" % b.tick)
			peak = maxi(peak, b.enemies.size())
			for e: EnemyState in b.enemies:
				seen[e.id] = true
			guard += 1
		v.advance_effects(2.0)
		v.sync(0.0)
		assert_eq(v.creature_count(), 0)
		assert_eq(v.ghost_count(), 0, "no creature is kept after wave %d" % b.waves_started)
		assert_true(v.sprite_count() <= v.tower_count() + peak + 4, "sprites are pooled after wave %d: %d for %d towers and a peak of %d" % [b.waves_started, v.sprite_count(), v.tower_count(), peak])
	assert_true(guard < 40000, "the waves ended")
	assert_true(b.waves_started >= 2, "more than one wave was played")
	assert_true(peak > 3, "a wave had a crowd")
	# Without this the pool bound above would pass for a pool that never reuses a sprite.
	assert_true(seen.size() > peak + 4, "more creatures passed through (%d) than the pool bound allows (peak %d)" % [seen.size(), peak])


func test_a_creature_removed_before_a_pause_is_not_drawn_whole() -> void:
	# QA round 3, p2: a pop waiting for its shot froze with the clock and stayed drawn whole.
	var b: Battle = Fx.battle("r1_l2")
	var v: MapView = _view(b)
	Fx.defend(b)
	b.start_next_wave()
	var waiting: bool = false
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 6000 and not waiting:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(0.5)
		v.play_events(events)
		waiting = v.ghost_count() > 0
		guard += 1
	assert_true(waiting, "a creature was removed while its shot was still in flight")
	assert_true(v.visible_ghost_count() > 0, "it shows until the pause")
	# The pause: the same tick and the same alpha, frame after frame.
	for i: int in 5:
		v.sync(0.5)
		v.play_events([] as Array[Dictionary])
		assert_eq(v.visible_ghost_count(), 0, "paused frame %d: no whole creature the battle does not hold" % i)
		assert_eq(v.creature_count(), b.enemies.size(), "paused frame %d: the map shows what the battle holds" % i)
	assert_true(v.ghost_count() > 0, "the pop still waits for its shot")
	# Resume: it stays hidden and its puff plays when the shot lands.
	var burst_before: int = v.sparkles().bursts
	for i: int in 8:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(0.5)
		v.play_events(events)
		assert_eq(v.visible_ghost_count(), 0, "resumed tick %d: it does not come back whole" % i)
	v.advance_effects(2.0)
	assert_eq(v.ghost_count(), 0, "the pop finished after the resume")
	assert_true(v.sparkles().bursts > burst_before, "the puff played")


func test_sold_towers_free_their_nodes() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	var cell: Vector2i = b.level.spots[0]
	assert_eq(b.place_tower(cell, &"sling_post"), Battle.DONE)
	v.sync(0.0)
	assert_eq(v.tower_count(), 1)
	assert_eq(b.sell_tower(cell), Battle.DONE)
	v.sync(0.0)
	assert_eq(v.tower_count(), 0)


func test_particles_are_capped() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	var events: Array[Dictionary] = []
	for i: int in 200:
		events.append({"kind": &"defeated", "id": 1000 + i, "enemy": &"scamp", "pos": Vector2i(30000 + i * 10, 30000), "gold": 5})
		events.append({"kind": &"popped", "id": 2000 + i})
		events.append({"kind": &"built", "cell": Vector2i(1, 1), "tower": &"sling_post", "tier": 1, "spec": -1, "gold": 100})
	v.play_events(events)
	var s: MapSparkles = v.sparkles()
	assert_true(s.bursts >= 200)
	assert_eq(s.emitter_count(), MapSparkles.EMITTERS)
	assert_true(s.active_count() <= MapSparkles.EMITTERS)
	assert_true(s.particle_budget() <= 400, "at most 400 particles alive")


func test_projectiles_are_capped_and_arrive() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	var events: Array[Dictionary] = []
	for i: int in 400:
		events.append({"kind": &"fired", "cell": b.level.spots[0], "tower": &"sling_post", "spec": -1,
			"targets": [i], "at": [Vector2i(40000, 40000)]})
	v.play_events(events)
	assert_true(v.projectile_count() <= 150, "%d projectiles" % v.projectile_count())
	assert_true(v.projectile_count() > 0)
	v.advance_effects(1.0)
	assert_eq(v.projectile_count(), 0, "every shot lands within a second")


func test_shots_arrive_about_when_the_hit_lands() -> void:
	# The sim hit lands the tick the tower fires, so a picture must be there within a few ticks.
	var shots: MapShots = MapShots.new()
	for look: int in MapShots.Look.values():
		var done: float = shots.launch(look, Vector2(0, 0), Vector2(5.0 * MapShots.CELL, 0), 1, 0.0)
		# A thorn ring or a snowball covers a whole reach, but the creatures near the tower are marked
		# at once: each hit mark is timed when the picture passes it.
		var limit: float = 0.4 if MapShots.look_is_placed(look) else 0.25
		assert_true(done <= limit, "look %d arrives in %.2f s" % [look, done])
	shots.free()


func test_enemy_at_finds_the_nearest_creature() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	v.fit(Rect2(0, 0, 896, 1200))
	b.start_next_wave()
	for i: int in 30:
		Fx.tick(b)
	v.sync(1.0)
	assert_true(b.enemies.size() > 0)
	var e: EnemyState = b.enemies[0]
	var local: Vector2 = Vector2(e.pos) * MapView.PX_PER_SUB
	assert_eq(v.enemy_at(v.get_global_transform() * local), e.id)
	assert_eq(v.enemy_at(Vector2(-4000, -4000)), -1)


func test_walkers_follow_the_round_turns_smoothly() -> void:
	var b: Battle = Fx.battle("r1_l2")
	var v: MapView = _view(b)
	b.start_next_wave()
	var last: Dictionary = {}
	var worst: float = 0.0
	for i: int in 900:
		b.step()
		for e: EnemyState in b.enemies:
			if last.has(e.id):
				var now: Vector2 = v.call("_curve", Vector2(e.pos))
				var jump: float = now.distance_to(last[e.id])
				worst = maxf(worst, jump)
			last[e.id] = v.call("_curve", Vector2(e.pos))
		if b.phase != Battle.Phase.WAVE:
			break
	# A scamp walks 1 cell a second: 5 px per tick at most plus the arc's extra, never a jump.
	assert_true(worst < 12.0, "largest step %.1f px" % worst)
	assert_true(worst > 0.5)


func test_gate_looks_follow_the_state() -> void:
	var b: Battle = Fx.battle("r1_l2")
	var v: MapView = _view(b)
	v.sync(0.0)
	var gates: MapGates = v.get("_gates") as MapGates
	assert_eq(gates.cells.size(), b.level.sockets.size(), "open sockets show in the build phase")
	assert_eq(gates.looks[0], MapArt.Gate.SOCKET)
	var socket: Vector2i = b.level.sockets[0]
	assert_eq(b.place_gate(socket), Battle.DONE)
	v.sync(0.0)
	assert_eq(gates.looks[gates.cells.find(socket)], MapArt.Gate.CLOSED)
	var redraws: int = gates.redraws
	v.sync(0.0)
	v.sync(0.0)
	assert_eq(gates.redraws, redraws, "an unchanged gate layer is not redrawn")
	v.show_refused(b.level.sockets[1])
	v.sync(0.0)
	assert_eq(gates.looks[gates.cells.find(b.level.sockets[1])], MapArt.Gate.REFUSED)


func test_route_lines_show_for_every_entrance() -> void:
	var b: Battle = Fx.battle("r1_l5")
	var v: MapView = _view(b)
	var routes: Array[Dictionary] = b.routes(b.closed_cells())
	v.show_routes(routes)
	var layer: MapRoutes = v.get("_routes") as MapRoutes
	assert_eq(layer.lines.size(), b.level.entrances.size())
	assert_true(layer.lines[0].walk[0].size() > 4)
	v.show_routes([])
	assert_false(layer.is_showing())


func _leak(id: int, enemy: StringName, lives: int) -> Dictionary:
	return {"kind": &"leaked", "id": id, "enemy": enemy, "lives": lives}


func test_a_leak_makes_a_dull_puff_and_a_heart() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	v.sync(0.0)
	var s: MapSparkles = v.sparkles()
	var l: MapLeaks = v.leaks()
	assert_eq(l.active_count(), 0)
	var bursts: int = s.bursts
	var leaked: Array[Dictionary] = [_leak(7, &"scamp", 1)]
	v.play_events(leaked)
	assert_eq(l.active_count(), 1, "one heart")
	assert_eq(l.lives_in(0), 1)
	assert_false(l.shows_count(0), "one life shows no number")
	assert_eq(s.bursts, bursts + 1, "one puff")
	var puff: CPUParticles2D = s.last_emitter
	assert_true(puff.emitting)
	v.play_events([{"kind": &"defeated", "id": 99, "enemy": &"scamp", "pos": Vector2i(30000, 30000), "gold": 5}])
	assert_ne(puff.texture, s.last_emitter.texture, "the leak puff is a different picture than the defeat sparkle")
	assert_ne(puff.color_initial_ramp, s.last_emitter.color_initial_ramp, "and a different color ramp")
	assert_true(v.is_effect_busy(), "the view stays busy while the heart floats")
	v.advance_effects(0.5)
	assert_eq(l.active_count(), 1, "still floating at half a second")
	v.advance_effects(0.4)
	assert_eq(l.active_count(), 0, "gone after 0.8 s")
	assert_false(v.is_effect_busy())


func test_hearts_show_the_lives_and_a_boss_is_bigger() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	var l: MapLeaks = v.leaks()
	v.play_events([_leak(1, &"scamp", 3)])
	assert_eq(l.lives_in(0), 3)
	assert_true(l.shows_count(0), "a creature worth 3 lives shows its count")
	v.advance_effects(0.3)
	v.play_events([_leak(2, &"grumblesack", 20)])
	assert_eq(l.lives_in(1), 20)
	assert_true(MapLeaks.size_cells(20, true) > MapLeaks.size_cells(3, false))
	assert_true(MapLeaks.size_cells(3, false) > MapLeaks.size_cells(1, false))


func test_leaks_in_one_moment_merge_and_the_pool_is_capped() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var v: MapView = _view(b)
	var l: MapLeaks = v.leaks()
	var burst: Array[Dictionary] = []
	for i: int in 5:
		burst.append(_leak(i, &"scamp", 1))
	v.play_events(burst)
	assert_eq(l.active_count(), 1, "five at the same moment share one heart")
	assert_eq(l.lives_in(0), 5)
	assert_true(l.shows_count(0))
	for i: int in 40:
		v.advance_effects(0.2)
		v.play_events([_leak(100 + i, &"scamp", 1)])
		assert_true(l.active_count() <= MapLeaks.SLOTS)
	v.advance_effects(1.0)
	assert_eq(l.active_count(), 0)


func test_a_real_wave_of_leaks_returns_every_node_to_the_pool() -> void:
	# No defense: the creatures walk home. Every one that gets through gives a leaked event.
	# Relaxed gives enough lives that the first waves are not lost, so no creature stays alive.
	var stats: Catalog = Fx.catalog()
	var b: Battle = Battle.create(Fx.level("r1_l1", stats), stats, true, [])
	var v: MapView = _view(b)
	var leaked_events: int = 0
	var lives_lost: int = 0
	var start_lives: int = b.lives
	var guard: int = 0
	while b.phase != Battle.Phase.LOST and b.waves_started < 3 and guard < 40000:
		b.start_next_wave()
		while b.phase == Battle.Phase.WAVE and guard < 40000:
			var events: Array[Dictionary] = Fx.tick(b)
			v.sync(1.0)
			v.play_events(events)
			for e: Dictionary in events:
				if e.get("kind") == &"leaked":
					leaked_events += 1
					lives_lost += int(e["lives"])
			assert_true(v.leaks().active_count() <= MapLeaks.SLOTS)
			guard += 1
		if b.phase == Battle.Phase.LOST:
			break
	assert_eq(b.phase, Battle.Phase.BUILD, "the test battle was not lost")
	assert_true(leaked_events > 0, "creatures got through")
	assert_eq(start_lives - lives_lost, b.lives, "the events add up to the lives lost")
	assert_true(v.leaks().started > 0 and v.leaks().started <= leaked_events)
	assert_true(v.is_effect_busy() or v.leaks().active_count() == 0)
	v.advance_effects(2.0)
	v.sync(0.0)
	assert_eq(v.leaks().active_count(), 0, "every heart ended")
	assert_eq(v.creature_count(), 0)
	assert_eq(v.ghost_count(), 0)
	var pool: Array = v.get("_pool")
	assert_eq(pool.size(), v.sprite_count() - v.tower_count(), "every creature sprite is back in the pool")
	var pooled: Dictionary = {}
	for sp: Variant in pool:
		pooled[sp] = true
	assert_eq(pooled.size(), pool.size(), "no sprite is pooled twice")
	for sp: Variant in pool:
		assert_false((sp as Sprite2D).visible, "a pooled sprite is hidden")
	assert_eq(v.sparkles().emitter_count(), MapSparkles.EMITTERS, "no emitter was added")
