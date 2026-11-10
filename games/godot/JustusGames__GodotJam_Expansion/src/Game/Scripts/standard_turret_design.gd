extends Node3D
class_name StandardTurret

@export var FirePointLocatons:Array[Marker3D]
@onready var FireRateTimer:Timer = get_node("%FireRateTimer")
@onready var _gun_barrel:Node3D = get_node("%BarrelRoot")
@export var Current_Gun_Level:int = 0

@onready var _level_2_upgrade_root:Node3D = get_node("%Level_2_Upgrade")
@onready var _level_1_upgrade_root:Node3D = get_node("%Level_1_Upgrade")
@onready var _level_1_barrel_upgrade_root:Node3D = get_node("%Level_1_Barrel_Upgrade")
@onready var _level_1_upgrade_firepoint_1:Marker3D = get_node("%Level1_FirePoint_1")
@onready var _level_1_upgrade_firepoint_2:Marker3D = get_node("%Level1_FirePoint_2")
@onready var _level_2_missile_battery:CharacterBody3D = get_node("%AutoTargetingTurret")

func _ready() -> void:
	set_gun_level(0)
	
	
func set_gun_level(pLevel:int = 0):
	Current_Gun_Level = pLevel
	match Current_Gun_Level:
		0:
			_default_gun_level()
		1:
			_level_1_gun()
		2:
			_level_2_gun()
		3:
			pass

func _default_gun_level():
	_level_1_upgrade_root.visible = false
	_level_1_barrel_upgrade_root.visible = false
	_level_2_upgrade_root.visible = false
	
	var _find_firepoint_1 = FirePointLocatons.find(_level_1_upgrade_firepoint_1)
	if _find_firepoint_1 >= 0:
		FirePointLocatons.remove_at(_find_firepoint_1)

	var _find_firepoint_2 = FirePointLocatons.find(_level_1_upgrade_firepoint_2)
	if _find_firepoint_2 >= 0:
		FirePointLocatons.remove_at(_find_firepoint_2)

func _level_1_gun():
	_level_1_upgrade_root.visible = true
	_level_1_barrel_upgrade_root.visible = true
	_level_2_upgrade_root.visible = false
	
	FirePointLocatons.append(_level_1_upgrade_firepoint_2)
	FirePointLocatons.append(_level_1_upgrade_firepoint_1)

func _level_2_gun():
	_level_1_upgrade_root.visible = true
	_level_1_barrel_upgrade_root.visible = true
	_level_2_upgrade_root.visible = true

func launch_missiles():
	_level_2_missile_battery._fire()

func fire(pBullet:PackedScene) -> void:
	
	var tween = get_tree().create_tween()
	var n = Vector3(0,.879,-1.2)
	tween.tween_property(_gun_barrel,"position",n,.1)
	tween.tween_property(_gun_barrel,"position",Vector3(0,.879,-2.2),.1)
	
	for firepoint in FirePointLocatons:
		var _bullet_dupe:CharacterBody3D = pBullet.instantiate()	
		_bullet_dupe.global_transform = firepoint.global_transform
		_bullet_dupe.speed += Current_Gun_Level * 50
		get_tree().root.add_child(_bullet_dupe)
