extends GutTest
## The generated sounds: each effect has samples, stays within range, and the music loops.


func test_every_effect_has_audio_data() -> void:
	for stream: AudioStreamWAV in [
		Tones.tap(), Tones.step(), Tones.blocked(), Tones.success(), Tones.fail(), Tones.hint()
	]:
		assert_gt(stream.data.size(), 0)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
		assert_eq(stream.mix_rate, Tones.RATE)


func test_a_sequence_lasts_as_long_as_its_notes() -> void:
	var stream := Tones.sequence([[440.0, 0.1], [0.0, 0.05]], 0.3)
	var samples := stream.data.size() / 2
	assert_eq(samples, int(0.1 * Tones.RATE) + int(0.05 * Tones.RATE))


func test_samples_stay_within_the_requested_volume() -> void:
	var stream := Tones.sequence([[440.0, 0.2]], 0.25)
	var peak := 0
	for i in stream.data.size() / 2:
		peak = maxi(peak, absi(stream.data.decode_s16(i * 2)))
	assert_lte(peak, int(0.25 * 32767.0) + 1)
	assert_gt(peak, 0)


func test_music_is_a_single_pass_not_a_looping_stream() -> void:
	var stream := Tones.music()
	assert_eq(
		stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "looping generated audio quit Android"
	)
	assert_gt(stream.data.size() / 2, 7 * Tones.RATE)
