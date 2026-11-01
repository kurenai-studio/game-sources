extends RefCounted
## Registry of the three Phase 1 design directions and their four screens.
## The contrast checker and the capture tool read the list from here.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

const ROOT: String = "res://tools/directions"
## Direction ids, also their folder names, in presentation order.
const IDS: PackedStringArray = ["gumdrop", "slate", "nova"]
## The four screens every direction shows.
const SCREENS: PackedStringArray = ["board", "targeting", "gameover", "settings"]


## Path of a direction's token script.
static func tokens_path(direction_id: String) -> String:
	return "%s/%s/tokens.gd" % [ROOT, direction_id]


## A fresh token object for a direction, or null if its script is missing.
static func load_tokens(direction_id: String) -> DirectionTokens:
	var path: String = tokens_path(direction_id)
	if not ResourceLoader.exists(path):
		push_error("no tokens for direction '%s' at %s" % [direction_id, path])
		return null
	var script: GDScript = load(path) as GDScript
	if script == null:
		push_error("could not load %s" % path)
		return null
	return script.new() as DirectionTokens


## Path of one composed screen scene.
static func screen_path(direction_id: String, screen: String) -> String:
	return "%s/%s/screens/%s.tscn" % [ROOT, direction_id, screen]
