extends Node
## Original synthesized cabinet motor and independent hoofbeat loops.
## Uses its own fixed noise stream, never the race random generator.
const RATE := 16000
static var loops := {}
var preferences := {}
var mechanical := AudioStreamPlayer.new()
var hoofs := AudioStreamPlayer.new()

func _init() -> void:
	add_child(mechanical)
	add_child(hoofs)
	for kind in ["mechanical","hoofs"]:
		if not loops.has(kind): loops[kind] = synthesize(kind)
	mechanical.stream = loops.mechanical
	hoofs.stream = loops.hoofs

static func synthesize(kind: String) -> AudioStreamWAV:
	var count := int(RATE*1.6)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 8251
	for i in range(count):
		var t := float(i)/RATE
		var sample := 0.0
		if kind == "mechanical":
			var phase := fmod(t,0.08)
			if phase < 0.025:
				sample = 0.28*exp(-phase*170.0)*noise.randf_range(-1,1)
		else:
			for beat in [0.0,0.14,0.36,0.52]:
				var age := fposmod(t-beat,0.8)
				if age < 0.09:
					var envelope := exp(-age*65.0)*minf(age*1200.0,1.0)
					sample += envelope*(0.40*sin(TAU*120*age)+0.15*noise.randf_range(-1,1))
		bytes.encode_s16(i*2,int(clampf(sample,-0.9,0.9)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

func update_playback(moving: bool, photo_finish: bool=false) -> void:
	for entry in [[mechanical,"mechanical"],[hoofs,"hoof"]]:
		var player: AudioStreamPlayer = entry[0]
		var key: String = entry[1]
		var volume: float = preferences.get("master_volume",0.8)*preferences.get(key+"_volume",0.45)
		var enabled: bool = moving and not (photo_finish and key=="hoof") and preferences.get(key+"_enabled",true) and volume > 0.0
		player.volume_db = linear_to_db(maxf(volume,0.00001))
		if enabled and not player.playing: player.play()
		elif not enabled and player.playing: player.stop()
