extends Node

var jump_player: AudioStreamPlayer
var die_player: AudioStreamPlayer
var point_player: AudioStreamPlayer
var web_audio_unlocked: bool = false

const JUMP_SOUND: AudioStream = preload("res://assets/audio/player/jump.wav")
const DIE_SOUND: AudioStream = preload("res://assets/audio/player/die.wav")
const POINT_SOUND: AudioStream = preload("res://assets/audio/point.wav")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_setup_audio_buses()
	_create_audio_players()
	_setup_web_audio_unlock_hooks()

func _input(event: InputEvent) -> void:
	if web_audio_unlocked:
		return

	if event is InputEventMouseButton and event.pressed:
		_unlock_web_audio()
	elif event is InputEventScreenTouch and event.pressed:
		_unlock_web_audio()
	elif event is InputEventKey and event.pressed:
		_unlock_web_audio()

func _unlock_web_audio() -> void:
	if web_audio_unlocked:
		return

	if OS.has_feature("web"):
		_resume_web_audio_contexts()

		# Warm-up cycle to initialize output path in strict browsers.
		if jump_player and jump_player.stream:
			jump_player.play()
			jump_player.stop()
		if die_player and die_player.stream:
			die_player.play()
			die_player.stop()
		if point_player and point_player.stream:
			point_player.play()
			point_player.stop()

	web_audio_unlocked = true

func _setup_web_audio_unlock_hooks() -> void:
	if not OS.has_feature("web"):
		return

	JavaScriptBridge.eval("""
		(function () {
			if (window.__gnuGameAudioUnlockHookInstalled) {
				return;
			}
			window.__gnuGameAudioUnlockHookInstalled = true;

			const resume = function () {
				try {
					if (typeof GodotAudio !== 'undefined' && GodotAudio.ctx && GodotAudio.ctx.state === 'suspended') {
						GodotAudio.ctx.resume();
					}
					if (typeof Module !== 'undefined' && Module.audioContext && Module.audioContext.state === 'suspended') {
						Module.audioContext.resume();
					}
				} catch (e) {}
			};

			window.addEventListener('pointerdown', resume, { passive: true });
			window.addEventListener('touchstart', resume, { passive: true });
			window.addEventListener('keydown', resume, { passive: true });
		})();
	""", true)

func _resume_web_audio_contexts() -> void:
	if not OS.has_feature("web"):
		return

	JavaScriptBridge.eval("""
		(function () {
			try {
				if (typeof GodotAudio !== 'undefined' && GodotAudio.ctx && GodotAudio.ctx.state === 'suspended') {
					GodotAudio.ctx.resume();
				}
				if (typeof Module !== 'undefined' && Module.audioContext && Module.audioContext.state === 'suspended') {
					Module.audioContext.resume();
				}
			} catch (e) {}
		})();
	""", true)

func _setup_audio_buses() -> void:
	var master_bus_idx := AudioServer.get_bus_index("Master")
	if master_bus_idx != -1:
		AudioServer.set_bus_mute(master_bus_idx, false)

func _create_audio_players() -> void:
	"""Crea los nodos AudioStreamPlayer para cada tipo de sonido"""
	jump_player = _create_audio_player("JumpPlayer", JUMP_SOUND)
	die_player = _create_audio_player("DiePlayer", DIE_SOUND)
	point_player = _create_audio_player("PointPlayer", POINT_SOUND)

func _create_audio_player(player_name: String, sound: AudioStream) -> AudioStreamPlayer:
	"""Crea un AudioStreamPlayer configurado correctamente"""
	var player = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Master"
	
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = sound
	
	add_child(player)
	return player

func play_jump() -> void:
	"""Reproduce el sonido de salto del jugador"""
	_unlock_web_audio()
	if jump_player and jump_player.stream:
		jump_player.play()

func play_die() -> void:
	"""Reproduce el sonido de muerte del jugador"""
	_unlock_web_audio()
	if die_player and die_player.stream:
		die_player.play()

func play_point() -> void:
	"""Reproduce el sonido de puntuación (cada 100 puntos)"""
	_unlock_web_audio()
	if point_player and point_player.stream:
		point_player.play()

func set_sfx_volume(db: float) -> void:
	"""Establece el volumen del bus SFX en dB"""
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus != -1:
		AudioServer.set_bus_volume_db(master_bus, db)

func get_sfx_volume() -> float:
	"""Obtiene el volumen actual del bus SFX en dB"""
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus != -1:
		return AudioServer.get_bus_volume_db(master_bus)
	return 0.0
