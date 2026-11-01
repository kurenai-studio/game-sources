# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name StarText
extends RefCounted
## The three star rules of a level as plain sentences (RULES 10, docs/ARCHITECTURE.md
## 2.7). The sentences are built from the level's star3 data, its number and the
## Catalog, so a tower's name is never written here.

const BIT_WIN: int = 1
const BIT_LIVES: int = 2
const BIT_CHALLENGE: int = 4
const STATE_EARNED: String = "Earned"
const STATE_NOT_YET: String = "Not yet"
const STATE_LOST: String = "Lost"
const STATE_NORMAL_ONLY: String = "Normal only"


static func win() -> String:
	return "Win the level."


## "Keep 15 lives." The number is rules.json star2_lives.
static func lives(catalog: Catalog) -> String:
	return "Keep %d lives." % catalog.rules.star2_lives


## The level's own challenge, from its kind, its number and the tower's plural.
static func challenge(level: LevelData, catalog: Catalog) -> String:
	var kind: StringName = level.star3.get("kind", &"")
	var value: int = int(level.star3.get("value", 0))
	match kind:
		&"no_lives_lost":
			return "Lose no lives."
		&"towers_at_most":
			return "Have at most %d %s." % [value, _plural(value, "tower", "towers")]
		&"tower_ban":
			var type: TowerType = catalog.tower(level.star3.get("tower", &""))
			return "Build no %s." % (type.plural if type != null else "towers of that kind")
		&"gates_at_most":
			if value == 0:
				return "Use no gates."
			return "Use at most %d %s." % [value, _plural(value, "gate", "gates")]
		&"tier_at_most":
			# A cap of tier 1 reads "Upgrade no towers.": the player has not met tiers yet
			# on the first levels (FUN_REVIEW_R1 item 4).
			if value <= 1:
				return "Upgrade no towers."
			return "No tower above tier %d." % value
		&"early_calls_at_least":
			return "Call %d %s early." % [value, _plural(value, "wave", "waves")]
		&"kinds_at_most":
			return "Use at most %d %s of tower." % [value, _plural(value, "kind", "kinds")]
		&"gates_whole":
			return "Use every gate and keep them whole."
	return ""


## The three lines, star 1 to star 3.
static func lines(level: LevelData, catalog: Catalog) -> PackedStringArray:
	return PackedStringArray([win(), lives(catalog), challenge(level, catalog)])


## The star lines of the Pause menu (RULES 10.6): the sentence, one word for where it stands
## and whether the line is struck through. `earned` and `possible` are star bits. "Earned"
## when the player has the star, "Normal only" for stars 2 and 3 on Relaxed, "Not yet" while
## `possible` still holds it, else "Lost" (struck through, so color is never the only signal).
static func play_lines(level: LevelData, catalog: Catalog, earned: int, possible: int, relaxed: bool) -> Array[Dictionary]:
	var sentences: PackedStringArray = lines(level, catalog)
	var out: Array[Dictionary] = []
	for i: int in 3:
		var state: String
		var struck: bool = false
		var got: bool = (earned >> i) & 1 == 1
		if got:
			state = STATE_EARNED
		elif relaxed and i > 0:
			state = STATE_NORMAL_ONLY
		elif (possible >> i) & 1 == 1:
			state = STATE_NOT_YET
		else:
			state = STATE_LOST
			struck = true
		out.append({"text": sentences[i], "state": state, "struck": struck, "earned": got})
	return out


## How many stars a bit mask holds.
static func count(bits: int) -> int:
	return (bits & BIT_WIN) + ((bits >> 1) & 1) + ((bits >> 2) & 1)


static func _plural(value: int, one: String, many: String) -> String:
	return one if value == 1 else many
