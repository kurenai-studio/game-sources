# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## MapView on the expansion's cast (docs/ARCHITECTURE.md 14.10, build step V4): the four new towers
## and their paths, the eight new creatures and four bosses, the three new shots (one drawn shot per
## pulse or line, one beam per lured flyer), a mark for every status, the nap pose, the dig mound,
## low flyers, growth, blinks and hops that snap, dozing towers, and the atlas budget. Played on
## the sim's expansion catalog (tests/sim/fixtures/creature_fixtures.gd) because data/stats/ has
## none of the new content until E5.1. Every view is freed at the end with the node count back
## where it started.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const GUARD_TICKS: int = 30000
## The Fold5's inner screen asks for this sharpness (a cell about 160 px): everything must fit.
const INNER_SCALE: float = 1.25

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
	(Engine.get_main_loop() as SceneTree).root.add_child(v)
	v.setup(b)
	_views.append(v)
	return v


func _nodes() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


func _creature(v: MapView, id: int) -> MapView.CreatureView:
	return (v.get("_creatures") as Dictionary)[id] as MapView.CreatureView


func _status(v: MapView) -> MapStatus:
	return v.get("_status") as MapStatus


func _shots(v: MapView) -> MapShots:
	return v.get("_shots") as MapShots


func _bit(mark: StringName) -> int:
	return 1 << Silhouettes.MARKS.find(mark)


## Steps until `count` creatures stand on the map (or the guard), drawing every tick.
func _until(b: Battle, v: MapView, count: int) -> void:
	var guard: int = 0
	while b.enemies.size() < count and guard < 4000:
		v.play_events(Fx.tick(b))
		v.sync(1.0)
		guard += 1


## Plays the running wave to its end, drawing every tick. Returns the events seen, by kind, and
## checks one node per live creature on every frame.
func _play(b: Battle, v: MapView, label: String) -> Dictionary:
	var seen: Dictionary = {}
	var ticks: int = 0
	while b.phase == Battle.Phase.WAVE and ticks < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		for e: Dictionary in events:
			seen[e["kind"]] = int(seen.get(e["kind"], 0)) + 1
		v.sync(1.0)
		v.play_events(events)
		if v.creature_count() != b.enemies.size():
			fail("%s tick %d: %d nodes for %d creatures" % [label, b.tick, v.creature_count(), b.enemies.size()])
			break
		ticks += 1
	assert_true(ticks < GUARD_TICKS, "%s: the wave ended" % label)
	v.advance_effects(3.0)
	v.sync(0.0)
	return seen


func _defend(b: Battle) -> void:
	Fx.build(b, Vector2i(2, 4), &"sling_post", 3, 1)
	Fx.build(b, Vector2i(4, 4), &"sling_post", 3, 0)
	Fx.build(b, Vector2i(2, 6), &"bramble_cottage", 3, 0)
	Fx.build(b, Vector2i(1, 9), &"longbow_loft", 3, 0)
	Fx.build(b, Vector2i(4, 9), &"snow_fort", 2)
	Fx.build(b, Vector2i(4, 6), &"scarecrow", 2)
	Fx.build(b, Vector2i(4, 2), &"moth_lantern", 2)


func _assert_clean(v: MapView, label: String) -> void:
	assert_eq(v.creature_count(), 0, "%s: no creature node left" % label)
	assert_eq(v.ghost_count(), 0, "%s: no ghost left" % label)
	assert_false(v.is_effect_busy(), "%s: no effect left" % label)
	var pool: Array = v.get("_pool")
	assert_eq(pool.size(), v.sprite_count() - v.tower_count(), "%s: every creature sprite is back in the pool" % label)
	for sp: Variant in pool:
		assert_false((sp as Sprite2D).visible, "%s: a pooled sprite is hidden" % label)


# The fixtures themselves.

func test_the_fixture_catalog_holds_the_whole_new_cast() -> void:
	var cat: Catalog = Fx.Cx.catalog()
	for id: String in Fx.EXPANSION_TOWER_IDS:
		assert_true(cat.has_tower(StringName(id)), "tower %s" % id)
		assert_true(Silhouettes.has_tower(StringName(id)), "drawn tower %s" % id)
	for id: String in Fx.EXPANSION_ENEMY_IDS + Fx.EXPANSION_BOSS_IDS:
		assert_true(cat.has_enemy(StringName(id)), "creature %s" % id)
		assert_true(Silhouettes.has_enemy(StringName(id)), "drawn creature %s" % id)
	for id: String in Fx.EXPANSION_BOSS_IDS:
		assert_true(cat.enemy(StringName(id)).boss, "%s is a boss in the data" % id)


# Every new creature and boss, and every look of every new tower.

func test_every_new_creature_and_boss_plays_a_full_wave_with_no_leak() -> void:
	var ids: Array = Fx.EXPANSION_ENEMY_IDS + Fx.EXPANSION_BOSS_IDS
	for id: String in ids:
		var before: int = _nodes()
		var boss: bool = Fx.EXPANSION_BOSS_IDS.has(id)
		var groups: Array = [Fx.group(id, 1 if boss else 6, 600)]
		var b: Battle = Fx.expansion([groups], 50 if boss else 100)
		_defend(b)
		var v: MapView = _view(b)
		b.start_next_wave()
		var seen: Dictionary = _play(b, v, id)
		_assert_clean(v, id)
		assert_true(int(seen.get("spawned", 0)) >= 1, "%s: it came" % id)
		var needs: Dictionary = {
			&"burrowbelly": &"burrowed", &"yawner": &"yawned", &"blinker": &"blinked",
			&"snowsnore": &"yawned", &"glimmertoad": &"blinked",
		}
		if needs.has(StringName(id)):
			var kind: StringName = needs[StringName(id)]
			assert_true(int(seen.get(kind, 0)) > 0, "%s: the sim sent %s" % [id, kind])
			assert_true(int(v.handled.get(kind, 0)) > 0, "%s: the view handled %s" % [id, kind])
		assert_true(int(v.handled.get(&"defeated", 0)) > 0, "%s: something puffed" % id)
		v.get_parent().remove_child(v)
		v.free()
		_views.clear()
		assert_eq(_nodes(), before, "%s: no node leaked" % id)


func test_every_look_of_the_new_towers_stands_and_fires_with_no_leak() -> void:
	var looks: Array = [[1, -1], [2, -1], [3, 0], [3, 1]]
	for id: String in Fx.EXPANSION_TOWER_IDS:
		for look: Array in looks:
			var label: String = "%s tier %d spec %d" % [id, look[0], look[1]]
			var before: int = _nodes()
			var enemy: String = "flitter" if id == "moth_lantern" else "scamp"
			var b: Battle = Fx.expansion([[Fx.group(enemy, 8, 300)]], 100)
			assert_true(Fx.build(b, Vector2i(2, 4), StringName(id), look[0], look[1]), label)
			var v: MapView = _view(b)
			assert_eq(v.tower_count(), 0)
			v.sync(0.0)
			assert_eq(v.tower_count(), 1, "%s: drawn" % label)
			var atlas: MapAtlas = v.get("_atlas") as MapAtlas
			assert_not_null(atlas.entry_for(MapAtlas.tower_key(StringName(id), look[0], look[1])), "%s: on the sheet" % label)
			b.start_next_wave()
			var fired: int = 0
			var guard: int = 0
			while b.phase == Battle.Phase.WAVE and guard < GUARD_TICKS:
				var events: Array[Dictionary] = Fx.tick(b)
				for e: Dictionary in events:
					if e["kind"] == &"fired":
						fired += 1
				v.sync(1.0)
				v.play_events(events)
				guard += 1
			v.advance_effects(3.0)
			v.sync(0.0)
			if id == "scarecrow":
				assert_eq(fired, 0, "%s never fires" % label)
			else:
				assert_true(fired > 0, "%s fired" % label)
			_assert_clean(v, label)
			v.get_parent().remove_child(v)
			v.free()
			_views.clear()
			assert_eq(_nodes(), before, "%s: no node leaked" % label)


# The three new shots.

func test_a_pulse_is_one_drawn_shot_with_a_mark_on_each_creature() -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 12, 200)]], 100)
	Fx.build(b, Vector2i(2, 4), &"bramble_cottage", 3, 0)
	var v: MapView = _view(b)
	var shots: MapShots = _shots(v)
	b.start_next_wave()
	var fired: int = 0
	var targets: int = 0
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		for e: Dictionary in events:
			if e["kind"] == &"fired":
				fired += 1
				targets += (e["targets"] as Array).size()
		v.sync(1.0)
		v.play_events(events)
		assert_true(shots.shots.size() <= MapShots.MAX_SHOTS)
		guard += 1
	assert_true(fired >= 3, "the cottage pulsed")
	assert_eq(shots.launched[MapShots.Look.THORNS], fired, "one drawn shot a pulse")
	var total: int = 0
	for n: int in shots.launched:
		total += n
	assert_eq(total, fired, "and no other shot")
	assert_true(targets > fired, "some pulses hit several creatures")
	assert_eq(shots.marked[MapShots.Fx.HIT], targets, "a hit mark on each creature it hit")


func test_a_pulse_ring_opens_to_the_towers_real_reach() -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 6, 300)]], 100)
	Fx.build(b, Vector2i(2, 4), &"bramble_cottage", 3, 0)
	var v: MapView = _view(b)
	var shots: MapShots = _shots(v)
	b.start_next_wave()
	var guard: int = 0
	while shots.shots.is_empty() and guard < GUARD_TICKS:
		v.play_events(Fx.tick(b))
		v.sync(1.0)
		guard += 1
	var shot: MapShots.Shot = shots.shots[0]
	assert_eq(shot.look, MapShots.Look.THORNS)
	assert_near(shot.radius, 2.0 * MapView.CELL, 0.01, "a Wild Bramble's ring is 2.0 tiles")
	assert_eq(shot.from, (Vector2(2.5, 4.5)) * MapView.CELL, "centered on the cottage")
	assert_eq(shot.target, -1, "it follows no creature")


func test_a_line_is_one_snowball_from_the_tower_along_to() -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 12, 200)]], 100)
	Fx.build(b, Vector2i(2, 4), &"snow_fort", 3, 0)
	var v: MapView = _view(b)
	var shots: MapShots = _shots(v)
	b.start_next_wave()
	var fired: int = 0
	var targets: int = 0
	var checked: bool = false
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		v.sync(1.0)
		v.play_events(events)
		for e: Dictionary in events:
			if e["kind"] != &"fired":
				continue
			fired += 1
			targets += (e["targets"] as Array).size()
			if not checked:
				var shot: MapShots.Shot = shots.shots[shots.shots.size() - 1]
				assert_eq(shot.look, MapShots.Look.BIG_SNOWBALL, "the Big Snowball path rolls the big one")
				assert_eq(shot.from, (Vector2(2.5, 4.5)) * MapView.CELL, "from the tower's center")
				assert_eq(shot.to, Vector2(e["to"] as Vector2i) * MapView.PX_PER_SUB, "to the end of the sim's line")
				assert_near(shot.radius, 0.5 * MapView.CELL, 0.01, "as wide as the line, 1.0 tile")
				checked = true
		guard += 1
	assert_true(checked and fired >= 2, "the fort fired")
	assert_eq(shots.launched[MapShots.Look.BIG_SNOWBALL], fired, "one drawn shot a line")
	assert_eq(shots.marked[MapShots.Fx.HIT], targets, "a hit mark on each creature on the line")


func test_a_lure_is_one_beam_for_each_flyer_it_hits() -> void:
	var b: Battle = Fx.expansion([[Fx.group("flitter", 8, 150)]], 100)
	Fx.build(b, Vector2i(2, 4), &"moth_lantern", 3, 1)
	var v: MapView = _view(b)
	var shots: MapShots = _shots(v)
	b.start_next_wave()
	var targets: int = 0
	var most: int = 0
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < GUARD_TICKS:
		var events: Array[Dictionary] = Fx.tick(b)
		for e: Dictionary in events:
			if e["kind"] == &"fired":
				targets += (e["targets"] as Array).size()
				most = maxi(most, (e["targets"] as Array).size())
		v.sync(1.0)
		v.play_events(events)
		guard += 1
	assert_true(targets > 0)
	assert_true(most >= 2, "the Garland lured several at once")
	assert_eq(shots.launched[MapShots.Look.BEAM], targets, "one beam a lured flyer")
	var muzzles: Array[Vector2] = []
	for i: int in 3:
		muzzles.append(MapShots.muzzle(&"moth_lantern", Vector2i(2, 4), 3, 1, i))
	assert_true(muzzles[0] != muzzles[1] and muzzles[1] != muzzles[2], "each beam leaves from its own lantern")


# Statuses.

## A battle with `type` on the map, stepped until it is there and drawn.
func _with(type: String, tower: Array = [], offered: Array = []) -> Array:
	var b: Battle = Fx.expansion([[Fx.group(type, 2, 700)]], 100, Fx.ARENA_GRID, 2, offered)
	if not tower.is_empty():
		Fx.build(b, tower[0], tower[1], tower[2])
	var v: MapView = _view(b)
	b.start_next_wave()
	_until(b, v, 1)
	for i: int in 10:
		v.play_events(Fx.tick(b))
		v.sync(1.0)
	return [b, v]


func test_a_napping_creature_lies_on_its_side_with_the_crescent() -> void:
	var made: Array = _with("sleepyhead")
	var b: Battle = made[0]
	var v: MapView = made[1]
	var e: EnemyState = b.enemies[0]
	var view: MapView.CreatureView = _creature(v, e.id)
	assert_eq(view.sprite.rotation, 0.0, "standing")
	var stood: Vector2 = view.sprite.position
	e.nap_ticks = 40
	e.napped = true
	v.sync(1.0)
	assert_near(absf(view.sprite.rotation), PI * 0.5, 0.0001, "on its side")
	assert_true((_status(v).items.has(view.item)) and view.item.marks & _bit(&"napping") != 0, "with the napping mark")
	assert_true(view.sprite.position != stood)
	assert_eq(view.frame, 0, "it does not walk in its sleep")
	e.nap_ticks = 0
	v.sync(1.0)
	assert_eq(view.sprite.rotation, 0.0, "up again when it wakes")
	assert_eq(view.item.marks & _bit(&"napping"), 0)


func test_a_creature_that_dug_under_is_its_dirt_mound() -> void:
	var made: Array = _with("burrowbelly")
	var b: Battle = made[0]
	var v: MapView = made[1]
	var e: EnemyState = b.enemies[0]
	var view: MapView.CreatureView = _creature(v, e.id)
	var atlas: MapAtlas = v.get("_atlas") as MapAtlas
	var normal: Rect2 = view.sprite.region_rect
	e.dig_ticks = 30
	v.sync(1.0)
	assert_eq(view.look, MapView.LOOK_DUG)
	var mounds: Array = atlas.mark_rects[&"dug"]
	assert_eq(mounds.size(), 4, "the only mark that moves has four frames")
	assert_true(mounds.has(view.sprite.region_rect), "the sprite is a frame of the mound")
	assert_false(view.sprite.region_rect == normal)
	assert_true(v.enemy_at(v.get_global_transform() * view.center) == e.id, "it is drawn, so it can be tapped")
	var seen: Dictionary = {}
	for i: int in 30:
		v.advance_effects(0.07)
		v.sync(1.0)
		seen[view.sprite.region_rect] = true
	assert_true(seen.size() >= 3, "the mound animates")
	e.dig_ticks = 0
	v.sync(1.0)
	assert_eq(view.look, MapView.LOOK_HIGH)
	assert_eq(view.sprite.region_rect.size, normal.size, "the creature comes back")


func test_a_lured_flyer_is_drawn_lower_with_its_ring() -> void:
	var made: Array = _with("flitter", [], ["sling_post"])
	var b: Battle = made[0]
	var v: MapView = made[1]
	assert_eq(v.get("_lures"), false, "no lantern here")
	# The lowered picture is made when a flyer first goes low even where no tower lures.
	var e: EnemyState = b.enemies[0]
	var view: MapView.CreatureView = _creature(v, e.id)
	var high: float = view.center.y
	var flight: float = view.item.ground_center.y
	e.low_ticks = 40
	v.sync(1.0)
	var atlas: MapAtlas = v.get("_atlas") as MapAtlas
	assert_true(atlas.low_rects.has(&"flitter"))
	assert_eq(view.look, MapView.LOOK_LOW)
	assert_near(view.center.y - high, MapAtlas.LOW_DROP * view.size_px, 0.01, "lower, just above its shadow")
	assert_near(view.item.ground_center.y, flight, 0.01, "the ring stays on the shadow line")
	assert_true(view.item.marks & _bit(&"low") != 0, "with the low ring")
	assert_true(_status(v).items.has(view.item))
	e.low_ticks = 0
	v.sync(1.0)
	assert_eq(view.look, MapView.LOOK_HIGH)
	assert_eq(view.item.marks & _bit(&"low"), 0)


func test_a_lantern_bakes_the_lowered_flyers_in_advance() -> void:
	var plain: Battle = Fx.expansion([[Fx.group("flitter", 2, 700), Fx.group("scamp", 1, 700)]], 100, Fx.ARENA_GRID, 2, ["sling_post", "bakery"])
	var v: MapView = _view(plain)
	assert_false((v.get("_atlas") as MapAtlas).low_rects.has(&"flitter"), "not without a lantern")
	assert_false(v.get("_lures"))
	var card: Array[Dictionary] = [{"type": "add_tower", "tower": "moth_lantern"}]
	assert_eq(plain.add_effects(card, false), Battle.DONE)
	v.sync(0.0)
	assert_true(v.get("_lures"), "a card that adds a lantern turns it on")
	var lit: Battle = Fx.expansion([[Fx.group("flitter", 2, 700)]], 100)
	assert_true(((_view(lit)).get("_atlas") as MapAtlas).low_rects.has(&"flitter"), "a level with a lantern bakes them")


func test_hidden_frightened_and_awake_creatures_wear_their_marks() -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 6, 300), Fx.group("mistwisp", 1, 1000, 100), Fx.group("hootling", 1, 1000, 200)]], 100)
	Fx.build(b, Vector2i(2, 4), &"scarecrow", 2)
	var v: MapView = _view(b)
	b.start_next_wave()
	var hidden: bool = false
	var afraid: bool = false
	var awake: bool = false
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 900:
		v.play_events(Fx.tick(b))
		v.sync(1.0)
		for e: EnemyState in b.enemies:
			var view: MapView.CreatureView = _creature(v, e.id)
			var marks: int = view.item.marks
			if e.hidden:
				assert_true(marks & _bit(&"hidden") != 0, "hidden creature %d wears the curl" % e.id)
				hidden = true
			else:
				assert_eq(marks & _bit(&"hidden"), 0)
			if e.fright_ticks > 0:
				assert_true(marks & _bit(&"fright") != 0)
				afraid = true
			if e.awake:
				assert_true(marks & _bit(&"awake") != 0)
				awake = true
		guard += 1
	assert_true(hidden and afraid and awake, "all three showed: %s %s %s" % [hidden, afraid, awake])


func test_a_dozing_tower_wears_the_doze_mark() -> void:
	var b: Battle = Fx.expansion([[Fx.group("scamp", 1, 700)]], 100)
	Fx.build(b, Vector2i(2, 4), &"sling_post", 1)
	Fx.build(b, Vector2i(4, 4), &"sling_post", 1)
	var v: MapView = _view(b)
	v.sync(0.0)
	assert_eq(_status(v).dozing.size(), 0)
	b.tower_at(Vector2i(2, 4)).doze_ticks = 20
	v.sync(0.0)
	assert_eq(_status(v).dozing.size(), 1, "one tower dozes")
	var center: Vector2 = (Vector2(2.5, 4.5)) * MapView.CELL
	assert_true(_status(v).dozing[0].distance_to(center) < 0.1 * MapView.CELL, "over that tower")
	b.tower_at(Vector2i(2, 4)).doze_ticks = 0
	v.sync(0.0)
	assert_eq(_status(v).dozing.size(), 0, "and it wakes")


# Growth.

func test_growth_scales_between_the_start_and_the_cap() -> void:
	assert_near(MapView.growth(40, 40, 300), 1.0, 0.0001, "no growth yet")
	assert_near(MapView.growth(40, 80, 300), 1.25, 0.0001, "halfway to the cap")
	assert_near(MapView.growth(40, 120, 300), 1.5, 0.0001, "1.5 times at the cap")
	assert_near(MapView.growth(40, 500, 300), 1.5, 0.0001, "never above it")
	assert_near(MapView.growth(3400, 4250, 150), 1.25, 0.0001, "Snowsnore halfway")
	assert_near(MapView.growth(3400, 5100, 150), 1.5, 0.0001, "Snowsnore at its cap")


func test_growth_guards_a_cap_that_equals_the_start() -> void:
	# 40 * 101 / 100 truncates to 40: nothing to grow to, and nothing to divide by.
	assert_near(MapView.growth(40, 40, 101), 1.0, 0.0001)
	assert_near(MapView.growth(1, 1, 150), 1.0, 0.0001)
	assert_near(MapView.growth(0, 0, 300), 1.0, 0.0001)


func test_a_grower_is_drawn_larger_as_it_grows_from_its_feet() -> void:
	var made: Array = _with("snowroller")
	var b: Battle = made[0]
	var v: MapView = made[1]
	var e: EnemyState = b.enemies[0]
	var view: MapView.CreatureView = _creature(v, e.id)
	var atlas: MapAtlas = v.get("_atlas") as MapAtlas
	e.max_health = e.start_health
	e.health = e.max_health
	v.sync(1.0)
	var small: float = view.sprite.scale.x
	var feet: Vector2 = view.sprite.position
	e.max_health = e.start_health * 3
	v.sync(1.0)
	assert_near(view.sprite.scale.x / small, 1.5, 0.0001, "1.5 times at its cap")
	assert_eq(view.sprite.position, feet, "it grows from its feet")
	assert_near(view.item.size, view.size_px * 1.5, 0.01, "and so do its bar and marks")
	assert_near(view.sprite.scale.x * atlas.texel_scale, 1.5, 0.0001)


# Blinks and hops.

func test_a_blink_snaps_to_the_landing_with_no_streak() -> void:
	var b: Battle = Fx.expansion([[Fx.group("blinker", 1, 700)]], 100, Fx.GALLERY_GRID, 0)
	var v: MapView = _view(b)
	b.start_next_wave()
	var blinked: bool = false
	var guard: int = 0
	while not blinked and guard < 600:
		var events: Array[Dictionary] = Fx.tick(b)
		var bursts: int = v.sparkles().bursts
		v.sync(1.0)
		v.play_events(events)
		for e: Dictionary in events:
			if e["kind"] != &"blinked":
				continue
			blinked = true
			assert_eq(v.sparkles().bursts, bursts + 2, "sparkles where it was and where it landed")
			var en: EnemyState = b.enemies[0]
			var landed: Vector2 = Vector2(en.prev_pos) * MapView.PX_PER_SUB
			var at_start: Vector2 = v.creature_center(en.id)
			assert_true(at_start.distance_to(landed) < MapView.CELL * 0.6, "drawn at the landing, not between")
			v.sync(0.5)
			var mid: Vector2 = v.creature_center(en.id)
			assert_true(mid.distance_to(landed) < MapView.CELL * 0.6, "and half a tick later still beside it")
			var before: Vector2 = Vector2(e["from"] as Vector2i) * MapView.PX_PER_SUB
			assert_true(before.distance_to(landed) > MapView.CELL * 1.2, "the hop was long")
		guard += 1
	assert_true(blinked, "it blinked")


# The atlas budget.

func _everything(atlas: MapAtlas) -> void:
	for t: StringName in Silhouettes.TOWERS:
		atlas.add_tower_looks(t)
	var ids: Array[StringName] = []
	ids.append_array(Silhouettes.CREATURES)
	ids.append_array(Silhouettes.BOSSES)
	for id: StringName in ids:
		atlas.add_enemy(id, Silhouettes.is_flyer(id))
	atlas.add_marks()
	atlas.add_status_marks()
	atlas.add_shot_pieces()
	atlas.add_gates()
	atlas.add_route_pieces()


func test_every_look_and_creature_fits_the_sheet_at_the_inner_screens_sharpness() -> void:
	var atlas: MapAtlas = MapAtlas.new()
	_everything(atlas)
	assert_true(atlas.height_at(INNER_SCALE) <= MapAtlas.MAX_HEIGHT, "all 40 looks, 27 creatures and every mark: %d rows" % atlas.height_at(INNER_SCALE))
	atlas.bake(INNER_SCALE)
	assert_eq(atlas.texel_scale, INNER_SCALE, "no lowering needed")
	assert_eq(atlas.size.x, MapAtlas.WIDTH)
	assert_true(atlas.size.y <= MapAtlas.MAX_HEIGHT)
	for e: MapAtlas.Entry in atlas.entries:
		assert_true(e.rect.end.x <= float(MapAtlas.WIDTH) and e.rect.end.y <= float(atlas.size.y), "%s is on the sheet" % e.key)
	atlas.free()


func test_the_sheet_lowers_its_sharpness_in_steps_until_it_fits() -> void:
	var atlas: MapAtlas = MapAtlas.new()
	_everything(atlas)
	assert_true(atlas.height_at(2.0) > MapAtlas.MAX_HEIGHT, "everything at 2.0 would be too tall: %d" % atlas.height_at(2.0))
	atlas.bake(2.0)
	assert_true(atlas.texel_scale < 2.0, "so it is lowered: %.2f" % atlas.texel_scale)
	assert_true(atlas.size.y <= MapAtlas.MAX_HEIGHT, "to a sheet of at most %d rows: %d" % [MapAtlas.MAX_HEIGHT, atlas.size.y])
	var steps: float = (2.0 - atlas.texel_scale) / MapAtlas.SCALE_STEP
	assert_near(steps, roundf(steps), 0.0001, "in whole steps of 0.25")
	assert_true(atlas.height_at(atlas.texel_scale + MapAtlas.SCALE_STEP) > MapAtlas.MAX_HEIGHT, "the highest scale that fits")
	atlas.bake(8.0)
	assert_true(atlas.size.y <= MapAtlas.MAX_HEIGHT, "any asked scale ends on a sheet that fits")
	atlas.free()
	var small: MapAtlas = MapAtlas.new()
	small.add_tower_looks(&"snow_fort")
	small.bake(2.0)
	assert_eq(small.texel_scale, 2.0, "a small sheet is baked as asked")
	small.free()


func test_every_status_mark_is_on_the_sheet_and_dug_has_four_frames() -> void:
	var atlas: MapAtlas = MapAtlas.new()
	atlas.add_status_marks()
	atlas.bake(1.0)
	var count: int = 0
	for mark: StringName in Silhouettes.MARKS:
		var frames: int = 4 if mark == &"dug" else 1
		count += frames
		var rects: Array = atlas.mark_rects[mark]
		assert_eq(rects.size(), frames, "%s frames" % mark)
		for f: int in frames:
			assert_not_null(atlas.entry_for(MapAtlas.mark_key(mark, f)))
			assert_true((rects[f] as Rect2).size.x > 0.0)
	assert_eq(atlas.entries.size(), count, "one entry a frame, from the list of marks")
	atlas.free()


func test_the_new_cast_keeps_the_draw_call_budget_in_a_crowd() -> void:
	# No renderer here: this only checks that a crowd with every status draws from few nodes.
	var groups: Array = []
	for id: String in Fx.EXPANSION_ENEMY_IDS:
		groups.append(Fx.group(id, 8, 150))
	var b: Battle = Fx.expansion([groups], 100)
	_defend(b)
	var v: MapView = _view(b)
	b.start_next_wave()
	var peak: int = 0
	for i: int in 300:
		v.play_events(Fx.tick(b))
		v.sync(1.0)
		peak = maxi(peak, b.enemies.size())
	assert_true(peak >= 40, "a crowd: %d" % peak)
	assert_true(v.sprite_count() <= v.tower_count() + peak + 4, "one sprite a creature")
	assert_eq(_status(v).get_child_count(), 0, "marks are quads, not nodes")
