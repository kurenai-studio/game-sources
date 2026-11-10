class_name StoryQuests
# ---------- Задания ----------
# Основные (сюжетные) и побочные. Каждое задание — цепочка шагов; у шага
# может быть счётчик (ударить манекен 10 раз). Награда — опыт и вещи.

const DB := {
	"awakening": {"name": "Пробуждение", "main": true,
			"steps": [
				{"text": "Осмотри сундук рядом с собой"},
				{"text": "Надень найденное снаряжение (рюкзак)"},
				{"text": "Изучи свиток способности (рюкзак → «Вещи»)"},
				{"text": "Найди дверь, к которой подходит старый ключ"},
			],
			"reward": {"xp": 60}, "desc": "Ты очнулся в поле. Кто ты и как здесь оказался — неизвестно."},
	"warmup": {"name": "Разминка", "main": false,
			"steps": [{"text": "Ударь тренировочное чучело", "count": 10}],
			"reward": {"xp": 30}, "desc": "Рядом стоит соломенное чучело. Самое время вспомнить, как держать оружие."},
	"bandits": {"name": "Незваные гости", "main": false,
			"steps": [{"text": "Прогони разбойников на востоке", "count": 3}],
			"reward": {"xp": 80, "items": {"potion_hp": 2}}, "desc": "На восточной тропе кто-то шумит. Похоже, разбойники."},
}

static func start_state() -> Dictionary:
	return {"awakening": {"step": 0, "n": 0, "done": false},
			"warmup": {"step": 0, "n": 0, "done": false},
			"bandits": {"step": 0, "n": 0, "done": false}}

static func step_text(qid: String, st: Dictionary) -> String:
	var q: Dictionary = DB[qid]
	if st.get("done", false):
		return "Выполнено"
	var step: Dictionary = q["steps"][int(st["step"])]
	if step.has("count"):
		return "%s (%d/%d)" % [step["text"], int(st["n"]), int(step["count"])]
	return step["text"]

# Продвинуть задание, если оно сейчас на шаге step. Возвращает награду (или {}), если задание завершилось.
static func advance(d: Dictionary, qid: String, step: int, amount := 1) -> Dictionary:
	var qs: Dictionary = d.get("quests", {})
	if not qs.has(qid):
		return {}
	var st: Dictionary = qs[qid]
	if st.get("done", false) or int(st["step"]) != step:
		return {}
	var s: Dictionary = DB[qid]["steps"][step]
	if s.has("count"):
		st["n"] = int(st["n"]) + amount
		if int(st["n"]) < int(s["count"]):
			return {"progress": true}
	st["step"] = step + 1
	st["n"] = 0
	if int(st["step"]) >= DB[qid]["steps"].size():
		st["done"] = true
		return DB[qid].get("reward", {}).merged({"done": true})
	return {"progress": true}
