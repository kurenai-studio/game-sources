extends TestCase
## Perfect shift: shifting while a threat is about to touch the player.

const PLAYER_SCENE := preload("res://scenes/player.tscn")


func test_threat_inside_danger_range_counts() -> void:
	var edge := 6.0 + Player.BODY_RADIUS + PerfectShift.DANGER_MARGIN
	assert_true(PerfectShift.is_threat(Vector2.ZERO, Vector2(edge - 0.5, 0), 6.0), "just inside should count")
	assert_false(PerfectShift.is_threat(Vector2.ZERO, Vector2(edge + 0.5, 0), 6.0), "just outside should not")


func test_touching_threat_counts() -> void:
	assert_true(PerfectShift.is_threat(Vector2.ZERO, Vector2(3, 0), 6.0), "overlapping enemy is a threat")


func test_trigger_needs_danger() -> void:
	var perfect := PerfectShift.new()
	assert_false(perfect.try_trigger(false), "no danger, no perfect")
	assert_true(perfect.try_trigger(true), "danger should trigger")


func test_cooldown_blocks_until_it_runs_out() -> void:
	var perfect := PerfectShift.new()
	assert_true(perfect.try_trigger(true))
	assert_false(perfect.try_trigger(true), "second perfect right away should be blocked")
	perfect.tick(PerfectShift.COOLDOWN - 0.01)
	assert_false(perfect.try_trigger(true), "still cooling down")
	perfect.tick(0.02)
	assert_true(perfect.try_trigger(true), "ready after the cooldown")


func test_energy_restore_clamps_to_full() -> void:
	var energy := FormEnergy.new()
	energy.tick(Player.Form.KNIGHT, FormEnergy.DRAIN_TIME * 0.5)
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 0.5)
	energy.restore(Player.Form.KNIGHT, 0.25)
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 0.75)
	energy.restore(Player.Form.KNIGHT, 1.0)
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 1.0)


func test_invulnerable_player_takes_no_damage() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.health = player.max_health
	player.make_invulnerable(PerfectShift.INVULNERABLE_TIME)
	assert_true(player.is_invulnerable(), "player should be invulnerable")
	player.take_damage(5.0)
	assert_almost_eq(player.health, player.max_health)
	player.free()


func test_damage_numbers_show_text_popups() -> void:
	var numbers := DamageNumbers.new()
	numbers.spawn_text(Vector2.ZERO, "PERFECT", Color.CYAN)
	assert_eq(numbers.count(), 1)
	assert_eq(numbers.color_of_newest(), Color.CYAN)
	numbers.free()
