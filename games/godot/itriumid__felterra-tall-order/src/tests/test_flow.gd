extends TestCase
## The run's place in the game: its numbers go into the records, the best are kept, and with no
## cat in the clearing (behind the title) the horde and the giants wander.

const TEST_PATH := "user://test_records.cfg"


func test_a_better_run_sets_new_bests_and_a_worse_one_doesnt() -> void:
	var records := Records.new()
	var first := records.record({"time": 120.0, "level": 8, "kills": 300, "giants": 1})
	check(first.size() == 4, "a first run beat %d of 4 bests" % first.size())
	var worse := records.record({"time": 60.0, "level": 5, "kills": 100, "giants": 0})
	check(worse.is_empty(), "a worse run beat %s" % str(worse))
	var some := records.record({"time": 200.0, "level": 7, "kills": 350, "giants": 1})
	var expected: Array[String] = ["time", "kills"]
	check(some == expected, "the better parts of a mixed run were %s" % str(some))
	check(records.best.level == 8, "a lower level replaced the best")


func test_records_come_back_from_the_file() -> void:
	var records := Records.new()
	records.record({"time": 95.5, "level": 6, "kills": 210, "giants": 2})
	check(records.save(TEST_PATH), "couldn't save")
	var loaded := Records.new()
	loaded.load_from(TEST_PATH)
	check(is_equal_approx(loaded.best.time, 95.5) and loaded.best.giants == 2, "records came back as %s" % str(loaded.best))
	DirAccess.remove_absolute(TEST_PATH)


func test_a_run_counts_the_giants_it_fells() -> void:
	var arena := Arena.new()
	arena.spawning = false
	arena.add_cat(Arena.SIZE / 2.0)
	var giant := arena.add_giant(Arena.SIZE / 2.0 + Vector2(3.0, 0.0))
	arena.strike(giant, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round")
	check(Records.of(arena).giants == 1, "a felled giant wasn't counted")


func test_a_run_counts_the_machines_it_breaks() -> void:
	var arena := Arena.new()
	arena.spawning = false
	arena.add_cat(Arena.SIZE / 2.0)
	var machine := arena.add_machine(Arena.SIZE / 2.0 + Vector2(5.0, 0.0))
	arena.strike(machine, Machine.HEALTH / Machine.ARMOR_SHARE + 1.0, Vector2.RIGHT, 0.0, 0.0, "round")
	check(Records.of(arena).machines == 1, "a broken machine wasn't counted")


func test_records_from_before_machines_still_load() -> void:
	var path := "user://test_old_records.cfg"
	var old := ConfigFile.new()
	for key in ["time", "level", "kills", "giants"]:
		old.set_value("best", key, 7 if key != "time" else 70.0)
	old.save(path)
	var records := Records.new()
	records.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(records.best.giants == 7 and records.best.machines == 0, "old records came back as %s" % str(records.best))
	check(records.record({"time": 10.0, "level": 1, "kills": 1, "giants": 0, "machines": 1}) == ["machines"], "a first machine broken wasn't a new best")


func test_with_no_cat_the_horde_and_giants_wander() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var rat := arena.add_creature(Arena.SIZE / 2.0)
	var giant := arena.add_giant(Arena.SIZE / 2.0 + Vector2(5.0, 0.0))
	var rat_start := rat.body.position
	var giant_start := giant.body.position
	for step in 60 * 5:
		arena.step()
	check(rat.body.position.distance_to(rat_start) > 0.5, "the rat stood still with no cat to chase")
	check(giant.body.position.distance_to(giant_start) > 1.0, "the giant stood still with no cat to chase")
