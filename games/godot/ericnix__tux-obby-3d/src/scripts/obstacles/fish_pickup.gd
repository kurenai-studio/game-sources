extends Area3D
class_name FishPickup
## Peixinho colecionável. Gira, flutua e some com um "pop".

var _visual: Node3D
var _time := 0.0
var _base_y := 0.0
var _collected := false


func _ready() -> void:
	_time = randf() * TAU
	_base_y = position.y


func build() -> void:
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.62
	shape.shape = sphere
	add_child(shape)

	_visual = Node3D.new()
	add_child(_visual)
	var gold := ObstacleKit.glow_material(Color("ffb03a"), 1.4)
	var orange := ObstacleKit.glow_material(Color("ff7a2f"), 1.0)
	var dark := ObstacleKit.material(Color("1b1626"), 0.0)

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.30
	body_mesh.height = 0.6
	body_mesh.radial_segments = 20
	body_mesh.rings = 12
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = gold
	body.scale = Vector3(1.45, 0.85, 0.5)
	_visual.add_child(body)

	var tail := CylinderMesh.new()
	tail.top_radius = 0.0
	tail.bottom_radius = 0.2
	tail.height = 0.34
	tail.radial_segments = 3
	tail.rings = 1
	var tail_node := MeshInstance3D.new()
	tail_node.mesh = tail
	tail_node.material_override = orange
	tail_node.position = Vector3(0.48, 0, 0)
	tail_node.rotation.z = -PI * 0.5
	_visual.add_child(tail_node)

	var fin := BoxMesh.new()
	fin.size = Vector3(0.26, 0.3, 0.03)
	var fin_node := MeshInstance3D.new()
	fin_node.mesh = fin
	fin_node.material_override = orange
	fin_node.position = Vector3(0.02, 0.26, 0)
	fin_node.rotation.z = 0.3
	_visual.add_child(fin_node)

	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.05
		eye.height = 0.1
		var eye_node := MeshInstance3D.new()
		eye_node.mesh = eye
		eye_node.material_override = dark
		eye_node.position = Vector3(-0.24, 0.05, 0.24 * side)
		_visual.add_child(eye_node)

	var light := OmniLight3D.new()
	light.light_color = Color("ffbb55")
	light.light_energy = 0.9
	light.omni_range = 3.0
	add_child(light)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += delta * 1.8
	position.y = _base_y + sin(_time * 2.2) * 0.09


func _on_body_entered(body: Node3D) -> void:
	if _collected or not (body is TuxPlayer):
		return
	_collected = true
	set_deferred("monitoring", false)
	Sfx.play("fish", -5.0, randf_range(0.97, 1.06))
	get_tree().call_group("game", "collect_fish")
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.6, 1.6, 1.6), 0.08)
	tween.tween_property(_visual, "scale", Vector3.ZERO, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
