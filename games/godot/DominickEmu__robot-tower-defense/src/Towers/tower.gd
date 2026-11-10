extends Sprite2D

var cur_target : CharacterBody2D = null

@export_enum("Bought", "Active", "Inactive") var state = 0;
@onready var type = get_groups()[0]

@export var damage = 5
@export var rotation_delta = 0.07;
@export var proj_speed = 2600;
@export var proj_lifespan = 0.2
@export var fire_rate = 0.3;
@export var proj_size = 1.0
@export var pierce = 2;
@export var acceleration = 0.0
@export var min_fire_rate = fire_rate/3
@export var energy_max = 200
@export var energy_consumpt = 1
@export var buff = 0
@onready var energy = energy_max;
@export_enum("Fire","Null") var effect : String = "Null"
@export_enum("First","Last","Weak","Strong") var targeting : String = "First"
@export var effect_rate = 0.0
@export var cost = 100
@export var upgrade_opts : Array[String] = ["damage", "energy_consumpt"]
var buff_bonus = 0;

@onready var proj_folder = get_tree().get_first_node_in_group("Projs")
@onready var tileset : TileMap = get_tree().get_first_node_in_group("Tiles")
@onready var stat_gui : Control = get_tree().get_first_node_in_group("StatGUI")
@onready var hover_area : Area2D = $HoverArea
@onready var tower_rad : Sprite2D = %TowerRad
@onready var fire_cooldown = $FireCooldown
@onready var proj;
@onready var consume_energy = $ConsumeEnergy
@onready var range = $Range
var buff_timer := Timer.new();

var mouse_over = false;
var valid_placement = false;
var deactivate_flag = false
var grid_pos = Vector2i(0,0)

func _ready():
	fire_cooldown.wait_time = fire_rate
	match type:
		"Jukebot":
			proj = preload("res://Towers/Projs/aoe_proj.tscn");
		"SEBA":
			proj = preload("res://Towers/Projs/boom_proj.tscn");
		_:
			proj = preload("res://Towers/Projs/proj.tscn")

func _process(delta):
	match state:
		0: #Bought
			# checks if player can place the robot down
			var placable_tiles;
			grid_pos = tileset.local_to_map(get_global_mouse_position())
			
			match type:
				"Newtron":
					placable_tiles = tileset.placable_water_tiles
				_:
					placable_tiles = tileset.placable_ground_tiles
			
			if placable_tiles.has(tileset.get_cell_atlas_coords(0,grid_pos)) and !tileset.occupied_tiles.has(grid_pos):
				valid_placement = true
			else:
				valid_placement = false;
			
			if not valid_placement:
				self_modulate = Color(1.0,0,0)
			else:
				self_modulate = Color(1.0,1.0,1.0)
			
			global_position = grid_pos*128 + Vector2i(64,64)
			
			# confirms the place action and switches to active
			if Input.is_action_just_pressed("Click") and valid_placement:
				tileset.occupied_tiles.append(grid_pos);
				Global.tower_list.append(self)
				Global.bought_tower = null
				Global.update_curr(-cost,0)
				consume_energy.start()
				state = 1;
			elif Input.is_action_just_pressed("Back"):
				Global.bought_tower = null;
				queue_free()
		1: #Active
			match type:
				# jukebot simply fires whenever an enemy is near, while all the others rotate towards target
				"Jukebot":
					if range.get_overlapping_bodies().size() > 0:
						if fire_cooldown.is_stopped():
							fire_cooldown.start();
					else:
						fire_cooldown.stop()
				_:
					cur_target = target_enemy()
					if cur_target != null:
						# math to calculate whether to rotate (anti-)clockwise
						var angle_to_target = cur_target.global_position - global_position
						var difference = fmod((angle_to_target).angle() - rotation, 2*PI)
						var angle_dist = fmod(2 * difference, 2*PI) - difference
						
						rotation = move_toward(rotation, rotation+angle_dist, rotation_delta*delta)
						
						# stops firing if target is too far away
						if angle_dist < PI/6 and angle_dist > -(PI/6):
							if fire_cooldown.is_stopped():
								fire_cooldown.start()
						
						if not range.get_overlapping_bodies().has(cur_target):
							if range.get_overlapping_bodies().size() > 0:
								cur_target = target_enemy();
							else:
								cur_target = null;
								fire_cooldown.stop()
								fire_cooldown.wait_time = fire_rate
						elif not is_instance_valid(cur_target):
							range.get_overlapping_bodies().erase(cur_target)
							cur_target = null
			
			tower_rad.visible = mouse_over
			
			if Input.is_action_just_pressed("Click") and mouse_over:
				Global.highlighted_tower = self;
				stat_gui.update_gui();
			
			if energy <= 0:
				state = 2;
				fire_cooldown.stop()
				if Global.highlighted_tower == self:
					Global.highlighted_tower = null
				self_modulate = Color(0.38, 0.38, 0.38)
				modulate = Color(1,1,1)
		2: #Inactive
			if !deactivate_flag:
				match type:
					"SEBA":
						deactivate_flag = true
						
						rotation = 0
						texture = load("res://Textures/Towers/scorchmark.png");
						var adj_tiles = []
						for i in range(-1,2):
							for j in range(-1,2):
								var diff = Vector2i(i,j)
								
								if tileset.placable_ground_tiles.has(tileset.get_cell_atlas_coords(0,grid_pos+diff)) or tileset.placable_water_tiles.has(tileset.get_cell_atlas_coords(0,grid_pos+diff)):
									tileset.set_cell(0,grid_pos+diff,0,Vector2i(0,3))
								
								if diff != Vector2i(0,0):
									for t in Global.tower_list:
										if is_instance_valid(t):
											if t.grid_pos == grid_pos+diff:
												tileset.occupied_tiles.erase(grid_pos+diff)
												t.queue_free()
								
					"Newtron":
						var adj_tiles = []
						for i in range(-1,2):
							for j in range(-1,2):
								var diff = Vector2i(i,j)
								
								if tileset.placable_ground_tiles.has(tileset.get_cell_atlas_coords(0,grid_pos+diff)) or tileset.placable_water_tiles.has(tileset.get_cell_atlas_coords(0,grid_pos+diff)):
									tileset.set_cell(0,grid_pos+diff,0,Vector2i(0,2))
								
								for t in Global.tower_list:
									if is_instance_valid(t):
										if t.grid_pos == grid_pos+diff and (t.type != "Newtron" or t == self):
											tileset.occupied_tiles.erase(grid_pos+diff)
											t.queue_free()
					"Jukebot":
						deactivate_flag = true;
						
						proj_lifespan = 3;
						fire_proj()
					"Gatling Golem":
						min_fire_rate += 0.01;
						rotation = randf_range(-PI, PI)
						
						fire_proj()
						if min_fire_rate >= fire_rate:
							deactivate_flag = true
	
	

func target_enemy() -> CharacterBody2D:
	# sorts list of enemies to make all towers possible to target specific properties of enemies
	if range.get_overlapping_bodies().size() > 0:
		if fire_cooldown.is_stopped():
			fire_cooldown.start();
		
		var enemy_vals = []
		for i in range.get_overlapping_bodies():
			match targeting:
				"First","Last":
					enemy_vals.append(i.dist_travelled)
				"Weak", "Strong":
					enemy_vals.append(i.hp)
		enemy_vals.sort()
		
		var target_val
		match targeting:
			"First", "Strong":
				target_val = enemy_vals[enemy_vals.size()-1];
			"Last", "Weak":
				target_val = enemy_vals[0]
		
		for i in range.get_overlapping_bodies():
			match targeting:
				"First","Last":
					if i.dist_travelled == target_val:
						return i
				"Strong","Weak":
					if i.hp == target_val:
						return i
		
		return range.get_overlapping_bodies()[0];
	else:
		fire_cooldown.stop();
		fire_cooldown.wait_time = fire_rate
		return null;
	

func fire_proj():
	# fires proj specific to tower. certain towers use diff projs (see _ready())
	var shooty = proj.instantiate();
	shooty.global_position = global_position
	shooty.damage = damage+buff_bonus
	shooty.speed = proj_speed;
	shooty.pierce = pierce;
	shooty.lifespan = proj_lifespan
	shooty.dir = Vector2(cos(rotation), sin(rotation))
	shooty.size = proj_size
	shooty.effect = effect
	shooty.effect_rate = effect_rate
	
	match type:
		"Jukebot":
			shooty.buff_bonus = buff;
			shooty.permanent = deactivate_flag
	
	proj_folder.add_child(shooty)

func _on_fire_cooldown_timeout():
	fire_cooldown.wait_time = clamp(fire_cooldown.wait_time-acceleration,min_fire_rate,fire_rate)
	fire_proj()

func _on_range_body_entered(body):
	if state != 0:
		range.get_overlapping_bodies().append(body)

func _on_range_body_exited(body):
	range.get_overlapping_bodies().erase(body)


func _on_hover_area_mouse_entered():
	mouse_over = true;

func _on_hover_area_mouse_exited():
	mouse_over = false;


func _on_consume_energy_timeout():
	# ticks down energy based on energy_consumpt
	if state == 1 and energy > 0:
		energy = max(energy-energy_consumpt,0);
		if energy < 11:
			if modulate != Color(1.0,0,0):
				modulate = Color(1.0,0,0)
			else:
				modulate = Color(1,1,1)


func _on_hover_area_area_entered(area):
	# modifies damage based on juke's buff
	if area.is_in_group("Buff"):
		if !area.permanent:
			buff_bonus = area.buff_bonus
			
			buff_timer.queue_free()
			buff_timer = Timer.new();
			buff_timer.wait_time = area.lifespan*4;
			buff_timer.one_shot = true
			buff_timer.connect("timeout",Callable(self,"_remove_buff"))
			add_child(buff_timer)
			buff_timer.start()
		else:
			damage += area.buff_bonus

func _remove_buff():
	buff_bonus = 0
