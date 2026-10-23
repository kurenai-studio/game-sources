extends "trigger_relay.gd"

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)

var has_fired := false

func _on_fired() -> void:
	if is_instance_valid(wait_timer):
		wait_timer.start()
	_start_delay_timer(delay_time)
	sound_player.play()

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node3D) -> void:
	if has_fired: return
	set_deferred("monitoring", false)
	has_fired = true
	_on_fired()


func _on_delay_timer_timeout() -> void:
	generic_free.emit()
	generic.emit({})


func _on_wait_timer_timeout() -> void:
	set_deferred("monitoring", true)
	has_fired = false

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	_on_body_entered(null)
