extends SceneTree

const Rules = preload("res://scripts/game_rules.gd")
var failures: int = 0

func _initialize() -> void:
	check(is_equal_approx(Rules.radius_for_mass(0), Rules.START_RADIUS), "New rounds start at the configured radius")
	check(is_equal_approx(Rules.radius_for_mass(-50), Rules.START_RADIUS), "Negative mass cannot shrink a hole")
	check(is_equal_approx(Rules.radius_for_mass(1e9), Rules.MAX_RADIUS), "Growth has a performance-safe cap")
	check(Rules.can_absorb(29.0, 16.0), "Starting hole can swallow cones")
	check(not Rules.can_absorb(29.0, 25.0), "Bench is too big at spawn")
	check(Rules.can_absorb(30.0, 25.0), "Exact absorption threshold is inclusive")
	check(Rules.level_for_radius(41.99) == 0 and Rules.level_for_radius(42) == 1, "Level boundaries are exact")
	check(is_equal_approx(Rules.growth_progress(42.0), 0.0), "Progress resets after leveling")
	check(is_equal_approx(Rules.growth_progress(156.0), 1.0), "Final level shows full progress")
	check(Rules.combo_multiplier(1) == 1.0 and Rules.combo_multiplier(6) == 1.25, "Combo reward steps after five chained items")
	check(Rules.combo_multiplier(9999) == 3.0, "Combo multiplier is bounded")
	check(Rules.score_for(100, 6) == 125, "Score applies combo multiplier once")
	check(Rules.growth_mass(100, 1) > Rules.growth_mass(100, 0), "Growth candidate has its promised bonus")
	check(Rules.movement_speed(0, 29) > Rules.movement_speed(1, 29), "Speed candidate has its promised bonus")
	check(Rules.combo_window(2) > Rules.combo_window(0), "Combo candidate has its promised bonus")
	check(Rules.bounded_position(Vector2(-100, 9000), 29) == Vector2(41, 1859), "World bounds reserve hole radius")
	var previous: float = Rules.START_RADIUS
	for mass in range(0, 4000, 7):
		var current: float = Rules.radius_for_mass(float(mass))
		check(current >= previous, "Growth is monotonic")
		previous = current
	# A player can bootstrap from litter through every object tier.
	var mass: float = 0.0
	for tier in range(Rules.PROP_TYPES.size()):
		var prop: Dictionary = Rules.PROP_TYPES[tier]
		if tier > 0:
			var prior: Dictionary = Rules.PROP_TYPES[tier - 1]
			while not Rules.can_absorb(Rules.radius_for_mass(mass), float(prop["radius"])):
				mass += float(prior["mass"])
		check(Rules.can_absorb(Rules.radius_for_mass(mass), float(prop["radius"])), "Each size tier is reachable")
	print("Game rule regression tests: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
