extends TestCase
## Restoring the village: the story brings each ruin back, and it opens what it holds; the
## smith forges weapons, gear and support into the cards a run can offer, and a forged piece can be worn
## from a run's start; housed cats weave cloth; the weaver sells looks for it.


func _village(cats: int, salvage: int) -> Village:
	var village := Village.new()
	for index in cats:
		village.cats.append({"name": Cage.NAMES[index % Cage.NAMES.size()], "coat": "gray"})
	village.salvage = salvage
	return village


func test_the_story_brings_the_village_back() -> void:
	var village := _village(0, 100)
	check(village.catch_up().is_empty() and village.restored.is_empty(), "something came back before the story began")
	village.liberate("edge")
	check(village.catch_up() == ["home", "smithy"], "freeing the edge brought back %s, not his home and the smithy" % str(village.restored))
	check(village.salvage == 100 + Areas.named("edge").bonus, "bringing a building back cost salvage")
	check(village.catch_up().is_empty(), "something came back twice")
	check(village.restored_lines(["home"])[0].contains("Pak Besi"), "his home's story doesn't name who fixed it")
	for index in 2:
		village.cats.append({"name": "Tes", "coat": "gray"})
	check(village.catch_up() == ["hut_1"], "three cats rescued didn't build a hut")


func test_every_building_comes_back_with_the_story() -> void:
	for building in VillageMap.building_names():
		check(Village.RESTORED_BY.has(building), "nothing brings %s back" % building)
		var by: Variant = Village.RESTORED_BY.get(building, "")
		check(by is int or by == "rescue" or by in Areas.ids(), "%s comes back with %s, which isn't anything" % [building, by])
		check(not (Village.RESTORED_LINES.get(building, []) as Array).is_empty(), "nothing's told when %s comes back" % building)
		for line: String in Village.RESTORED_LINES.get(building, []):
			check(PixelFont.width(line) <= 640 - 16, "too wide for the screen: %s" % line)
	var village := _village(10, 0)
	for id in Areas.ids():
		village.liberate(id)
	village.catch_up()
	check(village.restored.size() == VillageMap.building_names().size(), "with the forest free, only %s stood" % str(village.restored))


func test_the_smith_forges_into_the_cards() -> void:
	var village := _village(1, 100)
	check(not village.forge("gear:vest"), "a vest was forged with the smithy in ruins")
	village.restored.append("smithy")
	check(village.forge("gear:vest") and "gear:vest" in village.pool(), "the vest didn't go into the cards")
	check(not village.forge("gear:vest"), "the vest was forged twice")
	check(not village.forge("weapon:knife"), "something he starts with was forged")


func test_what_isnt_forged_is_never_offered() -> void:
	var village := _village(1, 100)
	village.restored.append("smithy")
	village.forge("gear:vest")
	var cat := Cat.new()
	cat.locked.append_array(village.locked_for_run())
	var offered := Upgrades.available(cat)
	for id in offered:
		check(not id in Village.FORGE or id == "gear:vest", "%s was offered before it was forged" % id)
	check("gear:vest" in offered, "the vest, forged, wasn't offered")


func test_only_forged_gear_is_worn_from_the_start() -> void:
	var village := _village(1, 100)
	village.restored.append("smithy")
	check(not village.wear_from_start("gear:vest"), "an unforged vest was worn from the start")
	village.forge("gear:vest")
	check(village.wear_from_start("gear:vest") and village.starting_piece == "gear:vest", "a forged vest couldn't be worn from the start")
	village.forge("support:mines")
	check(not village.wear_from_start("support:mines"), "mines were worn like gear")


func test_housed_cats_weave_cloth() -> void:
	var village := _village(5, 100)
	var arena := Arena.new()
	village.bring_home(arena)
	check(village.cloth == 0, "cats with no roof wove %d cloth" % village.cloth)
	village.restored.append("hut_0")
	village.restored.append("hut_1")
	village.bring_home(arena)
	check(village.cloth == 2 * Village.CATS_PER_HUT, "two huts' cats wove %d cloth" % village.cloth)


func test_the_weaver_sells_looks_for_cloth() -> void:
	var village := _village(1, 100)
	village.cloth = 20
	check(not village.buy_look("coat:gray"), "a look was bought with the weaver's hut in ruins")
	village.restored.append("hut_0")
	check(village.buy_look("coat:gray") and village.wear_look("coat:gray") and village.coat == "gray", "the gray coat couldn't be bought and worn")
	check(village.cloth == 20 - Village.LOOKS["coat:gray"].cloth, "the coat left %d cloth" % village.cloth)
	check(not village.wear_look("coat:black"), "a coat he doesn't own was worn")


func test_everything_comes_back_and_a_reset_clears_it() -> void:
	var village := _village(2, 100)
	village.cloth = 30
	village.restored.append("smithy")
	village.restored.append("hut_0")
	village.forge("gear:vest")
	village.wear_from_start("gear:vest")
	village.buy_look("banners:lagoon")
	village.wear_look("banners:lagoon")
	var path := "user://test_restoration.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.restored == ["smithy", "hut_0"] and loaded.forged == ["gear:vest"], "came back with %s restored, %s forged" % [loaded.restored, loaded.forged])
	check(loaded.starting_piece == "gear:vest" and loaded.banners == "lagoon" and loaded.cloth == village.cloth, "the starting piece, banners or cloth didn't come back")
	loaded.clear()
	check(loaded.restored.is_empty() and loaded.forged.is_empty() and loaded.starting_piece.is_empty() and loaded.cloth == 0 and loaded.banners == "festival", "a reset left something behind")


func test_the_market_trades_salvage_and_cloth() -> void:
	var village := _village(0, 10)
	check(not village.trade("cloth"), "the market traded while it stood in ruins")
	village.restored.append("market")
	check(village.trade("cloth") and village.salvage == 7 and village.cloth == 1, "salvage for cloth left %d salvage, %d cloth" % [village.salvage, village.cloth])
	check(village.trade("salvage") and village.salvage == 9 and village.cloth == 0, "cloth for salvage left %d salvage, %d cloth" % [village.salvage, village.cloth])
	check(not village.trade("salvage"), "cloth was traded with none to give")


func test_the_healers_tonic_waits_for_the_next_run() -> void:
	var village := _village(0, 20)
	check(not village.brew_tonic(), "a tonic was brewed with the healer's hut in ruins")
	village.restored.append("healer")
	check(village.brew_tonic() and village.tonic_ready and village.salvage == 20 - Village.TONIC_COST, "the tonic wasn't brewed for its price")
	check(not village.brew_tonic(), "a second tonic was brewed with one waiting")
