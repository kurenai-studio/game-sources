extends RefCounted
## Song time, corrected for the delay between play() and the speakers.
## Gameplay never counts rendered frames to decide where the beat is.

var player: AudioStreamPlayer
var started_usec: int = 0
var latency: float = 0.0
var paused_at: int = 0
var running: bool = false

func start(audio_player: AudioStreamPlayer) -> void:
	player = audio_player
	started_usec = Time.get_ticks_usec()
	var mix_delay: float = AudioServer.get_time_to_next_mix()
	var output_delay: float = AudioServer.get_output_latency()
	latency = estimated_delay(mix_delay,output_delay,OS.has_feature("web"))
	if OS.has_feature("qa"):
		print("QA_AUDIO_CLOCK "+JSON.stringify({"mix": mix_delay,"output": output_delay,"used": latency,"web": OS.has_feature("web")}))
	paused_at = 0
	running = true
	player.stream_paused = false
	player.play()

func seconds() -> float:
	if not running:
		return 0.0
	var now: int = paused_at if paused_at > 0 else Time.get_ticks_usec()
	return maxf(0.0, float(now - started_usec) / 1000000.0 - latency)

func set_paused(value: bool) -> void:
	if not running:
		return
	if value and paused_at == 0:
		paused_at = Time.get_ticks_usec()
		player.stream_paused = true
	elif not value and paused_at > 0:
		started_usec += Time.get_ticks_usec() - paused_at
		paused_at = 0
		player.stream_paused = false

func stop() -> void:
	running = false
	if is_instance_valid(player):
		player.stop()
		player.stream_paused = false

static func estimated_delay(mix_delay: float, output_delay: float, web: bool) -> float:
	# Web Sample playback bypasses Godot's mixer. Its "next mix" estimate can
	# be negative before first audio, so it must not move the song clock ahead.
	var output: float = output_delay if is_finite(output_delay) and output_delay >= 0.0 and output_delay <= 2.0 else 0.0
	var mix: float = mix_delay if not web and is_finite(mix_delay) and mix_delay >= 0.0 and mix_delay <= 0.25 else 0.0
	return output+mix
