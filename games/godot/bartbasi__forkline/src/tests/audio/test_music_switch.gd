# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The music switch (AudioService.set_music_on) beside the sound switch
## (set_enabled): every combination, toggling mid-track, the foreground gate
## with music off, and the fade.

var _made: Array[AudioService] = []


func after_each() -> void:
	for service: AudioService in _made:
		if service.is_inside_tree():
			service.get_parent().remove_child(service)
		service.free()
	_made.clear()


## A service outside the tree, built and ready (voice bookkeeping only).
func _service(gated: bool = false) -> AudioService:
	var service: AudioService = AudioService.new(gated)
	service.wait_until_ready()
	_made.append(service)
	return service


func _tap_plays(service: AudioService) -> bool:
	OS.delay_msec(int(AudioService.GAP_MS[&"tap"]) + 15)
	service.play_ui(&"tap")
	return service.voice_count(&"tap") == 1


func test_music_is_on_by_default() -> void:
	var service: AudioService = _service()
	assert_true(service.is_music_on())
	service.set_music(&"menu")
	assert_true(service.is_music_playing())


func test_every_combination_of_the_two_switches() -> void:
	for sound_on: bool in [true, false]:
		for music_on: bool in [true, false]:
			var service: AudioService = _service()
			service.set_enabled(sound_on)
			service.set_music_on(music_on)
			service.set_music(&"battle")
			var label: String = "sound %s, music %s" % [sound_on, music_on]
			assert_eq(service.current_music(), &"battle", label)
			assert_eq(service.is_music_playing(), sound_on and music_on, "music: " + label)
			service.play_ui(&"tap")
			assert_eq(service.voice_count(&"tap"), 1 if sound_on else 0, "effects: " + label)
			service.play_events([{"kind": &"won"}] as Array[Dictionary])
			assert_eq(service.voice_count(&"won"), 1 if sound_on else 0, "events: " + label)
			assert_eq(service.is_enabled(), sound_on, label)
			assert_eq(service.is_music_on(), music_on, label)


func test_every_combination_reached_in_the_other_order() -> void:
	# The switches are independent, so the order they were set in does not matter.
	for sound_on: bool in [true, false]:
		for music_on: bool in [true, false]:
			var service: AudioService = _service()
			service.set_music(&"menu")
			service.set_music_on(music_on)
			service.set_enabled(sound_on)
			assert_eq(service.is_music_playing(), sound_on and music_on, "sound %s, music %s" % [sound_on, music_on])
			# Flip both back to on: the wanted tune returns.
			service.set_music_on(true)
			service.set_enabled(true)
			assert_true(service.is_music_playing())
			assert_eq(service._music_playing, &"menu")


func test_music_off_mid_track_keeps_sound_effects() -> void:
	var service: AudioService = _service()
	service.set_music(&"battle")
	assert_true(service.is_music_playing())
	service.play_events([{"kind": &"wave_cleared"}] as Array[Dictionary])
	service.set_music_on(false)
	assert_false(service.is_music_playing())
	assert_eq(service.current_music(), &"battle")
	# The sound already playing is not cut, and new ones start.
	assert_eq(service.voice_count(&"wave_cleared"), 1)
	assert_true(_tap_plays(service))
	service.play_events([{"kind": &"won"}] as Array[Dictionary])
	assert_eq(service.voice_count(&"won"), 1)


func test_music_back_on_resumes_the_tune_for_the_screen() -> void:
	var service: AudioService = _service()
	service.set_music(&"battle")
	service.set_music_on(false)
	service.set_music_on(true)
	assert_true(service.is_music_playing())
	assert_eq(service._music_playing, &"battle")
	# A screen change while off is remembered, and the new screen's tune comes back.
	service.set_music_on(false)
	service.set_music(&"menu")
	assert_false(service.is_music_playing())
	assert_eq(service._music_playing, &"")
	assert_eq(service.current_music(), &"menu")
	service.set_music_on(true)
	assert_true(service.is_music_playing())
	assert_eq(service._music_playing, &"menu")
	# Silence stays silence.
	service.set_music(&"")
	service.set_music_on(false)
	service.set_music_on(true)
	assert_false(service.is_music_playing())


func test_the_switch_is_idempotent() -> void:
	var service: AudioService = _service()
	service.set_music(&"menu")
	service.set_music_on(true)
	service.set_music_on(true)
	assert_true(service.is_music_playing())
	service.set_music_on(false)
	service.set_music_on(false)
	assert_false(service.is_music_playing())
	service.set_music_on(true)
	assert_true(service.is_music_playing())


func test_sound_off_wins_over_music_on() -> void:
	var service: AudioService = _service()
	service.set_music(&"menu")
	service.set_enabled(false)
	service.set_music_on(false)
	service.set_music_on(true)
	assert_false(service.is_music_playing(), "music on must not override sound off")
	service.set_enabled(true)
	assert_true(service.is_music_playing())
	# Sound on does not override music off.
	service.set_music_on(false)
	service.set_enabled(false)
	service.set_enabled(true)
	assert_false(service.is_music_playing(), "sound on must not override music off")
	assert_true(_tap_plays(service))


func test_music_off_before_the_streams_are_built_stays_silent() -> void:
	var early: AudioService = AudioService.new()
	_made.append(early)
	early.set_music_on(false)
	early.set_music(&"battle")
	early.wait_until_ready()
	assert_false(early.is_music_playing())
	assert_eq(early._music_playing, &"")
	assert_eq(early.current_music(), &"battle")
	early.play_ui(&"tap")
	assert_eq(early.voice_count(&"tap"), 1)
	early.set_music_on(true)
	assert_true(early.is_music_playing())


func test_music_waiting_for_its_stream_does_not_start_after_music_off() -> void:
	# The service polls each frame while a tune waits for its stream. Music off
	# in that time stops the polling and nothing starts.
	var early: AudioService = AudioService.new()
	_made.append(early)
	early.set_music(&"menu")
	early.set_music_on(false)
	early.wait_until_ready()
	early._process(0.016)
	assert_false(early.is_music_playing())
	assert_eq(early._music_playing, &"")


# The foreground gate with music off.

func test_gate_with_music_off_keeps_the_music_off() -> void:
	var phone: AudioService = _service(true)
	phone.set_music_on(false)
	phone.set_music(&"menu")
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_true(phone.is_in_front())
	assert_false(phone.is_music_playing())
	assert_eq(phone._music_playing, &"")
	assert_true(_tap_plays(phone), "effects must still play in front")
	# Leaving and coming back: still no music.
	phone._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_false(phone.is_in_front())
	assert_eq(phone.voice_count(), 0)
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(phone.is_music_playing(), "music started on resume with music off")
	assert_eq(phone._music_playing, &"")
	phone._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	phone._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_false(phone.is_music_playing())
	assert_true(_tap_plays(phone))
	# Music on brings it back.
	phone.set_music_on(true)
	assert_true(phone.is_music_playing())


func test_gate_frame_fallback_with_music_off_starts_no_music() -> void:
	var phone: AudioService = _service(true)
	phone.set_music(&"battle")
	phone.set_music_on(false)
	phone._process(0.016)
	phone._process(0.016)
	assert_true(phone.is_in_front())
	assert_false(phone.is_music_playing())
	assert_eq(phone._music_playing, &"")
	phone._process(0.016)
	assert_false(phone.is_music_playing())


func test_music_off_while_away_stays_off_on_return() -> void:
	var phone: AudioService = _service(true)
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	phone.set_music(&"battle")
	assert_true(phone.is_music_playing())
	phone._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	phone.set_music_on(false)
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(phone.is_music_playing())
	assert_true(_tap_plays(phone))
	# Music on while away starts nothing, and returns on the way back.
	phone._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	phone.set_music_on(true)
	assert_false(phone.is_music_playing())
	assert_eq(phone._music_playing, &"")
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_true(phone.is_music_playing())
	assert_eq(phone._music_playing, &"battle")


func test_sound_off_then_on_with_music_off_stays_quiet_on_a_phone() -> void:
	var phone: AudioService = _service(true)
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	phone.set_music(&"menu")
	phone.set_music_on(false)
	phone.set_enabled(false)
	phone.set_enabled(true)
	assert_false(phone.is_music_playing())
	assert_true(_tap_plays(phone))


# The fade: no click. The tween itself needs a running scene tree, which the
# test runner does not have, so the ramp was also checked frame by frame in a
# running tree (see the audio engineer's report). Here: the numbers that keep it
# click free, and the off path outside a tree.

func test_the_fade_is_long_and_ends_quiet() -> void:
	# A fade from the music level to -40 dB over at least a quarter second is a
	# slope of 112 dB per second at most, which is smooth.
	var slope: float = (AudioService.MUSIC_DB - -40.0) / AudioService.FADE_OUT_SECONDS
	assert_true(AudioService.FADE_OUT_SECONDS >= 0.25, "fade out is too short")
	assert_true(slope <= 112.0, "fade out slope %f dB/s is too steep" % slope)
	assert_true(AudioService.FADE_IN_SECONDS >= 0.5, "fade in is too short")


func test_music_off_leaves_the_music_player_volume_alone_outside_a_tree() -> void:
	# Outside a tree there is nothing to ramp: the player is stopped, and the
	# next start sets its own starting volume.
	var service: AudioService = _service()
	service.set_music(&"battle")
	service.set_music_on(false)
	assert_false(service._music.playing)
	service.set_music_on(true)
	assert_true(service.is_music_playing())


func test_sound_effects_are_not_touched_by_the_music_switch() -> void:
	var service: AudioService = _service()
	service.set_music(&"battle")
	service.play_events([{"kind": &"won"}] as Array[Dictionary])
	service.play_ui(&"tap")
	var before: int = service.voice_count()
	assert_true(before >= 2)
	service.set_music_on(false)
	assert_eq(service.voice_count(), before, "effects were cut with the music")
	service.set_music_on(true)
	assert_eq(service.voice_count(), before)
