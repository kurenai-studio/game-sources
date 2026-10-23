extends Node3D
class_name Level
## Constrói o percurso completo do obby em tempo de execução.
## Tudo é feito com primitivas 3D, então o projeto não depende de assets externos.

const START_COLOR := Color("e9cd93")
const A_COLOR := Color("35c3a6")
const B_COLOR := Color("7f68f2")
const C_COLOR := Color("ed6250")
const D_COLOR := Color("f0b33f")
const E_COLOR := Color("3fa8e8")
const F_COLOR := Color("f0649f")
const G_COLOR := Color("8fd23e")
const FINISH_COLOR := Color("4cf0c0")

const ROCK_COLOR := Color("1a1527")
const KILL_Y := -4.0

var start_spawn := Vector3(0.0, 0.08, 2.2)
var checkpoint_spawns: Array[Vector3] = []
var total_fish := 0
var kill_y := KILL_Y

var _fish_created := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261022
	checkpoint_spawns.append(start_spawn)
	_build_lava()
	_build_decor()
	_build_start()
	_build_section_a()
	_build_section_b()
	_build_section_c()
	_build_section_d()
	_build_section_e()
	_build_section_f()
	_build_section_g()


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

func _platform(top: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Platform"
	body.position = top - Vector3(0.0, size.y * 0.5, 0.0)
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var mat := ObstacleKit.material(color, 0.10)
	ObstacleKit.add_box(body, size, Vector3.ZERO, mat)
	ObstacleKit.add_box(
		body,
		Vector3(size.x + 0.16, 0.16, size.z + 0.16),
		Vector3(0.0, -size.y * 0.5 + 0.10, 0.0),
		ObstacleKit.material(color.lightened(0.25), 0.55)
	)
	ObstacleKit.add_collision_box(body, size)

	# Base rochosa para dar volume de ilha flutuante.
	if maxf(size.x, size.z) <= 13.0:
		var rock := CylinderMesh.new()
		rock.top_radius = minf(size.x, size.z) * 0.46
		rock.bottom_radius = minf(size.x, size.z) * 0.12
		rock.height = 2.2 + size.y
		rock.radial_segments = 7
		rock.rings = 2
		var rock_node := MeshInstance3D.new()
		rock_node.mesh = rock
		rock_node.material_override = ObstacleKit.material(ROCK_COLOR, 0.0, 0.9)
		rock_node.position = Vector3(0.0, -size.y * 0.5 - rock.height * 0.5, 0.0)
		rock_node.rotation.y = _rng.randf_range(0.0, TAU)
		body.add_child(rock_node)
	return body


func _moving_platform(top: Vector3, size: Vector3, travel: Vector3, speed: float, color: Color) -> MovingPlatform:
	var body := MovingPlatform.new()
	body.name = "MovingPlatform"
	body.position = top - Vector3(0.0, size.y * 0.5, 0.0)
	body.travel = travel
	body.speed = speed
	body.phase = -PI * 0.5
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.build(size, color)
	return body


func _rotating_platform(top: Vector3, radius: float, height: float, speed: float, color: Color) -> RotatingPlatform:
	var body := RotatingPlatform.new()
	body.name = "RotatingPlatform"
	body.position = top - Vector3(0.0, height * 0.5, 0.0)
	body.rotation_speed = speed
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.build(radius, height, color)
	return body


func _vanishing_platform(top: Vector3, size: Vector3, color: Color, phase: float) -> VanishingPlatform:
	var body := VanishingPlatform.new()
	body.name = "VanishingPlatform"
	body.position = top - Vector3(0.0, size.y * 0.5, 0.0)
	body.phase = phase
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	body.build(size, color)
	return body


func _checkpoint(index: int, top: Vector3, title: String, spawn: Vector3, accent: Color) -> Checkpoint:
	var cp := Checkpoint.new()
	cp.index = index
	cp.title = title
	cp.respawn_point = spawn
	cp.position = top
	add_child(cp)
	cp.build(accent)
	checkpoint_spawns.append(spawn)
	return cp


func _spinner(pos: Vector3, length: float, speed: float, bars := 1) -> Spinner:
	var spinner := Spinner.new()
	spinner.position = pos
	spinner.bar_length = length
	spinner.rotation_speed = speed
	spinner.bar_count = bars
	add_child(spinner)
	spinner.build()
	return spinner


func _fish(pos: Vector3, parent: Node3D = null) -> void:
	var fish := FishPickup.new()
	fish.position = pos
	if parent == null:
		add_child(fish)
	else:
		parent.add_child(fish)
	fish.build()
	total_fish += 1
	_fish_created += 1


func _sign(key: String, pos: Vector3, color: Color) -> void:
	var label := ObstacleKit.add_label(self, Loc.t(key), pos, color, 48, 0.0085)
	Loc.bind_text(label, key)


# --------------------------------------------------------------------------
# Cenário
# --------------------------------------------------------------------------

func _build_lava() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(720, 720)
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 lava_color : source_color = vec4(0.09, 0.015, 0.025, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.46, 0.08, 1.0);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amp * noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz * 0.020;
	vec2 warp = vec2(
		fbm(uv * 1.7 + vec2(TIME * 0.014, 0.0)),
		fbm(uv * 1.7 + vec2(5.2, 1.3 - TIME * 0.011))
	);
	float flow = fbm(uv + warp * 0.7 + vec2(TIME * 0.016, -TIME * 0.013));
	float detail = fbm(uv * 3.1 - vec2(TIME * 0.021, TIME * 0.017));
	float heat = smoothstep(0.40, 0.82, flow * 0.78 + detail * 0.38);
	float cracks = smoothstep(0.60, 0.90, flow * 0.62 + detail * 0.64);
	vec3 col = mix(lava_color.rgb, vec3(0.42, 0.055, 0.02), heat);
	col = mix(col, hot_color.rgb, cracks * 0.9);
	col += vec3(1.0, 0.28, 0.02) * pow(cracks, 3.0) * 0.55;
	ALBEDO = col;
	EMISSION = col * (0.18 + heat * 0.55 + cracks * 0.6);
}
"""
	material.shader = shader
	plane.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = plane
	mesh.position = Vector3(0, -7.5, -80)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

	# Brasas subindo do vazio
	var embers := CPUParticles3D.new()
	embers.amount = 110
	embers.lifetime = 5.0
	embers.preprocess = 4.0
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3(55, 1.0, 90)
	embers.position = Vector3(0, -6.2, -80)
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 25.0
	embers.initial_velocity_min = 0.8
	embers.initial_velocity_max = 2.6
	embers.gravity = Vector3(0, 0.25, 0)
	embers.scale_amount_min = 0.4
	embers.scale_amount_max = 1.3
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	embers.mesh = quad
	var ember_mat := StandardMaterial3D.new()
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	ember_mat.albedo_color = Color(1.0, 0.55, 0.18, 0.7)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.45, 0.1)
	ember_mat.emission_energy_multiplier = 2.5
	embers.material_override = ember_mat
	add_child(embers)


func _build_decor() -> void:
	# Ilhas e rochas distantes para dar profundidade ao cenário.
	for i in 12:
		var side := -1.0 if i % 2 == 0 else 1.0
		var dist := _rng.randf_range(34.0, 80.0)
		var pos := Vector3(side * dist, _rng.randf_range(-17.0, 2.0), _rng.randf_range(25.0, -205.0))
		var rock := SphereMesh.new()
		rock.radius = _rng.randf_range(2.0, 5.0)
		rock.height = rock.radius * _rng.randf_range(0.7, 1.4)
		rock.radial_segments = 7
		rock.rings = 5
		var node := MeshInstance3D.new()
		node.mesh = rock
		node.material_override = ObstacleKit.material(ROCK_COLOR.lightened(_rng.randf_range(0.02, 0.12)), 0.0, 0.85)
		node.position = pos
		node.rotation = Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(0, TAU), _rng.randf_range(-0.4, 0.4))
		add_child(node)

		# Pequeno brilho em algumas ilhas
		if i % 4 == 0:
			var crystal := CylinderMesh.new()
			crystal.top_radius = 0.0
			crystal.bottom_radius = _rng.randf_range(0.4, 0.9)
			crystal.height = _rng.randf_range(2.0, 4.5)
			crystal.radial_segments = 5
			var crystal_node := MeshInstance3D.new()
			crystal_node.mesh = crystal
			crystal_node.material_override = ObstacleKit.glow_material(Color("7dffdf"), 1.6)
			crystal_node.position = pos + Vector3(0, rock.height * 0.5 + 1.0, 0)
			crystal_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(crystal_node)

	# Ilhas maiores, decorativas, preenchendo o vazio nas laterais.
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var center := Vector3(side * _rng.randf_range(32.0, 68.0), _rng.randf_range(-18.0, -6.0), _rng.randf_range(-70.0, -200.0))
		var radius := _rng.randf_range(4.0, 8.5)
		var island_root := Node3D.new()
		island_root.position = center
		add_child(island_root)
		var top := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = radius
		disc.bottom_radius = radius * 0.92
		disc.height = 1.0
		disc.radial_segments = 9
		top.mesh = disc
		top.material_override = ObstacleKit.material(Color("24484a"), 0.0, 0.9)
		island_root.add_child(top)
		var beneath := MeshInstance3D.new()
		var spike := CylinderMesh.new()
		spike.top_radius = radius * 0.9
		spike.bottom_radius = 0.6
		spike.height = 5.0
		spike.radial_segments = 7
		beneath.mesh = spike
		beneath.material_override = ObstacleKit.material(ROCK_COLOR, 0.0, 0.95)
		beneath.position.y = -2.8
		island_root.add_child(beneath)
		var beacon := MeshInstance3D.new()
		var beacon_mesh := CylinderMesh.new()
		beacon_mesh.top_radius = 0.0
		beacon_mesh.bottom_radius = 0.5
		beacon_mesh.height = 3.0
		beacon_mesh.radial_segments = 5
		beacon.mesh = beacon_mesh
		beacon.material_override = ObstacleKit.glow_material(A_COLOR, 1.1)
		beacon.position.y = 2.0
		beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		island_root.add_child(beacon)

	# Planeta gigante no céu, só para compor o cenário.
	var planet := Node3D.new()
	planet.position = Vector3(150, 118, -340)
	add_child(planet)
	var planet_mat := StandardMaterial3D.new()
	planet_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	planet_mat.albedo_color = Color("f6c9a0")
	planet_mat.emission_enabled = true
	planet_mat.emission = Color("ff9f70")
	planet_mat.emission_energy_multiplier = 0.65
	planet_mat.disable_fog = true
	var planet_mesh := SphereMesh.new()
	planet_mesh.radius = 26.0
	planet_mesh.height = 52.0
	planet_mesh.radial_segments = 40
	planet_mesh.rings = 24
	var planet_node := MeshInstance3D.new()
	planet_node.mesh = planet_mesh
	planet_node.material_override = planet_mat
	planet_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.add_child(planet_node)


func _build_start() -> void:
	_platform(Vector3(0, 0, 0), Vector3(9, 1.2, 9), START_COLOR)
	# Pilares decorativos nos cantos
	for x in [-3.7, 3.7]:
		for z in [-3.7, 3.7]:
			ObstacleKit.add_cylinder(self, 0.18, 2.2, Vector3(x, 1.1, z), ObstacleKit.material(Color("2a2440"), 0.1), 12)
			ObstacleKit.add_cylinder(self, 0.3, 0.18, Vector3(x, 2.3, z), ObstacleKit.glow_material(Color("7dffdf"), 1.5), 16)

	# Setas no chão apontando para o percurso
	for i in 3:
		var z := 1.6 - i * 1.15
		var left := ObstacleKit.add_box(self, Vector3(0.62, 0.02, 0.1), Vector3(-0.36, 0.02, z), ObstacleKit.glow_material(Color("7dffdf"), 1.2))
		var right := ObstacleKit.add_box(self, Vector3(0.62, 0.02, 0.1), Vector3(0.36, 0.02, z), ObstacleKit.glow_material(Color("7dffdf"), 1.2))
		left.rotation.y = -0.7
		right.rotation.y = 0.7

	_fish(Vector3(0, 1.25, -3.0))


func _build_section_a() -> void:
	_sign("section_warmup", Vector3(0, 4.9, -6.5), A_COLOR)
	_platform(Vector3(0, 0.25, -8.2), Vector3(3.6, 1.0, 3.6), A_COLOR)
	_platform(Vector3(1.8, 0.6, -13.6), Vector3(3.0, 1.0, 3.0), A_COLOR)
	_platform(Vector3(-1.8, 1.0, -18.8), Vector3(3.0, 1.0, 3.0), A_COLOR)
	_platform(Vector3(-1.8, 1.2, -23.8), Vector3(3.2, 1.0, 3.2), A_COLOR)

	_fish(Vector3(1.8, 1.75, -13.6))
	_fish(Vector3(-1.8, 2.15, -21.4))

	var cp_platform := _platform(Vector3(-1.8, 1.2, -28.8), Vector3(6, 1.2, 6), A_COLOR)
	_checkpoint(1, Vector3(-1.8, 1.2, -29.2), "checkpoint_label", Vector3(-1.8, 1.3, -27.2), A_COLOR)
	_fish(Vector3(-1.0, 2.35, -28.8))
	cp_platform.set_meta("section", "A")


func _build_section_b() -> void:
	_platform(Vector3(-1.8, 1.2, -37.0), Vector3(1.5, 0.9, 10.0), B_COLOR)
	_spinner(Vector3(-1.8, 1.95, -37.0), 6.4, 1.15)
	_fish(Vector3(-1.8, 2.35, -39.8))

	_platform(Vector3(-1.8, 1.2, -45.0), Vector3(5.5, 1.0, 5.0), B_COLOR)
	_fish(Vector3(-3.8, 2.35, -45.0))


func _build_section_c() -> void:
	var ferry1 := _moving_platform(Vector3(0, 1.35, -51.5), Vector3(4.2, 0.8, 4.2), Vector3(0, 0, -6.0), 0.9, C_COLOR)
	_fish(Vector3(0, 1.15, 0), ferry1)

	var island1 := _platform(Vector3(0, 1.35, -62.5), Vector3(5, 1.0, 5), C_COLOR)
	_fish(Vector3(1.5, 2.5, -62.5))
	island1.set_meta("section", "C")

	var ferry2 := _moving_platform(Vector3(0, 1.6, -68.5), Vector3(3.5, 0.8, 3.5), Vector3(5.0, 0, 0), 1.0, C_COLOR)
	_fish(Vector3(0, 1.15, 0), ferry2)

	_platform(Vector3(5.0, 1.8, -74.0), Vector3(5, 1.0, 5), C_COLOR)
	_checkpoint(2, Vector3(5.0, 1.8, -75.2), "checkpoint_label", Vector3(5.0, 1.9, -72.6), C_COLOR)
	_fish(Vector3(6.0, 2.95, -74.0))


func _build_section_d() -> void:
	_vanishing_platform(Vector3(5.0, 1.9, -79.5), Vector3(3, 0.8, 3), D_COLOR, 0.0)
	_vanishing_platform(Vector3(3.0, 2.1, -84.5), Vector3(3, 0.8, 3), D_COLOR, 0.65)
	_vanishing_platform(Vector3(6.0, 2.3, -89.5), Vector3(3, 0.8, 3), D_COLOR, 1.3)
	_vanishing_platform(Vector3(4.0, 2.5, -94.5), Vector3(3, 0.8, 3), D_COLOR, 1.95)
	_fish(Vector3(5.0, 3.05, -79.5))
	_fish(Vector3(3.0, 3.25, -84.5))
	_fish(Vector3(6.0, 3.45, -89.5))
	_fish(Vector3(4.0, 3.65, -94.5))

	_platform(Vector3(4.0, 2.6, -100.0), Vector3(6, 1.2, 6), D_COLOR)
	_checkpoint(3, Vector3(4.0, 2.6, -100.4), "checkpoint_label", Vector3(4.0, 2.7, -98.0), D_COLOR)
	_fish(Vector3(2.0, 3.75, -100.0))


func _build_section_e() -> void:
	_platform(Vector3(4.0, 2.6, -105.2), Vector3(4, 1.0, 4), E_COLOR)
	var pad := BouncePad.new()
	pad.position = Vector3(4.0, 2.6, -105.2)
	add_child(pad)
	pad.build()

	_platform(Vector3(4.0, 8.2, -109.5), Vector3(5, 1.2, 5), E_COLOR)
	_checkpoint(4, Vector3(4.0, 8.2, -110.6), "checkpoint_label", Vector3(4.0, 8.3, -108.2), E_COLOR)
	_fish(Vector3(2.0, 9.35, -110.0))

	var elevator := _moving_platform(Vector3(4.0, 8.2, -116.5), Vector3(4, 0.8, 4), Vector3(0, 5.4, 0), 0.75, E_COLOR)
	_fish(Vector3(0, 1.15, 0), elevator)

	_platform(Vector3(4.0, 13.6, -122.0), Vector3(5, 1.0, 5), E_COLOR)
	_fish(Vector3(6.0, 14.75, -122.0))


func _build_section_f() -> void:
	_platform(Vector3(5.5, 14.0, -127.0), Vector3(2.6, 2.2, 2.6), F_COLOR)
	_platform(Vector3(3.0, 14.5, -131.0), Vector3(2.6, 2.6, 2.6), F_COLOR)
	_platform(Vector3(6.0, 15.0, -135.0), Vector3(2.6, 3.0, 2.6), F_COLOR)
	_platform(Vector3(3.5, 15.4, -139.0), Vector3(2.6, 3.4, 2.6), F_COLOR)
	_fish(Vector3(3.0, 15.65, -131.0))
	_fish(Vector3(6.0, 16.15, -135.0))
	_fish(Vector3(3.5, 16.55, -139.0))

	_platform(Vector3(3.5, 15.6, -144.5), Vector3(7, 1.2, 7), F_COLOR)
	_checkpoint(5, Vector3(3.5, 15.6, -142.0), "checkpoint_label", Vector3(3.5, 15.7, -142.4), F_COLOR)
	_spinner(Vector3(3.5, 16.2, -146.0), 5.2, 1.35)
	_fish(Vector3(1.5, 16.75, -144.5))


func _build_section_g() -> void:
	_rotating_platform(Vector3(1.5, 15.8, -151.5), 2.6, 0.6, 0.85, G_COLOR)
	_fish(Vector3(1.5, 16.95, -151.5))
	_rotating_platform(Vector3(-1.5, 16.0, -157.0), 2.4, 0.6, -1.0, G_COLOR)
	_fish(Vector3(-1.5, 17.15, -157.0))

	var ferry3 := _moving_platform(Vector3(-1.5, 16.2, -161.5), Vector3(3.8, 0.9, 3.8), Vector3(3.5, 0, 0), 0.9, G_COLOR)
	_fish(Vector3(0, 1.1, 0), ferry3)

	_platform(Vector3(2.0, 16.4, -167.0), Vector3(9, 1.5, 8), FINISH_COLOR)
	var gate := FinishGate.new()
	gate.position = Vector3(2.0, 16.4, -168.8)
	add_child(gate)
	gate.build()
	_fish(Vector3(-0.3, 17.55, -167.0))

	# Plataformas de festa em volta da chegada
	for i in 4:
		var angle := i * TAU / 4.0
		var pos := Vector3(2.0 + cos(angle) * 7.5, 15.6 + (i % 2) * 1.2, -167.0 + sin(angle) * 5.5)
		_platform(pos, Vector3(2.2, 0.7, 2.2), FINISH_COLOR)


# --------------------------------------------------------------------------
# Utilidades para o resto do jogo
# --------------------------------------------------------------------------

func format_position_hint() -> String:
	return Loc.t("fish_hidden", [total_fish])


func get_section_count() -> int:
	return 7
