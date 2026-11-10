extends CharacterBody3D

@export var speed:float = 80
var _steer_force:float = 4
var _bullet_lifetime:float = 5 #seconds
var TrackingMissile:bool = false
var Target:Vector3 = Vector3(0,0,0)

@export var projectile_damage:float = 1
@export var _impact_particles:PackedScene

func _physics_process(delta: float) -> void:
	_bullet_lifetime -= delta
	velocity = global_transform.basis.z * -speed
	if TrackingMissile:
		_steering(delta)
	var _col = move_and_collide(velocity * delta)	
	if _col:
		var _new_impact_fx:GPUParticles3D = _impact_particles.instantiate()
		get_tree().root.add_child(_new_impact_fx)
		_new_impact_fx.global_position = _col.get_position()

		if _col.get_collider().has_method("Hit_Registered"):
			_col.get_collider().Hit_Registered(projectile_damage)		
		queue_free()
	
	if _bullet_lifetime <=0.0:
		queue_free()

func _steering(delta:float) -> void:
	var _desired = global_transform.looking_at(Target,Vector3.UP)
	global_transform = global_transform.interpolate_with(_desired,_steer_force * delta)

	
