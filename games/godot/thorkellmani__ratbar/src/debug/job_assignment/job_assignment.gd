## Displays available jobs and emits the selected job index.
class_name DebugJobAssignment extends FoldableContainer


#region State

signal assign_job_requested(job_index: int)

@onready var _job_buttons: VBoxContainer = $Details/Jobs
@onready var _unassign_button: Button = $Details/Unassign

#endregion


#region Initialization

func _ready() -> void:
	_unassign_button.pressed.connect(
		assign_job_requested.emit.bind(-1)
	)

#endregion


#region Display

func display_available_jobs(job_titles: Array[String]) -> void:
	for child in _job_buttons.get_children():
		_job_buttons.remove_child(child)
		child.queue_free()

	for job_index in range(job_titles.size()):
		var button := Button.new()
		button.text = job_titles[job_index]
		button.pressed.connect(
			assign_job_requested.emit.bind(job_index)
		)
		_job_buttons.add_child(button)

#endregion
