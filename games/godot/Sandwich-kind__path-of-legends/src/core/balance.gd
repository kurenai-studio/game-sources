class_name Balance
# ---------- Баланс легенд: отдельно для Дуэли и для Арены ----------
# Базовые числа легенды — в characters.gd. Здесь — поправки поверх них.
#
#   Дуэль — способности такие, как задуманы (базовые числа). Только постройки
#           ломаются чуть быстрее, чтобы карта разрушалась в бою.
#   Арена — те же способности, но в усиленном виде (больше стрел, шире взрыв,
#           дольше действует — см. наборы легенд, проверка Balance.arena(p)),
#           плюс больше здоровья и чуть сильнее урон. Перезарядки не сокращаются,
#           чтобы нельзя было победить одной кнопкой.
#
# Ключи поправок:
#   hp        — множитель здоровья
#   dmg       — множитель всего урона легенды по противникам
#   boss_dmg  — множитель урона по боссам и мини-боссам (Арена)
#   stagger   — как быстро легенда «пошатывает» босса до оглушения (Арена)
#   cds       — свои перезарядки способностей [1, 2, 3] (секунды)
#   cd_mult   — множитель всех перезарядок способностей
#   ult_mult  — множитель заряда ульты (меньше — ульта копится быстрее)
#   cell      — множитель урона по блокам и постройкам
#   blast     — множитель радиуса взрывов легенды
#   speed     — множитель скорости бега
# TESTIK_1 и UBER_TESTIK_2 (без набора способностей) не трогаются ни в одном режиме.

# Общие поправки режима — для всех легенд
const BASE := {
	"duel":  {"cell": 1.6},
	"arena": {"hp": 1.25, "dmg": 1.15},
}

const DUEL := {}

const ARENA := {
	# Охотница стреляет редко, но метко — по боссам бьёт сильнее и быстрее их оглушает
	"hunter":    {"hp": 1.3, "dmg": 1.2, "boss_dmg": 1.4, "stagger": 1.8},
	# Кузнец и так бьёт вблизи часто и сильно — зато крепче
	"smith":     {"hp": 1.35, "dmg": 1.1, "boss_dmg": 0.85, "stagger": 0.8},
	"champion":  {"boss_dmg": 1.15, "stagger": 1.1},
	# Терновник, Мортис и Самурай слабее других обычной атакой — подтягиваем
	"ternovnik": {"dmg": 1.4, "boss_dmg": 1.3, "stagger": 1.3},
	# Мортис: скелеты и кости-обереги на Арене откатываются дольше, чем в Дуэли
	"mortis":    {"dmg": 1.35, "boss_dmg": 1.0, "stagger": 1.0, "cds": [13.0, 22.0, 10.0]},
	"soldier":   {"boss_dmg": 1.1, "stagger": 1.0},
	"samurai":   {"hp": 1.35, "dmg": 1.35, "boss_dmg": 1.1, "stagger": 1.2},
	"prism":     {"hp": 1.3, "dmg": 1.25, "boss_dmg": 1.1, "stagger": 1.1},
	"assassin":  {"boss_dmg": 1.15, "stagger": 1.2},
	# Осока бьёт комьями по дуге — не быстро, зато держит поле лужами
	"osoka":     {"hp": 1.3, "dmg": 1.45, "boss_dmg": 1.15, "stagger": 1.2},
	# Зарница: частые лёгкие искры, много урона по площади от молний — чуть крепче на Арене
	"zarnitsa":  {"hp": 1.3, "dmg": 1.3, "boss_dmg": 1.1, "stagger": 1.15},
	# Рассвет бьёт вблизи и держит удар — чуть меньше бонуса к здоровью
	"rassvet":   {"hp": 1.25, "dmg": 1.3, "boss_dmg": 1.1, "stagger": 1.2},
	"pivozavr":  {"hp": 1.3, "dmg": 1.3, "boss_dmg": 1.1, "stagger": 1.1},
}

# Боссы Арены: сколько урона (доля здоровья) нужно, чтобы босс пошатнулся и был оглушён
const STAGGER_SHARE := 0.10
const STAGGER_STUN := 2.2          # сколько секунд оглушён
const STAGGER_COOLDOWN := 9.0      # после оглушения — столько секунд не копится

static func hero_key(p: Player) -> String:
	return String(p.kit.hero) if p.kit else ""

static func get_mods(mode: String, key: String) -> Dictionary:
	if key == "":
		return {}                      # тестовые легенды — как есть
	var t: Dictionary = ARENA if mode == "arena" else DUEL
	var m: Dictionary = (BASE.get(mode, {}) as Dictionary).duplicate()
	m.merge(t.get(key, {}), true)
	return m

static func apply(p: Player, mode: String) -> void:
	var m := get_mods(mode, hero_key(p))
	if m.has("hp"):
		p.max_hp = int(round(p.max_hp * float(m["hp"])))
		p.hp = p.max_hp
	if m.has("cds"):
		p.ability_cds = (m["cds"] as Array).duplicate()
	var cdm := float(m.get("cd_mult", 1.0))
	if cdm != 1.0:
		for i in p.ability_cds.size():
			p.ability_cds[i] = float(p.ability_cds[i]) * cdm
	if m.has("ult_mult"):
		p.ult_need *= float(m["ult_mult"])
	if m.has("speed"):
		p.speed *= float(m["speed"])
	p.set_meta("bal_mode", mode)
	p.set_meta("bal_dmg", float(m.get("dmg", 1.0)))
	p.set_meta("boss_dmg", float(m.get("boss_dmg", 1.0)))
	p.set_meta("stagger", float(m.get("stagger", 1.0)))
	p.set_meta("cd_mult", cdm)
	p.set_meta("ult_mult", float(m.get("ult_mult", 1.0)))
	p.set_meta("cell_mult", float(m.get("cell", 1.0)))
	p.set_meta("blast_mult", float(m.get("blast", 1.0)))

# Призванные союзники (скелеты, деревца, приманки) бьют с теми же поправками, что и хозяин
static func inherit(minion: Node, owner: Node) -> void:
	for k in ["bal_dmg", "cell_mult", "blast_mult"]:
		if owner.has_meta(k):
			minion.set_meta(k, owner.get_meta(k))

# Множитель урона по блокам и радиуса взрывов того, кто бьёт
static func cell_mult(attacker) -> float:
	if attacker != null and is_instance_valid(attacker) and attacker is Node:
		return float(attacker.get_meta("cell_mult", 1.0))
	return 1.0

static func blast_mult(attacker) -> float:
	if attacker != null and is_instance_valid(attacker) and attacker is Node:
		return float(attacker.get_meta("blast_mult", 1.0))
	return 1.0

# Легенда на Арене — способности работают в усиленном виде
static func arena(p: Node) -> bool:
	return p != null and is_instance_valid(p) and String(p.get_meta("bal_mode", "")) == "arena"
