extends Enemy

@onready var _enemy_path_spawn_r:Path3D = get_node("%EnemySpawner_R")
@onready var _enemy_path_spawn_l:Path3D = get_node("%EnemySpawner_L")
@onready var _weak_point_armor:StaticBody3D = get_node("%WeakPointArmor")
@onready var _release_flyers_timer:Timer = get_node("%ReleaseFlyersTimer")

@export var Turret_Locations:Array[CharacterBody3D]

var _max_flyer_patterns:int = 3
var _current_flyer_patterns:int = 0

func ReleaseFlyers():
	if _current_flyer_patterns < _max_flyer_patterns:
		_current_flyer_patterns += 1
		_enemy_path_spawn_l.start_formation_movement(5)
		_enemy_path_spawn_r.start_formation_movement(5)
		_release_flyers_timer.start()
	else:
		_release_flyers_timer.stop()

func start_firing() -> void:
	var tween = get_tree().create_tween()
	var n = Vector3(0.0,-16.901,5.162)
	tween.tween_property(_weak_point_armor,"position",n,.1)
	tween.tween_property(_weak_point_armor,"position",Vector3(0.0,-16.901,-5.861),.1)
	_weak_point_armor.visible = false
	_weak_point_armor.get_child(0).disabled = true
	
	for turret in Turret_Locations:
		if is_instance_valid(turret):
			var _tur:Enemy = turret
			turret.add_to_group("Enemy")
			turret.find_target()
			turret.start_firing()

func end_all_attacks() -> void:
	for turret in Turret_Locations:
		if is_instance_valid(turret):
			turret.remove_from_group("Enemy")
			turret.end_all_attacks()


func _on_release_flyers_timer_timeout() -> void:
	ReleaseFlyers()
