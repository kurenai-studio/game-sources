extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var director=load("res://ui/announcer_director.gd").new()
	root.add_child(director)
	director.configure(load("res://core/game_settings.gd").new().values)
	var speech=director.backend
	var events: Array=[]
	if speech.has_signal("playback_event"):
		speech.playback_event.connect(func(kind,details): events.append({"kind":kind,"details":details}))
	var clips: Array=[]
	for role in ["race","house"]: clips.append(director.clip(role,"Horse two just passed Horse four for second!" if role=="race" else "There is the winning total! Congratulations to our winners!"))
	speech.prepare(clips)
	var deadline:=Time.get_ticks_msec()+20000
	while speech.preparing() and Time.get_ticks_msec()<deadline:
		speech.tick(0.05)
		await create_timer(0.05).timeout
	var waves:=[]
	var report:=[]
	var good: bool=clips[0].voice!=clips[1].voice
	var capture:=AudioEffectCapture.new()
	AudioServer.add_bus_effect(0,capture)
	for clip in clips:
		var wave=speech.stream_for(clip)
		if wave==null:
			good=false
			printerr("Missing voice clip: ",speech.failure)
			continue
		waves.append(wave.data)
		speech.say(clip.text,clip.voice,45,clip.rate)
		var peak:=0.0
		deadline=Time.get_ticks_msec()+10000
		while speech.speaking() and Time.get_ticks_msec()<deadline:
			speech.tick(0.05)
			await create_timer(0.05).timeout
			for frame in capture.get_buffer(capture.get_frames_available()): peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
		report.append({"voice":clip.voice,"seconds":wave.get_length(),"audio_peak":peak})
		good=good and peak>0.001
	good=good and waves.size()==2 and waves[0]!=waves[1]
	good=good and events.filter(func(event): return event.kind=="audio_clip_started").size()==2 and events.filter(func(event): return event.kind=="audio_clip_ended" and event.details.reason=="completed").size()==2
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	print("VOICE PAIR AUDIO 15: ",JSON.stringify(report)," distinct=",good," playback_events=",events.size())
	director.queue_free()
	await process_frame
	quit(0 if good else 1)
