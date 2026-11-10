extends StaticBody3D

@onready var _forcfield_mesh:CSGSphere3D = get_node("%Forcfield")
@onready var _forcfield_hit:CSGSphere3D = get_node("%ForcfieldHIT")
@onready var _forcfield_col_shape:CollisionShape3D = get_node("%CollisionShape3D")
@onready var _reset_timer:Timer = get_node("ResetTimer")
var offset_x:float = 0
var _max_shield_health = 1000
var _current_shield_health = 200
var ForcfieldEnergy:float = 0.0


func _process(delta: float) -> void:
	offset_x += .01 * delta
	_forcfield_mesh.material.set("uv1_offset",Vector3(offset_x,-offset_x,0))
	
	#if ForcfieldEnergy >= 0.0:
		#_forcfield_col_shape.shape.radius += ForcfieldEnergy
		#_forcfield_mesh.radius += ForcfieldEnergy
		
func Hit_Registered(_pDamage:float = 1):
	if _current_shield_health <= 0:
		_destroy()
	else:
		_current_shield_health -= _pDamage
		_forcfield_hit.visible = true
		await get_tree().create_timer(.1).timeout
		_forcfield_hit.visible = false

func heal_shield(pHealAmount:float = 1.0):
	if _current_shield_health < _max_shield_health:
		_current_shield_health += pHealAmount

func Increase_Shield_Radius(pAmount:float = 1.0):
	_forcfield_col_shape.shape.radius += pAmount
	_forcfield_mesh.radius += pAmount
	_forcfield_hit.radius += pAmount
	
func Decrease_Shield_Radius(pAmount:float = 1.0):
	_forcfield_col_shape.shape.radius -= pAmount
	_forcfield_mesh.radius -= pAmount
	_forcfield_hit.radius -= pAmount

func _destroy():
	self.visible = false
	_forcfield_col_shape.disabled = true
	_reset_timer.start()

func _reset():
	self.visible = true
	_forcfield_col_shape.disabled = false
	_current_shield_health = 200

func _on_body_entered(_body: Node3D) -> void:
	pass


func _on_reset_timer_timeout() -> void:
	_reset()
