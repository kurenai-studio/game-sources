extends Area3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export var push_speed: float = 15.0
@export var targets: Array[NodePath] = []
@export var teleport_sounds: Array[AudioStream] = []


func _ready() -> void:
	_validate_targets.call_deferred()


func _validate_targets() -> void:
	for path in targets:
		var target := get_node_or_null(path)
		if is_instance_valid(target):
			assert(target is Node3D)


func _get_random_target(rng: RandomNumberGenerator) -> Node3D:
	var size: int = 0
	for path in targets:
		var target := get_node_or_null(path)
		if is_instance_valid(target): size += 1
	if size == 0: return null
	var index := rng.randi() % size
	for path in targets:
		var target := get_node_or_null(path)
		if not is_instance_valid(target): continue
		if index <= 0: return target
		index = index - 1
	return null


func _teleport(body: Node3D, to: Transform3D) -> void:
	var _scale := body.global_basis.get_scale()
	body.global_basis = to.basis.orthonormalized()
	body.global_basis = body.global_basis.scaled(_scale)
	body.global_position = to.origin

# OBJECT: teleport(to: Transform3D, push_speed: float)
func _on_body_entered(body: Node3D) -> void:
	var target := _get_random_target(GameState.rng)
	if not is_instance_valid(target):
		return

	if teleport_sounds.size() > 0:
		_play_teleport_sound(body, GameState.rng)

	_teleport(body, target.global_transform)
	if body.has_method("teleport"):
		body.teleport(target.global_transform, push_speed)
	elif body is RigidBody3D:
		var push_direction := -body.global_basis.z.normalized()
		body.apply_central_impulse(body.mass * push_direction * push_speed)

	if teleport_sounds.size() > 0:
		_play_teleport_sound(body, GameState.rng)

	generic_free.emit()
	generic.emit({})

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	set_deferred("monitoring", true)


func _play_teleport_sound(at: Node3D, rng: RandomNumberGenerator) -> void:
	var sound_player := AudioStreamPlayer3D.new()
	LAYERS.set_audio_stream_player_area_mask(sound_player)
	sound_player.finished.connect(sound_player.queue_free)
	self.add_child(sound_player, false)

	var sound_index := rng.randi() % teleport_sounds.size()
	sound_player.stream = teleport_sounds[sound_index]
	sound_player.global_position = at.global_position
	sound_player.play()
