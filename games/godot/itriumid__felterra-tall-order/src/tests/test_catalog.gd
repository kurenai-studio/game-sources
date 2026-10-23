extends TestCase
## The catalog (docs/catalog.md) is the list to brainstorm on, so it has to be right about what's
## built: every row marked Built is in the game, and everything in the game has a Built row.

const CATALOG := "res://docs/catalog.md"
## What the catalog calls each kind of enemy in the code.
const CREATURE_NAMES := {"rat": "Rat", "dog": "Guard dog", "rat_baron": "Rat Baron"}
const GIANT_NAMES := {"worker": "Worker", "chainsaw": "Chainsaw worker", "handler": "Handler"}
const MACHINE_NAMES := {
	"feller_buncher": "Feller buncher", "log_loader": "Log loader", "logging_truck": "Logging truck",
	"bulldozer": "Bulldozer", "helicopter": "Helicopter",
}
## The village's buildings by kind, as the catalog names them.
const BUILDING_NAMES := {"home": "Home", "longhouse": "Longhouse", "smithy": "Smithy", "hut": "Huts", "board": "Map board", "watchtower": "Watchtower", "market": "Market", "healer": "Healer's hut"}


## Each row's name, by its status: {"Built": [names], "Planned": [...], ...}.
func _rows() -> Dictionary:
	var rows := {}
	var text := FileAccess.get_file_as_string(CATALOG)
	for line in text.split("\n"):
		if not line.begins_with("| **"):
			continue
		var cells := line.split("|")
		var row_name := cells[1].strip_edges().trim_prefix("**").trim_suffix("**")
		var status := cells[2].strip_edges()
		if not rows.has(status):
			rows[status] = []
		rows[status].append(row_name)
	return rows


## Everything the code has, by the name the catalog gives it.
func _in_the_game() -> Array[String]:
	var names: Array[String] = []
	for kind: String in Creature.KINDS:
		names.append(CREATURE_NAMES.get(kind, "(creature %s)" % kind))
	for kind: String in Giant.KINDS:
		names.append(GIANT_NAMES.get(kind, "(giant %s)" % kind))
	for kind in Machine.KINDS:
		names.append(MACHINE_NAMES.get(kind, "(machine %s)" % kind))
	for weapon: String in Upgrades.WEAPON_NAMES:
		names.append(Upgrades.WEAPON_NAMES[weapon])
	for gear: String in Upgrades.GEAR:
		names.append(Upgrades.GEAR[gear].name)
	for support: String in Upgrades.SUPPORT:
		names.append(Upgrades.SUPPORT[support].name)
	for mutation: String in Upgrades.MUTATIONS:
		names.append(Upgrades.MUTATIONS[mutation].name)
	var kinds := {}
	for building in VillageMap.new().buildings:
		kinds[building.kind] = true
	for kind: String in kinds:
		names.append(BUILDING_NAMES.get(kind, "(building %s)" % kind))
	for area in Areas.LIST:
		names.append(area.name)
	names.append("Endless")
	for look: String in Village.LOOKS:
		names.append(Village.LOOKS[look].name)
	for stat: String in Upgrades.STATS:
		names.append(Upgrades.STATS[stat].name)
	return names


func test_every_row_has_a_known_status() -> void:
	for status: String in _rows():
		check(status in ["Built", "Planned", "Idea"], "%s has the status %s" % [str(_rows()[status]), status])


func test_everything_in_the_game_is_marked_built() -> void:
	var built: Array = _rows().get("Built", [])
	for name in _in_the_game():
		check(name in built, "%s is in the game, but the catalog doesn't say it's built" % name)


func test_everything_marked_built_is_in_the_game() -> void:
	var in_the_game := _in_the_game()
	for name: String in _rows().get("Built", []):
		check(name in in_the_game, "the catalog says %s is built, but it isn't in the game" % name)


func test_no_name_is_listed_twice() -> void:
	var seen := {}
	for status: String in _rows():
		for name: String in _rows()[status]:
			check(not seen.has(name), "%s is listed twice" % name)
			seen[name] = true
