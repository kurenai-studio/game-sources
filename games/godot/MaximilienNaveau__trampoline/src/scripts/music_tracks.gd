# Which tune plays where: one per mode, and one per crossword (all made by
# tools/audio/make_music.py, see tools/audio/README.md). main.gd only asks
# for the tune of the mode it starts.
# A `class_name` script holding only constants and static functions is
# used like a Python module: `MusicTracks.MULTIPLAYER`,
# `MusicTracks.free_play(2)`, no instance needed.
class_name MusicTracks
extends RefCounted

# `preload` loads a file once, as soon as this script is (like an import
# at the top of a Python module): these two are always ready to play.
const MULTIPLAYER := preload("res://assets/audio/music/multi_le_bouquiniste.ogg")
const FREE_PLAY := preload("res://assets/audio/music/libre_flanerie.ogg")
# One tune per crossword, in puzzle order (crossword `puzzle_index + 1`
# plays `_CROSSWORDS[puzzle_index]`). Paths, not `preload`s: `load()` reads
# a tune only when its crossword starts, where `preload` would keep all
# ten in memory the whole time.
const _CROSSWORDS := [
	"res://assets/audio/music/croise_01_les_definitions.ogg",
	"res://assets/audio/music/croise_02_case_blanche.ogg",
	"res://assets/audio/music/croise_03_horizontalement.ogg",
	"res://assets/audio/music/croise_04_verticalement.ogg",
	"res://assets/audio/music/croise_05_l_encrier.ogg",
	"res://assets/audio/music/croise_06_le_crayon.ogg",
	"res://assets/audio/music/croise_07_la_gomme.ogg",
	"res://assets/audio/music/croise_08_mot_de_passe.ogg",
	"res://assets/audio/music/croise_09_le_dictionnaire.ogg",
	"res://assets/audio/music/croise_10_le_point_final.ogg",
]


# The tune for free play solving crossword `puzzle_index` (-1: no
# crossword, plain free play). `static`: called on the class itself, like
# a Python @staticmethod.
static func free_play(puzzle_index: int) -> AudioStream:
	return load(_CROSSWORDS[puzzle_index]) if puzzle_index >= 0 else FREE_PLAY
