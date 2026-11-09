extends Node3D
class_name MainGame

@onready var facility_manager: FacilityManager = $FacilityManager
@onready var player: NightShiftPlayer = $Player
@onready var ui: NightShiftUI = $UI_Layer/UI
@onready var doorway_coolant: ShiftDoorway = $ShiftDoorway_Coolant

func _ready():
	if player and facility_manager:
		player.facility_ref = facility_manager
		
	if facility_manager and ui:
		facility_manager.time_updated.connect(ui.update_time)
		facility_manager.ticket_updated.connect(func(_id, _status): ui.update_tickets(facility_manager.tickets))
		facility_manager.shift_completed.connect(ui.show_shift_complete)
		ui.update_tickets(facility_manager.tickets)
		
	if player and player.camera_tool and ui:
		player.camera_tool.photo_taken.connect(ui.on_photo_taken)
		player.camera_tool.camera_aim_toggled.connect(ui.set_aiming)

	# Connect containment override console if present
	var console = get_node_or_null("Containment04/OverrideConsole")
	if console:
		if console.has_signal("console_activated"):
			console.console_activated.connect(func(): facility_manager.resolve_ticket(3))
		elif console.has_signal("valve_stabilized"):
			console.valve_stabilized.connect(func(): facility_manager.resolve_ticket(3))

func _input(event: InputEvent):
	if event.is_action_pressed("toggle_help") and ui:
		ui.toggle_help()
