extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host := Node.new()
	root.add_child(host)
	var speech=load("res://ui/speech_backend.gd").new()
	speech.attach(host)
	var voices: Array=speech.voices()
	if voices.is_empty():
		printerr("No voices enumerated")
		quit(1)
		return
	var clip := {"text":"Welcome to the track. The game voice is now playing through the game audio.","voice":voices[0].id,"rate":1.0}
	speech.prepare([clip])
	var deadline := Time.get_ticks_msec()+15000
	while speech.preparing() and Time.get_ticks_msec()<deadline:
		speech.tick(0.05)
		await create_timer(0.05).timeout
	var wave: AudioStreamWAV=speech.stream_for(clip)
	if wave==null:
		printerr("Voice clip failed: "+speech.failure)
		speech.shutdown()
		host.queue_free()
		quit(1)
		return
	var peak := 0
	for i in range(0,wave.data.size()-1,2): peak=maxi(peak,absi(wave.data.decode_s16(i)))
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(0,capture)
	speech.say(clip.text,clip.voice,65,clip.rate)
	var output_peak := 0.0
	deadline=Time.get_ticks_msec()+12000
	while speech.speaking() and Time.get_ticks_msec()<deadline:
		speech.tick(0.05)
		await create_timer(0.05).timeout
		var frames: PackedVector2Array=capture.get_buffer(capture.get_frames_available())
		for frame in frames: output_peak=maxf(output_peak,maxf(absf(frame.x),absf(frame.y)))
	print("CLIP AUDIO: voice=%s duration=%.3f PCM peak=%d game output peak=%.4f" % [voices[0].name,wave.get_length(),peak,output_peak])
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	speech.shutdown()
	host.queue_free()
	await process_frame
	quit(0 if peak>100 and output_peak>0.001 else 1)
