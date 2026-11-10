# French dictionary word-validity check, ported from the Unity project's
# `FrenchDictionary.cs`. Wraps the "classique" Dicollecte word list
# (data/dictionaries/fr-classique.dic, MPL 2.0 — see the accompanying
# README_dict_fr.txt) as a set of normalized words, checked against
# whatever word a row currently spells (see doc/RULES.md: any dictionary
# word is legal, including all grammatical forms — the word list already
# contains every inflected form as its own line, there's no on-the-fly
# conjugation happening here).
#
# Simplified from the C# version: that one supported both a synchronous
# and an async load, but every actual caller in the Unity project passed
# `async: false` anyway, so only the synchronous path is ported here.
#
# The game doesn't read the Hunspell file itself: stripping the accents
# off its ~440,000 lines takes seconds (far more on a phone). A tool
# (tools/build_word_list.gd) does it once, writing every word, already in
# tile letters, sorted, to `WORD_LIST_PATH` — which the game just reads.
# tests/test_french_dictionary.gd checks that list is up to date.
class_name FrenchDictionary
extends RefCounted

# The Hunspell word list the game's words come from (see the header).
const HUNSPELL_PATH := "res://data/dictionaries/fr-classique.dic"
# Every valid word, in plain A-Z tile letters, one per line, sorted.
const WORD_LIST_PATH := "res://data/dictionaries/fr-words.txt"

# Every accented/ligature/superscript character that appears in the source
# word list, mapped to the plain uppercase letter(s) it should be treated
# as. The physical game tiles only ever show plain A-Z letters (see
# doc/RULES.md), so a dictionary word can only ever match a placed word
# once accents are stripped this way — same idea as the C# version's
# Unicode NFD-normalize-then-strip-combining-marks approach, just spelled
# out directly since GDScript has no built-in equivalent.
const _ACCENT_MAP := {
	"à": "A",
	"â": "A",
	"ä": "A",
	"å": "A",
	"ã": "A",
	"á": "A",
	"À": "A",
	"Â": "A",
	"Ä": "A",
	"Å": "A",
	"Ã": "A",
	"Á": "A",
	"æ": "AE",
	"Æ": "AE",
	"ç": "C",
	"ć": "C",
	"Ç": "C",
	"Ć": "C",
	"é": "E",
	"è": "E",
	"ê": "E",
	"ë": "E",
	"É": "E",
	"È": "E",
	"Ê": "E",
	"Ë": "E",
	"í": "I",
	"î": "I",
	"ï": "I",
	"Í": "I",
	"Î": "I",
	"Ï": "I",
	"ñ": "N",
	"ń": "N",
	"Ñ": "N",
	"Ń": "N",
	"ó": "O",
	"ô": "O",
	"ö": "O",
	"Ó": "O",
	"Ô": "O",
	"Ö": "O",
	"œ": "OE",
	"Œ": "OE",
	"ś": "S",
	"š": "S",
	"Ś": "S",
	"Š": "S",
	"ù": "U",
	"û": "U",
	"ü": "U",
	"Ù": "U",
	"Û": "U",
	"Ü": "U",
	"ÿ": "Y",
	"Ÿ": "Y",
	# Superscript/subscript letters (used in footnote-style ordinal
	# abbreviations like "1ᵉʳ") that the C# version also replaced one by
	# one rather than via general Unicode normalization.
	"ᵃ": "A",
	"ᵇ": "B",
	"ᶜ": "C",
	"ᵈ": "D",
	"ᵉ": "E",
	"ᶠ": "F",
	"ᵍ": "G",
	"ʰ": "H",
	"ⁱ": "I",
	"ʲ": "J",
	"ᵏ": "K",
	"ˡ": "L",
	"ᵐ": "M",
	"ⁿ": "N",
	"ᵒ": "O",
	"ᵖ": "P",
	"ʳ": "R",
	"ˢ": "S",
	"ᵗ": "T",
	"ᵘ": "U",
	"ᵛ": "V",
	"ʷ": "W",
	"ˣ": "X",
	"ʸ": "Y",
	"ᶻ": "Z",
	"ₐ": "A",
	"ₑ": "E",
	"ₕ": "H",
	"ᵢ": "I",
	"ⱼ": "J",
	"ₖ": "K",
	"ₗ": "L",
	"ₘ": "M",
	"ₙ": "N",
	"ₒ": "O",
	"ₚ": "P",
	"ᵣ": "R",
	"ₛ": "S",
	"ₜ": "T",
	"ᵤ": "U",
	"ᵥ": "V",
	"ₓ": "X",
}

# Every valid word, sorted (see the header). A PackedStringArray is a
# compact array of strings, like a C++ `std::vector<std::string>`; being
# sorted, it can be searched by halves (`bsearch`, a binary search, like
# C++'s `std::lower_bound`) — no need to build a hash set of 420,000
# words first, which is what made loading slow.
var _words: PackedStringArray


func _init() -> void:
	var file := FileAccess.open(WORD_LIST_PATH, FileAccess.READ)
	if file == null:
		push_error("FrenchDictionary: could not open %s" % WORD_LIST_PATH)
		return
	# One call reading the whole file and one splitting it: both run in
	# Godot's own C++, in milliseconds. `false`: no empty entries.
	_words = file.get_as_text().split("\n", false)


# Whether `word` is valid, case- and accent-insensitively — matching
# however the game's plain-letter tiles actually spell it out.
func is_word_valid(word: String) -> bool:
	var normalized := normalize(word)
	# Where `normalized` is, or would be inserted to keep the list sorted.
	var index := _words.bsearch(normalized)
	return index < _words.size() and _words[index] == normalized


# How many words loaded — mainly useful for sanity-checking the load
# itself (tests, or a debug screen), not needed for gameplay.
func word_count() -> int:
	return _words.size()


# Every word of the Hunspell file at `path`, in tile letters, sorted,
# each once — what `WORD_LIST_PATH` holds. Slow (seconds): only for
# tools/build_word_list.gd and the test checking its output is current.
static func words_from_hunspell(path: String) -> PackedStringArray:
	# Used as a set, to keep each word once: only the keys matter.
	var words := {}
	var file := FileAccess.open(path, FileAccess.READ)
	for line in file.get_as_text().split("\n"):
		var word := _word_from_line(line)
		if word != "":
			words[word] = true
	var sorted := PackedStringArray(words.keys())
	sorted.sort()
	return sorted


# Parses one raw Hunspell .dic line (e.g. "1er/23\t154" or "abaisser/12")
# and returns the resulting word, or "" if it should be skipped.
# Mirrors `FrenchDictionary.cs`'s `LoadDictionary` exactly, including how
# the file's leading word-count line and any comment line end up
# harmlessly filtered out on their own (see the digit check below): split
# on '/' then '\t' then ' ' to isolate the bare word, normalize it, then
# reject anything left containing a dash or a digit.
static func _word_from_line(line: String) -> String:
	if line.strip_edges() == "" or line.begins_with("#"):
		return ""
	var word := line.split("/")[0].split("\t")[0].split(" ")[0]
	var normalized := normalize(word)
	if normalized.contains("-") or _contains_digit(normalized):
		return ""
	return normalized


# Walks `word` ONE CHARACTER AT A TIME, replacing each one that's a key in
# `_ACCENT_MAP` — deliberately not the 80-odd sequential `.replace()` calls
# this used to do (once per _ACCENT_MAP entry, on every word): each
# `.replace()` re-scans the whole string looking for that one substring,
# so doing 80 of them costs roughly 80x a single pass, and this function
# runs once per line of a dictionary that's now ~440,000 lines long (see
# `words_from_hunspell`). `static`: it needs no loaded word list.
static func normalize(word: String) -> String:
	var normalized := ""
	for i in range(word.length()):
		var character := word[i]
		normalized += _ACCENT_MAP[character] if _ACCENT_MAP.has(character) else character
	return normalized.to_upper()


static func _contains_digit(text: String) -> bool:
	for i in range(text.length()):
		if text[i] in "0123456789":
			return true
	return false
