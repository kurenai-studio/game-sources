extends GutTest
## Boots the real game scene headless and drives it through its main loop.

const SAVE := "user://test_integration_save.json"
var game: Node
var _old_path: String
var _old_data: Dictionary


func before_each() -> void:
	_old_path = SaveSystem.path
	_old_data = SaveSystem.data
	SaveSystem.path = SAVE
	SaveSystem.data = SaveSystem.default_data()
	GameState.selected_character = &"arcanist"
	game = load("res://scenes/game.tscn").instantiate()
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	SaveSystem.path = _old_path
	SaveSystem.data = _old_data
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_boots_with_selected_character_and_arena() -> void:
	assert_eq(game.character.id, &"arcanist")
	assert_false(game.layout.is_empty())
	assert_eq(game.player.max_health(), 105)


func test_first_wave_starts_and_spawns() -> void:
	await wait_seconds(1.8)
	assert_eq(game.wave, 1)
	assert_gt(game.living_enemies().size(), 0)


func test_upgrade_choice_pauses_and_applies() -> void:
	game.debug_force_upgrade()
	assert_true(get_tree().paused)
	var before: float = game.stats.get_stat(&"damage")
	var power: UpgradeData = load("res://data/upgrades/power.tres")
	game._on_card_chosen(power)
	assert_false(get_tree().paused)
	assert_gt(game.stats.get_stat(&"damage"), before)
	assert_eq(game.upgrades.stack_count(&"power"), 1)


func test_ability_damages_nearby_enemies() -> void:
	game._spawn_enemy(&"tank", game.player.global_position + Vector2(60, 0))
	var e: Enemy = game.living_enemies()[0]
	var hp := e.health
	game._on_ability(CharacterData.Ability.SHOCKWAVE, game.player.global_position, Vector2.RIGHT)
	assert_lt(e.health, hp)


func test_kill_drops_xp_and_scores() -> void:
	game._spawn_enemy(&"chaser", game.player.global_position + Vector2(300, 0))
	var e: Enemy = game.living_enemies()[0]
	game._damage_enemy(e, 9999, false, Vector2.ZERO)
	assert_eq(game.run["kills"], 1)
	assert_gt(game.scores.score, 0)
	assert_gt(game._pickup_pool.active_count(), 0)


func test_death_records_run_and_shows_results() -> void:
	game.run["coins"] = 7
	game.player.die()
	assert_eq(game.phase, game.Phase.OVER)
	game._show_results()
	get_tree().paused = false
	assert_true(game._results.visible)
	assert_eq(SaveSystem.stat("runs"), 1)
	assert_eq(SaveSystem.get_coins(), 7)
