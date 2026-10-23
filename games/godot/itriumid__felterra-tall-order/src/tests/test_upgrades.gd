extends TestCase
## Level-up cards: kills fill the crew's experience, each level hands every cat an offer of three,
## rarity changes only how much a choice gives, and what's offered fits what he carries.


func _quiet() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_kills_level_the_crew_up_and_each_cat_gets_an_offer() -> void:
	var arena := _quiet()
	var first := arena.add_cat(Arena.SIZE / 2.0)
	var second := arena.add_cat(Arena.SIZE / 2.0 + Vector2(1.0, 0.0))
	for index in Arena.experience_needed(1):
		arena._gain_experience(1)
	check(arena.level == 2, "the crew is level %d" % arena.level)
	check(first.offers.size() == 1 and second.offers.size() == 1, "offers: %d and %d" % [first.offers.size(), second.offers.size()])
	check((first.offers[0] as Array).size() == Upgrades.CHOICES, "an offer of %d choices" % (first.offers[0] as Array).size())


func test_offers_wait_until_played() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.offers.append(Upgrades.offer(cat, arena.random))
	cat.offers.append(Upgrades.offer(cat, arena.random))
	for step in 60 * 30:
		arena.step()
	check(cat.offers.size() == 2, "offers expired: %d left" % cat.offers.size())
	check(cat.play(0), "couldn't play an offer")
	check(cat.offers.size() == 1, "playing didn't take the oldest offer")


func test_rarity_changes_how_much_never_what() -> void:
	var common := Cat.new()
	var legendary := Cat.new()
	Upgrades.apply(common, {"id": "gear:gloves", "rarity": Upgrades.Rarity.COMMON})
	Upgrades.apply(legendary, {"id": "gear:gloves", "rarity": Upgrades.Rarity.LEGENDARY})
	check(common.attack_speed_bonus > 0.0, "common gloves did nothing")
	check(is_equal_approx(legendary.attack_speed_bonus / common.attack_speed_bonus, Upgrades.AMOUNTS[3]), "legendary gave %.2f times common" % (legendary.attack_speed_bonus / common.attack_speed_bonus))
	check(is_equal_approx(legendary.damage_bonus / common.damage_bonus, Upgrades.AMOUNTS[3]), "rarity scaled one stat and not the other")
	check(legendary.armor == 0.0 and legendary.luck == 0.0, "legendary gloves gave stats gloves don't give")


func test_stats_only_come_from_gear() -> void:
	var cat := Cat.new()
	for id in Upgrades.available(cat):
		check(id.begins_with("gear:") or id.begins_with("level:") or id.begins_with("weapon:") or id.begins_with("mutation:") or id.begins_with("support:"), "%s is offered on its own" % id)


func test_the_same_gear_again_levels_it_up() -> void:
	var cat := Cat.new()
	Upgrades.apply(cat, {"id": "gear:boots", "rarity": Upgrades.Rarity.COMMON})
	check("gear_level:boots" in Upgrades.available(cat), "boots worn weren't offered a level")
	check(not Upgrades.available(cat).any(func(id: String) -> bool: return id == "gear:boots"), "boots were offered twice")
	var speed := cat.speed_bonus
	Upgrades.apply(cat, {"id": "gear_level:boots", "rarity": Upgrades.Rarity.COMMON})
	check(cat.gear_levels.boots == 2 and cat.speed_bonus > speed, "a level of boots gave nothing")


func test_one_item_per_slot() -> void:
	var cat := Cat.new()
	Upgrades.apply(cat, {"id": "gear:caping", "rarity": Upgrades.Rarity.COMMON})
	check(not "gear:hard_hat" in Upgrades.available(cat), "a second hat was offered over the caping")


func test_unfamiliar_stats_are_explained() -> void:
	var card := Upgrades.describe({"id": "gear:jamu_flask", "rarity": Upgrades.Rarity.COMMON})
	check(card.unfamiliar, "adrenaline wasn't marked as worth reading")
	check(card.explain.any(func(line: String) -> bool: return line.begins_with("Adrenaline:")), "adrenaline wasn't explained")


func test_luck_makes_rarer_cards_likelier() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 7
	var plain := 0
	var lucky := 0
	for roll in 4000:
		plain += 1 if Upgrades.roll_rarity(random, 0.0) >= Upgrades.Rarity.RARE else 0
		lucky += 1 if Upgrades.roll_rarity(random, 2.0) >= Upgrades.Rarity.RARE else 0
	check(lucky > plain * 1.5, "luck barely helped: %d rare against %d" % [lucky, plain])


func test_weapons_are_only_offered_if_the_paws_are_free() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["knife", "handgun"]})
	var offered := Upgrades.available(cat)
	check(not offered.any(func(id: String) -> bool: return id.begins_with("weapon:")), "a third weapon was offered for two full paws")
	var one := Cat.new()
	one.wear({"weapons": ["knife"]})
	check("weapon:handgun" in Upgrades.available(one), "a free tail wasn't offered a handgun")
	check(not "weapon:knife" in Upgrades.available(one), "he was offered the knife he holds")


func test_gear_is_worn_when_chosen_and_not_offered_again() -> void:
	var cat := Cat.new()
	Upgrades.apply(cat, {"id": "gear:vest", "rarity": Upgrades.Rarity.COMMON})
	check(cat.gear.get("body", "") == "vest", "the vest wasn't worn")
	check(cat.armor > 0.0, "the vest gave no armor")
	check(not "gear:vest" in Upgrades.available(cat), "the vest was offered again")


func test_a_banished_choice_never_comes_back() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.offers.append(Upgrades.offer(cat, arena.random))
	var gone: String = cat.offers[0][0].id
	check(cat.banish(0, arena.random), "couldn't banish")
	check((cat.offers[0] as Array).size() == Upgrades.CHOICES, "banishing left the offer short")
	for index in 50:
		var offer := Upgrades.offer(cat, arena.random)
		check(not offer.any(func(choice: Dictionary) -> bool: return choice.id == gone), "%s came back" % gone)


func test_rerolls_run_out() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.offers.append(Upgrades.offer(cat, arena.random))
	for index in cat.rerolls:
		check(cat.reroll(arena.random), "a reroll was refused")
	check(not cat.reroll(arena.random), "rerolled with none left")


func test_stats_do_what_they_say() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.raise("armor", 0.5)
	cat.hurt(1.0, Vector2.ZERO)
	check(is_equal_approx(cat.health, Cat.MOST_HEALTH - 0.5), "armor 0.5 let %.2f of a 1 through" % (Cat.MOST_HEALTH - cat.health))
	cat.raise("regeneration", 1.0)
	for step in 30:
		arena.step()
	check(cat.health > Cat.MOST_HEALTH - 0.5, "regeneration gave nothing back")
	var fast := Cat.new()
	fast.raise("attack_speed", 1.0)
	check(is_equal_approx(fast.weapons[0].interval_for(fast), fast.weapons[0].interval / 2.0), "double attack speed didn't halve the interval")


func test_adrenaline_gives_back_a_share_of_damage_dealt() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.health = 5.0
	cat.raise("adrenaline", 0.5)
	var rat := arena.add_creature(cat.body.position + Vector2(3.0, 0.0))
	rat.health = 100.0
	arena.strike(rat, 2.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	check(is_equal_approx(cat.health, 6.0), "dealing 2 at half adrenaline healed to %.2f" % cat.health)


func _play_levels(cat: Cat, random: RandomNumberGenerator, levels: int) -> Array[int]:
	var sizes: Array[int] = []
	for level in levels:
		var offer := Upgrades.offer(cat, random)
		sizes.append(offer.size())
		if offer.is_empty():
			break
		Upgrades.apply(cat, offer[random.randi_range(0, offer.size() - 1)])
	return sizes


func test_a_long_run_never_runs_out_of_upgrades() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 3
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	var sizes := _play_levels(cat, random, 200)
	check(sizes.size() == 200 and sizes.all(func(size: int) -> bool: return size == Upgrades.CHOICES), "an offer came up short: %s" % str(sizes.filter(func(size: int) -> bool: return size < Upgrades.CHOICES)))


func test_power_keeps_growing_past_every_top_level() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 4
	var cat := Cat.new()
	cat.wear({"weapons": ["knife", "handgun"]})
	_play_levels(cat, random, 80)
	var damage_at_80 := cat.weapons.map(func(weapon: Weapon) -> float: return weapon.hit_for(cat))
	_play_levels(cat, random, 80)
	var damage_at_160 := cat.weapons.map(func(weapon: Weapon) -> float: return weapon.hit_for(cat))
	check(damage_at_160.reduce(func(a: float, b: float) -> float: return a + b) > damage_at_80.reduce(func(a: float, b: float) -> float: return a + b), "eighty more levels made him no stronger")


func test_a_knife_evolves_only_at_the_top_level_and_keeps_its_levels() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	for level in Upgrades.WEAPON_TOP - 1:
		Upgrades.apply(cat, {"id": "level:knife", "rarity": Upgrades.Rarity.COMMON})
	check("evolve:knife" in Upgrades.available(cat), "a top-level knife wasn't offered its evolution")
	var young := Cat.new()
	young.wear({"weapons": ["knife"]})
	for level in 4:
		Upgrades.apply(young, {"id": "level:knife", "rarity": Upgrades.Rarity.COMMON})
	check(not "evolve:knife" in Upgrades.available(young), "a level 5 knife could already evolve")
	var power := cat.weapons[0].power
	Upgrades.apply(cat, {"id": "evolve:knife", "rarity": Upgrades.Rarity.COMMON})
	check(cat.weapons[0].name == "keris", "the knife became %s" % cat.weapons[0].name)
	check(cat.weapons[0].power >= power, "evolving lost the knife's levels")
	check(not "weapon:knife" in Upgrades.available(cat), "a knife was offered beside his keris")


func test_the_last_of_a_family_takes_mastery_without_limit() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["kerambit"]})
	for level in Upgrades.WEAPON_TOP + 10:
		var id := "level:kerambit" if cat.weapons[0].level < Upgrades.WEAPON_TOP else "mastery:kerambit"
		check(id in Upgrades.available(cat), "%s wasn't offered at level %d" % [id, cat.weapons[0].level])
		Upgrades.apply(cat, {"id": id, "rarity": Upgrades.Rarity.COMMON})
	check(cat.weapons[0].level == Upgrades.WEAPON_TOP + 11, "the kerambit stopped at level %d" % cat.weapons[0].level)


func test_full_health_never_reads_as_more_than_the_most() -> void:
	var cat := Cat.new()
	# Gear gives fractions of a point of health: an uncommon vest, a rare batik shirt.
	Upgrades.apply(cat, {"id": "gear:vest", "rarity": Upgrades.Rarity.UNCOMMON})
	Upgrades.apply(cat, {"id": "gear:batik_shirt", "rarity": Upgrades.Rarity.RARE})
	check(not is_equal_approx(cat.max_health, roundf(cat.max_health)), "the most health came out whole, %.2f, so this checks nothing" % cat.max_health)
	check(is_equal_approx(cat.health, cat.max_health), "he wasn't at full health")
	var shown := Overlay.health_text(cat.health, cat.max_health, "/").split("/")
	check(shown[0] == shown[1], "full health reads as %s" % "/".join(shown))
	check(Overlay.health_text(0.3, cat.max_health, "/").begins_with("1/"), "a sliver of health didn't read as one")
	# And healing never goes past the most: adrenaline and regeneration heal the same way.
	cat.adrenaline = 1.0
	cat.heal(1000.0)
	check(cat.health <= cat.max_health, "healing went past the most, to %.2f of %.2f" % [cat.health, cat.max_health])
