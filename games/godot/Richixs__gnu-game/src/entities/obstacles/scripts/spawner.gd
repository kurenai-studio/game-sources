extends Node2D

@export var ground_obstacles: Array[PackedScene] = []
@export var air_obstacles: Array[PackedScene] = []
@export var min_spawn_time: float = 1.2
@export var max_spawn_time: float = 2.5
@export var ground_y: float = 280.0 
@export var air_y: float = 150.0
@export_range(0.0, 1.0) var air_probability: float = 0.3

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_spawn_obstacle)
	_start_timer()

func _start_timer() -> void:
	timer.start(randf_range(min_spawn_time, max_spawn_time))

func _spawn_obstacle() -> void:
	var obstacle_instance: Area2D = null
	
	var is_air = randf() < air_probability 
	
	if is_air and air_obstacles.size() > 0:
		var random_index = randi() % air_obstacles.size()
		obstacle_instance = air_obstacles[random_index].instantiate()
		var lower_limit = ground_y - 10.0
		obstacle_instance.position.y = randf_range(air_y, lower_limit)
		
	elif ground_obstacles.size() > 0:
		var random_index = randi() % ground_obstacles.size()
		obstacle_instance = ground_obstacles[random_index].instantiate()
		obstacle_instance.position.y = ground_y

	if obstacle_instance:
		obstacle_instance.position.x = global_position.x
		get_parent().add_child(obstacle_instance)

	_start_timer()
