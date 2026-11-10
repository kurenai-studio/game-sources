extends CharacterBody3D

@onready var _main_camera:Camera3D = get_node("%Camera3D")
@export var _building_camera:Camera3D
@onready var _turret:StandardTurret = get_node("%StandardTurret")
@onready var _HUD:Control = get_node("%HUD")
@onready var _Pause_Menu:Control = get_node("%PauseMenu")
@onready var _WinOrLose:Control = get_node("%WinOrLose")
@export var _basic_bullet:PackedScene
@onready var _ammo_reload_timer:Timer = get_node("%AmmoReloadTimer")

@export var _forcefield_path:NodePath
@onready var _player_forcefield:StaticBody3D = get_node(_forcefield_path)
@onready var _indicator_lookat:Marker3D = get_node("%Indicator_LookAt")

#################
enum turret_states {
	turret_mode,
	building_mode
}
var current_turret_state:int = turret_states.turret_mode
#################
var Ammo_Count:int = 250
var Max_Ammo_Count:int = 500
var Ammo_Reload_Amount:int = 1
var Max_Health:float = 100
var Current_Health:float = 50
var Max_Energy:float = 100.0
var Current_Energy:float = 100.0
var Energy_Charge_Rate:float = .1
@export var Fire_Rate:float = 5
#################
var _mouse_sensitivity = .002
var _current_gun_level:int = 0
var _camera_rotation:Vector2 = Vector2(0,0)
var _allow_firing:bool = true
var _allow_missile_launch:bool = true
var _in_build_mode:bool = false
var _current_scrap_amount:int = 25
var _firing_cooldown:float = 0.0
var _launching_cooldown:float = 0.0
var _looked_at_object:Object = null
var _current_mouse_mode = null
var _selected_build_spot:BuildSpot = null
var _building_count_dict:Dictionary = {
	"Power":0,
	"Ammo":0,
	"Health":0,
	"Upgrade":0
}
var _building_cost_dict:Dictionary = {
	"Power":5,
	"Ammo":10,
	"Health":20,
	"Upgrade":100
}
#################

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_current_mouse_mode = Input.MOUSE_MODE_CAPTURED
	_HUD.update_energy(Current_Energy)
	_HUD.connect("building_placed",_on_building_place)
	Global.add_to_targetable_locations(self.global_position)
	_Pause_Menu.connect("pause_menu_closed",_on_pause_menu_closed)
	_HUD.update_scrap(_current_scrap_amount)
	

	
	
func _on_pause_menu_closed():
	Input.mouse_mode = _current_mouse_mode

func Boss_Killed():
	await  get_tree().create_timer(2).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_HUD.visible = false
	_WinOrLose.show_results("BOSS DEFEATED!")

func _on_building_place(pBuilding:String):
	if is_instance_valid(_selected_build_spot):
		if _selected_build_spot.spot_taken == false and _current_scrap_amount >= _building_cost_dict[pBuilding]:
			_current_scrap_amount -= _building_cost_dict[pBuilding]
			_selected_build_spot.spawn_new_building(pBuilding)
			if !_selected_build_spot.is_connected("building_was_destroyed",_on_building_destroyed):
				_selected_build_spot.connect("building_was_destroyed",_on_building_destroyed.bind(pBuilding))
			_building_count_dict[pBuilding] += 1
			match pBuilding:
				"Ammo":
					update_reload_wait()				
				"Power":
					if is_instance_valid(_player_forcefield):
						var _charge_shield_amount:float = _building_count_dict["Power"]
						_player_forcefield.Increase_Shield_Radius(8)
				"Upgrade":
					_current_gun_level = _building_count_dict[pBuilding]
					_turret.set_gun_level(_current_gun_level)	
					Fire_Rate += _current_gun_level * 3
					
			_selected_build_spot = null

func _on_building_destroyed(_pBuilding:String):
	if _pBuilding == "Ammo":
		_ammo_reload_timer.wait_time += .2
	if _building_count_dict[_pBuilding] > 0:
		_building_count_dict[_pBuilding] -= 1	
	if _pBuilding == "Power" and is_instance_valid(_player_forcefield):
		var _charge_shield_amount:float = _building_count_dict["Power"]
		_player_forcefield.Decrease_Shield_Radius(8)
	if _pBuilding == "Upgrade":
		_current_gun_level = _building_count_dict[_pBuilding]
		_turret.set_gun_level(_current_gun_level)
	
func _physics_process(_delta: float) -> void:
	match current_turret_state:
		turret_states.building_mode:	
			var space = get_world_3d().direct_space_state
			var mousePosViewport = get_viewport().get_mouse_position()
			var camera = _building_camera
			var rayOrigin = camera.project_ray_origin(mousePosViewport)
			var rayEnd = rayOrigin+camera.project_ray_normal(mousePosViewport)*1000
			var detectionParameters = PhysicsRayQueryParameters3D.new() 
			detectionParameters.collide_with_areas = true
			detectionParameters.collide_with_bodies = false
			detectionParameters.from = rayOrigin
			detectionParameters.to = rayEnd

			var rayArray = space.intersect_ray(detectionParameters)
			if rayArray:
				_looked_at_object = rayArray["collider"]
			else:
				_looked_at_object = null
		#turret_states.turret_mode:
			#for body in _damage_indicator_array:
				#_indicator_lookat.look_at(body.global_transform.origin, Vector3.UP)
				#var _new_rotation = -_indicator_lookat.rotation.y
				#_HUD.spawn_damage_indicator(_new_rotation)

				
func _process(delta: float) -> void:
	_update_hud(delta)
	match current_turret_state:
		turret_states.turret_mode:
			_primary_fire_held(delta)
			_secondary_fire_held(delta)
		turret_states.building_mode:
			pass	

func _update_hud(delta:float):
	_player_forcefield.heal_shield(_building_count_dict["Power"] * 3 * delta)
	if Current_Energy <= Max_Energy:
		var building_total_charge:float = _building_count_dict["Power"] * .003
		Current_Energy += delta * Energy_Charge_Rate + building_total_charge
		_HUD.update_energy(Current_Energy)
	if Current_Health >= 0 and Current_Health < Max_Health:
		Current_Health += delta * _building_count_dict["Health"] * .01
		_HUD.update_health(Current_Health)
	if Ammo_Count <= Max_Ammo_Count:
		_HUD.update_ammo(Ammo_Count)

func _heal_player(pHealAmount:float = 1.0):
	Current_Health += pHealAmount + _building_count_dict["Health"]

func _primary_fire_held(delta):
	if Input.is_action_pressed("Primary Fire") and _allow_firing and Ammo_Count > 0:
		if is_instance_valid(_turret):
			_turret.fire(_basic_bullet)
			Ammo_Count -= 1
			_main_camera.CameraShake()
			_allow_firing = false
			_firing_cooldown = 1.0 / Fire_Rate
	
	if !_allow_firing:
		_firing_cooldown -= delta
		if _firing_cooldown <= 0.0:
			_allow_firing = true	

func _secondary_fire_held(delta):
	if Input.is_action_pressed("Alternate Fire") and _allow_missile_launch and Ammo_Count > 0 and _current_gun_level >= 2:
		if is_instance_valid(_turret):
			_turret.launch_missiles()
			Ammo_Count -= 1
			_main_camera.CameraShake()
			_allow_missile_launch = false
			_launching_cooldown = 1.0 / Fire_Rate
	
	if !_allow_missile_launch:
		_launching_cooldown -= delta
		if _launching_cooldown <= 0.0:
			_allow_missile_launch = true	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var MouseEvent = event.relative * _mouse_sensitivity
		CameraLook(MouseEvent)
	
	if event.is_action_pressed("Alternate Fire"):
		match current_turret_state:
			turret_states.turret_mode:
				pass
	
	if event.is_action_pressed("Pause Menu"):
		if !_Pause_Menu.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_Pause_Menu.visible = true
	if event.is_action_released("Left Click"):
		match current_turret_state:
			turret_states.building_mode:
				if is_instance_valid(_looked_at_object) and _looked_at_object.name.begins_with("BuildSpot"):
					if _looked_at_object.spot_taken == false:
						_HUD.show_menu_at_mouse(event)
						_selected_build_spot = _looked_at_object
				else:
					_HUD.remove_menus()
					_selected_build_spot = null
	
	if event.is_action_pressed("SwitchCamera"):
		if is_instance_valid(_building_camera):
			match current_turret_state:
				turret_states.turret_mode:
					_building_camera.current = true
					_main_camera.current = false
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					_current_mouse_mode = Input.MOUSE_MODE_VISIBLE
					_HUD.toggle_reticle(false)				
					current_turret_state = turret_states.building_mode
				turret_states.building_mode:
					_main_camera.current = true
					_building_camera.current = false
					_HUD.toggle_reticle(true)
					_HUD.remove_menus()
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					_current_mouse_mode = Input.MOUSE_MODE_CAPTURED
					current_turret_state = turret_states.turret_mode

func Scrap_Get():
	_current_scrap_amount += 10
	_HUD.update_scrap(_current_scrap_amount)

func update_reload_wait() -> void:
	_ammo_reload_timer.wait_time -= .2

func _on_ammo_reload_timer_timeout() -> void:
	if Ammo_Count < Max_Ammo_Count:
		var _clamp_reload = clamp(clamp(Ammo_Reload_Amount,1,99) + _building_count_dict["Ammo"],1,99) * 10
		Ammo_Count += _clamp_reload
		_HUD.show_ammmo_reload_amount(_clamp_reload)

func Hit_Registered(_pDamage:float = 1.0):
	if Current_Health <= 0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_HUD.visible = false
		_WinOrLose.show_results("GAME OVER")
	else:
		Current_Health -= _pDamage
		_main_camera.period = 0.03
		_main_camera.magnitude = 0.02
		_main_camera.CameraShake()

func CameraLook(Movement: Vector2):
	if !_in_build_mode:
		_camera_rotation += Movement
		transform.basis = Basis()	
		rotate_object_local(Vector3(0,1,0),-_camera_rotation.x)
		rotate_object_local(Vector3(1,0,0), -_camera_rotation.y)
		_camera_rotation.y = clamp(_camera_rotation.y,-1.5,1.2)

func _on_heal_timer_timeout() -> void:
	_heal_player(0.0)

func _on_threat_detection_body_entered(body: CharacterBody3D) -> void:
	if body.is_in_group("Enemy"):
		_indicator_lookat.look_at(body.global_transform.origin, Vector3.UP)
		var _new_rotation = -_indicator_lookat.rotation.y
		_HUD.spawn_damage_indicator(_new_rotation)
