extends Enemy

@export var Turret_Locations:Array[CharacterBody3D]
@onready var _boss_head:Enemy = get_node("%Head")



func start_firing() -> void:
	if is_instance_valid(_boss_head):
		_boss_head.start_firing()

func end_all_attacks() -> void:
	if is_instance_valid(_boss_head):
		_boss_head.end_all_attacks()


func _destroy():
	get_tree().call_group("Player","Boss_Killed")
	super._destroy()
