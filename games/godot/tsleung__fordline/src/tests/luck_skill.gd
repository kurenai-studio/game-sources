extends SceneTree
## Luck or skill? Fights one campaign battle many times, varying three
## things independently:
##   the commander - the player policies in POLICIES
##   the draw      - the map and the enemy roster swap (a run seed)
##   the dice      - the battle's own random numbers (reloads, scatter)
## and prints one ROW line of JSON per battle for tests/luck_skill.py.
##   Godot --headless --path . -s tests/luck_skill.gd -- --battle=2 --draws=6 --dice=3
## --policies=sharp,reserve fights only those. --scenario=hold fights a
## quick-battle scenario instead of a campaign battle (draws then only
## change a Skirmish's field and armies).

const K := UnitTypes.Kind


func _initialize() -> void:
	var battle_index := 0
	var draws := 6
	var dice := 3
	var chosen := PackedStringArray(Fights.POLICIES.keys())
	var scenario := ""
	var impact := 0
	for arg in OS.get_cmdline_user_args():
		var value := int(arg.get_slice("=", 1))
		if arg.begins_with("--battle="):
			battle_index = value
		elif arg.begins_with("--draws="):
			draws = value
		elif arg.begins_with("--dice="):
			dice = value
		elif arg.begins_with("--scenario="):
			scenario = arg.get_slice("=", 1)
		elif arg.begins_with("--policies="):
			chosen = arg.get_slice("=", 1).split(",")
		elif arg.begins_with("--impact="):
			impact = value
	for draw in draws:
		for die in dice:
			for policy in chosen:
				print("ROW ", JSON.stringify(_fight(battle_index, draw, die, policy, scenario, impact)))
	quit()


## One battle, its measures of play, and with `impact` > 0 that many of the
## player's orders taken out one at a time and the battle fought again.
func _fight(battle_index: int, draw: int, die: int, policy_name: String, scenario: String, impact: int) -> Dictionary:
	var make: Callable
	var enemy: Dictionary
	var spec := {}
	if scenario != "":
		spec = Scenarios.resolve(scenario, 1000 + draw)
		make = func() -> Battle: return Scenarios.make_battle(spec, 7919 * (die + 1))
		enemy = AI.PERSONAS[spec.persona]
	else:
		var run := Campaign.new_run(1000 + draw)
		run.battle = battle_index
		for i in battle_index:
			run = Campaign.apply_reward(run, {"id": "recruit", "kind": UnitTypes.RECRUITABLE[(i + draw) % 5]})
		make = func() -> Battle:
			var b := Campaign.make_battle(run)
			b.rng.seed = 7919 * (die + 1)
			return b
		enemy = AI.PERSONAS[Campaign.BATTLES[battle_index].persona]
	var fought := Fights.fight(make.call(), enemy, policy_name, impact > 0)
	var b := fought.battle
	var warned: Dictionary = Measures.warning(fought, 0)
	var row := {
		"battle": scenario if scenario != "" else battle_index, "draw": draw, "dice": die, "policy": policy_name,
		"stars": Scenarios.stars(spec, b) if scenario != "" else 0,
		"won": b.winner == 0, "margin": Measures.margin(b), "time": snappedf(b.time, 0.1),
		"lead_changes": fought.trace.lead.changes, "killed": b.killed,
		"flags": b.flags.map(func(f): return f.owner),
		"comeback": Measures.comeback(fought), "quiet": Measures.quiet_max(fought),
		"warning": warned.median, "unannounced": warned.unannounced,
		"orders_min": snappedf(Measures.orders_per_minute(fought, 0), 0.1),
	}
	if impact > 0:
		row.impact = Measures.impact(fought, make, Fights.seats.bind(enemy, policy_name), impact, 17 + die)
	return row
