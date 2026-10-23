extends SceneTree
## Plays every sound effect one after another into a single file, with a pause between, to listen
## the kit through without playing. Run with:
## godot --headless --path . --script tools/sound_sheet.gd -- <output>.wav

const GAP := 0.35


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	var output := arguments[0] if not arguments.is_empty() else "user://sound_sheet.wav"
	var data := PackedByteArray()
	var silence := PackedByteArray()
	silence.resize(int(GAP * SoundKit.RATE) * 2)
	for sound_name in SoundKit.NAMES:
		for variant in 2:
			data.append_array(SoundKit.stream(sound_name, variant).data)
			data.append_array(silence)
		data.append_array(silence)
	var sheet := AudioStreamWAV.new()
	sheet.format = AudioStreamWAV.FORMAT_16_BITS
	sheet.mix_rate = SoundKit.RATE
	sheet.data = data
	sheet.save_to_wav(output)
	print("%d sounds, two variants each, %.1f seconds, in %s" % [SoundKit.NAMES.size(), data.size() / 2.0 / SoundKit.RATE, output])
	quit()
