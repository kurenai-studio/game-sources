# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name CombatEngine
extends RefCounted
## Turn-based ship-to-ship combat and boarding, with no UI dependencies.
##
## Each call to act() or board() is one player turn followed by the enemy's
## reply. The screen reads `lines` (narration) and `events` (for effects)
## after every call, and stops once `over` is true.

## Player actions in ship combat.
const ACTIONS: Array[String] = ["fire", "evade", "recharge", "board", "flee"]
## Player actions while boarding.
const BOARD_ACTIONS: Array[String] = ["charge", "hold", "retreat"]

var ship: Ship
var crew: Crew
var enemy: Encounter
var rng: RandomNumberGenerator

var boarding := false
var over := false
## "", "destroyed", "boarded", "fled", "enemy_fled", "defeat"
var outcome := ""
var casualties := 0
var turn := 0
var lines: Array[String] = []
## Each: {"type": "shot", "by": "player"|"enemy", "hit": bool}
var events: Array[Dictionary] = []

var _evading := false


func _init(p_ship: Ship, p_crew: Crew, p_enemy: Encounter, p_rng: RandomNumberGenerator) -> void:
	ship = p_ship
	crew = p_crew
	enemy = p_enemy
	rng = p_rng


# --- Derived odds (shown on the buttons) ----------------------------------

func player_evasion() -> int:
	return 5 + 4 * ship.level("thrusters") + 4 * crew.skill("pilot") + (20 if _evading else 0)


func player_hit_chance() -> int:
	return clampi(65 + 5 * crew.skill("weapons") - enemy.evasion, 10, 95)


func enemy_hit_chance() -> int:
	return clampi(60 + 3 * enemy.danger - player_evasion(), 5, 95)


func flee_chance() -> int:
	return clampi(25 + 6 * crew.skill("pilot") + 6 * ship.level("thrusters") - 10 * enemy.speed, 5, 95)


func can_board() -> bool:
	return not over and enemy.boardable and enemy.shield <= 0


func board_reason() -> String:
	if not enemy.boardable:
		return "Can't board a creature"
	if enemy.shield > 0:
		return "Drop their shields first"
	return ""


# --- Ship combat -----------------------------------------------------------

## The enemy gets a free opening volley (after a failed escape or bluff).
func ambush() -> void:
	lines.clear()
	events.clear()
	lines.append("The %s opens fire first!" % enemy.title)
	_enemy_turn()


func act(action: String) -> void:
	lines.clear()
	events.clear()
	if over or boarding:
		return
	turn += 1
	match action:
		"fire":
			_player_fire()
		"evade":
			_evading = true
			lines.append("Pilot throws the ship into evasive manoeuvres.")
		"recharge":
			var before := ship.shield_points
			ship.shield_points = mini(ship.max_shield(), ship.shield_points + ship.shield_recharge())
			lines.append("Power diverted to shields (+%d)." % (ship.shield_points - before))
		"board":
			if not can_board():
				lines.append(board_reason() + ".")
				return
			boarding = true
			lines.append("Grapples away! Your crew storms the %s." % ("ship" if enemy.kind != "monster" else "beast"))
			return
		"flee":
			if rng.randi_range(1, 100) <= flee_chance():
				_finish("fled", "You punch the engines and leave them behind.")
				return
			lines.append("They match your burn. No escape this turn.")
	if not over:
		_enemy_turn()
	_evading = false


func _player_fire() -> void:
	var hit := rng.randi_range(1, 100) <= player_hit_chance()
	events.append({"type": "shot", "by": "player", "hit": hit})
	if not hit:
		lines.append("Your shot goes wide.")
		return
	var dmg := ship.weapon_damage() + rng.randi_range(0, crew.skill("weapons"))
	var absorbed := mini(enemy.shield, dmg)
	enemy.shield -= absorbed
	enemy.hull -= dmg - absorbed
	if absorbed > 0 and enemy.shield <= 0:
		lines.append("Hit for %d! Their shields collapse." % dmg)
	else:
		lines.append("Hit for %d damage." % dmg)
	if enemy.hull <= 0:
		enemy.hull = 0
		var verb := "is torn apart" if enemy.kind == "monster" else "breaks apart"
		_finish("destroyed", "The %s %s!" % [enemy.title, verb])


func _enemy_turn() -> void:
	if enemy.kind == "pirate" and enemy.hull * 10 < enemy.max_hull * 3 and rng.randf() < 0.35:
		_finish("enemy_fled", "The pirates break off and run for it.")
		return
	# A collapsed shield stays down, which is what opens the window to board.
	if enemy.shield_regen > 0 and enemy.shield > 0 and enemy.shield < enemy.max_shield:
		enemy.shield = mini(enemy.max_shield, enemy.shield + enemy.shield_regen)
	if enemy.kind == "monster" and rng.randf() < 0.2:
		events.append({"type": "shot", "by": "enemy", "hit": true})
		crew.hands -= 1
		casualties += 1
		lines.append("A tentacle rips through the hull and drags a crewmember away!")
		if crew.hands <= 0:
			_finish("defeat", "There is no one left aboard.")
		return
	var hit := rng.randi_range(1, 100) <= enemy_hit_chance()
	events.append({"type": "shot", "by": "enemy", "hit": hit})
	if not hit:
		lines.append("Enemy fire misses.")
		return
	var dmg := 2 * enemy.weapons + rng.randi_range(0, 2)
	var absorbed := mini(ship.shield_points, dmg)
	ship.shield_points -= absorbed
	ship.hull -= dmg - absorbed
	lines.append("You take %d damage%s." % [dmg, " (shields absorb %d)" % absorbed if absorbed > 0 else ""])
	if ship.hull <= 0:
		ship.hull = 0
		_finish("defeat", "Your hull gives way.")


# --- Boarding ---------------------------------------------------------------

func boarding_strength(charge: bool) -> int:
	return int(crew.hands / 2.0) + crew.skill("captain") + int(crew.skill("weapons") / 2.0) + (2 if charge else 0)


func enemy_boarding_strength() -> int:
	return int(enemy.hands / 2.0) + enemy.danger + 1


func board(action: String) -> void:
	lines.clear()
	events.clear()
	if over or not boarding:
		return
	turn += 1
	if action == "retreat":
		boarding = false
		lines.append("Your boarding party falls back to the airlock.")
		if rng.randf() < 0.5:
			_lose_hands(1)
		if not over:
			_enemy_turn()
		return
	var charge := action == "charge"
	var ours := boarding_strength(charge) + rng.randi_range(1, 6)
	var theirs := enemy_boarding_strength() + rng.randi_range(1, 6)
	if ours >= theirs:
		var kills := 2 if charge else 1
		enemy.hands = maxi(0, enemy.hands - kills)
		lines.append("Your crew pushes forward (%d vs %d); %d defender%s down." % [ours, theirs, kills, "s" if kills > 1 else ""])
		# A winning charge can cost a crewmember, but never the last one.
		if charge and crew.hands > 1 and rng.randf() < 0.4:
			_lose_hands(1)
	else:
		lines.append("The defenders hold (%d vs %d)." % [ours, theirs])
		_lose_hands(2 if charge else 1)
	if not over and enemy.hands <= 0:
		_finish("boarded", "The ship is yours! The survivors surrender.")


func _lose_hands(n: int) -> void:
	var lost := mini(n, crew.hands)
	crew.hands -= lost
	casualties += lost
	lines.append("%d of your crew fall%s." % [lost, "s" if lost == 1 else ""])
	if crew.hands <= 0:
		_finish("defeat", "Your last crewmember falls.")


func _finish(p_outcome: String, text: String) -> void:
	over = true
	boarding = false
	outcome = p_outcome
	lines.append(text)


func player_won() -> bool:
	return outcome == "destroyed" or outcome == "boarded"
