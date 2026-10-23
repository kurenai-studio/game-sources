extends Node3D
class_name BouncePad
## Trampolim: arremessa o Tux para plataformas altas.

@export var power := 18.5

var _pad: Node3D
var _ring: MeshInstance3D
var _cooldown := 0.0


func build(color := Color("6bff9e")) -> void:
	var base_mat := ObstacleKit.material(Color("173a2c"), 0.1)
	var glow := ObstacleKit.glow_material(color, 1.8)

	ObstacleKit.add_cylinder(self, 1.15, 0.12, Vector3(0, -0.02, 0), base_mat, 32)
	_pad = Node3D.new()
	_pad.position.y = 0.1
	add_child(_pad)
	ObstacleKit.add_cylinder(_pad, 0.92, 0.16, Vector3.ZERO, glow, 32)

	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.84
	torus.rings = 28
	torus.ring_segments = 12
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.material_override = ObstacleKit.glow_material(Color("e9fff2"), 2.6)
	_ring.position.y = 0.19
	_ring.rotation.x = 0.0
	add_child(_ring)

	# Setas apontando para cima
	var arrow_mat := ObstacleKit.glow_material(Color("e9fff2"), 2.0)
	for i in 3:
		var angle := i * TAU / 3.0
		var arrow := ObstacleKit.add_box(
			_pad,
			Vector3(0.10, 0.05, 0.38),
			Vector3(cos(angle) * 0.45, 0.1, sin(angle) * 0.45),
			arrow_mat
		)
		arrow.rotation.y = -angle

	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.4, 2.2)
	shape.shape = box
	shape.position.y = 0.7
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_ring.rotation.y += delta * 0.7
	_ring.position.y = 0.19 + sin(Time.get_ticks_msec() * 0.004) * 0.025


func _on_body_entered(body: Node3D) -> void:
	if not (body is TuxPlayer) or _cooldown > 0.0:
		return
	_cooldown = 0.45
	body.bounce(power)
	Sfx.play("bounce", -5.0, randf_range(0.94, 1.06))
	var tween := create_tween()
	tween.tween_property(_pad, "scale:y", 0.35, 0.07)
	tween.tween_property(_pad, "scale:y", 1.0, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
