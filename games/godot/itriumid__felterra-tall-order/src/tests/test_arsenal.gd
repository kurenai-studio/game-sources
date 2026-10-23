extends TestCase
## The arsenal: every weapon can be built, drawn, named and forged; and each does what sets it
## apart, from a shotgun's cone to a bamboo spear that breaks.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


## A cat holding one weapon, and nothing else.
func _cat(arena: Arena, weapon_name: String) -> Cat:
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.health = 1.0e6
	cat.wear({"weapons": [weapon_name]})
	return cat


func _rat(arena: Arena, at: Vector2, health := 1000.0) -> Creature:
	var rat := arena.add_creature(at)
	rat.health = health
	return rat


## Steps with the creatures held where they are, so only the weapon is tested.
func _hold_and_step(arena: Arena, held: Array, steps: int) -> void:
	var spots := held.map(func(creature: Creature) -> Vector2: return creature.body.position)
	for step in steps:
		for index in held.size():
			var creature: Creature = held[index]
			if creature.alive() and not creature.tripped():
				creature.body.position = spots[index]
				creature.body.velocity = Vector2.ZERO
		arena.step()


func test_every_weapon_is_built_drawn_named_and_forged() -> void:
	var every: Array[String] = []
	every.append_array(Upgrades.WEAPONS)
	for from: String in Upgrades.EVOLVES:
		every.append_array(Upgrades.EVOLVES[from])
	for weapon_name in every:
		check(Weapon.named(weapon_name).name == weapon_name, "%s couldn't be built" % weapon_name)
		check(Sprites.held_art().has(weapon_name), "%s has no drawing" % weapon_name)
		check(Upgrades.WEAPON_NAMES.has(weapon_name), "%s has no name" % weapon_name)
	for weapon_name in Upgrades.WEAPONS:
		check(Village.FORGE.has("weapon:" + weapon_name) != ("weapon:" + weapon_name in Village.STARTING), "%s is neither forged nor had from the start, or both" % weapon_name)
	for support: String in Upgrades.SUPPORT:
		check(Village.FORGE.has("support:" + support), "the %s can't be forged" % support)


func test_two_handed_weapons_take_both_paws() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["greatsword", "knife"]})
	check(cat.weapons.size() == 1 and cat.weapons[0].name == "greatsword", "a greatsword left his tail free")


func test_a_shotgun_fires_a_cone_of_pellets() -> void:
	var arena := _arena()
	var cat := _cat(arena, "shotgun")
	_rat(arena, cat.body.position + Vector2(3.0, 0.0))
	arena.step()
	check(arena.shots.size() == Weapon.ARSENAL.shotgun.pellets, "%d pellets in the air" % arena.shots.size())


func test_a_sniper_round_goes_through_a_line() -> void:
	var arena := _arena()
	var cat := _cat(arena, "sniper_rifle")
	var line: Array = []
	for index in 4:
		line.append(_rat(arena, cat.body.position + Vector2(3.0 + index * 0.5, 0.0)))
	_hold_and_step(arena, line, 30)
	check(line.all(func(rat: Creature) -> bool: return rat.health < 1000.0), "a round didn't go through the line")


func test_a_ketapel_stone_glances_off_to_the_next() -> void:
	var arena := _arena()
	var cat := _cat(arena, "ketapel")
	var first := _rat(arena, cat.body.position + Vector2(3.0, 0.0))
	var second := _rat(arena, cat.body.position + Vector2(3.0, 1.5))
	_hold_and_step(arena, [first, second], 150)
	check(first.health < 1000.0 and second.health < 1000.0, "the stone didn't glance off to the second rat")


func test_a_sumpit_dart_poisons_and_slows() -> void:
	var arena := _arena()
	var cat := _cat(arena, "sumpit")
	var rat := _rat(arena, cat.body.position + Vector2(4.0, 0.0))
	_hold_and_step(arena, [rat], 20)
	check(rat.afflictions.has("poison") and rat.pace() < 1.0, "the dart neither poisoned nor slowed")
	var poisoned := rat.health
	cat.weapons.clear()
	_hold_and_step(arena, [rat], 60)
	check(rat.health < poisoned, "the poison did nothing")


func test_a_flare_sets_alight() -> void:
	var arena := _arena()
	var cat := _cat(arena, "flare_gun")
	var rat := _rat(arena, cat.body.position + Vector2(4.0, 0.0))
	var lit := false
	for step in 60 * 4:
		_hold_and_step(arena, [rat], 1)
		lit = lit or rat.afflictions.has("burn")
	check(lit, "the flare didn't set the rat alight")


func test_lamp_oil_burns_where_it_lands() -> void:
	var arena := _arena()
	var cat := _cat(arena, "lamp_oil")
	var rat := _rat(arena, cat.body.position + Vector2(3.0, 0.0))
	_hold_and_step(arena, [rat], 90)
	check(not arena.fires.is_empty(), "the oil didn't catch where it landed")
	var later := _rat(arena, arena.fires[0].position)
	_hold_and_step(arena, [later], 2)
	check(later.afflictions.has("burn"), "a rat walked into the fire and didn't burn")


func test_nails_stay_where_they_land_for_the_next_foot() -> void:
	var arena := _arena()
	var cat := _cat(arena, "nail_gun")
	arena.hazards.append({"position": cat.body.position + Vector2(1.0, 0.0), "radius": 0.08, "damage": 1.0, "left": 5.0, "kind": "nail", "by": cat, "ready": {}})
	cat.weapons.clear()
	var rat := _rat(arena, cat.body.position + Vector2(1.0, 0.0))
	_hold_and_step(arena, [rat], 2)
	check(rat.health < 1000.0 and arena.hazards.is_empty(), "the nail didn't go into the rat's foot")


func test_petasan_pop_one_after_another() -> void:
	var arena := _arena()
	arena.crackers.append({"position": Arena.SIZE / 2.0, "left": 0.0, "count": 4, "damage": 1.0, "by": null})
	var pops := 0
	for step in 60:
		arena.step()
		pops += arena.events.filter(func(event: Dictionary) -> bool: return event.by == "blast").size()
		arena.events.clear()
	check(pops == 4, "%d pops" % pops)


func test_a_celurit_trips() -> void:
	var arena := _arena()
	var cat := _cat(arena, "celurit")
	var rat := _rat(arena, cat.body.position + Vector2(0.4, 0.0))
	for step in 20:
		arena.step()
		if rat.tripped():
			break
	check(rat.tripped(), "the celurit didn't trip the rat")


func test_a_kujang_hooks_them_in() -> void:
	var arena := _arena()
	var cat := _cat(arena, "kujang")
	var rat := _rat(arena, cat.body.position + Vector2(0.5, 0.0))
	var start := rat.body.position.distance_to(cat.body.position)
	var pulled := false
	for step in 20:
		arena.step()
		if rat.body.velocity.dot(cat.body.position - rat.body.position) > 0.5:
			pulled = true
	check(pulled, "the kujang pushed the rat off instead of hooking it in (from %.2f)" % start)


func test_a_bamboo_spear_breaks_and_is_sharpened_again() -> void:
	var arena := _arena()
	var cat := _cat(arena, "bambu_runcing")
	var spear: Weapon = cat.weapons[0]
	_rat(arena, cat.body.position + Vector2(0.8, 0.0))
	for step in 60 * 12:
		_hold_and_step(arena, arena.creatures, 1)
		if spear.broken_for > 0.0:
			break
	check(spear.broken_for > 0.0, "the spear never broke")
	arena.creatures.clear()
	for step in ceili(Weapon.RESHARPEN_TIME / Arena.STEP) + 2:
		arena.step()
	check(spear.broken_for == 0.0 and spear.hits_left == spear.breaks, "the spear wasn't sharpened again")


func test_a_rifle_grows_two_ways() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["rifle"]})
	cat.weapons[0].level = Upgrades.WEAPON_TOP
	var offered := Upgrades.available(cat)
	check("evolve:rifle" in offered and "evolve:rifle>sniper_rifle" in offered, "the rifle was offered %s" % str(offered.filter(func(id: String) -> bool: return id.begins_with("evolve"))))
	Upgrades.apply(cat, {"id": "evolve:rifle>sniper_rifle", "rarity": Upgrades.Rarity.COMMON})
	check(cat.weapons[0].name == "sniper_rifle", "the rifle grew into a %s" % cat.weapons[0].name)


func test_a_critical_hit_lands_twice_as_hard() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.critical = 1.0
	var rat := _rat(arena, cat.body.position + Vector2(2.0, 0.0))
	arena.strike(rat, 3.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	check(is_equal_approx(rat.health, 1000.0 - 6.0), "a critical hit took %.1f" % (1000.0 - rat.health))


func test_knockback_shoves_harder() -> void:
	var arena := _arena()
	var plain := arena.add_cat(Arena.SIZE / 2.0)
	var strong := arena.add_cat(Arena.SIZE / 2.0)
	strong.knockback_bonus = 1.0
	var first := _rat(arena, Vector2(5.0, 5.0))
	var second := _rat(arena, Vector2(8.0, 5.0))
	arena.strike(first, 1.0, Vector2.RIGHT, 2.0, 0.0, "round", plain)
	arena.strike(second, 1.0, Vector2.RIGHT, 2.0, 0.0, "round", strong)
	check(second.body.velocity.length() > first.body.velocity.length() * 1.5, "knockback didn't shove harder")


func test_the_net_drone_pins_them_down() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	Upgrades.apply(cat, {"id": "support:net_drone", "rarity": Upgrades.Rarity.COMMON})
	var rat := _rat(arena, cat.body.position + Vector2(4.0, 0.0))
	var pinned := false
	for step in 60 * 4:
		_hold_and_step(arena, [rat], 1)
		pinned = pinned or rat.tripped()
	check(pinned, "no net ever pinned the rat")


func test_the_kite_string_cuts_what_it_crosses() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	Upgrades.apply(cat, {"id": "support:layang_layang", "rarity": Upgrades.Rarity.COMMON})
	var rat := _rat(arena, cat.body.position + Vector2(1.2, 0.0))
	_hold_and_step(arena, [rat], 60 * 5)
	check(rat.health < 1000.0, "the kite's string never cut the rat")


func test_the_spike_bed_pricks_and_slows() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	Upgrades.apply(cat, {"id": "support:ranjau_bambu", "rarity": Upgrades.Rarity.COMMON})
	var rat := _rat(arena, cat.body.position + Vector2(3.0, 0.0))
	_hold_and_step(arena, [rat], 1)
	check(arena.hazards.any(func(hazard: Dictionary) -> bool: return hazard.kind == "spikes"), "no spike bed was set down")
	rat.body.position = cat.body.position + Vector2(0.3, 0.0)
	_hold_and_step(arena, [rat], 2)
	check(rat.health < 1000.0 and rat.pace() < 1.0, "the spikes neither pricked nor slowed the rat")


func test_the_radio_draws_the_horde() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	Upgrades.apply(cat, {"id": "support:radio", "rarity": Upgrades.Rarity.COMMON})
	for index in Support.RADIO_CROWD:
		_rat(arena, cat.body.position + Vector2.from_angle(index) * 3.0)
	arena.step()
	check(arena.decoys.size() == 1, "the radio wasn't set down")
	var radio_at := arena.decoys[0].body.position
	cat.body.position += Vector2(6.0, 0.0)
	var rat := arena.creatures[0]
	for step in 60:
		arena.step()
	check(rat.body.position.distance_to(radio_at) < rat.body.position.distance_to(cat.body.position), "the horde went for him, not the radio")
