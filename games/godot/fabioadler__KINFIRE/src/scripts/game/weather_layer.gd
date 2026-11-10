class_name WeatherLayer
extends Node2D
## Fase 7.6 (MECANICAS #14.4 + #14.5.3): clima e partículas ambientais.
## Um emissor GPUParticles2D por bioma (folhas, neve, cinzas, esporos,
## poeira) + vagalumes noturnos + chuva global determinística com
## relâmpago e trovão; névoa volumétrica fake (parallax) no pântano e
## nas Terras Corrompidas. As partículas herdam o vento (#14.5.3):
## direção e velocidade vêm de WindField.at * massa da partícula.

const VIEW := Vector2(1280, 720)
const VIEW_MARGIN := 320.0

var _emitters: Dictionary = {}            ## StringName -> GPUParticles2D
var _materials: Dictionary = {}           ## StringName -> ParticleProcessMaterial
var _active: Array[StringName] = []
var _raining := false
var _fog_rects: Array[ColorRect] = []
var _fog_layer: CanvasLayer
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect
var _lightning_timer := 0.0
var _flash_count := 0
var _biome: StringName = &""
var _night := false
var _time_sec := 0.0
var _world: World


func _ready() -> void:
	z_index = 50
	for kind in [&"leaf", &"snow", &"ash", &"spore", &"dust", &"firefly", &"rain"]:
		_make_emitter(kind)
	# névoa: duas camadas parallax entre o mundo (0) e a vinheta (2)
	_fog_layer = CanvasLayer.new()
	_fog_layer.layer = 2
	add_child(_fog_layer)
	var fog_shader: Shader = load("res://shaders/fog_drift.gdshader")
	for layer in 2:
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		var mat := ShaderMaterial.new()
		mat.shader = fog_shader
		mat.set_shader_parameter("layer_seed", 0.37 + float(layer) * 1.31)
		rect.material = mat
		_fog_layer.add_child(rect)
		_fog_rects.append(rect)
	_fog_layer.visible = false
	# relâmpago: flash branco-azulado acima da vinheta, abaixo da HUD (10)
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 3
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1.55, 1.62, 1.9, 0.0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_layer.add_child(_flash_rect)


func _make_emitter(kind: StringName) -> void:
	var p := GPUParticles2D.new()
	p.name = kind
	p.texture = _make_texture(kind)
	p.amount = int(maxf(1.0, (26 if kind != &"rain" else 220) * Game.particle_mult()))
	p.lifetime = 6.0 if kind != &"rain" else 1.1
	p.preprocess = 4.0
	p.visibility_rect = Rect2(-VIEW_MARGIN, -VIEW_MARGIN,
		VIEW.x + VIEW_MARGIN * 2.0, VIEW.y + VIEW_MARGIN * 2.0)
	p.local_coords = false              # coordenadas globais: emissão ao redor do player
	p.self_modulate = Weather.EMITTER_COLOR[kind]
	# vagalumes passam do threshold do glow (HDR 2D): florescem no escuro
	if kind == &"firefly":
		p.self_modulate = Color(2.4, 2.8, 1.1, 1.0)
	var mat := ParticleProcessMaterial.new()
	p.process_material = mat
	var box: Vector2 = Vector2(VIEW.x + VIEW_MARGIN * 2.0, 260.0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	if kind == &"rain":
		mat.emission_box_extents = Vector3(box.x * 0.5, 40.0, 1.0)
		mat.direction = Vector3(0.12, 1.0, 0.0)
		mat.spread = 8.0
		mat.initial_velocity_min = 900.0
		mat.initial_velocity_max = 1100.0
		mat.gravity = Vector3(0, 150.0, 0)
		mat.scale_min = 0.5
		mat.scale_max = 0.8
	elif kind == &"firefly":
		mat.emission_box_extents = Vector3(box.x * 0.5, 180.0, 1.0)
		mat.direction = Vector3(0, 0, 0)
		mat.spread = 180.0
		mat.initial_velocity_min = 6.0
		mat.initial_velocity_max = 18.0
		mat.gravity = Vector3(0, 0, 0)
		mat.scale_min = 1.0
		mat.scale_max = 1.6
		mat.turbulence_enabled = true
		mat.turbulence_noise_strength = 2.5
		mat.turbulence_noise_scale = 2.0
	else:
		mat.emission_box_extents = Vector3(box.x * 0.5, 130.0, 1.0)
		mat.direction = Vector3(0, 1.0, 0.0)
		mat.spread = 25.0
		# queda por massa: folha balança devagar, cinza flutua, neve cai reta
		var mass: float = Weather.EMITTER_MASS[kind]
		mat.initial_velocity_min = 18.0 + 40.0 * (1.0 - mass)
		mat.initial_velocity_max = 36.0 + 80.0 * (1.0 - mass)
		mat.gravity = Vector3(0, 60.0 * (1.0 - mass) + 8.0, 0)
		mat.scale_min = 1.0
		mat.scale_max = 2.0
		mat.angular_velocity_min = -90.0
		mat.angular_velocity_max = 90.0
	p.emitting = false
	p.visible = false
	add_child(p)
	_emitters[kind] = p
	_materials[kind] = mat


func _make_texture(kind: StringName) -> ImageTexture:
	## Textura procedural (sem asset externo): ponto suave; gota alongada p/ chuva
	var stretch := 4 if kind == &"rain" else 1
	var size: Vector2i = Vector2i(8, 8 * stretch)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var fx := (float(x) + 0.5) / float(size.x) - 0.5
			var fy := (float(y) + 0.5) / float(size.y) - 0.5
			var d := sqrt(fx * fx + fy * fy * 4.0) * 2.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ CONFIGURACAO

## Configura o clima: bioma, noite e chuva (o Overworld chama a cada 0.5s).
func configure(biome: StringName, night: bool, raining: bool, world: World) -> void:
	_world = world
	_biome = biome
	_night = night
	_raining = raining
	# emissores: um por bioma + vagalumes à noite (#14.4)
	var want: Array[StringName] = [Weather.emitter_of(biome)]
	if Weather.fireflies_at(biome, night):
		want.append(&"firefly")
	if raining:
		want.append(&"rain")
	_lightning_timer = 0.0 if not raining else _lightning_timer
	for kind in _emitters.keys():
		var on: bool = want.has(kind)
		_emitters[kind].visible = on
		_emitters[kind].emitting = on
	_active = want
	# névoa parallax no pântano e Terras Corrompidas (#14.4)
	var fog: bool = Weather.fog_at(biome)
	_fog_layer.visible = fog
	if fog:
		var base: Color = Color(0.72, 0.82, 0.68) if biome == &"pantano" else Color(0.55, 0.42, 0.62)
		var density := 0.22 if _night else 0.12
		for i in _fog_rects.size():
			var mat := _fog_rects[i].material as ShaderMaterial
			mat.set_shader_parameter("fog_color", Color(base.r, base.g, base.b, density))
			mat.set_shader_parameter("density", density)
	# chuva molha o som (#14.4): ambiência de chuva no bus Ambience
	Audio.set_rain(raining)


func _process(delta: float) -> void:
	if _world == null or _world.player == null:
		return
	_time_sec += delta
	# emissor segue o herói (partículas em coordenadas globais)
	global_position = _world.player.global_position
	# vento nas partículas (#14.5.3): direção * força * massa
	var w := WindField.at(_world.player.global_position)
	for kind in _active:
		if kind == &"firefly":
			continue  # vagalumes voam contra o vento - são vivos
		var mat: ParticleProcessMaterial = _materials[kind]
		var mass: float = Weather.EMITTER_MASS[kind]
		if kind == &"rain":
			mat.direction = Vector3(w.x * mass * 0.35, 1.0, 0.0)
		else:
			var dir: Vector2 = Vector2(w.x * mass, 0.55 + 0.45 * (1.0 - mass))
			mat.direction = Vector3(dir.x, dir.y, 0.0)
			mat.initial_velocity_min = 18.0 + 60.0 * (1.0 - mass) * (0.4 + absf(w.length()))
			mat.initial_velocity_max = 36.0 + 120.0 * (1.0 - mass) * (0.4 + absf(w.length()))
	# névoa: o vento empurra as camadas, a noite engrossa
	if _fog_layer.visible:
		for i in _fog_rects.size():
			var mat := _fog_rects[i].material as ShaderMaterial
			mat.set_shader_parameter("drift_dir", w)
			mat.set_shader_parameter("time_sec", _time_sec * (0.6 + 0.4 * float(i)))
	# relâmpago: só na chuva; intervalo "aleatório" entre 5 e 14s
	if _raining:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			_lightning_timer = randf_range(5.0, 14.0)
			trigger_lightning()


## Flash do relâmpago + trovão com atraso realista (smoke chama direto).
func trigger_lightning() -> void:
	_flash_count += 1
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.42, 0.06)
	tw.tween_property(_flash_rect, "color:a", 0.0, 0.32)
	# trovão chega depois do flash (distância da tempestade)
	var t := get_tree().create_timer(randf_range(0.3, 1.1), true, false, true)
	t.timeout.connect(func(): Audio.play_thunder())


# ------------------------------------------------------------------ GETTERS (smoke)

func active_emitters() -> Array[StringName]: return _active.duplicate()
func is_raining() -> bool: return _raining
func fog_visible() -> bool: return _fog_layer.visible
func flash_count() -> int: return _flash_count
func current_biome() -> StringName: return _biome
