# Rebuilds data/dictionaries/fr-words.txt, the word list the game reads
# (see french_dictionary.gd), from the Hunspell file — to run again
# whenever that file changes:
#   godot4 --headless --path . --script tools/build_word_list.gd
# tests/test_french_dictionary.gd fails while the list is out of date.
extends SceneTree


func _initialize() -> void:
	var words := FrenchDictionary.words_from_hunspell(FrenchDictionary.HUNSPELL_PATH)
	# "res://" is the project folder: writable when run from the source
	# tree like this (never from an exported game).
	var file := FileAccess.open(FrenchDictionary.WORD_LIST_PATH, FileAccess.WRITE)
	if file == null:
		print("Could not write ", FrenchDictionary.WORD_LIST_PATH)
		quit(1)
		return
	# One word per line, ending with a newline like any text file.
	file.store_string("\n".join(words) + "\n")
	print("Wrote ", words.size(), " words to ", FrenchDictionary.WORD_LIST_PATH)
	quit()
