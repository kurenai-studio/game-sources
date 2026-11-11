extends SceneTree
var started := false
var ended := false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var backend=load("res://ui/speech_backend.gd").new()
	var voices: Array=backend.voices()
	print("NATIVE VOICES: ",voices.map(func(v): return v.name))
	if voices.is_empty():
		printerr("No native voices available in this environment")
		quit(2)
		return
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED,func(_id): started=true)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED,func(_id): ended=true)
	backend.say("Welcome to the track. Voice test complete.",voices[0].id,30,1.0)
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<15000 and not ended: await process_frame
	backend.stop()
	print("NATIVE SPEECH: started=",started," ended=",ended)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED,Callable())
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED,Callable())
	await create_timer(0.5).timeout
	quit(0 if started and ended else 1)
