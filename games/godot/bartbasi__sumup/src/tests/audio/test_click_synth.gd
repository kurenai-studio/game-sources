extends "res://tests/base_test.gd"
## ClickSynth builds the click as docs/BRIEF.md section 4 and
## docs/ARCHITECTURE.md section 9 say: 16 bit mono, 50 to 90 ms, soft attack,
## quick decay, peak below full scale. Headless runs cannot hear anything, so
## every check reads the generated sample data.

const Measure := preload("res://tests/audio/click_measure.gd")
## The default rate, a low rate, and the rate many Android phones mix at.
const RATES: PackedInt32Array = [44100, 22050, 48000]
## Levels as fractions of full scale.
const CEILING: float = 0.8912509  # -1 dBFS
const AUDIBLE_FLOOR: float = 0.2511886  # -12 dBFS
const NEAR_SILENCE: float = 0.001  # -60 dBFS


func test_format_is_16_bit_mono_one_shot() -> void:
	for rate: int in RATES:
		var stream: AudioStreamWAV = ClickSynth.build(rate)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "%d Hz format" % rate)
		assert_false(stream.stereo, "%d Hz is mono" % rate)
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "%d Hz does not loop" % rate)
		assert_eq(stream.mix_rate, rate, "%d Hz mix rate" % rate)
	assert_eq(ClickSynth.build().mix_rate, 44100, "default mix rate")


func test_duration_between_50_and_90_ms() -> void:
	for rate: int in RATES:
		var stream: AudioStreamWAV = ClickSynth.build(rate)
		var seconds: float = stream.get_length()
		assert_true(seconds >= 0.050 and seconds <= 0.090, "%d Hz click lasts %.4f s" % [rate, seconds])
		assert_near(float(Measure.samples(stream).size()) / rate, seconds, 0.0001, "%d Hz sample count matches the length" % rate)


func test_peak_at_or_below_minus_1_dbfs() -> void:
	for rate: int in RATES:
		var peak: float = Measure.peak(Measure.samples(ClickSynth.build(rate)))
		assert_true(peak <= CEILING, "%d Hz peak %.2f dBFS is at or below -1 dBFS" % [rate, Measure.to_dbfs(peak)])
		assert_true(peak >= AUDIBLE_FLOOR, "%d Hz peak %.2f dBFS is loud enough to hear" % [rate, Measure.to_dbfs(peak)])


func test_starts_and_ends_near_silence() -> void:
	for rate: int in RATES:
		var wave: PackedFloat64Array = Measure.samples(ClickSynth.build(rate))
		assert_true(absf(wave[0]) <= NEAR_SILENCE, "%d Hz first sample %f" % [rate, wave[0]])
		assert_true(absf(wave[wave.size() - 1]) <= NEAR_SILENCE, "%d Hz last sample %f" % [rate, wave[wave.size() - 1]])
		var tail: float = Measure.peak_between(wave, wave.size() - roundi(0.002 * rate), wave.size())
		assert_true(tail <= NEAR_SILENCE, "%d Hz last 2 ms fade out, loudest %.1f dBFS" % [rate, Measure.to_dbfs(tail)])


func test_attack_is_soft_and_quick() -> void:
	for rate: int in RATES:
		var wave: PackedFloat64Array = Measure.samples(ClickSynth.build(rate))
		var peak: float = Measure.peak(wave)
		var peak_ms: float = 1000.0 * Measure.peak_index(wave) / rate
		assert_true(peak_ms >= 1.0 and peak_ms <= 10.0, "%d Hz peak arrives at %.2f ms" % [rate, peak_ms])
		var opening: float = Measure.peak_between(wave, 0, roundi(0.0005 * rate))
		assert_true(opening <= peak * 0.1, "%d Hz first 0.5 ms stays 20 dB under the peak, got %.1f dB" % [rate, Measure.to_dbfs(opening / peak)])


func test_decay_is_quick() -> void:
	for rate: int in RATES:
		var wave: PackedFloat64Array = Measure.samples(ClickSynth.build(rate))
		var after_peak_ms: float = 1000.0 * (Measure.last_above(wave, 0.1) - Measure.peak_index(wave)) / rate
		assert_true(after_peak_ms <= 40.0, "%d Hz falls 20 dB within 40 ms of the peak, took %.2f ms" % [rate, after_peak_ms])


func test_no_dc_offset() -> void:
	for rate: int in RATES:
		var offset: float = Measure.mean(Measure.samples(ClickSynth.build(rate)))
		assert_true(absf(offset) <= NEAR_SILENCE, "%d Hz mean %.6f is below -60 dBFS" % [rate, offset])


func test_same_rate_builds_the_same_click() -> void:
	assert_eq(ClickSynth.build(44100).data, ClickSynth.build(44100).data)
