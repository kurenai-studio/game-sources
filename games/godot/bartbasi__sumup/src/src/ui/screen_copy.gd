extends RefCounted
## Every word the screens and panels show (DESIGN_SYSTEM.md section 7 and
## 7.10). Screens case it with the skin's type role rule when they show it
## (see ui_parts.gd). Booster names come from the design's UiCopy, so the bar
## and the screens always agree.

const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")

const WORDMARK: String = "SumUp"
const NEW_GAME: String = "New game"
const SETTINGS: String = "Settings"
const BEST_SCORE: String = "Best score"
const BEST_TILE: String = "Best tile"
const RUN_HIGHEST: String = "This run's highest tile"
const SCORE: String = "Score"

const PAUSED: String = "Paused"
const RESUME: String = "Resume"

const CONFIRM_TITLE: String = "Start a new game?"
const CONFIRM_BODY: String = "This run ends here. Its score already counts in your records."
const CANCEL: String = "Cancel"

const OUT_OF_MOVES: String = "Out of moves"
const OFFER_BODY: String = "Pick a booster to keep this run going."
const OFFER_NO_RESCUE: String = "No rescue left. Pick a booster or end the run."
const END_RUN: String = "End run"

const RUN_OVER: String = "Run over"
## GDD 12.2 step 3: the run ended at once because nothing was usable (QA4-01).
const NO_MOVES_LEFT: String = "No moves left."
## 2026-10-14: the end of run screen's button to the splash (was "Main menu").
const HOME: String = "Home"
const NEW_BEST: String = "New best"

const SOUND: String = "Sound"
const SKIN: String = "Skin"

## 2026-10-13 and 2026-10-14 additions (DESIGN_SYSTEM.md 7.10).
const PLAY: String = "Play"
const INFO: String = "Info"
const ABOUT: String = "About"
## About's source code line (7.13): plain text, not a link, never cased.
const SOURCE_CODE: String = "Source code: github.com/bartbasi/sumup"
## The one address the Buy me a coffee buttons hand to the system (GDD 15.5).
## Written once, never built from anything, never shown on screen.
const COFFEE_URL: String = "https://buymeacoffee.com/playinc"
## The Buy me a coffee button (DESIGN_SYSTEM.md 7.2): body role, as written.
const COFFEE: String = "Buy me a coffee"
## The play screen button's stacked form in the side gutter (7.10, 7.15): two
## lines, body role, as written.
const COFFEE_TOP: String = "Buy me"
const COFFEE_BOTTOM: String = "a coffee"
const VERSION: String = "Version %s"
const MADE_BY: String = "Made by Bart Basi"
## A license term (NOTICE, term 1): shown exactly, never cased.
const COPYRIGHT: String = "Copyright 2026 Play, Inc."
const ABOUT_SECTIONS: Array[Dictionary] = [
	{"title": "What it is", "text": "SumUp is a number merge puzzle. Join touching tiles of the same number into bigger ones and see how high you can go."},
	{"title": "Offline, no data", "text": "SumUp works fully offline. It collects no data, has no ads or accounts and asks for no permissions. The Buy me a coffee button only opens a web page in your phone's browser, and the game itself sends nothing."},
	{"title": "Supporting SumUp", "text": "SumUp is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated.", "coffee": true},
	{"title": "Licenses", "text": "SumUp is free software: you can share and change it under the GNU General Public License, version 3, with additional terms (see the SumUp license below). Any work based on SumUp keeps its attribution, and changed versions are marked as changed. SumUp comes with no warranty."},
]
## The license rows, in order: id, title, detail line.
const LICENSE_ROWS: Array[Dictionary] = [
	{"id": &"game", "title": "SumUp", "detail": "GNU GPL version 3, added terms"},
	{"id": &"godot", "title": "Godot Engine", "detail": "MIT license and its parts"},
	{"id": &"outfit", "title": "Outfit font", "detail": "SIL Open Font License 1.1"},
]
const LICENSE_TITLES: Dictionary[StringName, String] = {
	&"game": "SumUp license",
	&"godot": "Godot Engine",
	&"outfit": "Outfit font",
}
const NOTICE_HEADING: String = "Notice"
const GPL_HEADING: String = "GNU General Public License"
const GODOT_LICENSE_HEADING: String = "Godot Engine license"
const GODOT_PARTS_HEADING: String = "Third party parts"
const GODOT_TEXTS_HEADING: String = "License texts"
## What the Android build adds on top of the engine's own parts, which
## Engine.get_copyright_info() does not list (checked against the APK on
## 2026-10-23). Each license text is under "License texts".
const ANDROID_HEADING: String = "Android libraries"
const ANDROID_INTRO: String = "The Android version of SumUp also includes these libraries, which the Godot Engine's Android build adds."
const ANDROID_PARTS: Array[Dictionary] = [
	{"name": "AndroidX libraries", "copyright": "The Android Open Source Project", "license": "Apache-2.0"},
	{"name": "Kotlin standard library", "copyright": "JetBrains s.r.o. and Kotlin Programming Language contributors", "license": "Apache-2.0"},
	{"name": "kotlinx.coroutines", "copyright": "JetBrains s.r.o. and contributors", "license": "Apache-2.0"},
	{"name": "JetBrains Java Annotations", "copyright": "JetBrains s.r.o.", "license": "Apache-2.0"},
	{"name": "LLVM libc++", "copyright": "The LLVM Project contributors", "license": "Apache-2.0 WITH LLVM-exception"},
]
const PART_COPYRIGHT: String = "Copyright %s"
const PART_LICENSE: String = "License: %s"
## Shown in a license view instead of a text that is missing or damaged in
## this copy of the game.
const TEXT_MISSING: String = "This text could not be read in this copy of SumUp. Installing the game again should bring it back."

const HINTS: Dictionary[StringName, String] = {
	&"hammer": "Tap a tile to smash it",
	&"swap": "Tap two tiles to swap them",
	&"double": "Tap a tile to double it",
}
const SWAP_SECOND: String = "Now tap the tile to swap with"


## The suggested buy button: "Shuffle for 4K". cost is the price's exponent
## and uses the tile label format (D-32), whose letters are never cased.
## While a free booster is held: "Shuffle for free" (D-46).
static func buy(booster_id: StringName, cost: int, free: bool = false) -> String:
	if free:
		return "%s for free" % booster_name(booster_id)
	return "%s for %s" % [booster_name(booster_id), NumberFormat.tile_label(cost)]


## GDD 21.2, IN1 to IN17, word for word (TH21). Each section: {"title":
## String, "text": String, "example": PackedInt64Array (the joined tiles in
## drag order, or the one tile a booster changes; empty for none), "result":
## int (the result tile, 0 for none), "row": &"chain", &"change" or &"" for
## none, "icon": the booster icon name for IN9 to IN13, &"" for none}.
## Tiles are exponents (docs/ARCHITECTURE.md section 17): the GDD's 2, 2, 4
## and 8 are 1, 1, 2 and 3 here.
static func info_sections() -> Array[Dictionary]:
	return [
		_section("Make a chain", "Slide across touching tiles, diagonals too, starting with two equal ones. Each next tile must match the last one or double it. A tile that does not fit simply does not join.", [1, 1, 2], 3),
		_section("Merge", "Lift your finger to merge, or lift on one tile to cancel. The tiles add up and round down to a tile number, so 2, 2, 2 makes 4. The new tile lands where your chain ended.", [1, 1, 1], 2),
		_section("While you drag", "While you drag, you see the tile your chain will make, and the tiles that can join next are highlighted. Slide back onto the previous tile to drop the last one."),
		_section("Points", "A chain scores the sum of its tiles, so 2, 2, 2 scores 6 although it makes 4. Only chains score. Your score never drops below zero."),
		_section("New tiles", "Tiles above fall into the gaps, and new tiles drop in from the top. New tiles are 2 to 16 at first and move up as your highest tile grows."),
		_section("Moving up", "When your highest tile reaches 2K (2048), and each time it doubles after that, the smallest number stops dropping in and its tiles clear from the board. Cleared tiles score no points.", [10, 10], 11),
		_section("Stars", "Each number that stops dropping in earns a star, once per run. Every 3 stars give you a free booster: the next booster you use costs nothing. Stars and free boosters end with the run."),
		_section("Boosters", "Boosters are paid from your score and never add points. Prices follow your highest tile, and a booster you can't afford is switched off. To cancel before you tap a tile, tap the booster again: nothing is charged."),
		_section("Hammer", "Tap Hammer, then a tile to smash it. The tiles above fall and a new tile drops in.", [], 0, &"hammer"),
		_section("Swap", "Tap Swap, then two tiles anywhere on the board, and they trade places. The two must be different numbers.", [], 0, &"swap"),
		_section("Shuffle", "Tap Shuffle to mix the same tiles into new places. You always get at least one move.", [], 0, &"shuffle"),
		_section("Double", "Tap Double, then a tile to double it, so 8 becomes 16. It costs twice as much as Hammer.", [3], 4, &"double"),
		_section("Undo", "Undo takes back your last chain and its points, and any booster used since. It goes back one step only, and what you paid stays paid. Your score without that chain's points must cover its price.", [], 0, &"undo"),
		_section("Out of moves", "When no two touching tiles match, play stops and you can pick any booster you can afford, with one marked as suggested. Or tap End run. If you can't afford any, the run ends."),
		_section("Records", "Best score and Best tile are kept across runs, and spending never lowers them. When a run ends you see its score, its highest tile and New best if you beat your Best score."),
		_section("Saving and settings", "Your run saves after every move, and Play takes you back to it. New game in Pause starts over. Pick a skin and turn sound on or off in Settings."),
		_section("Big numbers", "Big tiles are shortened: 2048 shows as 2K, then come M, B, T and Q. After Q, labels go on with letters: aa, ab and so on. More letters means a bigger number."),
	]


## A row with one tile before the arrow is a change row (DESIGN_SYSTEM.md
## 7.12); with more it is a chain row.
static func _section(title: String, text: String, example: Array[int] = [], result: int = 0, icon: StringName = &"") -> Dictionary:
	var row: StringName = &""
	if example.size() == 1:
		row = &"change"
	elif example.size() > 1:
		row = &"chain"
	return {"title": title, "text": text, "example": PackedInt64Array(example), "result": result, "row": row, "icon": icon}


## "Version 0.1" for About, or "" when the project sets no version (the line
## is then left out, DESIGN_SYSTEM.md 7.10).
static func version_text() -> String:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	return "" if version.is_empty() else VERSION % version


static func booster_name(booster_id: StringName) -> String:
	return UiCopy.BOOSTER_NAMES.get(booster_id, String(booster_id))


## The targeting hint for the booster (7.10), or "" for none. Swap reads
## differently once its first tile is chosen.
static func hint(booster_id: StringName, swap_chosen: bool) -> String:
	if booster_id == &"swap" and swap_chosen:
		return SWAP_SECOND
	return HINTS.get(booster_id, "")


## Slate's context row in targeting: "Hammer: Tap a tile to smash it", which
## its label role sets in capitals (DESIGN_SYSTEM.md 5.7).
static func targeting_context(booster_id: StringName, swap_chosen: bool) -> String:
	var text: String = hint(booster_id, swap_chosen)
	if text.is_empty():
		return ""
	return "%s: %s" % [booster_name(booster_id), text]


## Slate's context row while dragging: "Chain 6" (DESIGN_SYSTEM.md 5.7).
static func chain(count: int) -> String:
	return "Chain %d" % count


## The settings version line: the project name and, when the project sets
## one, its version.
static func version_line() -> String:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	return WORDMARK if version.is_empty() else "%s %s" % [WORDMARK, version]
