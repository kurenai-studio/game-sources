extends SceneTree
var guard = preload("res://ui/instance_guard.gd").new()
func _initialize() -> void:
	if not guard.acquire():
		quit(2)
		return
	print("INSTANCE_LOCK_READY")
	create_timer(15.0).timeout.connect(func(): quit())
