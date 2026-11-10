extends Enemy

@export var Turret_Locations:Array[CharacterBody3D]

func _ready() -> void:
	var _targets:Array[Vector3] = Global.get_targetable_locations()
	_look_at_target = true
	_look_at_location = _targets[0]

func start_firing() -> void:
	#super.start_firing()	
	for turret in Turret_Locations:
		if is_instance_valid(turret):
			var _tur:Enemy = turret
			turret.add_to_group("Enemy")
			turret.find_target()
			turret.start_firing()

				
	
func end_all_attacks() -> void:
	#super.end_all_attacks()
	for turret in Turret_Locations:
		if is_instance_valid(turret):
			turret.remove_from_group("Enemy")
			turret.end_all_attacks()
