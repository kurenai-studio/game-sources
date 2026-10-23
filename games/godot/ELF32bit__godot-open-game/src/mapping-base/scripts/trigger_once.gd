extends Area3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("AudioStreamPlayer3D") var _sound_player: NodePath
@onready var sound_player: AudioStreamPlayer3D = get_node(_sound_player)

@export_node_path("Timer") var _delay_timer: NodePath
@onready var delay_timer: Timer = get_node_or_null(_delay_timer)

var has_fired := false


func _on_fired() -> void:
	if is_instance_valid(delay_timer):
		delay_timer.start()
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

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	_on_body_entered(null)
