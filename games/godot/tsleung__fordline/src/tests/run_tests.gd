extends SceneTree
## Headless checks: the rules, the maps, the campaign, and whole battles
## fought AI against AI.
##   godot --headless --path . -s tests/run_tests.gd [-- --quick]

const K := UnitTypes.Kind

var _failures := 0
## Lead changes in the last battle _fight fought.
var _lead_changes := 0
var _checks := 0
## This run's recorded battles, key -> line, compared at the end with the
## recordings for the platform the suite runs on. Battles are deterministic
## on one platform, but the last bits of the maths library differ between
## platforms, and in a battle this sensitive those bits grow into a
## different battle; so each platform keeps its own recording.
var _golden := {}
var _golden_path := "res://tests/golden-%s.txt" % OS.get_name().to_lower()
## Budgets for the largest battle's step, in microseconds: the mean, and the
## slowest one in a hundred.
const STEP_BUDGET_MEAN := 4000
const STEP_BUDGET_P99 := 20000


func _initialize() -> void:
	_run()


## A coroutine, because the screen test needs a frame for its nodes to
## enter the tree.
func _run() -> void:
	var quick := "--quick" in OS.get_cmdline_user_args()
	_test_combat()
	_test_terrain()
	_test_fortress()
	_test_campaign()
	await _test_routes()
	await _test_screens()
	_test_scenarios()
	await _test_grand(quick)
	_test_replay()
	_test_battles(quick)
	if not quick:
		_test_budget()
	_compare_golden("--record" in OS.get_cmdline_user_args())
	print("\n%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		print("FAIL: ", what)


func _test_combat() -> void:
	_check(Combat.type_mult(K.PIKES, K.CAVALRY) == 2.5, "pikes beat cavalry")
	_check(Combat.type_mult(K.SWORDS, K.PIKES) == 1.5, "swords beat pikes")
	_check(Combat.type_mult(K.CAVALRY, K.ARCHERS) > 1.0, "cavalry beats archers")
	var facing_up := -PI * 0.5
	_check(Combat.zone(Vector2.ZERO, facing_up, Vector2(0, -50)) == Combat.Zone.FRONT, "front zone")
	_check(Combat.zone(Vector2.ZERO, facing_up, Vector2(50, 0)) == Combat.Zone.SIDE, "side zone")
	_check(Combat.zone(Vector2.ZERO, facing_up, Vector2(0, 50)) == Combat.Zone.REAR, "rear zone")
	_check(not Combat.charge_lands(K.PIKES, Combat.Zone.FRONT), "pikes brace a frontal charge")
	_check(Combat.charge_lands(K.PIKES, Combat.Zone.REAR), "pikes caught from behind")
	var front := Combat.melee_dps(K.SWORDS, 32, 8, 1.0, K.SWORDS, 0.3, Combat.Zone.FRONT, false)
	var rear := Combat.melee_dps(K.SWORDS, 32, 8, 1.0, K.SWORDS, 0.3, Combat.Zone.REAR, false)
	_check(is_equal_approx(rear / front, 2.2), "rear hits 2.2x")
	_check(Combat.fighting_men(32, 8) == 16, "two ranks fight")
	_check(Combat.stars_for_kills(0) == 0 and Combat.stars_for_kills(60) == 3, "stars from kills")
	_check(Combat.fatigue_hit(1.0) == 1.0 and Combat.fatigue_hit(0.0) == Combat.SPENT_HIT, "spent regiments hit softer")
	_check(Combat.fatigue_nerve(0.0) > Combat.fatigue_nerve(1.0), "spent regiments break sooner")
	_check(_duel(1.0, 1.0) == "even", "fresh against fresh is even")
	_check(_duel(1.0, 0.2) == "first", "fresh swords beat tired swords")
	_test_muskets()
	_test_squares()
	_test_fixes()


## A volley of shot goes through armour, drops men all at once, and costs
## its target more nerve than the men alone.
func _test_muskets() -> void:
	_check(is_equal_approx(Combat.pierced(0.3, 0.7), 0.09), "shot goes through most armour")
	_check(Combat.type_mult(K.CAVALRY, K.MUSKETS) > 1.0, "cavalry rides down muskets")
	var t := Terrain.generate("woods", 1)
	t.forests.clear()
	t.hills.clear()
	var battle := Battle.new(t, 1)
	var mid := Terrain.SIZE * 0.5
	battle.add_regiment(0, K.MUSKETS, 40, mid + Vector2(0, 75), -PI * 0.5, 0, {})
	var block := battle.add_regiment(1, K.PIKES, 48, mid - Vector2(0, 75), PI * 0.5, 0, {})
	battle.begin()
	while block.men() == block.men_max and battle.time < 20.0:
		battle.step(Battle.STEP)
	var lost := block.men_max - block.men()
	_check(lost >= 3, "one volley drops several pikemen at once")
	_check(block.morale_max - block.morale > Combat.loss_morale(lost, block.men_max) + 4.0, "a volley shakes more than its losses")


## Two sword regiments meet head on, the first with stamina a, the second
## with stamina b, on open ground; which breaks first?
func _duel(a: float, b: float) -> String:
	var t := Terrain.generate("woods", 1)
	t.forests.clear()
	t.hills.clear()
	var battle := Battle.new(t, 1)
	var mid := Terrain.SIZE * 0.5
	var first := battle.add_regiment(0, K.SWORDS, 48, mid + Vector2(0, 30), -PI * 0.5, 0, {})
	var second := battle.add_regiment(1, K.SWORDS, 48, mid - Vector2(0, 30), PI * 0.5, 0, {})
	first.stamina = a
	second.stamina = b
	battle.begin()
	while battle.time < 120.0:
		battle.step(Battle.STEP)
		var first_broke := not first.fighting()
		var second_broke := not second.fighting()
		if first_broke and second_broke:
			return "even"
		if second_broke:
			return "first"
		if first_broke:
			return "second"
	return "even"


func _test_terrain() -> void:
	for kind in ["fords", "woods", "bridges", "roads", "ridge"]:
		for s in 6:
			var t := Terrain.generate(kind, 1000 + s)
			var tag := "%s/%d" % [kind, s]
			_check(t.flags.size() == 3, tag + " has three flags")
			for f in t.flags:
				_check(not t.is_water(f), tag + " flag on dry ground or a crossing")
			var from := Vector2(Terrain.SIZE.x * 0.3, Terrain.SIZE.y - 100.0)
			var to := Vector2(Terrain.SIZE.x * 0.7, 100.0)
			var way := t.path(from, to)
			_check(way[way.size() - 1].distance_to(to) < 1.0, tag + " path ends at the goal")
			if t.has_river:
				var dry := true
				var last := from
				for w in way:
					for i in 40:
						if t.is_water(last.lerp(w, i / 40.0)):
							dry = false
					last = w
				_check(dry, tag + " path never wades except at a crossing")
				var banks := 0
				for i in way.size() - 1:
					if t.side(way[i]) != t.side(way[i + 1]):
						banks += 1
						_check(not t.crossing_at(way[i].x).is_empty(), tag + " river crossed at a crossing")
				_check(banks == 1, tag + " path crosses the river once")
			var b := Battle.new(t, s)
			for k in [K.SWORDS, K.PIKES, K.ARCHERS, K.CAVALRY, K.CANNONS, K.GENERAL, K.SWORDS, K.SWORDS]:
				b.add_regiment(0, k, 40, Terrain.SIZE * 0.5, 0.0, 0, {})
				b.add_regiment(1, k, 40, Terrain.SIZE * 0.5, 0.0, 0, {})
			b.apply_orders(AI.deploy_orders(b, 0))
			b.apply_orders(AI.deploy_orders(b, 1))
			for r in b.regiments:
				_check(t.in_deploy(r.team, r.pos) or t.clamp_deploy(r.team, r.pos) == r.pos, tag + " deployed inside the zone")
				_check(not t.is_water(r.pos), tag + " deployed on dry ground")


func _test_campaign() -> void:
	var run := Campaign.new_run(42)
	_check(run.roster.size() == 7, "starting roster is the general and six regiments")
	_check(Campaign.enemy_army(run).size() == 6, "first enemy is the general and five regiments")
	var picks := Campaign.offer_rewards(run)
	_check(picks.size() == 3, "three rewards on offer")
	_check(picks.any(func(p): return p.id == "recruit"), "a recruit is always on offer")
	var titles := {}
	for p in picks:
		titles[p.title] = true
	_check(titles.size() == 3, "rewards are distinct")
	var units: Array = []
	for i in run.roster.size():
		units.append({"roster_index": i, "men": 10 if i == 1 else run.roster[i].men, "kills": 15 if i == 1 else 0, "fled": false})
	units.remove_at(2)
	var after := Campaign.after_battle(run, {"won": true, "time": 120.0, "kills": 40, "units": units})
	_check(after.roster.size() == 6, "a destroyed regiment leaves the roster")
	var full: int = UnitTypes.stat(K.SWORDS, "men")
	_check(after.roster[1].men == 10 + int(ceil((full - 10) * Campaign.REFILL)), "losses refill by 40%")
	_check(after.roster[1].stars == 1, "kills earn a star")
	var survivors := 0
	for u in units:
		survivors += u.men
	_check(after.score == 1000 + 2 * 40 + survivors + 60 * 3, "score counts win, kills, survivors, speed")
	_check(run.roster.size() == 7, "after_battle leaves the old run alone")
	var drilled := Campaign.apply_reward(after, {"id": "doctrine", "name": "drill"})
	_check(is_equal_approx(drilled.doctrine["atk_0"], 1.12), "drill raises sword attack")
	_check(not after.doctrine.has("atk_0"), "apply_reward leaves the old run alone")
	var lost := Campaign.after_battle(run, {"won": false, "time": 200.0, "kills": 5, "units": units})
	_check(lost.over and not lost.won, "a defeat ends the run")


## Waypoints through the real battle screen: tap a regiment, tap the
## field, tap the route's end to pin it, tap again; the route runs through
## the first stop to the second. Without the pin a tap replaces the route;
## shift-click appends.
func _test_routes() -> void:
	var screen = preload("res://scripts/battle_screen.gd").new()
	screen.setup(Campaign.make_battle(Campaign.new_run(9)), "dug_in", "routes")
	root.add_child(screen)
	await process_frame
	screen.begin_battle()
	var r: Regiment = screen.battle.team_regiments(0).filter(func(x): return x.kind == K.SWORDS)[0]
	var first: Vector2 = r.pos + Vector2(-140.0, -30.0)
	var second: Vector2 = r.pos + Vector2(-260.0, 20.0)
	_tap(screen, r.pos)
	_check(screen.selected == [r.id], "tapping a banner selects it")
	# A tap on the top bar, through the real input path (in the viewport's
	# own coordinates), is not an order.
	var before_route: Vector2 = screen.route_end(r)
	for pressed in [true, false]:
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = pressed
		tap.position = Vector2(400, 12)
		root.push_input(tap, true)
	await process_frame
	# No route before, none after: route_end is NaN both times.
	_check(str(screen.route_end(r)) == str(before_route) and screen.selected == [r.id], "a tap on the top bar sends no one anywhere")
	_tap(screen, first)
	_check(screen.route_end(r).distance_to(first) < 1.0, "tapping the field sends it there")
	_tap(screen, first)
	_check(screen.pinned, "tapping the route's end pins it")
	_tap(screen, second)
	_check(not screen.pinned, "the next tap uses the pin up")
	_check(screen.route_end(r).distance_to(second) < 1.0, "the pinned route ends at the new stop")
	_check(Array(r.waypoints).any(func(w): return w.distance_to(first) < 1.0), "the pinned route still goes through the first stop")
	_tap(screen, first)
	_check(not Array(r.waypoints).any(func(w): return w.distance_to(second) < 1.0), "a tap without the pin replaces the route")
	screen._press(screen.to_screen(second), false, true)
	screen._release(screen.to_screen(second))
	_check(screen.route_end(r).distance_to(second) < 1.0 and Array(r.waypoints).any(func(w): return w.distance_to(first) < 1.0), "shift-click adds a stop")
	# A drag is an arrow: stand where it starts, face the way it points,
	# whichever side the enemy is on.
	var spot: Vector2 = r.pos + Vector2(0.0, -150.0)
	screen._select([r.id] as Array[int])
	_drag(screen, spot, spot + Vector2(0.0, 90.0))
	_check(screen.route_end(r).distance_to(spot) < 1.0, "a drag on the field sends the selection to where it starts")
	_check(absf(angle_difference(r.final_facing, PI * 0.5)) < 0.01, "and faces it the way the drag points, even away from the enemy")
	_drag(screen, r.pos, r.pos + Vector2(90.0, 0.0))
	_check(absf(angle_difference(r.final_facing, 0.0)) < 0.01, "a drag from its own banner turns it")
	var pair: Array[int] = [r.id, screen.battle.team_regiments(0).filter(func(x): return x.kind == K.PIKES)[0].id]
	screen._select(pair)
	var slots: Array = screen.arrow_slots(spot, spot + Vector2(90.0, 0.0))
	_check(slots.size() == 2 and absf(slots[0][1].x - spot.x) < 0.01 and absf(slots[1][1].x - spot.x) < 0.01, "a group forms side by side across the arrow")
	# The menu stops the battle, gives the pause back, and leaving is
	# announced for whoever started the battle to act on.
	var was: float = screen.battle.time
	screen.open_menu()
	screen._process(0.5)
	_check(screen.battle.time == was, "the menu stops the battle")
	screen.close_menu()
	_check(not screen.paused, "closing the menu resumes")
	_check(screen.leaving_costs(), "leaving a campaign battle in progress is a retreat")
	var heard := [false]
	screen.left.connect(func(): heard[0] = true)
	screen.leave()
	_check(heard[0], "leaving is announced")
	screen.free()
	# Guns selected, a tap on the enemy's gate: they batter it, and the
	# foot selected with them march on it.
	var siege = preload("res://scripts/battle_screen.gd").new()
	var spec := Scenarios.resolve("storm", 1)
	siege.setup(Scenarios.make_battle(spec, 1), spec.persona, spec.name)
	root.add_child(siege)
	await process_frame
	siege.begin_battle()
	var gun: Regiment = siege.battle.team_regiments(0).filter(func(x): return x.kind == K.CANNONS)[0]
	var foot: Regiment = siege.battle.team_regiments(0).filter(func(x): return x.kind == K.SWORDS)[0]
	siege._select([gun.id, foot.id] as Array[int])
	_tap(siege, siege.battle.terrain.gates[0].c)
	_check(gun.target_gate == 0, "tapping a gate with guns selected batters it")
	_check(foot.waypoints.size() > 0 and siege.route_end(foot).distance_to(siege.battle.terrain.gates[0].c) < 60.0, "the foot with them march on the gate")
	siege.free()


func _drag(screen, from_world: Vector2, to_world: Vector2) -> void:
	screen._press(screen.to_screen(from_world), false, false)
	screen._release(screen.to_screen(to_world))


func _tap(screen, world_pos: Vector2) -> void:
	var sp: Vector2 = screen.to_screen(world_pos)
	screen._press(sp, false, false)
	screen._release(sp)


## The real screens, built and shown in turn; any script error in them
## fails the suite through test.sh.
func _test_screens() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save_path = "user://test_screens.cfg"
	DirAccess.remove_absolute(main.save_path)
	root.add_child(main)
	await process_frame
	for step in [
		func(): main.show_scenarios(),
		func(): main.show_scenarios("pike_shot"),
		func(): main.show_scenario("skirmish_shot"),
		func(): main.show_scenarios(),
		func(): main.show_scenario("skirmish"),
		func(): main.show_scenario("bridges", 3),
		func(): main._start_run(),
		func(): main.show_title(),
	]:
		step.call()
		await process_frame
		await process_frame
	_check(main.get_child_count() == 1, "one screen on stage after walking the screens")
	_check(main._load("ui", "era", "") == "pike_shot", "the scenario list remembers its era")
	main.free()
	DirAccess.remove_absolute("user://test_screens.cfg")


## The castle: routes go round stone and through gates, a shut gate stops
## the besieger until it is battered down, no blades cross a wall, and the
## wall-walk gives height and cover.
## Napoleonic line infantry forms square against horse while it stands:
## no flank, a charge that doesn't land, and horse that does little; it
## forms line to march, and horse that reaches it first catches it in line.
func _test_squares() -> void:
	var b := Battle.new(Terrain.generate("woods", 4), 1)
	var foot := b.add_regiment(0, K.LINE, 40, Vector2(650, 500), -PI * 0.5, 0, {})
	var horse := b.add_regiment(1, K.CAVALRY, 24, Vector2(650, 290), PI * 0.5, 0, {})
	b.begin()
	b.step(Battle.STEP)
	_check(foot.square and b.take_events().any(func(e): return e.type == "square"), "line infantry forms square as horse comes near")
	_check(absf(foot.width() - foot.depth()) < 0.01 and foot.formation_cols(40) == 10, "a square is as deep as it is wide, ten men a face")
	b.apply_orders([{"type": "attack", "id": horse.id, "target": foot.id}])
	var charged := false
	var lost := 0
	for i in 150:
		b.step(Battle.STEP)
		charged = charged or b.take_events().any(func(e): return e.type == "charge")
	lost = 40 - foot.men()
	_check(not charged, "a charge doesn't land on a square")
	_check(lost < 8, "horse can't break into a square (lost %d of 40)" % lost)
	b.apply_orders([{"type": "move", "id": foot.id, "to": Vector2(650, 700)}])
	b.step(Battle.STEP)
	_check(not foot.square, "a square forms line again to march")
	var caught := Battle.new(Terrain.generate("woods", 4), 1)
	var line := caught.add_regiment(0, K.LINE, 40, Vector2(650, 500), -PI * 0.5, 0, {})
	caught.add_regiment(1, K.CAVALRY, 24, Vector2(650, 470), PI * 0.5, 0, {})
	caught.begin()
	caught.step(Battle.STEP)
	_check(not line.square, "horse already on a line catches it before it can form square")


## Bugs found and fixed, each kept fixed.
func _test_fixes() -> void:
	# A general who breaks and is then cut down is mourned once.
	var b := Battle.new(Terrain.generate("woods", 4), 1)
	var general := b.add_regiment(0, K.GENERAL, 10, Vector2(650, 500), -PI * 0.5, 0, {})
	b.add_regiment(1, K.SWORDS, 48, Vector2(650, 300), PI * 0.5, 0, {})
	b.begin()
	b._rout(general)
	var after_rout: float = b.resolve[0]
	b._kill(general, range(general.men()), null, 1.0)
	_check(b.take_events().filter(func(e): return e.type == "general").size() == 1, "a general who routed and then fell is mourned once")
	_check(after_rout - b.resolve[0] <= Battle.DESTROYED_COST + 0.01, "and his death costs only what a routed regiment's does")
	# Two Narrow Bridges needs both bridges, not a bridge and the field.
	var spec := Scenarios.resolve("bridges", 1)
	for held in [[0, 1], [1, 2]]:
		var dusk := Scenarios.make_battle(spec, 1)
		dusk.begin()
		for i in dusk.flags.size():
			dusk.flags[i].owner = 0 if i in held else 1
		dusk.time = dusk.deadline
		dusk.step(Battle.STEP)
		var won := dusk.broken_team == 1
		_check(won == (held == [1, 2]), "holding flags %s at dusk %s Two Narrow Bridges" % [held, "wins" if won else "loses"])


func _test_fortress() -> void:
	var t := Terrain.generate("fortress", 3)
	var outside := Vector2(650, 700)
	var keep_flag: Vector2 = t.flags[2]
	var way := t.path(outside, keep_flag)
	var at := outside
	var crosses_stone := false
	var by_gate := [false, false]
	for w in way:
		for k in 40:
			var q := at.lerp(w, k / 39.0)
			crosses_stone = crosses_stone or t.walled(q, t.holder)
			for g in 2:
				by_gate[g] = by_gate[g] or q.distance_to(t.gates[g].c) < 30.0
		at = w
	_check(not crosses_stone, "a route into the keep never crosses stone")
	_check(by_gate[0] and by_gate[1], "a route into the keep runs through both gates")
	_check(way[way.size() - 1].distance_to(keep_flag) < 1.0, "a route into the keep ends where it was sent")
	_check(t.walled(t.gates[0].c, 0) and not t.walled(t.gates[0].c, 1), "a gate is shut to the besieger and open to the garrison")
	var post := t.posts[0]
	_check(t.on_rampart(post) and t.height(post) == 1.0 and t.cover(post) == Terrain.BATTLEMENTS, "the wall-walk gives height and cover")
	_check(t.is_water(t.gates[0].c + t.gates[0].out * 36.0 + Vector2(80, 0)) and not t.is_water(t.gates[0].c + t.gates[0].out * 36.0), "the moat has a bridge at the gate")
	var held := Terrain.generate("fortress_held", 3)
	_check(held.inside(Vector2(650, Terrain.SIZE.y - 190)) and not held.inside(Vector2(650, 190)), "a castle can be the player's, at the south edge")

	# One regiment of swords sent at the gate: it stops there, rams it
	# down, and goes in.
	var b := Battle.new(Terrain.generate("fortress", 3), 1)
	var sword := b.add_regiment(0, K.SWORDS, 48, Vector2(650, 560), -PI * 0.5, 0, {})
	b.add_regiment(1, K.GENERAL, 10, Vector2(650, 160), PI * 0.5, 0, {})
	b.begin()
	b.apply_orders([{"type": "move", "id": sword.id, "to": Vector2(650, 330)}])
	var got_in_early := false
	while not b.terrain.gate_broken[0] and b.time < 240.0:
		b.step(Battle.STEP)
		got_in_early = got_in_early or b.terrain.inside(sword.pos)
	_check(not got_in_early, "a shut gate keeps the besieger out")
	_check(b.terrain.gate_broken[0] and b.time > 60.0, "one regiment rams the gate down, slowly (%ds)" % int(b.time))
	b.apply_orders([{"type": "move", "id": sword.id, "to": Vector2(650, 330)}])
	for i in 600:
		b.step(Battle.STEP)
	_check(b.terrain.inside(sword.pos), "through the broken gate")

	# Swords either side of the curtain wall can't fight; guns can batter
	# the gate, but not their own side's.
	var w := Battle.new(Terrain.generate("fortress", 3), 1)
	var out_sword := w.add_regiment(0, K.SWORDS, 48, Vector2(400, 448), -PI * 0.5, 0, {})
	var in_sword := w.add_regiment(1, K.SWORDS, 48, Vector2(400, 414), PI * 0.5, 0, {})
	var gun := w.add_regiment(0, K.CANNONS, 12, Vector2(650, 760), -PI * 0.5, 0, {})
	var own_gun := w.add_regiment(1, K.CANNONS, 12, Vector2(650, 300), PI * 0.5, 0, {})
	w.begin()
	w.apply_orders([{"type": "bombard", "id": gun.id, "gate": 0}, {"type": "bombard", "id": own_gun.id, "gate": 0}])
	_check(own_gun.target_gate < 0, "a garrison's guns won't batter their own gate")
	w.step(Battle.STEP)
	_check(out_sword.pos.distance_to(in_sword.pos) < 40.0 and out_sword.contacts.is_empty(), "no blades cross a wall")
	for i in 30 * 30:
		w.step(Battle.STEP)
	_check(w.gate_hp[0] < w.terrain.gates[0].hp, "guns batter a gate")


## Every scenario builds, deploys on dry ground and finishes in time with
## the AI as the player; the hold scenario's clock decides on the flags.
func _test_scenarios() -> void:
	for spec in Scenarios.LIST:
		for s in [1, 2]:
			var resolved := Scenarios.resolve(spec.id, s)
			var b := Scenarios.make_battle(resolved, s)
			for r in b.regiments:
				_check(not b.terrain.is_water(r.pos), "%s deploys on dry ground" % spec.id)
				_check(not b.terrain.walled(r.pos, r.team), "%s deploys clear of walls" % spec.id)
				_check(b.terrain.inside(r.pos) == (r.team == b.terrain.holder), "%s deploys on its own side of the walls" % spec.id)
			var ok := _fight(b, true, resolved.persona, "scenario/%s/%d" % [spec.id, s])
			print("  scenario %-9s seed %d  %-14s %3ds  stars %d  lead changes %d" % [
				spec.id, s, "player won" if b.winner == 0 else "enemy won", int(b.time),
				Scenarios.stars(resolved, b), _lead_changes])
			_check(ok, "%s ends within the time limit" % spec.id)
			if resolved.get("deadline", 0.0) > 0.0:
				_check(b.time <= resolved.deadline + Battle.BREAK_DELAY + 0.5, "%s ends by its deadline" % spec.id)
	var sk1 := Scenarios.resolve("skirmish", 1)
	_check(sk1.player == sk1.enemy, "a skirmish's armies are the same")
	var held := Scenarios.make_battle(Scenarios.resolve("hold", 1), 1)
	_check(held.flags_held(0) == 3, "hold starts with every ford ours")
	var front := INF
	for r in held.team_regiments(0):
		front = minf(front, r.pos.y)
	_check(front < Terrain.SIZE.y - Terrain.DEPLOY_DEPTH, "hold deploys forward of the usual zone")
	held.begin()
	while held.phase == "battle":
		held.step(Battle.STEP)
	# Holding all three drains them, so an enemy that never comes breaks
	# before the clock does.
	_check(held.winner == 0 and held.time <= held.deadline + Battle.BREAK_DELAY, "an enemy that never comes loses the fords' race")


## Fight every campaign battle AI against AI, the player's army growing by
## one regiment a battle as it would with rewards.
## A grand battle: the hand-drawn field, armies arriving by road, the
## division AI, dusk deciding it, and the camera over a field bigger than
## the screen. The full suite also fights the whole day AI against AI.
func _test_grand(quick: bool) -> void:
	var spec := Scenarios.resolve("gettysburg", 1)
	var b := Scenarios.make_battle(spec, 1)
	var t := b.terrain
	var flag := func(i: int) -> Vector2: return Gettysburg.FLAGS[i].at
	_check(t.size == Vector2(3200, 2200) and t.flag_names.size() == 6, "Gettysburg's field is its own size, with named flags")
	_check(t.height(flag.call(Gettysburg.CEMETERY)) > 0.9 and t.height(Vector2(1610, 700)) > 0.9, "Cemetery Hill and the crest of Seminary Ridge stand high")
	_check(t.height(Vector2(1450, 1000)) < 0.3, "the low ground between the ridges is low")
	_check(t.in_town(flag.call(Gettysburg.TOWN)) and t.cover(flag.call(Gettysburg.TOWN)) == 0.5, "the town gives cover")
	_check(t.speed_mult(Vector2(1135, 600)) < 0.6, "wading Willoughby Run is slow")
	_check(t.path(Vector2(300, 300), Vector2(2900, 2000)).size() == 1, "an open field routes straight")
	_check(spec == Scenarios.resolve("gettysburg", 1) and b.regiments.size() == 8, "the day opens with Buford and Heth's van only")
	var muster: Vector2 = Gettysburg.EMMITSBURG_ROAD.back()
	b.begin()
	while b.time < (10.0 - 8.0) * Gettysburg.HOUR + 1.0:
		b.step(Battle.STEP)
	var arrived := b.team_regiments(0).filter(func(r): return r.formation == "Wadsworth's Division")
	_check(arrived.size() == 3 and arrived.any(func(r): return r.name == "the Iron Brigade"), "Wadsworth's division comes up at 10:00, named")
	_check(b.take_events().any(func(e): return e.type == "arrival" and e.formation == "Wadsworth's Division"), "its arrival is announced")
	_check(arrived.all(func(r): return r.waypoints[r.waypoints.size() - 1].distance_to(muster) < 150.0), "it marches to muster at the end of its road")
	# A division's objectives in order: the next once it holds the last.
	var heth := PackedVector2Array([flag.call(Gettysburg.MCPHERSON), flag.call(Gettysburg.SEMINARY)])
	_check(AI._objective(b, 1, heth) == heth[0], "a division goes for its first objective")
	b.flags[Gettysburg.MCPHERSON].owner = 1
	_check(AI._objective(b, 1, heth) == heth[1], "and on to the next once it holds it")
	# Coming from the west, a division's blocks stand north and south of
	# each other, not one behind another.
	var west: Array[Regiment] = []
	for y in [900.0, 1100.0]:
		west.append(b.add_regiment(1, K.RIFLES, 40, Vector2(300, y), 0.0, 0, {}))
	var spots := west.map(func(r): return AI._division_spot(b, 1, r, west, Vector2(1300, 1000)))
	_check(absf(spots[0].x - spots[1].x) < 1.0 and absf(spots[0].y - spots[1].y) >= AI.DIVISION_GAP - 1.0, "a division forms square to its approach")
	# Dusk decides on Cemetery Hill alone.
	for team in 2:
		var dusk := Scenarios.make_battle(spec, 1)
		dusk.begin()
		for f in dusk.flags:
			f.owner = 1
		dusk.flags[Gettysburg.CEMETERY].owner = team
		dusk.time = dusk.deadline
		dusk.step(Battle.STEP)
		_check(dusk.broken_team == 1 - team, "at dusk the side without Cemetery Hill is beaten (%d holds it)" % team)
	# The camera: zoom kept in range, the view on the field, the point
	# under a pinch kept still, and a double-tap taking the division.
	var screen = preload("res://scripts/battle_screen.gd").new()
	screen.setup(Scenarios.make_battle(spec, 1), spec.persona, spec.name)
	screen.grand = true
	screen.cam_centre = spec.view
	root.add_child(screen)
	await process_frame
	_check(screen.battle.phase == "battle" and screen.paused, "a grand battle opens under way and paused")
	var probe := Vector2(1200, 900)
	_check(screen.to_world(screen.to_screen(probe)).distance_to(probe) < 0.01, "screen and field positions round-trip")
	var under: Vector2 = screen.to_screen(probe)
	screen.zoom_at(under, 1.3)
	_check(screen.to_world(under).distance_to(probe) < 0.5, "zooming keeps the point under the finger still")
	screen.zoom_at(under, 1000.0)
	_check(screen.cam_zoom == screen.ZOOM_MAX, "zoom stops at its closest")
	screen.pan_by(Vector2(-1e6, -1e6))
	var view: Rect2 = screen.view_rect()
	_check(view.end.x <= 3200.5 and view.end.y <= 2200.5, "panning stops at the field's edge")
	screen.zoom_at(under, 0.0001)
	view = screen.view_rect()
	_check(view.size.x >= 3199.0 or view.size.y >= 2199.0, "zoomed out, the whole field shows")
	var gamble: Regiment = screen.battle.team_regiments(0).filter(func(r): return r.name == "Gamble's Brigade")[0]
	_tap(screen, gamble.pos)
	_tap(screen, gamble.pos)
	_check(screen.selected.size() == 4, "a double-tap selects the whole division")
	# A tap on a flag hands the division to its own command: the AI takes
	# it there, until the player orders a block again.
	var seminary: Vector2 = flag.call(Gettysburg.SEMINARY)
	_tap(screen, seminary)
	_check(screen.delegated.size() == 4 and gamble.objectives == PackedVector2Array([seminary]), "tapping a flag sends the division to take it on its own")
	screen.run.advance()
	_check(gamble.waypoints.size() > 0 and gamble.waypoints[gamble.waypoints.size() - 1].distance_to(seminary) < 250.0, "and the division's own command marches it there")
	screen._select([gamble.id] as Array[int])
	_tap(screen, Vector2(1300, 1500))
	_check(not gamble.id in screen.delegated and screen.delegated.size() == 3, "an order from the player takes the block back")
	screen.clear_selection()
	screen.cam_zoom = 0.6
	screen.look_at(Vector2(1600, 1100))
	var before: Vector2 = screen.cam_centre
	var from: Vector2 = screen.to_screen(Vector2(1500, 1700))
	screen._press(from, false, false)
	var motion := InputEventMouseMotion.new()
	motion.position = from - Vector2(60, 0)
	screen._unhandled_input(motion)
	screen._release(motion.position)
	_check(screen.cam_centre.x > before.x and screen.selected.is_empty(), "with nothing selected a drag on the field pans")
	screen.free()
	# Waterloo: each side's farms and villages held from the start, and the
	# French going in corps by corps at their hours.
	var w_spec := Scenarios.resolve("waterloo", 1)
	var w := Scenarios.make_battle(w_spec, 1)
	_check(w.flags.map(func(f): return f.owner) == [0, 0, 0, 0, 1, 1], "at Waterloo each side holds its own ground at 11:00")
	var guard: Regiment = w.regiments.filter(func(r): return r.name == "the Old Guard")[0]
	_check(is_equal_approx(guard.holds_until, 8.5 * Waterloo.HOUR) and guard.stars == 4, "the Old Guard waits for 19:30, with four stars")
	w.begin()
	var ids: Array = AI.decide(w, 1, AI.PERSONAS.aggressive).map(func(o): return o.get("id", -1))
	_check(not guard.id in ids and w.regiments.any(func(r): return r.formation == "Jérôme's Division" and r.holds_until > 0.0), "nobody moves before their hour")
	if quick:
		return
	var day := Fights.fight(Scenarios.make_battle(spec, 3), AI.PERSONAS.aggressive, "standard").battle
	_record("grand/gettysburg/3", day)
	print("  Gettysburg  winner %s at %s  flags %s  resolve %d/%d" % [
		"Union" if day.winner == 0 else "Confederate", Scenarios.hour_text(spec, day.time),
		day.flags.map(func(f): return f.owner), int(day.resolve[0]), int(day.resolve[1])])
	_check(day.phase == "over" and day.time <= day.deadline + Battle.BREAK_DELAY + 0.5, "Gettysburg is decided by dusk")


## A battle is its scenario, its seed and its log: replaying a recorded
## player's log fights the same battle to the man, and a log with an order
## taken out fights a different one.
func _test_replay() -> void:
	var spec := Scenarios.resolve("hold", 1)
	var make := func() -> Battle: return Scenarios.make_battle(spec, 1)
	var played := Fights.fight(make.call(), AI.PERSONAS[spec.persona], "standard", true)
	var seats := func() -> Array:
		var s := Fights.seats(AI.PERSONAS[spec.persona], "standard")
		s[1] = BattleRun.Seat.new(0, null)
		return s
	var again := BattleRun.replay(make, seats, played.log, Fights.length(played.battle))
	var same := func(a: Battle, b: Battle) -> bool:
		return a.winner == b.winner and a.time == b.time and a.killed == b.killed and a.resolve == b.resolve
	_check(played.log.size() > 10 and same.call(played.battle, again.battle), "replaying a log fights the same battle (%d turns logged)" % played.log.size())
	var changed := played.log.duplicate(true)
	changed[0].orders.clear()
	var other := BattleRun.replay(make, seats, changed, Fights.length(played.battle))
	_check(not same.call(played.battle, other.battle), "the same log without the first orders fights another battle")


func _test_battles(quick: bool) -> void:
	var wins := 0
	var seeds := [3] if quick else [3, 11, 29]
	for s in seeds:
		var run := Campaign.new_run(s)
		for i in Campaign.BATTLES.size():
			run.battle = i
			if i > 0:
				run = Campaign.apply_reward(run, {"id": "recruit", "kind": UnitTypes.RECRUITABLE[(i + s) % 5]})
			var b := Campaign.make_battle(run)
			var outcome := _fight(b, true, Campaign.BATTLES[i].persona, "campaign/%d/%d" % [s, i])
			var name: String = Campaign.BATTLES[i].name
			print("  seed %d  %-16s  winner %s  %3ds  kills %d/%d  resolve %d/%d  lead changes %d" % [
				s, name, "player" if b.winner == 0 else "enemy", int(b.time),
				b.killed[0], b.killed[1], int(b.resolve[0]), int(b.resolve[1]), _lead_changes])
			_check(outcome, "seed %d %s ends within the time limit" % [s, name])
			if b.winner == 0:
				wins += 1
	var passive := Campaign.make_battle(Campaign.new_run(5))
	_fight(passive, false, "balanced", "campaign/5/passive")
	print("  passive player: winner %s at %ds" % ["player" if passive.winner == 0 else "enemy", int(passive.time)])
	_check(passive.winner == 1, "an army that never moves loses")
	print("  AI-as-player won %d of %d" % [wins, seeds.size() * Campaign.BATTLES.size()])


## Fight `b` computer against computer and record it under `key`.
func _fight(b: Battle, player_acts: bool, persona: String, key := "") -> bool:
	var run := Fights.fight(b, AI.PERSONAS[persona], "standard" if player_acts else "idle")
	_lead_changes = run.trace.lead.changes
	if key != "":
		_record(key, b)
	return b.phase == "over" and b.time < 420.0


func _record(key: String, b: Battle) -> void:
	_golden[key] = "%s winner %d time %.2f killed %d/%d resolve %.2f/%.2f flags %s" % [
		key, b.winner, b.time, b.killed[0], b.killed[1], b.resolve[0], b.resolve[1],
		",".join(b.flags.map(func(f): return str(f.owner)))]


## Every battle this run fought must come out as recorded. With --record,
## the file takes this run's results instead: a deliberate change to how
## battles come out, made in the same commit as the change that caused it.
func _compare_golden(record: bool) -> void:
	var known := {}
	if FileAccess.file_exists(_golden_path):
		for line in FileAccess.get_file_as_string(_golden_path).split("\n", false):
			known[line.get_slice(" ", 0)] = line
	if record:
		known.merge(_golden, true)
		var keys := known.keys()
		keys.sort()
		var f := FileAccess.open(_golden_path, FileAccess.WRITE)
		for k in keys:
			f.store_line(known[k])
		print("  recorded %d battles" % _golden.size())
		return
	for key in _golden:
		_check(known.has(key), "%s is recorded in %s (run ./test.sh --record)" % [key, _golden_path])
		if known.has(key) and known[key] != _golden[key]:
			_check(false, "%s comes out as recorded:\n    was %s\n    now %s" % [key, known[key], _golden[key]])


## The largest battle, Waterloo, stays inside the step budget.
func _test_budget() -> void:
	var spec := Scenarios.resolve("waterloo", 1)
	var run := BattleRun.new(Scenarios.make_battle(spec, 3))
	for seat in Fights.seats(AI.PERSONAS[spec.persona], "standard"):
		run.add_seat(seat)
	run.begin()
	var times := PackedInt64Array()
	while run.battle.phase == "battle" and run.battle.time < run.battle.deadline + 10.0:
		var t0 := Time.get_ticks_usec()
		run.advance()
		times.append(Time.get_ticks_usec() - t0)
	_record("grand/waterloo/3", run.battle)
	var mean := 0
	for t in times:
		mean += t
	mean /= maxi(times.size(), 1)
	times.sort()
	var p99: int = times[int(times.size() * 0.99)]
	print("  Waterloo  winner %s at %s  step %d us mean, %d us p99" % [
		"Allies" if run.battle.winner == 0 else "French", Scenarios.hour_text(spec, run.battle.time), mean, p99])
	_check(mean <= STEP_BUDGET_MEAN and p99 <= STEP_BUDGET_P99, "Waterloo's step is within budget (%d us mean, %d us p99)" % [mean, p99])
