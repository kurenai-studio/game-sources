extends SceneTree

const TEST_SAVE := "user://zhenye_meta_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)

	var meta := MetaProgression.new(TEST_SAVE, false)
	for slot in meta.SLOT_ORDER:
		assert(meta.ITEM_NAMES[slot].size() == 9)
	assert(meta.WEAPON_KEYS.size() == 9)
	var item := meta.generate_item(1, "boss")
	assert(int(item["rarity"]) >= 2)
	assert(meta.add_item(item))
	assert(meta.equip_item(int(item["uid"])))
	assert(not meta.equipped_item(item["slot"]).is_empty())
	var rule_item := meta.generate_item(0, "first_clear")
	assert(int(rule_item["rarity"]) >= 3)
	assert(not String(rule_item.get("rule", "")).is_empty())
	assert(meta.add_item(rule_item))
	assert(meta.equip_item(int(rule_item["uid"])))
	meta.currencies["essence"] = 100
	meta.currencies["incense"] = 200
	assert(meta.upgrade_item(int(item["uid"])))
	assert(int(meta.get_item(int(item["uid"]))["level"]) == 1)
	assert(not meta.talent_requirements_met("power"))
	assert(meta.upgrade_talent("vitality"))
	assert(meta.upgrade_talent("vitality"))
	assert(meta.talent_requirements_met("power"))
	assert(meta.upgrade_talent("power"))
	var stats := meta.aggregate_stats()
	assert(stats.has("starting_weapon"))
	assert(String(rule_item["rule"]) in stats["rules"])
	assert(float(stats["health"]) >= 0.1)
	assert(float(stats["damage"]) >= 0.03)
	meta.talents["mastery"] = 3
	stats = meta.aggregate_stats()
	assert("celestial_guard" in stats["rules"])
	meta.save_data()

	var loaded := MetaProgression.new(TEST_SAVE, false)
	assert(loaded.inventory.size() == 2)
	assert(int(loaded.currencies["essence"]) < 100)
	assert(loaded.talent_rank("vitality") == 2)
	assert(loaded.talent_rank("power") == 1)
	var run_loot := [loaded.generate_item(2, "elite")]
	var rewards := loaded.settle_run(true, 2, 120, run_loot)
	assert(int(rewards["incense"]) > 0)
	assert(int(rewards["scroll"]) > 0)
	assert(rewards["items"].size() >= 2)
	var dismantle_uid: int = loaded.inventory[0]["uid"]
	assert(loaded.dismantle_item(dismantle_uid) > 0)

	DirAccess.remove_absolute(absolute_path)
	print("局外测试通过：掉落、穿戴、强化、分解、结算和存档读取正常")
	quit()
