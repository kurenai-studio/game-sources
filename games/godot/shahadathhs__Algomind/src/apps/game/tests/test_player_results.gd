extends GutTest
## The programs waiting for the server and the points it reported.

const PATH := "user://test_results.json"

var _results: PlayerResults


func before_each() -> void:
	_remove()
	_results = PlayerResults.new(PATH)


func after_each() -> void:
	_remove()


func _remove() -> void:
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func _program(count: int) -> Array:
	var program: Array = []
	for i in count:
		program.append({"op": "MOVE_FORWARD"})
	return program


func test_a_level_keeps_only_the_program_with_the_fewest_slots() -> void:
	_results.queue_result("a", 1, _program(6), 6)
	_results.queue_result("a", 1, _program(4), 4)
	_results.queue_result("a", 1, _program(5), 5)
	assert_eq(int(_results.queue["a"]["slots"]), 4)
	assert_eq(_results.queue["a"]["program"].size(), 4)


func test_a_newer_level_version_replaces_an_older_one_and_never_the_reverse() -> void:
	_results.queue_result("a", 1, _program(3), 3)
	_results.queue_result("a", 2, _program(8), 8)
	assert_eq(int(_results.queue["a"]["levelVersion"]), 2)
	_results.queue_result("a", 1, _program(2), 2)
	assert_eq(int(_results.queue["a"]["levelVersion"]), 2, "an older version does not come back")


func test_pending_lists_slugs_in_order() -> void:
	_results.queue_result("b", 1, _program(2), 2)
	_results.queue_result("a", 1, _program(2), 2)
	assert_eq(_results.pending(), ["a", "b"] as Array[String])


func test_a_sent_entry_is_dropped_but_a_better_one_that_arrived_meanwhile_stays() -> void:
	_results.queue_result("a", 1, _program(5), 5)
	var sent: Dictionary = _results.queue["a"].duplicate(true)
	_results.queue_result("a", 1, _program(3), 3)
	_results.drop_if_unchanged("a", sent)
	assert_true(_results.queue.has("a"), "the better program was not sent yet")
	_results.drop_if_unchanged("a", _results.queue["a"].duplicate(true))
	assert_false(_results.queue.has("a"))


func test_the_servers_answer_is_kept_and_stars_only_go_up() -> void:
	_results.apply_result("a", {"stars": 2, "points": 25, "total": 25})
	_results.apply_result("a", {"stars": 3, "points": 35, "total": 35})
	_results.apply_result("a", {"stars": 1, "points": 10, "total": 35})
	assert_eq(_results.total, 35)
	assert_eq(_results.stars_for("a"), 3)
	assert_eq(_results.stars_for("missing"), 0)


func test_save_and_load_round_trip() -> void:
	_results.queue_result("a", 1, _program(3), 3)
	_results.apply_result("b", {"stars": 3, "points": 35, "total": 35})
	assert_true(_results.save())
	var again := PlayerResults.new(PATH)
	again.load_data()
	assert_eq(again.pending(), ["a"] as Array[String])
	assert_eq(again.total, 35)
	assert_eq(again.stars_for("b"), 3)


func test_clearing_points_keeps_the_unsent_programs() -> void:
	_results.queue_result("a", 1, _program(3), 3)
	_results.apply_result("a", {"stars": 3, "points": 35, "total": 35})
	_results.clear_points()
	assert_eq(_results.total, -1)
	assert_eq(_results.stars_for("a"), 0)
	assert_true(_results.queue.has("a"))


func test_a_damaged_file_starts_empty() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	_results.load_data()
	assert_eq(_results.total, -1)
	assert_true(_results.queue.is_empty())


func test_entries_without_a_program_are_ignored_on_load() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"version": 1,
						"queue": {"a": {"levelVersion": 1, "slots": 3, "program": []}},
						"total": 5,
						"levels": {},
					}
				)
			)
		)
	)
	file.close()
	_results.load_data()
	assert_true(_results.queue.is_empty())
	assert_eq(_results.total, 5)
