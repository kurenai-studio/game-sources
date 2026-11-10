extends CharacterBody2D

var speed = 400.0
@export var hp_max : int;
@export var money = 2;
var hp
var path : Line2D
var path_index : int = 1
var dist_travelled : int = 0;
var fire_count = 0
var fire_timer

@onready var hurtbox = $Hurtbox
var hit_once_array = [];

func _ready():
	randomize()
	var paths = get_tree().get_first_node_in_group("Path").get_children()
	path = paths.pick_random();
	hp = hp_max

func _physics_process(_delta):
	# moves to next point on path
	var dir = global_position.direction_to(path.points[path_index])
	velocity = speed*dir
	
	# if gets to end of path, enemy despawns
	# check if you can tweak the point change radius
	if (global_position - path.points[path_index]).length() < 60:
		if path_index < path.points.size()-1: # make sure to have an extra point off screen so that it doesn't conflit with array
			path_index += 1
		else:
			queue_free();
			#life loss 
	
	# move distance, update distance travelled for tower targeting
	rotation = lerp_angle(rotation, velocity.angle(), .2)
	
	var prev_pos = global_position
	move_and_slide()
	dist_travelled += (prev_pos - global_position).length()


func _on_hitbox_area_entered(area):
	if area.is_in_group("Projs"):
		# ensure that the proj hits only once 
		# the projectile connects to the enemy to allow itself to be removed later
		if not hit_once_array.has(area):
			hit_once_array.append(area)
			if area.has_signal("remove_from_array"):
				if not area.is_connected("remove_from_array",Callable(self,"remove_from_list")):
					area.connect("remove_from_array",Callable(self,"remove_from_list"));
			
			# for the juke robot's malfunction ability
			if "permanent" in area:
				if area.permanent:
					speed += area.buff_bonus*2
			
			# deal damage
			area.enemy_hit();
			hp -= area.damage;
			
			apply_effect(area.effect, area.effect_rate, area.damage)
			
			if area.effect == "Null":
				modulate = Color(1.0,0,0,1.0)
				$HitFlashTimer.start()
			else:
				
				modulate = Color(1, 0.31764706969261, 0)
				apply_effect(area.effect, area.effect_rate, area.damage)
			
			if hp <= 0:
				death()

func remove_from_list(proj):
	if hit_once_array.has(proj):
		hit_once_array.erase(proj)

func _on_hit_flash_timer_timeout():
	if fire_count <= 0:
		modulate = Color(1.0,1.0,1.0)
	elif fire_count > 0:
		modulate = Color(1, 0.31764706969261, 0)

func apply_effect(effect = "Null", duration = 0, damage = 0):
	match effect:
		"Fire":
			# starts fire timer, each timeout deals 1 damage
			fire_count = damage
			fire_timer = Timer.new();
			fire_timer.wait_time = duration;
			fire_timer.one_shot = true
			fire_timer.connect("timeout",Callable(self,"_fire_tick"))
			add_child(fire_timer)
			fire_timer.start()
			

func _fire_tick():
	# fire count == damage, ticks down
	if fire_count <= 0:
		modulate = Color(1, 1, 1)
	else:
		fire_count -= 1;
		hp -= 1
		if hp <= 0:
			death();
		
		fire_timer.start()

func death():
	# gibme loot!!
	Global.update_curr(2,0)
	queue_free();
