extends Node
const RATE := 16000
const HORN_GAP := 1.5
var player := AudioStreamPlayer.new()
var duration := 0.0
var schedule := {}
var horn: AudioStream
func _init() -> void:
	add_child(player)
	horn=AudioStreamOggVorbis.load_from_file("res://assets/audio/first_call.ogg")

func plan(prefs: Dictionary) -> Dictionary:
	var kind: String=prefs.get("start_signal","Bell")
	var use_horn := kind in ["Horn","Horn and bell"] and horn!=null
	var use_bell := kind in ["Bell","Horn and bell"]
	var horn_end := horn.get_length() if use_horn else 0.0
	var bell_start := horn_end+HORN_GAP if use_horn else 0.0
	var bell_duration := clampf(float(prefs.get("bell_seconds",0.5)),0.1,1.0) if use_bell else 0.0
	return {"kind":kind,"horn_end":horn_end,"bell_start":bell_start if use_bell else -1.0,
		"bell_seconds":bell_duration,"total":bell_start+bell_duration if use_horn or use_bell else 0.0}

func wave(bytes: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=RATE; stream.data=bytes
	return stream

func school_bell(seconds: float) -> AudioStreamWAV:
	var samples := roundi(RATE*clampf(seconds,0.1,1.0))
	var bytes := PackedByteArray(); bytes.resize(samples*2)
	for i in range(samples):
		var t := float(i)/RATE
		var edge := minf(1.0,float(samples-1-i)/RATE/0.018)
		var tone := 0.0
		# Repeated hammer strikes excite inharmonic metal modes, like a school bell.
		for strike in range(int(t*18.0)+1):
			var age := t-float(strike)/18.0
			tone+=0.24*sin(TAU*873*age)*exp(-age*19)
			tone+=0.18*sin(TAU*1438*age)*exp(-age*24)
			tone+=0.12*sin(TAU*2197*age)*exp(-age*33)
			tone+=0.08*sin(TAU*3261*age)*exp(-age*48)
		bytes.encode_s16(i*2,roundi(clampf(tone*edge,-0.95,0.95)*32767))
	return wave(bytes)

func play_signal(prefs: Dictionary) -> float:
	player.stop()
	schedule=plan(prefs); duration=schedule.total
	if duration<=0: return 0.0
	var clips: Array[AudioStream]=[]
	if schedule.horn_end>0:
		clips.append(horn)
		var silence := PackedByteArray(); silence.resize(roundi(RATE*HORN_GAP)*2)
		clips.append(wave(silence))
	if schedule.bell_seconds>0: clips.append(school_bell(schedule.bell_seconds))
	var sequence := AudioStreamPlaylist.new()
	sequence.loop=false; sequence.shuffle=false; sequence.fade_time=0.0
	sequence.stream_count=clips.size()
	for i in range(clips.size()): sequence.set_list_stream(i,clips[i])
	player.stream=sequence
	var volume: float=prefs.get("master_volume",0.8)*prefs.get("start_signal_volume",0.65)
	player.volume_db=linear_to_db(maxf(volume,0.00001))
	if volume>0: player.play()
	return duration
