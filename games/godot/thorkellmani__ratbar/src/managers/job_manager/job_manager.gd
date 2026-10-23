extends Node2D

class_name JobManager

signal job_assignment_changed(rat_id: int)

var _ASSIGNED_JOBS: Dictionary[int, Job] = {}

func get_jobs() -> Array[Job]:
	var jobs: Array[Job] = []
	for child in get_children():
		if child is Job:
			jobs.append(child)
		
	return jobs


func get_assigned_job(rat_id: int) -> Job:
	return _ASSIGNED_JOBS.get(rat_id)


func get_assigned_job_title(rat_id: int) -> String:
	var job: Job = _ASSIGNED_JOBS.get(rat_id)

	return job.title if job != null else ""


func get_assigned_job_location_ids(
	rat_id: int
) -> Array[StringName]:
	var location_ids: Array[StringName] = []
	var job: Job = _ASSIGNED_JOBS.get(rat_id)

	if job == null:
		return location_ids

	for location in job.locations:
		location_ids.append(location.location_id)

	return location_ids


func unassign_job(rat_id: int) -> void:
	if not _ASSIGNED_JOBS.has(rat_id):
		return

	_ASSIGNED_JOBS.erase(rat_id)
	print("Clearing assigned job from rat ", rat_id)
	job_assignment_changed.emit(rat_id)


func assign_job(rat_id: int, job: Job) -> void:
	if _ASSIGNED_JOBS.get(rat_id) == job:
		return

	_ASSIGNED_JOBS[rat_id] = job
	print("Assigning job ", job.title, " to rat ", rat_id)
	job_assignment_changed.emit(rat_id)


func clear_all_jobs() -> void:
	var previously_assigned_rat_ids := _ASSIGNED_JOBS.keys()
	_ASSIGNED_JOBS.clear()

	for rat_id in previously_assigned_rat_ids:
		job_assignment_changed.emit(rat_id)
