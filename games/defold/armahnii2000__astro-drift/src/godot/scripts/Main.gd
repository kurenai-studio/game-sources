extends Node2D

const STARTING_LIVES := 3
const STARTING_ASTEROIDS := 4
const SCORE_FOR_SIZE := [100, 50, 20]

var player: Player
var hud: HUD
var crt_layer: CanvasLayer
var crt_enabled: bool = true
var score: int = 0
var lives: int = STARTING_LIVES
var game_over: bool = false
var screen_size: Vector2
var wave: int = 1

func _ready() -> void:
	randomize()
	screen_size = get_viewport_rect().size
	hud = HUD.new()
	add_child(hud)
	_setup_crt()
	_start_game()

func _setup_crt() -> void:
	crt_layer = CanvasLayer.new()
	crt_layer.layer = 100
	var rect := ColorRect.new()
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crt.gdshader")
	mat.set_shader_parameter("resolution", screen_size)
	rect.material = mat
	crt_layer.add_child(rect)
	add_child(crt_layer)

func _toggle_crt() -> void:
	crt_enabled = not crt_enabled
	crt_layer.visible = crt_enabled

func _start_game() -> void:
	for c in get_children():
		if c is Player or c is Asteroid or c is Bullet:
			c.queue_free()
	score = 0
	lives = STARTING_LIVES
	game_over = false
	wave = 1
	_spawn_player()
	_spawn_wave()
	hud.update_stats(score, lives)
	hud.show_message("")

func _spawn_wave() -> void:
	var count := STARTING_ASTEROIDS + wave - 1
	for i in range(count):
		_spawn_asteroid_at_edge(Asteroid.SIZE_LARGE)

func _spawn_player() -> void:
	if is_instance_valid(player):
		player.queue_free()
	player = Player.new()
	player.position = screen_size / 2.0
	player.shoot_requested.connect(_on_player_shoot)
	player.died.connect(_on_player_died)
	add_child(player)

func _spawn_asteroid_at_edge(size_tier: int) -> void:
	var a := Asteroid.new()
	a.size_tier = size_tier
	var edge := randi() % 4
	match edge:
		0: a.position = Vector2(randf() * screen_size.x, -40.0)
		1: a.position = Vector2(screen_size.x + 40.0, randf() * screen_size.y)
		2: a.position = Vector2(randf() * screen_size.x, screen_size.y + 40.0)
		_: a.position = Vector2(-40.0, randf() * screen_size.y)
	var to_center := (screen_size / 2.0 - a.position).normalized()
	var angle := to_center.angle() + randf_range(-0.5, 0.5)
	a.velocity = Vector2.from_angle(angle) * randf_range(70.0, 130.0)
	a.destroyed.connect(_on_asteroid_destroyed)
	add_child(a)

func _spawn_asteroid_at(pos: Vector2, size_tier: int) -> void:
	var a := Asteroid.new()
	a.size_tier = size_tier
	a.position = pos
	a.velocity = Vector2.from_angle(randf() * TAU) * randf_range(100.0, 200.0)
	a.destroyed.connect(_on_asteroid_destroyed)
	add_child(a)

func _on_player_shoot(pos: Vector2, dir: Vector2) -> void:
	var b := Bullet.new()
	b.position = pos
	b.direction = dir
	add_child(b)

func _on_player_died() -> void:
	lives -= 1
	hud.update_stats(score, lives)
	if lives <= 0:
		game_over = true
		hud.show_message("GAME OVER\nPress End to restart")
		return
	await get_tree().create_timer(1.2).timeout
	if not game_over:
		_spawn_player()

func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	var size_tier := asteroid.size_tier
	score += SCORE_FOR_SIZE[size_tier]
	hud.update_stats(score, lives)
	if size_tier > Asteroid.SIZE_SMALL:
		for i in range(2):
			_spawn_asteroid_at(asteroid.position, size_tier - 1)
	if _count_asteroids_remaining(asteroid) == 0 and not game_over:
		wave += 1
		await get_tree().create_timer(1.4).timeout
		if game_over:
			return
		hud.show_message("Wave %d" % wave)
		await get_tree().create_timer(1.0).timeout
		hud.show_message("")
		_spawn_wave()

func _count_asteroids_remaining(exclude: Asteroid) -> int:
	var n := 0
	for c in get_children():
		if c is Asteroid and c != exclude and not c.is_queued_for_deletion():
			n += 1
	return n

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_INSERT:
			_toggle_crt()
		elif game_over and event.keycode == KEY_END:
			_start_game()
