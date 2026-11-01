# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## MapView on maps with features (docs/ARCHITECTURE.md 14.10, 14.13; step V3): the ground by
## region, the kept feature layer, the draw order at bridges, walkers fading in tunnels, walkers
## hidden on twin steps with no streak across the jump, and route lines split at twin steps and
## drawn over decks. Fixture maps come from tests/sim/fixtures/sim_fixtures.gd (read only).
## Real frames, with a display, run in tests/render/frames_checks.gd.

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")

## The stump map of the sim fixtures, mirrored, so the twin step goes west.
const MIRROR_STUMP_GRID: Array = [
	"...1...",
	"...#...",
	".##P##.",
	".#...#.",
	".#...#.",
	".P...#.",
	".#...#.",
	".#####.",
	"...B...",
]

## A tunnel of two tiles in a row, walked from east to west.
const SIDEWAYS_TUNNEL_GRID: Array = [
	"......1",
	"......#",
	".#TT###",
	".#.....",
	".#.....",
	".#.....",
	".#.....",
	".B.....",
]

var _views: Array[MapView] = []
var _catalog: Catalog = null


func before_each() -> void:
	_catalog = Sx.catalog()


func after_each() -> void:
	for v: MapView in _views:
		if is_instance_valid(v):
			if v.get_parent() != null:
				v.get_parent().remove_child(v)
			v.free()
	_views.clear()


func _battle(grid: Array, groups: Array) -> Battle:
	return Sx.battle(grid, [{"groups": groups}], {}, _catalog)


func _view(b: Battle, region: StringName = &"lantern_hill") -> MapView:
	var v: MapView = MapView.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(v)
	v.setup(b, region)
	_views.append(v)
	return v


func _nodes() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


# The ground.

func test_the_ground_follows_the_region_and_a_run_map_follows_its_first_feature() -> void:
	var plain: Battle = Fx.battle("r1_l1")
	assert_eq(_view(plain).ground_id(), &"lantern_hill", "the default region")
	for region: StringName in MapArt.GROUNDS:
		assert_eq(_view(plain, region).ground_id(), region, "a campaign region keeps its ground")
	assert_eq(_view(plain, &"").ground_id(), &"lantern_hill", "a run map with no feature")
	assert_eq(_view(plain, &"not_a_region").ground_id(), &"lantern_hill", "an unknown region")
	var cases: Array = [
		[Sx.TUNNEL_GRID, &"hollow_lanes"], [Sx.BRIDGE_LOOP_GRID, &"russet_orchards"],
		[Sx.SLIDE_DOWN_GRID, &"frostpine_ridge"], [Sx.STUMP_GRID, &"starglen"],
		# The first feature in reading order decides: the tunnel comes before the slide.
		[Sx.FEATURE_GRID, &"hollow_lanes"],
	]
	for item: Array in cases:
		var b: Battle = _battle(item[0], [Sx.group("scamp", 1)])
		assert_eq(_view(b, &"").ground_id(), item[1], "a run map's ground by its feature")
		assert_eq(_view(b, &"russet_orchards").ground_id(), &"russet_orchards", "a region wins over the features")


# The feature layer.

func test_only_maps_with_a_feature_get_the_feature_layers() -> void:
	var plain: MapView = _view(Fx.battle("r1_l3"))
	var nodes: Array[Node] = plain.layer_nodes()
	assert_not_null(nodes[0], "ground")
	assert_not_null(nodes[1], "route lines")
	assert_null(nodes[2], "no layer for walkers under a deck")
	assert_null(nodes[3], "no feature layer")
	assert_null(nodes[4], "no layer for lines over decks")
	assert_eq(plain.feature_bakes(), 0)
	# Ice slides are part of the ground: no feature layer for them.
	var slide: MapView = _view(_battle(Sx.SLIDE_DOWN_GRID, [Sx.group("scamp", 1)]))
	assert_eq(slide.feature_bakes(), 0, "a slide is ground")
	assert_null(slide.layer_nodes()[3])
	for grid: Array in [Sx.TUNNEL_GRID, Sx.BRIDGE_LOOP_GRID, Sx.STUMP_GRID, Sx.FEATURE_GRID]:
		var v: MapView = _view(_battle(grid, [Sx.group("scamp", 1)]))
		assert_eq(v.feature_bakes(), 1, "the feature layer is drawn once")
		assert_not_null(v.layer_nodes()[3])
		assert_not_null(v.layer_nodes()[4])


func test_the_layers_are_children_in_draw_order() -> void:
	var b: Battle = _battle(Sx.FEATURE_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	var nodes: Array[Node] = v.layer_nodes()
	var last: int = -1
	for i: int in nodes.size():
		assert_not_null(nodes[i], "layer %d exists on a map with every feature" % i)
		var at: int = v.get_children().find(nodes[i])
		assert_true(at > last, "layer %d comes after the one before it" % i)
		last = at
	# Shots, status and the rest come after the creatures.
	assert_true(v.get_child_count() > last + 1)


func test_the_feature_layer_covers_only_the_box_around_the_features() -> void:
	var tunnel: Rect2 = MapGround.feature_area(PackedStringArray(Sx.TUNNEL_GRID))
	assert_eq(tunnel.position, Vector2(3.0 - MapGround.MARGIN, 2.0 - MapGround.MARGIN), "a three tile tunnel in column 3")
	assert_eq(tunnel.size, Vector2(1.0 + 2.0 * MapGround.MARGIN, 3.0 + 2.0 * MapGround.MARGIN))
	assert_false(MapGround.feature_area(PackedStringArray(Sx.SLIDE_UP_GRID)).has_area(), "slides are not in it")
	var b: Battle = _battle(Sx.TUNNEL_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	var ground: MapGround = v.layer_nodes()[0] as MapGround
	var features: MapGround = v.layer_nodes()[3] as MapGround
	assert_true(features.texture_size().x * features.texture_size().y < ground.texture_size().x * ground.texture_size().y / 4, "a small texture for a small feature")


func test_nothing_is_redrawn_while_playing_a_feature_map() -> void:
	var b: Battle = _battle(Sx.FEATURE_GRID, [Sx.group("scamp", 8, 0, 300)])
	var v: MapView = _view(b)
	v.fit(Rect2(0, 236, 1080, 1700))
	var ground: int = v.ground_bakes()
	var features: int = v.feature_bakes()
	var atlas: int = v.atlas_bakes()
	b.start_next_wave()
	v.show_routes(b.routes(b.closed_cells()))
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 3000:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(0.5)
		v.play_events(events)
		guard += 1
	assert_eq(v.ground_bakes(), ground, "the ground is kept")
	assert_eq(v.feature_bakes(), features, "the feature layer is kept")
	assert_eq(v.atlas_bakes(), atlas, "the sheet is kept")
	v.fit(Rect2(0, 0, 1080, 1750))
	assert_eq(v.feature_bakes(), features, "a resize only moves and scales the node")


func test_setup_again_and_free_leave_no_nodes_behind() -> void:
	var b: Battle = _battle(Sx.FEATURE_GRID, [Sx.group("scamp", 3, 0, 300)])
	var before: int = _nodes()
	var v: MapView = MapView.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(v)
	v.setup(b)
	v.setup(b, &"starglen")
	b.start_next_wave()
	for i: int in 300:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
	tree.root.remove_child(v)
	v.free()
	assert_eq(_nodes(), before, "every node the view made is gone")


# Bridges.

func test_a_walker_under_the_deck_is_below_it_and_one_on_the_deck_is_above_it() -> void:
	var b: Battle = _battle(Sx.BRIDGE_LOOP_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	var bridge: Vector2i = Vector2i(3, 3)
	b.start_next_wave()
	var under: int = 0
	var over: int = 0
	var entities: Node = v.layer_nodes()[7]
	var below: Node = v.layer_nodes()[2]
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		Fx.tick(b)
		v.sync(1.0)
		var e: EnemyState = b.enemy_with_id(0)
		if e == null:
			break
		var sprite: Sprite2D = (v.get("_creatures") as Dictionary)[0].sprite as Sprite2D
		if Sim.cell_of(e.pos) != bridge:
			assert_eq(v.layer_of(0), &"top", "tick %d: off the bridge it is drawn in row order" % b.tick)
			assert_eq(sprite.get_parent(), entities)
			continue
		if b.map.under_bridge(e.from_cell, e.to_cell):
			under += 1
			assert_eq(v.layer_of(0), &"under", "tick %d: on the north-south road it passes under" % b.tick)
			assert_eq(sprite.get_parent(), below, "it is a child of the layer below the deck")
		else:
			over += 1
			assert_eq(v.layer_of(0), &"top", "tick %d: on the east-west road it is on the deck" % b.tick)
			assert_eq(sprite.get_parent(), entities, "it is a child of the layer above the deck")
		assert_eq(v.creature_alpha(0), 1.0, "a bridge hides nothing")
	assert_true(under > 5, "the walker went under the deck")
	assert_true(over > 5, "the walker went over the deck")


func test_a_creature_on_a_bridge_can_be_found_and_the_pool_is_reused() -> void:
	var b: Battle = _battle(Sx.BRIDGE_LOOP_GRID, [Sx.group("scamp", 6, 0, 500)])
	var v: MapView = _view(b)
	v.fit(Rect2(0, 0, 700, 1300))
	b.start_next_wave()
	var found: int = 0
	var peak: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 4000:
		Fx.tick(b)
		v.sync(1.0)
		peak = maxi(peak, b.enemies.size())
		for e: EnemyState in b.enemies:
			if v.layer_of(e.id) == &"under":
				var at: Vector2 = v.get_global_transform() * v.creature_center(e.id)
				if v.enemy_at(at) == e.id:
					found += 1
	assert_true(found > 5, "a walker under the deck is drawn, so a finger finds it")
	v.advance_effects(3.0)
	v.sync(0.0)
	assert_true(v.sprite_count() <= peak + 4, "sprites moved between layers are pooled once: %d for a peak of %d" % [v.sprite_count(), peak])


# Tunnels.

func test_a_walker_fades_out_at_one_mouth_and_back_in_at_the_other() -> void:
	_check_fade(Sx.TUNNEL_GRID, "vertical tunnel")


func test_a_sideways_tunnel_fades_along_its_row() -> void:
	_check_fade(SIDEWAYS_TUNNEL_GRID, "sideways tunnel")


## Walks one scamp through the tunnel of `grid` and checks what the view shows each tick.
func _check_fade(grid: Array, label: String) -> void:
	var b: Battle = _battle(grid, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	v.fit(Rect2(0, 0, 700, 1300))
	b.start_next_wave()
	var alphas: Array[float] = []
	var inside: Array[bool] = []
	var findable_outside: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		Fx.tick(b)
		v.sync(1.0)
		var e: EnemyState = b.enemy_with_id(0)
		if e == null:
			break
		var in_tunnel: bool = b.level.feature_at(Sim.cell_of(e.pos)) == LevelData.Feature.TUNNEL
		inside.append(in_tunnel)
		alphas.append(v.creature_alpha(0))
		var found: bool = v.enemy_at(v.get_global_transform() * v.creature_center(0)) == 0
		if in_tunnel:
			if found:
				assert_true(alphas.back() >= 0.5, "%s: a finger finds it only while it is mostly shown" % label)
			assert_true(v.layer_of(0) == &"under" or v.layer_of(0) == &"hidden", "%s: inside the tunnel it is below the mound" % label)
			assert_true(e.out_of_reach, "%s: the sim agrees it is out of reach" % label)
		else:
			if found:
				findable_outside += 1
			assert_eq(v.layer_of(0), &"top", "%s: outside it is in row order" % label)
			assert_eq(alphas.back(), 1.0, "%s: outside it is whole" % label)
	var first: int = inside.find(true)
	var last: int = inside.rfind(true)
	assert_true(first > 0 and last > first, "%s: it went through the tunnel" % label)
	assert_true(alphas[first] > 0.8, "%s: it is almost whole at the first mouth" % label)
	assert_true(alphas[last] > 0.8, "%s: and almost whole at the last" % label)
	var bottom: int = alphas.find(0.0)
	var rise: int = alphas.rfind(0.0)
	assert_true(bottom > first and rise < last and rise >= bottom, "%s: it is gone inside" % label)
	for i: int in range(first + 1, bottom + 1):
		assert_true(alphas[i] <= alphas[i - 1] + 0.0001, "%s: it fades out one way" % label)
	for i: int in range(rise + 1, last + 1):
		assert_true(alphas[i] >= alphas[i - 1] - 0.0001, "%s: and back in" % label)
	var partial: int = 0
	for a: float in alphas:
		if a > 0.0 and a < 1.0:
			partial += 1
	assert_true(partial >= 2, "%s: it fades, it does not blink" % label)
	assert_true(findable_outside > 5, "%s: a finger finds it outside" % label)
	

func test_the_faded_sprite_scales_all_four_channels() -> void:
	# The sheet is premultiplied, so a lone alpha would brighten it.
	var b: Battle = _battle(Sx.TUNNEL_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	b.start_next_wave()
	var partial: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		Fx.tick(b)
		v.sync(1.0)
		if b.enemy_with_id(0) == null:
			break
		var a: float = v.creature_alpha(0)
		var sprite: Sprite2D = (v.get("_creatures") as Dictionary)[0].sprite as Sprite2D
		assert_eq(sprite.modulate, Color(a, a, a, a))
		assert_eq(sprite.visible, a > 0.0)
		if a > 0.0 and a < 1.0:
			partial += 1
	assert_true(partial >= 2)


# Twin steps.

func _walk_stumps(grid: Array, label: String) -> Dictionary:
	var b: Battle = _battle(grid, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	v.fit(Rect2(0, 0, 700, 1300))
	b.start_next_wave()
	var out: Dictionary = {"hidden": 0, "bursts": 0, "found": 0, "left_before": false, "left_after": false, "landed": Vector2.ZERO,
		"jumped": 0, "max_step": 0.0, "stump": Vector2.ZERO, "twin": Vector2.ZERO}
	var prev: Vector2 = Vector2.ZERO
	var prev_shown: bool = false
	var was_hidden: bool = false
	var entered_bursts: int = 0
	var twin_tick: int = -1
	var landed_tick: int = -100
	var alpha_before: float = 1.0
	out["fading"] = 0
	out["fading_in"] = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 3000:
		Fx.tick(b)
		# Sweep the interpolation, as frames between two ticks would.
		for a: float in [0.0, 0.34, 0.67, 1.0]:
			v.sync(a)
			var e: EnemyState = b.enemy_with_id(0)
			if e == null:
				break
			var step_is_twin: bool = e.progress < Sim.UNIT and e.to_cell == b.map.twin_of(e.from_cell)
			var layer: StringName = v.layer_of(0)
			var shown: float = v.creature_alpha(0)
			if step_is_twin:
				if twin_tick < 0:
					twin_tick = b.tick
					alpha_before = 1.0
				assert_true(shown <= alpha_before + 0.0001, "%s tick %d: it only fades out on the way in" % [label, b.tick])
				alpha_before = shown
				if b.tick - twin_tick >= 4:
					assert_eq(layer, &"hidden", "%s tick %d: hidden once the fade is done" % [label, b.tick])
				if shown > 0.0:
					out["fading"] += 1
					var at_stump: Vector2 = (Vector2(e.from_cell) + Vector2(0.5, 0.5)) * MapView.CELL
					assert_true(v.creature_center(0).distance_to(at_stump) < MapView.CELL * 0.3, "%s tick %d: it fades out where it went in, no streak" % [label, b.tick])
				else:
					out["hidden"] += 1
				out["stump"] = v.creature_center(0)
				if shown < 0.5 and v.enemy_at(v.get_global_transform() * v.creature_center(0)) == 0:
					out["found"] += 1
				if not was_hidden:
					entered_bursts = v.sparkles().bursts
				was_hidden = true
				prev_shown = false
				landed_tick = b.tick
				continue
			twin_tick = -1
			if b.tick - landed_tick >= 4:
				assert_true(layer != &"hidden", "%s tick %d: shown again once the fade is done" % [label, b.tick])
			elif b.tick - landed_tick <= 3 and was_hidden == false and shown < 1.0:
				out["fading_in"] += 1
				var here: Vector2i = e.to_cell if e.progress >= Sim.UNIT else e.from_cell
				var at_twin: Vector2 = (Vector2(here) + Vector2(0.5, 0.5)) * MapView.CELL
				assert_true(v.creature_center(0).distance_to(at_twin) < MapView.CELL * 0.5, "%s tick %d: it fades in at the twin, no streak" % [label, b.tick])
			if was_hidden:
				was_hidden = false
				out["bursts"] = entered_bursts
				out["landed"] = v.creature_center(0)
				out["left_after"] = v.creature_faces_left(0)
				out["twin"] = (Vector2(e.from_cell) + Vector2(0.5, 0.5)) * MapView.CELL
			elif not prev_shown:
				out["left_before"] = v.creature_faces_left(0)
			var c: Vector2 = v.creature_center(0)
			if prev_shown:
				out["max_step"] = maxf(float(out["max_step"]), c.distance_to(prev))
			prev = c
			prev_shown = true
	return out


func test_a_walker_on_a_twin_step_is_hidden_and_reappears_at_the_twin() -> void:
	var r: Dictionary = _walk_stumps(Sx.STUMP_GRID, "stump map")
	assert_true(r["hidden"] > 4, "it is hidden for most of the step")
	assert_true(r["fading"] > 0, "it fades out at the stump instead of vanishing at once")
	assert_true(r["fading_in"] > 0, "it fades in at the twin")
	assert_eq(r["found"], 0, "a finger finds nothing where it is faint or not drawn")
	assert_true(r["max_step"] < MapView.CELL * 0.5, "no streak: drawn positions never jump while it shows (largest %.1f px)" % r["max_step"])
	var landed: Vector2 = r["landed"]
	var twin_center: Vector2 = (Vector2(5, 5) + Vector2(0.5, 0.5)) * MapView.CELL
	assert_true(landed.distance_to(twin_center) < MapView.CELL * 0.3, "it shows again at the twin: %s" % landed)
	var stump: Vector2 = r["stump"]
	assert_true(stump.distance_to((Vector2(3, 2) + Vector2(0.5, 0.5)) * MapView.CELL) < 1.0, "it was hidden at the stump it entered")


func test_a_walker_sparkles_where_it_goes_in() -> void:
	var b: Battle = _battle(Sx.STUMP_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	b.start_next_wave()
	var before: int = -1
	var after: int = -1
	var at: Vector2 = Vector2.ZERO
	while b.phase == Battle.Phase.WAVE and b.tick < 3000:
		Fx.tick(b)
		var e: EnemyState = b.enemy_with_id(0)
		if e == null:
			break
		var twin: bool = e.progress < Sim.UNIT and e.to_cell == b.map.twin_of(e.from_cell)
		if before < 0 and not twin:
			v.sync(1.0)
			before = v.sparkles().bursts
		elif before >= 0 and twin and after < 0:
			v.sync(1.0)
			after = v.sparkles().bursts
			at = v.sparkles().last_emitter.position
			v.sync(1.0)
			assert_eq(v.sparkles().bursts, after, "one burst for the step, not one a frame")
	assert_true(after > before, "sparkles when it goes in")
	assert_true(at.distance_to((Vector2(3, 2) + Vector2(0.5, 0.5)) * MapView.CELL) < 1.0, "at the stump it entered")


func test_a_jump_to_the_west_does_not_turn_the_walker_round() -> void:
	var r: Dictionary = _walk_stumps(MIRROR_STUMP_GRID, "mirrored stump map")
	assert_true(r["hidden"] > 4)
	var landed: Vector2 = r["landed"]
	assert_true(landed.distance_to((Vector2(1, 5) + Vector2(0.5, 0.5)) * MapView.CELL) < MapView.CELL * 0.3, "it lands at the western stump: %s" % landed)
	assert_eq(r["left_before"], false, "it came down the road facing right")
	assert_eq(r["left_after"], false, "the jump west did not turn it round: it walks south on")
	assert_true(r["max_step"] < MapView.CELL * 0.5, "no streak across the map")


func test_a_release_that_begins_on_a_twin_step_is_hidden_too() -> void:
	var b: Battle = _battle(Sx.STUMP_GRID, [Sx.group("grumblesack", 1)])
	var v: MapView = _view(b)
	b.start_next_wave()
	var guard: int = 0
	var twin_since: Dictionary = {}
	var landed: Dictionary = {}
	var saw_twin: bool = false
	while b.phase == Battle.Phase.WAVE and guard < 6000:
		Fx.tick(b)
		v.sync(1.0)
		for e: EnemyState in b.enemies:
			var twin: bool = e.progress < Sim.UNIT and e.to_cell == b.map.twin_of(e.from_cell)
			if twin:
				twin_since[e.id] = int(twin_since.get(e.id, b.tick))
				if b.tick - int(twin_since[e.id]) >= 4:
					assert_eq(v.layer_of(e.id), &"hidden", "tick %d: creature %d is gone from the stump" % [b.tick, e.id])
				saw_twin = true
			else:
				if twin_since.has(e.id):
					landed[e.id] = b.tick
					twin_since.erase(e.id)
				if b.tick - int(landed.get(e.id, -100)) >= 4:
					assert_true(v.layer_of(e.id) != &"hidden", "tick %d: creature %d shows" % [b.tick, e.id])
		guard += 1
	assert_true(guard > 100)
	assert_true(saw_twin, "a creature took the twin step")


# Route lines.

func test_route_lines_are_split_at_twin_steps() -> void:
	var b: Battle = _battle(Sx.STUMP_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	v.show_routes(b.routes(b.closed_cells()))
	var layer: MapRoutes = v.get("_routes") as MapRoutes
	var line: MapRoutes.Line = layer.lines[0]
	assert_eq(line.walk.size(), 2, "the line runs into a stump and starts again at its twin")
	var stump: Vector2 = (Vector2(3, 2) + Vector2(0.5, 0.5)) * MapView.CELL
	var twin: Vector2 = (Vector2(5, 5) + Vector2(0.5, 0.5)) * MapView.CELL
	assert_eq(line.walk[0][line.walk[0].size() - 1], stump)
	assert_eq(line.walk[1][0], twin)
	assert_eq(line.walk[0][0], (Vector2(3, 0) + Vector2(0.5, 0.5)) * MapView.CELL, "from the entrance")
	assert_eq(line.walk[1][line.walk[1].size() - 1], (Vector2(3, 8) + Vector2(0.5, 0.5)) * MapView.CELL, "to the base")
	for part: PackedVector2Array in line.walk:
		for i: int in range(1, part.size()):
			assert_true(part[i].distance_to(part[i - 1]) < MapView.CELL * 1.01, "no segment crosses the map")
	# A map with no twin step keeps one line.
	var plain: MapView = _view(Fx.battle("r1_l2"))
	plain.show_routes(Fx.battle("r1_l2").routes([] as Array[Vector2i]))
	assert_eq((plain.get("_routes") as MapRoutes).lines[0].walk.size(), 1)


func test_route_lines_split_for_gate_breakers_too() -> void:
	var b: Battle = _battle(Sx.STUMP_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	var routes: Array[Dictionary] = b.routes(b.closed_cells())
	routes[0]["break"] = routes[0]["walk"]
	v.show_routes(routes)
	var line: MapRoutes.Line = (v.get("_routes") as MapRoutes).lines[0]
	assert_eq(line.breaker.size(), 2)


func test_a_strange_route_does_not_break_the_lines() -> void:
	var b: Battle = _battle(Sx.STUMP_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	var routes: Array[Dictionary] = [
		{"entrance": 1, "walk": [Vector2i(0, 0), Vector2i(5, 5), Vector2i(1, 1)], "break": [Vector2i(2, 2)], "cracks": [], "fly": false},
		{"entrance": 9, "walk": "not a list", "break": [], "cracks": [], "fly": true},
	]
	v.show_routes(routes)
	var layer: MapRoutes = v.get("_routes") as MapRoutes
	assert_eq(layer.lines[0].walk.size(), 0, "single cells make no line")
	assert_eq(layer.lines[0].breaker.size(), 0)
	assert_eq(layer.lines[1].fly.size(), 0, "an entrance that is not on the map has no flyer line")


func test_a_line_over_a_deck_is_drawn_again_on_top_and_one_under_it_is_not() -> void:
	# Entrance 2 crosses the bridge east to west, entrance 1 goes under it.
	var b: Battle = _battle(Sx.BRIDGE_GATE_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	v.show_routes(b.routes(b.closed_cells()))
	var base: MapRoutes = v.get("_routes") as MapRoutes
	var top: MapRoutes = v.get("_overpass") as MapRoutes
	assert_true(top.deck_layer and not base.deck_layer)
	assert_true(base.fly_above, "the flyers' line goes to the top layer on a map with features")
	assert_eq(top.lines.size(), 2)
	var bridge: Vector2 = (Vector2(3, 3) + Vector2(0.5, 0.5)) * MapView.CELL
	var north_south: int = 0
	var east_west: int = 0
	for i: int in top.lines.size():
		var cells: Array[Vector2i] = []
		for c: Variant in b.routes(b.closed_cells())[i]["walk"] as Array:
			cells.append(c)
		var crosses_over: bool = false
		for k: int in range(1, cells.size() - 1):
			if cells[k] == Vector2i(3, 3) and cells[k - 1].y == 3:
				crosses_over = true
		var decks: Array[MapRoutes.Deck] = top.lines[i].walk_decks
		if crosses_over:
			east_west += 1
			assert_eq(decks.size(), 1, "entrance %d goes over the deck" % (i + 1))
			var pts: PackedVector2Array = decks[0].points
			for p: Vector2 in pts:
				assert_eq(p.y, bridge.y, "the piece runs along the deck")
			assert_true(minf(pts[0].x, pts[pts.size() - 1].x) <= bridge.x - MapRoutes.DECK_HALF * MapView.CELL + 0.01, "it reaches the near end of the deck")
			assert_true(maxf(pts[0].x, pts[pts.size() - 1].x) >= bridge.x + MapRoutes.DECK_HALF * MapView.CELL - 0.01, "and the far end")
			assert_true(pts[pts.size() - 1].x > pts[0].x, "in the walker's direction")
		else:
			north_south += 1
			assert_eq(decks.size(), 0, "entrance %d goes under the deck: the deck cuts its line" % (i + 1))
	assert_eq([east_west, north_south], [1, 1])
	assert_eq(top.deck_count(), 1)
	v.show_routes([])
	assert_eq(top.deck_count(), 0)


func test_a_route_that_crosses_itself_at_a_bridge_has_one_piece_over_it() -> void:
	var b: Battle = _battle(Sx.BRIDGE_LOOP_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	v.show_routes(b.routes(b.closed_cells()))
	var top: MapRoutes = v.get("_overpass") as MapRoutes
	assert_eq(top.deck_count(), 1, "over once, and under once without a piece")
	var line: MapRoutes.Line = top.lines[0]
	assert_eq(line.walk.size(), 1)
	# The piece lies on the whole line: its first and last points are on it, and it starts after the line does.
	var deck: MapRoutes.Deck = line.walk_decks[0]
	var bridge: Vector2 = (Vector2(3, 3) + Vector2(0.5, 0.5)) * MapView.CELL
	assert_true(deck.start > 0.0)
	for p: Vector2 in deck.points:
		assert_eq(p.y, bridge.y, "level, like the deck")
	assert_true(deck.points[0].x < bridge.x and deck.points[deck.points.size() - 1].x > bridge.x)


func test_dashed_breaker_lines_get_deck_pieces_too() -> void:
	var b: Battle = _battle(Sx.BRIDGE_GATE_GRID, [Sx.group("scamp", 1)])
	var v: MapView = _view(b)
	var routes: Array[Dictionary] = b.routes(b.closed_cells())
	for r: Dictionary in routes:
		r["break"] = r["walk"]
	v.show_routes(routes)
	var top: MapRoutes = v.get("_overpass") as MapRoutes
	assert_eq(top.deck_count(), 2, "one for the walker line and one for the breaker line of entrance 2")


func test_a_deck_next_to_a_mound_does_not_draw_over_it() -> void:
	# A tunnel tile at [2, 3] right beside the bridge at [3, 3]. Entrance 2 crosses the deck east.
	var grid: Array = [
		"...1...",
		"...#...",
		"...#...",
		"2#TX##.",
		"...#.#.",
		"...#.#.",
		"...###.",
		".....B.",
	]
	var lvl: LevelData = LevelData.from_data(Sx.level_data(grid, [{"groups": [Sx.group("scamp", 1, 0, 1000, 2)]}]), _catalog)
	assert_not_null(lvl, "the map loads")
	var b: Battle = Battle.create(lvl, _catalog, false, [])
	var v: MapView = _view(b)
	v.show_routes(b.routes(b.closed_cells()))
	var top: MapRoutes = v.get("_overpass") as MapRoutes
	assert_eq(top.deck_count(), 1)
	var bridge_x: float = 3.5 * MapView.CELL
	for line: MapRoutes.Line in top.lines:
		for deck: MapRoutes.Deck in line.walk_decks:
			var left: float = INF
			var right: float = -INF
			for p: Vector2 in deck.points:
				left = minf(left, p.x)
				right = maxf(right, p.x)
			assert_true(absf(left - (bridge_x - MapRoutes.DECK_HALF * MapView.CELL)) < 0.5, "the piece stops at the deck's end next to the mound: %.1f" % left)
			assert_true(right > bridge_x + (MapRoutes.DECK_HALF + 0.3) * MapView.CELL, "and goes on over plain road to the east, for its arrows: %.1f" % right)
