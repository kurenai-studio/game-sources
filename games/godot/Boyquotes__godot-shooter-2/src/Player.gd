extends CharacterBody2D

@export 
var movespeed : float = 500

const bullet_speed = 2000
const bullet = preload("res://bullet.tscn")

func _ready():
	pass

func _physics_process(delta):
	var motion = Vector2()
	
	motion.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	motion.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	motion = motion.normalized()
	velocity = motion * movespeed
	
	var collided : bool = move_and_slide()
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("fire"):
		fire()

func fire():
	var bullet_instance = bullet.instantiate()
	bullet_instance.position = global_position
	bullet_instance.rotation_degrees = rotation_degrees
	bullet_instance.apply_impulse(Vector2(bullet_speed, 0).rotated((rotation)), Vector2())
	get_tree().root.call_deferred("add_child", bullet_instance)


func _on_area_2d_body_entered(body):
	if "Enemy" in body.name:
		get_tree().reload_current_scene() 
