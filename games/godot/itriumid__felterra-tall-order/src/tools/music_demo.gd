extends SceneTree
## Renders the adaptive soundtrack through a scripted fight to one file, mixed the way the
## director would mix it, to hear the layers come and go without playing: an empty clearing, the
## horde gathering, a crush, a giant walking in, and the giant felled. Run with:
## godot --headless --path . --script tools/music_demo.gd -- <output>.wav

## Each part of the fight: its length in loops, how many are around him, whether a giant stands.
const SCRIPT := [[1, 0, false], [1, 12, false], [1, 35, false], [1, 35, true], [1, 20, false]]


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	var output := arguments[0] if not arguments.is_empty() else "user://music_demo.wav"
	var layers := MusicKit.make_all()
	var loop := MusicKit.loop_samples()
	var total := 0
	for part: Array in SCRIPT:
		total += part[0] * loop
	var mix := PackedFloat32Array()
	mix.resize(total)
	var levels := {}
	for layer: String in layers:
		levels[layer] = 0.0
	var at := 0
	for part: Array in SCRIPT:
		var wanted := MusicDirector.targets(part[1], part[2], false)
		for index in part[0] * loop:
			for layer: String in layers:
				# The same fade the director makes, a sample at a time.
				levels[layer] = move_toward(levels[layer], wanted[layer], MusicDirector.FADE / MusicKit.RATE)
				var wav: AudioStreamWAV = layers[layer]
				mix[at] += wav.data.decode_s16((index % loop) * 2) / 32767.0 * levels[layer]
			at += 1
	var data := PackedByteArray()
	data.resize(total * 2)
	for index in total:
		data.encode_s16(index * 2, int(tanh(mix[index] * 0.8) * 30000.0))
	var demo := AudioStreamWAV.new()
	demo.format = AudioStreamWAV.FORMAT_16_BITS
	demo.mix_rate = MusicKit.RATE
	demo.data = data
	demo.save_to_wav(output)
	print("%.1f seconds of the fight, in %s" % [total / float(MusicKit.RATE), output])
	quit()
