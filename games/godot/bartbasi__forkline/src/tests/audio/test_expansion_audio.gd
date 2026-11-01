# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## AU1: the shot sounds of the expansion's attacking towers and the sounds of
## the creature events (architecture 14.6, 14.11): mapping, caps, rate limits,
## the toggle, and the quiet mix.

## The three attacking towers of the expansion: plain, spec 0 and spec 1 shot sounds.
const EXPANSION_SHOTS: Dictionary[StringName, Array] = {
	&"bramble_cottage": [&"shot_bramble_cottage", &"shot_wild_bramble", &"shot_holly_crown"],
	&"snow_fort": [&"shot_snow_fort", &"shot_big_snowball", &"shot_flurry"],
	&"moth_lantern": [&"shot_moth_lantern", &"shot_beacon_lantern", &"shot_lantern_garland"],
}
const COTTAGE_SHOTS: Array[StringName] = [&"shot_bramble_cottage", &"shot_wild_bramble", &"shot_holly_crown"]
## The six events of the expansion.
const CREATURE_EVENTS: Array[StringName] = [&"napped", &"woke", &"burrowed", &"surfaced", &"blinked", &"yawned"]

var service: AudioService = null


func before_each() -> void:
	service = AudioService.new()
	service.wait_until_ready()


func after_each() -> void:
	service.free()
	service = null


func _shot(tower: StringName, spec: int, cell: Vector2i) -> Dictionary:
	var targets: Array[int] = [4]
	var at: Array[Vector2i] = [Vector2i(30000, 50000)]
	return {"kind": &"fired", "cell": cell, "tower": tower, "spec": spec, "targets": targets, "at": at}


## A creature event shaped like the sim's (architecture 14.6). A yawn dozes one tower.
func _event(kind: StringName) -> Dictionary:
	var cells: Array[Vector2i] = [Vector2i(1, 1)]
	return {
		"kind": kind, "id": 7, "enemy": &"yawner", "pos": Vector2i(30000, 50000),
		"from": Vector2i(20000, 50000), "cells": cells,
	}


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


func _shot_voices() -> int:
	var shots: int = 0
	for sound: StringName in AudioService.SHOT_IDS:
		shots += service.voice_count(sound)
	return shots


func test_expansion_towers_pick_their_shot_by_tower_and_path() -> void:
	for tower: StringName in EXPANSION_SHOTS:
		var row: Array = EXPANSION_SHOTS[tower]
		assert_eq(AudioService.sound_for(_shot(tower, -1, Vector2i(1, 1))), row[0], "%s plain" % tower)
		assert_eq(AudioService.sound_for(_shot(tower, 0, Vector2i(1, 1))), row[1], "%s spec 0" % tower)
		assert_eq(AudioService.sound_for(_shot(tower, 1, Vector2i(1, 1))), row[2], "%s spec 1" % tower)
		# A spec outside 0 and 1 falls back to the plain shot, never to a wrong path.
		assert_eq(AudioService.sound_for(_shot(tower, 2, Vector2i(1, 1))), row[0], "%s spec 2" % tower)
		for sound: StringName in row:
			assert_not_null(service._bank.stream(sound), "%s has no stream" % sound)
			assert_true(AudioService.SHOT_IDS.has(sound), "%s is not capped as a shot" % sound)


func test_the_scarecrow_has_no_shot_and_a_stray_event_is_safe() -> void:
	assert_false(AudioService.SHOT_SOUNDS.has(&"scarecrow"))
	# The sim never sends one. If one came, it would make the plain pip.
	assert_eq(AudioService.sound_for(_shot(&"scarecrow", -1, Vector2i(1, 1))), &"fired")


func test_a_pulse_or_line_is_one_sound_however_many_it_hits() -> void:
	var targets: Array[int] = []
	var at: Array[Vector2i] = []
	for i: int in 30:
		targets.append(i)
		at.append(Vector2i(10000 + i * 100, 20000))
	var pulse: Dictionary = {"kind": &"fired", "cell": Vector2i(2, 3), "tower": &"bramble_cottage", "spec": -1, "targets": targets, "at": at}
	var line: Dictionary = {"kind": &"fired", "cell": Vector2i(4, 3), "tower": &"snow_fort", "spec": 1, "targets": targets, "at": at, "to": Vector2i(60000, 20000)}
	service.play_events([pulse] as Array[Dictionary])
	assert_eq(service.voice_count(&"shot_bramble_cottage"), 1)
	assert_eq(service.voice_count(), 1)
	service.play_events([line] as Array[Dictionary])
	assert_eq(service.voice_count(&"shot_flurry"), 1)
	assert_eq(service.voice_count(), 2)


func test_ten_cottages_pulsing_in_one_frame_make_one_sound() -> void:
	var pulses: Array[Dictionary] = []
	for i: int in 10:
		pulses.append(_shot(&"bramble_cottage", -1, Vector2i(i % 7, i / 7)))
	service.play_events(pulses)
	assert_eq(service.voice_count(&"shot_bramble_cottage"), 1)


func test_cottage_pulses_over_time_stay_under_the_caps() -> void:
	# Cottages of every path pulse together, round after round. The shot cap and
	# the cap of the same sound hold, and spaced starts do reach the caps.
	var pulses: Array[Dictionary] = []
	for spec: int in [-1, 0, 1]:
		for i: int in 4:
			pulses.append(_shot(&"bramble_cottage", spec, Vector2i(i, spec + 2)))
	var gap: int = int(AudioService.GAP_MS[&"shot_bramble_cottage"]) + 15
	var most: int = 0
	for round_index: int in 10:
		service.play_events(pulses)
		most = maxi(most, _shot_voices())
		assert_true(_shot_voices() <= AudioService.MAX_SHOTS, "%d shots at once" % _shot_voices())
		for sound: StringName in COTTAGE_SHOTS:
			assert_true(service.voice_count(sound) <= AudioService.MAX_SAME)
		assert_true(service.voice_count() <= AudioService.VOICES)
		OS.delay_msec(gap)
	assert_true(most >= 2, "the three paths never sounded together: %d" % most)


func test_expansion_events_each_play_their_own_sound() -> void:
	for kind: StringName in CREATURE_EVENTS:
		var event: Dictionary = _event(kind)
		assert_eq(AudioService.sound_for(event), kind, "%s maps to the wrong sound" % kind)
		service.set_enabled(false)
		service.set_enabled(true)
		service.play_events([event] as Array[Dictionary])
		assert_eq(service.voice_count(kind), 1, "%s made no sound" % kind)
		assert_eq(service.voice_count(), 1, "%s started more than one sound" % kind)


func test_a_yawn_that_dozes_no_tower_is_silent() -> void:
	var empty: Array[Vector2i] = []
	var none: Dictionary = {"kind": &"yawned", "id": 3, "enemy": &"yawner", "pos": Vector2i(1, 1), "cells": empty}
	assert_eq(AudioService.sound_for(none), &"")
	service.play_events([none] as Array[Dictionary])
	assert_eq(service.voice_count(), 0)
	# A malformed yawn is silent too, never a crash.
	for bad: Variant in [null, 5, "x", &"y", Vector2i(1, 1)]:
		assert_eq(AudioService.sound_for({"kind": &"yawned", "cells": bad}), &"")
	assert_eq(AudioService.sound_for({"kind": &"yawned"}), &"")
	var one: Array[Vector2i] = [Vector2i(2, 2)]
	assert_eq(AudioService.sound_for({"kind": &"yawned", "cells": one}), &"yawned")


func test_no_lives_lost_is_silent_on_purpose() -> void:
	assert_false(AudioService.EVENT_SOUNDS.has(&"no_lives_lost"))
	assert_eq(AudioService.sound_for({"kind": &"no_lives_lost"}), &"")


func test_fifty_blinks_digs_and_yawns_do_not_spam() -> void:
	for kind: StringName in CREATURE_EVENTS:
		service.set_enabled(false)
		service.set_enabled(true)
		service.play_events(_events(kind, 50))
		assert_eq(service.voice_count(kind), 1, "%s stacked in one frame" % kind)
	# Spread over time, the same sound never passes its cap.
	for kind: StringName in [&"blinked", &"burrowed", &"surfaced"]:
		service.set_enabled(false)
		service.set_enabled(true)
		var gap: int = int(AudioService.GAP_MS[kind]) + 15
		for i: int in 6:
			service.play_events(_events(kind, 10))
			assert_true(service.voice_count(kind) <= AudioService.MAX_SAME)
			OS.delay_msec(gap)


func test_repeating_creature_sounds_give_way_and_messages_do_not() -> void:
	for kind: StringName in [&"blinked", &"burrowed", &"surfaced"]:
		assert_true(AudioService.OTHER_COMMON.has(kind), "%s should give way" % kind)
	for kind: StringName in [&"napped", &"woke", &"yawned"]:
		assert_false(AudioService.OTHER_COMMON.has(kind), "%s carries a message and should play" % kind)
	# Fill every voice with frequent sounds (four sounds, three voices each).
	var frequent: Array[StringName] = [&"defeated", &"spawned", &"popped", &"healed"]
	for i: int in AudioService.VOICES:
		service._voice_sound[i] = frequent[i % frequent.size()]
		service._voice_end[i] = Time.get_ticks_msec() + 5000
	assert_eq(service.voice_count(), AudioService.VOICES)
	service.play_events(_events(&"blinked", 1))
	service.play_events(_events(&"burrowed", 1))
	assert_eq(service.voice_count(&"blinked"), 0)
	assert_eq(service.voice_count(&"burrowed"), 0)
	service.play_events([_event(&"napped"), _event(&"woke"), _event(&"yawned")] as Array[Dictionary])
	assert_eq(service.voice_count(&"napped"), 1)
	assert_eq(service.voice_count(&"woke"), 1)
	assert_eq(service.voice_count(&"yawned"), 1)
	assert_true(service.voice_count() <= AudioService.VOICES)


func test_blink_pitch_varies_by_creature() -> void:
	var seen: Dictionary[float, bool] = {}
	for id: int in 6:
		var event: Dictionary = _event(&"blinked")
		event["id"] = id
		seen[service._pitch_for(&"blinked", event)] = true
	assert_eq(seen.size(), AudioService.PUFF_PITCHES.size())
	assert_eq(service._pitch_for(&"blinked", {"kind": &"blinked"}), 1.0)


func test_the_toggle_silences_the_new_shots_and_events() -> void:
	service.set_enabled(false)
	var all: Array[Dictionary] = []
	for tower: StringName in EXPANSION_SHOTS:
		for spec: int in [-1, 0, 1]:
			all.append(_shot(tower, spec, Vector2i(1, 2)))
	for kind: StringName in CREATURE_EVENTS:
		all.append(_event(kind))
	service.play_events(all)
	assert_eq(service.voice_count(), 0)
	assert_eq(_playing_players(), 0)
	# On again, they play. Off stops them at once.
	service.set_enabled(true)
	service.play_events(all)
	assert_true(service.voice_count() > 0)
	service.set_enabled(false)
	assert_eq(service.voice_count(), 0)
	assert_eq(_playing_players(), 0)


# The sounds themselves.

func test_every_expansion_sound_is_built() -> void:
	for tower: StringName in EXPANSION_SHOTS:
		for sound: StringName in EXPANSION_SHOTS[tower]:
			assert_true(SoundBank.EFFECTS.has(sound), sound)
			assert_not_null(SoundBank.render_effect(sound), sound)
	for sound: StringName in CREATURE_EVENTS:
		assert_true(SoundBank.EFFECTS.has(sound), sound)
		assert_eq(AudioService.EVENT_SOUNDS[sound], sound)
		assert_false(AudioService.SHOT_IDS.has(sound), "%s should not count as a shot" % sound)
		assert_not_null(SoundBank.render_effect(sound), sound)


func test_expansion_shots_are_soft_and_cottages_are_the_quietest_and_slowest() -> void:
	for tower: StringName in EXPANSION_SHOTS:
		for sound: StringName in EXPANSION_SHOTS[tower]:
			assert_true(float(AudioService.GAIN_DB[sound]) <= -12.0, "%s is too loud for a shot" % sound)
			assert_true(int(AudioService.GAP_MS[sound]) >= 70, "%s repeats too fast" % sound)
			assert_true(SoundBank.render_effect(sound).get_length() <= 0.6, "%s is too long for a shot" % sound)
	for sound: StringName in COTTAGE_SHOTS:
		assert_true(int(AudioService.GAP_MS[sound]) >= 100, "%s pulses too often" % sound)
		assert_true(float(AudioService.GAIN_DB[sound]) <= float(AudioService.GAIN_DB[&"fired"]), "%s is louder than the plain pip" % sound)


func test_the_repeating_creature_sounds_are_quiet_and_spaced() -> void:
	# Blinks repeat the most, so they are the quietest and the most spaced.
	assert_true(float(AudioService.GAIN_DB[&"blinked"]) <= -18.0)
	assert_true(int(AudioService.GAP_MS[&"blinked"]) >= 250)
	for sound: StringName in [&"burrowed", &"surfaced"]:
		assert_true(float(AudioService.GAIN_DB[sound]) <= -12.0)
		assert_true(int(AudioService.GAP_MS[sound]) >= 200)
	# The messages (asleep, awake, towers drowsy) are heard but never loud.
	for sound: StringName in [&"napped", &"woke", &"yawned"]:
		assert_true(float(AudioService.GAIN_DB[sound]) >= -12.0, "%s is too faint to read" % sound)
		assert_true(float(AudioService.GAIN_DB[sound]) <= -6.0, "%s is too loud" % sound)
	for sound: StringName in CREATURE_EVENTS:
		assert_true(SoundBank.render_effect(sound).get_length() <= 0.9, "%s is too long" % sound)
