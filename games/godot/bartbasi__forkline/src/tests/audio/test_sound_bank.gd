# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The synthesized streams: every sound exists, is mono 16 bit, is not silent,
## never clips, ends without a click, and builds the same every time.

## Every event kind of architecture 3.1, written out here on purpose, so a kind
## added to the contract without a sound fails this test.
const EVENT_KINDS: Array[StringName] = [
	&"wave_started", &"spawned", &"fired", &"popped", &"defeated", &"healed",
	&"leaked", &"gate_broken", &"wave_cleared", &"build_started", &"built",
	&"upgraded", &"sold", &"gate_placed", &"gate_removed", &"won", &"lost",
	&"released", &"break_started", &"sped_up", &"interest",
	&"napped", &"woke", &"burrowed", &"surfaced", &"blinked", &"yawned",
]
## The UI sounds of architecture 3.8.
const UI_SOUNDS: Array[StringName] = [&"tap", &"refuse", &"star"]
const FULL_SCALE: int = 32767

static var _music_cache: Dictionary[StringName, AudioStreamWAV] = {}


func _samples(wav: AudioStreamWAV) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var bytes: PackedByteArray = wav.data
	out.resize(bytes.size() / 2)
	for i: int in out.size():
		out[i] = bytes.decode_s16(i * 2)
	return out


func _peak(wav: AudioStreamWAV) -> int:
	var peak: int = 0
	for v: int in _samples(wav):
		peak = maxi(peak, absi(v))
	return peak


func _track(track: StringName) -> AudioStreamWAV:
	if not _music_cache.has(track):
		_music_cache[track] = SoundBank.render_music(track)
	return _music_cache[track]


func test_every_event_kind_has_a_sound_with_a_stream() -> void:
	for kind: StringName in EVENT_KINDS:
		assert_true(AudioService.EVENT_SOUNDS.has(kind), "%s has no sound" % kind)
		var sound: StringName = AudioService.EVENT_SOUNDS.get(kind, &"")
		assert_true(SoundBank.EFFECTS.has(sound), "%s: sound %s is not in the bank" % [kind, sound])
		assert_not_null(SoundBank.render_effect(sound), "%s did not render" % sound)


func test_every_ui_sound_has_a_stream() -> void:
	assert_eq(AudioService.UI_SOUNDS.size(), UI_SOUNDS.size())
	for sound: StringName in UI_SOUNDS:
		assert_true(AudioService.UI_SOUNDS.has(sound))
		assert_true(SoundBank.EFFECTS.has(sound))
		assert_not_null(SoundBank.render_effect(sound), "%s did not render" % sound)


func test_every_effect_has_a_mix_entry() -> void:
	for sound: StringName in SoundBank.EFFECTS:
		assert_true(AudioService.GAIN_DB.has(sound), "%s has no gain" % sound)
		assert_true(AudioService.GAP_MS.has(sound), "%s has no gap" % sound)
		assert_true(float(AudioService.GAIN_DB.get(sound, 0.0)) <= -3.0, "%s is too loud" % sound)


func test_unknown_ids_make_nothing() -> void:
	assert_null(SoundBank.render_effect(&"no_such_sound"))
	assert_null(SoundBank.render_music(&"no_such_track"))
	assert_null(SoundBank.render_music(&""))


func test_effects_are_mono_16_bit_and_not_silent() -> void:
	for sound: StringName in SoundBank.EFFECTS:
		var wav: AudioStreamWAV = SoundBank.render_effect(sound)
		assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS, sound)
		assert_false(wav.stereo, sound)
		assert_eq(wav.mix_rate, AudioSynth.EFFECT_RATE, sound)
		assert_true(wav.data.size() >= 2 * 1000, "%s is too short" % sound)
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED, sound)
		assert_true(wav.get_length() < 3.0, "%s is too long" % sound)
		assert_true(_peak(wav) > 3000, "%s is nearly silent" % sound)


func test_effects_never_clip() -> void:
	var limit: int = int(AudioSynth.CEILING * float(FULL_SCALE)) + 1
	for sound: StringName in SoundBank.EFFECTS:
		assert_true(_peak(SoundBank.render_effect(sound)) <= limit, "%s is too hot" % sound)


func test_effects_end_without_a_click() -> void:
	for sound: StringName in SoundBank.EFFECTS:
		var samples: PackedInt32Array = _samples(SoundBank.render_effect(sound))
		assert_true(absi(samples[samples.size() - 1]) < 300, "%s ends on a step" % sound)
		assert_true(absi(samples[0]) < 300, "%s starts on a step" % sound)


func test_music_loops_and_is_audible_but_not_hot() -> void:
	var limit: int = int(AudioSynth.CEILING * float(FULL_SCALE)) + 1
	for track: StringName in SoundBank.TRACKS:
		var wav: AudioStreamWAV = _track(track)
		assert_not_null(wav, track)
		assert_eq(wav.format, AudioStreamWAV.FORMAT_16_BITS, track)
		assert_false(wav.stereo, track)
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, track)
		assert_eq(wav.loop_begin, 0, track)
		assert_eq(wav.loop_end, wav.data.size() / 2 - 1, track)
		assert_true(wav.get_length() >= 12.0 and wav.get_length() <= 30.0, "%s length %s" % [track, wav.get_length()])
		var peak: int = _peak(wav)
		assert_true(peak > 6000 and peak <= limit, "%s peak %d" % [track, peak])


func test_music_loop_seam_is_smooth() -> void:
	# The jump from the last sample of the period to the first is no bigger
	# than a typical step. The guard frame after the period is left out.
	for track: StringName in SoundBank.TRACKS:
		var wav: AudioStreamWAV = _track(track)
		var samples: PackedInt32Array = _samples(wav)
		var seam: int = absi(samples[0] - samples[wav.loop_end - 1])
		var biggest_step: int = 0
		for i: int in range(1, wav.loop_end):
			biggest_step = maxi(biggest_step, absi(samples[i] - samples[i - 1]))
		assert_true(seam <= biggest_step, "%s seam %d, biggest step %d" % [track, seam, biggest_step])


func test_a_loop_holds_a_guard_frame_equal_to_its_first() -> void:
	# The mixer plays frame loop_end before it wraps, so that frame must exist
	# and must sound like frame 0, or the loop reads past its data.
	var raw: PackedFloat32Array = PackedFloat32Array([0.25, -0.5, 0.75, 0.1, -0.3])
	var made: AudioStreamWAV = AudioSynth.to_stream(raw, AudioSynth.MUSIC_RATE, true)
	var streams: Array[AudioStreamWAV] = [made]
	for track: StringName in SoundBank.TRACKS:
		streams.append(_track(track))
	for wav: AudioStreamWAV in streams:
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
		assert_eq(wav.loop_begin, 0)
		assert_eq(wav.data.size(), (wav.loop_end + 1) * 2)
		var samples: PackedInt32Array = _samples(wav)
		assert_eq(samples[samples.size() - 1], samples[0])
	assert_eq(made.loop_end, raw.size())
	var samples_made: PackedInt32Array = _samples(made)
	for i: int in raw.size():
		assert_eq(samples_made[i], int(raw[i] * float(FULL_SCALE)), "frame %d" % i)


func test_a_one_shot_has_no_extra_frame() -> void:
	var raw: PackedFloat32Array = AudioSynth.buffer(0.1, AudioSynth.EFFECT_RATE)
	raw.fill(0.2)
	var wav: AudioStreamWAV = AudioSynth.to_stream(raw, AudioSynth.EFFECT_RATE, false)
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED)
	assert_eq(wav.data.size(), raw.size() * 2)
	for sound: StringName in SoundBank.EFFECTS:
		var effect: AudioStreamWAV = SoundBank.render_effect(sound)
		assert_eq(effect.loop_mode, AudioStreamWAV.LOOP_DISABLED, sound)


func test_the_two_tracks_differ() -> void:
	assert_ne(_track(&"menu").data, _track(&"battle").data)


func test_generation_is_deterministic() -> void:
	for sound: StringName in SoundBank.EFFECTS:
		var a: AudioStreamWAV = SoundBank.render_effect(sound)
		var b: AudioStreamWAV = SoundBank.render_effect(sound)
		assert_eq(a.data, b.data, "%s differs between runs" % sound)
	for track: StringName in SoundBank.TRACKS:
		assert_eq(SoundBank.render_music(track).data, _track(track).data, "%s differs between runs" % track)


func test_threaded_bank_matches_the_static_recipes() -> void:
	var bank: SoundBank = SoundBank.new()
	assert_null(bank.stream(&"tap"), "nothing is built before start")
	bank.start()
	bank.wait()
	assert_true(bank.is_complete())
	for sound: StringName in SoundBank.EFFECTS:
		assert_eq(bank.stream(sound).data, SoundBank.render_effect(sound).data, sound)
	for track: StringName in SoundBank.TRACKS:
		assert_eq(bank.stream(track).data, _track(track).data, track)
	assert_null(bank.stream(&"no_such_sound"))


func test_shot_sounds_differ_from_each_other() -> void:
	var seen: Dictionary[PackedByteArray, StringName] = {}
	for sound: StringName in AudioService.SHOT_IDS:
		var data: PackedByteArray = SoundBank.render_effect(sound).data
		assert_false(seen.has(data), "%s sounds the same as %s" % [sound, seen.get(data, &"")])
		seen[data] = sound


func test_phase_7_sounds_sit_under_the_warnings_and_the_wave_sounds() -> void:
	# released and interest are soft; the two warnings are heard but never loud.
	assert_true(float(AudioService.GAIN_DB[&"released"]) <= -14.0)
	assert_true(float(AudioService.GAIN_DB[&"interest"]) <= -12.0)
	assert_true(float(AudioService.GAIN_DB[&"break_started"]) >= float(AudioService.GAIN_DB[&"interest"]))
	assert_true(float(AudioService.GAIN_DB[&"sped_up"]) >= float(AudioService.GAIN_DB[&"interest"]))
	assert_true(float(AudioService.GAIN_DB[&"break_started"]) <= -6.0)
	assert_true(float(AudioService.GAIN_DB[&"sped_up"]) <= -6.0)


func test_phase_7_sounds_differ_from_every_other_sound() -> void:
	var seen: Dictionary[PackedByteArray, StringName] = {}
	for sound: StringName in SoundBank.EFFECTS:
		var data: PackedByteArray = SoundBank.render_effect(sound).data
		assert_false(seen.has(data), "%s sounds the same as %s" % [sound, seen.get(data, &"")])
		seen[data] = sound
