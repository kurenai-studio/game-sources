extends Control

var source_body:CharacterBody3D = null
@onready var _damage_rect:TextureRect = get_node("%DamageIndicator")

#func _physics_process(delta: float) -> void:
	#if source_body != null:
		#damage_indicator_look_at.look_at(damage_indicator_target.global_transform.origin, Vector3.UP)
		#damage_indicator.rotation = -damage_indicator_look_at.rotation.y
	#else:
		#damage_indicator.visible = false

func update_damage_source(_pRotation:float):
	_damage_rect.rotation = _pRotation
	await get_tree().create_timer(.8).timeout
	queue_free()
	
