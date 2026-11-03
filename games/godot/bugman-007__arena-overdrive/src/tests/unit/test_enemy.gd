extends GutTest

var enemy: Enemy
var dummy: Node2D


func _make(id: String) -> Enemy:
	var e: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	add_child_autofree(e)
	e.setup(load("res://data/enemies/%s.tres" % id))
	return e


func before_each() -> void:
	enemy = _make("chaser")
	dummy = Node2D.new()
	add_child_autofree(dummy)


func _place(e: Enemy, dist: float) -> void:
	e.target = dummy
	dummy.global_position = e.global_position + Vector2(dist, 0)


func test_starts_idle() -> void:
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_idle_without_target() -> void:
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_chaser_chases_then_attacks() -> void:
	_place(enemy, 400)
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.CHASE)
	assert_gt(enemy.velocity.x, 0.0)
	dummy.global_position = enemy.global_position + Vector2(10, 0)
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.ATTACK)


func test_state_changed_signal_parameters() -> void:
	watch_signals(enemy)
	_place(enemy, 400)
	enemy.tick(0.016)
	assert_signal_emitted_with_parameters(enemy, "state_changed", [Enemy.State.IDLE, Enemy.State.CHASE])


func test_leash_hysteresis() -> void:
	enemy.data = enemy.data.duplicate()
	enemy.data.detect_range = 300.0
	enemy.state = Enemy.State.CHASE
	assert_eq(enemy.evaluate_state(340.0, true), Enemy.State.CHASE)
	enemy.state = Enemy.State.IDLE
	assert_eq(enemy.evaluate_state(340.0, true), Enemy.State.IDLE)


func test_melee_damages_player_with_cooldown() -> void:
	var p: Player = preload("res://scenes/player.tscn").instantiate()
	add_child_autofree(p)
	enemy.target = p
	p.global_position = enemy.global_position + Vector2(10, 0)
	var start := p.health
	enemy.tick(enemy.data.attack_cooldown)
	enemy.tick(0.01)
	assert_eq(int(start - p.health), enemy.data.damage)


func test_ignores_dead_player() -> void:
	var p: Player = preload("res://scenes/player.tscn").instantiate()
	add_child_autofree(p)
	p.die()
	enemy.target = p
	enemy.tick(0.016)
	assert_eq(enemy.state, Enemy.State.IDLE)


func test_shooter_keeps_distance() -> void:
	var s := _make("shooter")
	_place(s, s.data.attack_range * 0.3)
	s.tick(0.016)
	assert_eq(s.state, Enemy.State.RETREAT)
	assert_lt(s.velocity.x, 0.0, "moves away from target")


func test_shooter_fires_in_range() -> void:
	var s := _make("shooter")
	watch_signals(s)
	_place(s, s.data.attack_range * 0.8)
	s.tick(s.data.attack_cooldown)
	assert_eq(s.state, Enemy.State.ATTACK)
	assert_signal_emitted(s, "fire_requested")


func test_exploder_fuses_then_explodes_without_reward() -> void:
	var x := _make("exploder")
	watch_signals(x)
	_place(x, 20)
	x.tick(0.016)
	assert_eq(x.state, Enemy.State.FUSE)
	dummy.global_position += Vector2(1000, 0)
	x.tick(0.016)
	assert_eq(x.state, Enemy.State.FUSE, "fuse can't be cancelled")
	x.tick(x.data.attack_cooldown)
	assert_signal_emitted(x, "exploded")
	assert_signal_emitted_with_parameters(x, "died", [x, false])


func test_tank_resists_knockback() -> void:
	var t := _make("tank")
	t.take_hit(1, Vector2(1000, 0))
	enemy.take_hit(1, Vector2(1000, 0))
	assert_lt(t.knockback.length(), enemy.knockback.length())


func test_health_scale() -> void:
	enemy.setup(enemy.data, 2.0)
	assert_eq(enemy.max_health, enemy.data.max_hp * 2.0)


func test_take_hit_kills_and_rewards() -> void:
	watch_signals(enemy)
	assert_false(enemy.take_hit(1))
	assert_true(enemy.take_hit(9999))
	assert_false(enemy.is_alive())
	assert_signal_emitted_with_parameters(enemy, "died", [enemy, true])
	assert_false(enemy.take_hit(5), "dead enemies ignore hits")


func test_dead_enemy_dissolves() -> void:
	enemy.take_hit(9999)
	for i in 30:
		enemy.tick(0.05)
	assert_true(enemy.dissolved())


func test_boss_phase_thresholds() -> void:
	assert_eq(Enemy.boss_phase_for(1.0), 1)
	assert_eq(Enemy.boss_phase_for(0.5), 2)
	assert_eq(Enemy.boss_phase_for(0.2), 3)


func test_boss_changes_phase_and_fires_rings() -> void:
	var b := _make("boss")
	watch_signals(b)
	_place(b, 300)
	b.tick(1.0)
	assert_signal_emitted(b, "fire_requested")
	b.take_hit(b.max_health * 0.5)
	b.tick(0.016)
	assert_eq(b.phase, 2)
	assert_signal_emitted_with_parameters(b, "phase_changed", [2])
	assert_gt(b.speed_multiplier(), 1.0)


func test_boss_phase_three_summons() -> void:
	var b := _make("boss")
	watch_signals(b)
	_place(b, 300)
	b.take_hit(b.max_health * 0.8)
	for i in 8:
		b.tick(1.0)
	assert_eq(b.phase, 3)
	assert_signal_emitted(b, "summon_requested")
