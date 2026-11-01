class_name GameSession extends RefCounted
## The one object that runs a game (docs/ARCHITECTURE.md section 5). It owns
## the current run, the records, the random generator and the flow state
## (playing, targeting, offer, ended). Screens read from it and send it
## intents. Moves resolve and ask to be saved at once (D-09, D-33); the
## outcome of a move (play on, the no moves offer, or the end of the run) is
## worked out when the view says it has shown the move (D-35).
##
## GameSession never reads or writes files, never plays sounds and never
## touches nodes.

enum Phase { NONE, PLAYING, TARGETING, OFFER, ENDED }

signal run_started(result: MoveResult)                  # a new run's board exists (kind NEW_RUN)
signal move_resolved(result: MoveResult)                # a chain or booster was applied; the view animates it
signal status_changed()                                 # score, records, costs, usability, stars, free boosters or phase changed: re-read
signal targeting_changed(booster_id: StringName, swap_first: Vector2i)   # &"" when targeting ends
signal offer_changed(is_open: bool, suggested: StringName)
signal run_ended(summary: RunSummary)
signal save_requested()                                 # save state and records now (D-33)

const _NO_CELL: Vector2i = Vector2i(-1, -1)

var config: GameConfig
var rng: RunRandom
var state: RunState                                     # read only outside this class
var records: Records                                    # read only outside this class

var _phase: Phase = Phase.NONE
var _waiting: bool = false
var _dragging: bool = false
var _offer_open: bool = false
var _targeting: StringName = &""
var _swap_first: Vector2i = _NO_CELL


## Missing services are created here. Until a run starts, state is an empty
## board with score 0, so every query is safe. Like every state the session
## holds, it never has a null best_at_start (unknown), which SaveCodec refuses to write
## (docs/ARCHITECTURE.md section 10).
@warning_ignore("shadowed_variable")
func _init(config: GameConfig = null, rng: RunRandom = null, records: Records = null) -> void:
	self.config = config if config != null else GameConfig.new()
	self.rng = rng if rng != null else RunRandom.new()
	self.records = records if records != null else Records.new()
	state = RunState.new()
	state.columns = self.config.columns
	state.best_at_start = self.records.best_score


## D-14 with a fresh random seed. Emits run_started (spawn_cells holds all 40
## cells), status_changed and save_requested, and waits for move_shown().
## The run keeps the Best Score from before it began (QA6-03, GDD 12.3), so
## the New best badge survives a restart. The new run has no stars and no
## free boosters (D-45, D-46).
func start_new_run() -> void:
	_leave_flow(Phase.PLAYING)
	rng.use_random_seed()
	var best_score_before: BigNum = records.best_score
	var best_tile_before: int = records.best_tile
	state = RunRules.new_run(rng, records, config)
	state.best_at_start = best_score_before
	var result: MoveResult = MoveResult.new()
	result.kind = MoveResult.Kind.NEW_RUN
	result.cells_before = state.cells.duplicate()
	result.cells_after = state.cells.duplicate()
	for column: int in config.columns:
		for row: int in config.rows:
			var cell: Vector2i = Vector2i(column, row)
			result.spawn_cells.append(cell)
			result.spawn_values.append(state.value_at(cell))
	result.new_best_tile = records.best_tile > best_tile_before
	_begin(result)


## D-33 on load (flow rule 7). Takes a fresh random seed, updates the records
## from the board, and emits run_started with no spawn cells, then
## status_changed and save_requested. move_shown() then runs the move check,
## which opens the offer again if the board has no valid move (GO7).
## The saved Best Score from when the run began is kept. A run saved without
## one (null) takes the Best Score loaded with it instead, the old behaviour
## (GDD 15.1). Loading earns no star (D-45): the saved run highest tile
## already counts them.
func resume(saved: RunState) -> void:
	if saved == null:
		push_error("GameSession.resume: no saved run")
		return
	_leave_flow(Phase.PLAYING)
	rng.use_random_seed()
	state = saved.copy()
	if state.best_at_start == null:
		state.best_at_start = records.best_score
	var result: MoveResult = MoveResult.new()
	result.kind = MoveResult.Kind.NEW_RUN
	result.cells_before = state.cells.duplicate()
	result.cells_after = state.cells.duplicate()
	RunRules.update_records(state, records, result, config)
	_begin(result)


func phase() -> Phase:
	return _phase


## Phase PLAYING, TARGETING or OFFER.
func is_run_in_progress() -> bool:
	return _phase == Phase.PLAYING or _phase == Phase.TARGETING or _phase == Phase.OFFER


## Phase OFFER, or TARGETING entered from the offer.
func is_offer_open() -> bool:
	return _offer_open


## D-35: true from a resolved move until move_shown().
func is_waiting_for_view() -> bool:
	return _waiting


## PLAYING, not waiting for the view, no drag open.
func can_start_chain() -> bool:
	return _phase == Phase.PLAYING and not _waiting and not _dragging


## A finger started a chain. Returns false, and opens no drag, unless can_start_chain().
func begin_drag() -> bool:
	if not can_start_chain():
		return false
	_dragging = true
	return true


## The drag ended by commit, cancel, pause or focus loss.
func end_drag() -> void:
	_dragging = false


func is_dragging() -> bool:
	return _dragging


## D-03. The exponent of the tile the chain would make, or 0 to hide the
## preview: for fewer than 2 tiles, or for a list the joining rule (D-04),
## measured with the run's score, would not build.
func preview_value(chain: Array[Vector2i]) -> int:
	if chain.size() < 2:
		return 0
	var built: Array[Vector2i] = []
	var values: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in chain:
		if not CoreRules.can_join(state.cells, state.score, built, cell, config):
			return 0
		built.append(cell)
		values.append(state.value_at(cell))
	return CoreRules.merge_result(values)


## D-40. The tiles that would join the chain now.
func joinable_cells(chain: Array[Vector2i]) -> Array[Vector2i]:
	return CoreRules.joinable_cells(state.cells, state.score, chain, config)


## Ends the open drag, then commits the chain through RunRules. Refused with
## &"not_now" outside PLAYING or while waiting for the view (flow rule 1); a
## chain RunRules refuses comes back refused. Neither emits anything.
func commit_chain(chain: Array[Vector2i]) -> MoveResult:
	_dragging = false
	if _phase != Phase.PLAYING or _waiting:
		var refused: MoveResult = MoveResult.new()
		refused.kind = MoveResult.Kind.CHAIN
		refused.refusal = &"not_now"
		refused.chain = chain.duplicate()
		refused.cells_before = state.cells.duplicate()
		refused.cells_after = state.cells.duplicate()
		refused.has_valid_move = CoreRules.has_valid_move(state.cells, state.score, config)
		return refused
	var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
	if not result.accepted:
		return result
	return _resolve(result)


## A tap on a booster (GDD 13.1, flow rule 4). Does nothing while input is
## locked or when the booster is not usable. The active targeting booster
## again cancels targeting. Shuffle and Undo apply at once, ending any
## targeting first with nothing charged. Hammer, Swap and Double enter
## targeting, or switch to it from another targeting booster. Returns the
## move when one happened, else null.
func press_booster(id: StringName) -> MoveResult:
	if not _accepts_taps() or not BoosterRules.ALL.has(id):
		return null
	if _phase == Phase.TARGETING and id == _targeting:
		cancel_targeting()
		return null
	if BoosterRules.usability(id, state, config) != BoosterStatus.Usability.USABLE:
		return null
	if BoosterRules.target_count(id) == 0:
		var no_targets: Array[Vector2i] = []
		var result: MoveResult = BoosterRules.apply(id, state, records, no_targets, rng, config)
		if not result.accepted:
			return null
		if _phase == Phase.TARGETING:
			_stop_targeting()
		return _resolve(result)
	_targeting = id
	_swap_first = _NO_CELL
	_phase = Phase.TARGETING
	targeting_changed.emit(id, _NO_CELL)
	status_changed.emit()
	return null


## A tap on a tile while targeting (D-43, flow rule 6). Hammer and Double apply
## to the tile. Swap selects its first tile, deselects it when it is tapped
## again, and applies on a valid second tile; a second tile of the same value
## does nothing (D-24). Returns the move when one happened, else null.
func tap_cell(cell: Vector2i) -> MoveResult:
	if not _accepts_taps() or _phase != Phase.TARGETING:
		return null
	if not CoreRules.in_bounds(cell, config) or state.value_at(cell) <= 0:
		return null
	var targets: Array[Vector2i] = [cell]
	if _targeting == BoosterRules.SWAP:
		if _swap_first == _NO_CELL:
			_swap_first = cell
			targeting_changed.emit(_targeting, cell)
			return null
		if cell == _swap_first:
			_swap_first = _NO_CELL
			targeting_changed.emit(_targeting, _NO_CELL)
			return null
		if not BoosterRules.can_pick_second(state, _swap_first, cell):
			return null
		targets = [_swap_first, cell]
	var result: MoveResult = BoosterRules.apply(_targeting, state, records, targets, rng, config)
	if not result.accepted:
		return null
	_stop_targeting()
	return _resolve(result)


## Back button, pause, focus loss, or the same booster again (13.1, flow
## rule 5). Nothing is charged. Returns to the offer, worked out afresh, when
## targeting was entered from it, else to play.
func cancel_targeting() -> void:
	if _phase != Phase.TARGETING:
		return
	_stop_targeting()
	if _offer_open:
		offer_changed.emit(true, BoosterRules.suggested_rescue(state, config))
	status_changed.emit()


## End run in the offer (D-19 step 7), also while targeting from it. Ignored
## when the offer is not open or a move is still showing.
func end_run() -> void:
	if not _offer_open or _waiting:
		return
	_finish(false)


## The view finished showing the last move. Clears the waiting flag and runs
## the move check (flow rule 3): play on, open or refresh the offer, or end
## the run. Never asks for a save after the run ends.
func move_shown() -> void:
	if not _waiting:
		return
	_waiting = false
	var before: Phase = _phase
	match BoosterRules.outcome(state, config):
		BoosterRules.Outcome.PLAY:
			var was_open: bool = _offer_open
			_offer_open = false
			_phase = Phase.PLAYING
			if was_open:
				offer_changed.emit(false, &"")
			if _phase != before:
				status_changed.emit()
		BoosterRules.Outcome.OFFER:
			_offer_open = true
			_phase = Phase.OFFER
			offer_changed.emit(true, BoosterRules.suggested_rescue(state, config))
			if _phase != before:
				status_changed.emit()
		BoosterRules.Outcome.END:
			_finish(true)


## Every booster in bar order, fresh every call. The suggested rescue (D-42)
## is marked only while the offer is open. While a free booster is held every
## status is free, usable or not, and cost still holds the price (D-46).
func booster_statuses() -> Array[BoosterStatus]:
	var suggested: StringName = BoosterRules.suggested_rescue(state, config) if _offer_open else &""
	var free: bool = BoosterRules.is_free(state, config)
	var statuses: Array[BoosterStatus] = []
	for id: StringName in BoosterRules.ALL:
		var status: BoosterStatus = BoosterStatus.new()
		status.id = id
		status.cost = BoosterRules.cost(id, state, config)
		status.reason = BoosterRules.usability(id, state, config)
		status.usable = status.reason == BoosterStatus.Usability.USABLE
		status.active = _phase == Phase.TARGETING and _targeting == id
		status.suggested = suggested != &"" and id == suggested
		status.free = free
		statuses.append(status)
	return statuses


## The booster in targeting mode, or &"".
func targeting_booster() -> StringName:
	return _targeting


## Swap's selected first tile, or (-1, -1).
func swap_first() -> Vector2i:
	return _swap_first


## D-45. This run's stars, from its run highest tile. 0 before any run, whose
## state is an empty board. status_changed tells the HUD when to read it again.
func stars() -> int:
	return CoreRules.stars(state.run_highest, config)


## D-46. This run's free boosters held: earned minus used. 0 before any run.
## Never below 0 for a run the save code accepts (GDD 15.1).
func free_held() -> int:
	return CoreRules.free_held(state, config)


## Booster and tile taps count only in a run, with no drag open and no move
## still showing (flow rule 1).
func _accepts_taps() -> bool:
	return is_run_in_progress() and not _waiting and not _dragging


## Flow rule 2: mark the outcome on the result, wait for the view, then emit
## move_resolved, status_changed and save_requested in that order.
func _resolve(result: MoveResult) -> MoveResult:
	var next: BoosterRules.Outcome = BoosterRules.outcome(state, config)
	result.offer_opens = next == BoosterRules.Outcome.OFFER
	result.run_ends = next == BoosterRules.Outcome.END
	_waiting = true
	move_resolved.emit(result)
	status_changed.emit()
	save_requested.emit()
	return result


## A new or resumed run's board is in state: play, waiting for the view.
func _begin(result: MoveResult) -> void:
	var next: BoosterRules.Outcome = BoosterRules.outcome(state, config)
	result.accepted = true
	result.has_valid_move = CoreRules.has_valid_move(state.cells, state.score, config)
	result.offer_opens = next == BoosterRules.Outcome.OFFER
	result.run_ends = next == BoosterRules.Outcome.END
	_phase = Phase.PLAYING
	_waiting = true
	run_started.emit(result)
	status_changed.emit()
	save_requested.emit()


## Leaves targeting with nothing charged. The phase goes back to the offer if
## it is open, else to play.
func _stop_targeting() -> void:
	_targeting = &""
	_swap_first = _NO_CELL
	_phase = Phase.OFFER if _offer_open else Phase.PLAYING
	targeting_changed.emit(&"", _NO_CELL)


## Drops the flow state of the run being left and moves to next_phase, then
## tells the view if targeting or the offer was showing.
func _leave_flow(next_phase: Phase) -> void:
	var was_targeting: bool = _targeting != &""
	var was_open: bool = _offer_open
	_targeting = &""
	_swap_first = _NO_CELL
	_offer_open = false
	_dragging = false
	_waiting = false
	_phase = next_phase
	if was_targeting:
		targeting_changed.emit(&"", _NO_CELL)
	if was_open:
		offer_changed.emit(false, &"")


## The run ends (12.3). Closes targeting and the offer, then emits
## status_changed and run_ended. Never save_requested. The New best badge
## shows when the Best Score now is above the Best Score when this run began;
## equalling the old record is not enough.
func _finish(no_moves_left: bool) -> void:
	_leave_flow(Phase.ENDED)
	status_changed.emit()
	var summary: RunSummary = RunSummary.new()
	summary.final_score = state.score
	summary.best_score = records.best_score
	summary.best_tile = records.best_tile
	summary.run_highest = state.run_highest
	summary.stars = stars()
	summary.new_best_score = state.best_at_start != null and records.best_score.compare(state.best_at_start) > 0
	summary.no_moves_left = no_moves_left
	run_ended.emit(summary)
