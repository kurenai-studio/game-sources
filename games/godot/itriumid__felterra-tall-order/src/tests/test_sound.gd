extends TestCase
## The sound kit: every sound it promises can be made, isn't silent, doesn't clip, and its
## variants differ, so a repeat never sounds the same.


func test_every_sound_is_made_and_heard_and_does_not_clip() -> void:
	for sound_name in SoundKit.NAMES:
		var stream := SoundKit.stream(sound_name, 0)
		check(stream.data.size() > 0, "%s has no samples" % sound_name)
		var loudest := SoundKit.peak(sound_name)
		check(loudest > 0.05, "%s is all but silent: peak %.2f" % [sound_name, loudest])
		check(loudest < 0.99, "%s clips" % sound_name)


func test_variants_of_a_noisy_sound_differ() -> void:
	var first := SoundKit.stream("hit_small", 0).data
	var second := SoundKit.stream("hit_small", 1).data
	check(first != second, "two variants of a hit are the same sound")


func test_the_director_only_asks_for_sounds_the_kit_has() -> void:
	var source := FileAccess.get_file_as_string("res://game/audio_director.gd") + FileAccess.get_file_as_string("res://game/main.gd")
	# Whole names only: a name built from parts, like a shot's, is checked by the test above.
	var asked := RegEx.create_from_string("(?:play_at|interface)\\(\"([a-z_]+)\"[,)]")
	for found in asked.search_all(source):
		check(found.get_string(1) in SoundKit.NAMES, "%s is asked for but never made" % found.get_string(1))
