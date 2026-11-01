# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Dozes end when a build phase begins (DM, 2026-10-27): a tower dozing when the last wave
## on the map clears is awake for the build phase, a save made in the build phase holds no
## doze, and a build phase save that holds one is refused. A wave that clears while
## another still runs begins no build phase, so its dozes go on.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

## The straight road of test_battle_late_creatures.gd.
const STRAIGHT: Array = [
	"...1...",
	".o.#.o.",
	"..o#o..",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...#...",
	"...B...",
]
const SLING: Vector2i = Vector2i(2, 2)
const BELL: Vector2i = Vector2i(4, 2)

var catalog: Catalog = null


## A Yawner that yawns every 100 ms with a 60 s doze and cannot fall, so the Sling Post
## beside the road dozes from the Yawner's first steps until long after it reaches the base.
func before_each() -> void:
	catalog = Cx.catalog_with("yawner", {"yawn_ms": 100, "doze_ms": 60000, "health": 100000})


func _battle(waves: Array) -> Battle:
	var b: Battle = Cx.battle(STRAIGHT, waves, {}, catalog)
	assert_not_null(Tx.build(b, SLING, &"sling_post"))
	assert_not_null(Tx.build(b, BELL, &"lullaby_bell"))
	return b


## Steps until the Sling Post dozes. Returns false when it never does.
func _until_dozing(b: Battle) -> bool:
	while b.phase == Battle.Phase.WAVE and b.tick < 400:
		b.step()
		if b.tower_at(SLING).doze_ticks > 0:
			return true
	return false


func test_a_doze_ends_when_the_build_phase_begins() -> void:
	var b: Battle = _battle([{"groups": [Fx.group("yawner", 1)]}, {"groups": [Fx.group("scamp", 1)]}])
	b.start_next_wave()
	assert_true(_until_dozing(b), "the Yawner dozes the Sling Post")
	var before: int = 0
	var started: bool = false
	while b.phase == Battle.Phase.WAVE and b.tick < 4000:
		before = b.tower_at(SLING).doze_ticks
		b.step()
		started = not Fx.events_of(b.take_events(), &"build_started").is_empty()
	assert_eq(b.phase, Battle.Phase.BUILD, "the Yawner reached the base and the wave cleared")
	assert_true(started, "the build phase began in that tick")
	assert_true(before > 100, "it was still dozing, %d ticks left, as the wave cleared" % before)
	assert_eq(b.tower_at(SLING).doze_ticks, 0, "awake for the build phase")
	assert_eq(b.tower_numbers(SLING)["doze_ms"], 0)
	assert_false(b._dozes_on, "no doze pass while nothing dozes")
	# Awake in the next wave too: it fires at the Scamp.
	assert_eq(b.start_next_wave(), Battle.DONE)
	var fired: bool = false
	while b.phase == Battle.Phase.WAVE and b.tick < 6000 and not fired:
		b.step()
		for event: Dictionary in Fx.events_of(b.take_events(), &"fired"):
			fired = fired or event["cell"] == SLING
	assert_true(fired, "the Sling Post fires in the next wave")


func test_a_build_phase_save_holds_no_doze() -> void:
	var b: Battle = _battle([{"groups": [Fx.group("yawner", 1)]}, {"groups": [Fx.group("scamp", 1)]}])
	b.start_next_wave()
	assert_true(_until_dozing(b))
	Fx.run_wave(b)
	assert_eq(b.phase, Battle.Phase.BUILD)
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	for tower: Dictionary in data["towers"]:
		assert_eq(int(tower["doze_ticks"]), 0, "written as 0")
	var loaded: Battle = Battle.from_data(data, catalog)
	assert_not_null(loaded, "the build phase save loads")
	if loaded == null:
		return
	assert_eq(loaded.tower_at(SLING).doze_ticks, 0)
	assert_eq(JSON.parse_string(JSON.stringify(loaded.to_data())), data, "to_data after from_data is the same")
	# A tampered build phase save that holds a doze is refused, at any length.
	for ticks: int in [1, 31, 1200]:
		var tampered: Dictionary = data.duplicate(true)
		tampered["towers"][0]["doze_ticks"] = ticks
		assert_eq([int(tampered["towers"][0]["cell"][0]), int(tampered["towers"][0]["cell"][1])], [SLING.x, SLING.y])
		assert_null(Battle.from_data(tampered, catalog), "doze_ticks %d in a build phase" % ticks)
	var missing: Dictionary = data.duplicate(true)
	(missing["towers"][0] as Dictionary).erase("doze_ticks")
	assert_not_null(Battle.from_data(missing, catalog), "missing is 0, as from an older build")


func test_a_wave_that_clears_while_another_runs_keeps_its_dozes() -> void:
	# Wave 1 is called early and its Scamp comes 60 s in, so it still runs when wave 0 clears.
	var waves: Array = [{"groups": [Fx.group("yawner", 1)]}, {"groups": [Fx.group("scamp", 1, 60000)]}, {"groups": [Fx.group("scamp", 1)]}]
	var b: Battle = _battle(waves)
	b.start_next_wave()
	assert_true(_until_dozing(b))
	assert_eq(b.start_next_wave(), Battle.DONE, "an early call")
	var cleared: bool = false
	while b.phase == Battle.Phase.WAVE and b.tick < 4000 and not cleared:
		b.step()
		for event: Dictionary in Fx.events_of(b.take_events(), &"wave_cleared"):
			cleared = cleared or event["wave"] == 0
	assert_true(cleared, "wave 0 cleared")
	assert_eq(b.phase, Battle.Phase.WAVE, "wave 1 still runs")
	assert_true(b.tower_at(SLING).doze_ticks > 100, "no build phase, so the doze goes on: %d ticks left" % b.tower_at(SLING).doze_ticks)
	# A mid-wave save keeps the doze, as before.
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	assert_true(int(data["towers"][0]["doze_ticks"]) > 100)
	assert_not_null(Battle.from_data(data, catalog))


func test_restore_while_dozing_reaches_the_same_build_phase() -> void:
	var b: Battle = _battle([{"groups": [Fx.group("yawner", 1)]}, {"groups": [Fx.group("scamp", 1)]}])
	b.start_next_wave()
	assert_true(_until_dozing(b))
	Fx.steps(b, 20)
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy)
	if copy == null:
		return
	assert_eq(copy.tower_at(SLING).doze_ticks, b.tower_at(SLING).doze_ticks)
	b.take_events()
	Fx.run_wave(b)
	Fx.run_wave(copy)
	assert_eq(b.phase, Battle.Phase.BUILD)
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b), "the same build phase, dozes ended in both")
	assert_eq(copy.take_events(), b.take_events())
