extends Enemy

#@onready var _tank_turret:Node3D = get_node("%TankTurret")
#@onready var _missile_battery:Node3D = get_node("%MissileBattery")
#@export var Missile_Body_Path:NodePath
#@export var Missile_Hit_Body_Path:NodePath
#
#@export var MissileBattery:bool = false
#
#
#func _ready() -> void:
	#_tank_turret.visible = true
	#_missile_battery.visible = false
	#if MissileBattery:
		#_tank_turret.visible = false
		#_missile_battery.visible = true
