extends CharacterBody3D

@onready var _scrap_mesh:CSGTorus3D = get_node("CSGTorus3D")
@export var speed:float = 80
var _steer_force:float = 5
var _lifetime:float = 5 #seconds
var TrackingMissile:bool = true
var Target:Vector3 = Vector3(0,8,0)

func _physics_process(delta: float) -> void:
	_scrap_mesh.rotation += Vector3(0,0,5) * delta
	_lifetime -= delta
	velocity = global_transform.basis.z * -speed
	if TrackingMissile:
		_steering(delta)
	var _col = move_and_collide(velocity * delta)	
	if _col:
		if _col.get_collider().has_method("Scrap_Get"):
			_col.get_collider().Scrap_Get()	
		queue_free()
	
	if _lifetime <=0.0:
		queue_free()

func _steering(delta:float) -> void:
	var _desired = global_transform.looking_at(Target,Vector3.UP)
	global_transform = global_transform.interpolate_with(_desired,_steer_force * delta)

	
