extends Area2D

class_name Rat


#region State

signal rat_clicked(rat: Rat)
signal state_changed
signal arrived_at_location(rat: Rat)

@export var _state: RatState

var _destination: Location

const MIN_OWNER_RELATIONSHIP: float = -100.0
const MAX_OWNER_RELATIONSHIP: float = 100.0

#endregion


#region Initialization

const DEFAULT_VALUES := preload(
	"res://entities/rat/config/generation/generation_defaults.tres"
)


func initialize(idx: int) -> void:
	_state = RatState.new()
	_state.rat_id = idx
	_state.title = "Rat " + str(idx)

	_state.personality = Personality.new()
	_state.personality.greed = _randomize_personality_trait("greed")
	_state.personality.temper = _randomize_personality_trait("temper")
	_state.personality.socialness = _randomize_personality_trait("socialness")
	_state.personality.ambition = _randomize_personality_trait("ambition")
	_state.personality.laziness = _randomize_personality_trait("laziness")

	_state.status = DEFAULT_VALUES.default_status.duplicate(true) as Status
	_state.needs = DEFAULT_VALUES.default_needs.duplicate(true) as Needs
	_state.camaraderie = Camaraderie.new()


func _ready() -> void:
	$Label.text = _state.title
	$ColorRect.modulate = Color.from_hsv(randf(), 0.8, 0.9)


func _randomize_personality_trait(personality_trait: String) -> float:
	return randfn(DEFAULT_VALUES.personality_mean.get(personality_trait), DEFAULT_VALUES.personality_deviation.get(personality_trait))

#endregion


#region State capture

func get_id() -> int:
	return _state.rat_id


## Returns an independent copy of the rat's current state.
func get_state_snapshot() -> RatState:
	return _state.duplicate(true) as RatState


## Returns independent working values for preparing a rat state update.
func get_state_update_draft() -> RatStateUpdateDraft:
	return RatStateUpdateDraft.new(
		_state.rat_id,
		_state.needs,
		_state.status.stress,
		_state.effective_average_urgency
	)

#endregion


#region Requests and updates

## Validates the draft before applying any changes to the rat.
## Accepted drafts may leave the rat unchanged.
func request_state_update(draft: RatStateUpdateDraft) -> Error:
	if draft == null:
		push_error(
			"Rat %d rejected a missing update draft." % _state.rat_id
		)
		return ERR_INVALID_PARAMETER

	if draft.rat_id != _state.rat_id:
		push_error(
			"Rat %d rejected an update draft for rat %d."
			% [_state.rat_id, draft.rat_id]
		)
		return ERR_INVALID_PARAMETER

	var validation_error: Error = draft.validate()
	if validation_error != OK:
		return validation_error

	_process_state_change(_apply_state_update_draft.bind(draft))
	return OK


func _apply_state_update_draft(draft: RatStateUpdateDraft) -> bool:
	var changed: bool = false

	for need in NeedValues.get_keys():
		if _state.needs[need] != draft.needs[need]:
			_state.needs[need] = draft.needs[need]
			changed = true

	var bounded_stress: float = clampf(
		draft.stress,
		Status.MIN_STATUS_VALUE,
		Status.MAX_STATUS_VALUE
	)

	if _state.status.stress != bounded_stress:
		_state.status.stress = bounded_stress
		changed = true

	if _state.effective_average_urgency != draft.effective_average_urgency:
		_state.effective_average_urgency = draft.effective_average_urgency
		changed = true

	return changed


## Validates a complete proposed state before accepting an owned copy.
func request_state_replacement(proposed_state: RatState) -> Error:
	if proposed_state == null:
		push_error(
			"Rat %d rejected a missing proposed state." % _state.rat_id
		)
		return ERR_INVALID_PARAMETER

	if proposed_state.rat_id != _state.rat_id:
		push_error(
			"Rat %d rejected a proposed state for rat %d."
			% [_state.rat_id, proposed_state.rat_id]
		)
		return ERR_INVALID_PARAMETER

	var validation_error: Error = proposed_state.validate()
	if validation_error != OK:
		return validation_error

	_process_state_change(_apply_state_replacement.bind(proposed_state))
	return OK


func _apply_state_replacement(proposed_state: RatState) -> bool:
	var accepted_state: RatState = proposed_state.duplicate(true) as RatState
	accepted_state.owner_relationship = clampf(
		accepted_state.owner_relationship,
		MIN_OWNER_RELATIONSHIP,
		MAX_OWNER_RELATIONSHIP
	)

	for other_rat_id in accepted_state.camaraderie.camaraderie:
		accepted_state.camaraderie.add_relationship(
			other_rat_id,
			accepted_state.camaraderie.camaraderie[other_rat_id]
		)

	if _state.is_equal_to(accepted_state):
		return false

	_state = accepted_state
	$Label.text = _state.title
	return true


## Runs a complete state operation and announces any resulting change.
func _process_state_change(apply_change: Callable) -> bool:
	var changed: bool = apply_change.call()

	if changed:
		state_changed.emit()

	return changed

#endregion


#region Decisions

## Chooses from the manager's scoring options and handles the destination.
func request_destination_choice(
	locations: Array[Location],
	options: Array[LocationChoiceOption]
) -> void:
	_process_state_change(_choose_destination.bind(locations, options))


func _choose_destination(
	locations: Array[Location],
	options: Array[LocationChoiceOption]
) -> bool:
	var copied_needs: Needs = _state.needs.duplicate(true) as Needs
	var urgencies: NeedUrgencyValues = (
		NeedSystem.calculate_need_urgencies(copied_needs)
	)
	var chosen_index: int = LocationChoice.choose_destination_index(
		urgencies,
		options
	)
	var intended_location: Location = null

	if chosen_index >= 0:
		intended_location = locations[chosen_index]

	return _apply_destination_choice(intended_location)


func _apply_destination_choice(intended_location: Location) -> bool:
	var intended_location_id: StringName = (
		intended_location.location_id if intended_location != null else &""
	)

	if intended_location_id == _state.current_location_id:
		return false

	var proposed_state: RatState = get_state_snapshot()
	proposed_state.destination_id = intended_location_id

	if intended_location != null:
		proposed_state.current_location_id = &""
		proposed_state.activity_state = RatConstants.STATE.TRAVELLING
	else:
		proposed_state.activity_state = RatConstants.STATE.IDLE

	_destination = intended_location
	return _apply_state_replacement(proposed_state)

#endregion


#region Movement

func _process(delta: float) -> void:
	if _state.activity_state == RatConstants.STATE.TRAVELLING:
		_travel_to_destination(delta)


## Moves toward the destination and handles arrival when it is reached.
func _travel_to_destination(delta: float) -> void:
	global_position = global_position.move_toward(
		_destination.global_position,
		400 * delta
	)

	if global_position == _destination.global_position:
		_arrive_at_destination()


## Finishes travelling and defaults to idle.
## Announces arrival after the location and activity are updated.
func _arrive_at_destination() -> void:
	_process_state_change(_record_arrival)
	arrived_at_location.emit(self)


func _record_arrival() -> bool:
	var proposed_state: RatState = get_state_snapshot()
	proposed_state.current_location_id = proposed_state.destination_id
	proposed_state.destination_id = &""
	proposed_state.activity_state = RatConstants.STATE.IDLE
	_destination = null
	return _apply_state_replacement(proposed_state)

#endregion


#region Work

## Requests that the rat start working at its current location.
## The manager checks employment eligibility before making this request.
func request_start_work() -> bool:
	return _process_state_change(_start_work)


func _start_work() -> bool:
	if _state.activity_state != RatConstants.STATE.IDLE:
		return false

	if _state.current_location_id == &"":
		return false

	_state.activity_state = RatConstants.STATE.WORKING
	return true


## Stops working and returns to idle.
## Does nothing if the rat is already idle or travelling.
func request_stop_work() -> void:
	_process_state_change(_stop_work)


func _stop_work() -> bool:
	if _state.activity_state != RatConstants.STATE.WORKING:
		return false

	_state.activity_state = RatConstants.STATE.IDLE
	return true

#endregion


#region Input

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		rat_clicked.emit(self)

#endregion
