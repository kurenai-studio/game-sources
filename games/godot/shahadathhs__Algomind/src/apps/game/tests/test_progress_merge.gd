extends GutTest
## Merging solved levels from another device: nothing is lost, better results are kept, and
## merging the same data twice changes nothing.

var _store: ProgressStore


func before_each() -> void:
	_store = ProgressStore.new("user://test_merge.json")


func _entry(id: String, version: int, commands: int, at: float = 100.0) -> Dictionary:
	return {"levelId": id, "levelVersion": version, "bestCommands": commands, "completedAt": at}


func test_union_of_solved_levels() -> void:
	_store.record_completion("a", 1, 4)
	_store.merge_completions([_entry("b", 1, 6)])
	assert_true(_store.is_completed("a"))
	assert_true(_store.is_completed("b"))
	assert_eq(_store.completions().size(), 2)


func test_same_version_keeps_the_fewer_commands() -> void:
	_store.record_completion("a", 1, 9)
	_store.merge_completions([_entry("a", 1, 5)])
	assert_eq(_store.best_commands("a", 1), 5)
	_store.merge_completions([_entry("a", 1, 7)])
	assert_eq(_store.best_commands("a", 1), 5, "a worse remote result never replaces a better one")


func test_a_newer_level_version_replaces_the_score() -> void:
	_store.record_completion("a", 1, 3)
	_store.merge_completions([_entry("a", 2, 8)])
	assert_eq(_store.best_commands("a", 2), 8)
	assert_eq(_store.best_commands("a", 1), 0, "scores are never read against other content")
	_store.merge_completions([_entry("a", 1, 2)])
	assert_eq(_store.best_commands("a", 2), 8, "an older version does not replace a newer one")


func test_the_earliest_completion_time_is_kept() -> void:
	_store.merge_completions([_entry("a", 1, 5, 500.0)])
	_store.merge_completions([_entry("a", 1, 5, 200.0)])
	var found := _store.completions()[0]
	assert_eq(found["completedAt"], 200.0)


func test_merging_twice_changes_nothing() -> void:
	var remote := [_entry("a", 1, 5), _entry("b", 2, 7, 300.0)]
	_store.merge_completions(remote)
	var once := JSON.stringify(_store.completions())
	_store.merge_completions(remote)
	assert_eq(JSON.stringify(_store.completions()), once)


func test_malformed_remote_entries_are_skipped() -> void:
	(
		_store
		. merge_completions(
			[
				"nope",
				{"levelId": 5},
				_entry("zero", 0, 3),
				_entry("none", 1, 0),
				_entry("ok", 1, 3),
			]
		)
	)
	assert_eq(_store.completions().size(), 1)
	assert_true(_store.is_completed("ok"))
