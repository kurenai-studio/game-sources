extends Node3D

@export var path_follow_speed: float = 6.0
@export var path_follow_quality: float = 2.5
@export var path_follow_progress: float = 0.0

@export_node_path("Path3D") var _path_to_follow: NodePath
@onready var path: Path3D = get_node_or_null(_path_to_follow)

var path_follow: PathFollow3D


func _ready() -> void:
	if path == null:
		set_physics_process(false)
	elif path_follow == null:
		path_follow = PathFollow3D.new()
		path.add_child(path_follow, false)
		path_follow.progress = path_follow_progress
		global_transform = path_follow.global_transform
		path_follow.loop = path.curve.closed


func _physics_process(delta: float) -> void:
	path_follow.progress += path_follow_speed * delta
	global_transform = global_transform.interpolate_with(
		path_follow.global_transform, path_follow_quality * delta)
