# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Node
## Headless test suite. Run with:
##
##     godot --headless --path . res://tests/test_runner.tscn
##
## Exits with code 0 when every check passes, 1 otherwise. Runs as a scene
## (not with -s) so the Game autoload is available.

var _failures := 0
var _checks := 0


func _ready() -> void:
	Game.save_path = "user://test_save.json"
	test_galaxy_is_deterministic()
	test_galaxy_is_connected_at_starting_range()
	test_starbases()
	test_system_generation_and_depletion()
	test_cargo_hold()
	test_power_plant_caps_upgrades()
	test_upgrade_consumes_resources()
	test_combat_is_winnable_early()
	test_boarding_resolves()
	test_patrol_shield_stays_down()
	test_monster_cannot_be_boarded()
	test_encounter_roll_kinds()
	test_save_round_trip()
	await test_screens_build()
	await test_playthrough()
	print("\n%d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: " + what)


func test_galaxy_is_deterministic() -> void:
	var a := Galaxy.new()
	a.generate(1234)
	var b := Galaxy.new()
	b.generate(1234)
	check(a.stars.size() == b.stars.size(), "same star count for same seed")
	check(a.stars.size() >= 40, "galaxy has a reasonable number of stars (%d)" % a.stars.size())
	var same := true
	for i in a.stars.size():
		if a.stars[i]["name"] != b.stars[i]["name"] or a.stars[i]["pos"] != b.stars[i]["pos"]:
			same = false
	check(same, "stars identical for same seed")
	var sa := a.get_system(5)
	var sb := b.get_system(5)
	check(sa.planets.size() == sb.planets.size() and sa.planets[0].type == sb.planets[0].type, "systems identical for same seed")


func test_galaxy_is_connected_at_starting_range() -> void:
	for seed_value in [1, 2, 3, 99, 31337]:
		var g := Galaxy.new()
		g.generate(seed_value)
		var range_lvl1 := Ship.new().jump_range()
		var seen := {g.start_star: true}
		var queue: Array[int] = [g.start_star]
		while not queue.is_empty():
			var cur: int = queue.pop_back()
			for n in g.reachable_from(cur, range_lvl1):
				if not seen.has(n):
					seen[n] = true
					queue.append(n)
		check(seen.size() == g.stars.size(), "seed %d: all stars reachable at level-1 jump range" % seed_value)


func test_starbases() -> void:
	var g := Galaxy.new()
	g.generate(42)
	check(g.star(g.start_star)["starbase"], "start system has a starbase")
	var count := 0
	for s in g.stars:
		if s["starbase"]:
			count += 1
	check(count >= 3, "several starbases exist (%d)" % count)
	check(g.star(g.nearest_starbase(g.start_star))["starbase"], "nearest_starbase returns a starbase")


func test_system_generation_and_depletion() -> void:
	var g := Galaxy.new()
	g.generate(7)
	var found := false
	for id in g.stars.size():
		var sys := g.get_system(id)
		check(sys.planets.size() >= 2 and sys.planets.size() <= 5, "planet count in range")
		for p in sys.planets:
			if p.deposits.is_empty() or found:
				continue
			found = true
			var before: int = p.deposits[0]["amount"]
			var got := g.extract(id, p, 0, 3)
			check(got == mini(3, before), "extract returns units taken")
			g.mark_scanned(id, p, 2)
			var g2 := Galaxy.new()
			g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
			var p2: Planet = g2.get_system(id).planets[p.index]
			check(p2.deposits[0]["amount"] == before - got, "depletion survives save/load")
			check(g2.scan_level(id, p2) == 2, "scan level survives save/load")
	check(found, "some planet has deposits")


func test_cargo_hold() -> void:
	var c := CargoHold.new()
	c.capacity = 10
	check(c.add("iron", 7) == 7, "add within capacity")
	check(c.add("ice", 7) == 3, "add clamps to free space")
	check(c.free_space() == 0, "hold is full")
	check(c.remove("iron", 10) == 7, "remove clamps to count")
	check(not c.items.has("iron"), "empty stacks are erased")


func test_power_plant_caps_upgrades() -> void:
	var s := Ship.new()
	for id in ResourceDB.ORDER:
		s.cargo.capacity = 999
		s.cargo.add(id, 50)
	check(s.power_used() == 4 and s.power_capacity() == 5, "starting power budget")
	check(s.upgrade_block_reason("weapons") == "", "one spare power point")
	s.apply_upgrade("weapons")
	check(s.upgrade_block_reason("shield") == "Needs more power", "power plant blocks further upgrades")
	check(s.upgrade_block_reason("power") == "", "power plant itself is upgradable")
	s.apply_upgrade("power")
	check(s.upgrade_block_reason("shield") == "", "upgrade allowed after power upgrade")


func test_upgrade_consumes_resources() -> void:
	var s := Ship.new()
	check(s.upgrade_block_reason("power") == "Missing resources", "upgrade needs resources")
	s.cargo.add("uranium", 2)
	s.cargo.add("iron", 3)
	s.apply_upgrade("power")
	check(s.level("power") == 2 and s.cargo.count("iron") == 1 and s.cargo.count("uranium") == 0, "upgrade consumes resources")


func test_combat_is_winnable_early() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var wins := 0
	var fights := 200
	for i in fights:
		var ship := Ship.new()
		var crew := Crew.new()
		var e := CombatEngine.new(ship, crew, Encounter.create("pirate", 0, rng), rng)
		var turns := 0
		while not e.over and turns < 100:
			e.act("recharge" if ship.shield_points == 0 and ship.hull < 12 else "fire")
			turns += 1
		check(e.over, "fight %d ends" % i)
		if e.player_won() or e.outcome == "enemy_fled":
			wins += 1
	check(wins > fights * 0.7, "a fresh ship usually beats a danger-0 pirate (%d/%d)" % [wins, fights])


func test_boarding_resolves() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var enc := Encounter.create("trader", 0, rng)
	var e := CombatEngine.new(Ship.new(), Crew.new(), enc, rng)
	check(not e.can_board(), "cannot board with shields up")
	enc.shield = 0
	check(e.can_board(), "can board once shields are down")
	e.act("board")
	check(e.boarding, "boarding started")
	var rounds := 0
	while not e.over and rounds < 50:
		e.board("charge")
		rounds += 1
	check(e.over and (e.outcome == "boarded" or e.outcome == "defeat"), "boarding ends in capture or defeat")


func test_patrol_shield_stays_down() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var enc := Encounter.create("patrol", 0, rng)
	var e := CombatEngine.new(Ship.new(), Crew.new(), enc, rng)
	enc.shield = 0
	e.act("evade")
	check(e.over or e.can_board(), "patrol shield does not regenerate from zero")


func test_monster_cannot_be_boarded() -> void:
	var rng := RandomNumberGenerator.new()
	var enc := Encounter.create("monster", 2, rng)
	enc.shield = 0
	var e := CombatEngine.new(Ship.new(), Crew.new(), enc, rng)
	check(not e.can_board(), "monsters cannot be boarded")


func test_encounter_roll_kinds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var seen := {}
	var star := {"danger": 2, "starbase": true}
	for i in 2000:
		var enc := Encounter.roll(star, "arrival", 0, rng)
		if enc:
			seen[enc.kind] = true
	for k in Encounter.KINDS:
		check(seen.has(k), "encounter kind '%s' occurs" % k)


func test_save_round_trip() -> void:
	Game.new_game(777)
	Game.credits = 1234
	Game.ship.cargo.add("crystals", 4)
	Game.crew.train("pilot")
	Game.ship.hull = 17
	Game.notoriety = 2
	Game.save_game()
	Game.new_game(1)
	check(Game.load_game(), "save loads")
	check(Game.galaxy.galaxy_seed == 777, "seed restored")
	check(Game.credits == 1234, "credits restored")
	check(Game.ship.cargo.count("crystals") == 4, "cargo restored")
	check(Game.crew.skill("pilot") == 2, "crew skills restored")
	check(Game.ship.hull == 17 and Game.notoriety == 2, "hull and notoriety restored")
	Game.delete_save()


## Builds every screen inside the real Main scene to catch runtime errors.
func test_screens_build() -> void:
	Game.new_game(2024)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var rng := RandomNumberGenerator.new()
	var screens := [
		["title", {}], ["system", {}], ["galaxy", {}], ["starbase", {}],
		["encounter", {"encounter": Encounter.create("pirate", 1, rng)}],
		["encounter", {"encounter": Encounter.create("trader", 1, rng)}],
		["encounter", {"encounter": Encounter.create("patrol", 1, rng)}],
		["encounter", {"encounter": Encounter.create("monster", 1, rng)}],
		["combat", {"encounter": Encounter.create("pirate", 0, rng)}],
		["combat", {"encounter": Encounter.create("monster", 0, rng), "ambush": true}],
	]
	for s in screens:
		main.goto(s[0], s[1])
		await get_tree().process_frame
		await get_tree().process_frame
		check(main.get_child_count() == 2, "screen '%s' built" % s[0])
		var focus := get_viewport().gui_get_focus_owner()
		check(focus != null, "screen '%s' has a focused control for gamepad play" % s[0])
	Game.ship.hull = 0
	Game.check_game_over()
	main.goto("game_over")
	await get_tree().process_frame
	check(get_viewport().gui_get_focus_owner() != null, "game over screen focused")
	main.queue_free()
	Game.delete_save()


# --- Scripted playthrough: presses real buttons through the whole loop ---

var _main: Control


func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame


func _screen() -> String:
	return _main._current.get_script().resource_path.get_file().get_basename()


## Presses the button named `key` on the current screen. Returns false if absent.
func _press(key: String) -> bool:
	var b := _main._current.find_child(key, true, false) as Button
	if b == null:
		return false
	b.pressed.emit()
	await _frames()
	return true


## Plays out whatever encounter or fight is on screen until back in a system.
func _resolve() -> void:
	var guard := 0
	while guard < 300 and (_screen() == "encounter_screen" or _screen() == "combat_screen"):
		guard += 1
		Game.ship.hull = Game.ship.max_hull  # keep the run alive
		Game.crew.hands = maxi(Game.crew.hands, 4)
		for key in ["continue", "opt_leave", "opt_fight", "board", "charge", "fire"]:
			var b := _main._current.find_child(key, true, false) as Button
			if b and not b.disabled:
				await _press(key)
				break
	check(_screen() == "system_screen", "encounter resolves back to the system (on %s: %s hands=%d)" % [_screen(), Game.game_over_reason, Game.crew.hands])


func test_playthrough() -> void:
	Game.rng.seed = 12345
	Game.new_game(2024)
	Game.credits = 3000
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames()
	_main.goto("system")
	await _frames()

	# Scan and mine the home rocky planet.
	check(await _press("planet_0"), "planet button exists")
	check(await _press("scan"), "scan button exists")
	var mined := 0
	for i in 3:
		if _screen() != "system_screen":
			await _resolve()
		var before := Game.ship.cargo.count("iron")
		if await _press("extract_0"):
			mined += Game.ship.cargo.count("iron") - before
	await _resolve()
	check(mined > 0, "extracting puts iron in the hold")

	# Dock, trade, upgrade, train, hire.
	check(await _press("act_dock"), "dock button exists")
	check(_screen() == "starbase_screen", "docked")
	var credits := Game.credits
	check(await _press("sellall_iron"), "sell iron button exists")
	check(Game.credits > credits and Game.ship.cargo.count("iron") == 0, "selling iron pays credits")
	await _press("buy1_uranium")
	check(Game.ship.cargo.count("uranium") >= 1, "buying uranium")
	await _press("tab_1")
	Game.ship.cargo.add("hydrogen", 3)
	Game.ship.cargo.add("iron", 2)
	check(await _press("up_thrusters"), "upgrade button exists")
	check(Game.ship.level("thrusters") == 2, "thrusters upgraded via shipyard")
	Game.ship.hull -= 5
	await _press("repair")
	check(Game.ship.hull == Game.ship.max_hull, "hull repaired")
	await _press("tab_2")
	check(await _press("train_pilot"), "train button exists")
	check(Game.crew.skill("pilot") == 2, "pilot trained")
	var hands := Game.crew.hands
	await _press("hire")
	check(Game.crew.hands == hands + 1, "crew hired")
	await _press("tab_3")
	check(await _press("undock"), "undock button exists")
	check(_screen() == "system_screen", "undocked")
	Game.log_msg("message after the starbase was freed")
	await _frames()

	# Galaxy map and a jump.
	check(await _press("act_map"), "map button exists")
	var target: int = Game.reachable_stars()[0]
	check(await _press("jump_%d" % target), "jump button exists")
	check(Game.current_star == target, "jumped to target")
	await _resolve()

	# Each encounter kind, via its choices.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	Game.ship.cargo.add("organics", 4)
	Game.ship.fuel = 1
	await _encounter("trader", rng)
	check(await _press("opt_trade"), "trade option")
	var org := Game.ship.cargo.count("organics")
	await _press("sell1_organics")
	check(Game.ship.cargo.count("organics") == org - 1, "sold to trader")
	await _press("buy_fuel")
	check(Game.ship.fuel == 2, "bought fuel from trader")
	await _press("done")
	await _press("continue")
	check(_screen() == "system_screen", "trade finished")

	Game.bounties = 2
	Game.ship.fuel = 0
	await _encounter("patrol", rng)
	var cr := Game.credits
	await _press("opt_claim")
	check(Game.bounties == 0 and Game.credits == cr + 2 * Game.BOUNTY_PER_PIRATE, "bounties claimed from patrol")
	await _press("opt_fuel")
	check(Game.ship.fuel == 1, "patrol gave fuel")
	await _press("opt_leave")
	await _press("continue")

	Game.notoriety = 1
	await _encounter("patrol", rng)
	await _press("opt_fine")
	check(Game.notoriety == 0, "fine paid to patrol")
	await _press("continue")

	Game.ship.cargo.add("iron", 6)
	await _encounter("pirate", rng)
	await _press("opt_tribute")
	check(Game.ship.cargo.count("iron") <= 3, "tribute took cargo")
	await _press("continue")

	for opt in ["opt_intimidate", "opt_flee"]:
		await _encounter("pirate", rng)
		await _press(opt)
		await _resolve()
	await _encounter("monster", rng)
	await _press("opt_sneak")
	await _resolve()

	# A fight through the buttons, including every boarding choice.
	Game.ship.hull = Game.ship.max_hull
	Game.crew.hands = Game.crew.max_hands
	_main.goto("combat", {"encounter": Encounter.create("trader", 0, rng)})
	await _frames()
	await _press("evade")
	await _press("recharge")
	var used_retreat := false
	var used_hold := false
	var guard := 0
	while _main._current.find_child("continue", true, false) == null and guard < 200:
		guard += 1
		Game.ship.hull = Game.ship.max_hull
		var board := _main._current.find_child("board", true, false) as Button
		if _main._current.find_child("retreat", true, false):
			if not used_retreat:
				used_retreat = true
				await _press("retreat")
			elif not used_hold:
				used_hold = true
				await _press("hold")
			else:
				await _press("charge")
		elif board and not board.disabled:
			await _press("board")
		else:
			await _press("fire")
	check(used_retreat and used_hold, "boarding retreat and hold were exercised")
	await _press("continue")
	check(_screen() == "system_screen" or _screen() == "game_over_screen", "combat continues to the next screen")

	_main.queue_free()
	Game.delete_save()


func _encounter(kind: String, rng: RandomNumberGenerator) -> void:
	_main.goto("encounter", {"encounter": Encounter.create(kind, 0, rng)})
	await _frames()
