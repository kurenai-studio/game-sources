extends Enemy

@onready var _launch_points_root:Node3D = get_node("%LaunchPoints")

func _fire():	
	var tween = get_tree().create_tween()
	var n = Vector3(0,10.639,3.274)
	tween.tween_property(_enemy_body_root,"position",n,.1)
	tween.tween_property(_enemy_body_root,"position",Vector3(0.0,10.639,0.0),.1)
	
	var _bullet_dupe:CharacterBody3D = Projectile.instantiate()
	var _random_number:int = randi_range(0,_launch_points_root.get_child_count() - 1)
	var _random_launch_marker:Marker3D = _launch_points_root.get_child(_random_number)
	_bullet_dupe.global_transform = _random_launch_marker.global_transform 
	get_tree().root.add_child(_bullet_dupe)
	if TrackingMissiles:
		_bullet_dupe.TrackingMissile = true
		_bullet_dupe.Target = _look_at_location
