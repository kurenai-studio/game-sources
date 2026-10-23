# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Node
## Global game state, autoloaded as "Game".
##
## Owns the ship, crew, wallet, galaxy and progress, and exposes every action
## that changes them (jumping, mining, trading, upgrading, encounter outcomes),
## so screens stay thin: they call a method here, then redraw.
## Actions that can fail return "" on success or a reason string.

signal state_changed
signal message_logged(text: String)

const SAVE_VERSION := 1
const START_CREDITS := 400
const MAX_MESSAGES := 40
const FUEL_PRICE := 20
const REPAIR_PRICE := 6
const BUY_MARKUP := 1.3
const FINE_PER_NOTORIETY := 250
const BOUNTY_PER_PIRATE := 150

## Tests and tools point this elsewhere so they never touch a real save.
var save_path := "user://starexplorer_save.json"
var rng := RandomNumberGenerator.new()
var galaxy: Galaxy
var ship: Ship
var crew: Crew
var credits := 0
var current_star := 0
## Rises when you attack traders or the Star Patrol; the Patrol hunts you.
var notoriety := 0
## Pirates defeated but not yet reported to the Star Patrol.
var bounties := 0
var visited: Dictionary = {}
var stats: Dictionary = {}
var messages: Array[String] = []
var game_over_reason := ""


func _ready() -> void:
	rng.randomize()


# --- Lifecycle -----------------------------------------------------------

func new_game(galaxy_seed: int = 0) -> void:
	if galaxy_seed == 0:
		galaxy_seed = rng.randi_range(1, 2147483646)
	galaxy = Galaxy.new()
	galaxy.generate(galaxy_seed)
	ship = Ship.new()
	crew = Crew.new()
	credits = START_CREDITS
	current_star = galaxy.start_star
	notoriety = 0
	bounties = 0
	visited = {current_star: true}
	stats = {
		"jumps": 0, "credits_earned": 0, "units_mined": 0,
		"pirates_defeated": 0, "monsters_slain": 0, "ships_boarded": 0,
	}
	messages.clear()
	game_over_reason = ""
	log_msg("The %s is fuelled and crewed. The galaxy awaits, Captain." % ship.ship_name)
	changed()


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> void:
	if game_over_reason != "":
		return
	var data := {
		"version": SAVE_VERSION,
		"galaxy": galaxy.to_dict(), "ship": ship.to_dict(), "crew": crew.to_dict(),
		"credits": credits, "current_star": current_star, "notoriety": notoriety,
		"bounties": bounties, "visited": visited.keys(), "stats": stats,
		"messages": messages,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) != SAVE_VERSION:
		return false
	galaxy = Galaxy.new()
	galaxy.from_dict(data["galaxy"])
	ship = Ship.new()
	ship.from_dict(data["ship"])
	crew = Crew.new()
	crew.from_dict(data["crew"])
	credits = int(data.get("credits", 0))
	current_star = clampi(int(data.get("current_star", 0)), 0, galaxy.stars.size() - 1)
	notoriety = int(data.get("notoriety", 0))
	bounties = int(data.get("bounties", 0))
	visited.clear()
	for id in data.get("visited", []):
		visited[int(id)] = true
	stats = {}
	var saved_stats: Dictionary = data.get("stats", {})
	for k in saved_stats:
		stats[k] = int(saved_stats[k])
	messages.clear()
	for m in data.get("messages", []):
		messages.append(str(m))
	game_over_reason = ""
	changed()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


func changed() -> void:
	state_changed.emit()


func log_msg(text: String) -> void:
	messages.append(text)
	if messages.size() > MAX_MESSAGES:
		messages.remove_at(0)
	message_logged.emit(text)


func recent_messages(n: int) -> Array[String]:
	return messages.slice(maxi(0, messages.size() - n))


func _stat(key: String, amount: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


func add_credits(amount: int) -> void:
	credits += amount
	if amount > 0:
		_stat("credits_earned", amount)


## Checks hull and crew; sets game_over_reason and wipes the save if dead.
func check_game_over() -> bool:
	if game_over_reason != "":
		return true
	if ship.hull <= 0:
		game_over_reason = "The %s was destroyed." % ship.ship_name
	elif crew.hands <= 0:
		game_over_reason = "The %s drifts on, crewless." % ship.ship_name
	if game_over_reason != "":
		delete_save()
		return true
	return false


func net_worth() -> int:
	var worth := credits
	for id in ship.cargo.items:
		worth += sell_price(id) * ship.cargo.count(id)
	return worth


# --- Navigation ----------------------------------------------------------

func system() -> StarSystem:
	return galaxy.get_system(current_star)


func star() -> Dictionary:
	return galaxy.star(current_star)


func reachable_stars() -> Array[int]:
	return galaxy.reachable_from(current_star, ship.jump_range())


func jump_to(star_id: int) -> String:
	if ship.fuel <= 0:
		return "No fuel"
	if galaxy.distance(current_star, star_id) > ship.jump_range():
		return "Out of range"
	ship.fuel -= 1
	current_star = star_id
	var first_visit := not visited.has(star_id)
	visited[star_id] = true
	_stat("jumps")
	log_msg("Jumped to %s%s." % [star()["name"], " (new system)" if first_visit else ""])
	changed()
	return ""


## Stranded with no fuel: the Star Patrol tows you to the nearest starbase
## and takes half your credits as a fee.
func distress_tow() -> void:
	var dest := galaxy.nearest_starbase(current_star)
	var fee := credits / 2
	credits -= fee
	current_star = dest
	visited[dest] = true
	ship.fuel = maxi(ship.fuel, 1)
	log_msg("Star Patrol tows you to %s. Towing fee: %d cr." % [star()["name"], fee])
	changed()


func can_refine_fuel() -> bool:
	return ship.cargo.count("hydrogen") >= 2 and ship.fuel < ship.max_fuel()


## Two units of hydrogen become one unit of jump fuel.
func refine_fuel() -> String:
	if not can_refine_fuel():
		return "Need 2 hydrogen and room in the tank"
	ship.cargo.remove("hydrogen", 2)
	ship.fuel += 1
	log_msg("Refined 2 hydrogen into 1 fuel.")
	changed()
	return ""


# --- Scanning and mining -------------------------------------------------

func scan_planet(planet: Planet) -> void:
	var sci := crew.skill("science")
	galaxy.mark_scanned(current_star, planet, sci)
	var found := 0
	for i in planet.deposits.size():
		if galaxy.deposit_visible(current_star, planet, i):
			found += 1
	var hidden := planet.deposits.size() - found
	var msg := "Scan of %s: %d deposit%s found." % [planet.planet_name, found, "" if found == 1 else "s"]
	if hidden > 0:
		msg += " Faint readings hint at more."
	log_msg(msg)
	changed()


func extraction_yield(planet: Planet, deposit_index: int) -> int:
	var diff: int = planet.deposits[deposit_index]["difficulty"]
	return maxi(1, 2 + crew.skill("engineer") - int(diff / 2.0))


## One extraction run. Returns the units mined (0 if nothing could be taken).
func extract(planet: Planet, deposit_index: int) -> int:
	var dep: Dictionary = planet.deposits[deposit_index]
	var want := mini(extraction_yield(planet, deposit_index), ship.cargo.free_space())
	var got := galaxy.extract(current_star, planet, deposit_index, want)
	ship.cargo.add(dep["res"], got)
	_stat("units_mined", got)
	if got > 0:
		log_msg("Extracted %d %s from %s." % [got, ResourceDB.name_of(dep["res"]), planet.planet_name])
	changed()
	return got


func roll_encounter(context: String) -> Encounter:
	return Encounter.roll(star(), context, notoriety, rng)


# --- Market --------------------------------------------------------------

func sell_price(id: String) -> int:
	return maxi(1, int(ResourceDB.base_price(id) * (0.9 + 0.05 * crew.skill("captain"))))


func buy_price(id: String) -> int:
	return int(ceil(ResourceDB.base_price(id) * BUY_MARKUP))


func sell(id: String, qty: int, unit_price: int = -1) -> int:
	if unit_price < 0:
		unit_price = sell_price(id)
	var sold := ship.cargo.remove(id, qty)
	if sold > 0:
		add_credits(sold * unit_price)
		log_msg("Sold %d %s for %d cr." % [sold, ResourceDB.name_of(id), sold * unit_price])
		changed()
	return sold


func sell_all() -> void:
	for id in ship.cargo.items.keys():
		sell(id, ship.cargo.count(id))


func buy(id: String, qty: int) -> String:
	var cost := buy_price(id) * qty
	if credits < cost:
		return "Not enough credits"
	if ship.cargo.free_space() < qty:
		return "Cargo hold full"
	credits -= cost
	ship.cargo.add(id, qty)
	log_msg("Bought %d %s for %d cr." % [qty, ResourceDB.name_of(id), cost])
	changed()
	return ""


# --- Shipyard ------------------------------------------------------------

func upgrade_block_reason(system_id: String) -> String:
	var reason := ship.upgrade_block_reason(system_id)
	if reason == "" and credits < ship.upgrade_cost(system_id)["credits"]:
		reason = "Not enough credits"
	return reason


func upgrade(system_id: String) -> String:
	var reason := upgrade_block_reason(system_id)
	if reason != "":
		return reason
	credits -= ship.upgrade_cost(system_id)["credits"]
	ship.apply_upgrade(system_id)
	log_msg("%s upgraded to level %d." % [Ship.SYSTEM_NAMES[system_id], ship.level(system_id)])
	changed()
	return ""


func repair_cost() -> int:
	return (ship.max_hull - ship.hull) * REPAIR_PRICE


func repair() -> String:
	var missing := ship.max_hull - ship.hull
	if missing <= 0:
		return "Hull is intact"
	var affordable := mini(missing, credits / REPAIR_PRICE)
	if affordable <= 0:
		return "Not enough credits"
	credits -= affordable * REPAIR_PRICE
	ship.hull += affordable
	log_msg("Repaired %d hull." % affordable)
	changed()
	return ""


func refuel_cost() -> int:
	return (ship.max_fuel() - ship.fuel) * FUEL_PRICE


func refuel() -> String:
	var missing := ship.max_fuel() - ship.fuel
	if missing <= 0:
		return "Tank is full"
	var affordable := mini(missing, credits / FUEL_PRICE)
	if affordable <= 0:
		return "Not enough credits"
	credits -= affordable * FUEL_PRICE
	ship.fuel += affordable
	log_msg("Bought %d fuel." % affordable)
	changed()
	return ""


# --- Crew ----------------------------------------------------------------

func train(role: String) -> String:
	if not crew.can_train(role):
		return "Already at max skill"
	var cost := crew.training_cost(role)
	if credits < cost:
		return "Not enough credits"
	credits -= cost
	crew.train(role)
	log_msg("%s trained to skill %d." % [Crew.ROLE_NAMES[role], crew.skill(role)])
	changed()
	return ""


func hire() -> String:
	if crew.hands >= crew.max_hands:
		return "Crew quarters full"
	if credits < Crew.HIRE_COST:
		return "Not enough credits"
	credits -= Crew.HIRE_COST
	crew.hands += 1
	log_msg("Hired a new crewmember.")
	changed()
	return ""


# --- Law and order -------------------------------------------------------

func fine_amount() -> int:
	return notoriety * FINE_PER_NOTORIETY


func pay_fine() -> String:
	if notoriety <= 0:
		return "Your record is clean"
	if credits < fine_amount():
		return "Not enough credits"
	credits -= fine_amount()
	notoriety = 0
	log_msg("Fines paid. Your record is clean.")
	changed()
	return ""


func claim_bounties() -> String:
	if bounties <= 0:
		return "No bounties to claim"
	var reward := bounties * BOUNTY_PER_PIRATE
	add_credits(reward)
	log_msg("Star Patrol pays %d cr for %d pirate%s." % [reward, bounties, "" if bounties == 1 else "s"])
	bounties = 0
	changed()
	return ""


# --- Encounter resolutions (non-combat) ----------------------------------

## Pirates take half of every cargo stack, or credits if the hold is empty.
func pay_tribute(enc: Encounter) -> String:
	if ship.cargo.is_empty():
		var demand := mini(credits, 100 + 50 * enc.danger)
		credits -= demand
		log_msg("The pirates take %d cr and leave." % demand)
	else:
		for id in ship.cargo.items.keys():
			ship.cargo.remove(id, int(ceil(ship.cargo.count(id) / 2.0)))
		log_msg("The pirates strip half your cargo and leave.")
	changed()
	return ""


func intimidate_chance(enc: Encounter) -> int:
	return clampi(15 + 12 * crew.skill("captain") + 6 * ship.level("weapons") - 10 * enc.danger, 5, 90)


func sneak_chance(enc: Encounter) -> int:
	return clampi(20 + 12 * crew.skill("science") + 4 * crew.skill("pilot") - 8 * enc.danger, 5, 90)


func roll_percent(chance: int) -> bool:
	return rng.randi_range(1, 100) <= chance


## Applies loot, reputation, medical and repair effects after a battle.
## Returns lines describing what happened.
func apply_combat_outcome(engine: CombatEngine) -> Array[String]:
	var out: Array[String] = []
	var enc := engine.enemy
	if engine.outcome == "defeat":
		check_game_over()
		return out

	# The doctor patches up some of the fallen.
	if engine.casualties > 0:
		var saved := 0
		for i in engine.casualties:
			if rng.randf() < 0.12 * crew.skill("doctor"):
				saved += 1
		saved = mini(saved, crew.max_hands - crew.hands)
		if saved > 0:
			crew.hands += saved
			out.append("The doctor saves %d of the wounded." % saved)
	if check_game_over():
		return out

	if engine.player_won():
		var share := 1.0 if engine.outcome == "boarded" else 0.5
		var cash := int(enc.loot_credits * share)
		if cash > 0:
			add_credits(cash)
			out.append("Salvaged %d credits." % cash)
		for id in enc.loot_cargo:
			var qty := int(ceil(enc.loot_cargo[id] * share))
			var got := ship.cargo.add(id, qty)
			if got > 0:
				out.append("Took %d %s." % [got, ResourceDB.name_of(id)])
			if got < qty:
				out.append("No room for %d %s." % [qty - got, ResourceDB.name_of(id)])
		match enc.kind:
			"pirate":
				bounties += 1
				_stat("pirates_defeated")
				out.append("Bounty logged for the Star Patrol.")
			"monster":
				_stat("monsters_slain")
		if engine.outcome == "boarded":
			_stat("ships_boarded")

	# The engineer patches the hull and the shields come back up.
	var fixed := mini(crew.skill("engineer"), ship.max_hull - ship.hull)
	if fixed > 0:
		ship.hull += fixed
		out.append("Engineer patches %d hull." % fixed)
	ship.shield_points = ship.max_shield()
	for line in out:
		log_msg(line)
	changed()
	return out


## Firing on a lawful ship raises notoriety whether or not you win.
func attack_lawful(enc: Encounter) -> void:
	if enc.kind == "trader":
		notoriety += 1
	elif enc.kind == "patrol":
		notoriety += 2
	else:
		return
	log_msg("You open fire on the %s. Notoriety is now %d." % [enc.title, notoriety])
	changed()
