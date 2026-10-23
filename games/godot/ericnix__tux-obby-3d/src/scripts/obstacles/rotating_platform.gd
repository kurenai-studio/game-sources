extends AnimatableBody3D
class_name RotatingPlatform
## Disco que gira lentamente. Use o tempo certo para atravessar.

@export var rotation_speed := 0.9

var _visual: Node3D
var _time := 0.0


func _ready() -> void:
	sync_to_physics = true


func build(radius: float, height: float, color: Color) -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var meshes: Array[MeshInstance3D] = []
	var mat := ObstacleKit.material(color, 0.2)
	ObstacleKit.add_cylinder(_visual, radius, height, Vector3.ZERO, mat, 40)
	var rim := ObstacleKit.add_cylinder(
		_visual,
		radius + 0.08,
		0.12,
		Vector3(0, -height * 0.5 + 0.06, 0),
		ObstacleKit.glow_material(color.lightened(0.35), 0.9),
		40
	)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Marcações no topo para o giro ficar evidente
	var mark := ObstacleKit.material(color.darkened(0.35), 0.0)
	for i in 3:
		var angle := i * TAU / 3.0
		var marker := ObstacleKit.add_box(
			_visual,
			Vector3(radius * 0.55, 0.04, 0.16),
			Vector3(cos(angle) * radius * 0.45, height * 0.5 + 0.02, sin(angle) * radius * 0.45),
			mark
		)
		marker.rotation.y = -angle
		meshes.append(marker)
	ObstacleKit.add_collision_cylinder(self, radius, height)


func _physics_process(delta: float) -> void:
	_time += delta
	rotation.y = rotation.y + rotation_speed * delta
	_visual.position.y = sin(_time * 1.4) * 0.03
