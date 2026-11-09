extends SceneTree
## Integration smoke test: runs the real main scene with no input.
## Usage: godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd
## Checks that enemies spawn, reach the idle player, both forms kill and
## level-ups open the card menu (always picking the first card). Then
## brings in the boss early, checks it swaps resistance, fires rings and
## takes damage, and that killing it wins the run.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const TITLE_SCENE := preload("res://scenes/title.tscn")
const SECONDS_PER_PHASE := 15
## Long enough for at least one resistance swap and two bolt rings.
const BOSS_SECONDS := 12

var _errors: PackedStringArray = []


func _initialize() -> void:
	# Never touch the player's own save files.
	GameSettings.path = "user://smoke_settings.cfg"
	Progress.path = "user://smoke_progress.cfg"
	_run.call_deferred()


func _run() -> void:
	await _check_title()
	await _check_tutorial()
	# The rest of the smoke test plays a normal run.
	GameSettings.current().tutorial_done = true
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	var player: Player = main.get_node("Player")
	var spawner: HordeSpawner = main.get_node("HordeSpawner")
	# An idle player dies in ~15s by design; keep it alive to test both forms.
	player.max_health = 1000.0
	player.health = player.max_health
	var kills_as_knight := await _kills_during(main, SECONDS_PER_PHASE)
	_check(spawner.alive_count() > 0, "no enemies alive after %ds" % SECONDS_PER_PHASE)
	_check(kills_as_knight > 0, "knight killed nothing")
	_check(player.health < player.max_health, "player took no contact damage")
	player.shift()
	_check(player.form == Player.Form.MAGE, "shift did not switch to mage")
	var kills_as_mage := await _kills_during(main, SECONDS_PER_PHASE)
	_check(kills_as_mage > 0, "mage killed nothing")
	_check(main.experience.level > 1, "never leveled up")
	_check_perfect_shift(player, spawner)
	# A Shift Burst from that shift can kill and level up; finish it.
	await _drain_level_ups(main.level_up_menu)
	await _check_new_enemies(main, player)
	_check(not paused, "tree still paused after the run")
	print("smoke: elapsed %.1fs, alive %d, knight kills %d, mage kills %d, hp %.1f, level %d" % [
		spawner.elapsed, spawner.alive_count(), kills_as_knight, kills_as_mage, player.health,
		main.experience.level])
	await _check_boss(main, player)
	for error in _errors:
		printerr("SMOKE FAIL: ", error)
	for file in [GameSettings.path, Progress.path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	await AudioManager.shutdown()
	quit(1 if not _errors.is_empty() else 0)


func _check_boss(main: Run, player: Player) -> void:
	player.max_health = 100000.0
	player.health = player.max_health
	var spawner: HordeSpawner = main.get_node("HordeSpawner")
	# Jump past the last mini-boss time: both must spawn exactly once.
	spawner.elapsed = Run.MINI_BOSSES[Run.MINI_BOSSES.size() - 1].time + 1.0
	for frame in 3:
		await physics_frame
	var mini_bosses := get_nodes_in_group(spawner.enemy_group).filter(func(enemy: Node) -> bool: return enemy is Enemy and enemy.max_health >= 50.0)
	_check(mini_bosses.size() == Run.MINI_BOSSES.size(), "expected %d mini-bosses, found %d" % [Run.MINI_BOSSES.size(), mini_bosses.size()])
	# Like the real run: normal waves are over when the boss arrives.
	spawner.stop()
	for enemy in get_nodes_in_group(spawner.enemy_group):
		enemy.take_damage(1e9)
	# Every evolution on, so their code runs in the real scene.
	for id: StringName in [&"shift_burst", &"momentum", &"evo_arcane_orbit", &"evo_storm_cleaver", &"evo_blood_pact", &"evo_twin_soul"]:
		UpgradeEffects.apply(player, id)
	main.spawn_boss()
	var boss := main.boss
	var swaps: Array[int] = []
	boss.resistance_swapped.connect(func(form: int) -> void: swaps.append(form))
	for half in 2:
		await _kills_during(main, BOSS_SECONDS / 2)
		player.shift()
	_check(not swaps.is_empty(), "boss never swapped resistance")
	_check(boss._ring_count >= 2, "boss fired %d bolt rings" % boss._ring_count)
	_check(boss.health < boss.max_health, "boss took no damage")
	_check(main.boss_bar.visible, "boss bar not shown")
	print("smoke boss: swaps %d, rings %d, hp %.0f/%.0f" % [swaps.size(), boss._ring_count, boss.health, boss.max_health])
	boss.take_damage(boss.health + 1.0)
	for frame in 5:
		await physics_frame
	_check(main._run_over, "killing the boss did not end the run")
	for frame in int((Run.RESULTS_DELAY + 0.5) * 60):
		await physics_frame
	_check(main.results_screen.visible, "results screen not shown after the run")
	_check(main.results_screen.title() == "YOU WIN", "results title is %s" % main.results_screen.title())
	_check(main.results_screen.upgrade_slot_count() > 0, "results list no upgrades")
	_check(main.results_screen.score_text().begins_with("SCORE"), "no score on the results screen")
	_check(Progress.current().is_unlocked(&"demon_slayer"), "winning did not unlock Demon Slayer")


## An enemy right on the player makes the next shift perfect.
func _check_perfect_shift(player: Player, spawner: HordeSpawner) -> void:
	var enemies := get_nodes_in_group(spawner.enemy_group)
	_check(not enemies.is_empty(), "no enemy for the perfect shift check")
	if enemies.is_empty():
		return
	(enemies[0] as Node2D).global_position = player.global_position + Vector2(4, 0)
	var perfects := [0]
	player.perfect_shifted.connect(func() -> void: perfects[0] += 1)
	player.shift()
	_check(perfects[0] == 1, "shift next to an enemy was not perfect")
	_check(player.is_invulnerable(), "perfect shift gave no invulnerability")


## A first run starts in the tutorial with the waves held back; moving
## and shifting advance it, and skipping starts the waves.
func _check_tutorial() -> void:
	GameSettings.current().tutorial_done = false
	var main: Run = MAIN_SCENE.instantiate()
	root.add_child(main)
	await physics_frame
	var spawner: HordeSpawner = main.get_node("HordeSpawner")
	_check(main.tutorial != null, "first run has no tutorial")
	_check(not spawner.running, "waves run during the tutorial")
	var player: Player = main.get_node("Player")
	player.global_position += Vector2(TutorialSteps.MOVE_DISTANCE + 10.0, 0)
	for frame in 3:
		await physics_frame
	player.shift()
	await physics_frame
	_check(main.tutorial._steps.current == TutorialSteps.Step.RESIST, "tutorial at step %d, expected RESIST" % main.tutorial._steps.current)
	main.tutorial.skip()
	await physics_frame
	_check(spawner.running, "waves did not start after skipping the tutorial")
	_check(GameSettings.current().tutorial_done, "skipping did not mark the tutorial done")
	main.queue_free()
	await physics_frame


## The title builds its menu and leaves the tree unpaused.
func _check_title() -> void:
	var title := TITLE_SCENE.instantiate()
	root.add_child(title)
	for frame in 10:
		await process_frame
	var buttons := title.find_children("*", "Button", true, false)
	_check(buttons.size() >= 3, "title has %d buttons" % buttons.size())
	_check(not paused, "title paused the tree")
	title.queue_free()
	await process_frame


func _kills_during(main: Node, seconds: int) -> int:
	var before: int = main.kills
	var menu: LevelUpMenu = main.level_up_menu
	for frame in seconds * 60:
		if menu.visible:
			menu.choose(0)
		await physics_frame
	await _drain_level_ups(menu)
	return int(main.kills) - before


## The eye shoots, the beast charges and the slime splits in two.
func _check_new_enemies(main: Run, player: Player) -> void:
	var eye := main.spawn_enemy(load("res://scenes/enemy_eye.tscn"), 150.0) as RangedEnemy
	var beast := main.spawn_enemy(load("res://scenes/enemy_beast.tscn"), 90.0) as ChargerEnemy
	eye.max_health = 1e6
	eye.health = 1e6
	beast.max_health = 1e6
	beast.health = 1e6
	var saw_bolt := false
	var saw_charge := false
	for frame in 4 * 60:
		saw_bolt = saw_bolt or get_node_count_in_group(EnemyBolt.GROUP) > 0
		saw_charge = saw_charge or (is_instance_valid(beast) and beast.state == ChargerEnemy.State.CHARGE)
		if main.level_up_menu.visible:
			main.level_up_menu.choose(0)
		await physics_frame
	_check(saw_bolt, "the eye never fired")
	_check(saw_charge, "the beast never charged")
	eye.queue_free()
	beast.queue_free()
	var slime := main.spawn_enemy(load("res://scenes/enemy_slime.tscn"), 200.0)
	slime.take_damage(1e6)
	for frame in 3:
		await physics_frame
	var smalls := get_nodes_in_group(main.spawner.enemy_group).filter(func(enemy: Node) -> bool: return enemy.scene_file_path == "res://scenes/enemy_slime_small.tscn")
	_check(smalls.size() == 2, "slime split into %d pieces" % smalls.size())
	await _drain_level_ups(main.level_up_menu)


## A level-up on the last frame would leave the tree paused for the
## checks that follow; pick until none is pending.
func _drain_level_ups(menu: LevelUpMenu) -> void:
	while menu.visible or paused:
		if menu.visible:
			menu.choose(0)
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
