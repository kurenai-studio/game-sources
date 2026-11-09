extends Area3D
class_name PressurePlate

signal activated(is_active: bool)

@export var required_weight: float = 30.0 # Standard cube is 10kg, scaled 2x is 80kg
@export var is_toggle: bool = false

@onready var plate_mesh: MeshInstance3D = get_node_or_null("PlateMesh")

var bodies_on_plate = []
var is_pressed: bool = false
var original_plate_y: float = 0.1

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if plate_mesh:
		original_plate_y = plate_mesh.position.y
	_update_visuals(false)

func _process(_delta):
	check_activation()

func evaluate_weight() -> float:
	var total_weight = 0.0
	for body in bodies_on_plate:
		if is_instance_valid(body):
			if body is ShiftCube:
				total_weight += body.mass
			elif body is CharacterBody3D:
				total_weight += 70.0 # Player weight
	return total_weight

func check_activation() -> bool:
	var should_press = (evaluate_weight() >= required_weight)
	if should_press != is_pressed:
		is_pressed = should_press
		_update_visuals(is_pressed)
		if SoundManager.instance:
			SoundManager.instance.play("button_click", 1.0 if is_pressed else 0.8, -2.0)
		activated.emit(is_pressed)
	return is_pressed

func _on_body_entered(body: Node3D):
	if not bodies_on_plate.has(body):
		bodies_on_plate.append(body)
		check_activation()

func _on_body_exited(body: Node3D):
	if bodies_on_plate.has(body):
		bodies_on_plate.erase(body)
		check_activation()

func _update_visuals(active: bool):
	if plate_mesh:
		if is_inside_tree():
			var target_y = original_plate_y - 0.08 if active else original_plate_y
			var tween = create_tween()
			if tween:
				tween.tween_property(plate_mesh, "position:y", target_y, 0.15)
		else:
			plate_mesh.position.y = original_plate_y - 0.08 if active else original_plate_y
		
		var mat = plate_mesh.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			mat = mat.duplicate()
			mat.emission_enabled = true
			if active:
				mat.albedo_color = Color(0.2, 1.0, 0.4)
				mat.emission = Color(0.1, 0.9, 0.3)
				mat.emission_energy_multiplier = 2.5
			else:
				mat.albedo_color = Color(1.0, 0.3, 0.2)
				mat.emission = Color(0.8, 0.1, 0.1)
				mat.emission_energy_multiplier = 1.0
			plate_mesh.set_surface_override_material(0, mat)
