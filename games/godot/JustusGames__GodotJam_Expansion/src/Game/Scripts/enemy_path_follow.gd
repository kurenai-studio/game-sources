extends Path3D

@onready var EnemyPathFollow:PackedScene = preload("res://Enemies/Scenes/enemy_path_follow.tscn")
@onready var _spawn_delay_timer:Timer = get_node("%SpawnDelay")

@export var Enemy_To_Spawn:PackedScene = null
@export var Spawn_Amount:int = 1
@export var Spawn_Delay:float = 1.0
@export var Enemy_Speed:float = .025
@export var Slow_During_Attack:bool = false


@export var Attack_Start_Ratio:float = 0.0
@export var Attack_End_Ratio:float = 0.0
@export var Is_Bomber:bool = false
@export var Is_Carrier:bool = false
@export var Attack_At_Path_End:bool = false

var _amount_spawned:int = 0

var _new_enemy_inst:Enemy = null

func start_formation_movement(pSpawnAmount:int = 1):
	_amount_spawned = 0
	Spawn_Amount = pSpawnAmount
	_spawn_new_enemy(Enemy_To_Spawn)
	_spawn_delay_timer.wait_time = Spawn_Delay
	_spawn_delay_timer.start()

func _spawn_new_enemy(pEnemyToSpawn:PackedScene):
	if _amount_spawned < Spawn_Amount:
		_amount_spawned += 1
		var _new_enemy_path:PathFollow3D = EnemyPathFollow.instantiate()
		_new_enemy_path.Enemy_Speed = Enemy_Speed
		add_child(_new_enemy_path)
		if !_new_enemy_path.is_connected("reached_path_end",_enemy_reached_path_end):
			_new_enemy_path.connect("reached_path_end",_enemy_reached_path_end)
		_new_enemy_path.loop = false
		_new_enemy_path.Bomber = Is_Bomber
		if Is_Carrier:
			_new_enemy_path.rotation_mode = PathFollow3D.ROTATION_NONE
		_new_enemy_path.Slow_During_Attack = Slow_During_Attack
		_new_enemy_path.Attack_Start_Ratio = Attack_Start_Ratio
		_new_enemy_path.Attack_End_Ratio = Attack_End_Ratio
		_new_enemy_path.Attack_At_Path_End = Attack_At_Path_End
		
		_new_enemy_inst = pEnemyToSpawn.instantiate()
		_new_enemy_path.add_child(_new_enemy_inst)

func _enemy_reached_path_end():
	pass

func _on_spawn_delay_timeout() -> void:
	if _amount_spawned < Spawn_Amount:
		_spawn_new_enemy(Enemy_To_Spawn)
