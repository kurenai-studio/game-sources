# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The three parts of every tower shot (docs/ARCHITECTURE.md 9.3): a mark where it leaves, a body in
## flight, and a mark where it lands. The catapult shows its true splash area, read from the tower's
## stats. Played on a real Battle on the arena map of render_fixtures.gd.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const GUARD_TICKS: int = 2000

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


## Plays ticks until the tower has fired once. Returns false if it never did.
func _until_fired(b: Battle, v: MapView) -> bool:
	var shots: MapShots = v.get("_shots") as MapShots
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
		ticks += 1
		if not shots.shots.is_empty():
			return true
	return false


func test_a_catapult_shows_the_towers_real_splash_area() -> void:
	# [tier, spec, splash in hundredths of a tile].
	var cases: Array = [[1, -1, 75], [2, -1, 125], [3, 0, 150], [3, 1, 125]]
	for c: Array in cases:
		var label: String = "tier %d spec %d" % [c[0], c[1]]
		var b: Battle = Fx.arena([[Fx.group("scamp", 6, 200)]], 1000)
		assert_true(Fx.build(b, Vector2i(4, 2), &"pumpkin_catapult", c[0], c[1]), label)
		assert_eq(b.towers[0].stats.splash, c[2], "%s: the stats" % label)
		var v: MapView = _view(b)
		var shots: MapShots = v.get("_shots") as MapShots
		b.start_next_wave()
		assert_true(_until_fired(b, v), "%s: it fired" % label)
		var want: float = float(c[2]) / 100.0 * MapView.CELL
		var shot: MapShots.Shot = shots.shots[0]
		assert_true(MapShots.is_lobbed(shot.look), label)
		assert_near(shot.radius, want, 0.01, "%s: the ground mark has the splash radius" % label)
		var hits: int = shots.marked[MapShots.Fx.HIT]
		v.advance_effects(0.3)
		assert_true(shots.marked[MapShots.Fx.SPLASH] >= 1, "%s: a splash where it landed" % label)
		assert_eq(shots.marked[MapShots.Fx.HIT], hits, "%s: no plain hit mark" % label)
		var radius: float = 0.0
		for f: MapShots.Flash in shots.flashes:
			if f.kind == MapShots.Fx.SPLASH:
				radius = f.size
		assert_near(radius, want, 0.01, "%s: the splash reaches its true radius" % label)


func test_every_shot_has_a_mark_where_it_leaves_and_where_it_lands() -> void:
	for look: int in MapShots.Look.values():
		var shots: MapShots = MapShots.new()
		var from: Vector2 = Vector2(2.0, 2.0) * MapShots.CELL
		var arrives: float = shots.launch(look, from, from + Vector2(3.0, 1.0) * MapShots.CELL, 1, 0.0, 96.0)
		assert_eq(shots.marked[MapShots.Fx.MUZZLE], 1, "look %d: a mark at the tower" % look)
		var placed: bool = MapShots.look_is_placed(look)
		assert_true(arrives <= (0.4 if placed else 0.25), "look %d: flies for %.2f s" % [look, arrives])
		shots.advance(arrives + 0.01)
		assert_eq(shots.shots.size(), 0, "look %d: it landed" % look)
		var landed: int = shots.marked[MapShots.Fx.HIT] + shots.marked[MapShots.Fx.SPLASH]
		# A thorn ring and a snowball put their hit marks on each creature when they are launched
		# (MapView), so the shot itself leaves none where it ends.
		assert_eq(landed, 0 if placed else 1, "look %d: one mark where it landed" % look)
		if MapShots.is_lobbed(look):
			assert_eq(shots.marked[MapShots.Fx.SPLASH], 1, "look %d: a splash" % look)
		shots.advance(arrives + 2.0)
		assert_false(shots.is_busy(), "look %d: every mark ends" % look)
		shots.free()


func test_a_lobbed_shot_keeps_its_splash_where_the_hit_was_worked_out() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 6, 200)]], 1000)
	assert_true(Fx.build(b, Vector2i(4, 2), &"pumpkin_catapult", 1))
	var v: MapView = _view(b)
	var shots: MapShots = v.get("_shots") as MapShots
	b.start_next_wave()
	assert_true(_until_fired(b, v))
	var shot: MapShots.Shot = shots.shots[0]
	var spot: Vector2 = shot.spot
	assert_eq(shot.to, spot, "it starts aimed at the hit")
	var slid: bool = false
	var guard: int = 0
	while not shots.shots.is_empty() and guard < 200:
		v.sync(1.0)
		Fx.tick(b)
		v.sync(1.0)
		guard += 1
		if shot.to != spot:
			slid = true
		assert_eq(shot.spot, spot, "the spot the sim hit never moves")
		assert_true(shot.to.distance_to(spot) <= shot.radius * MapShots.AIM_REACH + 0.01, "the picture stays near it")
		if shots.now >= shot.t1 - 0.001:
			break
		v.advance_effects(0.02)
	assert_true(slid, "the pumpkin came down on the creature that walked on")
	v.advance_effects(0.3)
	var found: bool = false
	for f: MapShots.Flash in shots.flashes:
		if f.kind == MapShots.Fx.SPLASH:
			found = true
			assert_eq(f.at, spot, "the splash area is centered on the real hit")
			assert_near(f.size, shot.radius, 0.01, "and has the real radius")
			assert_true(f.aim.distance_to(spot) <= shot.radius * MapShots.AIM_REACH + 0.01, "the burst of chunks is inside it")
	assert_true(found, "a splash")


func test_the_dashed_ring_stays_on_the_real_hit_while_the_shot_slides() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 6, 200)]], 1000)
	assert_true(Fx.build(b, Vector2i(4, 2), &"pumpkin_catapult", 1))
	var v: MapView = _view(b)
	var shots: MapShots = v.get("_shots") as MapShots
	b.start_next_wave()
	assert_true(_until_fired(b, v))
	var shot: MapShots.Shot = shots.shots[0]
	var spot: Vector2 = shot.spot
	var slid: bool = false
	var guard: int = 0
	while not shots.shots.is_empty() and guard < 200:
		v.sync(1.0)
		Fx.tick(b)
		v.sync(1.0)
		guard += 1
		if shot.to != spot:
			slid = true
		assert_eq(MapShots.landing_mark_center(shot), spot, "the ring is centered on the real hit")
		if shots.now >= shot.t1 - 0.001:
			break
		v.advance_effects(0.02)
	assert_true(slid, "the shot body slid toward the creature")
	# The same, with a creature far away, so the slide is at its longest.
	var lone: MapShots = MapShots.new()
	var real: Vector2 = Vector2(5.0, 4.0) * MapShots.CELL
	lone.launch(MapShots.Look.PUMPKIN, Vector2(2.0, 2.0) * MapShots.CELL, real, 3, 0.0, 96.0)
	var pumpkin: MapShots.Shot = lone.shots[0]
	lone.aim_at(pumpkin, real + Vector2(0.0, 300.0))
	assert_ne(pumpkin.to, real, "the body slid")
	assert_eq(MapShots.landing_mark_center(pumpkin), real, "the ring did not")
	lone.free()


func test_a_lobbed_shot_and_a_rocket_come_down_on_their_creature_inside_the_true_area() -> void:
	for look: int in [MapShots.Look.PUMPKIN, MapShots.Look.JAM, MapShots.Look.PRIZE, MapShots.Look.ROCKET, MapShots.Look.BLOOM]:
		var shots: MapShots = MapShots.new()
		var from: Vector2 = Vector2(2.0, 2.0) * MapShots.CELL
		var spot: Vector2 = Vector2(5.0, 4.0) * MapShots.CELL
		var radius: float = 96.0
		var arrives: float = shots.launch(look, from, spot, 7, 0.0, radius)
		var shot: MapShots.Shot = shots.shots[0]
		assert_eq(shot.spot, spot, "look %d: the real spot" % look)
		assert_near(shot.radius, radius, 0.01, "look %d: the real radius" % look)
		# The creature walked a little way: the picture follows it all the way.
		var near: Vector2 = spot + Vector2(0.0, 20.0)
		shots.aim_at(shot, near)
		assert_eq(shot.to, near, "look %d: it follows a short step" % look)
		# The creature walked far: the picture stops inside the true area.
		var far: Vector2 = spot + Vector2(0.0, 300.0)
		shots.aim_at(shot, far)
		assert_near(shot.to.distance_to(spot), radius * MapShots.AIM_REACH, 0.01, "look %d: it stops short" % look)
		assert_true(shot.to.y > spot.y, "look %d: toward the creature" % look)
		shots.advance(arrives + 0.01)
		var kind: int = MapShots.Fx.SPLASH if MapShots.is_lobbed(look) else MapShots.Fx.BURST
		var area: MapShots.Flash = null
		var hit: MapShots.Flash = null
		for f: MapShots.Flash in shots.flashes:
			if f.kind == kind:
				area = f
			elif f.kind == MapShots.Fx.HIT:
				hit = f
		assert_not_null(area, "look %d: the splash or burst" % look)
		if area != null:
			assert_eq(area.at, spot, "look %d: its area stays on the real spot" % look)
			assert_near(area.size, radius, 0.01, "look %d: with the real radius" % look)
			assert_eq(area.aim, shot.to, "look %d: its flash lands on the creature" % look)
		if not MapShots.is_lobbed(look):
			assert_not_null(hit, "look %d: a hit mark on the creature" % look)
			if hit != null:
				assert_eq(hit.at, shot.to, "look %d: the hit mark is on the creature" % look)
		shots.free()


func test_shots_that_follow_their_creature_still_end_on_it() -> void:
	for look: int in [MapShots.Look.PEBBLE, MapShots.Look.STONE, MapShots.Look.ARROW, MapShots.Look.GIANT_ARROW, MapShots.Look.SKYROCKET]:
		var shots: MapShots = MapShots.new()
		shots.launch(look, Vector2.ZERO, Vector2(500.0, 0.0), 3, 0.0)
		var shot: MapShots.Shot = shots.shots[0]
		shots.aim_at(shot, Vector2(500.0, 300.0))
		assert_eq(shot.to, Vector2(500.0, 300.0), "look %d: no limit on a single target" % look)
		shots.free()


func test_catapult_and_rocket_flights_are_short_enough_to_read_as_instant() -> void:
	var longest: float = 6.0 * MapShots.CELL
	for look: int in MapShots.Look.values():
		var shots: MapShots = MapShots.new()
		var arrives: float = shots.launch(look, Vector2.ZERO, Vector2(longest, 0.0), 1, 0.0, 96.0)
		if MapShots.is_lobbed(look):
			assert_true(arrives <= 0.17, "look %d: lobbed flight %.3f s" % [look, arrives])
			assert_true(arrives >= 0.1, "look %d: still long enough to show its arc, %.3f s" % [look, arrives])
		elif look == MapShots.Look.ROCKET or look == MapShots.Look.BLOOM:
			assert_true(arrives <= 0.13, "look %d: rocket flight %.3f s" % [look, arrives])
		shots.free()


func test_a_single_target_hit_mark_is_smaller_than_the_smallest_creature() -> void:
	var smallest: float = 99.0
	for id: StringName in Silhouettes.ENEMY_SIZE:
		smallest = minf(smallest, Silhouettes.ENEMY_SIZE[id])
	assert_near(smallest, 0.4, 0.001, "the smallest creature is 0.4 of a cell")
	for heavy: bool in [false, true]:
		for i: int in 21:
			var k: float = float(i) / 20.0
			var reach: float = MapShots.hit_reach(heavy, k)
			assert_true(reach * 2.0 < smallest * MapShots.CELL, "heavy %s at %.2f: %.1f px across" % [heavy, k, reach * 2.0])
			assert_true(reach > 0.0, "heavy %s at %.2f: it shows" % [heavy, k])
	assert_true(MapShots.hit_reach(true, 1.0) > MapShots.hit_reach(false, 1.0), "a heavy hit still reads bigger")
	assert_true(MapShots.LIFE[MapShots.Fx.HIT] <= 0.2, "and it is quick")


func test_every_hit_mark_lands_on_the_creature_and_ends_quickly() -> void:
	for look: int in [MapShots.Look.PEBBLE, MapShots.Look.STONE, MapShots.Look.ARROW, MapShots.Look.GIANT_ARROW, MapShots.Look.SKYROCKET, MapShots.Look.ROCKET, MapShots.Look.BLOOM]:
		var shots: MapShots = MapShots.new()
		var to: Vector2 = Vector2(4.0, 3.0) * MapShots.CELL
		var arrives: float = shots.launch(look, Vector2.ZERO, to, 1, 0.0, 96.0)
		shots.advance(arrives + 0.001)
		var hits: int = 0
		for f: MapShots.Flash in shots.flashes:
			if f.kind == MapShots.Fx.HIT:
				hits += 1
				assert_eq(f.at, to, "look %d: on the creature" % look)
				var heavy: bool = look == MapShots.Look.GIANT_ARROW or look == MapShots.Look.SKYROCKET
				assert_eq(f.size > 1.0, heavy, "look %d: heavy only for the Giant Bow and Skyrocket" % look)
		assert_eq(hits, 1, "look %d: one hit mark" % look)
		shots.advance(arrives + 0.25)
		var left: int = 0
		for f: MapShots.Flash in shots.flashes:
			if f.kind == MapShots.Fx.HIT:
				left += 1
		assert_eq(left, 0, "look %d: the hit mark is gone in a quarter second" % look)
		shots.free()


func test_a_tower_kicks_back_when_it_fires_and_settles() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 2, 400)]], 1000)
	assert_true(Fx.build(b, Vector2i(4, 2), &"pumpkin_catapult", 1))
	var v: MapView = _view(b)
	b.start_next_wave()
	assert_true(_until_fired(b, v))
	for i: int in 2:
		v.sync(1.0)
		Fx.tick(b)
	v.sync(1.0)
	var tower: MapView.TowerView = (v.get("_towers") as Dictionary)[Vector2i(4, 2)]
	assert_true(absf(tower.kick_lean) > 0.05, "it leans")
	assert_true(tower.kick_lean > 0.0, "away from a target on its left")
	assert_true(absf(tower.sprite.rotation) > 0.01, "and shows it")
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS:
		Fx.tick(b)
		ticks += 1
	v.advance_effects(2.0)
	v.sync(0.0)
	assert_near(tower.sprite.rotation, 0.0, 0.0001, "back upright")


func test_shots_and_marks_stay_inside_their_caps() -> void:
	var shots: MapShots = MapShots.new()
	for i: int in 400:
		shots.launch(i % MapShots.Look.size(), Vector2.ZERO, Vector2(200.0, 100.0), i, 0.0, 96.0)
	assert_true(shots.shots.size() <= MapShots.MAX_SHOTS, "%d shots" % shots.shots.size())
	assert_true(shots.flashes.size() <= MapShots.MAX_FLASHES, "%d marks" % shots.flashes.size())
	shots.advance(1.0)
	assert_true(shots.flashes.size() <= MapShots.MAX_FLASHES, "%d marks after landing" % shots.flashes.size())
	shots.free()


func test_every_shot_piece_is_on_the_sheet() -> void:
	assert_eq(ShotPieces.TILES.size(), ShotPieces.Piece.size(), "a tile size for every piece")
	assert_eq(ShotPieces.ANCHORS.size(), ShotPieces.Piece.size(), "an anchor for every piece")
	var atlas: MapAtlas = MapAtlas.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(atlas)
	atlas.add_shot_pieces()
	atlas.add_shot_pieces()
	atlas.bake(1.0)
	assert_eq(atlas.entries.size(), ShotPieces.Piece.size(), "added once")
	for piece: int in ShotPieces.Piece.size():
		var e: MapAtlas.Entry = atlas.entry_for(ShotPieces.key(piece))
		assert_not_null(e, "piece %d" % piece)
		if e != null:
			assert_true(e.rect.size.x > 0.0 and e.rect.size.y > 0.0, "piece %d has room on the sheet" % piece)
			assert_true(e.anchor.x <= e.tile.x and e.anchor.y <= e.tile.y, "piece %d anchor is inside its tile" % piece)
	tree.root.remove_child(atlas)
	atlas.free()
