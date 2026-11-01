extends "res://tests/base_test.gd"
## AudioService follows docs/ARCHITECTURE.md section 9 and GDD D-36: sound is
## on by default, nothing plays when it is off, every request is counted
## (TH20), and fast drags stay clean.
##
## Tests run before the scene tree starts, so nothing can actually play here.
## They read the service's state instead: _clicks_started counts the clicks the
## service let through, and _accept_click takes a time so gaps can be checked
## without waiting.

const Measure := preload("res://tests/audio/click_measure.gd")
const CEILING: float = 0.8912509  # -1 dBFS

var _service: AudioService


func before_each() -> void:
	_service = AudioService.new()


func after_each() -> void:
	_service.free()


func test_at_94_sound_is_on_by_default() -> void:
	assert_true(_service.is_enabled())


func test_set_enabled_turns_sound_off_and_on() -> void:
	_service.set_enabled(false)
	assert_false(_service.is_enabled())
	_service.set_enabled(true)
	assert_true(_service.is_enabled())


func test_at_98_click_requests_count_every_call_on_or_off() -> void:
	assert_eq(_service.click_requests, 0, "no requests yet")
	for _i: int in 3:
		_service.play_click()
	_service.set_enabled(false)
	for _i: int in 2:
		_service.play_click()
	_service.set_enabled(true)
	_service.play_click()
	assert_eq(_service.click_requests, 6, "every call counts, with sound on or off")


func test_a_disabled_service_starts_no_playback() -> void:
	_service.set_enabled(false)
	for _i: int in 5:
		_service.play_click()
	assert_eq(_service._clicks_started, 0, "no click started")
	assert_false(_player().playing, "the player is silent")
	assert_false(_service._accept_click(10_000_000), "no click is accepted at any time")


func test_turning_sound_off_stops_playback_and_later_clicks() -> void:
	_service.play_click()
	assert_eq(_service._clicks_started, 1, "with sound on the click starts")
	_service.set_enabled(false)
	assert_false(_player().playing, "turning sound off stops the player")
	_service.play_click()
	assert_false(_service._accept_click(10_000_000), "no click starts later")
	assert_eq(_service._clicks_started, 1, "nothing new started while off")


func test_turning_sound_back_on_lets_the_next_click_start_at_once() -> void:
	assert_true(_service._accept_click(1_000_000))
	_service.set_enabled(false)
	_service.set_enabled(true)
	assert_true(_service._accept_click(1_000_001), "a click right after turning sound back on starts")


func test_player_is_set_up_for_the_click() -> void:
	var player: AudioStreamPlayer = _player()
	assert_true(player != null, "the service owns an AudioStreamPlayer")
	if player == null:
		return
	assert_eq(player.max_polyphony, AudioService.POLYPHONY, "polyphony")
	var stream: AudioStreamWAV = player.stream as AudioStreamWAV
	assert_true(stream != null, "the player holds the synthesized click")
	if stream == null:
		return
	var rate: int = roundi(AudioServer.get_mix_rate())
	assert_eq(stream.mix_rate, rate, "the click is built at the mix rate, so it is not resampled")
	assert_eq(stream.data, ClickSynth.build(rate).data, "the player holds ClickSynth's click")


func test_rapid_requests_join_the_last_click() -> void:
	for _i: int in 10:
		_service.play_click()
	assert_eq(_service.click_requests, 10, "every request counts")
	assert_eq(_service._clicks_started, 1, "requests within the gap join the click already playing")


func test_clicks_start_once_the_gap_has_passed() -> void:
	var gap: int = AudioService.MIN_GAP_USEC
	assert_true(_service._accept_click(5_000_000), "the first click starts")
	assert_false(_service._accept_click(5_000_000 + gap - 1), "just inside the gap joins it")
	assert_true(_service._accept_click(5_000_000 + gap), "at the gap a new click starts")
	assert_true(_service._accept_click(5_000_000 + 2 * gap), "and again one gap later")
	assert_false(_service._accept_click(5_000_000 + 2 * gap + 1), "the gap counts from the last start")
	assert_eq(_service._clicks_started, 3)


func test_gap_keeps_overlap_within_polyphony() -> void:
	var click_usec: float = ClickSynth.build(roundi(AudioServer.get_mix_rate())).get_length() * 1_000_000.0
	assert_true(AudioService.POLYPHONY * AudioService.MIN_GAP_USEC >= click_usec,
			"a click has ended before the next but one starts, so no click is cut off")


func test_overlapping_clicks_stay_below_minus_1_dbfs() -> void:
	var wave: PackedFloat64Array = Measure.samples(ClickSynth.build())
	var peak: float = Measure.peak(wave)
	var worst: float = AudioService.POLYPHONY * peak
	assert_true(worst <= CEILING, "%d clicks lined up on the same sample reach %.2f dBFS" % [AudioService.POLYPHONY, Measure.to_dbfs(worst)])
	var together: PackedFloat64Array = Measure.mix(wave, PackedInt64Array([0, 0]))
	assert_true(Measure.peak(together) <= CEILING, "two clicks on the same sample mix to %.2f dBFS" % Measure.to_dbfs(Measure.peak(together)))


func test_a_fast_drag_does_not_stack_up() -> void:
	var gap_samples: int = roundi(AudioService.MIN_GAP_USEC * 44100 / 1_000_000.0)
	var starts: PackedInt64Array = PackedInt64Array()
	for i: int in 8:
		starts.append(i * gap_samples)
	var wave: PackedFloat64Array = Measure.samples(ClickSynth.build())
	var drag: float = Measure.peak(Measure.mix(wave, starts))
	assert_true(drag <= CEILING, "eight clicks one gap apart peak at %.2f dBFS" % Measure.to_dbfs(drag))
	assert_true(drag <= Measure.peak(wave) * db_to_linear(1.0), "and stay within 1 dB of a single click")


func _player() -> AudioStreamPlayer:
	for child: Node in _service.get_children():
		if child is AudioStreamPlayer:
			return child as AudioStreamPlayer
	return null
