class_name TriadRunEngine
extends RefCounted

const PHASE_PLAYING := "playing"
const PHASE_REWARD := "reward"
const PHASE_GAME_OVER := "game_over"
const WILD_VALUE := -1

const LINES: Array[Dictionary] = [
	{"cells": [0, 1, 2], "name": "上横线", "diagonal": false, "center": 1},
	{"cells": [3, 4, 5], "name": "中横线", "diagonal": false, "center": 4},
	{"cells": [6, 7, 8], "name": "下横线", "diagonal": false, "center": 7},
	{"cells": [0, 3, 6], "name": "左竖线", "diagonal": false, "center": 3},
	{"cells": [1, 4, 7], "name": "中竖线", "diagonal": false, "center": 4},
	{"cells": [2, 5, 8], "name": "右竖线", "diagonal": false, "center": 5},
	{"cells": [0, 4, 8], "name": "主斜线", "diagonal": true, "center": 4},
	{"cells": [2, 4, 6], "name": "副斜线", "diagonal": true, "center": 4},
]

const BASE_THRESHOLDS: Array[int] = [50, 130, 240, 380, 560, 780, 1040, 1340]

const RULES: Array[Dictionary] = [
	{
		"id": "odd_tide", "title": "奇数潮汐", "category": "得分", "accent": "#F17B65",
		"desc": "奇数连线得分 ×1.7。", "note": "可叠加，倍率逐层连乘。", "max_stack": 3
	},
	{
		"id": "high_tide", "title": "高位回响", "category": "得分", "accent": "#E9B85D",
		"desc": "数值 3 以上的连线得分 ×1.35。", "note": "可叠加，越高阶越值得留下。", "max_stack": 3
	},
	{
		"id": "diagonal_echo", "title": "折光斜径", "category": "连线", "accent": "#72B8E8",
		"desc": "任意斜线得分 ×1.7。", "note": "两条斜线共享中心，适合交叉构筑。", "max_stack": 3
	},
	{
		"id": "center_cross", "title": "中心引力", "category": "场域", "accent": "#A18AE8",
		"desc": "经过棋盘中心线的得分 ×1.55。", "note": "中横、中竖与两条斜线全部受惠。", "max_stack": 3
	},
	{
		"id": "cascade_hymn", "title": "级联圣歌", "category": "连线", "accent": "#72D3B0",
		"desc": "第 2 段及之后级联，每段得分 +50%。", "note": "多段连锁时逐层放大。", "max_stack": 3
	},
	{
		"id": "single_note", "title": "孤线专注", "category": "得分", "accent": "#F4A8A0",
		"desc": "只消除 1 条线时，该线得分 ×1.5。", "note": "适合稳定、单线兼顾空间。", "max_stack": 3
	},
	{
		"id": "wild_line", "title": "幻色共振", "category": "连线", "accent": "#E3BE64",
		"desc": "包含万能块的连线得分 ×2。", "note": "万能块可替代任何数字。", "max_stack": 3
	},
	{
		"id": "empty_echo", "title": "留白生息", "category": "场域", "accent": "#6CC3C8",
		"desc": "结算时每个空位为每条线 +6 分。", "note": "保持棋盘疏朗也能稳定得分。", "max_stack": 3
	},
	{
		"id": "twin_bonus", "title": "双线协奏", "category": "连线", "accent": "#7EB7E9",
		"desc": "同时多消时，每多 1 条线额外 +80 分。", "note": "一次交叉形成 2–4 线时收益爆发。", "max_stack": 3
	},
	{
		"id": "streak_heat", "title": "连续热度", "category": "场域", "accent": "#F09A62",
		"desc": "连续落子成线会升温；每段热度 +20%。", "note": "断线即归零，最高 8 段热度。", "max_stack": 2
	},
	{
		"id": "quiet_flow", "title": "低语流速", "category": "生成", "accent": "#71C9A1",
		"desc": "新方块只会是 1 或 2，所有线得分 ×1.25。", "note": "更易成线，适合长局与空间流。", "max_stack": 2
	},
	{
		"id": "heavy_flow", "title": "沉重刻度", "category": "生成", "accent": "#E48763",
		"desc": "生成值 +1，所有线得分 ×1.15。", "note": "与低速流叠加后生成 2–3。", "max_stack": 2
	},
	{
		"id": "wild_seed", "title": "万能种子", "category": "生成", "accent": "#DEBF60",
		"desc": "每个新方块有 20% 概率成为万能块。", "note": "与任意数字组成三连线，最高 60%。", "max_stack": 3
	},
	{
		"id": "result_plus", "title": "再进一级", "category": "消除", "accent": "#EDC35D",
		"desc": "每次连消生成的中心产物额外 +1。", "note": "升级更快，也更容易产生级联。", "max_stack": 3
	},
	{
		"id": "wild_echo", "title": "余烬幻色", "category": "消除", "accent": "#BA9DEB",
		"desc": "连消后有 30% 概率在随机空位留下万能块。", "note": "每层提高触发概率，最高 75%。", "max_stack": 3
	},
	{
		"id": "second_wind", "title": "一线生机", "category": "场域", "accent": "#EE8C83",
		"desc": "获得 1 次救场：满盘无解时移除最低普通块。", "note": "可再次获得，次数会累计。", "max_stack": 2
	},
	{
		"id": "quiet_spark", "title": "静默火花", "category": "得分", "accent": "#72B6D3",
		"desc": "每次未成线落子获得 12 分。", "note": "为布局与等待提供最低保障。", "max_stack": 3
	},
	{
		"id": "heartbeat", "title": "稳定脉冲", "category": "场域", "accent": "#8FD1AD",
		"desc": "每第 4 次落子额外获得 25 分。", "note": "可叠加；计数跨回合保留。", "max_stack": 3
	},
	{
		"id": "contract", "title": "减法契约", "category": "场域", "accent": "#C7A7E8",
		"desc": "后续每次词条阈值降低 10%。", "note": "最多叠加 3 层，最低降低 30%。", "max_stack": 3
	},
]

var board: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
var pending_value := 1
var next_value := 1
var has_pending := true
var phase := PHASE_PLAYING
var score := 0
var turn := 1
var placements := 0
var lines_cleared := 0
var best_cascade := 1
var best_simultaneous := 1
var streak := 0
var rewards_selected := 0
var stacks: Dictionary = {}
var rescue_charges := 0
var rescues_used := 0
var pending_choices: Array[String] = []
var last_resolution: Dictionary = {}
var turn_events: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()


func start_run(seed_value: int = -1) -> void:
	_rng.randomize()
	if seed_value >= 0:
		_rng.seed = seed_value
	board = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	phase = PHASE_PLAYING
	score = 0
	turn = 1
	placements = 0
	lines_cleared = 0
	best_cascade = 1
	best_simultaneous = 1
	streak = 0
	rewards_selected = 0
	stacks.clear()
	rescue_charges = 0
	rescues_used = 0
	pending_choices.clear()
	last_resolution.clear()
	turn_events.clear()
	has_pending = true
	pending_value = _generate_value()
	next_value = _generate_value()


func place(index: int) -> Dictionary:
	if phase != PHASE_PLAYING:
		return {"ok": false, "reason": "not_playing"}
	if not has_pending:
		return {"ok": false, "reason": "no_pending"}
	if index < 0 or index >= board.size():
		return {"ok": false, "reason": "bad_index"}
	if board[index] != 0:
		return {"ok": false, "reason": "occupied"}

	var score_before := score
	var placed_value := pending_value
	board[index] = placed_value
	has_pending = false
	placements += 1
	turn += 1
	turn_events.clear()
	turn_events.append({
		"kind": "place",
		"index": index,
		"value": placed_value,
		"text": "落下 %s" % ("万能块" if placed_value == WILD_VALUE else str(placed_value)),
	})

	var immediate_matches := get_matches()
	if immediate_matches.is_empty():
		streak = 0
	else:
		streak = mini(streak + 1, 8)

	var resolution := _resolve_board()
	resolution["placed_index"] = index
	resolution["placed_value"] = placed_value
	resolution["turn"] = placements

	if int(resolution.get("lines_cleared", 0)) == 0 and _stack("quiet_spark") > 0:
		var spark_score := 12 * _stack("quiet_spark")
		score += spark_score
		resolution["bonus_score"] = int(resolution.get("bonus_score", 0)) + spark_score
		turn_events.append({
			"kind": "bonus",
			"score": spark_score,
			"text": "静默火花 +%d" % spark_score,
		})

	if placements % 4 == 0 and _stack("heartbeat") > 0:
		var pulse_score := 25 * _stack("heartbeat")
		score += pulse_score
		resolution["bonus_score"] = int(resolution.get("bonus_score", 0)) + pulse_score
		turn_events.append({
			"kind": "bonus",
			"score": pulse_score,
			"text": "稳定脉冲 +%d" % pulse_score,
		})

	resolution["score_gain"] = score - score_before
	resolution["score_total"] = score
	resolution["streak"] = streak
	last_resolution = resolution
	_advance_after_actions()
	return {"ok": true, "resolution": last_resolution, "phase": phase}


func choose_rule(rule_id: String) -> Dictionary:
	if phase != PHASE_REWARD or not pending_choices.has(rule_id):
		return {"ok": false, "reason": "invalid_choice"}
	var definition := get_rule(rule_id)
	if definition.is_empty():
		return {"ok": false, "reason": "unknown_rule"}

	stacks[rule_id] = _stack(rule_id) + 1
	if rule_id == "second_wind":
		rescue_charges += 1
	rewards_selected += 1
	pending_choices.clear()
	turn_events.append({
		"kind": "rule",
		"rule_id": rule_id,
		"text": "词条「%s」生效" % String(definition["title"]),
	})

	if score >= next_threshold() and _has_available_rules():
		_begin_reward()
	else:
		_finish_turn()
	return {"ok": true, "phase": phase}


func get_matches() -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for line in LINES:
		var cells: Array = line["cells"]
		var reference := _line_reference(cells)
		if reference < 0:
			continue
		matches.append({
			"cells": cells.duplicate(),
			"name": String(line["name"]),
			"center": int(line["center"]),
			"diagonal": bool(line["diagonal"]),
			"value": reference,
			"wild": _line_has_wild(cells),
		})
	return matches


func next_threshold() -> int:
	var base := _base_threshold(rewards_selected)
	var discount := 0.1 * _stack("contract")
	return int(round(base * maxf(0.7, 1.0 - discount)))


func threshold_before(level: int) -> int:
	return _base_threshold(maxi(0, level - 1))


func _base_threshold(level: int) -> int:
	if level < BASE_THRESHOLDS.size():
		return BASE_THRESHOLDS[level]
	var extra_level := level - BASE_THRESHOLDS.size() + 1
	return BASE_THRESHOLDS[BASE_THRESHOLDS.size() - 1] + 450 * extra_level + 100 * extra_level * extra_level


func get_rule(rule_id: String) -> Dictionary:
	for definition in RULES:
		if String(definition["id"]) == rule_id:
			return definition
	return {}


func get_rule_stack(rule_id: String) -> int:
	return _stack(rule_id)


func pending_text() -> String:
	if not has_pending:
		return "—"
	if pending_value == WILD_VALUE:
		return "✦"
	return str(pending_value)


func next_text() -> String:
	if next_value == WILD_VALUE:
		return "✦"
	return str(next_value)


func is_deadlocked() -> bool:
	return _board_is_full() and get_matches().is_empty()


func _resolve_board() -> Dictionary:
	var score_start := score
	var all_lines: Array[Dictionary] = []
	var all_results: Array[Dictionary] = []
	var wild_echo_index := -1
	var echo_checked := false
	var cascade := 0
	var safety_stop := false

	while true:
		var matches := get_matches()
		if matches.is_empty():
			if cascade > 0 and wild_echo_index < 0 and not echo_checked and _stack("wild_echo") > 0:
				echo_checked = true
				wild_echo_index = _try_wild_echo()
				if wild_echo_index >= 0:
					turn_events.append({
						"kind": "wild_echo",
						"index": wild_echo_index,
						"text": "余烬幻色：空格再生万能块",
					})
					matches = get_matches()
			if matches.is_empty():
				break

		cascade += 1
		best_cascade = maxi(best_cascade, cascade)
		best_simultaneous = maxi(best_simultaneous, matches.size())
		var empty_before := _empty_count()
		var cleared: Dictionary = {}
		var result_steps: Dictionary = {}
		var cascade_lines: Array[Dictionary] = []

		for match_line in matches:
			var cells: Array = match_line["cells"]
			for cell in cells:
				cleared[int(cell)] = true
			var line_score := _calculate_line_score(match_line, matches.size(), empty_before, cascade)
			var increment := int(match_line["value"]) + 1 + _stack("result_plus")
			var center := int(match_line["center"])
			result_steps[center] = int(result_steps.get(center, 0)) + increment
			var line_record: Dictionary = match_line.duplicate(true)
			line_record["score"] = line_score
			line_record["cascade"] = cascade
			line_record["result_increment"] = increment
			cascade_lines.append(line_record)
			all_lines.append(line_record)
			score += line_score
			lines_cleared += 1

		if matches.size() > 1 and _stack("twin_bonus") > 0:
			var multi_bonus := 80 * (matches.size() - 1) * _stack("twin_bonus")
			score += multi_bonus
			turn_events.append({
				"kind": "multi_bonus",
				"score": multi_bonus,
				"text": "%d 线同消 +%d" % [matches.size(), multi_bonus],
			})

		for cell in cleared.keys():
			board[int(cell)] = 0
		for center in result_steps.keys():
			var result_value := int(result_steps[center])
			board[int(center)] = result_value
			all_results.append({
				"index": int(center),
				"value": result_value,
				"cascade": cascade,
			})

		if cascade >= 20:
			safety_stop = true
			break

	return {
		"lines": all_lines,
		"lines_cleared": all_lines.size(),
		"results": all_results,
		"cascades": cascade,
		"wild_echo_index": wild_echo_index,
		"bonus_score": 0,
		"score_gain": score - score_start,
		"score_total": score,
		"safety_stop": safety_stop,
	}


func _calculate_line_score(match_line: Dictionary, simultaneous: int, empty_cells: int, cascade: int) -> int:
	var value := int(match_line["value"])
	var line_score := 22.0 + value * 11.0 + value * value * 2.0

	if value % 2 == 1:
		line_score *= pow(1.7, _stack("odd_tide"))
	if value >= 3:
		line_score *= pow(1.35, _stack("high_tide"))
	if bool(match_line["diagonal"]):
		line_score *= pow(1.7, _stack("diagonal_echo"))
	if _line_contains_center(match_line["cells"]):
		line_score *= pow(1.55, _stack("center_cross"))
	if simultaneous == 1:
		line_score *= pow(1.5, _stack("single_note"))
	if bool(match_line["wild"]):
		line_score *= pow(2.0, _stack("wild_line"))
	if _stack("cascade_hymn") > 0 and cascade > 1:
		line_score *= pow(1.0 + 0.5 * (cascade - 1), _stack("cascade_hymn"))
	if _stack("quiet_flow") > 0:
		line_score *= pow(1.25, _stack("quiet_flow"))
	if _stack("heavy_flow") > 0:
		line_score *= pow(1.15, _stack("heavy_flow"))
	if _stack("streak_heat") > 0 and streak > 0:
		line_score *= pow(1.0 + 0.2 * mini(streak, 8), _stack("streak_heat"))
	line_score += empty_cells * 6 * _stack("empty_echo")
	return maxi(1, int(round(line_score)))


func _advance_after_actions() -> void:
	if score >= next_threshold() and _has_available_rules():
		_begin_reward()
	else:
		_finish_turn()


func _finish_turn() -> void:
	if is_deadlocked() and rescue_charges > 0:
		_use_rescue()
	if is_deadlocked():
		phase = PHASE_GAME_OVER
		pending_value = 0
		has_pending = false
		return
	phase = PHASE_PLAYING
	pending_value = next_value
	next_value = _generate_value()
	has_pending = true


func _begin_reward() -> void:
	phase = PHASE_REWARD
	pending_choices.clear()
	var eligible: Array[Dictionary] = []
	for definition in RULES:
		var id := String(definition["id"])
		if _stack(id) < int(definition["max_stack"]):
			eligible.append(definition)
	if eligible.size() < 2:
		for definition in eligible:
			pending_choices.append(String(definition["id"]))
		return

	_shuffle_with_rng(eligible)
	var first: Dictionary = eligible[0]
	pending_choices.append(String(first["id"]))
	for candidate in eligible:
		if String(candidate["category"]) != String(first["category"]):
			pending_choices.append(String(candidate["id"]))
			break
	if pending_choices.size() < 2:
		for candidate in eligible:
			var id := String(candidate["id"])
			if not pending_choices.has(id):
				pending_choices.append(id)
				break


func _has_available_rules() -> bool:
	for definition in RULES:
		if _stack(String(definition["id"])) < int(definition["max_stack"]):
			return true
	return false


func _generate_value() -> int:
	var wild_chance := minf(0.75, 0.2 * _stack("wild_seed"))
	if wild_chance > 0.0 and _rng.randf() < wild_chance:
		return WILD_VALUE

	var value := 1
	var roll := _rng.randf()
	if roll < 0.55:
		value = 1
	elif roll < 0.88:
		value = 2
	else:
		value = 3
	if _stack("quiet_flow") > 0:
		value = 1 if _rng.randf() < 0.55 else 2
	if _stack("heavy_flow") > 0:
		value += _stack("heavy_flow")
	return value


func _try_wild_echo() -> int:
	if not is_deadlocked():
		pass
	var empties: Array[int] = []
	for i in board.size():
		if board[i] == 0:
			empties.append(i)
	if empties.is_empty():
		return -1
	var chance := minf(0.75, 0.3 * _stack("wild_echo"))
	if _rng.randf() >= chance:
		return -1
	var index := empties[_rng.randi_range(0, empties.size() - 1)]
	board[index] = WILD_VALUE
	return index


func _use_rescue() -> void:
	var candidates: Array[int] = []
	var lowest := 999999
	for i in board.size():
		var value := board[i]
		if value <= 0:
			continue
		if value < lowest:
			lowest = value
			candidates.clear()
			candidates.append(i)
		elif value == lowest:
			candidates.append(i)
	if candidates.is_empty():
		for i in board.size():
			if board[i] == 0:
				candidates.append(i)
	if candidates.is_empty():
		return
	var target := candidates[_rng.randi_range(0, candidates.size() - 1)]
	var removed_value := board[target]
	board[target] = 0
	rescue_charges -= 1
	rescues_used += 1
	turn_events.append({
		"kind": "rescue",
		"index": target,
		"text": "一线生机：移除 %d" % removed_value,
	})


func _line_reference(cells: Array) -> int:
	var reference := 0
	for cell in cells:
		var value := board[int(cell)]
		if value == 0:
			return -1
		if value == WILD_VALUE:
			continue
		if reference == 0:
			reference = value
		elif reference != value:
			return -1
	return 1 if reference == 0 else reference


func _line_has_wild(cells: Array) -> bool:
	for cell in cells:
		if board[int(cell)] == WILD_VALUE:
			return true
	return false


func _line_contains_center(cells: Array) -> bool:
	return cells.has(4)


func _empty_count() -> int:
	var count := 0
	for value in board:
		if value == 0:
			count += 1
	return count


func _board_is_full() -> bool:
	for value in board:
		if value == 0:
			return false
	return true


func _stack(rule_id: String) -> int:
	return int(stacks.get(rule_id, 0))


func _shuffle_with_rng(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
