extends TestCase
## Progression from the village: a run starts with weapons and nothing else, the smith forges more,
## freeing an area teaches its dodge mutations, and anything had can be packed or left home. Every
## thing has its story, and every story and scene line fits where it's shown. Leaving the village,
## he's seen off.

## How wide a cutscene's line can be, in pixels: the screen, less a margin either side.
const LINE_WIDTH := 640 - 16


func test_a_new_village_sends_her_out_with_six_weapons_and_five_pieces_of_gear() -> void:
	var village := Village.new()
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	cat.locked.append_array(village.locked_for_run())
	var offered := Upgrades.available(cat)
	for id in offered:
		var item := Upgrades.evolves_from(id) if id.begins_with("evolve:") else id.get_slice(":", 1)
		var kind := "gear" if id.begins_with("gear") else "weapon"
		check(("%s:%s" % [kind, Upgrades._family(item) if kind == "weapon" else item]) in Village.STARTING, "%s was offered before anything was forged or taught" % id)
	var kinds := {"weapon": 0, "gear": 0}
	for id in Village.STARTING:
		kinds[id.get_slice(":", 0)] += 1
	check(kinds.weapon == Village.keep_packed("weapon") and kinds.gear >= 5, "a new village starts with %s" % str(kinds))
	check("weapon:golok" in offered and "gear:caping" in offered, "what he starts with wasn't offered")


func test_she_can_level_up_all_run_with_what_she_starts_with() -> void:
	var village := Village.new()
	var random := RandomNumberGenerator.new()
	random.seed = 39
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	cat.locked.append_array(village.locked_for_run())
	for level in 60:
		var offer := Upgrades.offer(cat, random)
		check(offer.size() == Upgrades.CHOICES, "an offer came up short at level %d" % level)
		if offer.is_empty():
			return
		Upgrades.apply(cat, offer[0])


func test_too_few_packed_and_nothing_more_is_left_home() -> void:
	var village := Village.new()
	check(not village.repack("weapon:golok") and village.packed("weapon:golok"), "the golok was left home with only six weapons packed")
	check(not village.repack("weapon:nunchaku"), "the nunchaku he starts with was left home")
	village.forged.append("weapon:machete")
	check(village.repack("weapon:golok") and not village.packed("weapon:golok"), "with seven weapons, the golok couldn't be left home")
	check(not village.repack("weapon:machete"), "a weapon was left home, leaving five")
	for kind in ["weapon", "gear", "support", "mutation"]:
		check(Village.keep_packed(kind) == 3 * Village.places(kind), "%d %s kept packed, for %d places" % [Village.keep_packed(kind), kind, Village.places(kind)])
	check(Village.places("weapon") == 2 and Village.places("gear") == 7 and Village.places("support") == 2 and Village.places("mutation") == 3, "a run's places are counted wrong")


func test_freeing_an_area_teaches_its_mutations() -> void:
	var village := Village.new()
	check(village.learned().is_empty(), "he knew mutations before anyone taught him")
	check(not village.packed("mutation:rolling_slash"), "rolling slash was packed before it was taught")
	village.liberate("edge")
	check("mutation:rolling_slash" in village.learned() and "mutation:land_on_feet" in village.learned(), "freeing the edge taught %s" % str(village.learned()))
	var cat := Cat.new()
	cat.locked.append_array(village.locked_for_run())
	check("mutation:rolling_slash" in Upgrades.available(cat), "a taught mutation wasn't offered")
	check(not "mutation:pounce" in Upgrades.available(cat), "the pounce was offered before the deep forest was freed")


func test_every_mutation_is_taught_somewhere() -> void:
	var taught: Array[String] = []
	for id in Areas.ids():
		taught.append_array(Areas.teaches(id))
	for mutation: String in Upgrades.MUTATIONS:
		check(mutation in taught, "no area teaches %s" % mutation)


func test_what_she_has_can_be_left_home() -> void:
	var village := Village.new()
	village.salvage = 100
	village.restored.append("smithy")
	village.forge("weapon:machete")
	check(village.packed("weapon:machete"), "a forged machete wasn't packed")
	check(village.repack("weapon:machete") and not village.packed("weapon:machete"), "the machete couldn't be left home")
	var cat := Cat.new()
	cat.locked.append_array(village.locked_for_run())
	check(not "weapon:machete" in Upgrades.available(cat), "a machete left home was offered")
	check(village.repack("weapon:machete") and village.packed("weapon:machete"), "the machete couldn't be packed again")
	check(not village.repack("weapon:rifle"), "an unforged rifle was packed")


func test_gear_is_worn_from_the_start_and_put_back() -> void:
	var village := Village.new()
	village.salvage = 200
	village.restored.append("smithy")
	village.forge("gear:vest")
	village.repack("gear:vest")
	check(village.starting_piece == "gear:vest" and village.packed("gear:vest"), "the vest wasn't worn from the start")
	village.repack("gear:caping")
	check(village.starting_piece == "gear:caping" and village.packed("gear:vest"), "wearing the caping didn't put the vest back in the pack")
	# With too little gear to leave any home, worn from the start goes back to the pack.
	village.repack("gear:caping")
	check(village.packed("gear:caping") and village.starting_piece.is_empty(), "the caping was left home with too little gear packed")


func test_with_gear_enough_a_piece_is_left_home() -> void:
	var village := Village.new()
	for id: String in Upgrades.GEAR:
		if not "gear:" + id in Village.STARTING:
			village.forged.append("gear:" + id)
	# More gear than there is today: a test stands in for what's still to be built.
	var keep := Village.keep_packed("gear")
	var have := village.everything().filter(func(id: String) -> bool: return id.begins_with("gear:") and village.has(id)).size()
	if have <= keep:
		check(not village.repack("gear:caping") or village.starting_piece == "gear:caping", "gear was left home with %d packed, keeping %d" % [have, keep])
		return
	village.repack("gear:caping")
	village.repack("gear:caping")
	check(not village.packed("gear:caping"), "with gear enough, the caping wasn't left home")


func test_what_is_left_home_is_kept() -> void:
	var village := Village.new()
	village.forged.assign(["weapon:rifle", "gear:boots"])
	village.left_home.assign(["weapon:rifle", "not_a_thing"])
	var path := "user://test_village_left_home.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.left_home == ["weapon:rifle"], "left home came back as %s" % str(loaded.left_home))
	loaded.clear()
	check(loaded.left_home.is_empty(), "a reset kept what was left home")


func test_everything_has_its_story() -> void:
	var cards: Array[String] = Village.everything()
	for from: String in Upgrades.EVOLVES:
		for grown: String in Upgrades.EVOLVES[from]:
			cards.append("weapon:" + grown)
	for id in cards:
		var story := Lore.of(id.get_slice(":", 0), id.get_slice(":", 1))
		check(not story.is_empty(), "%s has no story" % id)
		var does: String = Upgrades.describe({"id": id, "rarity": 0}).does
		check(not does.is_empty(), "%s doesn't say what it does" % id)
		check(Overlay.wrapped(does, 320 - 24).size() + Overlay.wrapped(story, 320 - 24).size() <= Overlay.STORY_LINES, "%s's story and what it does are too long for the smithy" % id)
	for id: String in Lore.STORIES:
		check(id in cards, "a story for %s, which isn't anything" % id)


func test_every_card_carries_its_story() -> void:
	check(not (Upgrades.describe({"id": "evolve:knife", "rarity": 0}).story as String).is_empty(), "the keris's card has no story")
	check(not (Upgrades.describe({"id": "mutation:pounce", "rarity": 0}).story as String).is_empty(), "the pounce's card has no story")


func test_every_line_of_the_story_fits_the_screen() -> void:
	var lines: Array = []
	for area in Areas.LIST:
		lines.append_array(area.before)
		lines.append_array(area.after)
		lines.append_array(area.send_off)
		lines.append_array(area.get("again", []))
		lines.append_array(area.get("teaches", {}).get("lines", []))
	lines.append_array(load("res://game/main.gd").INTRO)
	for line: Variant in lines:
		if line is Dictionary:
			check(Overlay.wrapped(line.text, Overlay.BUBBLE_WIDTH).size() <= 3, "too long for a bubble: %s" % line.text)
		else:
			check(PixelFont.width(line) <= LINE_WIDTH, "too wide for the screen: %s" % line)
	for pool: String in Cage.SAYS:
		for line: String in Cage.SAYS[pool]:
			check(Overlay.wrapped(line, Overlay.BUBBLE_WIDTH).size() <= 3, "too long for a bubble: %s" % line)


func test_whoever_speaks_is_in_the_village_by_then() -> void:
	var village := Village.new()
	for area in Areas.LIST:
		# Who's home before he leaves for it, and before he's taught what freeing it teaches.
		var home := ["elder"]
		for cat: Dictionary in village.cats:
			home.append(cat.name)
		for line: Variant in area.send_off:
			if line is Dictionary:
				check(line.by in home, "%s sees him off to %s before coming home" % [line.by, area.name])
		village.liberate(area.id)
		home = ["elder"]
		for cat: Dictionary in village.cats:
			home.append(cat.name)
		for line: Variant in area.teaches.get("lines", []):
			if line is Dictionary:
				check(line.by in home, "%s teaches after %s, but isn't home" % [line.by, area.name])


func test_every_area_has_a_send_off() -> void:
	for area in Areas.LIST:
		check(not (area.send_off as Array).is_empty(), "nobody sees him off to %s" % area.name)


func test_she_is_seen_off_out_of_sight() -> void:
	var cats: Array = []
	for index in 5:
		cats.append({"name": Cage.NAMES[index], "coat": "gray"})
	var map := VillageMap.new(cats)
	map.cat.body.position = Vector2(VillageMap.EXIT_FROM + 0.1, 5.0)
	check(map.leaving(), "he wasn't leaving through the gate")
	map.see_off()
	for step in 60 * 20:
		map.step(Arena.STEP)
	check(map.gone(), "he was seen off and never left, stopping at %s" % map.cat.body.position)
	for villager in map.villagers:
		check(villager.body.position.x > VillageMap.SEE_OFF_FROM - 1.0, "a villager didn't come to see him off, stopping at %s" % villager.body.position)
		check(villager.facing.x > 0.0, "a villager at the gate looked away as he left")


func test_everyone_who_speaks_in_a_cutscene_has_a_portrait() -> void:
	var lines: Array = []
	for area in Areas.LIST:
		lines.append_array(area.send_off)
		lines.append_array(area.get("teaches", {}).get("lines", []))
	lines.append_array(load("res://game/main.gd").INTRO)
	for line: Variant in lines:
		if line is Dictionary:
			check(Portraits.has(line.by), "%s speaks, but has no portrait" % line.by)
			check(line.get("mood", "neutral") in Portraits.MOODS, "%s says a line in a mood there isn't: %s" % [line.by, line.get("mood")])


func test_every_portrait_is_the_same_size_in_every_mood() -> void:
	for who: String in Portraits.CAST.keys() + ["jogiboy"]:
		for mood in Portraits.MOODS:
			check(Sprites.image(Portraits.art(who, mood)).get_size() == Vector2i(40, 40), "%s's %s portrait isn't 40 by 40" % [who, mood])

