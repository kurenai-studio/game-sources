extends AnimatableBody3D
class_name MovingPlatform
## Plataforma que vai e volta entre dois pontos. Funciona como piso móvel.

@export var travel := Vector3.ZERO
@export var speed := 1.4
@export var phase := 0.0

var _start := Vector3.ZERO
var _time := 0.0
var _visual: Node3D


func _ready() -> void:
	sync_to_physics = true
	_start = position
	_time = phase


func build(size: Vector3, color: Color) -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var mat := ObstacleKit.material(color, 0.22)
	ObstacleKit.add_box(_visual, size, Vector3.ZERO, mat)
	var rim := ObstacleKit.add_box(
		_visual,
		Vector3(size.x + 0.16, 0.2, size.z + 0.16),
		Vector3(0, -size.y * 0.5 + 0.1, 0),
		ObstacleKit.material(color.lightened(0.32), 0.7)
	)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Listras de alerta nas laterais
	var stripe := ObstacleKit.material(Color("fff3d6"), 1.2)
	for side in [-1.0, 1.0]:
		ObstacleKit.add_box(
			_visual,
			Vector3(size.x * 0.62, 0.1, 0.06),
			Vector3(0, -size.y * 0.34, (size.z * 0.5 + 0.035) * side),
			stripe
		)
	ObstacleKit.add_collision_box(self, size)


func _physics_process(delta: float) -> void:
	_time += delta * speed
	var weight := (sin(_time) + 1.0) * 0.5
	position = _start + travel * weight
