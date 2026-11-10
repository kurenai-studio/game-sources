extends CharacterBody3D
class_name Enemy

@export var _enemy_body_root_path:NodePath
@onready var _enemy_body_root:Node3D = get_node(_enemy_body_root_path)

@export var _enemy_body_hit_root_path:NodePath
@onready var _enemy_bodyhit_root:Node3D = get_node(_enemy_body_hit_root_path)
@onready var _fire_point:Marker3D = get_node("%FirePoint")
@export var Projectile:PackedScene
@export var Drops_Scrap:bool = true
@onready var _scrap:PackedScene = preload("res://Game/Scenes/scrap_pickup.tscn")


@export var Enemy_Type = _enemy_type_enum.basic_flyer

enum _enemy_type_enum {
	basic_flyer,
	small_carrier,
	beam_frigate,
	bomber,
	small_tank,
	large_tank,
	dive_bomber,
	auto_turret,
	Boss_1
}

@export var Health:float = 8
@export var _explosion_particles:PackedScene
@export var _min_fire_delay:float = 1
@export var _max_fire_delay:float = 2

var _hit_shake_period = 0.15
var _hit_shake_magnitude = 0.4
var _look_at_target:bool = false
var _look_at_location:Vector3 = Vector3()
var initial_transform:Transform3D 
@export var Allow_LookAt:bool = true
@export var TrackingMissiles:bool = false
var _new_fire_timer:Timer = null
var _new_bomb_timer:Timer = null

func _physics_process(_delta: float) -> void:

	if _look_at_target:
		look_at(Vector3(_look_at_location))

func _ready() -> void:
	randomize()
	_enemy_bodyhit_root.visible = false
	_enemy_body_root.visible = true
	initial_transform = _enemy_body_root.transform 	
	find_target()

func Hit_Registered(_pDamage:float = 1):
	if Health <= 0:
		_destroy()
	else:
		Health -= _pDamage
		_enemy_bodyhit_root.visible = true
		_impact_shake()
		await get_tree().create_timer(.1).timeout
		_enemy_bodyhit_root.visible = false

func _destroy():
	var _new_explosion_fx:GPUParticles3D = _explosion_particles.instantiate()
	get_tree().root.add_child(_new_explosion_fx)
	_new_explosion_fx.global_position = self.global_position
	
	if Drops_Scrap:
		_release_scrap()
	
	var tween = get_tree().create_tween()
	var n = Vector3(1.2,1.2,1.2)
	tween.tween_property(self,"scale",n,.1)
	tween.tween_callback(queue_free)


func _release_scrap():
	var _new_scrap:CharacterBody3D = _scrap.instantiate()	
	get_tree().root.add_child(_new_scrap)
	_new_scrap.global_transform = self.global_transform 

func find_target():
	
	match Enemy_Type:
		_enemy_type_enum.basic_flyer:
			_find_target()		
		_enemy_type_enum.auto_turret:
			_find_target()
		_enemy_type_enum.small_tank:
			pass

func _find_target():
	var _targets:Array[Vector3] = Global.get_targetable_locations()
	if _targets.size() >= 1:
		if Allow_LookAt:
			_look_at_target = true
		var _random:int = randi_range(0,_targets.size()-1)
		_look_at_location = _targets[_random]	


func _impact_shake() -> void:	
	var elapsed_time = 0.0
	while elapsed_time < _hit_shake_period:
		var offset = Vector3(
			randf_range(-_hit_shake_magnitude, _hit_shake_magnitude),
			randf_range(-_hit_shake_magnitude, _hit_shake_magnitude),
			0.0
		)

		_enemy_body_root.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame
	_enemy_body_root.transform = initial_transform

func start_firing() -> void:			
	if !is_instance_valid(_new_fire_timer):
		_new_fire_timer = Timer.new()
		_new_fire_timer.wait_time = randf_range(_min_fire_delay,_max_fire_delay)
		_new_fire_timer.connect("timeout",_fire)
		add_child(_new_fire_timer)
		_new_fire_timer.start()
		_fire()
	
func start_bombing() -> void:
	if !is_instance_valid(_new_bomb_timer):
		_new_bomb_timer = Timer.new()
		_new_bomb_timer.wait_time = randf_range(2,2)
		_new_bomb_timer.connect("timeout",_drop_bomb)
		add_child(_new_bomb_timer)
		_new_bomb_timer.start()
		_drop_bomb()

func end_all_attacks() -> void:
	if is_instance_valid(_new_bomb_timer):
		_new_bomb_timer.stop()
	if is_instance_valid(_new_fire_timer):
		_new_fire_timer.stop()
	_look_at_target = false
	rotation = Vector3(0,0,0)

func _drop_bomb():
	var _bomb_inst:RigidBody3D = Projectile.instantiate()	
	_bomb_inst.global_transform = _fire_point.global_transform
	get_tree().root.add_child(_bomb_inst)

func _fire():
	var _bullet_dupe:CharacterBody3D = Projectile.instantiate()	
	_bullet_dupe.global_transform = _fire_point.global_transform 
	get_tree().root.add_child(_bullet_dupe)
	if TrackingMissiles:
		_bullet_dupe.TrackingMissile = true
		_bullet_dupe.Target = _look_at_location
