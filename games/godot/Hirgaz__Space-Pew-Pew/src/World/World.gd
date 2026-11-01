extends Node2D


@onready var asteroids_root := $AsteroidsRoot
@onready var camera := $Camera2D
@onready var spawn_point := $SpawnPath/SpawnPoint
@onready var world_bounds := $WorldBounds
@onready var world_bounds_shape := $WorldBounds/WorldBoundsShape


@export var asteroid_scenes : Array[PackedScene]


func _update_bounds() -> void:
	# TODO: Decide on logic for scene resize.
	#var shape := world_bounds_shape.shape as RectangleShape2D
	#shape.size = get_viewport_rect().size
	pass


func _ready() -> void:
	# Detect window size changes.
	get_window().size_changed.connect(_update_bounds)
	_update_bounds()

	_on_spawn_timer_timeout()


func _on_world_bounds_body_exited(body: Node2D) -> void:
	if body.has_method(&"exit_map"):
		body.exit_map()


func _on_spawn_timer_timeout() -> void:
	assert(not asteroid_scenes.is_empty())

	var asteroid : RigidBody2D = (asteroid_scenes.pick_random() as PackedScene).instantiate()

	# Find position using path.
	spawn_point.progress_ratio = randf()

	var spawn_pos : Vector2 = spawn_point.global_position

	# Get direction from spawn position, rotated by 90 degrees.
	var spawn_dir : float = spawn_point.rotation + PI / 2.0

	# Offset direction randomly.
	spawn_dir += randf_range(-PI / 8, PI / 8)

	asteroid.position = spawn_pos
	asteroid.rotation = randf() * 2 * PI
	asteroid.linear_velocity = Vector2(randf_range(150.0, 300.0), 0.0).rotated(spawn_dir)
	asteroid.angular_velocity = randf_range(PI / 4.0, PI / 3.0)

	asteroids_root.add_child(asteroid)
