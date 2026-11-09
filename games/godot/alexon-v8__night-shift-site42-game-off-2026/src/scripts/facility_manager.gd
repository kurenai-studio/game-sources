extends Node
class_name FacilityManager

signal time_updated(time_str: String)
signal ticket_updated(ticket_id: int, status: String)
signal shift_completed

var current_minutes: int = 0 # 0 = 12:00 AM, 360 = 06:00 AM
var tickets = [
	{"id": 1, "title": "Coolant Subsystem Alpha Pressure Leak", "status": "PENDING", "loc": "Coolant Sector"},
	{"id": 2, "title": "Sector B Auxiliary Power Failure", "status": "PENDING", "loc": "Power Grid"},
	{"id": 3, "title": "Containment Latch 04 Structural Drift", "status": "PENDING", "loc": "Containment Wing 04"},
	{"id": 4, "title": "Punch Out & Elevator Extraction", "status": "LOCKED", "loc": "Central Security Hub"}
]

func _ready():
	_broadcast_time()

func advance_time(mins: int):
	current_minutes = min(360, current_minutes + mins)
	_broadcast_time()
	if current_minutes >= 360 and are_all_tasks_done():
		tickets[3]["status"] = "AVAILABLE"
		ticket_updated.emit(4, "AVAILABLE")

func get_formatted_time() -> String:
	var total_hours = (current_minutes / 60)
	var mins = current_minutes % 60
	var display_hour = 12 if total_hours == 0 else total_hours
	return "%02d:%02d AM" % [display_hour, mins]

func _broadcast_time():
	time_updated.emit(get_formatted_time())

func resolve_ticket(ticket_id: int):
	for t in tickets:
		if t["id"] == ticket_id:
			t["status"] = "RESOLVED"
			ticket_updated.emit(ticket_id, "RESOLVED")
			
	match ticket_id:
		1: advance_time(90)  # to 01:30 AM
		2: advance_time(120) # to 03:30 AM
		3: advance_time(150) # to 06:00 AM
		
	if are_all_tasks_done():
		tickets[3]["status"] = "AVAILABLE"
		ticket_updated.emit(4, "AVAILABLE")

func are_all_tasks_done() -> bool:
	return tickets[0]["status"] == "RESOLVED" and tickets[1]["status"] == "RESOLVED" and tickets[2]["status"] == "RESOLVED"

func complete_shift():
	if are_all_tasks_done():
		tickets[3]["status"] = "RESOLVED"
		ticket_updated.emit(4, "RESOLVED")
		shift_completed.emit()
