class_name WorldSupport
extends RefCounted
## Shared builders for the tests of worlds 8 to 10: a level that offers the counter, breadcrumbs
## and nested loops, a sweep goal, and the play screen on such a level with stores of its own.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const ALL: Array[String] = [
	"MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "INC", "MARK", "REPEAT", "REPEAT_UNTIL", "IF", "PROC"
]


## A 6 by 3 open board, start (0,0) facing east. `goal` defaults to the target at (5,2).
static func level(
	commands: Array[String] = ALL, mechanics: Array = [], goal: Dictionary = {}
) -> Dictionary:
	return {
		"schemaVersion": 1,
		"levelId": "wt",
		"levelVersion": 1,
		"slug": "wt",
		"title": "World test",
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": mechanics},
		"board": {"width": 6, "height": 3, "walls": []},
		"initialState": {"position": [0, 0], "direction": "east"},
		"availableCommands": commands,
		"constraints": {"maxCommands": 16, "maxSteps": 80},
		"goal": goal if not goal.is_empty() else {"type": "reach_tile", "position": [5, 2]},
		"hints": [],
	}


static func sweep_level(commands: Array[String] = ALL) -> Dictionary:
	return level(commands, ["nested_loops"], {"type": "visit_all"})


## Row by row over the 6 by 3 board: run east, step down, run back, step down, run east.
static func lawnmower() -> Array:
	var run := {"op": "REPEAT", "count": 5, "body": [{"op": M}]}
	return [
		run,
		{"op": R},
		{"op": M},
		{"op": R},
		run.duplicate(true),
		{"op": L},
		{"op": M},
		{"op": L},
		run.duplicate(true),
	]


static func state(level_data: Dictionary, key: String) -> AppState:
	var campaign := Campaign.new()
	campaign.entries.append(
		{"id": level_data["slug"], "number": 2, "world": 0, "chapter": 0, "level": level_data}
	)
	# Stores of their own: never the real user:// data of a run of the game.
	var content := ContentStore.new("user://test_%s_content" % key)
	return AppState.new(campaign, ProgressStore.new("user://test_%s.json" % key), content)


static func screen(host: Control, level_data: Dictionary, key: String) -> PlayScreen:
	var play: PlayScreen = load("res://scenes/play.tscn").instantiate()
	play.persist = false
	play.setup(state(level_data, key), {"level_id": level_data["slug"]})
	host.add_child(play)
	return play
