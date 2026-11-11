extends Node
## Short original result cues, independent of all race random generators.
const RATE := 16000
static var clips := {}
var player := AudioStreamPlayer.new()

func _init() -> void:
	add_child(player)

func play_result(kind: String, preferences: Dictionary) -> void:
	if not clips.has(kind): clips[kind] = synthesize(kind)
	player.stream = clips[kind]
	update_preferences(preferences)
	player.play()

func update_preferences(preferences: Dictionary) -> void:
	var level: float = preferences.get("master_volume",0.8)*preferences.get("win_volume",0.7)
	player.volume_linear = level

static func synthesize(kind: String) -> AudioStreamWAV:
	var notes: Array = [523.25,659.25,783.99,1046.50]
	var beat := 0.22
	if kind == "jackpot":
		notes = [523.25,659.25,783.99,1046.50,783.99,1046.50,1318.51,1567.98,1046.50,1318.51,1567.98,2093.0]
		beat = 0.27
	elif kind == "none":
		notes = [392.0,329.63,261.63]
		beat = 0.24
	var duration := notes.size()*beat+0.35
	var bytes := PackedByteArray()
	bytes.resize(int(duration*RATE)*2)
	for i in range(bytes.size()/2):
		var t := float(i)/RATE
		var sample := 0.0
		for n in range(notes.size()):
			var age := t-n*beat
			if age >= 0.0 and age < beat+0.30:
				var envelope := minf(age*120.0,1.0)*exp(-age*8.0)
				sample += envelope*(0.22*sin(TAU*notes[n]*age)+0.06*sin(TAU*notes[n]*2.0*age))
		if kind == "jackpot":
			var age := fmod(t,beat)
			sample += 0.12*exp(-age*45.0)*sin(TAU*90.0*age)
		sample *= clampf((duration-t)/0.1,0.0,1.0)
		bytes.encode_s16(i*2,int(clampf(sample,-0.85,0.85)*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
