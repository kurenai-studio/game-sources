extends RigidBody3D

var _explosion_particles:PackedScene = preload("res://Game/VFX/explosion_particles.tscn")
var _lifetime:float = 10.0
var _bomb_damage:float = 5.0

func _physics_process(delta: float) -> void:
	_lifetime -= 1 * delta
	if _lifetime <=0.0:
		queue_free()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var _col = get_colliding_bodies()
	if _col.size() >= 1 and state.get_contact_count() >= 1:		
		_explode()
		if state.get_contact_collider_object(0).has_method("Hit_Registered"):
			state.get_contact_collider_object(0).Hit_Registered(_bomb_damage)		
		queue_free()
	
func _explode():
	var _new_impact_fx:GPUParticles3D = _explosion_particles.instantiate()
	get_tree().root.add_child(_new_impact_fx)
	_new_impact_fx.global_position = global_position

	
func Hit_Registered(_pDamageAmount:float = 1) -> void:
	_explode()
	queue_free()
