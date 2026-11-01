extends Area2D

@export var bullet_scene: PackedScene
@export var sight: Sprite2D
const Log = preload("res://src/yaiss/logging.gd")
	
func _physics_process(_delta: float) -> void:
	# TODO: Make this callback
	if Input.is_action_just_pressed("Shoot"):
		shoot()
		
func shoot() -> void:
	Log.record_debug("Player called shoot()!", ["Player"])

	# TODO: Maybe consider decoupling player and sight?
	var bullet = bullet_scene.instantiate()
	var fire_dir = (sight.global_position - global_position).normalized()
	# TODO: Create helper class
	var spawn_distance = sight.calcPadding(self)
	
	bullet.direction = fire_dir
	bullet.global_position = global_position + (fire_dir * spawn_distance)
	bullet.rotation = fire_dir.angle()
	get_tree().root.add_child(bullet)
