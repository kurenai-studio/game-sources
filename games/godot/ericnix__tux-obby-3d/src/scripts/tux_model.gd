extends Node3D
class_name TuxModel
## Tux, o pinguim, feito inteiramente com primitivas 3D + animação procedural.

var _bounce: Node3D
var _spin: Node3D
var _feet: Array[MeshInstance3D] = []
var _foot_base: Array[Vector3] = []
var _flippers: Array[Node3D] = []
var _eyes: Array[MeshInstance3D] = []
var _eye_base: Array[Vector3] = []
var _walk_phase := 0.0
var _idle_time := 0.0
var _blink_timer := 3.0
var _blink_anim := 0.0

var mat_black: StandardMaterial3D
var mat_white: StandardMaterial3D
var mat_orange: StandardMaterial3D
var mat_dark: StandardMaterial3D


func _ready() -> void:
	_build()


func _build() -> void:
	mat_black = _material(Color("3d3d50"), 0.52, 0.0)
	mat_white = _material(Color("fffdf8"), 0.72, 0.0)
	mat_white.emission_enabled = true
	mat_white.emission = Color("fff8ee")
	mat_white.emission_energy_multiplier = 0.26
	mat_orange = _material(Color("ff9a2e"), 0.55, 0.0)
	mat_orange.emission_enabled = true
	mat_orange.emission = Color("ff7a1a")
	mat_orange.emission_energy_multiplier = 0.25
	mat_dark = _material(Color("0b0b12"), 0.4, 0.0)

	_bounce = Node3D.new()
	_bounce.name = "Bounce"
	add_child(_bounce)
	_spin = Node3D.new()
	_spin.name = "Spin"
	_bounce.add_child(_spin)

	var body := Node3D.new()
	body.name = "Body"
	_spin.add_child(body)

	# Corpo e cabeça
	_sphere(body, 0.56, Vector3(0, 0.78, 0), Vector3(1.0, 1.16, 0.92), mat_black, 32, 20)
	_sphere(body, 0.40, Vector3(0, 1.32, -0.02), Vector3(1.0, 1.0, 0.96), mat_black, 32, 20)

	# Barriga branca (levemente para fora do corpo preto)
	_sphere(body, 0.46, Vector3(0, 0.74, -0.29), Vector3(0.93, 1.18, 0.55), mat_white, 28, 18)
	# Rosto branco
	_sphere(body, 0.30, Vector3(0, 1.30, -0.29), Vector3(1.02, 0.92, 0.50), mat_white, 24, 16)

	# Bico
	var beak := _cone(body, 0.145, 0.29, mat_orange, Vector3(0, 1.27, -0.47), 18)
	beak.rotation.x = -PI * 0.5
	beak.name = "Beak"

	# Olhos
	for side in [-1.0, 1.0]:
		var white := _sphere(body, 0.10, Vector3(0.155 * side, 1.44, -0.395), Vector3(0.92, 1.22, 0.55), mat_white, 20, 14)
		white.name = "Eye"
		_eyes.append(white)
		_eye_base.append(white.scale)
		var pupil := _sphere(body, 0.048, Vector3(0.152 * side, 1.427, -0.440), Vector3(1.0, 1.22, 0.55), mat_dark, 16, 10)
		pupil.name = "Pupil"
		_eyes.append(pupil)
		_eye_base.append(pupil.scale)
		_sphere(body, 0.017, Vector3(0.135 * side, 1.455, -0.462), Vector3.ONE, mat_white, 10, 8)

	# Asas / nadadeiras
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.name = "Flipper"
		pivot.position = Vector3(0.51 * side, 1.05, 0.02)
		_spin.add_child(pivot)
		var wing := _sphere(pivot, 0.35, Vector3(0, -0.33, 0), Vector3(0.33, 1.25, 0.56), mat_black, 22, 14)
		wing.name = "FlipperMesh"
		pivot.rotation.z = 0.1 * side
		_flippers.append(pivot)

	# Pés
	for side in [-1.0, 1.0]:
		var foot := _sphere(_spin, 0.20, Vector3(0.205 * side, 0.065, -0.10), Vector3(0.85, 0.30, 1.55), mat_orange, 20, 12)
		foot.name = "Foot"
		_feet.append(foot)
		_foot_base.append(foot.position)

	# Rabinho
	var tail := _cone(_spin, 0.17, 0.32, mat_black, Vector3(0, 0.50, 0.45), 12)
	tail.rotation.x = PI * 0.5
	tail.name = "Tail"


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.metallic_specular = 0.25
	return mat


func _sphere(parent: Node3D, radius: float, pos: Vector3, scl: Vector3, mat: Material, segs := 24, rings := 16) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segs
	mesh.rings = rings
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.layers = 2
	node.position = pos
	node.scale = scl
	parent.add_child(node)
	return node


func _cone(parent: Node3D, radius: float, height: float, mat: Material, pos: Vector3, segs := 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segs
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.layers = 2
	node.position = pos
	parent.add_child(node)
	return node


func update_animation(velocity: Vector3, on_floor: bool, delta: float) -> void:
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	var run_amt := clampf(planar_speed / 7.0, 0.0, 1.35)
	_idle_time += delta
	_walk_phase += delta * (4.0 + planar_speed * 1.65)

	# Balanço de caminhada + respiração parada
	var bob := sin(_walk_phase * 2.0) * 0.045 * run_amt
	var idle := sin(_idle_time * 1.8) * 0.012 * (1.0 - minf(run_amt, 1.0))
	_bounce.position.y = bob + idle
	_bounce.rotation.z = sin(_walk_phase) * 0.11 * run_amt
	_bounce.rotation.x = sin(_walk_phase * 2.0) * 0.025 * run_amt
	var lean := -0.10 * minf(run_amt, 1.0) if on_floor else -0.03
	rotation.x = lerpf(rotation.x, lean, minf(1.0, delta * 8.0))

	# Pés alternando
	for i in _feet.size():
		var foot := _feet[i]
		var sway := sin(_walk_phase + (PI if i == 0 else 0.0))
		foot.position.z = _foot_base[i].z + sway * 0.13 * run_amt
		foot.position.y = _foot_base[i].y + maxf(0.0, sway) * 0.10 * run_amt
		foot.rotation.x = -sway * 0.35 * run_amt

	# Nadadeiras: abertas no ar, remando no chão
	var open_angle := 1.15 if not on_floor else 0.12
	var flap := sin(_walk_phase * 1.0) * (0.05 + 0.18 * run_amt) if on_floor else sin(_idle_time * 16.0) * 0.12
	for i in _flippers.size():
		var side := -1.0 if i == 0 else 1.0
		var target := (open_angle + flap) * side
		_flippers[i].rotation.z = lerp_angle(_flippers[i].rotation.z, target, minf(1.0, delta * 12.0))

	# Piscada
	_blink_timer -= delta
	if _blink_timer <= 0.0 and _blink_anim <= 0.0:
		_blink_anim = 0.001
	if _blink_anim > 0.0:
		_blink_anim += delta
		var phase := clampf(_blink_anim / 0.19, 0.0, 1.0)
		var factor := 1.0 - sin(phase * PI) * 0.88
		for i in _eyes.size():
			_eyes[i].scale.y = _eye_base[i].y * factor
		if phase >= 1.0:
			_blink_anim = 0.0
			_blink_timer = randf_range(3.0, 6.5)


func double_jump_spin() -> void:
	_spin.rotation.y = 0.0
	var tween := create_tween()
	tween.tween_property(_spin, "rotation:y", TAU, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func stretch(amount: float = 0.35) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0 - amount * 0.28, 1.0 + amount * 0.35, 1.0 - amount * 0.28), 0.09)
	tween.tween_property(self, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func squash(amount: float = 0.35) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0 + amount * 0.4, 1.0 - amount * 0.45, 1.0 + amount * 0.4), 0.08)
	tween.tween_property(self, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func play_death() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation:z", 2.4, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func reset_visuals() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation:z", 0.0, 0.22)
	_bounce.position.y = 0.0
	_bounce.rotation = Vector3.ZERO
	_spin.rotation.y = 0.0
