# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## AudioService: events and UI sounds start voices, the caps hold, and the
## toggle silences everything.

const EVENT_KINDS: Array[StringName] = [
	&"wave_started", &"spawned", &"fired", &"popped", &"defeated", &"healed",
	&"leaked", &"gate_broken", &"wave_cleared", &"build_started", &"built",
	&"upgraded", &"sold", &"gate_placed", &"gate_removed", &"won", &"lost",
	&"released", &"break_started", &"sped_up", &"interest",
	&"napped", &"woke", &"burrowed", &"surfaced", &"blinked", &"yawned",
]

## Every tower that fires, with its tier 3 paths in spec order.
const SHOOTERS: Array[StringName] = [
	&"sling_post", &"pumpkin_catapult", &"longbow_loft", &"firework_tower",
	&"bramble_cottage", &"snow_fort", &"moth_lantern",
]
## The three attacking towers of the expansion: plain, spec 0 and spec 1 shot sounds.
const EXPANSION_SHOTS: Dictionary[StringName, Array] = {
	&"bramble_cottage": [&"shot_bramble_cottage", &"shot_wild_bramble", &"shot_holly_crown"],
	&"snow_fort": [&"shot_snow_fort", &"shot_big_snowball", &"shot_flurry"],
	&"moth_lantern": [&"shot_moth_lantern", &"shot_beacon_lantern", &"shot_lantern_garland"],
}
## The six events of the expansion (architecture 14.6).
const CREATURE_EVENTS: Array[StringName] = [&"napped", &"woke", &"burrowed", &"surfaced", &"blinked", &"yawned"]

var service: AudioService = null


func before_each() -> void:
	# The runner starts tests before the scene tree is running, so the service
	# is used outside the tree. Voice bookkeeping and the caps run the same
	# there; only the engine's play() call is skipped.
	service = AudioService.new()
	service.wait_until_ready()


func after_each() -> void:
	service.free()
	service = null


## An event shaped like the sim's (architecture 3.1). Fields a kind does not
## use are harmless extras.
func _event(kind: StringName) -> Dictionary:
	if kind == &"fired":
		return _shot(&"sling_post", -1, Vector2i(2, 3))
	return {
		"kind": kind, "id": 7, "cell": Vector2i(1, 1), "tower": &"sling_post", "tier": 1, "spec": -1, "gold": 10,
		"enemy": &"yawner", "pos": Vector2i(30000, 50000), "from": Vector2i(20000, 50000),
		"cells": [Vector2i(1, 1)],
	}


func _shot(tower: StringName, spec: int, cell: Vector2i) -> Dictionary:
	var targets: Array[int] = [4]
	var at: Array[Vector2i] = [Vector2i(30000, 50000)]
	return {"kind": &"fired", "cell": cell, "tower": tower, "spec": spec, "targets": targets, "at": at}


func _events(kind: StringName, count: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in count:
		out.append(_event(kind))
	return out


func _playing_players() -> int:
	var count: int = 0
	for child: Node in service.get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing:
			count += 1
	return count


func test_every_sound_is_built() -> void:
	assert_true(service.is_ready())
	for sound: StringName in SoundBank.EFFECTS:
		assert_not_null(service._bank.stream(sound), "%s missing" % sound)
	for track: StringName in SoundBank.TRACKS:
		assert_not_null(service._bank.stream(track), "%s missing" % track)


func test_every_event_kind_starts_a_voice() -> void:
	for kind: StringName in EVENT_KINDS:
		service.set_enabled(false)
		service.set_enabled(true)
		service.play_events(_events(kind, 1))
		var sound: StringName = AudioService.EVENT_SOUNDS[kind]
		assert_eq(service.voice_count(sound), 1, "%s made no sound" % kind)


func test_every_ui_sound_starts_a_voice() -> void:
	for sound: StringName in AudioService.UI_SOUNDS:
		service.play_ui(sound)
		assert_eq(service.voice_count(sound), 1, "%s made no sound" % sound)


func test_unknown_events_and_ui_sounds_are_ignored() -> void:
	var hostile: Array[Dictionary] = [
		{}, {"kind": 5}, {"kind": &"no_such_kind"}, {"kind": "also_nothing"},
		{"kind": &"fired"}, {"kind": &"fired", "tower": 5, "spec": "x", "cell": "x"},
		{"kind": &"fired", "tower": &"no_such_tower", "spec": 99}, {"kind": &"defeated", "id": "x"},
	]
	service.play_events(hostile)
	# Only the fired and defeated events are real kinds, so at most two sounds start.
	assert_true(service.voice_count() <= 2)
	assert_eq(service.voice_count(&"star"), 0)
	assert_eq(AudioService.sound_for({"kind": &"fired", "tower": 5}), &"fired")
	assert_eq(AudioService.sound_for({"kind": &"fired", "tower": &"no_such_tower", "spec": 99}), &"fired")
	assert_eq(AudioService.sound_for({"kind": &"fired", "tower": &"sling_post", "spec": 99}), &"fired")
	assert_eq(AudioService.sound_for({"kind": 5}), &"")
	service.play_ui(&"no_such_ui")
	service.play_ui(&"fired")
	assert_eq(service.voice_count(&"star"), 0)


func test_fifty_of_one_event_in_one_frame_hold_the_caps() -> void:
	for kind: StringName in EVENT_KINDS:
		service.set_enabled(false)
		service.set_enabled(true)
		service.play_events(_events(kind, 50))
		var sound: StringName = AudioService.EVENT_SOUNDS[kind]
		assert_true(service.voice_count(sound) >= 1, "%s: nothing played" % kind)
		assert_true(service.voice_count(sound) <= AudioService.MAX_SAME, "%s: %d voices" % [kind, service.voice_count(sound)])
		assert_true(service.voice_count() <= AudioService.VOICES, "%s: %d voices in all" % [kind, service.voice_count()])


func test_same_sound_cap_holds_over_time() -> void:
	# Spaced starts get past the gap, so only the cap of 3 can stop them.
	var gap: int = int(AudioService.GAP_MS[&"defeated"]) + 15
	var most: int = 0
	for i: int in 8:
		service.play_events(_events(&"defeated", 10))
		most = maxi(most, service.voice_count(&"defeated"))
		assert_true(service.voice_count(&"defeated") <= AudioService.MAX_SAME)
		OS.delay_msec(gap)
	assert_eq(most, AudioService.MAX_SAME, "the cap was never reached, so the test proved nothing")


func test_total_cap_holds_with_every_sound_at_once() -> void:
	var all: Array[Dictionary] = []
	for kind: StringName in EVENT_KINDS:
		all.append(_event(kind))
	var most: int = 0
	for round_index: int in 6:
		service.play_events(all)
		for sound: StringName in AudioService.UI_SOUNDS:
			service.play_ui(sound)
		most = maxi(most, service.voice_count())
		assert_true(service.voice_count() <= AudioService.VOICES)
		OS.delay_msec(130)
	assert_true(most > AudioService.MAX_SAME, "mixed sounds never stacked: %d" % most)


func test_the_big_sounds_still_play_when_voices_are_full() -> void:
	# Fill every voice with frequent sounds, then ask for a loss.
	for round_index: int in 8:
		service.play_events(_events(&"defeated", 3))
		service.play_events(_events(&"fired", 3))
		service.play_events(_events(&"spawned", 3))
		service.play_events(_events(&"popped", 3))
		service.play_events(_events(&"healed", 3))
		OS.delay_msec(70)
	service.play_events(_events(&"lost", 1))
	assert_eq(service.voice_count(&"lost"), 1)
	assert_true(service.voice_count() <= AudioService.VOICES)


func test_toggle_off_silences_everything() -> void:
	service.set_music(&"battle")
	service.play_events(_events(&"wave_cleared", 1))
	service.play_ui(&"tap")
	assert_true(service.voice_count() > 0)
	assert_true(service.is_music_playing())
	service.set_enabled(false)
	assert_false(service.is_enabled())
	assert_eq(service.voice_count(), 0)
	assert_false(service.is_music_playing())
	assert_eq(_playing_players(), 0, "a player is still playing")
	# New sounds, UI sounds and music stay silent while off.
	for kind: StringName in EVENT_KINDS:
		service.play_events(_events(kind, 5))
	for sound: StringName in AudioService.UI_SOUNDS:
		service.play_ui(sound)
	service.set_music(&"menu")
	assert_eq(service.voice_count(), 0)
	assert_eq(_playing_players(), 0)
	assert_false(service.is_music_playing())


func test_toggle_back_on_brings_the_music_back() -> void:
	service.set_music(&"battle")
	service.set_enabled(false)
	service.set_enabled(true)
	assert_eq(service.current_music(), &"battle")
	assert_true(service.is_music_playing())
	service.play_ui(&"tap")
	assert_eq(service.voice_count(&"tap"), 1)


func test_music_choice() -> void:
	service.set_music(&"menu")
	assert_eq(service.current_music(), &"menu")
	assert_true(service.is_music_playing())
	service.set_music(&"battle")
	assert_eq(service.current_music(), &"battle")
	service.set_music(&"")
	assert_eq(service.current_music(), &"")
	service.set_music(&"no_such_track")
	assert_eq(service.current_music(), &"")


func test_music_asked_before_the_streams_are_built_starts_when_ready() -> void:
	var early: AudioService = AudioService.new()
	early.set_music(&"battle")
	early.wait_until_ready()
	assert_true(early.is_music_playing())
	early.free()


func test_sounds_asked_before_they_are_built_are_skipped_not_fatal() -> void:
	var early: AudioService = AudioService.new()
	early.play_events(_events(&"won", 1))
	early.play_ui(&"star")
	early.wait_until_ready()
	assert_true(early.voice_count() <= 2)
	early.free()


func test_disabled_before_anything_else_stays_silent() -> void:
	var early: AudioService = AudioService.new()
	early.set_enabled(false)
	early.set_music(&"menu")
	early.wait_until_ready()
	early.play_ui(&"tap")
	early.play_events(_events(&"won", 1))
	assert_eq(early.current_music(), &"menu")
	assert_false(early.is_music_playing())
	assert_eq(early.voice_count(), 0)
	early.free()


func test_mixer_buses_exist_and_the_sfx_bus_has_a_limiter() -> void:
	var sfx: int = AudioServer.get_bus_index(AudioService.SFX_BUS)
	assert_true(sfx >= 0)
	assert_true(AudioServer.get_bus_index(AudioService.MUSIC_BUS) >= 0)
	assert_true(AudioServer.get_bus_effect(sfx, 0) is AudioEffectLimiter)


func test_fired_picks_the_shot_by_tower_and_path() -> void:
	var catapult: StringName = AudioService.sound_for(_shot(&"pumpkin_catapult", -1, Vector2i(1, 1)))
	var sling: StringName = AudioService.sound_for(_shot(&"sling_post", -1, Vector2i(1, 1)))
	assert_eq(catapult, &"shot_pumpkin_catapult")
	assert_eq(sling, &"fired")
	assert_eq(AudioService.sound_for(_shot(&"sling_post", 0, Vector2i(1, 1))), &"shot_quickshot")
	assert_eq(AudioService.sound_for(_shot(&"sling_post", 1, Vector2i(1, 1))), &"shot_stone_sling")
	assert_eq(AudioService.sound_for(_shot(&"pumpkin_catapult", 1, Vector2i(1, 1))), &"shot_jam_pot")
	service.play_events([_shot(&"pumpkin_catapult", -1, Vector2i(1, 1))] as Array[Dictionary])
	assert_eq(service.voice_count(&"shot_pumpkin_catapult"), 1)
	assert_eq(service.voice_count(&"fired"), 0)


func test_two_towers_fired_events_pick_different_streams() -> void:
	var a: StringName = AudioService.sound_for(_shot(&"sling_post", -1, Vector2i(0, 0)))
	var b: StringName = AudioService.sound_for(_shot(&"pumpkin_catapult", -1, Vector2i(0, 0)))
	assert_ne(a, b)
	assert_ne(service._bank.stream(a).data, service._bank.stream(b).data)


func test_every_tower_and_path_has_a_shot_stream() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for tower: StringName in SHOOTERS:
		for spec: int in [-1, 0, 1]:
			var sound: StringName = AudioService.sound_for(_shot(tower, spec, Vector2i(2, 2)))
			assert_not_null(service._bank.stream(sound), "%s %d has no stream" % [tower, spec])
			assert_true(AudioService.SHOT_IDS.has(sound), "%s %d: %s is not a shot" % [tower, spec, sound])
			seen[sound] = true
	# Seven attacking towers with three sounds each.
	assert_eq(seen.size(), 21)
	assert_eq(AudioService.SHOT_IDS.size(), 21)


func test_bells_bakeries_and_scarecrows_have_no_shot_sound() -> void:
	# They never fire (architecture 3.1, RULES 5.13), so no shot sound is kept for them.
	for tower: StringName in [&"lullaby_bell", &"bakery", &"scarecrow"]:
		assert_false(AudioService.SHOT_SOUNDS.has(tower), "%s has a shot row" % tower)
	for sound: StringName in SoundBank.EFFECTS:
		var text: String = String(sound)
		assert_false(text.contains("bell") or text.contains("bakery"), "%s is an unused shot sound" % sound)
	for sound: StringName in AudioService.GAIN_DB:
		assert_true(SoundBank.EFFECTS.has(sound), "%s has a gain but no sound" % sound)
	for sound: StringName in AudioService.GAP_MS:
		assert_true(SoundBank.EFFECTS.has(sound), "%s has a gap but no sound" % sound)


func test_shot_pitch_spread_comes_from_the_cell() -> void:
	var pitches: Dictionary[float, bool] = {}
	for x: int in 7:
		pitches[service._pitch_for(&"fired", _shot(&"sling_post", -1, Vector2i(x, 0)))] = true
	assert_true(pitches.size() >= 4, "the spread is too narrow: %d" % pitches.size())
	assert_eq(service._pitch_for(&"fired", {"kind": &"fired", "tower": &"sling_post"}), 1.0)


func test_shots_of_every_tower_in_one_frame_stay_under_the_shot_cap() -> void:
	var all: Array[Dictionary] = []
	for tower: StringName in SHOOTERS:
		for spec: int in [-1, 0, 1]:
			all.append(_shot(tower, spec, Vector2i(spec + 1, 2)))
	var most: int = 0
	for round_index: int in 6:
		service.play_events(all)
		var shots: int = 0
		for sound: StringName in AudioService.SHOT_IDS:
			shots += service.voice_count(sound)
		most = maxi(most, shots)
		assert_true(shots <= AudioService.MAX_SHOTS, "%d shots at once" % shots)
		assert_true(service.voice_count() <= AudioService.VOICES)
		OS.delay_msec(70)
	assert_eq(most, AudioService.MAX_SHOTS, "the shot cap was never reached")


## The four phase 7 events, shaped as the sim sends them (architecture 3.1).
func _phase7_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{"kind": &"released", "id": 3, "source": &"puffball", "enemy": &"puff", "count": 3, "pos": Vector2i(40000, 20000)},
		{"kind": &"break_started", "id": 5, "cell": Vector2i(2, 4)},
		{"kind": &"sped_up", "id": 9, "speed": 140},
		{"kind": &"interest", "gold": 12},
	]
	return out


func test_phase_7_events_each_play_their_own_sound() -> void:
	for event: Dictionary in _phase7_events():
		var kind: StringName = event["kind"]
		assert_eq(AudioService.sound_for(event), kind, "%s maps to the wrong sound" % kind)
		service.set_enabled(false)
		service.set_enabled(true)
		service.play_events([event] as Array[Dictionary])
		assert_eq(service.voice_count(kind), 1, "%s made no sound" % kind)
		assert_eq(service.voice_count(), 1, "%s started more than one sound" % kind)


func test_a_big_split_does_not_machine_gun() -> void:
	# Forty releases in one frame make one sound. Spread over time, the cap of 3 holds.
	var split: Array[Dictionary] = []
	for i: int in 40:
		split.append(_phase7_events()[0])
	service.play_events(split)
	assert_eq(service.voice_count(&"released"), 1)
	var gap: int = int(AudioService.GAP_MS[&"released"]) + 15
	for i: int in 8:
		service.play_events(split)
		assert_true(service.voice_count(&"released") <= AudioService.MAX_SAME)
		OS.delay_msec(gap)


func test_warnings_still_play_when_voices_are_full() -> void:
	for round_index: int in 8:
		service.play_events(_events(&"defeated", 3))
		service.play_events(_events(&"fired", 3))
		service.play_events(_events(&"spawned", 3))
		service.play_events(_events(&"popped", 3))
		service.play_events(_events(&"released", 3))
		OS.delay_msec(70)
	var warnings: Array[Dictionary] = [_phase7_events()[1], _phase7_events()[2]]
	service.play_events(warnings)
	assert_eq(service.voice_count(&"break_started"), 1)
	assert_eq(service.voice_count(&"sped_up"), 1)
	assert_true(service.voice_count() <= AudioService.VOICES)


func test_releasing_playback_lets_go_of_every_stream() -> void:
	# At exit a player still holding a stream leaks the stream and its playback.
	service.set_music(&"menu")
	service.play_events(_events(&"built", 1))
	service._release_playback()
	assert_null(service._music.stream)
	for player: AudioStreamPlayer in service._voices:
		assert_null(player.stream)
	assert_false(service.is_music_playing())


# Foreground only. A phone service (gated) plays nothing until the app is in
# front and stops everything when it leaves. The notifications are sent by hand.

func _gated_service() -> AudioService:
	var gated: AudioService = AudioService.new(true)
	gated.wait_until_ready()
	return gated


func test_a_phone_service_starts_silent_until_the_app_is_in_front() -> void:
	var phone: AudioService = _gated_service()
	assert_false(phone.is_in_front())
	phone.set_music(&"menu")
	phone.play_ui(&"tap")
	phone.play_events(_events(&"built", 1))
	assert_eq(phone.current_music(), &"menu")
	assert_false(phone.is_music_playing())
	assert_eq(phone.voice_count(), 0)
	assert_eq(phone._music_playing, &"")
	phone._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(phone.is_in_front())
	assert_true(phone.is_music_playing())
	phone.play_ui(&"tap")
	assert_eq(phone.voice_count(&"tap"), 1)
	phone.free()


func test_resumed_also_brings_the_app_to_the_front() -> void:
	var phone: AudioService = _gated_service()
	phone.set_music(&"battle")
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_true(phone.is_music_playing())
	phone.free()


func test_leaving_the_front_stops_every_voice_and_the_music() -> void:
	for leave: int in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT]:
		var phone: AudioService = _gated_service()
		phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		phone.set_music(&"battle")
		phone.play_events(_events(&"wave_cleared", 1))
		phone.play_ui(&"tap")
		assert_true(phone.is_music_playing())
		assert_true(phone.voice_count() > 0)
		phone._notification(leave)
		assert_false(phone.is_in_front())
		assert_false(phone.is_music_playing())
		assert_eq(phone.voice_count(), 0)
		assert_eq(phone._music_playing, &"")
		for child: Node in phone.get_children():
			if child is AudioStreamPlayer:
				assert_false((child as AudioStreamPlayer).playing, "a player kept playing")
		# Nothing new starts while away, and a music change waits.
		phone.play_ui(&"tap")
		phone.play_events(_events(&"won", 1))
		phone.set_music(&"menu")
		assert_eq(phone.voice_count(), 0)
		assert_false(phone.is_music_playing())
		assert_eq(phone.current_music(), &"menu")
		# Back in front: the music wanted last comes back, and sounds play.
		phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		assert_true(phone.is_music_playing())
		assert_eq(phone._music_playing, &"menu")
		OS.delay_msec(int(AudioService.GAP_MS[&"tap"]) + 15)
		phone.play_ui(&"tap")
		assert_eq(phone.voice_count(&"tap"), 1)
		phone.free()


func test_sound_off_stays_off_after_coming_to_the_front() -> void:
	var phone: AudioService = _gated_service()
	phone.set_enabled(false)
	phone.set_music(&"menu")
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(phone.is_music_playing())
	phone.play_ui(&"tap")
	assert_eq(phone.voice_count(), 0)
	phone.set_enabled(true)
	assert_true(phone.is_music_playing())
	# Turning sound on while away does not start anything.
	phone._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	phone.set_enabled(false)
	phone.set_enabled(true)
	assert_false(phone.is_music_playing())
	phone.free()


func test_the_frame_fallback_brings_a_phone_service_to_the_front() -> void:
	# If neither RESUMED nor FOCUS_IN arrives, a drawn frame is the sign.
	var phone: AudioService = _gated_service()
	phone.set_music(&"menu")
	phone._process(0.016)
	assert_false(phone.is_music_playing(), "one frame is too early")
	phone._process(0.016)
	assert_true(phone.is_in_front())
	assert_true(phone.is_music_playing())
	phone.free()


func test_the_frame_fallback_never_overrides_a_leave() -> void:
	var phone: AudioService = _gated_service()
	phone.set_music(&"menu")
	phone._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	for i: int in 10:
		phone._process(0.016)
	assert_false(phone.is_in_front())
	assert_false(phone.is_music_playing())
	phone.free()


func test_a_desktop_service_ignores_focus_changes() -> void:
	# Windows and headless keep the old behavior: always in front.
	service.set_music(&"menu")
	assert_true(service.is_in_front())
	service._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(service.is_in_front())
	assert_true(service.is_music_playing())
	service.play_ui(&"tap")
	assert_eq(service.voice_count(&"tap"), 1)


func test_releasing_playback_still_works_when_gated() -> void:
	var phone: AudioService = _gated_service()
	phone._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	phone.set_music(&"menu")
	phone.play_events(_events(&"built", 1))
	phone._release_playback()
	assert_null(phone._music.stream)
	assert_false(phone.is_music_playing())
	phone.free()
