extends CharacterBody3D
class_name NightShiftPlayer

signal interacted_with(target: Node)
signal photo_inspection_toggled(is_inspecting: bool)

@export var move_speed: float = 4.2
@export var mouse_sensitivity: float = 0.0025
@export var gravity: float = 14.0

@onready var camera_mount: Node3D = $CameraMount
@onready var camera: Camera3D = $CameraMount/Camera3D
@onready var interact_raycast: RayCast3D = $CameraMount/Camera3D/InteractRayCast
@onready var camera_tool: PolaroidCameraTool = $CameraMount/Camera3D/PolaroidCameraTool
@onready var flashlight: SpotLight3D = $CameraMount/Camera3D/Flashlight

var held_power_cell: PowerCell = null
var footstep_timer: float = 0.0
var is_inspecting_photo: bool = false
var facility_ref: FacilityManager = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_mount.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	if event.is_action_pressed("raise_camera"):
		if camera_tool:
			camera_tool.toggle_aim()

	if event.is_action_pressed("take_photo"):
		if camera_tool:
			var time_str = facility_ref.get_formatted_time() if facility_ref else "00:00 AM"
			camera_tool.snap_photo(time_str)

	if event.is_action_pressed("toggle_flashlight"):
		if flashlight:
			flashlight.visible = not flashlight.visible
			if FacilitySoundManager.instance:
				FacilitySoundManager.instance.play("terminal_beep", 1.8, -10.0)

	if event.is_action_pressed("inspect_photo"):
		is_inspecting_photo = not is_inspecting_photo
		photo_inspection_toggled.emit(is_inspecting_photo)

	if event.is_action_pressed("interact"):
		_handle_interaction()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var move_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
		if is_on_floor():
			footstep_timer += delta
			if footstep_timer > 0.45:
				footstep_timer = 0.0
				if FacilitySoundManager.instance:
					FacilitySoundManager.instance.play("footstep_metal", randf_range(0.9, 1.1), -10.0)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	# Process carried power cell
	if held_power_cell:
		var hold_pos = camera.global_position + (-camera.global_transform.basis.z * 1.5) + (-camera.global_transform.basis.y * 0.4)
		held_power_cell.update_held_position(hold_pos)

func _handle_interaction():
	if camera_tool and camera_tool.is_aiming:
		var time_str = facility_ref.get_formatted_time() if facility_ref else "00:00 AM"
		camera_tool.snap_photo(time_str)
		return

	if not interact_raycast or not interact_raycast.is_colliding():
		return
		
	var col = interact_raycast.get_collider()
	
	# Power cell interaction
	if held_power_cell:
		if col is PowerSocket:
			if col.insert_cell():
				interact_raycast.remove_exception(held_power_cell)
				held_power_cell.queue_free()
				held_power_cell = null
				if facility_ref:
					facility_ref.resolve_ticket(2)
		else:
			interact_raycast.remove_exception(held_power_cell)
			held_power_cell.release()
			held_power_cell = null
	elif col is PowerCell:
		held_power_cell = col
		interact_raycast.add_exception(held_power_cell)
		held_power_cell.grab(self)
		if FacilitySoundManager.instance:
			FacilitySoundManager.instance.play("footstep_metal", 1.5, -4.0)
	elif col is CoolantValve:
		col.interact()
		if col.is_complete and facility_ref:
			facility_ref.resolve_ticket(1)
	elif col is OverrideConsole or col.is_in_group("containment_console"):
		col.interact()
		if facility_ref:
			facility_ref.resolve_ticket(3)
	elif col is MaintenanceTerminal:
		col.interact()
	elif col.name == "TimeClock" or col.is_in_group("exit_clock"):
		if facility_ref and facility_ref.are_all_tasks_done():
			facility_ref.complete_shift()
			
	interacted_with.emit(col)
