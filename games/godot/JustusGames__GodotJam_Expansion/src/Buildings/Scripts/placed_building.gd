extends StaticBody3D
class_name PlacedBuilding

@export var Current_Health:float = 20

@onready var _building_hit_root:Node3D = get_node("%BuildingHIT")
var _explosion_particles:PackedScene = preload("res://Game/VFX/explosion_particles.tscn")

signal placed_building_destroyed

func _ready() -> void:
	_building_hit_root.visible = false

func Hit_Registered(_pDamage:float = 1.0):
	if Current_Health <= 0:
		_destroy()
	else:
		Current_Health -= _pDamage
		_building_hit_root.visible = true
		await get_tree().create_timer(.1).timeout
		_building_hit_root.visible = false

func _destroy():
	var _new_explosion_fx:GPUParticles3D = _explosion_particles.instantiate()
	get_tree().root.add_child(_new_explosion_fx)
	_new_explosion_fx.global_position = self.global_position
	emit_signal("placed_building_destroyed")
	queue_free()
