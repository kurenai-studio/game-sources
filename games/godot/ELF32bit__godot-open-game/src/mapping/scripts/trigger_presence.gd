extends Area3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("AudioStreamPlayer3D") var _sound_player: NodePath
@onready var sound_player: AudioStreamPlayer3D = get_node(_sound_player)

@export_node_path("Timer") var _delay_timer: NodePath
@onready var delay_timer: Timer = get_node_or_null(_delay_timer)

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)


func _ready() -> void:
	set_physics_process(false)
	if not is_instance_valid(delay_timer):
		set_deferred("monitoring", false)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not monitoring: set_physics_process(false)
	elif get_overlapping_bodies().size() == 0:
		set_physics_process(false)
		generic_free.emit()
		generic.emit({})

		set_deferred("monitoring", false)
		if is_instance_valid(wait_timer):
			wait_timer.start()

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node3D) -> void:
	if is_physics_processing(): return
	if is_instance_valid(delay_timer):
		if delay_timer.is_stopped():
			delay_timer.start()


func _on_delay_timer_timeout() -> void:
	if not monitoring: return
	elif get_overlapping_bodies().size() > 0:
		set_physics_process(true)
		generic_free.emit()
		generic.emit({})
		sound_player.play()


func _on_wait_timer_timeout() -> void:
	set_deferred("monitoring", true)

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	if is_instance_valid(delay_timer):
		set_deferred("monitoring", true)
