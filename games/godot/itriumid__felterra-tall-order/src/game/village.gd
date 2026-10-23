class_name Village
extends RefCounted
## The cats' village at the forest's edge, and everything that carries over between runs: the
## cats rescued, by name and coat; the salvage and the cloth; the buildings restored from ruin;
## what the smith has forged; and the looks bought. Kept in the player's data folder beside the
## settings and the best run.
##
## The village comes back as the story goes: nothing is restored with salvage. His own home is a
## ruin like the rest until the first cat he rescues fixes it up, as a thank-you; every other
## building comes back with an area freed. Each opens what it holds: his home is where he packs,
## the smithy forges, the Elder at the longhouse lets a run start with anything forged and keeps the
## book of stories, and every hut houses two cats, who weave cloth while he's away. The first hut
## is the weaver's, and sells looks for cloth.
##
## A run starts with what any village has lying about: six weapons and five pieces of gear are all
## the cards can offer at first. Forging puts more weapons, gear and support into them, and freeing
## an area teaches him its dodge mutations. Anything had can be packed or left home, so the cards offer
## only what he wants; a forged piece of gear can be worn from a run's start. Unlocks, never stats
## on their own: runs grow wider, not easier.

const PATH := "user://village.cfg"

## What brings each building back from ruin: "rescue" for the first cat rescued, the area whose
## freeing brings home the cat whose trade it is, or for a hut, so many cats rescued, who build it
## themselves.
const RESTORED_BY := {
	"home": "rescue", "smithy": "edge", "hut_0": "deep", "longhouse": "sawpits",
	"watchtower": "clearing", "market": "slide", "healer": "offices",
	"hut_1": 3, "hut_2": 5, "hut_3": 7, "hut_4": 9,
}
## What's told as he walks home to a building just restored, by name; "%s" in his home's line is
## the cat who fixed it.
const RESTORED_LINES := {
	"home": ["Your roof doesn't leak anymore. %s fixed it while you were out.", "A thank-you, for getting them out."],
	"smithy": ["Pak Besi has his hammer back, and the company's tools from the edge.", "The old smithy has its fire again."],
	"hut_0": ["Nenek Pus has moved into the hut by the path, and set up her loom."],
	"longhouse": ["Si Belang was a carpenter before the sawpits. He starts on the longhouse the day he's home.", "It's big enough to hold everyone. After the sawpits, everyone wants to talk at once."],
	"watchtower": ["Jingga has built herself a tower by the gate, the way she likes it: tall, and a bit wobbly."],
	"market": ["Kopi and Susu have their stall back. They're already arguing over the prices."],
	"healer": ["Bu Jamu has her pots out, and the whole village smells of turmeric."],
	"hut_1": ["The cats you've rescued have built themselves a hut."],
	"hut_2": ["Another hut stands again, with room for two more."],
	"hut_3": ["Another hut stands again, built from the company's own planks."],
	"hut_4": ["The last hut stands again. The village is whole."],
}
## What each building does, in full, for what's new as he walks home to it.
const EXPLAINS := {
	"home": "Your pack: choose what your cards can offer, and a piece of gear to wear from the start.",
	"smithy": "Forge weapons, gear and support with salvage. Once forged, they turn up on your cards.",
	"hut_0": "The weaver sells new looks for cloth. Cats housed in huts weave cloth while you're away.",
	"longhouse": "Start a run with any weapon you've forged, and read the story so far in the book.",
	"watchtower": "Jingga watches the forest: on the map board, each area found shows its boss, and how to beat it.",
	"market": "Trade salvage for cloth, or cloth for salvage, at Kopi and Susu's prices.",
	"healer": "Bu Jamu brews a tonic for salvage: the next run starts with two more rerolls.",
	"hut_1": "Room for two more cats, weaving cloth while you're away.",
	"hut_2": "Room for two more cats, weaving cloth while you're away.",
	"hut_3": "Room for two more cats, weaving cloth while you're away.",
	"hut_4": "Room for two more cats, weaving cloth while you're away.",
}
## What each building opens, in a line, for its prompt.
const OPENS := {
	"home": "pack what you take on a run",
	"smithy": "the smith forges",
	"longhouse": "start a run with anything forged, and read the story so far",
	"hut_0": "the weaver sells looks for cloth",
	"watchtower": "the map shows each boss, and how to beat it",
	"market": "trade salvage and cloth",
	"healer": "a tonic for the next run",
}
## The market's prices, as {give, get}: salvage for cloth, and cloth for salvage. And the healer's
## tonic: what it costs, and the rerolls it starts the next run with.
const TRADES := {"cloth": {"salvage": 3, "cloth": 1}, "salvage": {"cloth": 1, "salvage": 2}}
const TONIC_COST := 6
## What Jogiboy has dug up for Tompel each time he walks home: he's the village's finder.
const JOGIBOY_FINDS := 2
const TONIC_REROLLS := 2
## How many caged cats Jogiboy can smell out in an area: its cages to free, and as many more as
## the company keeps there at once.
static func caged_in(area_id: String) -> int:
	var area := Areas.named(area_id)
	var count: int = (area.goal.at as Array).size() if area.goal.kind == "cages" else 0
	return count + int(area.plan.get("cages", {}).get("most", 0))


## Cats a restored hut houses, each weaving a cloth a run.
const CATS_PER_HUT := 2
## What's in the cards from the start, things any village has lying about: as many weapons as must
## stay packed, and five pieces of gear, so even the first run's cards are a draw. The nunchaku and
## the handgun are what a run starts with, and are always packed.
const STARTING: Array[String] = [
	"weapon:nunchaku", "weapon:handgun", "weapon:knife", "weapon:ketapel", "weapon:golok",
	"weapon:rattan_staff",
	"gear:caping", "gear:scarf", "gear:boots", "gear:sarong", "gear:gloves",
]
const ALWAYS_PACKED: Array[String] = ["weapon:nunchaku", "weapon:handgun"]
## How many of each kind must stay packed, for every place a run has for one: leaving things home
## narrows the cards, but never so far that they stop being a draw.
const KEEP_PACKED_PER_PLACE := 3
## What can be forged, by card id, and its salvage: every other weapon, the rest of the gear, and
## all the support. What a family grows into needs no forging: a forged rifle can evolve into a sniper
## rifle. Dodge mutations aren't forged; they're taught (Areas.teaches).
const FORGE := {
	"gear:vest": 8, "gear:hard_hat": 10, "gear:bell_collar": 6, "gear:goggles": 8,
	"gear:jamu_flask": 12, "gear:peci": 8, "gear:batik_shirt": 10, "gear:raincoat": 10,
	"gear:headlamp": 9, "gear:sunglasses": 12, "gear:bandana": 8, "gear:wristbands": 10,
	"gear:rubber_boots": 9, "gear:sandals": 8, "gear:tool_belt": 11, "gear:batik_headcloth": 9,
	"gear:ear_defenders": 10, "gear:life_jacket": 12, "gear:kebaya": 11, "gear:lanyard": 9,
	"gear:prayer_beads": 10, "gear:safety_glasses": 8, "gear:gem_rings": 12, "gear:rattan_bracers": 9,
	"gear:wooden_clogs": 8, "gear:fighting_sash": 11,
	"weapon:machete": 10, "weapon:badik": 10, "weapon:rencong": 12, "weapon:celurit": 14,
	"weapon:kujang": 14, "weapon:mandau": 16, "weapon:tombak": 16, "weapon:sumpit": 14, "weapon:bambu_runcing": 10,
	"weapon:panah": 16, "weapon:petasan": 14, "weapon:lamp_oil": 15, "weapon:nail_gun": 14,
	"weapon:flare_gun": 16, "weapon:rifle": 18, "weapon:crossbow": 18, "weapon:shotgun": 20,
	"weapon:grenade_launcher": 24,
	"support:gun_drone": 20, "support:net_drone": 18, "support:layang_layang": 16,
	"support:meriam_bambu": 18, "support:mines": 15, "support:ranjau_bambu": 12, "support:radio": 14,
	"support:bee_swarm": 17, "support:alarm_drum": 15, "support:snare": 13,
}
## Looks, by id: what each is and what it costs in cloth. His coat, and the umbul-umbul's colors.
const LOOKS := {
	"coat:tompel": {"name": "Tompel's own coat", "cloth": 0},
	"coat:orange": {"name": "Orange coat", "cloth": 0},
	"coat:gray": {"name": "Gray coat", "cloth": 6},
	"coat:black": {"name": "Black coat", "cloth": 8},
	"coat:cream": {"name": "Cream coat", "cloth": 8},
	"banners:festival": {"name": "Festival banners", "cloth": 0},
	"banners:rhodonite": {"name": "Rhodonite banners", "cloth": 10},
	"banners:lagoon": {"name": "Lagoon banners", "cloth": 10},
}

var cats: Array[Dictionary] = []
var salvage := 0
var cloth := 0
## Whether the story's opening has been told: it's told once, on the first walk into the village.
var intro_seen := false
## The buildings brought back from ruin, by name.
var restored: Array[String] = []
## What the smith has forged, by card id, and the piece of gear worn from a run's start ("" none).
var forged: Array[String] = []
var starting_piece := ""
## The looks bought, by id, and the ones worn: his coat, and the banners' colors.
var looks: Array[String] = ["coat:tompel", "coat:orange", "banners:festival"]
var coat := "tompel"
var banners := "festival"
## The forest's areas freed, the cutscenes already told (as "intro:<area>" or "outro:<area>"),
## and where the next run goes: an area's id, or "endless".
var liberated: Array[String] = []
var told: Array[String] = []
var next_run := "edge"
## What he has but leaves home, by card id: the cards never offer it.
var left_home: Array[String] = []
## The areas whose goal he's done, though their boss still stands: done stays done, and the next
## run there is for the boss.
var goals_done: Array[String] = []
## A tonic from the healer's hut, brewed and waiting for the next run.
var tonic_ready := false


## Every card id for a thing he could have, in the order the smithy shows them: weapons, gear,
## support, then dodge mutations.
static func everything() -> Array[String]:
	var ids: Array[String] = []
	for weapon_name: String in Upgrades.WEAPONS:
		ids.append("weapon:" + weapon_name)
	for gear_id: String in Upgrades.GEAR:
		ids.append("gear:" + gear_id)
	for support_name: String in Upgrades.SUPPORT:
		ids.append("support:" + support_name)
	for mutation: String in Upgrades.MUTATIONS:
		ids.append("mutation:" + mutation)
	return ids


## The dodge mutations he's been taught, by card id: what the areas freed so far teach.
func learned() -> Array[String]:
	var ids: Array[String] = []
	for area_id in liberated:
		for mutation in Areas.teaches(area_id):
			ids.append("mutation:" + mutation)
	return ids


## Whether he has a thing at all: it starts with him, it's forged, or it's been taught.
func has(id: String) -> bool:
	return id in STARTING or id in forged or id in learned()


## Whether a run's cards can offer it: he has it, and hasn't left it home.
func packed(id: String) -> bool:
	return has(id) and not id in left_home


## Packs a thing he has, or leaves it home; the nunchaku and the handgun are always packed. A piece of
## gear goes round three ways: packed, then worn from the start, then left home. Nothing is left
## home that would leave fewer of its kind packed than keep_packed() (gear worn from the start goes
## back to the pack instead). Returns false if it can't change.
func repack(id: String) -> bool:
	if not has(id) or id in ALWAYS_PACKED:
		return false
	if id in left_home:
		left_home.erase(id)
	elif id.begins_with("gear:") and starting_piece != id:
		starting_piece = id
	elif not cant_leave_home(id).is_empty():
		if starting_piece != id:
			return false
		starting_piece = ""
	else:
		if starting_piece == id:
			starting_piece = ""
		left_home.append(id)
	return true


## Why a thing can't be left home ("" if it can): always packed, or too few of its kind packed.
func cant_leave_home(id: String) -> String:
	if id in ALWAYS_PACKED:
		return "it's what a run starts with"
	var kind := id.get_slice(":", 0)
	var packed_count := everything().filter(func(each: String) -> bool: return each.begins_with(kind + ":") and packed(each)).size()
	if packed_count <= keep_packed(kind):
		return "keep at least %d packed" % keep_packed(kind)
	return ""


## How many of a kind must stay packed: three for every place a run has for one, his mouth and tail for
## weapons, its seven slots for gear, one drone and one thing set down, and three mutations.
static func keep_packed(kind: String) -> int:
	return places(kind) * KEEP_PACKED_PER_PLACE


## How many of a kind a run can have on him at once.
static func places(kind: String) -> int:
	match kind:
		"weapon": return Cat.HOLDS
		"gear": return Upgrades.SLOTS.size()
		"support":
			var slots: Array = []
			for slot: String in Support.SLOTS.values():
				if not slot in slots:
					slots.append(slot)
			return slots.size()
	return Cat.MOST_MUTATIONS


## Every card id a run's cards must never offer: what he doesn't have, and what he's left home.
func locked_for_run() -> Array[String]:
	var ids: Array[String] = []
	for id in everything():
		if not packed(id):
			ids.append(id)
	return ids


## Whether an area can be chosen: the first always, then each once the one before it is free.
func found(area_id: String) -> bool:
	var index := Areas.ids().find(area_id)
	return index == 0 or (index > 0 and Areas.ids()[index - 1] in liberated)


## The first area not yet freed, or Endless once they all are.
func next_area() -> String:
	for id in Areas.ids():
		if not id in liberated:
			return id
	return "endless"


## An area freed for the first time: it's marked free, and brings the village what freeing it
## brings, its cats and its salvage. Returns false if it was free already.
func liberate(area_id: String) -> bool:
	if area_id in liberated:
		return false
	liberated.append(area_id)
	goals_done.erase(area_id)
	var area := Areas.named(area_id)
	salvage += area.bonus
	for freed: Dictionary in area.frees:
		cats.append(freed)
	if next_run == area_id:
		next_run = next_area()
	return true


## What a run brought home: its rescued cats join, its salvage goes on the pile, and the cats
## housed in the village weave while he's away.
func bring_home(arena: Arena) -> void:
	cats.append_array(arena.rescued)
	salvage += arena.salvage
	cloth += weavers()


## The cats housed in restored huts, who weave: two to a hut, no more than there are cats.
func weavers() -> int:
	var huts := restored.filter(func(name: String) -> bool: return name.begins_with("hut_")).size()
	return mini(cats.size(), huts * CATS_PER_HUT)


func is_restored(building: String) -> bool:
	return building in restored


## What brings a building back, in words, for a ruin's prompt.
static func restored_when(building: String) -> String:
	var by: Variant = RESTORED_BY[building]
	if by is int:
		return "%d cats rescued will build it" % by
	if by == "rescue":
		return "the first cat you rescue will fix it up"
	return "freeing %s brings it back" % (Areas.named(by).name as String).to_lower()


## Restores whatever the story so far has brought back, and returns what's newly restored, in the
## order the buildings stand.
func catch_up() -> Array[String]:
	var fresh: Array[String] = []
	for building in VillageMap.building_names():
		if is_restored(building):
			continue
		var by: Variant = RESTORED_BY[building]
		if (by is int and cats.size() >= by) or (by is String and ((by == "rescue" and not cats.is_empty()) or by in liberated)):
			restored.append(building)
			fresh.append(building)
	return fresh


## What's told as he walks home to buildings just restored.
func restored_lines(buildings: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	for building in buildings:
		for line: String in RESTORED_LINES[building]:
			lines.append(line % (cats[0].name if not cats.is_empty() else "A neighbor") if line.contains("%s") else line)
	return lines


## Forges an item into the cards, spending its salvage. The smithy has to be restored first.
func forge(id: String) -> bool:
	if not is_restored("smithy") or id in forged or not FORGE.has(id) or salvage < FORGE[id]:
		return false
	salvage -= FORGE[id]
	forged.append(id)
	return true


## Every card id a run may offer from: what's packed.
func pool() -> Array[String]:
	var ids: Array[String] = []
	for id in everything():
		if packed(id):
			ids.append(id)
	return ids


## A trade at the market, for cloth or for salvage, at its price. Returns false if the market isn't
## back yet, or there isn't enough to give.
func trade(for_what: String) -> bool:
	if not is_restored("market") or not TRADES.has(for_what):
		return false
	var price: Dictionary = TRADES[for_what]
	var give := "salvage" if for_what == "cloth" else "cloth"
	if get(give) < price[give]:
		return false
	set(give, get(give) - price[give])
	set(for_what, get(for_what) + price[for_what])
	return true


## A tonic brewed at the healer's hut, for the next run. One at a time.
func brew_tonic() -> bool:
	if not is_restored("healer") or tonic_ready or salvage < TONIC_COST:
		return false
	salvage -= TONIC_COST
	tonic_ready = true
	return true


## Wears a forged piece of gear from a run's start, or none (""): packed, if it was left home.
func wear_from_start(id: String) -> bool:
	if not id.is_empty() and (not id.begins_with("gear:") or not id in forged):
		return false
	starting_piece = id
	left_home.erase(id)
	return true


## Buys a look for cloth, once; the weaver's hut has to be restored first.
func buy_look(id: String) -> bool:
	if id in looks:
		return true
	if not is_restored("hut_0") or not LOOKS.has(id) or cloth < LOOKS[id].cloth:
		return false
	cloth -= LOOKS[id].cloth
	looks.append(id)
	return true


## Wears a look he owns: a coat, or the banners' colors.
func wear_look(id: String) -> bool:
	if not id in looks:
		return false
	if id.begins_with("coat:"):
		coat = id.trim_prefix("coat:")
	else:
		banners = id.trim_prefix("banners:")
	return true


## Back to the start: nobody rescued, nothing on the pile, every building in ruins.
func clear() -> void:
	cats.clear()
	salvage = 0
	cloth = 0
	intro_seen = false
	restored.clear()
	forged.clear()
	starting_piece = ""
	looks.assign(["coat:tompel", "coat:orange", "banners:festival"])
	coat = "tompel"
	banners = "festival"
	liberated.clear()
	told.clear()
	next_run = "edge"
	left_home.clear()
	goals_done.clear()
	tonic_ready = false


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	file.set_value("village", "cats", cats)
	file.set_value("village", "salvage", salvage)
	file.set_value("village", "cloth", cloth)
	file.set_value("village", "intro_seen", intro_seen)
	file.set_value("village", "restored", restored)
	file.set_value("village", "forged", forged)
	file.set_value("village", "starting_piece", starting_piece)
	file.set_value("village", "looks", looks)
	file.set_value("village", "coat", coat)
	file.set_value("village", "banners", banners)
	file.set_value("village", "liberated", liberated)
	file.set_value("village", "told", told)
	file.set_value("village", "next_run", next_run)
	file.set_value("village", "left_home", left_home)
	file.set_value("village", "goals_done", goals_done)
	file.set_value("village", "tonic_ready", tonic_ready)
	return file.save(path) == OK


func load_from(path := PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	var saved_cats: Variant = file.get_value("village", "cats", [])
	if saved_cats is Array:
		cats.clear()
		for each: Variant in saved_cats:
			if each is Dictionary and each.has("name") and each.has("coat"):
				cats.append(each)
	salvage = _count(file, "salvage")
	cloth = _count(file, "cloth")
	intro_seen = file.get_value("village", "intro_seen", false) == true
	_names(file, "restored", restored, VillageMap.building_names())
	_names(file, "forged", forged, FORGE.keys())
	_names(file, "looks", looks, LOOKS.keys())
	# A village kept before Tompel had his own coat wore orange because it had nothing else.
	var had_his_coat := "coat:tompel" in looks
	for kept: String in ["coat:tompel", "coat:orange", "banners:festival"]:
		if not kept in looks:
			looks.append(kept)
	var piece: Variant = file.get_value("village", "starting_piece", "")
	starting_piece = piece if piece is String and piece in forged else ""
	var saved_coat: Variant = file.get_value("village", "coat", "tompel")
	coat = saved_coat if saved_coat is String and "coat:" + saved_coat in looks else "tompel"
	if coat == "orange" and not had_his_coat:
		coat = "tompel"
	_names(file, "liberated", liberated, Areas.ids())
	var known_scenes: Array = []
	for id in Areas.ids():
		known_scenes.append("intro:" + id)
		known_scenes.append("outro:" + id)
		known_scenes.append("send_off:" + id)
		known_scenes.append("teach:" + id)
	_names(file, "told", told, known_scenes)
	var saved_next: Variant = file.get_value("village", "next_run", "edge")
	next_run = saved_next if saved_next is String and (saved_next == "endless" or saved_next in Areas.ids()) else next_area()
	tonic_ready = file.get_value("village", "tonic_ready", false) == true
	_names(file, "goals_done", goals_done, Areas.ids())
	for id in liberated:
		goals_done.erase(id)
	_names(file, "left_home", left_home, everything())
	left_home.erase(starting_piece)
	for always: String in ALWAYS_PACKED:
		left_home.erase(always)
	var saved_banners: Variant = file.get_value("village", "banners", "festival")
	banners = saved_banners if saved_banners is String and "banners:" + saved_banners in looks else "festival"


## A count from the file, never below none.
static func _count(file: ConfigFile, key: String) -> int:
	var saved: Variant = file.get_value("village", key, 0)
	return maxi(saved, 0) if saved is int else 0


## A list of names from the file, keeping only the ones there are.
static func _names(file: ConfigFile, key: String, into: Array[String], known: Array) -> void:
	var saved: Variant = file.get_value("village", key, [])
	if not saved is Array:
		return
	into.clear()
	for name: Variant in saved:
		if name is String and name in known and not name in into:
			into.append(name)
