extends Node3D
class_name PolaroidCameraTool

signal photo_taken(photo_data: Dictionary)
signal camera_aim_toggled(is_aiming: bool)

@export var raycast: RayCast3D
@export var flash_light: OmniLight3D

var is_aiming: bool = false
var active_photo: Dictionary = {}
var anchored_doorway: ShiftDoorway = null

func _ready():
	if flash_light:
		flash_light.visible = false

func toggle_aim() -> void:
	set_aim(not is_aiming)

func set_aim(aiming: bool) -> void:
	is_aiming = aiming
	camera_aim_toggled.emit(is_aiming)

func snap_photo(current_time_str: String = "00:00 AM") -> Dictionary:
	if FacilitySoundManager.instance:
		FacilitySoundManager.instance.play("polaroid_snap", 1.0, 3.0)
		
	# Quick flash animation
	if flash_light:
		flash_light.visible = true
		var tween = create_tween()
		tween.tween_property(flash_light, "light_energy", 6.0, 0.05)
		tween.tween_property(flash_light, "light_energy", 0.0, 0.2)
		tween.tween_callback(func(): flash_light.visible = false)

	var target_label = "SECTOR VIEW"
	var target_doorway: ShiftDoorway = null
	
	if raycast and raycast.is_colliding():
		var col = raycast.get_collider()
		if col is ShiftDoorway:
			target_doorway = col
		elif col.get_parent() is ShiftDoorway:
			target_doorway = col.get_parent()

	if target_doorway:
		# If another doorway was anchored, release it
		if anchored_doorway and anchored_doorway != target_doorway:
			anchored_doorway.set_anchored(false)
			
		target_doorway.set_anchored(true)
		anchored_doorway = target_doorway
		target_label = target_doorway.doorway_name + "\n[QUANTUM ANCHORED]"
	else:
		target_label = "FACILITY CORRIDOR\n[NO ANCHOR DETECTED]"

	active_photo = {
		"title": target_label,
		"time": current_time_str,
		"is_anchored": (target_doorway != null),
		"doorway_id": target_doorway.doorway_id if target_doorway else ""
	}
	
	photo_taken.emit(active_photo)
	return active_photo
