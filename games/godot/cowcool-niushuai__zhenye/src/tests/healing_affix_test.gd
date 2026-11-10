extends SceneTree

const TEST_SAVE := "user://zhenye_healing_affix_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)

	var meta := MetaProgression.new(TEST_SAVE, false)
	var charm := {
		"uid": 1,
		"slot": "charm",
		"name": "还魂玉",
		"template": 4,
		"rarity": 3,
		"level": 0,
		"stats": {"life_steal": 0.002},
		"source_stage": 2,
	}
	assert(meta.add_item(charm))
	assert(meta.equip_item(1))
	assert(is_equal_approx(float(meta.aggregate_stats()["life_steal"]), 0.002))
	assert("每秒最多恢复 2% 生命" in meta.item_description(charm))

	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.meta = meta
	game._start_game()
	assert(is_equal_approx(game.life_steal, 0.002))
	game.health = 40.0
	game._record_damage("sword", 2000.0)
	assert(is_equal_approx(game.health, 42.0))
	assert(is_zero_approx(game.life_steal_heal_budget))
	game._record_damage("sword", 2000.0)
	assert(is_equal_approx(game.health, 42.0))

	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)
	print("续航词条测试通过：噬魂吸血可汇总、回血并受每秒上限约束")
	quit()
