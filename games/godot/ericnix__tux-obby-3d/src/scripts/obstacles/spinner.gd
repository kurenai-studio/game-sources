extends Node3D
class_name Spinner
## Barra giratória mortal. Pule no tempo certo ou volte para o checkpoint.

@export var rotation_speed := 1.25
@export var bar_length := 6.4
@export var bar_count := 1

var _area: Area3D
var _time := 0.0


func build(color := Color("ff4f5e")) -> void:
	var hazard_mat := ObstacleKit.glow_material(color, 2.2)
	var dark_mat := ObstacleKit.material(Color("221c2e"), 0.0)
	var cap_mat := ObstacleKit.glow_material(Color("ffd166"), 2.5)

	_area = Area3D.new()
	_area.name = "Hazard"
	_area.collision_layer = 4
	_area.collision_mask = 2
	_area.monitorable = false
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)

	for i in bar_count:
		var holder := Node3D.new()
		holder.rotation.y = i * PI / bar_count
		add_child(holder)

		ObstacleKit.add_box(holder, Vector3(bar_length, 0.34, 0.34), Vector3.ZERO, hazard_mat)
		ObstacleKit.add_box(holder, Vector3(bar_length * 0.62, 0.07, 0.36), Vector3(0, 0.18, 0), dark_mat)
		ObstacleKit.add_box(holder, Vector3(bar_length * 0.62, 0.07, 0.36), Vector3(0, -0.18, 0), dark_mat)
		for side in [-1.0, 1.0]:
			ObstacleKit.add_cylinder(holder, 0.24, 0.42, Vector3(bar_length * 0.5 * side, 0, 0), cap_mat, 16)

		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(bar_length, 0.42, 0.42)
		shape.shape = box
		_area.add_child(shape)

	# Mastro central
	ObstacleKit.add_cylinder(self, 0.16, 1.6, Vector3(0, -0.9, 0), dark_mat, 20)
	ObstacleKit.add_cylinder(self, 0.34, 0.55, Vector3.ZERO, hazard_mat, 24)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.6
	light.omni_range = 4.5
	light.position.y = 0.4
	add_child(light)


func _physics_process(delta: float) -> void:
	_time += delta
	rotation.y += rotation_speed * delta
	position.y += sin(_time * 2.0) * 0.0006


func _on_body_entered(body: Node3D) -> void:
	if body is TuxPlayer:
		body.kill()
