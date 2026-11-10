extends Marker2D

@onready var spawn_timer = %SpawnTimer
@onready var next_wave_notif = preload("res://GUI/next_wave_notif.tscn")
@export var wave_array : Array[wave_data]
var enemy_index = -1
var enemies_spawned = 0;
var wave_notif_visible = false;

func _ready():
	spawn_timer = %SpawnTimer

func _on_spawn_timer_timeout():
	# checks how many enemies and the type of enemy are spawned. spacing controls the timer wait_time
	if enemies_spawned <= 0:
		enemy_index += 1
		if enemy_index < wave_array.size():
			enemies_spawned = wave_array[enemy_index].amount;
			spawn_timer.wait_time = wave_array[enemy_index].spacing;
			if wave_array[enemy_index].next_wave:
				show_wave_notif();
		else: # stops spawner at the end of the wave data array
			spawn_timer.stop()
	else: # spawns enemies
		var rand_vector = Vector2(randi_range(-32,0), randi_range(-32,32))
		var enemy : CharacterBody2D = wave_array[enemy_index].enemy.instantiate();
		enemy.global_position = global_position+rand_vector;
		get_tree().get_first_node_in_group("Enemies").add_child(enemy)
		
		enemies_spawned -= 1;

# allows player to skip, see next_wave_notif
func show_wave_notif():
	var notif = load("res://GUI/next_wave_notif.tscn").instantiate();
	var vp = get_viewport_rect().size
	var rotate;
	notif.position.x = clampf(global_position.x,300,vp.x - 450)
	notif.position.y = clampf(global_position.y,300,vp.y - 450)
	
	if global_position.x < 0:
		rotate = PI + PI/2
	elif global_position.x > vp.x:
		rotate = PI/2
	elif global_position.y < 0:
		rotate = PI
	elif global_position.y > vp.y:
		rotate = 0
	
	get_tree().get_current_scene().add_child(notif)
	notif.rotate_bubble(rotate);

func start_wave():
	_ready()
	spawn_timer.start()
