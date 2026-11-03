extends GutTest


func test_defaults() -> void:
	var s := PlayerStats.new()
	assert_eq(s.get_stat(&"max_hp"), 100.0)
	assert_eq(s.get_int(&"projectile_count"), 1)


func test_from_character() -> void:
	var c: CharacterData = load("res://data/characters/ranger.tres")
	var s := PlayerStats.from_character(c)
	assert_eq(s.get_stat(&"fire_rate"), c.fire_rate)
	assert_eq(s.get_stat(&"move_speed"), c.move_speed)


func test_flat_then_multiplier_formula() -> void:
	var s := PlayerStats.new()
	s.add_flat(&"damage", 8.0)
	s.add_mult(&"damage", 0.5)
	assert_almost_eq(s.get_stat(&"damage"), (12.0 + 8.0) * 1.5, 0.001)


func test_limits_clamp() -> void:
	var s := PlayerStats.new()
	s.add_flat(&"crit_chance", 5.0)
	s.add_mult(&"dash_cooldown", -5.0)
	assert_eq(s.get_stat(&"crit_chance"), 1.0)
	assert_eq(s.get_stat(&"dash_cooldown"), 0.25)


func test_apply_upgrade_modes() -> void:
	var s := PlayerStats.new()
	s.apply_upgrade(load("res://data/upgrades/multishot.tres"))
	s.apply_upgrade(load("res://data/upgrades/power.tres"))
	assert_eq(s.get_int(&"projectile_count"), 2)
	assert_almost_eq(s.get_stat(&"damage"), 12.0 * 1.15, 0.001)


func test_changed_signal() -> void:
	var s := PlayerStats.new()
	watch_signals(s)
	s.add_flat(&"armor", 1.0)
	assert_signal_emitted_with_parameters(s, "changed", [&"armor"])


func test_roll_damage_crit() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var always: Dictionary = Combat.roll_damage(10.0, 1.0, 2.0, rng)
	var never: Dictionary = Combat.roll_damage(10.0, 0.0, 2.0, rng)
	assert_eq(always, {"amount": 20, "crit": true})
	assert_eq(never, {"amount": 10, "crit": false})


func test_roll_damage_minimum_one() -> void:
	assert_eq(Combat.roll_damage(0.1, 0.0, 2.0, RandomNumberGenerator.new())["amount"], 1)


func test_mitigate() -> void:
	assert_eq(Combat.mitigate(20, 0.0), 20)
	assert_eq(Combat.mitigate(20, 10.0), 10)
	assert_eq(Combat.mitigate(1, 50.0), 1)
	assert_eq(Combat.mitigate(0, 0.0), 0)


func test_spread_directions() -> void:
	var one := Combat.spread_directions(Vector2.UP, 1)
	assert_eq(one, [Vector2.UP] as Array[Vector2])
	var three := Combat.spread_directions(Vector2.RIGHT, 3, 10.0)
	assert_eq(three.size(), 3)
	assert_almost_eq(three[1].angle(), 0.0, 0.0001)
	assert_almost_eq(three[0].angle(), -deg_to_rad(10.0), 0.0001)


func test_ring_directions() -> void:
	var ring := Combat.ring_directions(4)
	assert_eq(ring.size(), 4)
	var sum := Vector2.ZERO
	for d in ring:
		sum += d
	assert_almost_eq(sum.length(), 0.0, 0.0001)
