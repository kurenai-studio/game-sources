# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## MapView on what phase 7 added (docs/ARCHITECTURE.md 3.7, 13 V1): the Longbow Loft and the
## Firework Tower with their paths, every creature and boss, heals, gate breaks and releases,
## boss speed ups, the coin glint, the gate looks in their order and all six looks in the atlas.
## Every wave is played on a real Battle on the arena map of render_fixtures.gd, and every view
## is freed at the end with the node count back where it started.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const GUARD_TICKS: int = 30000

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


func _nodes() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


## Plays the running wave to its end, one tick a frame. Returns the events seen, by kind, and the
## most creatures on the map. Checks one node per live creature on every frame.
func _play(b: Battle, v: MapView, label: String) -> Dictionary:
	var seen: Dictionary = {}
	var peak: int = 0
	var ticks: int = 0
	var cracked: bool = false
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		for e: Dictionary in events:
			seen[e["kind"]] = int(seen.get(e["kind"], 0)) + 1
		v.sync(1.0)
		v.play_events(events)
		cracked = cracked or not (v.get("_crack_cells") as Array).is_empty()
		if v.creature_count() != b.enemies.size():
			fail("%s tick %d: %d nodes for %d creatures" % [label, b.tick, v.creature_count(), b.enemies.size()])
			break
		peak = maxi(peak, b.enemies.size())
		ticks += 1
	assert_true(ticks < GUARD_TICKS, "%s: the wave ended" % label)
	seen["peak"] = peak
	seen["cracked"] = cracked
	v.advance_effects(3.0)
	v.sync(0.0)
	return seen


## After a wave: no creature node is left, every pooled sprite is hidden and counted once, and
## nothing is still drawing an effect.
func _assert_clean(v: MapView, label: String, peak: int) -> void:
	assert_eq(v.creature_count(), 0, "%s: no creature node left" % label)
	assert_eq(v.ghost_count(), 0, "%s: no ghost left" % label)
	assert_false(v.is_effect_busy(), "%s: no effect left" % label)
	assert_true(v.sprite_count() <= v.tower_count() + peak + 4, "%s: %d sprites for %d towers and a peak of %d" % [label, v.sprite_count(), v.tower_count(), peak])
	var pool: Array = v.get("_pool")
	assert_eq(pool.size(), v.sprite_count() - v.tower_count(), "%s: every creature sprite is back in the pool" % label)
	var pooled: Dictionary = {}
	for sp: Variant in pool:
		pooled[sp] = true
		assert_false((sp as Sprite2D).visible, "%s: a pooled sprite is hidden" % label)
	assert_eq(pooled.size(), pool.size(), "%s: no sprite is pooled twice" % label)
	assert_eq((v.get("_crack_cells") as Array).size(), 0, "%s: no gate is still cracking" % label)
	assert_eq((v.get("_break_total") as Dictionary).size(), 0, "%s: no breaker is still tracked" % label)


# The new towers and their paths.

func test_longbow_and_firework_shots_have_their_own_look() -> void:
	# [tower, tier, spec, enemy, look]: a burst for tiers 1 and 2, then the three paths.
	var cases: Array = [
		[&"longbow_loft", 1, -1, "scamp", MapShots.Look.ARROW],
		[&"longbow_loft", 2, -1, "scamp", MapShots.Look.ARROW],
		[&"longbow_loft", 3, 0, "scamp", MapShots.Look.GIANT_ARROW],
		[&"longbow_loft", 3, 1, "scamp", MapShots.Look.ARROW],
		[&"firework_tower", 1, -1, "flitter", MapShots.Look.ROCKET],
		[&"firework_tower", 2, -1, "flitter", MapShots.Look.ROCKET],
		[&"firework_tower", 3, 0, "flitter", MapShots.Look.BLOOM],
		[&"firework_tower", 3, 1, "flitter", MapShots.Look.SKYROCKET],
	]
	for c: Array in cases:
		var label: String = "%s tier %d spec %d" % [c[0], c[1], c[2]]
		var before: int = _nodes()
		var b: Battle = Fx.arena([[Fx.group(c[3], 10, 200)]])
		assert_true(Fx.build(b, Vector2i(2, 4), c[0], c[1], c[2]), label)
		var v: MapView = _view(b)
		b.start_next_wave()
		var shots: MapShots = v.get("_shots") as MapShots
		var most_targets: int = 0
		var ticks: int = 0
		while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS:
			var events: Array[Dictionary] = Fx.tick(b)
			for e: Dictionary in events:
				if e["kind"] == &"fired":
					most_targets = maxi(most_targets, (e["targets"] as Array).size())
			v.sync(1.0)
			v.play_events(events)
			ticks += 1
		# The burst is made when its rocket lands, so let the last ones land.
		v.advance_effects(0.5)
		var look: int = c[4]
		assert_true(shots.launched[look] > 0, "%s: shots of look %d" % [label, look])
		var total: int = 0
		for n: int in shots.launched:
			total += n
		assert_eq(total, shots.launched[look], "%s: no other look was fired" % label)
		var bursts: int = shots.marked[MapShots.Fx.BURST]
		if look == MapShots.Look.ROCKET or look == MapShots.Look.BLOOM:
			assert_eq(bursts, shots.launched[look], "%s: a burst at every landing" % label)
		else:
			assert_eq(bursts, 0, "%s: no burst" % label)
		if c[2] == 1 and c[0] == &"longbow_loft":
			assert_eq(most_targets, 3, "%s: three arrows at three targets" % label)
			assert_true(shots.launched[look] >= 3)
		elif c[0] == &"longbow_loft":
			assert_eq(most_targets, 1, "%s: one arrow" % label)
		v.advance_effects(3.0)
		v.sync(0.0)
		_assert_clean(v, label, 10)
		v.get_parent().remove_child(v)
		v.free()
		_views.clear()
		assert_eq(_nodes(), before, "%s: no node leaked" % label)


func test_muzzles_rise_with_the_tier_and_the_triple_bow_has_three() -> void:
	var cell: Vector2i = Vector2i(2, 4)
	for tower: StringName in [&"longbow_loft", &"firework_tower"]:
		var y1: float = MapShots.muzzle(tower, cell, 1).y
		var y3: float = MapShots.muzzle(tower, cell, 3).y
		assert_true(y3 < y1, "%s: a tier 3 tower shoots from higher up" % tower)
	var left: Vector2 = MapShots.muzzle(&"longbow_loft", cell, 3, 1, 0)
	var mid: Vector2 = MapShots.muzzle(&"longbow_loft", cell, 3, 1, 1)
	var right: Vector2 = MapShots.muzzle(&"longbow_loft", cell, 3, 1, 2)
	assert_true(left.x < mid.x and mid.x < right.x, "three bows side by side")
	assert_true(mid.y < left.y and mid.y < right.y, "the middle bow is higher")
	assert_eq(MapShots.muzzle(&"longbow_loft", cell, 3, 0, 1), MapShots.muzzle(&"longbow_loft", cell, 3, 0, 0), "a Giant Bow has one bow")


func test_a_burst_shows_the_towers_real_splash() -> void:
	var b: Battle = Fx.arena([[Fx.group("flitter", 6, 300)]])
	Fx.build(b, Vector2i(2, 4), &"firework_tower", 3, 0)
	var v: MapView = _view(b)
	var shots: MapShots = v.get("_shots") as MapShots
	b.start_next_wave()
	var radius: float = 0.0
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS and radius == 0.0:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
		for f: MapShots.Flash in shots.flashes:
			if f.kind == MapShots.Fx.BURST:
				radius = f.size
		ticks += 1
	var splash: int = b.towers[0].stats.splash
	assert_eq(splash, 125, "the Star Bloom's splash")
	assert_near(radius, 1.25 * MapView.CELL, 0.01, "the burst reaches the splash radius")


# Every creature and boss.

func test_every_creature_and_boss_plays_a_full_wave_with_no_leak() -> void:
	# The ids come from the data (docs/ARCHITECTURE.md 14.10), so a creature that E5.1 to E8.1 add
	# is played here the moment it is in data/stats/.
	var cat: Catalog = Fx.catalog()
	var ids: Array[StringName] = cat.enemy_ids()
	for id: StringName in ids:
		var before: int = _nodes()
		var boss: bool = cat.enemy(id).boss
		var groups: Array = [Fx.group(String(id), 1 if boss else 8, 500)]
		if id == &"mender":
			groups = [Fx.group("scamp", 6, 300, 0), Fx.group("mender", 2, 500, 0)]
		var b: Battle = Fx.arena([groups], 50 if boss else 100)
		var gatecrasher: bool = id == &"gatecrasher" or id == &"old_tusk"
		if gatecrasher:
			assert_eq(b.place_gate(Fx.ARENA_SOCKETS[0]), Battle.DONE)
		if id == &"gatecrasher":
			Fx.build(b, Vector2i(4, 9), &"sling_post", 1)
		else:
			Fx.build(b, Vector2i(2, 4), &"sling_post", 3, 1)
			Fx.build(b, Vector2i(4, 4), &"sling_post", 3, 0)
			Fx.build(b, Vector2i(2, 6), &"lullaby_bell", 2)
			Fx.build(b, Vector2i(1, 9), &"longbow_loft", 3, 0)
			Fx.build(b, Vector2i(4, 9), &"firework_tower", 2)
		var v: MapView = _view(b)
		b.start_next_wave()
		var seen: Dictionary = _play(b, v, String(id))
		_assert_clean(v, String(id), int(seen["peak"]))
		assert_true(int(seen.get("spawned", 0)) >= (1 if boss else 8), "%s: it came" % id)
		var needs: Dictionary = {
			&"puffball": &"released", &"mender": &"healed", &"bubbler": &"popped", &"ironshell": &"sped_up",
			&"grumblesack": &"released", &"moon_moth": &"released", &"gatecrasher": &"gate_broken",
			&"old_tusk": &"released",
		}
		if needs.has(id):
			var kind: StringName = needs[id]
			assert_true(int(seen.get(kind, 0)) > 0, "%s: the sim sent %s" % [id, kind])
			assert_true(int(v.handled.get(kind, 0)) > 0, "%s: the view handled %s" % [id, kind])
		if gatecrasher:
			assert_true(int(seen.get("break_started", 0)) > 0, "%s: it started breaking" % id)
			assert_true(bool(seen["cracked"]), "%s: the gate showed a crack" % id)
		assert_true(int(v.handled.get(&"defeated", 0)) > 0 or id == &"gatecrasher", "%s: something puffed" % id)
		v.get_parent().remove_child(v)
		v.free()
		_views.clear()
		assert_eq(_nodes(), before, "%s: no node leaked" % id)


func test_creatures_added_by_a_risk_card_get_their_pictures_before_the_wave() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 3, 500)]])
	var v: MapView = _view(b)
	var atlas: MapAtlas = v.get("_atlas") as MapAtlas
	assert_false(atlas.enemy_rects.has(&"puffball"), "the level has no Puffball")
	var card: Array[Dictionary] = [{"type": "add_group", "enemy": "puffball", "count": 2, "entrance": 1, "at_ms": 0, "every_ms": 500, "after_last": true}]
	assert_eq(b.add_effects(card, true), Battle.DONE)
	var bakes: int = v.atlas_bakes()
	v.sync(0.0)
	assert_true(atlas.enemy_rects.has(&"puffball"), "the risk card's creature is on the sheet")
	assert_true(atlas.enemy_rects.has(&"puff"), "and what it splits into")
	assert_eq(v.atlas_bakes(), bakes + 1, "laid out once, in the build phase")
	b.start_next_wave()
	for i: int in 400:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
	assert_eq(v.atlas_bakes(), bakes + 1, "not again while the wave plays")


# Heals, gate breaks, releases, speed ups and the coin glint.

func _marks(v: MapView) -> PackedInt32Array:
	return (v.get("_shots") as MapShots).marked


func test_a_heal_draws_a_ring_and_plus_marks_for_the_creatures_that_gained() -> void:
	var b: Battle = Fx.arena([[Fx.group("mender", 1, 500), Fx.group("scamp", 3, 300)]])
	var v: MapView = _view(b)
	b.start_next_wave()
	for i: int in 60:
		v.sync(1.0)
		Fx.tick(b)
	v.sync(1.0)
	var mender: int = -1
	var hurt: Array[int] = []
	for e: EnemyState in b.enemies:
		if e.type == &"mender":
			mender = e.id
		else:
			hurt.append(e.id)
	assert_true(mender >= 0 and hurt.size() >= 2, "a Mender and scamps are on the map")
	var before: PackedInt32Array = _marks(v).duplicate()
	v.play_events([{"kind": &"healed", "id": mender, "ids": hurt}])
	var after: PackedInt32Array = _marks(v).duplicate()
	assert_eq(after[MapShots.Fx.PULSE], before[MapShots.Fx.PULSE] + 1, "one ring")
	assert_eq(after[MapShots.Fx.PLUS], before[MapShots.Fx.PLUS] + hurt.size(), "a plus for each creature")
	# A heal of a big crowd stays calm.
	var crowd: Array[int] = []
	for i: int in 40:
		crowd.append(hurt[0])
	v.play_events([{"kind": &"healed", "id": mender, "ids": crowd}])
	assert_eq(_marks(v)[MapShots.Fx.PLUS], after[MapShots.Fx.PLUS] + MapView.HEAL_MARKS, "at most %d plus marks a heal" % MapView.HEAL_MARKS)
	# A ring around a creature that is gone is skipped, not an error.
	v.play_events([{"kind": &"healed", "id": 99999, "ids": [88888]}])


func test_a_breaker_shakes_and_cracks_its_gate_then_the_gate_breaks() -> void:
	var b: Battle = Fx.arena([[Fx.group("gatecrasher", 1, 500)]])
	assert_eq(b.place_gate(Fx.ARENA_SOCKETS[0]), Battle.DONE)
	var v: MapView = _view(b)
	var gates: MapGates = v.get("_gates") as MapGates
	b.start_next_wave()
	var last_progress: float = -1.0
	var rising: int = 0
	var broke: bool = false
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS and not broke:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
		for e: Dictionary in events:
			broke = broke or e["kind"] == &"gate_broken"
		if not gates.cracking.is_empty():
			assert_eq(gates.cracking[0], Fx.ARENA_SOCKETS[0], "the crack is on the gate being broken")
			var p: float = gates.crack_progress[0]
			assert_true(p >= last_progress and p >= 0.0 and p <= 1.0, "progress only grows: %f after %f" % [p, last_progress])
			if p > last_progress:
				rising += 1
			last_progress = p
		ticks += 1
	assert_true(rising >= 5, "the crack grew over time (%d steps)" % rising)
	assert_true(last_progress > 0.8, "and nearly finished: %f" % last_progress)
	assert_true(broke, "the gate broke")
	v.sync(1.0)
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[0])], MapArt.Gate.BROKEN, "the broken look")
	assert_true(gates.cracking.is_empty(), "no crack on a broken gate")
	assert_true(int(v.handled.get(&"break_started", 0)) == 1 and int(v.handled.get(&"gate_broken", 0)) == 1)


func test_a_broken_gate_marks_are_splinters_and_a_ring() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 1, 500)]])
	var v: MapView = _view(b)
	var pulses: int = _marks(v)[MapShots.Fx.PULSE]
	var bursts: int = v.sparkles().bursts
	v.play_events([{"kind": &"gate_broken", "cell": Fx.ARENA_SOCKETS[0]}])
	assert_eq(_marks(v)[MapShots.Fx.PULSE], pulses + 1)
	assert_eq(v.sparkles().bursts, bursts + 2, "dust and splinters")
	v.play_events([{"kind": &"break_started", "id": 1, "cell": Fx.ARENA_SOCKETS[0]}])
	assert_eq(_marks(v)[MapShots.Fx.PULSE], pulses + 2)


func test_a_release_and_a_speed_up_have_a_picture_each() -> void:
	var b: Battle = Fx.arena([[Fx.group("ironshell", 1, 500)]], 50)
	Fx.build(b, Vector2i(2, 4), &"sling_post", 3, 0)
	var v: MapView = _view(b)
	b.start_next_wave()
	for i: int in 40:
		Fx.tick(b)
	v.sync(1.0)
	var boss: int = b.enemies[0].id
	var marks: PackedInt32Array = _marks(v).duplicate()
	var bursts: int = v.sparkles().bursts
	v.play_events([{"kind": &"sped_up", "id": boss, "speed": 50}])
	assert_eq(_marks(v)[MapShots.Fx.WHOOSH], marks[MapShots.Fx.WHOOSH] + 1, "speed lines")
	assert_eq(v.sparkles().bursts, bursts + 1, "and a kick of dust")
	v.play_events([{"kind": &"released", "id": 5, "source": &"puffball", "enemy": &"puff", "count": 3, "pos": Vector2i(30000, 30000)}])
	assert_eq(_marks(v)[MapShots.Fx.PULSE], marks[MapShots.Fx.PULSE] + 1, "a ring where the Puffs come out")
	assert_eq(v.sparkles().bursts, bursts + 2)
	var small: float = 0.0
	var big: float = 0.0
	var shots: MapShots = v.get("_shots") as MapShots
	for f: MapShots.Flash in shots.flashes:
		if f.kind == MapShots.Fx.PULSE:
			small = f.size
	v.play_events([{"kind": &"released", "id": boss, "source": &"moon_moth", "enemy": &"flitter", "count": 3, "pos": Vector2i(40000, 40000)}])
	for f: MapShots.Flash in shots.flashes:
		if f.kind == MapShots.Fx.PULSE:
			big = f.size
	assert_true(big > small, "a boss's release is a bigger ring")
	# Events about a creature that is gone are skipped.
	v.play_events([{"kind": &"sped_up", "id": 424242, "speed": 50}])


func test_the_coin_glint_is_small_and_only_for_gold() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 1, 500)]])
	var v: MapView = _view(b)
	var coins: int = _marks(v)[MapShots.Fx.COIN]
	v.play_events([{"kind": &"defeated", "id": 1, "enemy": &"scamp", "pos": Vector2i(30000, 30000), "gold": 5}])
	assert_eq(_marks(v)[MapShots.Fx.COIN], coins + 1, "a coin where a creature pops")
	v.play_events([{"kind": &"defeated", "id": 2, "enemy": &"scamp", "pos": Vector2i(30000, 30000), "gold": 0}])
	assert_eq(_marks(v)[MapShots.Fx.COIN], coins + 1, "none without gold")
	v.play_events([{"kind": &"wave_cleared", "wave": 0, "gold": 0}])
	assert_eq(_marks(v)[MapShots.Fx.COIN], coins + 1, "none for a clear with no bonus")
	v.play_events([{"kind": &"wave_cleared", "wave": 0, "gold": 35}])
	assert_eq(_marks(v)[MapShots.Fx.COIN], coins + 4, "three coins at the home for a clear bonus")
	assert_true(MapShots.LIFE[MapShots.Fx.COIN] <= 0.6, "it is over in about half a second")
	v.advance_effects(2.0)
	assert_false(v.is_effect_busy())
	# Many at once stay inside the cap.
	var events: Array[Dictionary] = []
	for i: int in 300:
		events.append({"kind": &"defeated", "id": 100 + i, "enemy": &"scamp", "pos": Vector2i(30000, 30000), "gold": 5})
	v.play_events(events)
	assert_true((v.get("_shots") as MapShots).flashes.size() <= MapShots.MAX_FLASHES)


# Gate looks.

func test_gate_look_order_is_broken_then_open_then_fixed_then_closed() -> void:
	var g: GateState = GateState.new()
	for broken: bool in [false, true]:
		for fixed: bool in [false, true]:
			for open: bool in [false, true]:
				g.broken = broken
				g.fixed = fixed
				var want: int = MapArt.Gate.CLOSED
				if broken:
					want = MapArt.Gate.BROKEN
				elif open:
					want = MapArt.Gate.OPEN
				elif fixed:
					want = MapArt.Gate.FIXED
				assert_eq(MapView.gate_look(g, open), want, "broken %s, fixed %s, open %s" % [broken, fixed, open])


func test_a_locked_gate_under_gates_open_looks_open() -> void:
	var effects: Array = [{"type": "fixed_gates", "cells": [[1, 5]]}]
	var b: Battle = Fx.arena([[Fx.group("scamp", 2, 500)]], 100, 2, effects)
	assert_not_null(b)
	assert_true(b.gates[0].fixed)
	assert_eq(b.place_gate(Fx.ARENA_SOCKETS[3]), Battle.DONE)
	var v: MapView = _view(b)
	var gates: MapGates = v.get("_gates") as MapGates
	v.sync(0.0)
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[0])], MapArt.Gate.FIXED, "a locked gate")
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[3])], MapArt.Gate.CLOSED, "a placed gate")
	var card: Array[Dictionary] = [{"type": "gates_open"}]
	assert_eq(b.add_effects(card, true), Battle.DONE)
	b.start_next_wave()
	assert_true(b.gates_open)
	v.sync(1.0)
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[0])], MapArt.Gate.OPEN, "a locked gate under gates_open is OPEN")
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[3])], MapArt.Gate.OPEN, "and so is a placed one")


func test_a_broken_locked_gate_looks_broken_even_under_the_old_fixed_first_order() -> void:
	var effects: Array = [{"type": "fixed_gates", "cells": [[1, 5]]}]
	var b: Battle = Fx.arena([[Fx.group("gatecrasher", 1, 500)], [Fx.group("scamp", 1, 500)]], 100, 1, effects)
	var v: MapView = _view(b)
	var gates: MapGates = v.get("_gates") as MapGates
	b.start_next_wave()
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS and not b.gates[0].broken:
		v.sync(1.0)
		v.play_events(Fx.tick(b))
		ticks += 1
	assert_true(b.gates[0].broken and b.gates[0].fixed, "a locked gate broke")
	v.sync(1.0)
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[0])], MapArt.Gate.BROKEN)
	# It mends, closed and still locked, when the next build phase begins.
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < GUARD_TICKS:
		v.sync(1.0)
		v.play_events(Fx.tick(b))
		guard += 1
	v.advance_effects(3.0)
	v.sync(0.0)
	assert_false(b.gates[0].broken)
	assert_eq(gates.looks[gates.cells.find(Fx.ARENA_SOCKETS[0])], MapArt.Gate.FIXED, "mended, still locked")


func test_the_atlas_has_every_gate_look_on_both_road_directions() -> void:
	var atlas: MapAtlas = MapAtlas.new()
	atlas.add_gates()
	atlas.bake(1.0)
	assert_eq(MapArt.Gate.size(), 6, "six looks")
	for look: int in MapArt.Gate.size():
		for across: bool in [false, true]:
			var e: MapAtlas.Entry = atlas.entry_for(MapAtlas.gate_key(look, across))
			assert_not_null(e, "look %d, across %s" % [look, across])
			if e != null:
				assert_true(e.rect.size.x > 0.0 and e.rect.end.x <= float(MapAtlas.WIDTH), "look %d is on the sheet" % look)
	assert_eq(atlas.entries.size(), MapArt.Gate.size() * 2)
	# The same through a view, so the OPEN look reaches the sheet the map draws from.
	var v: MapView = _view(Fx.arena([[Fx.group("scamp", 1, 500)]]))
	var sheet: MapAtlas = v.get("_atlas") as MapAtlas
	assert_not_null(sheet.entry_for(MapAtlas.gate_key(MapArt.Gate.OPEN, true)))
	assert_not_null(sheet.entry_for(MapAtlas.gate_key(MapArt.Gate.OPEN, false)))
	atlas.free()


# Marks on towers and creatures.

func test_boost_marks_read_the_towers_own_fields() -> void:
	var b: Battle = Fx.arena([[Fx.group("scamp", 1, 500)]])
	Fx.build(b, Vector2i(4, 1), &"sling_post", 1)
	Fx.build(b, Vector2i(4, 2), &"bakery", 1)
	Fx.build(b, Vector2i(1, 9), &"sling_post", 1)
	var v: MapView = _view(b)
	var status: MapStatus = v.get("_status") as MapStatus
	v.sync(0.0)
	assert_eq(status.boosted.size(), 1, "one tower is boosted, by the Bakery next to it")
	var boosted: TowerState = b.tower_at(Vector2i(4, 1))
	assert_true(boosted.got_pct > 0)
	assert_eq(status.boosted[0], (Vector2(4.5, 1.5)) * MapView.CELL)
	assert_eq(b.sell_tower(Vector2i(4, 2)), Battle.DONE)
	v.sync(0.0)
	assert_eq(status.boosted.size(), 0, "the mark goes with the Bakery, on the next frame")
	# A Bakery that a card added after the level began still gets its picture.
	var card: Array[Dictionary] = [{"type": "add_tower", "tower": "bakery"}]
	assert_eq(b.add_effects(card, false), Battle.DONE)
	v.sync(0.0)
	assert_not_null((v.get("_atlas") as MapAtlas).entry_for(MapAtlas.tower_key(&"bakery", 3, 1)))


func test_drowsy_and_bubble_marks_follow_the_creatures() -> void:
	var b: Battle = Fx.arena([[Fx.group("bubbler", 6, 300)]])
	Fx.build(b, Vector2i(2, 4), &"lullaby_bell", 2)
	Fx.build(b, Vector2i(4, 4), &"sling_post", 3, 0)
	var v: MapView = _view(b)
	var status: MapStatus = v.get("_status") as MapStatus
	b.start_next_wave()
	var drowsy: bool = false
	var bubble: bool = false
	var popped_ring: bool = false
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
		for it: MapStatus.Item in status.items:
			drowsy = drowsy or it.drowsy
			bubble = bubble or it.bubble
		popped_ring = popped_ring or _marks(v)[MapShots.Fx.RING] > 0
		ticks += 1
	assert_true(drowsy, "a slowed creature showed the drowsy mark")
	assert_true(bubble, "a creature with its bubble up showed the bubble")
	assert_true(popped_ring, "a popped bubble rang")
