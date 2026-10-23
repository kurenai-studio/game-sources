extends RefCounted
class_name ObstacleKit
## Pequenos utilitários compartilhados para montar a geometria dos obstáculos.

static var _materials: Dictionary = {}


static func material(color: Color, emission := 0.0, roughness := 0.62) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), emission, roughness]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.05
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	_materials[key] = mat
	return mat


static func glow_material(color: Color, energy := 1.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.3
	return mat


static func add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node


static func add_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, segments := 28) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node


static func add_collision_box(parent: CollisionObject3D, size: Vector3, pos := Vector3.ZERO) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = pos
	parent.add_child(node)
	return node


static func add_collision_cylinder(parent: CollisionObject3D, radius: float, height: float, pos := Vector3.ZERO) -> CollisionShape3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = pos
	parent.add_child(node)
	return node


static func add_label(parent: Node3D, text: String, pos: Vector3, color: Color, size := 64, pixel := 0.011) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = color
	label.outline_modulate = Color(0.03, 0.03, 0.08, 1.0)
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	parent.add_child(label)
	return label
