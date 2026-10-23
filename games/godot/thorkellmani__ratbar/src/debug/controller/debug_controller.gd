## Coordinates colony inspection, debug edits, and time controls.
class_name DebugController extends Node


#region State

var _selected_rat_id: int = 0
var _dependencies_valid: bool = false
var _is_paused: bool = false
var _running_speed: float = 1.0
var _available_jobs: Array[Job] = []

@onready var _rat_manager: RatManager = (
	get_node_or_null("%RatManager") as RatManager
)
@onready var _job_manager: JobManager = (
	get_node_or_null("%JobManager") as JobManager
)
@onready var _location_manager: LocationManager = (
	get_node_or_null("%LocationManager") as LocationManager
)
@onready var _debug_panel: DebugPanel = (
	get_node_or_null("%DebugUI") as DebugPanel
)

#endregion


#region Initialization

func _ready() -> void:
	_dependencies_valid = _validate_dependencies()
	if not _dependencies_valid:
		return

	if not OS.is_debug_build():
		return

	_available_jobs = _job_manager.get_jobs()
	var job_titles: Array[String] = []

	for job in _available_jobs:
		job_titles.append(job.title)

	_debug_panel.display_available_jobs(job_titles)
	_connect_colony_signals()
	_connect_debug_controls()
	_debug_panel.assign_job_requested.connect(
		_on_job_assignment_requested
	)

	_update_game_speed_and_time_controls()


func _validate_dependencies() -> bool:
	var missing_dependencies: Array[String] = []

	if _rat_manager == null:
		missing_dependencies.append("RatManager")

	if _job_manager == null:
		missing_dependencies.append("JobManager")

	if _location_manager == null:
		missing_dependencies.append("LocationManager")

	if _debug_panel == null:
		missing_dependencies.append("DebugUI")

	if not missing_dependencies.is_empty():
		push_error(
			"DebugController is missing scene unique nodes: %s."
			% ", ".join(missing_dependencies)
		)
		return false

	return true


func _connect_colony_signals() -> void:
	_rat_manager.rat_clicked.connect(_on_rat_clicked)
	_rat_manager.rat_state_changed.connect(
		_on_rat_state_changed
	)
	_job_manager.job_assignment_changed.connect(
		_on_job_assignment_changed
	)


func _connect_debug_controls() -> void:
	_debug_panel.pause_requested.connect(_on_pause_requested)
	_debug_panel.play_requested.connect(_on_play_requested)
	_debug_panel.running_speed_requested.connect(
		_on_running_speed_requested
	)
	_debug_panel.discard_edits_requested.connect(
		_on_discard_edits_requested
	)
	_debug_panel.generate_rat_requested.connect(
		_rat_manager.generate_rat
	)

#endregion


#region Rat inspection

func _on_rat_clicked(rat_id: int) -> void:
	if rat_id != _selected_rat_id:
		_debug_panel.discard_edit_draft()

	_selected_rat_id = rat_id
	_update_selected_rat_debug_display()


func _on_rat_state_changed(rat_id: int) -> void:
	if rat_id == _selected_rat_id:
		_update_selected_rat_debug_display()


func _on_job_assignment_changed(rat_id: int) -> void:
	if rat_id == _selected_rat_id:
		_update_selected_rat_debug_display()


func _update_selected_rat_debug_display() -> void:
	if _selected_rat_id == 0:
		return

	var state_snapshot: RatState = (
		_rat_manager.get_rat_state_snapshot(_selected_rat_id)
	)

	if state_snapshot == null:
		_selected_rat_id = 0
		_debug_panel.discard_edit_draft()
		_debug_panel.visible = false
		return

	var display_data: RatDebugDisplayData = (
		_prepare_rat_debug_display_data(state_snapshot)
	)

	_debug_panel.display_rat_debug_data(display_data)
	_debug_panel.visible = true


func _prepare_rat_debug_display_data(
	state_snapshot: RatState
) -> RatDebugDisplayData:
	var display_data := RatDebugDisplayData.new(state_snapshot)
	var current_location: Location = (
		_location_manager.get_location_by_id(
			state_snapshot.current_location_id
		)
	)
	if current_location != null:
		display_data.current_location_title = current_location.title

	var assigned_job_title: String = (
		_job_manager.get_assigned_job_title(state_snapshot.rat_id)
	)
	if not assigned_job_title.is_empty():
		display_data.assigned_job_title = assigned_job_title

	var average_urgency: float = (
		state_snapshot.effective_average_urgency
	)
	if is_nan(average_urgency):
		return display_data

	var tier: StressTier = StressSystem.get_stress_tier(
		average_urgency
	)
	var is_working: bool = (
		_rat_manager.is_rat_working_assigned_job(state_snapshot)
	)

	display_data.need_tier_label = tier.label
	display_data.need_stress_rate_per_game_hour = (
		tier.stress_change_per_game_hour
	)
	display_data.working_stress_rate_per_game_hour = (
		StressSystem.get_work_rate_per_game_hour(is_working)
	)
	display_data.net_stress_rate_per_game_hour = (
		display_data.need_stress_rate_per_game_hour
		+ display_data.working_stress_rate_per_game_hour
	)

	return display_data

#endregion


#region Time controls

func _on_pause_requested() -> void:
	_is_paused = true
	_update_game_speed_and_time_controls()


func _on_running_speed_requested(speed: float) -> void:
	_running_speed = speed
	_update_game_speed_and_time_controls()


func _update_game_speed_and_time_controls() -> void:
	Engine.time_scale = 0.0 if _is_paused else _running_speed
	_debug_panel.display_time_control_state(
		_is_paused,
		_running_speed
	)


func _on_play_requested() -> void:
	var draft: RatState = _debug_panel.get_edit_draft()

	if draft != null:
		if not _debug_panel.validate_edit_inputs():
			return

		var submission_result: Error = _rat_manager.request_debug_state_update(draft)
		if submission_result != OK:
			return

		_debug_panel.discard_edit_draft()
		_update_selected_rat_debug_display()

	_is_paused = false
	_update_game_speed_and_time_controls()


func _on_discard_edits_requested() -> void:
	_debug_panel.discard_edit_draft()
	_update_selected_rat_debug_display()

#endregion


#region Job requests

func _on_job_assignment_requested(job_index: int) -> void:
	if _selected_rat_id == 0:
		return

	if job_index == -1:
		_job_manager.unassign_job(_selected_rat_id)
		return

	if job_index < 0 or job_index >= _available_jobs.size():
		push_error(
			"DebugController received an invalid job index: %d."
			% job_index
		)
		return

	_job_manager.assign_job(
		_selected_rat_id,
		_available_jobs[job_index]
	)

#endregion
