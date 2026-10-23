extends Node

## Game-level state machine (State Machine pattern).
##
## Manages top-level game flow:
##   Title → Running → Checkpoint → Upgrading → GameOver
##
## Registered as an autoload named "GameStateManager" in project.godot.
## Any script can call GameStateManager.change_state(GameStateManager.State.RUNNING).
##
## UI nodes drive their own visibility by connecting to `state_changed` in
## their _ready(), and reading `GameStateManager.current_state` for the
## initial value (autoloads are ready before scene nodes).
##
## Phase 3 will wire Checkpoint and Upgrading into the upgrade screen.
## EventBus callbacks (_on_run_started, _on_run_ended, _on_checkpoint_reached)
## are already stubbed — connect them once the EventBus PR is merged.

## Top-level game states. Matches the flow in PLAN.md section 2.
enum State {
	TITLE,
	RUNNING,
	CHECKPOINT,  ## Phase 3 stub — pauses run, shows upgrade choice UI
	UPGRADING,   ## Phase 3 stub — player selects upgrade
	GAME_OVER,
}

## Emitted after every successful state transition.
## new_state and old_state are both State enum values.
## Connect in any UI node's _ready() to drive show/hide cleanly:
##   GameStateManager.state_changed.connect(_on_game_state_changed)
signal state_changed(new_state: State, old_state: State)

var current_state: State = State.TITLE
var _previous_state: State = State.TITLE

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# TODO (EventBus PR): wire run lifecycle signals here:
	#   EventBus.run_started.connect(_on_run_started)
	#   EventBus.run_ended.connect(_on_run_ended)
	#   EventBus.checkpoint_reached.connect(_on_checkpoint_reached)

	# Enter the initial state without emitting state_changed — scene nodes
	# haven't connected yet. They should read current_state in their own _ready().
	_enter_state(current_state)

func _process(delta: float) -> void:
	_process_state(current_state, delta)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Transition to new_state. No-ops if already in that state.
## Calls exit on the current state, then enter on the new one, then emits
## state_changed so all connected UI / systems update themselves.
func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	_exit_state(current_state)
	_previous_state = current_state
	current_state = new_state
	_enter_state(new_state)
	state_changed.emit(current_state, _previous_state)

# ---------------------------------------------------------------------------
# State dispatch — mirrors player_state_manager.gd's set_state() approach
# but uses match instead of a child-node dict (autoloads have no scene tree).
# ---------------------------------------------------------------------------

func _enter_state(state: State) -> void:
	match state:
		State.TITLE:       _enter_title()
		State.RUNNING:     _enter_running()
		State.CHECKPOINT:  _enter_checkpoint()
		State.UPGRADING:   _enter_upgrading()
		State.GAME_OVER:   _enter_game_over()

func _exit_state(state: State) -> void:
	match state:
		State.TITLE:       _exit_title()
		State.RUNNING:     _exit_running()
		State.CHECKPOINT:  _exit_checkpoint()
		State.UPGRADING:   _exit_upgrading()
		State.GAME_OVER:   _exit_game_over()

func _process_state(state: State, delta: float) -> void:
	match state:
		State.TITLE:       _process_title(delta)
		State.RUNNING:     _process_running(delta)
		State.CHECKPOINT:  _process_checkpoint(delta)
		State.UPGRADING:   _process_upgrading(delta)
		State.GAME_OVER:   _process_game_over(delta)

# ---------------------------------------------------------------------------
# TITLE
# ---------------------------------------------------------------------------

func _enter_title() -> void:
	get_tree().paused = false

func _exit_title() -> void:
	pass

func _process_title(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# RUNNING
# ---------------------------------------------------------------------------

func _enter_running() -> void:
	get_tree().paused = false

func _exit_running() -> void:
	pass

func _process_running(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# CHECKPOINT  (Phase 3 stub)
# ---------------------------------------------------------------------------

func _enter_checkpoint() -> void:
	## Phase 3: pause the run, present upgrade-choice UI.
	## For now just log so accidental transitions are visible in the debugger.
	push_warning("GameStateManager: CHECKPOINT state entered — not yet implemented (Phase 3).")

func _exit_checkpoint() -> void:
	pass

func _process_checkpoint(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# UPGRADING  (Phase 3 stub)
# ---------------------------------------------------------------------------

func _enter_upgrading() -> void:
	## Phase 3: player picks one upgrade from the randomised pool.
	push_warning("GameStateManager: UPGRADING state entered — not yet implemented (Phase 3).")

func _exit_upgrading() -> void:
	pass

func _process_upgrading(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# GAME OVER
# ---------------------------------------------------------------------------

func _enter_game_over() -> void:
	get_tree().paused = true

func _exit_game_over() -> void:
	get_tree().paused = false

func _process_game_over(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# EventBus callbacks — stubbed, connect in _ready() once EventBus PR merges
# ---------------------------------------------------------------------------

func _on_run_started() -> void:
	change_state(State.RUNNING)

func _on_run_ended(_distance: float) -> void:
	change_state(State.GAME_OVER)

func _on_checkpoint_reached(_index: int) -> void:
	change_state(State.CHECKPOINT)
