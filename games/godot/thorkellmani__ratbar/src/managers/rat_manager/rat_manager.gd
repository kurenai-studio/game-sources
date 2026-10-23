extends Node2D

class_name RatManager

var rat_scene = preload("res://entities/rat/rat.tscn")

signal rat_clicked(rat_id: int)
signal rat_state_changed(rat_id: int)

var next_rat_id: int = 1

var _rat_tick_slot_registry: Array[TickSlotRegistry] = []
var _dependencies_valid: bool = false

@onready var _location_manager: LocationManager = (
	get_node_or_null("%LocationManager") as LocationManager
)
@onready var _job_manager: JobManager = (
	get_node_or_null("%JobManager") as JobManager
)

## Reports missing uniquely named managers before colony operations begin.
func _validate_dependencies() -> bool:
	var missing_dependencies: Array[String] = []

	if _location_manager == null:
		missing_dependencies.append("LocationManager")

	if _job_manager == null:
		missing_dependencies.append("JobManager")

	if not missing_dependencies.is_empty():
		push_error(
			"RatManager is missing scene unique managers: %s."
			% ", ".join(missing_dependencies)
		)
		return false

	return true


func _ready() -> void:
	_dependencies_valid = _validate_dependencies()
	if not _dependencies_valid:
		return

	for i in range(GameConstants.GAME_TICK_SLOTS):
		var new_slot := TickSlotRegistry.new()
		new_slot.idx = i
		_rat_tick_slot_registry.append(new_slot)

	_job_manager.job_assignment_changed.connect(
		_on_job_assignment_changed
	)


## Returns captured state for the requested colony rat.
## Returns null if that rat no longer exists.
func get_rat_state_snapshot(rat_id: int) -> RatState:
	var rat: Rat = Colony.colony.get(rat_id)

	if rat == null:
		return null

	return rat.get_state_snapshot()


func generate_rat() -> void:
	if not _dependencies_valid:
		return

	var rat: Rat = rat_scene.instantiate()
	rat.initialize(next_rat_id)
	next_rat_id += 1

	rat.position = $RatGenerateMarker.position
	Colony.colony[rat.get_id()] = rat
	_assign_slot(rat)
	_connect_rat_signals(rat)

	add_child(rat)


func _connect_rat_signals(rat: Rat) -> void:
	rat.rat_clicked.connect(_on_rat_clicked)
	rat.arrived_at_location.connect(_on_rat_arrived_at_location)
	rat.state_changed.connect(
		_on_rat_state_changed.bind(rat.get_id())
	)


func _on_rat_clicked(rat: Rat) -> void:
	rat_clicked.emit(rat.get_id())


func _on_rat_state_changed(rat_id: int) -> void:
	rat_state_changed.emit(rat_id)


func request_debug_state_update(draft: RatState) -> Error:
	if draft == null:
		push_error("RatManager rejected a missing debug state draft.")
		return ERR_INVALID_PARAMETER

	var rat: Rat = Colony.colony.get(draft.rat_id)
	if rat == null:
		push_error(
			"RatManager received a debug draft for unknown rat %d."
			% draft.rat_id
		)
		return ERR_DOES_NOT_EXIST

	return rat.request_state_replacement(draft)


## Checks active work against the rat's current assignment and location.
func is_rat_working_assigned_job(state: RatState) -> bool:
	if not _dependencies_valid or state == null:
		return false

	if state.activity_state != RatConstants.STATE.WORKING:
		return false

	var assigned_job: Job = _job_manager.get_assigned_job(state.rat_id)
	if assigned_job == null:
		return false

	var current_location: Location = _location_manager.get_location_by_id(
		state.current_location_id
	)
	return current_location != null and current_location in assigned_job.locations


func _request_rat_work_for_current_assignment(rat: Rat) -> void:
	if not _dependencies_valid:
		return

	var state: RatState = rat.get_state_snapshot()
	if state.activity_state == RatConstants.STATE.TRAVELLING:
		return

	var assigned_location_ids: Array[StringName] = (
		_job_manager.get_assigned_job_location_ids(state.rat_id)
	)
	var is_at_assigned_job_station: bool = (
		state.current_location_id != &""
		and state.current_location_id in assigned_location_ids
	)

	if not is_at_assigned_job_station:
		rat.request_stop_work()
	elif state.activity_state == RatConstants.STATE.IDLE:
		rat.request_start_work()


func _on_rat_arrived_at_location(rat: Rat) -> void:
	_request_rat_work_for_current_assignment(rat)


func _on_job_assignment_changed(rat_id: int) -> void:
	var rat: Rat = Colony.colony.get(rat_id)
	if rat != null:
		_request_rat_work_for_current_assignment(rat)


func _assign_slot(rat: Rat) -> void:
	var slot_counts := _rat_tick_slot_registry.map(func(s) -> int: return s.rats.size())
	var slot: int = Utils.pick_weighted_random(slot_counts)
	_rat_tick_slot_registry[slot].rats.append(rat)

func _on_game_clock_tick(tick_count: int) -> void:
	if not _dependencies_valid:
		return

	for rat: Rat in Colony.colony.values():
		var assigned_job: Job = _job_manager.get_assigned_job(rat.get_id())

		_update_rat_simulation(rat, assigned_job)
		_check_rat_reevaluation(tick_count, rat)


## Prepares a state update through the need and stress systems.
## The rat validates and accepts the completed draft.
func _update_rat_simulation(rat: Rat, assigned_job: Job) -> void:
	var state: RatState = rat.get_state_snapshot()
	var current_location: Location = _location_manager.get_location_by_id(
		state.current_location_id
	)
	var is_working_assigned_job: bool = is_rat_working_assigned_job(state)
	var draft: RatStateUpdateDraft = rat.get_state_update_draft()
	var location_and_job_rates_per_game_hour: NeedRates = (
		_get_location_and_job_rates_per_game_hour(
			current_location,
			assigned_job,
			is_working_assigned_job
		)
	)

	NeedSystem.apply_tick_effects(
		draft,
		location_and_job_rates_per_game_hour
	)
	StressSystem.apply_tick_effects(
		draft,
		is_working_assigned_job
	)

	rat.request_state_update(draft)


## Collects location and active-job changes per game-hour for each need.
## NeedSystem adds baseline decay separately.
func _get_location_and_job_rates_per_game_hour(
	current_location: Location,
	assigned_job: Job,
	is_working_assigned_job: bool
) -> NeedRates:
	var location_and_job_rates_per_game_hour := NeedRates.new()

	for need in NeedValues.get_keys():
		if current_location != null:
			location_and_job_rates_per_game_hour[need] += (
				current_location.modifiers[need]
			)

		if is_working_assigned_job:
			location_and_job_rates_per_game_hour[need] += (
				assigned_job.modifiers[need]
			)

	return location_and_job_rates_per_game_hour


## Copies each destination's appeal and adds current employment pressure.
## Keeps the location order so Rat can identify the chosen destination.
func _build_location_choice_options(
	locations: Array[Location],
	assigned_job: Job
) -> Array[LocationChoiceOption]:
	var options: Array[LocationChoiceOption] = []

	for location in locations:
		var employment_pressure: float = 0.0

		if (
			assigned_job != null
			and location in assigned_job.locations
		):
			employment_pressure = JobConstants.EMPLOYMENT_PRESSURE

		options.append(
			LocationChoiceOption.new(
				location.title,
				location.pull,
				employment_pressure
			)
		)

	return options


func _check_rat_reevaluation(tick_count: int, rat: Rat) -> void:
	var slot_index: int = (
		tick_count % GameConstants.GAME_TICK_SLOTS
	)
	var slotted_rats: Array[Rat] = (
		_rat_tick_slot_registry[slot_index].rats
	)

	if rat not in slotted_rats:
		return

	var locations: Array[Location] = (
		_location_manager.get_location_data()
	)
	var assigned_job: Job = _job_manager.get_assigned_job(
		rat.get_id()
	)
	var options: Array[LocationChoiceOption] = (
		_build_location_choice_options(locations, assigned_job)
	)

	rat.request_destination_choice(locations, options)
