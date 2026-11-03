extends GutTest

var player: Player


func before_each() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	var c: CharacterData = load("res://data/characters/vanguard.tres")
	player.setup(c, PlayerStats.from_character(c))
	add_child_autofree(player)


func test_setup_uses_character_health() -> void:
	assert_eq(player.max_health(), 140)
	assert_eq(player.health_int(), 140)


func test_moves_at_stat_speed() -> void:
	player.step(0.016, Vector2.RIGHT)
	assert_almost_eq(player.velocity.x, player.stats.get_stat(&"move_speed"), 0.01)


func test_slow_factor_reduces_speed() -> void:
	player.slow_factor = 0.5
	player.step(0.016, Vector2.RIGHT)
	assert_almost_eq(player.velocity.x, player.stats.get_stat(&"move_speed") * 0.5, 0.01)


func test_input_override_is_clamped() -> void:
	player.input_override = Vector2(3, 4)
	assert_almost_eq(player.get_input_direction().length(), 1.0, 0.001)


func test_dash_speed_and_duration() -> void:
	assert_true(player.try_dash(Vector2.UP))
	player.step(0.016, Vector2.UP)
	assert_almost_eq(player.velocity.length(), player.stats.get_stat(&"move_speed") * Player.DASH_SPEED_MULT, 0.1)
	player.step(Player.DASH_DURATION, Vector2.UP)
	player.step(0.016, Vector2.UP)
	assert_false(player.is_dashing)


func test_dash_cooldown_blocks_then_recovers() -> void:
	player.try_dash(Vector2.RIGHT)
	player.step(0.2, Vector2.ZERO)
	assert_false(player.try_dash(Vector2.RIGHT))
	player.step(player.stats.get_stat(&"dash_cooldown"), Vector2.ZERO)
	assert_true(player.can_dash())


func test_dash_cooldown_stat_upgrade_shortens_cooldown() -> void:
	player.stats.add_mult(&"dash_cooldown", -0.5)
	player.try_dash(Vector2.RIGHT)
	assert_almost_eq(player.get_dash_cooldown_left(), 0.5, 0.001)


func test_dash_grants_iframes() -> void:
	player.try_dash(Vector2.RIGHT)
	assert_eq(player.take_damage(50), 0)


func test_damage_applies_armor_and_iframes() -> void:
	player.stats.add_flat(&"armor", 10.0)
	assert_eq(player.take_damage(20), 10)
	assert_eq(player.take_damage(20), 0, "invulnerable right after a hit")


func test_dies_and_emits_once() -> void:
	watch_signals(player)
	player.take_damage(9999)
	player.die()
	assert_true(player.is_dead)
	assert_signal_emit_count(player, "died", 1)


func test_heal_capped() -> void:
	player.take_damage(40)
	player.heal(1000)
	assert_eq(player.health_int(), player.max_health())


func test_regen_heals_over_time() -> void:
	player.take_damage(40)
	player.stats.add_flat(&"regen", 10.0)
	var before := player.health
	player.step(1.0, Vector2.ZERO)
	assert_almost_eq(player.health - before, 10.0, 0.01)


func test_fire_requires_target_and_respects_rate() -> void:
	watch_signals(player)
	assert_false(player.try_fire(null))
	assert_true(player.try_fire(player.global_position + Vector2(100, 0)))
	assert_false(player.try_fire(player.global_position + Vector2(100, 0)))
	player.step(1.0 / player.stats.get_stat(&"fire_rate") + 0.01, Vector2.ZERO)
	assert_true(player.try_fire(player.global_position + Vector2(100, 0)))
	assert_signal_emit_count(player, "fired", 2)


func test_multishot_fires_multiple_directions() -> void:
	player.stats.add_flat(&"projectile_count", 2.0)
	watch_signals(player)
	player.try_fire(player.global_position + Vector2(0, 100))
	var params: Array = get_signal_parameters(player, "fired")
	assert_eq((params[1] as Array).size(), 3)


func test_ability_cooldown_and_kind() -> void:
	watch_signals(player)
	assert_true(player.try_ability(Vector2.LEFT))
	assert_false(player.try_ability(Vector2.LEFT))
	assert_signal_emitted_with_parameters(player, "ability_used", [CharacterData.Ability.SHOCKWAVE, player.global_position, Vector2.LEFT])
	assert_almost_eq(player.ability_ready_ratio(), 0.0, 0.001)
