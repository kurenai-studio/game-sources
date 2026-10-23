extends Node3D
class_name Checkpoint
## Bandeira de checkpoint. Ativa uma vez e passa a ser o ponto de renascimento.

@export var index := 1
@export var respawn_point := Vector3.ZERO
@export var title := "checkpoint_label"

var active := false
var _flag_pivot: Node3D
var _flag_mesh: MeshInstance3D
var _flag_material: StandardMaterial3D
var _label: Label3D
var _ring: MeshInstance3D
var _time := 0.0


func build(accent := Color("47e0c0")) -> void:
	var base_mat := ObstacleKit.material(Color("1a2338"), 0.0)
	var steel := ObstacleKit.material(Color("8a93b5"), 0.05)

	ObstacleKit.add_cylinder(self, 1.25, 0.12, Vector3(0, 0.06, 0), base_mat, 36)
	_ring = ObstacleKit.add_cylinder(
		self,
		1.25,
		0.05,
		Vector3(0, 0.14, 0),
		ObstacleKit.material(accent.darkened(0.25), 0.6),
		36
	)

	ObstacleKit.add_cylinder(self, 0.065, 3.1, Vector3(1.05, 1.55, 0), steel, 14)
	ObstacleKit.add_cylinder(self, 0.13, 0.18, Vector3(1.05, 3.1, 0), ObstacleKit.material(Color("ffd166"), 1.2), 16)

	_flag_pivot = Node3D.new()
	_flag_pivot.position = Vector3(1.05, 2.92, 0)
	add_child(_flag_pivot)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.35, 0.8)
	_flag_material = StandardMaterial3D.new()
	_flag_material.albedo_color = accent.darkened(0.1)
	_flag_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flag_material.roughness = 0.75
	_flag_material.emission_enabled = true
	_flag_material.emission = accent
	_flag_material.emission_energy_multiplier = 0.12
	_flag_mesh = MeshInstance3D.new()
	_flag_mesh.mesh = quad
	_flag_mesh.material_override = _flag_material
	_flag_mesh.position = Vector3(0.7, 0, 0)
	_flag_pivot.add_child(_flag_mesh)

	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.75
	cylinder.height = 2.4
	shape.shape = cylinder
	shape.position.y = 1.2
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

	_label = ObstacleKit.add_label(self, Loc.t(title, [index]), Vector3(0, 3.7, 0), Color("c9d3ee"), 46, 0.0095)
	Loc.bind_text(_label, title, [index])


func _process(delta: float) -> void:
	_time += delta
	_flag_pivot.rotation.y = sin(_time * 1.7) * 0.12
	_flag_mesh.position.y = sin(_time * 2.1) * 0.035
	if not active:
		_ring.scale = Vector3.ONE * (1.0 + sin(_time * 2.0) * 0.03)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		_label.visible = global_position.distance_to(player.global_position) < 24.0


func _on_body_entered(body: Node3D) -> void:
	if active or not (body is TuxPlayer):
		return
	activate()


func activate() -> void:
	active = true
	_flag_material.albedo_color = Color("53f0c8")
	_flag_material.emission_enabled = true
	_flag_material.emission = Color("2bd6a8")
	_flag_material.emission_energy_multiplier = 0.7
	_label.modulate = Color("7dffdf")
	_ring.material_override = ObstacleKit.glow_material(Color("53f0c8"), 1.4)
	var tween := create_tween()
	tween.tween_property(_flag_pivot, "scale", Vector3(1.25, 1.25, 1.25), 0.12)
	tween.tween_property(_flag_pivot, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	_burst()
	Sfx.play("checkpoint", -3.0)
	get_tree().call_group("game", "reach_checkpoint", index, respawn_point)


func _burst() -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 36
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 55.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 6.0
	particles.gravity = Vector3(0, -7, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.2
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.radial_segments = 6
	mesh.rings = 3
	particles.mesh = mesh
	particles.material_override = ObstacleKit.glow_material(Color("7dffdf"), 2.5)
	particles.position.y = 1.4
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(2.0).timeout.connect(particles.queue_free)
