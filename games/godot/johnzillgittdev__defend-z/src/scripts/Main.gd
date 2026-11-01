extends Control

@export var skel_scene: PackedScene

var skel_count: int = 0

func _ready():
	$SkelTimer.start()

func _on_skel_timer_timeout() -> void:
	var skel = skel_scene.instantiate()
	
	var skel_spawn_location = $VBoxContainer/BattleSection/Ground/SpawnPoint.global_position
	skel.position = skel_spawn_location
	
	skel.died.connect(_on_skel_died)
	
	add_child(skel)
	update_skel_count(1)

func _on_player_hit() -> void:
	$SkelTimer.stop()

func _on_skel_died():
	var wait = $SkelTimer.wait_time
	$SkelTimer.wait_time = wait * .95
	update_skel_count(-1)

func update_skel_count(change: int) -> void:
	skel_count += change
	$Player.update_state(skel_count)
