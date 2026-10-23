extends AnimatableBody3D
class_name VanishingPlatform
## Plataforma fantasma: fica sólida, pisca como aviso e some por alguns instantes.

@export var cycle := 3.2
@export var on_time := 1.85
@export var warn_time := 0.55
@export var off_time := 0.8
@export var phase := 0.0

var _time := 0.0
var _mesh: MeshInstance3D
var _material: StandardMaterial3D
var _solid := true


func _ready() -> void:
	sync_to_physics = true


func build(size: Vector3, color: Color) -> void:
	_material = ObstacleKit.material(color, 0.15).duplicate()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = 1.0
	_mesh = ObstacleKit.add_box(self, size, Vector3.ZERO, _material)
	var edge := ObstacleKit.add_box(
		self,
		Vector3(size.x + 0.1, 0.12, size.z + 0.1),
		Vector3(0, -size.y * 0.5 + 0.06, 0),
		ObstacleKit.material(color.lightened(0.4), 1.0)
	)
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ObstacleKit.add_collision_box(self, size)


func _physics_process(delta: float) -> void:
	_time += delta
	var t := fmod(_time + phase, cycle)
	var solid := true
	var alpha := 1.0
	if t < on_time:
		alpha = 1.0
	elif t < on_time + warn_time:
		# Aviso: pisca cada vez mais rápido.
		var warn_progress := (t - on_time) / warn_time
		var blink := sin((t - on_time) * (18.0 + warn_progress * 26.0))
		alpha = 0.55 + blink * 0.45
		solid = true
	else:
		alpha = 0.10
		solid = false

	if solid != _solid:
		_solid = solid
		collision_layer = 1 if solid else 0
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if solid else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material.albedo_color.a = alpha
