extends Node2D

const W := 1280.0
const H := 720.0
const CENTER := Vector2(W / 2.0, H / 2.0)
const SPEED := 380.0
const DASH_SPEED := 1150.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.1
const PLAYER_R := 12.0
const LEVEL_TIME := 20.0
const COMBO_TIME := 2.2
const MAX_COMBO := 10
const MAX_HUNTERS := 70
const GRID_STEP := 48.0
const GRAZE_DIST := 20.0  # extra distance around a hunter that still counts as a close call
const DEADZONE := 0.25

# HDR colors: channels above 1.0 bloom through the glow pass.
const CYAN := Color(0.4, 1.6, 2.2)
const GOLD := Color(2.2, 1.7, 0.5)
const RED := Color(2.4, 0.45, 0.6)
const ORANGE := Color(2.4, 1.1, 0.3)
const PURPLE := Color(1.6, 0.6, 2.4)
const PINK := Color(2.4, 0.4, 1.6)
const GREEN := Color(0.6, 2.2, 1.0)
const BLUE := Color(0.6, 1.2, 2.6)
const HOT := Color(2.5, 2.5, 2.5)
const TEXT := Color(0.92, 0.95, 1.0)
const DIM := Color(0.7, 0.76, 0.9, 0.75)

enum State { TITLE, PLAYING, DYING, OVER }
enum Kind { CHASER, DART, SPLITTER, MINI }
enum Power { SHIELD, SLOW, MAGNET }


class Hunter:
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var kind: int
	var r: float
	var spin: float = 0.0
	var age: float = 0.0
	var warn: float = 0.0  # darts sit and telegraph before launching
	var aim: Vector2 = Vector2.RIGHT
	var grazed := false


class Spark:
	var pos: Vector2
	var t: float = 0.0


class Pickup:
	var pos: Vector2
	var kind: int
	var t: float = 0.0
	var life: float = 9.0


class Particle:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: float
	var streak: bool


class Ring:
	var pos: Vector2
	var r: float
	var max_r: float
	var life: float
	var max_life: float
	var color: Color


class FloatText:
	var pos: Vector2
	var text: String
	var life: float = 0.9
	var color: Color


var state := State.TITLE
var paused := false
var time := 0.0
var hitstop := 0.0
var shake := 0.0
var flash := 0.0
var aberr := 0.0
var slow_fx := 0.0

var player := CENTER
var vel := Vector2.ZERO
var facing := 0.0
var dash_timer := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.RIGHT
var invuln := 0.0
var shield := false
var slow_timer := 0.0
var magnet_timer := 0.0
var trail: Array[Vector2] = []

var score := 0
var best := 0
var new_best := false
var combo := 1
var max_combo := 1
var combo_timer := 0.0
var kills := 0
var elapsed := 0.0
var level := 1
var banner := ""
var banner_timer := 0.0
var spawn_timer := 0.0
var pickup_timer := 0.0
var death_timer := 0.0
var over_timer := 0.0
var grazes := 0
var killed_by := ""

var hunters: Array[Hunter] = []
var sparks: Array[Spark] = []
var pickups: Array[Pickup] = []
var particles: Array[Particle] = []
var rings: Array[Ring] = []
var popups: Array[FloatText] = []

var grid_cols := 0
var grid_rows := 0
var grid_off := PackedVector2Array()
var grid_vel := PackedVector2Array()

var settings := GameSettings.new()
var sfx: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var music_player: AudioStreamPlayer
var music_builder: Synth.MusicBuilder
var music_stream: AudioStreamWAV
var soft_glow := false  # the Compatibility renderer (web) has no 2D bloom, so draw halos by hand
var hud: Node2D
var bg_mat: ShaderMaterial
var post_mat: ShaderMaterial
var font_b: Font
var font_m: Font
var rng := RandomNumberGenerator.new()
var version: String = ProjectSettings.get_setting("application/config/version", "")
var persist := true:  # tests turn this off so they never touch the player's settings or best score
	set(value):
		persist = value
		settings.persist = value


func _ready() -> void:
	get_window().title = ProjectSettings.get_setting("application/config/name")
	rng.randomize()
	settings.load_file()
	best = settings.best
	soft_glow = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	font_b = _make_font(800)
	font_m = _make_font(500)
	_setup_scene()
	_setup_grid()
	_build_sounds()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		paused = true


# --- setup -------------------------------------------------------------

func _make_font(weight: int) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial"])
	f.font_weight = weight
	return f


func _setup_scene() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = 5
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_strength = 0.9
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	for i in 7:
		env.set_glow_level(i, i >= 2 and i <= 5)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	bg_mat = _shader_layer(-10, "res://shaders/background.gdshader")
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	hud = Node2D.new()
	hud_layer.add_child(hud)
	hud.draw.connect(_draw_hud)
	post_mat = _shader_layer(20, "res://shaders/post.gdshader")


func _shader_layer(layer: int, path: String) -> ShaderMaterial:
	var cl := CanvasLayer.new()
	cl.layer = layer
	add_child(cl)
	var rect := ColorRect.new()
	rect.size = Vector2(W, H)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(path)
	rect.material = mat
	cl.add_child(rect)
	return mat


func _setup_grid() -> void:
	grid_cols = int(ceil(W / GRID_STEP)) + 1
	grid_rows = int(ceil(H / GRID_STEP)) + 1
	grid_off.resize(grid_cols * grid_rows)
	grid_vel.resize(grid_cols * grid_rows)


# --- sound (synthesized at startup, no audio files) --------------------

func _build_sounds() -> void:
	sfx = Synth.effects()
	for i in 10:
		var v := AudioStreamPlayer.new()
		v.volume_db = -8.0
		add_child(v)
		voices.append(v)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -13.0
	add_child(music_player)
	music_builder = Synth.MusicBuilder.new()


func _update_music() -> void:
	if music_builder:
		music_builder.step(4000)  # about a quarter of a 60 fps frame
		if music_builder.done():
			music_stream = music_builder.stream()
			music_player.stream = music_stream
			music_builder = null
	if music_player.stream == null:
		return
	var want := settings.music and not paused
	if want and not music_player.playing:
		music_player.play()
	elif not want and music_player.playing:
		music_player.stop()


func _play(sound: String, pitch: float = 1.0) -> void:
	if not settings.sound:
		return
	var v := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	v.stream = sfx[sound]
	v.pitch_scale = pitch
	v.play()


# --- flow --------------------------------------------------------------

func _start() -> void:
	state = State.PLAYING
	paused = false
	player = CENTER
	vel = Vector2.ZERO
	facing = -PI / 2.0
	hunters.clear()
	sparks.clear()
	pickups.clear()
	trail.clear()
	score = 0
	new_best = false
	combo = 1
	max_combo = 1
	combo_timer = 0.0
	kills = 0
	elapsed = 0.0
	level = 1
	spawn_timer = 1.2
	pickup_timer = 10.0
	dash_timer = 0.0
	dash_cd = 0.0
	invuln = 0.0
	shield = false
	slow_timer = 0.0
	magnet_timer = 0.0
	grazes = 0
	killed_by = ""
	for i in 3:
		_spawn_spark()
	_show_banner("GO")
	_ring(CENTER, 700.0, 0.8, CYAN)
	_grid_push(CENTER, 900.0, 700.0)


func _show_banner(text: String) -> void:
	banner = text
	banner_timer = 1.8


func _unhandled_input(event: InputEvent) -> void:
	var action := _action_for(event)
	if action == "":
		return
	match action:
		"fullscreen":
			_toggle_fullscreen()
		"sound":
			settings.sound = not settings.sound
			settings.save()
		"music":
			settings.music = not settings.music
			settings.save()
		"effects":
			settings.reduced_effects = not settings.reduced_effects
			settings.save()
		_:
			_game_action(action)


func _game_action(action: String) -> void:
	match state:
		State.PLAYING:
			if action == "pause" or (paused and action == "back"):
				paused = not paused
			elif paused and action == "quit":
				get_tree().quit()
			elif not paused and (action == "dash" or action == "confirm"):
				_try_dash()
		State.TITLE:
			if action == "confirm" or action == "dash":
				_start()
			elif action == "back":
				get_tree().quit()
		State.OVER:
			if (action == "confirm" or action == "dash") and over_timer > 0.8:
				_start()
			elif action == "back":
				get_tree().quit()


## Maps keyboard and gamepad input to one action name, or "" for anything else.
func _action_for(event: InputEvent) -> String:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F, KEY_F11:
				return "fullscreen"
			KEY_M:
				return "sound"
			KEY_N:
				return "music"
			KEY_V:
				return "effects"
			KEY_SPACE:
				return "confirm"
			KEY_ENTER, KEY_KP_ENTER, KEY_R:
				return "confirm" if state != State.PLAYING else ""
			KEY_SHIFT, KEY_J:
				return "dash"
			KEY_ESCAPE:
				return "pause" if state == State.PLAYING else "back"
			KEY_P:
				return "pause"
			KEY_Q:
				return "quit"
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER:
				return "confirm"
			JOY_BUTTON_START:
				return "pause" if state == State.PLAYING else "confirm"
			JOY_BUTTON_B:
				return "back" if paused else ""
			JOY_BUTTON_BACK:
				return "quit" if paused else ""
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.6:
		return "dash" if state == State.PLAYING and not paused else ""
	return ""


func _toggle_fullscreen() -> void:
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_MAXIMIZED
	else:
		win.mode = Window.MODE_FULLSCREEN


func _input_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1.0
	if d == Vector2.ZERO:
		for pad in Input.get_connected_joypads():
			var stick := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
			if stick.length() > DEADZONE:
				return stick.limit_length(1.0)
			if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT):
				d.x -= 1.0
			if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT):
				d.x += 1.0
			if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_UP):
				d.y -= 1.0
			if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_DOWN):
				d.y += 1.0
	return d.normalized()


func _try_dash() -> void:
	if dash_cd > 0.0:
		return
	var d := _input_dir()
	if d == Vector2.ZERO:
		d = vel.normalized() if vel.length() > 10.0 else Vector2.from_angle(facing)
	dash_dir = d
	dash_timer = DASH_TIME
	dash_cd = DASH_COOLDOWN
	_burst(player, HOT, 12, 240.0, true)
	_grid_push(player, 350.0, 120.0)
	_play("dash", rng.randf_range(0.95, 1.1))


# --- update ------------------------------------------------------------

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	time += dt
	var gdt := dt
	if hitstop > 0.0:
		hitstop -= dt
		gdt = dt * 0.06

	match state:
		State.TITLE:
			_update_attract(gdt)
		State.PLAYING:
			if not paused:
				_update_game(gdt)
		State.DYING:
			death_timer += dt
			_update_hunters(gdt * 0.3, player)
			if death_timer > 1.4:
				state = State.OVER
				over_timer = 0.0
		State.OVER:
			over_timer += dt
			_update_hunters(gdt * 0.3, _phantom())

	if not paused:
		_update_fx(gdt)
	_update_music()
	var mouse := Input.MOUSE_MODE_HIDDEN if state == State.PLAYING and not paused else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mouse:
		Input.mouse_mode = mouse

	if settings.reduced_effects:
		shake = minf(shake, 2.0)
		flash = 0.0
		aberr = 0.0
	shake = maxf(0.0, shake - dt * 40.0)
	flash = maxf(0.0, flash - dt * 2.5)
	aberr = maxf(0.0, aberr - dt * 3.0)
	slow_fx = move_toward(slow_fx, 1.0 if slow_timer > 0.0 else 0.0, dt * 3.0)
	position = Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake))
	bg_mat.set_shader_parameter("cam", player)
	bg_mat.set_shader_parameter("slow", slow_fx)
	post_mat.set_shader_parameter("aberration", aberr)
	post_mat.set_shader_parameter("flash", flash)
	queue_redraw()
	hud.queue_redraw()


func _phantom() -> Vector2:
	return CENTER + Vector2(cos(time * 0.7) * 400.0, sin(time * 1.1) * 210.0)


func _update_attract(dt: float) -> void:
	if hunters.size() < 8 and rng.randf() < dt * 2.0:
		_spawn_hunter(true)
	_update_hunters(dt, _phantom())
	while sparks.size() < 5:
		_spawn_spark()
	for s in sparks:
		s.t += dt


func _update_game(dt: float) -> void:
	elapsed += dt
	var lvl := 1 + int(elapsed / LEVEL_TIME)
	if lvl > level:
		_level_up(lvl)
	dash_cd = maxf(0.0, dash_cd - dt)
	invuln = maxf(0.0, invuln - dt)
	slow_timer = maxf(0.0, slow_timer - dt)
	magnet_timer = maxf(0.0, magnet_timer - dt)

	_move_player(dt)

	combo_timer -= dt
	if combo_timer <= 0.0 and combo > 1:
		if combo >= 3:
			_popup(player + Vector2(0, -28), "COMBO LOST", DIM)
		combo = 1

	_update_sparks(dt)
	_update_pickups(dt)

	spawn_timer -= dt
	if spawn_timer <= 0.0 and hunters.size() < MAX_HUNTERS:
		_spawn_hunter(false)
		spawn_timer = maxf(0.28, 1.35 - level * 0.1)

	_update_hunters(dt * (0.4 if slow_timer > 0.0 else 1.0), player)
	_check_hits()


func _move_player(dt: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= dt
		vel = dash_dir * DASH_SPEED
	else:
		vel = vel.lerp(_input_dir() * SPEED, minf(1.0, dt * 12.0))
	player += vel * dt
	player.x = clampf(player.x, PLAYER_R, W - PLAYER_R)
	player.y = clampf(player.y, PLAYER_R, H - PLAYER_R)

	if vel.length() > 30.0:
		facing = lerp_angle(facing, vel.angle(), minf(1.0, dt * 14.0))
		if rng.randf() < 0.8:
			var back := -Vector2.from_angle(facing)
			var p := Particle.new()
			p.pos = player + back * 10.0
			p.vel = back.rotated(rng.randf_range(-0.4, 0.4)) * rng.randf_range(60.0, 160.0)
			p.max_life = rng.randf_range(0.18, 0.32)
			p.life = p.max_life
			p.color = Color(0.4, 1.2, 2.0) if dash_timer <= 0.0 else HOT
			p.size = rng.randf_range(1.5, 3.0)
			particles.append(p)
	trail.push_front(player)
	if trail.size() > 16:
		trail.pop_back()
	_grid_push(player, 500.0 * dt, 90.0)


func _update_sparks(dt: float) -> void:
	for s: Spark in sparks.duplicate():
		s.t += dt
		var d := player.distance_to(s.pos)
		if magnet_timer > 0.0 and d < 340.0:
			s.pos = s.pos.move_toward(player, dt * (560.0 - d))
		if d < PLAYER_R + 13.0:
			sparks.erase(s)
			var pts := 10 * combo
			score += pts
			combo = mini(combo + 1, MAX_COMBO)
			max_combo = maxi(max_combo, combo)
			combo_timer = COMBO_TIME
			_popup(s.pos, "+%d" % pts, GOLD)
			_burst(s.pos, GOLD, 14, 260.0, true)
			_ring(s.pos, 60.0, 0.35, GOLD)
			_grid_push(s.pos, 250.0, 110.0)
			_play("pickup", 1.0 + 0.07 * (combo - 1))
			_spawn_spark()
	while sparks.size() < 3 + int(level / 3):
		_spawn_spark()


func _update_pickups(dt: float) -> void:
	pickup_timer -= dt
	if pickup_timer <= 0.0:
		var p := Pickup.new()
		p.kind = rng.randi_range(0, 2)
		p.pos = _free_spot(180.0)
		pickups.append(p)
		pickup_timer = rng.randf_range(12.0, 18.0)
	for p: Pickup in pickups.duplicate():
		p.t += dt
		p.life -= dt
		if p.life <= 0.0:
			pickups.erase(p)
		elif player.distance_to(p.pos) < PLAYER_R + 16.0:
			pickups.erase(p)
			_apply_pickup(p)


func _apply_pickup(p: Pickup) -> void:
	var c := _pickup_color(p.kind)
	match p.kind:
		Power.SHIELD:
			shield = true
			_popup(p.pos, "SHIELD", c)
		Power.SLOW:
			slow_timer = 5.0
			_popup(p.pos, "SLOW TIME", c)
		Power.MAGNET:
			magnet_timer = 7.0
			_popup(p.pos, "MAGNET", c)
	_burst(p.pos, c, 24, 300.0, true)
	_ring(p.pos, 120.0, 0.5, c)
	_grid_push(p.pos, 500.0, 200.0)
	_play("power")


func _level_up(lvl: int) -> void:
	level = lvl
	_show_banner("LEVEL %d" % level)
	_ring(CENTER, 800.0, 1.0, PURPLE)
	_grid_push(CENTER, 1100.0, 900.0)
	_play("level")


func _update_hunters(dt: float, target: Vector2) -> void:
	var chase := minf(140.0 + level * 22.0, 340.0)
	for h in hunters:
		h.age += dt
		h.spin += dt * (0.8 if h.kind == Kind.SPLITTER else 3.0)
		if h.kind == Kind.DART:
			if h.warn > 0.0:
				h.warn -= dt
				if h.warn <= 0.0:
					h.vel = h.aim * (520.0 + level * 30.0)
					if state == State.PLAYING:
						_play("dart", rng.randf_range(0.9, 1.1))
		elif h.kind == Kind.SPLITTER:
			var want := (target - h.pos).normalized() * chase * 0.55
			h.vel = h.vel.lerp(want + _separation(h), minf(1.0, dt * 1.0))
		else:
			var mini_kind := h.kind == Kind.MINI
			var want := (target - h.pos).normalized() * chase * (1.35 if mini_kind else 1.0)
			h.vel = h.vel.lerp(want + _separation(h), minf(1.0, dt * (2.6 if mini_kind else 1.6)))
		h.pos += h.vel * dt

	var bounds := Rect2(-120.0, -120.0, W + 240.0, H + 240.0)
	for i in range(hunters.size() - 1, -1, -1):
		var h := hunters[i]
		if h.kind == Kind.DART and h.warn <= 0.0 and not bounds.has_point(h.pos):
			hunters.remove_at(i)


func _separation(h: Hunter) -> Vector2:
	var push := Vector2.ZERO
	for o in hunters:
		if o == h or o.kind == Kind.DART:
			continue
		var d := h.pos - o.pos
		var l := d.length()
		var min_d := h.r + o.r + 6.0
		if l < min_d and l > 0.01:
			push += d / l * (min_d - l) * 8.0
	return push


func _check_hits() -> void:
	for h: Hunter in hunters.duplicate():
		if h.kind == Kind.DART and h.warn > 0.0:
			continue
		if h.kind != Kind.DART and h.age < 0.35:
			continue
		var d := h.pos.distance_to(player)
		if d >= h.r + PLAYER_R:
			if d < h.r + PLAYER_R + GRAZE_DIST and not h.grazed and dash_timer <= 0.0 and invuln <= 0.0:
				_graze(h)
			continue
		if dash_timer > 0.0:
			_kill(h, true)
		elif invuln > 0.0:
			continue
		elif shield:
			shield = false
			invuln = 0.8
			aberr = 0.6
			_kill(h, false)
			_ring(player, 140.0, 0.5, BLUE)
			_play("shield")
		else:
			_die(h)
			return


## A hunter brushed past without touching you: a small reward for living dangerously.
func _graze(h: Hunter) -> void:
	h.grazed = true
	grazes += 1
	var pts := 5 * combo
	score += pts
	_popup(player + Vector2(0, -30), "CLOSE +%d" % pts, Color(1.4, 1.4, 1.6))
	_burst(player.lerp(h.pos, 0.5), Color(1.6, 1.6, 2.0), 6, 160.0, true)
	_play("graze", rng.randf_range(0.95, 1.1))


func _kill(h: Hunter, by_dash: bool) -> void:
	hunters.erase(h)
	kills += 1
	var base := 25
	match h.kind:
		Kind.DART:
			base = 40
		Kind.SPLITTER:
			base = 60
		Kind.MINI:
			base = 15
	var pts := base * combo
	score += pts
	var c := _hunter_color(h)
	_popup(h.pos, "+%d" % pts, c)
	_explode(h.pos, c, 1.6 if h.kind == Kind.SPLITTER else 1.0)
	hitstop = 0.045
	shake = maxf(shake, 7.0)
	aberr = maxf(aberr, 0.15)
	if by_dash:
		dash_cd = 0.0  # every dash kill refunds the dash, so kills can chain
	if h.kind == Kind.SPLITTER:
		for i in 3:
			var m := Hunter.new()
			m.kind = Kind.MINI
			m.r = 8.0
			m.pos = h.pos
			m.vel = Vector2.from_angle(TAU * i / 3.0 + rng.randf()) * 320.0
			hunters.append(m)
	_play("kill", rng.randf_range(0.9, 1.15))


func _die(h: Hunter) -> void:
	killed_by = _hunter_name(h.kind)
	state = State.DYING
	death_timer = 0.0
	shake = 20.0
	flash = 0.55
	aberr = 1.0
	_explode(player, CYAN, 3.0)
	_explode(player, HOT, 1.5)
	_play("death")
	if score > best:
		best = score
		new_best = true
		settings.best = best
		settings.save()


# --- spawning ----------------------------------------------------------

func _edge_point(out: float) -> Vector2:
	match rng.randi_range(0, 3):
		0:
			return Vector2(rng.randf_range(0.0, W), -out)
		1:
			return Vector2(rng.randf_range(0.0, W), H + out)
		2:
			return Vector2(-out, rng.randf_range(0.0, H))
		_:
			return Vector2(W + out, rng.randf_range(0.0, H))


func _free_spot(min_dist: float) -> Vector2:
	var p := CENTER
	for i in 25:
		p = Vector2(rng.randf_range(70.0, W - 70.0), rng.randf_range(80.0, H - 70.0))
		if p.distance_to(player) > min_dist:
			break
	return p


func _spawn_spark() -> void:
	var s := Spark.new()
	s.pos = _free_spot(150.0)
	s.t = rng.randf() * TAU
	sparks.append(s)


func _spawn_hunter(attract: bool) -> void:
	var h := Hunter.new()
	var roll := rng.randf()
	if not attract and level >= 3 and roll < 0.14:
		h.kind = Kind.SPLITTER
		h.r = 22.0
		h.pos = _edge_point(40.0)
	elif not attract and level >= 2 and roll < 0.42:
		h.kind = Kind.DART
		h.r = 9.0
		h.pos = _edge_point(-16.0)
		h.aim = (player - h.pos).normalized()
		h.warn = 0.85
	else:
		h.kind = Kind.CHASER
		h.r = 13.0
		h.pos = _edge_point(30.0)
	hunters.append(h)


# --- effects -----------------------------------------------------------

func _update_fx(dt: float) -> void:
	var damp := pow(0.03, dt)
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p.life -= dt
		if p.life <= 0.0:
			particles.remove_at(i)
			continue
		p.pos += p.vel * dt
		p.vel *= damp
	for i in range(rings.size() - 1, -1, -1):
		var r := rings[i]
		r.life -= dt
		if r.life <= 0.0:
			rings.remove_at(i)
			continue
		r.r = r.max_r * (1.0 - pow(r.life / r.max_life, 2.0))
	for i in range(popups.size() - 1, -1, -1):
		var p := popups[i]
		p.life -= dt
		p.pos.y -= dt * 50.0
		if p.life <= 0.0:
			popups.remove_at(i)
	banner_timer = maxf(0.0, banner_timer - dt)
	_update_grid(dt)


func _burst(at: Vector2, c: Color, n: int, power: float, streak: bool) -> void:
	for i in n:
		var p := Particle.new()
		p.pos = at
		p.vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(power * 0.25, power)
		p.max_life = rng.randf_range(0.35, 0.85)
		p.life = p.max_life
		p.color = c
		p.size = rng.randf_range(1.5, 3.5)
		p.streak = streak
		particles.append(p)


func _explode(at: Vector2, c: Color, scale: float) -> void:
	_burst(at, c, int(26 * scale), 380.0 * sqrt(scale), true)
	_burst(at, HOT, int(8 * scale), 160.0, false)
	_ring(at, 90.0 * scale, 0.45, c)
	_grid_push(at, 600.0 * scale, 170.0 * scale)


func _ring(at: Vector2, max_r: float, life: float, c: Color) -> void:
	var r := Ring.new()
	r.pos = at
	r.r = 0.0
	r.max_r = max_r
	r.life = life
	r.max_life = life
	r.color = c
	rings.append(r)


func _popup(at: Vector2, text: String, c: Color) -> void:
	var p := FloatText.new()
	p.pos = at
	p.text = text
	p.color = c
	popups.append(p)


func _grid_push(at: Vector2, force: float, radius: float) -> void:
	for y in grid_rows:
		for x in grid_cols:
			var i := y * grid_cols + x
			var p := Vector2(x * GRID_STEP, y * GRID_STEP) + grid_off[i]
			var d := p.distance_to(at)
			if d < radius and d > 0.01:
				grid_vel[i] += (p - at) / d * force * (1.0 - d / radius)


func _update_grid(dt: float) -> void:
	var damp := pow(0.05, dt)
	for i in grid_off.size():
		var v := (grid_vel[i] - grid_off[i] * 110.0 * dt) * damp
		grid_vel[i] = v
		grid_off[i] += v * dt


# --- drawing: world ----------------------------------------------------

func _draw() -> void:
	_draw_grid()
	for p in pickups:
		_draw_pickup(p)
	for s in sparks:
		_draw_spark(s)
	for h in hunters:
		_draw_hunter(h)
	if state == State.PLAYING:
		_draw_edge_warnings()
	for r in rings:
		var a := r.life / r.max_life
		draw_arc(r.pos, r.r, 0.0, TAU, 64, Color(r.color, a * 0.8), 1.0 + 3.0 * a)
	for p in particles:
		var a := p.life / p.max_life
		if p.streak:
			draw_line(p.pos, p.pos - p.vel * 0.035, Color(p.color, a), p.size * a + 0.5)
		else:
			draw_circle(p.pos, p.size * a, Color(p.color, a))
	if state == State.PLAYING:
		_draw_player()
	for p in popups:
		draw_string(font_b, p.pos - Vector2(60.0, 0.0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 20, Color(p.color, minf(1.0, p.life * 2.0)))


func _grid_color(i: int, base: Vector2) -> Color:
	var e := minf(grid_off[i].length() / 26.0, 1.0)
	var near := 0.0
	if state == State.PLAYING:
		near = clampf(1.0 - base.distance_to(player) / 170.0, 0.0, 1.0) * 0.35
	var k := maxf(e, near)
	return Color(0.22 + k * 1.1, 0.28 + k * 0.9, 0.85 + k * 1.5, 0.12 + k * 0.45)


func _draw_grid() -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for y in grid_rows:
		pts.clear()
		cols.clear()
		for x in grid_cols:
			var base := Vector2(x * GRID_STEP, y * GRID_STEP)
			var i := y * grid_cols + x
			pts.append(base + grid_off[i])
			cols.append(_grid_color(i, base))
		draw_polyline_colors(pts, cols, 1.0)
	for x in grid_cols:
		pts.clear()
		cols.clear()
		for y in grid_rows:
			var base := Vector2(x * GRID_STEP, y * GRID_STEP)
			var i := y * grid_cols + x
			pts.append(base + grid_off[i])
			cols.append(_grid_color(i, base))
		draw_polyline_colors(pts, cols, 1.0)


func _poly(at: Vector2, r: float, n: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(at + Vector2.from_angle(rot + TAU * i / n) * r)
	return pts


func _star(at: Vector2, r_out: float, r_in: float, n: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var r := r_out if i % 2 == 0 else r_in
		pts.append(at + Vector2.from_angle(rot + PI * i / n) * r)
	return pts


func _shape(pts: PackedVector2Array, c: Color, width: float) -> void:
	draw_colored_polygon(pts, Color(c.r * 0.1, c.g * 0.1, c.b * 0.1, c.a * 0.9))
	var closed := pts.duplicate()
	closed.append(pts[0])
	if soft_glow:
		draw_polyline(closed, Color(c, c.a * 0.12), width * 5.0)
		draw_polyline(closed, Color(c, c.a * 0.25), width * 2.5)
	draw_polyline(closed, c, width)


func _hunter_name(kind: int) -> String:
	match kind:
		Kind.DART:
			return "a dart"
		Kind.SPLITTER:
			return "a splitter"
		Kind.MINI:
			return "a mini"
	return "a chaser"


func _hunter_color(h: Hunter) -> Color:
	match h.kind:
		Kind.DART:
			return ORANGE
		Kind.SPLITTER:
			return PURPLE
		Kind.MINI:
			return PINK
	return RED


func _draw_hunter(h: Hunter) -> void:
	var c := Color(_hunter_color(h), minf(1.0, h.age / 0.35 + 0.2))
	match h.kind:
		Kind.DART:
			if h.warn > 0.0:
				var blink := 0.3 + 0.3 * sin(time * 30.0)
				draw_dashed_line(h.pos, h.pos + h.aim * 1600.0, Color(c, blink), 2.0, 14.0)
			else:
				draw_line(h.pos, h.pos - h.vel.normalized() * 46.0, Color(c, 0.35), 5.0)
			var xf := Transform2D(h.aim.angle(), h.pos)
			_shape(xf * PackedVector2Array([Vector2(15, 0), Vector2(-9, -8), Vector2(-4, 0), Vector2(-9, 8)]), c, 2.0)
		Kind.SPLITTER:
			_shape(_poly(h.pos, h.r, 6, h.spin), c, 2.5)
			_shape(_poly(h.pos, h.r * (0.45 + 0.08 * sin(time * 5.0)), 6, -h.spin * 1.5), c, 1.5)
		Kind.MINI:
			_shape(_star(h.pos, h.r, h.r * 0.5, 4, h.spin * 1.5), c, 1.5)
		_:
			_shape(_star(h.pos, h.r, h.r * 0.55, 6, h.spin), c, 2.0)
	draw_circle(h.pos, 2.2, Color(HOT, c.a))


## Small arrows on the screen edge for hunters that are about to come in.
func _draw_edge_warnings() -> void:
	var inner := Rect2(0.0, 0.0, W, H)
	for h in hunters:
		if inner.has_point(h.pos) or h.kind == Kind.DART:
			continue
		var at := Vector2(clampf(h.pos.x, 14.0, W - 14.0), clampf(h.pos.y, 14.0, H - 14.0))
		var dir := (CENTER - at).normalized()
		var near := clampf(1.0 - (h.pos.distance_to(at) / 120.0), 0.2, 1.0)
		var xf := Transform2D(dir.angle(), at)
		var c := Color(_hunter_color(h), 0.35 + 0.5 * near)
		draw_colored_polygon(xf * PackedVector2Array([Vector2(8, 0), Vector2(-5, -6), Vector2(-5, 6)]), c)


func _draw_spark(s: Spark) -> void:
	var pulse := 1.0 + 0.12 * sin(s.t * 6.0)
	draw_circle(s.pos, 18.0 * pulse, Color(1.0, 0.8, 0.3, 0.05))
	_shape(_poly(s.pos, 9.0 * pulse, 4, s.t * 1.5), GOLD, 2.0)
	draw_circle(s.pos, 2.5, HOT)


func _pickup_color(kind: int) -> Color:
	match kind:
		Power.SHIELD:
			return BLUE
		Power.SLOW:
			return PURPLE
	return GREEN


func _draw_pickup(p: Pickup) -> void:
	if p.life < 2.5 and int(p.life * 10.0) % 2 == 0:
		return
	var c := _pickup_color(p.kind)
	var r := 17.0 + sin(p.t * 4.0) * 1.5
	draw_circle(p.pos, r, Color(c.r * 0.08, c.g * 0.08, c.b * 0.08, 0.9))
	draw_arc(p.pos, r, 0.0, TAU, 40, c, 2.0)
	draw_arc(p.pos, r + 6.0, p.t * 2.0, p.t * 2.0 + PI * 0.6, 16, Color(c, 0.6), 1.5)
	match p.kind:
		Power.SHIELD:
			draw_arc(p.pos, 7.0, 0.0, TAU, 24, c, 2.0)
		Power.SLOW:
			draw_colored_polygon(PackedVector2Array([p.pos + Vector2(-6, -8), p.pos + Vector2(6, -8), p.pos]), c)
			draw_colored_polygon(PackedVector2Array([p.pos, p.pos + Vector2(6, 8), p.pos + Vector2(-6, 8)]), c)
		Power.MAGNET:
			draw_arc(p.pos + Vector2(0, -1), 6.0, 0.0, PI, 16, c, 3.0)
			draw_line(p.pos + Vector2(-6, -1), p.pos + Vector2(-6, -7), c, 3.0)
			draw_line(p.pos + Vector2(6, -1), p.pos + Vector2(6, -7), c, 3.0)


func _draw_player() -> void:
	if trail.size() > 1:
		var cols := PackedColorArray()
		for i in trail.size():
			cols.append(Color(0.3, 1.1, 1.8, 0.55 * (1.0 - float(i) / trail.size())))
		draw_polyline_colors(PackedVector2Array(trail), cols, 3.0)
	var c := HOT if dash_timer > 0.0 else CYAN
	if invuln > 0.0 and int(time * 20.0) % 2 == 0:
		c = Color(c, 0.3)
	draw_circle(player, 28.0, Color(0.2, 0.6, 1.0, 0.06))
	var xf := Transform2D(facing, player)
	_shape(xf * PackedVector2Array([Vector2(17, 0), Vector2(-11, -11), Vector2(-5, 0), Vector2(-11, 11)]), c, 2.5)
	draw_circle(player, 3.0, HOT)
	if shield:
		draw_arc(player, 25.0 + sin(time * 6.0) * 1.5, 0.0, TAU, 48, BLUE, 2.0)
	if magnet_timer > 0.0:
		for i in 3:
			var a := time * 3.0 + TAU * i / 3.0
			draw_arc(player, 34.0, a, a + 0.8, 10, Color(GREEN, 0.7), 2.0)


# --- drawing: HUD ------------------------------------------------------

func _htext(y: float, s: String, size: int, c: Color, f: Font = null) -> void:
	hud.draw_string(f if f else font_m, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, W, size, c)


func _bar(x: float, y: float, w: float, fill: float, c: Color) -> void:
	hud.draw_rect(Rect2(x, y, w, 6.0), Color(1, 1, 1, 0.1))
	hud.draw_rect(Rect2(x, y, w * clampf(fill, 0.0, 1.0), 6.0), c)


func _draw_hud() -> void:
	match state:
		State.TITLE:
			_htext(255.0 + sin(time * 1.5) * 5.0, "GLOWSHIFT", 104, Color(0.5, 1.25, 1.6), font_b)
			_htext(325.0, "Collect gold sparks. Dodge the hunters.", 26, TEXT)
			_htext(375.0, "Move  WASD / Arrows / Stick      Dash  Space / A      Pause  Esc / Start", 20, DIM)
			_htext(408.0, "Dash through hunters to destroy them. Each dash kill refunds your dash.", 20, DIM)
			_htext(441.0, "Grab sparks quickly to build a combo up to x10. Near misses score too.", 20, DIM)
			_htext(520.0, "PRESS SPACE", 30, Color(GOLD, 0.55 + 0.45 * sin(time * 4.0)), font_b)
			if best > 0:
				_htext(565.0, "BEST  %d" % best, 20, DIM)
			_draw_settings_line(H - 30.0)
			if version != "":
				hud.draw_string(font_m, Vector2(W - 120.0, H - 30.0), "v" + version, HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 16, Color(DIM, 0.5))
		State.PLAYING, State.DYING:
			_draw_play_hud()
		State.OVER:
			_draw_play_hud()
			hud.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, minf(0.55, over_timer)))
			_htext(225.0, "GAME OVER", 84, RED, font_b)
			_htext(315.0, str(score), 64, TEXT, font_b)
			if new_best:
				_htext(365.0, "NEW BEST!", 28, Color(GOLD, 0.6 + 0.4 * sin(time * 6.0)), font_b)
			else:
				_htext(365.0, "BEST  %d" % best, 22, DIM)
			var t := int(elapsed)
			if killed_by != "":
				_htext(410.0, "Caught by %s" % killed_by, 20, Color(RED.r * 0.4, RED.g * 0.6, RED.b * 0.6, 0.9))
			_htext(450.0, "Time %d:%02d     Kills %d     Close calls %d     Max combo x%d     Level %d" % [t / 60, t % 60, kills, grazes, max_combo, level], 22, DIM)
			if over_timer > 0.8:
				_htext(530.0, "Space to play again        Esc to quit", 24, TEXT)

	if banner_timer > 0.0 and state == State.PLAYING:
		var a := minf(1.0, banner_timer * 2.0)
		var grow := 1.0 + (1.8 - banner_timer) * 0.15
		_htext(H / 2.0 - 60.0, banner, int(64 * grow), Color(PURPLE if banner != "GO" else CYAN, a), font_b)

	if paused:
		hud.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.55))
		_htext(H / 2.0, "PAUSED", 72, CYAN, font_b)
		_htext(H / 2.0 + 50.0, "Esc to resume        Q to quit", 22, DIM)
		_draw_settings_line(H / 2.0 + 110.0)


func _draw_settings_line(y: float) -> void:
	var on := func(v: bool) -> String: return "On" if v else "Off"
	var line := "M  Sound %s      N  Music %s      V  Effects %s      F  Fullscreen" % [
		on.call(settings.sound), on.call(settings.music), "Reduced" if settings.reduced_effects else "Full"]
	_htext(y, line, 16, Color(DIM, 0.6))


func _draw_play_hud() -> void:
	hud.draw_string(font_b, Vector2(28, 58), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 44, TEXT)
	if combo > 1:
		hud.draw_string(font_b, Vector2(30, 96), "x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, GOLD)
		var frac := clampf(combo_timer / COMBO_TIME, 0.0, 1.0)
		hud.draw_arc(Vector2(100, 86), 10.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 24, GOLD, 3.0)
	_htext(36.0, "LEVEL %d" % level, 20, DIM, font_b)
	_bar(W / 2.0 - 60.0, 46.0, 120.0, fmod(elapsed, LEVEL_TIME) / LEVEL_TIME, Color(PURPLE, 0.8))
	hud.draw_string(font_m, Vector2(W - 228, 44), "BEST  %d" % best, HORIZONTAL_ALIGNMENT_RIGHT, 200, 20, DIM)

	var ready := dash_cd <= 0.0
	hud.draw_string(font_b, Vector2(W / 2.0 - 100.0, H - 40.0), "DASH", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, CYAN if ready else DIM)
	_bar(W / 2.0 - 90.0, H - 30.0, 180.0, 1.0 - dash_cd / DASH_COOLDOWN, CYAN if ready else Color(0.4, 0.7, 0.9, 0.6))

	var y := H - 34.0
	if shield:
		hud.draw_string(font_b, Vector2(28, y), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BLUE)
		y -= 28.0
	if slow_timer > 0.0:
		hud.draw_string(font_b, Vector2(28, y), "SLOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PURPLE)
		_bar(90.0, y - 10.0, 100.0, slow_timer / 5.0, PURPLE)
		y -= 28.0
	if magnet_timer > 0.0:
		hud.draw_string(font_b, Vector2(28, y), "MAGNET", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GREEN)
		_bar(100.0, y - 10.0, 100.0, magnet_timer / 7.0, GREEN)
