# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The map never expects more ids in a healed event than the sim puts in one (contract 3.1).


func test_heal_marks_never_exceed_the_ids_an_event_carries() -> void:
	assert_true(MapView.HEAL_MARKS <= Battle.HEAL_EVENT_IDS, "HEAL_MARKS %d is at most Battle.HEAL_EVENT_IDS %d" % [MapView.HEAL_MARKS, Battle.HEAL_EVENT_IDS])
	assert_true(MapView.HEAL_MARKS > 0, "the map marks at least one creature")
