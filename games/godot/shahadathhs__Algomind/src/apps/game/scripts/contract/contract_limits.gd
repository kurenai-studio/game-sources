class_name ContractLimits
extends RefCounted
## Limits, names, and patterns of the level contract (schema version 1).
## Mirrors packages/level-contract/src/constants.ts; a change to the rules changes both.

const SCHEMA_VERSION := 1

## The commands that move or turn the automaton, in the canonical order.
const PRIMITIVE_COMMANDS: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"]
## Adds one to the counter N (stops at 11). Offered by listing INC.
const INC_OP := "INC"
## Drops a breadcrumb on the current cell. Offered by listing MARK.
const MARK_OP := "MARK"
## Every instruction that moves, turns, counts or marks: one slot and one step each.
const ACTION_COMMANDS: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "INC", "MARK"]
## The value of REPEAT.count that means "the counter N, read when the loop starts".
const COUNTER_REF := "N"
## The mechanic a level lists in requires.mechanics to allow a loop inside a loop.
const NESTED_LOOPS_MECHANIC := "nested_loops"
const RECURSION_MECHANIC := "recursion"
## How many procedure calls may be running inside each other.
const CALL_DEPTH_MAX := 24
## The loop instruction: a count (a number or "N") and a body of actions, IFs and one inner loop.
const REPEAT_OP := "REPEAT"
## The conditional loop: it runs its body while the way ahead is open.
const REPEAT_UNTIL_OP := "REPEAT_UNTIL"
## The conditions a REPEAT_UNTIL can wait for. BLOCKED: a wall or the board edge is straight ahead.
## GOAL is never true at the start of a round (entering the goal ends the run).
const UNTIL_CONDITIONS: Array[String] = ["BLOCKED", "GOAL"]
## The decision instruction: a sensor, a `then` branch and an `else` branch of primitives.
const IF_OP := "IF"
## What an IF can look at, each about the cell ahead, left or right. CLEAR: on the board and not a
## wall. FRESH: such a cell with no breadcrumb. BACK: the cell this cell's breadcrumb points to.
## The FRESH and BACK sensors need MARK offered.
const SENSORS: Array[String] = [
	"CLEAR_AHEAD",
	"CLEAR_LEFT",
	"CLEAR_RIGHT",
	"FRESH_AHEAD",
	"FRESH_LEFT",
	"FRESH_RIGHT",
	"BACK_AHEAD",
	"BACK_LEFT",
	"BACK_RIGHT",
]
## A named piece of program, defined once at the top level and run by CALL.
const PROC_OP := "PROC"
## Runs the procedure of that name. Offered together with PROC: a level that lists PROC allows both.
const CALL_OP := "CALL"
## The names a procedure can have. At most one procedure per name.
const PROCEDURE_NAMES: Array[String] = ["A", "B", "C"]
## Every command a level can offer, in the canonical order.
const COMMAND_NAMES: Array[String] = [
	"MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "INC", "MARK", "REPEAT", "REPEAT_UNTIL", "IF", "PROC"
]
## Clockwise order: turning right moves one step forward in this list.
const DIRECTIONS: Array[String] = ["north", "east", "south", "west"]
const DIFFICULTIES: Array[String] = ["easy", "medium", "hard"]
const GOAL_TYPES: Array[String] = ["reach_tile", "visit_all"]

## Largest integer a JSON number may carry and still be exact (2^53 - 1).
const MAX_SAFE_INTEGER := 9007199254740991

const ID_MIN := 1
const ID_MAX := 64
const LEVEL_VERSION_MIN := 1
const LEVEL_VERSION_MAX := 1000000
const TITLE_MIN := 1
const TITLE_MAX := 60
const DESCRIPTION_MIN := 0
const DESCRIPTION_MAX := 280
const MECHANICS_MAX_COUNT := 8
const MECHANIC_MIN := 1
const MECHANIC_MAX := 32
const BOARD_SIDE_MIN := 3
const BOARD_SIDE_MAX := 12
const MAX_WALLS := 100
const MAX_COMMANDS_MIN := 1
const MAX_COMMANDS_MAX := 64
const MAX_STEPS_MIN := 1
const MAX_STEPS_MAX := 1000
const REPEAT_BODY_MIN := 1
const REPEAT_BODY_MAX := 8
const REPEAT_COUNT_MIN := 2
const REPEAT_COUNT_MAX := 11
## Extra test boards a level may carry besides its own board.
const EXTRA_BOARDS_MIN := 1
const EXTRA_BOARDS_MAX := 5

const PATROL_PATTERNS: Array[String] = ["back_and_forth", "loop"]
const PATROLS_MIN := 1
const PATROLS_MAX := 3
const PATROL_CELLS_MIN := 2
const PATROL_CELLS_MAX := 12
const PATROL_LOOP_CELLS_MIN := 4
const LOCKS_MIN := 1
const LOCKS_MAX := 3
const DELIVERIES_MIN := 1
const DELIVERIES_MAX := 3
const SWITCHES_MIN := 1
const SWITCHES_MAX := 3
const TELEPORTS_MIN := 1
const TELEPORTS_MAX := 3
const ICE_MIN := 1
const ICE_MAX := 30
const BELTS_MIN := 1
const BELTS_MAX := 20
const PROC_BODY_MIN := 1
const PROC_BODY_MAX := 8
const IF_THEN_MIN := 1
const IF_THEN_MAX := 4
const IF_ELSE_MIN := 0
const IF_ELSE_MAX := 4
## How many IFs an else-if chain may hold (the first IF and each IF in an else).
const IF_CHAIN_MAX := 6
## The counter N: its value at the start of a run, and the most it reaches.
const COUNTER_START := 1
const COUNTER_MAX := 11
const HINTS_MAX_COUNT := 5
const HINT_MIN := 1
const HINT_MAX := 140

## Unit steps as [dx, dy]; y grows downward, so north is -1.
const DIRECTION_DELTAS := {
	"north": [0, -1],
	"east": [1, 0],
	"south": [0, 1],
	"west": [-1, 0],
}


## True when op is the loop instruction. Safe for any value (comparing mismatched types errors).
static func is_repeat(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and op == REPEAT_OP


## True when op is the conditional loop. Safe for any value.
static func is_repeat_until(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and op == REPEAT_UNTIL_OP


## True when op is either loop instruction (a node that carries a body).
static func is_loop(op: Variant) -> bool:
	return is_repeat(op) or is_repeat_until(op)


## True when op is the decision instruction. Safe for any value.
static func is_if(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and op == IF_OP


## True when op is a procedure definition. Safe for any value.
static func is_proc(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and op == PROC_OP


## True when op is a procedure call. Safe for any value.
static func is_call(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and op == CALL_OP


## True when op is any op a program node can have: a command, or CALL (offered by PROC).
static func is_node_op(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and (COMMAND_NAMES.has(op) or op == CALL_OP)


## True when op is a single-step action: a move, a turn, INC or MARK. Safe for any value.
static func is_action(op: Variant) -> bool:
	return typeof(op) == TYPE_STRING and ACTION_COMMANDS.has(op)


## True when a sensor name reads breadcrumbs (and so needs MARK offered).
static func is_marker_sensor(sensor: Variant) -> bool:
	return typeof(sensor) == TYPE_STRING and not String(sensor).begins_with("CLEAR_")
