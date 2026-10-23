## Displays captured rat state and owns the selected rat's edit draft.
class_name DebugPanel extends CanvasLayer


#region State

signal assign_job_requested(job_index: int)
signal generate_rat_requested
signal play_requested
signal running_speed_requested(speed: float)
signal pause_requested
signal discard_edits_requested

var _displayed_state_snapshot: RatState
var _edit_draft: RatState

@onready var _personality_group: DebugPanelGroup = (
	$Scroller/Panel/Personality
)
@onready var _needs_group: DebugPanelGroup = (
	$Scroller/Panel/Needs
)
@onready var _statuses_group: DebugPanelGroup = (
	$Scroller/Panel/Statuses
)
@onready var _miscellaneous_group: DebugPanelGroup = (
	$Scroller/Panel/Miscellaneous
)
@onready var _attribute_groups: Array[DebugPanelGroup] = [
	_personality_group,
	_needs_group,
	_statuses_group,
	_miscellaneous_group,
]

@onready var _stress_readout: Label = $Scroller/Panel/RatReadout
@onready var _stress_breakdown: DebugStressBreakdown = (
	$Scroller/Panel/StressBreakdown
)
@onready var _job_assignment: DebugJobAssignment = (
	$Scroller/Panel/JobAssignment
)
@onready var _edit_error_label: Label = $Scroller/Panel/EditFeedback
@onready var _discard_edits_button: Button = $Scroller/Panel/DiscardEdits
@onready var _generate_rat_button: Button = $Scroller/Panel/GenerateRat
@onready var _pause_button: PauseButton = $Scroller/Panel/PauseButton
@onready var _time_button: TimeButton = $Scroller/Panel/TimeButton

#endregion


#region Initialization

func _ready() -> void:
	_bind_rat_field_groups()

	for group in _attribute_groups:
		group.edit_requested.connect(_begin_edit_draft)

	_job_assignment.assign_job_requested.connect(
		assign_job_requested.emit
	)
	_discard_edits_button.pressed.connect(discard_edits_requested.emit)
	_generate_rat_button.pressed.connect(generate_rat_requested.emit)
	_pause_button.pause_requested.connect(pause_requested.emit)
	_pause_button.play_requested.connect(play_requested.emit)
	_time_button.running_speed_requested.connect(
		running_speed_requested.emit
	)


func _bind_rat_field_groups() -> void:
	_bind_rat_field_group(
		_personality_group, Personality.get_keys(), "personality"
	)
	_bind_rat_field_group(
		_needs_group, Needs.get_keys(), "needs"
	)
	_bind_rat_field_group(
		_statuses_group, Status.get_keys(), "status"
	)
	_bind_rat_field_group(
		_miscellaneous_group,
		["owner_relationship", "currency", "crisis", "activity_state"]
	)


func _bind_rat_field_group(
	group: DebugPanelGroup,
	field_names: Array[String],
	property_prefix: String = ""
) -> void:
	group.configure_fields(
		field_names,
		_get_rat_attribute_value,
		_update_edit_draft_value,
		property_prefix
	)

#endregion


#region Display

func display_time_control_state(
	is_paused: bool,
	running_speed: float
) -> void:
	_pause_button.display_pause_state(is_paused)
	_time_button.display_running_speed(running_speed)


func display_available_jobs(job_titles: Array[String]) -> void:
	_job_assignment.display_available_jobs(job_titles)


func display_rat_debug_data(display_data: RatDebugDisplayData) -> void:
	_displayed_state_snapshot = display_data.state_snapshot

	var location_text: String = display_data.current_location_title
	if location_text.is_empty():
		location_text = (
			"Travelling"
			if _displayed_state_snapshot.activity_state
			== RatConstants.STATE.TRAVELLING
			else "None"
		)

	_stress_readout.text = (
		"Rat %d stress: %.2f / %.0f\nAssigned job: %s\nLocation: %s"
		% [
			_displayed_state_snapshot.rat_id,
			_displayed_state_snapshot.status.stress,
			Status.MAX_STATUS_VALUE,
			display_data.assigned_job_title,
			location_text,
		]
	)

	_update_rat_attribute_rows()
	_stress_breakdown.display_stress_breakdown(display_data)


func _update_rat_attribute_rows() -> void:
	if _edit_draft != null:
		return

	for group in _attribute_groups:
		group.update()

#endregion


#region Editing

func _begin_edit_draft() -> void:
	if _displayed_state_snapshot == null or _edit_draft != null:
		return

	pause_requested.emit()
	_edit_draft = _displayed_state_snapshot.duplicate(true) as RatState


func get_edit_draft() -> RatState:
	return _edit_draft


func discard_edit_draft() -> void:
	_edit_draft = null
	_edit_error_label.visible = false


func validate_edit_inputs() -> bool:
	_edit_error_label.visible = false
	var invalid_row: DebugPanelStatRow = _get_invalid_edit_row()

	if invalid_row == null:
		return true

	_edit_error_label.text = (
		"Enter a valid number for '%s' before pressing Play."
		% invalid_row.field_label.text
	)
	_edit_error_label.visible = true
	invalid_row.field_value.grab_focus()
	return false


func _get_rat_attribute_value(property_path: NodePath) -> Variant:
	var displayed_state: RatState = (
		_edit_draft
		if _edit_draft != null
		else _displayed_state_snapshot
	)

	if displayed_state == null:
		return null

	return displayed_state.get_indexed(property_path)


func _update_edit_draft_value(
	value: float,
	property_path: NodePath
) -> void:
	if _edit_draft == null:
		return

	_edit_draft.set_indexed(property_path, value)


func _get_invalid_edit_row() -> DebugPanelStatRow:
	for group in _attribute_groups:
		var invalid_row: DebugPanelStatRow = group.get_invalid_edit_row()
		if invalid_row != null:
			return invalid_row

	return null

#endregion
