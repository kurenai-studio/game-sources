# Standalone checks for french_dictionary.gd, runnable via:
#   godot4 --headless --path . --script tests/test_french_dictionary.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	var dictionary := FrenchDictionary.new()

	# Sanity: a real dictionary loaded, not an empty/broken one.
	_check(dictionary.word_count() > 50000, "loaded a substantial number of words")

	# Known real entries (verified present in fr-classique.dic), checked
	# both in their natural accented form and in plain tile-letter form —
	# since the physical tiles only ever show plain A-Z, both must work.
	_check(dictionary.is_word_valid("maison"), "a common word is valid, lowercase")
	_check(dictionary.is_word_valid("MAISON"), "...and uppercase")
	_check(dictionary.is_word_valid("table"), "another common word is valid")
	_check(dictionary.is_word_valid("étude"), "a word with an accent is valid in its accented form")
	_check(dictionary.is_word_valid("ETUDE"), "...and in plain-letter tile form (accent stripped)")
	_check(dictionary.is_word_valid("etude"), "...and lowercase plain form too")

	# Entries the loader is specifically supposed to reject.
	_check(not dictionary.is_word_valid("AK-47"), "a dash-containing entry is rejected")
	_check(not dictionary.is_word_valid("1er"), "a digit-containing entry is rejected")

	# Not a word at all.
	_check(not dictionary.is_word_valid("QSXWZY"), "gibberish is not a valid word")
	_check(not dictionary.is_word_valid(""), "the empty string is not a valid word")

	# The word list the game reads must be what the tool builds from the
	# Hunspell file today (see tools/build_word_list.gd).
	var fresh := FrenchDictionary.words_from_hunspell(FrenchDictionary.HUNSPELL_PATH)
	var shipped := FileAccess.get_file_as_string(FrenchDictionary.WORD_LIST_PATH)
	_check(
		shipped == "\n".join(fresh) + "\n",
		"fr-words.txt is up to date (else run tools/build_word_list.gd)"
	)

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)
