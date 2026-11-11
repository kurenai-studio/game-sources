extends Node2D
## Standalone simulation, drawing and controls. The application owns screen UI.

signal stats_changed(stats: Dictionary)
signal round_finished(stats: Dictionary)

const Rules = preload("res://scripts/game_rules.gd")
const CREAM: Color = Color("f4e9cc")
const INK: Color = Color("163e39")
const GOLD: Color = Color("f3be43")
const TEAL: Color = Color("40b89e")
const CORAL: Color = Color("e97154")
const GRID_SIZE: float = 180.0
const CAPTURE_RADIUS: float = 0.58

var active: bool = false
var paused: bool = false
var candidate: int = 0
var time_left: float = Rules.ROUND_SECONDS
var score: int = 0
var mass: float = 0.0
var radius: float = Rules.START_RADIUS
var shown_radius: float = Rules.START_RADIUS
var absorbed: int = 0
var combo: int = 0
var best_combo: int = 0
var combo_clock: float = 0.0
var player_position: Vector2 = Rules.START_POSITION
var velocity: Vector2 = Vector2.ZERO
var objects: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var total: int = 0
var elapsed: float = 0.0
var round_seed: int = 0
var last_absorbed: String = "Comece pelas promessas espalhadas."
var _camera: Camera2D
var _grid: Dictionary = {}
var _textures: Dictionary = {}
var _style_cache: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stats_clock: float = 0.0
var _pulse: float = 0.0
var _shake: float = 0.0
var _touch_id: int = -1
var _mouse_drag: bool = false
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_position: Vector2 = Vector2.ZERO
var _stick: Control
var _screen_layer: CanvasLayer
var _font: Font
var _sound_player: AudioStreamPlayer
var _sound_stream: AudioStreamGenerator
var _sound_playback: AudioStreamGeneratorPlayback
var _tone_time: float = 0.0
var _tone_frequency: float = 440.0
var _tone_phase: float = 0.0
var sound_enabled: bool = true
var demo_direction: Vector2 = Vector2.ZERO
var _demo_mode: bool = false
var _demo_target: int = -1

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_camera = Camera2D.new()
	_camera.position = player_position
	_camera.position_smoothing_enabled = false
	_camera.zoom = Vector2.ONE * 0.83
	add_child(_camera)
	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = 5
	add_child(_screen_layer)
	_stick = Control.new()
	_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stick.draw.connect(_draw_controls)
	_screen_layer.add_child(_stick)
	for kind in ["paper", "cone", "bench", "tree", "car", "kiosk", "congress"]:
		var path: String = "res://assets/art/%s.png" % kind
		if ResourceLoader.exists(path):
			_textures[kind] = load(path)
	_setup_audio()
	set_physics_process(true)
	queue_redraw()

func _exit_tree() -> void:
	if is_instance_valid(_sound_player):
		_sound_player.stop()
	_sound_playback = null

func _setup_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_sound_stream = AudioStreamGenerator.new()
	_sound_stream.mix_rate = 22050.0
	_sound_stream.buffer_length = 0.08
	_sound_player = AudioStreamPlayer.new()
	_sound_player.stream = _sound_stream
	_sound_player.volume_db = -13.0
	add_child(_sound_player)
	_sound_player.play()
	_sound_playback = _sound_player.get_stream_playback() as AudioStreamGeneratorPlayback

func start_round(candidate_index: int = 0, seed_value: int = 0) -> void:
	candidate = Rules.valid_candidate(candidate_index)
	round_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	_rng.seed = round_seed
	score = 0
	mass = 0.0
	radius = Rules.START_RADIUS
	shown_radius = radius
	absorbed = 0
	combo = 0
	best_combo = 0
	combo_clock = 0.0
	time_left = Rules.ROUND_SECONDS
	elapsed = 0.0
	_stats_clock = 0.0
	_pulse = 0.0
	_shake = 0.0
	player_position = Rules.START_POSITION
	velocity = Vector2.ZERO
	particles.clear()
	labels.clear()
	_clear_pointer()
	demo_direction = Vector2.ZERO
	_demo_target = -1
	last_absorbed = "Comece pelas promessas espalhadas."
	_generate_world()
	active = true
	paused = false
	if is_instance_valid(_camera):
		_camera.position = player_position
		_camera.enabled = true
	stats_changed.emit(get_stats())
	queue_redraw()

func set_paused(value: bool) -> void:
	paused = value
	_clear_pointer()
	velocity = Vector2.ZERO
	_tone_time = 0.0
	if is_instance_valid(_stick):
		_stick.queue_redraw()

func set_demo_mode(value: bool) -> void:
	_demo_mode = value
	_demo_target = -1
	demo_direction = Vector2.ZERO

func get_stats() -> Dictionary:
	var level: int = Rules.level_for_radius(radius)
	return {
		"score": score, "time_left": time_left, "radius": radius,
		"level": level + 1, "level_name": Rules.LEVEL_NAMES[level],
		"combo": combo, "best_combo": best_combo,
		"multiplier": Rules.combo_multiplier(combo),
		"combo_remaining": clampf(combo_clock / Rules.combo_window(candidate), 0.0, 1.0),
		"absorbed": absorbed, "total": total, "progress": Rules.growth_progress(radius),
		"candidate": candidate, "active": active, "paused": paused,
		"last_absorbed": last_absorbed, "seed": round_seed,
	}

func _generate_world() -> void:
	objects.clear()
	_grid.clear()
	# A generous starter ring makes the first few seconds teach by doing.
	for i in range(22):
		var angle: float = float(i) * TAU / 22.0
		var distance: float = 68.0 + float(i % 4) * 43.0
		_add_prop(0, Rules.START_POSITION + Vector2.from_angle(angle) * distance)
	for i in range(15):
		_add_prop(1, Vector2(690.0 + float(i % 5) * 117.0, 780.0 + float(i / 5) * 155.0))
	# Layer difficulty spatially: small clutter, park furniture, fleet, ministries.
	for i in range(82):
		var p: Vector2 = Vector2(_rng.randf_range(150.0, 1750.0), _rng.randf_range(510.0, 1740.0))
		_add_prop(0 if i % 3 != 0 else 1, p)
	for i in range(24):
		var side: float = 420.0 if i % 2 == 0 else 1480.0
		_add_prop(2, Vector2(side + _rng.randf_range(-65.0, 65.0), 530.0 + float(i / 2) * 94.0))
	for i in range(28):
		var side: float = 250.0 if i % 2 == 0 else 1650.0
		_add_prop(3, Vector2(side + _rng.randf_range(-70.0, 70.0), 450.0 + float(i / 2) * 98.0))
	for i in range(14):
		_add_prop(4, Vector2(615.0 if i % 2 == 0 else 1285.0, 530.0 + float(i / 2) * 179.0))
	for i in range(6):
		_add_prop(5, Vector2(400.0 + float(i % 3) * 550.0, 290.0 if i < 3 else 1715.0))
	_add_prop(6, Vector2(950.0, 265.0))
	total = objects.size()

func _add_prop(type_index: int, at: Vector2) -> void:
	var data: Dictionary = Rules.PROP_TYPES[type_index]
	var obj: Dictionary = {
		"type": type_index, "position": at, "radius": float(data["radius"]),
		"state": 0, "sink": 0.0, "angle": _rng.randf_range(-0.10, 0.10),
		"variant": _rng.randi_range(0, 2), "flash": 0.0,
	}
	var index: int = objects.size()
	objects.append(obj)
	var cell: Vector2i = _grid_cell(at)
	if not _grid.has(cell):
		_grid[cell] = []
	_grid[cell].append(index)

func _grid_cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / GRID_SIZE), floori(at.y / GRID_SIZE))

func _nearby(at: Vector2, reach: float) -> Array[int]:
	var result: Array[int] = []
	var minimum: Vector2i = _grid_cell(at - Vector2.ONE * reach)
	var maximum: Vector2i = _grid_cell(at + Vector2.ONE * reach)
	for x in range(minimum.x, maximum.x + 1):
		for y in range(minimum.y, maximum.y + 1):
			for index in _grid.get(Vector2i(x, y), []):
				result.append(index)
	return result

func _physics_process(delta: float) -> void:
	_fill_audio()
	if not active or paused:
		return
	time_left = maxf(0.0, time_left - delta)
	elapsed += delta
	if time_left <= 0.0:
		_finish_round()
		return
	combo_clock = maxf(0.0, combo_clock - delta)
	if combo_clock <= 0.0:
		combo = 0
	var desired: Vector2 = _movement_input()
	var target_velocity: Vector2 = desired * Rules.movement_speed(candidate, radius)
	velocity = velocity.move_toward(target_velocity, 1600.0 * delta)
	var next_position: Vector2 = Rules.bounded_position(player_position + velocity * delta, radius)
	# Huge props reject overlap; smaller ones are handled by the suction pass.
	for index in _nearby(next_position, radius + 128.0):
		var obj: Dictionary = objects[index]
		if obj["state"] != 0 or Rules.can_absorb(radius, float(obj["radius"])):
			continue
		var object_position: Vector2 = obj["position"]
		var offset: Vector2 = next_position - object_position
		var safe_distance: float = float(obj["radius"]) * 0.70 + radius * 0.40
		if offset.length_squared() < safe_distance * safe_distance:
			var normal: Vector2 = offset.normalized() if offset.length_squared() > 0.001 else Vector2.DOWN
			next_position = object_position + normal * safe_distance
			velocity = velocity.slide(normal)
			obj["flash"] = 0.3
	player_position = Rules.bounded_position(next_position, radius)
	for index in _nearby(player_position, radius + 128.0):
		var obj: Dictionary = objects[index]
		if obj["state"] != 0:
			continue
		var distance: float = player_position.distance_to(obj["position"])
		if Rules.can_absorb(radius, float(obj["radius"])) and distance <= radius * CAPTURE_RADIUS:
			obj["state"] = 1
			obj["sink"] = 0.0
			obj["sink_from"] = obj["position"]
			obj["sink_to"] = player_position
			_absorb(obj)
	_update_effects(delta)
	shown_radius = lerpf(shown_radius, radius, 1.0 - exp(-7.0 * delta))
	_pulse = maxf(0.0, _pulse - delta * 2.7)
	_shake = maxf(0.0, _shake - delta * 15.0)
	if is_instance_valid(_camera):
		var view_size: Vector2 = get_viewport_rect().size
		# World scale stays readable on phones and doesn't expose empty margins.
		var zoom_factor: float = clampf(minf(view_size.x / 650.0, view_size.y / 1050.0), 0.68, 1.12)
		_camera.zoom = Vector2.ONE * zoom_factor
		var half_view: Vector2 = view_size / (zoom_factor * 2.0)
		var camera_target: Vector2 = player_position + Vector2(0.0, -60.0)
		camera_target = camera_target.clamp(half_view, Rules.WORLD_SIZE - half_view)
		_camera.position = _camera.position.lerp(camera_target, 1.0 - exp(-8.0 * delta))
		_camera.offset = Vector2(sin(elapsed * 69.0), cos(elapsed * 57.0)) * _shake
	_stats_clock -= delta
	if _stats_clock <= 0.0:
		_stats_clock = 0.08
		stats_changed.emit(get_stats())
	queue_redraw()
	_stick.queue_redraw()

func _movement_input() -> Vector2:
	if _demo_mode:
		_update_demo_direction()
	var direction: Vector2 = demo_direction
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if _touch_id >= 0 or _mouse_drag:
		var stick_delta: Vector2 = (_stick_position - _stick_origin) / 58.0
		if stick_delta.length() > 0.12:
			direction += stick_delta.limit_length(1.0)
	return direction.limit_length(1.0)

func _update_demo_direction() -> void:
	# Capture automation uses the same acceleration, collisions and scoring path.
	if _demo_target < 0 or _demo_target >= objects.size() or objects[_demo_target]["state"] != 0:
		_demo_target = -1
		var nearest: float = INF
		for i in range(objects.size()):
			var obj: Dictionary = objects[i]
			if obj["state"] != 0 or not Rules.can_absorb(radius, float(obj["radius"])):
				continue
			var distance: float = player_position.distance_squared_to(obj["position"])
			if distance < nearest:
				nearest = distance
				_demo_target = i
	if _demo_target >= 0:
		demo_direction = player_position.direction_to(objects[_demo_target]["position"])
	else:
		demo_direction = Vector2.ZERO

func _input(event: InputEvent) -> void:
	# Always release a captured pointer, even if it ends over a HUD button.
	if event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
		_clear_pointer()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_mouse_drag = false
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_stick_position = event.position
	elif event is InputEventMouseMotion and _mouse_drag:
		_stick_position = event.position

func _unhandled_input(event: InputEvent) -> void:
	if not active or paused:
		return
	if event is InputEventScreenTouch and event.pressed and _touch_id == -1:
		_touch_id = event.index
		_stick_origin = event.position
		_stick_position = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _touch_id < 0:
		_mouse_drag = true
		_stick_origin = event.position
		_stick_position = event.position
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_pointer()
		velocity = Vector2.ZERO

func _clear_pointer() -> void:
	_touch_id = -1
	_mouse_drag = false
	_stick_position = Vector2.ZERO
	_stick_origin = Vector2.ZERO

func _absorb(obj: Dictionary) -> void:
	var data: Dictionary = Rules.PROP_TYPES[int(obj["type"])]
	combo += 1
	best_combo = maxi(combo, best_combo)
	combo_clock = Rules.combo_window(candidate)
	var points: int = Rules.score_for(int(data["points"]), combo)
	score += points
	absorbed += 1
	mass += Rules.growth_mass(float(data["mass"]), candidate)
	var old_level: int = Rules.level_for_radius(radius)
	radius = Rules.radius_for_mass(mass)
	last_absorbed = data["name"]
	_pulse = 1.0
	_shake = minf(3.6, float(obj["radius"]) * 0.045)
	labels.append({"position": obj["position"] + Vector2(0.0, -30.0), "text": "+%d" % points, "life": 1.0, "color": CREAM})
	if Rules.level_for_radius(radius) > old_level:
		labels.append({"position": player_position + Vector2(0.0, -radius - 35.0), "text": "CRESCEU!", "life": 1.4, "color": GOLD})
	for i in range(7):
		var angle: float = _rng.randf_range(0.0, TAU)
		particles.append({"position": player_position + Vector2.from_angle(angle) * shown_radius * 0.6, "velocity": Vector2.from_angle(angle) * _rng.randf_range(35.0, 105.0), "life": _rng.randf_range(0.25, 0.55), "color": GOLD if i % 2 == 0 else TEAL})
	_tone_frequency = 310.0 + minf(float(combo), 16.0) * 29.0
	_tone_time = 0.075
	_stats_clock = 0.0

func _update_effects(delta: float) -> void:
	for obj in objects:
		obj["flash"] = maxf(0.0, float(obj["flash"]) - delta)
		if obj["state"] == 1:
			obj["sink"] = minf(1.0, float(obj["sink"]) + delta * 3.5)
			if obj["sink"] >= 1.0:
				obj["state"] = 2
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] -= delta
		particles[i]["position"] += particles[i]["velocity"] * delta
		if particles[i]["life"] <= 0.0:
			particles.remove_at(i)
	for i in range(labels.size() - 1, -1, -1):
		labels[i]["life"] -= delta
		labels[i]["position"].y -= delta * 34.0
		if labels[i]["life"] <= 0.0:
			labels.remove_at(i)

func _finish_round() -> void:
	if not active:
		return
	active = false
	time_left = 0.0
	velocity = Vector2.ZERO
	_clear_pointer()
	# Anything already scored completes its visual sink before the results.
	for obj in objects:
		if obj["state"] == 1:
			obj["state"] = 2
	stats_changed.emit(get_stats())
	round_finished.emit(get_stats())
	queue_redraw()
	_stick.queue_redraw()

func _fill_audio() -> void:
	if not is_instance_valid(_sound_playback):
		return
	var count: int = _sound_playback.get_frames_available()
	for i in range(count):
		var sample: float = 0.0
		if sound_enabled and active and not paused and _tone_time > 0.0:
			_tone_phase += _tone_frequency / 22050.0
			_tone_phase = fmod(_tone_phase, 1.0)
			sample = sin(_tone_phase * TAU) * minf(_tone_time * 18.0, 1.0) * 0.22
			_tone_time -= 1.0 / 22050.0
		_sound_playback.push_frame(Vector2.ONE * sample)

func _draw() -> void:
	_draw_world()
	if not active and objects.is_empty():
		return
	_draw_hole()
	var visible_rect: Rect2 = _visible_world_rect().grow(280.0)
	for obj in objects:
		if obj["state"] == 2 or not visible_rect.has_point(obj["position"]):
			continue
		_draw_prop(obj)
	for particle in particles:
		var color: Color = particle["color"]
		color.a = clampf(float(particle["life"]) * 2.5, 0.0, 1.0)
		draw_rect(Rect2(particle["position"] - Vector2.ONE * 2.5, Vector2.ONE * 5.0), color)
	for label in labels:
		var color: Color = label["color"]
		color.a = clampf(float(label["life"]) * 2.0, 0.0, 1.0)
		var label_position: Vector2 = label["position"]
		draw_string(_font, label_position + Vector2(1.0, 2.0), label["text"], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 21, Color(0.05, 0.12, 0.10, color.a))
		draw_string(_font, label_position, label["text"], HORIZONTAL_ALIGNMENT_CENTER, -1.0, 21, color)

func _visible_world_rect() -> Rect2:
	if not is_instance_valid(_camera):
		return Rect2(Vector2.ZERO, Rules.WORLD_SIZE)
	var view: Vector2 = get_viewport_rect().size / _camera.zoom
	return Rect2(_camera.position - view * 0.5, view)

func _draw_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, Rules.WORLD_SIZE), Color("98b885"))
	# Esplanade: paired asphalt avenues around a sunlit monumental axis.
	draw_rect(Rect2(530, 0, 185, 1900), Color("6b8176"))
	draw_rect(Rect2(1185, 0, 185, 1900), Color("6b8176"))
	draw_rect(Rect2(0, 1420, 1900, 180), Color("6b8176"))
	draw_rect(Rect2(715, 0, 470, 1900), Color("e2d7b5"))
	draw_rect(Rect2(90, 200, 1720, 260), Color("d9d1b0"))
	draw_rect(Rect2(110, 1630, 1680, 200), Color("d9d1b0"))
	for x in [515.0, 720.0, 1180.0, 1370.0]:
		draw_line(Vector2(x, 0), Vector2(x, 1900), Color("f3e8c6"), 7.0)
	for y in range(35, 1890, 80):
		draw_rect(Rect2(620, y, 5, 34), Color("c4c3a5"))
		draw_rect(Rect2(1275, y, 5, 34), Color("c4c3a5"))
	for x in range(20, 1890, 90):
		draw_rect(Rect2(x, 1508, 42, 5), Color("c4c3a5"))
	for x in [535.0, 1190.0]:
		for i in range(7):
			draw_rect(Rect2(x + float(i) * 25.0, 1402.0, 13.0, 60.0), Color("e4e0c7"))
	# Small repeated pavement joints stay quiet behind gameplay objects.
	for y in range(490, 1860, 90):
		draw_line(Vector2(730, y), Vector2(1170, y), Color("d4c9a8"), 1.0)
	for x in range(790, 1170, 95):
		draw_line(Vector2(x, 470), Vector2(x, 1900), Color("d4c9a8"), 1.0)
	for y in range(510, 1390, 220):
		for x in [340.0, 1500.0]:
			draw_style_box(_round_box(Color("6e9b73"), 20), Rect2(x - 90.0, y - 60.0, 180.0, 130.0))
	# Monumental fountain remains decorative terrain, never a hidden collider.
	draw_circle(Vector2(950, 645), 88.0, Color("b3b99a"))
	draw_circle(Vector2(950, 640), 82.0, Color("f4e9cc"))
	draw_circle(Vector2(950, 640), 70.0, Color("67aca0"))
	draw_arc(Vector2(950, 640), 48.0, 0, TAU, 36, Color("a5d1bb"), 3.0)
	draw_arc(Vector2(950, 640), 28.0, 0, TAU, 28, Color("a5d1bb"), 2.0)
	draw_circle(Vector2(950, 640), 8.0, CREAM)
	# Plaques and arrow motifs give the district a place and direction.
	if _font != null:
		draw_string(_font, Vector2(790, 477), "ESPLANADA DAS PROMESSAS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color("657b64"))
		draw_string(_font, Vector2(794, 1855), "BRASÍLIA • DISTRITO DA SÁTIRA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("657b64"))
	for x in [115.0, 1780.0]:
		for y in range(120, 1870, 175):
			draw_circle(Vector2(x, y), 5, Color("547d60"))
	# A visible perimeter communicates the movement boundary.
	draw_rect(Rect2(14, 14, 1872, 1872), Color("547d60"), false, 12.0)

func _round_box(color: Color, corner: int) -> StyleBoxFlat:
	var cache_key: String = "%s:%d" % [color.to_html(), corner]
	if _style_cache.has(cache_key):
		return _style_cache[cache_key]
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = corner
	box.corner_radius_top_right = corner
	box.corner_radius_bottom_left = corner
	box.corner_radius_bottom_right = corner
	_style_cache[cache_key] = box
	return box

func _draw_hole() -> void:
	var rim: Color = [TEAL, CORAL, GOLD][candidate]
	var r: float = shown_radius + _pulse * 2.0
	draw_circle(player_position + Vector2(0, 5), r + 7.0, Color(0.06, 0.18, 0.16, 0.20))
	draw_circle(player_position, r + 4.0, rim.darkened(0.22))
	draw_circle(player_position, r + 1.0, rim)
	draw_circle(player_position, r - 4.0, Color("102b30"))
	draw_circle(player_position + Vector2(0, 4), r - 10.0, Color("091b22"))
	draw_arc(player_position, r - 2.0, PI * 1.06, PI * 1.91, 40, rim.lightened(0.35), 3.0)
	if velocity.length() > 20.0:
		var direction: Vector2 = velocity.normalized()
		var arrow: Vector2 = player_position + direction * (r + 13.0)
		draw_colored_polygon(PackedVector2Array([arrow + direction * 7.0, arrow - direction * 4.0 + direction.orthogonal() * 5.0, arrow - direction * 4.0 - direction.orthogonal() * 5.0]), CREAM)
	# Orbiting dashes remain outside the mouth so small props stay readable.
	for i in range(3):
		var angle: float = elapsed * 0.8 + float(i) * TAU / 3.0
		draw_arc(player_position, r + 9.0, angle, angle + 0.32, 10, Color(rim, 0.4), 2.0)

func _draw_prop(obj: Dictionary) -> void:
	var position_value: Vector2 = obj["position"]
	var scale_value: float = 1.0
	var alpha: float = 1.0
	var angle: float = float(obj["angle"])
	if obj["state"] == 1:
		var sink: float = float(obj["sink"])
		position_value = Vector2(obj["sink_from"]).lerp(obj["sink_to"], sink)
		scale_value = 1.0 - sink * 0.95
		angle += sink * 1.2
		alpha = 1.0 - sink
	var type_index: int = int(obj["type"])
	var object_radius: float = float(obj["radius"])
	# Color plus shape: a small dot for edible props, padlock for the next size.
	if obj["state"] == 0 and player_position.distance_squared_to(position_value) < 240.0 * 240.0:
		if Rules.can_absorb(radius, object_radius):
			draw_arc(position_value + Vector2(0, object_radius * 0.3), object_radius * 0.95 + 5.0, 0.0, TAU, 24, Color("b9dc9f"), 2.5)
		elif float(obj["flash"]) > 0.0:
			draw_arc(position_value, object_radius + 4.0, 0, TAU, 32, CORAL, 3.0)
			draw_string(_font, position_value + Vector2(-30, -object_radius - 12), "CRESÇA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, INK)
	draw_set_transform(position_value, angle if type_index < 2 else 0.0, Vector2.ONE * scale_value)
	var data: Dictionary = Rules.PROP_TYPES[type_index]
	var kind: String = data["kind"]
	if _textures.has(kind):
		var texture: Texture2D = _textures[kind]
		var texture_size: Vector2 = texture.get_size()
		var side: float = object_radius * 2.9
		var draw_size: Vector2 = texture_size * (side / maxf(texture_size.x, texture_size.y))
		draw_texture_rect(texture, Rect2(Vector2(-draw_size.x * 0.5, -draw_size.y + object_radius * 0.6), draw_size), false, Color(1, 1, 1, alpha))
	else:
		_draw_native_prop(type_index, int(obj["variant"]), alpha)
	draw_set_transform(Vector2.ZERO)

func _draw_native_prop(type_index: int, variant: int, alpha: float) -> void:
	var shadow: Color = Color(0.08, 0.20, 0.17, alpha * 0.19)
	var cream: Color = Color(CREAM, alpha)
	var ink: Color = Color(INK, alpha)
	match type_index:
		0:
			draw_rect(Rect2(-8, -6, 19, 20), shadow)
			draw_rect(Rect2(-10, -10, 18, 19), cream)
			draw_rect(Rect2(-7, -6, 12, 3), Color(CORAL if variant == 0 else TEAL, alpha))
			draw_line(Vector2(-7, 0), Vector2(4, 0), ink, 1)
			draw_line(Vector2(-7, 4), Vector2(0, 4), ink, 1)
		1:
			draw_ellipse(Vector2(2, 6), Vector2(19, 8), shadow)
			draw_rect(Rect2(-17, 1, 34, 11), ink)
			draw_colored_polygon(PackedVector2Array([Vector2(-13, 4), Vector2(0, -25), Vector2(13, 4)]), Color(CORAL, alpha))
			draw_line(Vector2(-7, -7), Vector2(7, -7), cream, 6)
		2:
			draw_rect(Rect2(-29, 4, 62, 20), shadow)
			draw_rect(Rect2(-26, -17, 52, 12), Color("9b644b") * Color(1, 1, 1, alpha))
			draw_rect(Rect2(-28, -2, 56, 14), Color("b78357") * Color(1, 1, 1, alpha))
			for x in [-21.0, 21.0]:
				draw_line(Vector2(x, -4), Vector2(x, 20), ink, 5)
			draw_line(Vector2(-27, 4), Vector2(27, 4), Color("d1a276") * Color(1, 1, 1, alpha), 2)
		3:
			draw_ellipse(Vector2(7, 17), Vector2(36, 16), shadow)
			draw_rect(Rect2(-6, -22, 12, 44), Color("8b694b") * Color(1, 1, 1, alpha))
			draw_circle(Vector2(0, -27), 34, Color("337c61") * Color(1, 1, 1, alpha))
			draw_circle(Vector2(-15, -35), 21, Color("50945f") * Color(1, 1, 1, alpha))
			draw_circle(Vector2(12, -42), 23, Color("6eab6a") * Color(1, 1, 1, alpha))
			draw_circle(Vector2(-5, -50), 13, Color("9bbb77") * Color(1, 1, 1, alpha))
		4:
			draw_rect(Rect2(-32, -43, 70, 104), shadow)
			for x in [-33.0, 25.0]:
				for y in [-33.0, 29.0]:
					draw_rect(Rect2(x, y, 9, 23), ink)
			draw_style_box(_round_box(Color(cream if variant != 1 else Color("e8b65b"), alpha), 11), Rect2(-30, -55, 60, 110))
			draw_rect(Rect2(-24, -23, 48, 27), Color("386b70") * Color(1, 1, 1, alpha))
			draw_rect(Rect2(-23, 28, 46, 15), Color("386b70") * Color(1, 1, 1, alpha))
			draw_rect(Rect2(-25, -49, 10, 5), Color(GOLD, alpha))
			draw_rect(Rect2(15, -49, 10, 5), Color(GOLD, alpha))
			draw_rect(Rect2(-14, 8, 28, 13), Color(TEAL, alpha))
		5:
			draw_rect(Rect2(-65, -31, 138, 99), shadow)
			draw_rect(Rect2(-65, -53, 130, 110), cream)
			draw_rect(Rect2(-70, -62, 140, 19), ink)
			draw_rect(Rect2(-59, -38, 118, 12), Color(GOLD, alpha))
			for x in [-46.0, -11.0, 24.0]:
				draw_rect(Rect2(x, -15, 22, 27), Color("62938a") * Color(1, 1, 1, alpha))
			draw_rect(Rect2(-13, 28, 26, 29), ink)
			draw_string(_font, Vector2(-49, -28), "GABINETE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, ink)
		6:
			draw_ellipse(Vector2(8, 44), Vector2(155, 45), shadow)
			draw_rect(Rect2(-152, 12, 304, 44), cream)
			draw_rect(Rect2(-144, 50, 288, 12), Color("c1bea6") * Color(1, 1, 1, alpha))
			for x in [-35.0, 8.0]:
				draw_rect(Rect2(x, -137, 27, 154), cream)
				for y in range(-125, 5, 14):
					draw_rect(Rect2(x + 4, y, 19, 4), Color("6d9991") * Color(1, 1, 1, alpha))
			draw_arc(Vector2(-90, 13), 46, PI, TAU, 24, cream, 32)
			draw_arc(Vector2(90, -12), 45, 0, PI, 24, cream, 24)
			draw_line(Vector2(-132, -14), Vector2(-48, -14), cream, 6)

func draw_ellipse(center: Vector2, extents: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		points.append(center + Vector2.from_angle(float(i) * TAU / 24.0) * extents)
	draw_colored_polygon(points, color)

func _draw_controls() -> void:
	if not active or paused:
		return
	var screen: Vector2 = get_viewport_rect().size
	var origin: Vector2 = _stick_origin if _touch_id >= 0 or _mouse_drag else Vector2(88, screen.y - 112)
	var knob: Vector2 = origin + (_stick_position - _stick_origin).limit_length(48.0) if _touch_id >= 0 or _mouse_drag else origin
	_stick.draw_circle(origin, 58, Color(0.06, 0.19, 0.17, 0.13))
	_stick.draw_arc(origin, 58, 0, TAU, 48, Color(0.96, 0.92, 0.80, 0.50), 2)
	_stick.draw_circle(knob, 25, Color(0.96, 0.92, 0.80, 0.52))
	_stick.draw_circle(knob, 7, Color(0.08, 0.23, 0.20, 0.55))
	if elapsed < 7.0 and _touch_id < 0 and not _mouse_drag:
		_stick.draw_string(_font, Vector2(159, screen.y - 108), "ARRASTE PARA MOVER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("f4e9cc"))
		_stick.draw_string(_font, Vector2(159, screen.y - 87), "ou use WASD / setas", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.96, 0.92, 0.80, 0.8))
