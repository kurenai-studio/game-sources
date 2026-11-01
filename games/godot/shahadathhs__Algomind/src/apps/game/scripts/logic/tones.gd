class_name Tones
extends RefCounted
## Sound effects and music made from code, so the game ships no audio files.
##
## Everything is a short run of sine notes with a quick fade in and out, as 16-bit mono PCM.
## Nothing here is needed to understand the game: every sound mirrors something shown on screen.

const RATE := 22050


## One note per entry in `notes` ([frequency_hz, seconds]); a frequency of 0 is a rest.
static func sequence(notes: Array, volume: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	for note: Array in notes:
		_append_note(samples, float(note[0]), float(note[1]), volume)
	return _to_stream(samples)


## A soft pattern of a minor pentatonic scale, about eight seconds long, played once; Feedback
## plays it again when it finishes. It is not a looping stream: on Android a looping generated
## stream made the app quit a few seconds in. It sits in the octave phone speakers can reproduce
## and uses a few harmonics so it is audible on them.
static func music() -> AudioStreamWAV:
	var scale := [440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
	var pattern := [0, 2, 4, 2, 5, 4, 2, 1, 0, 2, 3, 2, 4, 3, 1, 0]
	var samples := PackedFloat32Array()
	for step: int in pattern:
		_append_note(samples, scale[step], 0.5, 0.45)
	return _to_stream(samples)


static func tap() -> AudioStreamWAV:
	return sequence([[660.0, 0.05]], 0.6)


static func step() -> AudioStreamWAV:
	return sequence([[392.0, 0.06]], 0.45)


static func blocked() -> AudioStreamWAV:
	return sequence([[220.0, 0.1], [165.0, 0.14]], 0.7)


static func success() -> AudioStreamWAV:
	return sequence([[523.25, 0.1], [659.25, 0.1], [783.99, 0.1], [1046.5, 0.22]], 0.6)


static func fail() -> AudioStreamWAV:
	return sequence([[349.0, 0.1], [277.0, 0.1], [220.0, 0.2]], 0.6)


static func hint() -> AudioStreamWAV:
	return sequence([[880.0, 0.06], [0.0, 0.03], [1174.66, 0.1]], 0.5)


static func _append_note(
	samples: PackedFloat32Array, hz: float, seconds: float, volume: float
) -> void:
	var count := int(seconds * RATE)
	var fade := mini(int(0.008 * RATE), count / 2)
	for i in count:
		var envelope := 1.0
		if i < fade:
			envelope = float(i) / float(fade)
		elif i > count - fade:
			envelope = float(count - i) / float(fade)
		var value := 0.0
		if hz > 0.0:
			var phase := TAU * hz * float(i) / RATE
			# A little 2nd and 3rd harmonic, so small speakers carry the note.
			value = (sin(phase) + 0.45 * sin(2.0 * phase) + 0.2 * sin(3.0 * phase)) / 1.65
		samples.append(value * volume * envelope)


static func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
