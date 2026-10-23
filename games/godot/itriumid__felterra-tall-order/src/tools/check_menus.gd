extends SceneTree
## Plays every path through the menus the way a player would, pressing the keys, and fails if any
## step doesn't land where it should or a script error is raised. Screenshots only show a page;
## this chooses from them. Run with:
## timeout 120 godot --headless --path . --script tools/check_menus.gd -- --title

## Each step: the action to press (or a note to act on), the page it should land on ("" while
## playing), and, for some, what else should hold after it: where he is, and where the reset of
## all progress stands.
const STEPS := [
	# Play, then the walk into the village: a line hurried along, then the whole scene skipped.
	["menu_choose", "", {"_place": "arriving"}], ["menu_choose", "", {"_place": "arriving"}],
	["pause", "news", {"_place": "village"}], ["menu_choose", ""],
	["pause", "village_pause"], ["menu_choose", "", {"_place": "village"}],
	# A ruin's door does nothing yet: only the story brings it back, never salvage.
	["grant_salvage", ""], ["to_smithy", ""], ["menu_choose", "", {"village.restored": []}],
	# Out through the gate to the first area: seen off with a word, hurried and skipped; its story
	# told as he walks in, skipped, and he's there; then a run.
	["leave_village", "", {"_place": "leaving"}], ["menu_choose", "", {"_place": "leaving"}],
	["pause", "", {"_place": "run", "_briefing": true}], ["pause", "", {"_briefing": false}], ["pick_1", ""],
	# Salvage thrown out around him, drawn as it flies and lands.
	["drop_salvage", ""],
	["pause", "pause"], ["menu_choose", ""],
	["pause", "pause"], ["move_down", "pause"], ["menu_choose", "settings"], ["move_down", "settings"],
	["move_right", "settings"], ["pause", "pause"], ["pause", ""],
	# Down, then straight back out: walking in again, skipped.
	["down", "summary"], ["move_down", "summary"], ["menu_choose", "", {"_place": "run", "_entering": true}],
	["pause", "", {"_entering": false}], ["pick_2", ""],
	# Down again, and home to the village; the walk home skipped.
	["down", "summary"], ["menu_choose", "", {"_place": "arriving"}], ["pause", "", {"_place": "village"}],
	# Out again, seen off without a word this time (skipped all the same), and the first area
	# freed: the boss down, the freeing told and skipped, the area free in the village's record.
	# Home, the smithy stands again.
	["leave_village", "", {"_place": "leaving"}], ["pause", "", {"_place": "run", "_briefing": false, "_entering": true}],
	["pause", "", {"_entering": false}], ["pick_1", ""],
	["free_area", "", {"_freeing": true}], ["pause", "summary", {"village.liberated": ["edge"]}],
	# Home: the Elder's lesson and the smithy told on the way in, skipped; then what's new.
	["menu_choose", "", {"_place": "arriving"}], ["pause", "news", {"_place": "village", "village.restored": ["home", "smithy"]}],
	["menu_choose", "", {"village.told": ["send_off:edge", "intro:edge", "outro:edge", "teach:edge"]}],
	# Cats rescued, and the next areas freed, as the story would: the weaver's hut, the longhouse,
	# the watchtower, the market and the healer's hut come back, and the rescued build their huts.
	["catch_up", "", {"village.restored": ["home", "smithy", "longhouse", "hut_0", "hut_1", "hut_2", "hut_3", "hut_4", "watchtower", "market", "healer"]}],
	# The smithy: forge the first piece of gear, the vest.
	["to_smithy", ""], ["menu_choose", "forge"], ["move_right", "forge"],
	["menu_choose", "forge", {"village.forged": ["gear:vest"]}], ["pause", ""],
	# His pack at home: the vest worn from the start, then not left home but back in the pack, with
	# too little gear packed to leave any home; a weapon not left home either.
	["to_house", ""], ["menu_choose", "pack"], ["move_right", "pack"],
	["menu_choose", "pack", {"village.starting_piece": "gear:vest"}],
	["menu_choose", "pack", {"village.left_home": [], "village.starting_piece": ""}],
	["move_left", "pack"], ["move_down", "pack"], ["move_down", "pack"], ["menu_choose", "pack", {"village.left_home": []}], ["pause", ""],
	# The weaver's hut: buy a gray coat, and wear it.
	["to_weaver", ""], ["menu_choose", "looks"], ["move_down", "looks"], ["move_down", "looks"], ["menu_choose", "looks", {"village.coat": "gray"}], ["pause", ""],
	# The market: salvage traded for cloth. The healer's hut: a tonic brewed for the next run.
	["to_market", ""], ["menu_choose", "market"], ["menu_choose", "market", {"village.cloth": 45}], ["pause", ""],
	["to_healer", ""], ["menu_choose", "healer"], ["menu_choose", "healer", {"village.tonic_ready": true}], ["pause", ""],
	# The book of stories at the longhouse.
	["to_longhouse", ""], ["menu_choose", "book"], ["move_down", "book"], ["pause", ""],
	# The map board: it opens on the next area, the airstrip; up and back down to it, then on to
	# Endless.
	["to_board", ""], ["menu_choose", "board", {"village.next_run": "airstrip"}], ["move_up", "board"], ["move_right", "board"],
	["move_down", "board"], ["menu_choose", "board", {"village.next_run": "endless"}],
	["pause", ""], ["to_home", ""],
	# Out to Endless, then giving the run up: back to the village from the pause menu.
	["leave_village", "", {"_place": "leaving"}], ["pause", "", {"_place": "run", "_run_kind": "endless"}],
	["pause", "", {"_entering": false}], ["pick_1", ""],
	["pause", "pause"], ["move_down", "pause"], ["move_down", "pause"], ["move_down", "pause"],
	# Home, with the lessons of the two areas freed meanwhile told on the way in; then what's new.
	["menu_choose", "", {"_place": "arriving"}], ["pause", "news", {"_place": "village"}], ["menu_choose", ""],
	# From the village's pause menu, back to the title.
	["pause", "village_pause"], ["move_down", "village_pause"], ["move_down", "village_pause"],
	["menu_choose", "title", {"_place": "title"}], ["move_down", "title"], ["menu_choose", "settings"],
	# Up from the top wraps to Back, then up again to Reset all progress: asked, then done.
	["move_up", "settings"], ["move_up", "settings"], ["menu_choose", "settings", {"_reset_state": "asking"}],
	["menu_choose", "settings", {"_reset_state": "done"}],
	["pause", "title"],
]

## Hears every error the engine reports while the menus are played, script errors among them: an
## error can strike after a step has already landed on the right page.
class ErrorCounter extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d in %s: %s" % [file, line, function, rationale if not rationale.is_empty() else code])


var _main: Node
var _errors := ErrorCounter.new()
var _frame := 0
var _step := 0
var _failures: Array[String] = []


func _init() -> void:
	OS.add_logger(_errors)
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	# A key goes down for a frame, then the game gets a few frames to act on it.
	var phase := _frame % 6
	if _frame < 12:
		return false
	if _step >= STEPS.size():
		_finish()
		return true
	var action: String = STEPS[_step][0]
	if phase == 0:
		if action == "down":
			_main.cat.health = 0.0
		elif action == "leave_village":
			# Walked to the end of the path out.
			_main.village_map.cat.body.position = Vector2(VillageMap.SIZE.x - 0.1, VillageMap.RETURN_SPOT.y)
		elif action == "grant_salvage":
			_main.village.salvage = 200
			_main.village.cloth = 50
		elif action == "catch_up":
			for index in 6:
				_main.village.cats.append({"name": Cage.NAMES[index], "coat": "gray"})
			for area_id in ["deep", "sawpits", "clearing", "slide", "offices"]:
				_main.village.liberate(area_id)
			for building in _main.village.catch_up():
				_main.village_map.show_restored(building)
		elif action == "drop_salvage":
			_main.arena.drop_salvage(_main.cat.body.position + Vector2(1.5, 0.0), 6)
		elif action == "free_area":
			# The area's goal done and its boss down.
			_main.arena.goal_done = true
			if _main.arena.boss == null:
				_main.arena._bring_in_the_boss()
			_main.arena.strike(_main.arena.boss, 1.0e7, Vector2.ZERO, 0.0, 0.0, "round")
		elif action in ["to_smithy", "to_weaver", "to_home", "to_board", "to_house", "to_longhouse", "to_market", "to_healer"]:
			# Walked up to a door, or back into the open.
			var spots := {"to_smithy": VillageMap.SMITHY, "to_weaver": VillageMap.HUTS[0], "to_board": VillageMap.BOARD, "to_house": VillageMap.HOME, "to_longhouse": VillageMap.LONGHOUSE, "to_market": VillageMap.MARKET, "to_healer": VillageMap.HEALER}
			var footprint: Rect2 = spots.get(action, Rect2(VillageMap.HOME_SPOT, Vector2.ZERO))
			_main.village_map.cat.body.position = Vector2(footprint.get_center().x, footprint.end.y + 0.45) if action != "to_home" else VillageMap.HOME_SPOT
		else:
			Input.action_press(action)
	elif phase == 1 and InputMap.has_action(action):
		Input.action_release(action)
	elif phase == 5:
		var wanted: String = STEPS[_step][1]
		if _main._page != wanted:
			_failures.append("step %d (%s): on '%s', wanted '%s'" % [_step + 1, action, _main._page, wanted])
		if STEPS[_step].size() > 2:
			var expected: Dictionary = STEPS[_step][2]
			for property: String in expected:
				var found: Variant = _main
				for part in property.split("."):
					found = found.get(part)
				if found != expected[property]:
					_failures.append("step %d (%s): %s is '%s', wanted '%s'" % [_step + 1, action, property, found, expected[property]])
		_step += 1
	return false


func _finish() -> void:
	for failure in _failures:
		print("FAIL  ", failure)
	for error in _errors.errors:
		print("FAIL  error while playing the menus: ", error)
	print("%d of %d menu steps landed where they should, with %d errors." % [STEPS.size() - _failures.size(), STEPS.size(), _errors.errors.size()])
	quit(1 if not _failures.is_empty() or not _errors.errors.is_empty() else 0)
