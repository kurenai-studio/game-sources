class_name MetaProgression
extends RefCounted

const DEFAULT_SAVE_PATH := "user://zhenye_save.json"
const MAX_INVENTORY := 120

const SLOT_ORDER := ["weapon", "head", "robe", "belt", "boots", "charm"]
const SLOT_NAMES := {
	"weapon": "本命法器",
	"head": "道冠",
	"robe": "法袍",
	"belt": "腰饰",
	"boots": "云履",
	"charm": "护符",
}
const RARITY_NAMES := ["凡品", "良品", "灵品", "玄品", "地品", "天品"]
const RARITY_COLORS := ["a9a59b", "72b879", "5fa8d3", "a979d1", "d6a84d", "d94b3d"]

const ITEM_NAMES := {
	"weapon": ["青锋剑匣", "朱砂火葫", "雷击木印", "摄魂铜铃", "五帝钱串", "阴阳玉盘", "潮生玄葫", "渡魂桨匣", "太阴针囊"],
	"head": ["七星道冠", "纯阳巾", "阴山帽", "天师冠", "玄水冠", "百目傩面", "乌篷蓑笠", "玄冰道冠", "雪魈傩面"],
	"robe": ["百衲法衣", "玄阳道袍", "阴山尸衣", "朱砂鹤氅", "锁妖法袍", "九幽羽衣", "摆渡蓑衣", "幽莲法袍", "六花霜氅"],
	"belt": ["乾坤绳", "缚妖索带", "藏符腰囊", "镇墓石佩", "聚灵玉带", "香火锦囊", "锁舟缆带", "寒狱铁束", "冰河玉带"],
	"boots": ["踏罡履", "逐月靴", "阴风草鞋", "云纹法履", "缩地靴", "无影履", "踏浪芒鞋", "鬼渡水履", "雪踪云履"],
	"charm": ["平安护符", "镇煞符", "聚灵玉佩", "五雷符胆", "还魂玉", "天师法印", "河灯引魂符", "镇狱冰符", "北冥风魄"],
}
const WEAPON_KEYS := ["sword", "talisman", "thunder", "bell", "coin", "orb", "tide_gourd", "ferry_oar", "ice_needles"]
const STAT_NAMES := {
	"damage": "法器伤害",
	"health": "生命上限",
	"move_speed": "移动速度",
	"pickup": "拾取范围",
	"cooldown": "冷却缩减",
	"experience": "残魂获取",
	"luck": "寻宝运势",
	"damage_reduction": "受到伤害降低",
	"copper_bonus": "额外铜钱概率",
	"life_steal": "噬魂吸血",
	"health_regen": "每秒生命恢复",
}
const RULE_AFFIX_DATA := {
	"opening_purse": ["开坛钱囊", "每局开场获得 20 铜钱"],
	"free_reroll": ["识宝灵台", "每次鬼市首次刷新免费"],
	"emergency_guard": ["替命法衣", "每局首次致命伤害保留 1 点生命"],
	"wave_heal": ["回元玉带", "进入新波次时恢复 5% 生命"],
	"swift_start": ["踏风云履", "每局前 20 秒移动速度 +12%"],
	"opening_choice": ["灵签护符", "开局额外获得一次修行选择"],
	"celestial_guard": ["天师护命", "每局首次致命伤害保留 1 点生命"],
}
const SLOT_RULE_AFFIX := {
	"weapon": "opening_purse",
	"head": "free_reroll",
	"robe": "emergency_guard",
	"belt": "wave_heal",
	"boots": "swift_start",
	"charm": "opening_choice",
}
const TALENT_ORDER := ["vitality", "power", "agility", "warding", "regeneration", "prosperity", "spirit", "fortune", "cooldown", "magnet", "mastery", "opening_arsenal", "boss_hunter", "rebirth", "soul_vacuum", "shop_discount", "unbound_evolution"]
const TALENT_DATA := {
	"vitality": {"name": "固本培元", "description": "每阶生命上限 +5%", "max_rank": 5, "base_cost": 12, "cost_step": 8, "stat": "health", "value": 0.05, "requires": {}},
	"power": {"name": "炼炁化锋", "description": "每阶法器伤害 +3%", "max_rank": 5, "base_cost": 18, "cost_step": 10, "stat": "damage", "value": 0.03, "requires": {"vitality": 2}},
	"agility": {"name": "踏罡轻身", "description": "每阶移动速度 +2.5%", "max_rank": 5, "base_cost": 18, "cost_step": 10, "stat": "move_speed", "value": 0.025, "requires": {"vitality": 2}},
	"spirit": {"name": "聚灵纳魂", "description": "每阶残魂获取 +4%", "max_rank": 5, "base_cost": 26, "cost_step": 12, "stat": "experience", "value": 0.04, "requires": {"power": 2}},
	"fortune": {"name": "寻龙望气", "description": "每阶寻宝运势 +4%", "max_rank": 5, "base_cost": 26, "cost_step": 12, "stat": "luck", "value": 0.04, "requires": {"agility": 2}},
	"cooldown": {"name": "周天吐纳", "description": "每阶冷却缩减 +2.5%", "max_rank": 5, "base_cost": 36, "cost_step": 14, "stat": "cooldown", "value": 0.025, "requires": {"spirit": 2}},
	"magnet": {"name": "摄魂引", "description": "每阶拾取范围 +8%", "max_rank": 5, "base_cost": 36, "cost_step": 14, "stat": "pickup", "value": 0.08, "requires": {"fortune": 2}},
	"mastery": {"name": "天师敕令", "description": "每阶法器伤害 +6%，满阶获得天师护命", "max_rank": 3, "base_cost": 60, "cost_step": 30, "stat": "damage", "value": 0.06, "requires": {"cooldown": 2, "magnet": 2}, "rule_at_max": "celestial_guard"},
	"warding": {"name": "护体罡气", "description": "每阶受到伤害 -2.5%", "max_rank": 5, "base_cost": 30, "cost_step": 18, "stat": "damage_reduction", "value": 0.025, "requires": {"vitality": 2}},
	"regeneration": {"name": "生生不息", "description": "每阶每秒恢复 0.1 生命", "max_rank": 5, "base_cost": 34, "cost_step": 18, "stat": "health_regen", "value": 0.1, "requires": {"vitality": 3}},
	"prosperity": {"name": "生财有道", "description": "每阶铜钱掉落时有 8% 概率额外获得 1 枚", "max_rank": 5, "base_cost": 30, "cost_step": 18, "stat": "copper_bonus", "value": 0.08, "requires": {"vitality": 2}},
	"opening_arsenal": {"name": "万法随身", "description": "神通：开局额外获得三种随机法器", "max_rank": 1, "base_cost": 140, "cost_step": 0, "stat": "damage", "value": 0.0, "requires": {"spirit": 5}, "rule_at_max": "opening_arsenal"},
	"boss_hunter": {"name": "斩祟天命", "description": "神通：对首领造成的伤害提高 25%", "max_rank": 1, "base_cost": 150, "cost_step": 0, "stat": "damage", "value": 0.0, "requires": {"power": 5}, "rule_at_max": "boss_hunter"},
	"rebirth": {"name": "九转还魂", "description": "神通：每局首次死亡以 35% 生命复生并获得短暂无敌", "max_rank": 1, "base_cost": 180, "cost_step": 0, "stat": "health", "value": 0.0, "requires": {"warding": 5, "regeneration": 5}, "rule_at_max": "rebirth"},
	"soul_vacuum": {"name": "百川归魂", "description": "神通：全地图残魂都会自动飞向角色", "max_rank": 1, "base_cost": 140, "cost_step": 0, "stat": "pickup", "value": 0.0, "requires": {"magnet": 5}, "rule_at_max": "soul_vacuum"},
	"shop_discount": {"name": "鬼市敕令", "description": "神通：鬼市所有货物价格降低 25%", "max_rank": 1, "base_cost": 150, "cost_step": 0, "stat": "luck", "value": 0.0, "requires": {"prosperity": 5}, "rule_at_max": "shop_discount"},
	"unbound_evolution": {"name": "万法归一", "description": "神通：法器五阶后无需对应心法即可进化", "max_rank": 1, "base_cost": 200, "cost_step": 0, "stat": "damage", "value": 0.0, "requires": {"mastery": 3}, "rule_at_max": "unbound_evolution"},
}

var save_path := DEFAULT_SAVE_PATH
var inventory: Array = []
var equipped: Dictionary = {}
var currencies := {"incense": 0, "essence": 0, "iron": 0, "scroll": 0}
var talents: Dictionary = {}
var first_clears: Dictionary = {}
var next_uid := 1
var initialized := false
var rng := RandomNumberGenerator.new()


func _init(custom_save_path: String = DEFAULT_SAVE_PATH, create_default_profile: bool = true) -> void:
	save_path = custom_save_path
	rng.randomize()
	for slot in SLOT_ORDER:
		equipped[slot] = 0
	for talent_id in TALENT_ORDER:
		talents[talent_id] = 0
	load_data()
	if create_default_profile and not initialized:
		_initialize_profile()


func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	inventory = parsed.get("inventory", [])
	for item in inventory:
		if int(item.get("rarity", 0)) >= 3 and not item.has("rule"):
			item["rule"] = SLOT_RULE_AFFIX.get(String(item.get("slot", "")), "")
	next_uid = int(parsed.get("next_uid", 1))
	first_clears = parsed.get("first_clears", {})
	initialized = bool(parsed.get("initialized", true))
	var loaded_currencies: Dictionary = parsed.get("currencies", {})
	for key in currencies.keys():
		currencies[key] = int(loaded_currencies.get(key, 0))
	var loaded_equipped: Dictionary = parsed.get("equipped", {})
	for slot in SLOT_ORDER:
		equipped[slot] = int(loaded_equipped.get(slot, 0))
	var loaded_talents: Dictionary = parsed.get("talents", {})
	for talent_id in TALENT_ORDER:
		talents[talent_id] = clampi(int(loaded_talents.get(talent_id, 0)), 0, int(TALENT_DATA[talent_id]["max_rank"]))


func save_data() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"inventory": inventory,
		"equipped": equipped,
		"currencies": currencies,
		"talents": talents,
		"first_clears": first_clears,
		"next_uid": next_uid,
		"initialized": initialized,
	}))


func _initialize_profile() -> void:
	initialized = true
	for slot_index in SLOT_ORDER.size():
		var slot: String = SLOT_ORDER[slot_index]
		var item := {
			"uid": next_uid,
			"slot": slot,
			"name": ITEM_NAMES[slot][0],
			"template": 0,
			"rarity": 0,
			"level": 0,
			"stats": _base_stats(slot, 0),
			"source_stage": -1,
		}
		if slot == "weapon":
			item["weapon_key"] = "sword"
		inventory.append(item)
		equipped[slot] = next_uid
		next_uid += 1
	currencies["essence"] = 30
	currencies["iron"] = 10
	save_data()


func generate_item(stage: int, source: String) -> Dictionary:
	var slot: String = SLOT_ORDER[rng.randi_range(0, SLOT_ORDER.size() - 1)]
	var template_index := rng.randi_range(0, ITEM_NAMES[slot].size() - 1)
	var rarity := _roll_rarity(stage, source)
	var stats := _base_stats(slot, rarity)
	var affix_count := mini(3, 1 + floori(float(rarity) / 2.0))
	var affix_keys: Array[String] = []
	for key in STAT_NAMES.keys():
		if not stats.has(key):
			if key == "health_regen":
				continue
			if key == "life_steal" and (rarity < 2 or slot not in ["weapon", "charm"]):
				continue
			affix_keys.append(key)
	_shuffle_strings(affix_keys)
	for index in mini(affix_count, affix_keys.size()):
		var key := affix_keys[index]
		stats[key] = _affix_value(key, rarity)
	var item := {
		"uid": next_uid,
		"slot": slot,
		"name": ITEM_NAMES[slot][template_index],
		"template": template_index,
		"rarity": rarity,
		"level": 0,
		"stats": stats,
		"source_stage": stage,
	}
	if slot == "weapon":
		item["weapon_key"] = WEAPON_KEYS[template_index]
	if rarity >= 3:
		item["rule"] = SLOT_RULE_AFFIX[slot]
	next_uid += 1
	return item


func add_item(item: Dictionary) -> bool:
	if inventory.size() >= MAX_INVENTORY:
		return false
	inventory.append(item)
	return true


func settle_run(won: bool, stage: int, defeated: int, loot: Array) -> Dictionary:
	var added_items: Array = []
	for item in loot:
		if add_item(item):
			added_items.append(item)
	var incense := maxi(1, defeated / 5) + stage * 4
	var essence := maxi(0, defeated / 18) + added_items.size() * 2
	var iron := stage + (2 if won else 0)
	var scroll := 0
	if won:
		incense += 12 + stage * 6
		if not first_clears.has(str(stage)):
			first_clears[str(stage)] = true
			scroll = 3 + stage
			var guaranteed := generate_item(stage, "first_clear")
			if add_item(guaranteed):
				added_items.append(guaranteed)
	currencies["incense"] += incense
	currencies["essence"] += essence
	currencies["iron"] += iron
	currencies["scroll"] += scroll
	save_data()
	return {
		"items": added_items,
		"incense": incense,
		"essence": essence,
		"iron": iron,
		"scroll": scroll,
	}


func equip_item(uid: int) -> bool:
	var item := get_item(uid)
	if item.is_empty():
		return false
	equipped[item["slot"]] = uid
	save_data()
	return true


func upgrade_item(uid: int) -> bool:
	var index := get_item_index(uid)
	if index < 0:
		return false
	var item: Dictionary = inventory[index]
	if int(item["level"]) >= 5:
		return false
	var cost := 8 + int(item["level"]) * 7 + int(item["rarity"]) * 3
	if int(currencies["essence"]) < cost:
		return false
	currencies["essence"] -= cost
	item["level"] = int(item["level"]) + 1
	inventory[index] = item
	save_data()
	return true


func dismantle_item(uid: int) -> int:
	var index := get_item_index(uid)
	if index < 0:
		return 0
	var item: Dictionary = inventory[index]
	var reward := 4 + int(item["rarity"]) * 5 + int(item["level"]) * 3
	for slot in SLOT_ORDER:
		if int(equipped[slot]) == uid:
			equipped[slot] = 0
	inventory.remove_at(index)
	currencies["essence"] += reward
	save_data()
	return reward


func get_item(uid: int) -> Dictionary:
	var index := get_item_index(uid)
	return {} if index < 0 else inventory[index]


func get_item_index(uid: int) -> int:
	for index in inventory.size():
		if int(inventory[index]["uid"]) == uid:
			return index
	return -1


func equipped_item(slot: String) -> Dictionary:
	return get_item(int(equipped.get(slot, 0)))


func aggregate_stats() -> Dictionary:
	var totals := {
		"damage": 0.0,
		"health": 0.0,
		"move_speed": 0.0,
		"pickup": 0.0,
		"cooldown": 0.0,
		"experience": 0.0,
		"luck": 0.0,
		"damage_reduction": 0.0,
		"copper_bonus": 0.0,
		"life_steal": 0.0,
		"health_regen": 0.0,
		"starting_weapon": "sword",
		"rules": [],
	}
	for slot in SLOT_ORDER:
		var item := equipped_item(slot)
		if item.is_empty():
			continue
		var level_multiplier := 1.0 + int(item["level"]) * 0.08
		for key in item["stats"].keys():
			totals[key] = float(totals.get(key, 0.0)) + float(item["stats"][key]) * level_multiplier
		if slot == "weapon":
			totals["starting_weapon"] = item.get("weapon_key", "sword")
		var rule := String(item.get("rule", ""))
		if not rule.is_empty() and rule not in totals["rules"]:
			totals["rules"].append(rule)
	for talent_id in TALENT_ORDER:
		var talent: Dictionary = TALENT_DATA[talent_id]
		var rank := talent_rank(talent_id)
		var stat: String = talent["stat"]
		totals[stat] = float(totals[stat]) + float(talent["value"]) * rank
		var talent_rule := String(talent.get("rule_at_max", ""))
		if not talent_rule.is_empty() and rank >= int(talent["max_rank"]) and talent_rule not in totals["rules"]:
			totals["rules"].append(talent_rule)
	return totals


func talent_rank(talent_id: String) -> int:
	return int(talents.get(talent_id, 0))


func talent_cost(talent_id: String) -> int:
	var talent: Dictionary = TALENT_DATA[talent_id]
	return int(talent["base_cost"]) + talent_rank(talent_id) * int(talent["cost_step"])


func talent_requirements_met(talent_id: String) -> bool:
	var requirements: Dictionary = TALENT_DATA[talent_id]["requires"]
	for required_id in requirements:
		if talent_rank(String(required_id)) < int(requirements[required_id]):
			return false
	return true


func can_upgrade_talent(talent_id: String) -> bool:
	if not TALENT_DATA.has(talent_id):
		return false
	if talent_rank(talent_id) >= int(TALENT_DATA[talent_id]["max_rank"]):
		return false
	return talent_requirements_met(talent_id) and int(currencies["incense"]) >= talent_cost(talent_id)


func upgrade_talent(talent_id: String) -> bool:
	if not can_upgrade_talent(talent_id):
		return false
	currencies["incense"] -= talent_cost(talent_id)
	talents[talent_id] = talent_rank(talent_id) + 1
	save_data()
	return true


func item_description(item: Dictionary) -> String:
	if item.is_empty():
		return "尚未装备"
	var lines := PackedStringArray([
		"%s · %s" % [RARITY_NAMES[int(item["rarity"])], SLOT_NAMES[item["slot"]]],
		"强化 +%d / +5" % int(item["level"]),
	])
	if item.has("weapon_key"):
		lines.append("开局法器：%s" % _weapon_name(item["weapon_key"]))
	var rule := String(item.get("rule", ""))
	if not rule.is_empty():
		lines.append("特性·%s：%s" % [RULE_AFFIX_DATA[rule][0], RULE_AFFIX_DATA[rule][1]])
	var multiplier := 1.0 + int(item["level"]) * 0.08
	for key in item["stats"].keys():
		if key == "life_steal":
			lines.append("%s +%.2f%%（每秒最多恢复 2%% 生命）" % [STAT_NAMES[key], float(item["stats"][key]) * multiplier * 100.0])
		else:
			lines.append("%s +%.1f%%" % [STAT_NAMES[key], float(item["stats"][key]) * multiplier * 100.0])
	return "\n".join(lines)


func currency_text() -> String:
	return "香火 %d　器魄 %d　玄铁 %d　残卷 %d" % [currencies["incense"], currencies["essence"], currencies["iron"], currencies["scroll"]]


func _roll_rarity(stage: int, source: String) -> int:
	var minimum := 0
	var bonus := stage * 0.09
	if source == "elite":
		minimum = 1
		bonus += 0.16
	elif source == "boss":
		minimum = 2
		bonus += 0.26
	elif source == "first_clear":
		minimum = mini(5, 3 + stage)
		bonus += 0.35
	var roll := rng.randf() + bonus
	var rarity := 0
	if roll > 1.18:
		rarity = 5
	elif roll > 0.95:
		rarity = 4
	elif roll > 0.7:
		rarity = 3
	elif roll > 0.42:
		rarity = 2
	elif roll > 0.18:
		rarity = 1
	return maxi(minimum, rarity)


func _base_stats(slot: String, rarity: int) -> Dictionary:
	var scale := float(rarity + 1)
	match slot:
		"weapon":
			return {"damage": 0.035 * scale}
		"head":
			return {"cooldown": 0.018 * scale}
		"robe":
			return {"health": 0.045 * scale}
		"belt":
			return {"pickup": 0.035 * scale}
		"boots":
			return {"move_speed": 0.022 * scale}
		_:
			return {"experience": 0.025 * scale}


func _affix_value(key: String, rarity: int) -> float:
	var base_values := {
		"damage": 0.018,
		"health": 0.025,
		"move_speed": 0.014,
		"pickup": 0.022,
		"cooldown": 0.012,
		"experience": 0.016,
		"luck": 0.02,
		"damage_reduction": 0.008,
		"copper_bonus": 0.025,
		"life_steal": 0.0004,
	}
	return float(base_values[key]) * (1.0 + rarity * 0.42) * rng.randf_range(0.88, 1.14)


func _shuffle_strings(values: Array[String]) -> void:
	for index in values.size():
		var swap_index := rng.randi_range(index, values.size() - 1)
		var temporary := values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _weapon_name(key: String) -> String:
	var names := {
		"sword": "飞剑",
		"talisman": "符火",
		"thunder": "雷印",
		"bell": "镇魂铃",
		"coin": "铜钱镖",
		"orb": "阴阳玉",
		"chain": "缚妖索",
		"banner": "招魂幡",
		"paper_doll": "纸人术",
		"mirror": "八卦镜",
		"tide_gourd": "潮生葫",
		"ferry_oar": "引渡桨",
		"nether_lotus": "冥河莲灯",
		"ice_needles": "玄冰针",
		"frost_stele": "寒狱碑",
		"snow_umbrella": "六花伞",
	}
	return names.get(key, "飞剑")
