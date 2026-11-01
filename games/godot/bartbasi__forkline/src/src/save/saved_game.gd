# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name SavedGame
extends RefCounted
## One level or run in progress, saved at the exact moment (docs/ARCHITECTURE.md 3.5, 5.5, 5.6, 6).
## One saved game per mode (Bart, hard stop A).

const FORMAT: int = 1
const LEVEL: StringName = &"level"
const RUN: StringName = &"run"
const DAILY: StringName = &"daily"
const MODES: Array[StringName] = [LEVEL, RUN, DAILY]
const ORDER_MAX: int = 1000000000000
const KEYS: PackedStringArray = ["format", "mode", "order", "level_id", "twist", "battle", "run"]

var mode: StringName = LEVEL                           # &"level", &"run" or &"daily"
var order: int = 0                                     # higher is more recent; SaveStore sets it
var level_id: StringName = &""                         # the campaign level; &"" for runs
var twist: bool = false
var battle: Battle = null
var run: RunSession = null                             # the run around battle; null for a campaign level


## The file shape (5.5). "run" is null for a campaign level.
func to_data() -> Dictionary:
	return {
		"format": FORMAT, "mode": String(mode), "order": order, "level_id": String(level_id),
		"twist": twist, "battle": battle.to_data() if battle != null else {},
		"run": run.to_data() if run != null else null,
	}


## True when this game can be saved: a known mode and a battle still being played. A run
## or daily also needs its run around this battle, a daily with a day and a run without;
## a campaign level has no run. So a save never holds what from_data refuses.
func can_save() -> bool:
	if not MODES.has(mode) or battle == null:
		return false
	if battle.phase != Battle.Phase.BUILD and battle.phase != Battle.Phase.WAVE:
		return false
	if mode == LEVEL:
		return run == null
	return run != null and run.battle == battle and run.daily == (mode == DAILY)


## Null when any field is invalid. All or nothing.
static func from_data(data: Variant, game: GameData) -> SavedGame:
	if game == null or game.catalog == null:
		return null
	var chk: DataCheck = DataCheck.new("saved game")
	if not chk.object(data, "", KEYS) or not chk.ok():
		return null
	var top: Dictionary = data
	var saved: SavedGame = new()
	chk.integer(top, "format", "", FORMAT, FORMAT)
	var mode_value: Variant = top["mode"]
	if not DataCheck.is_string(mode_value) or not MODES.has(StringName(String(mode_value))):
		return null
	saved.mode = StringName(String(mode_value))
	saved.order = chk.integer(top, "order", "", 0, ORDER_MAX)
	saved.twist = chk.boolean(top, "twist", "")
	if saved.mode == LEVEL and top["run"] != null:
		chk.fail("run", "must be null for a campaign level")
	if saved.mode != LEVEL and (game.run == null or typeof(top["run"]) != TYPE_DICTIONARY):
		chk.fail("run", "must be a run")
	var id_value: Variant = top["level_id"]
	if saved.mode == LEVEL:
		saved.level_id = chk.ident(top, "level_id", "")
		if not game.levels.has(saved.level_id):
			chk.fail("level_id", "must be a campaign level")
	elif not DataCheck.is_string(id_value) or not String(id_value).is_empty():
		chk.fail("level_id", "must be empty for a run")
	if saved.twist and (saved.mode != LEVEL or not game.levels.has(saved.level_id) or game.levels[saved.level_id].twist_effects.is_empty()):
		chk.fail("twist", "must name a level with a Twist")
	if not chk.ok():
		return null
	saved.battle = Battle.from_data(top["battle"], game.catalog)
	if saved.battle == null:
		return null
	if saved.mode == LEVEL and saved.battle.level.id != saved.level_id:
		return null
	# A campaign level plays its Twist's effects or none, and takes no cards (RULES 13, 14).
	# A run has no Twist.
	if saved.mode == LEVEL:
		var twist: Array[Dictionary] = game.levels[saved.level_id].twist_effects if saved.twist else ([] as Array[Dictionary])
		if saved.battle.twist_effects != twist:
			return null
		if not saved.battle.card_effects.is_empty() or not saved.battle.risk_waiting.is_empty():
			return null
		# Only cards add gates, and only risk cards make a wave take a risk card or open
		# every gate (2.8). A Twist sets the gates given, never gates_added.
		var inner: Dictionary = top["battle"]
		if not (inner["wave_risk"] as Array).is_empty() or int(inner["gates_added"]) != 0 or saved.battle.gates_open:
			return null
	elif not saved.battle.twist_effects.is_empty():
		return null
	if saved.mode == DAILY and saved.battle.relaxed:
		return null
	if saved.mode != LEVEL:
		# The run is checked around the battle saved with it (5.6). A daily has a day and a
		# normal run has none, so neither can pass as the other.
		saved.run = RunSession.from_data(top["run"], saved.battle, game.run)
		if saved.run == null or saved.run.daily != (saved.mode == DAILY):
			return null
	return saved
