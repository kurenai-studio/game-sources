extends RefCounted
## The generated players: names, ratings shaped by a style, and the techniques
## and weak spots each starts with. Also the generated clubs of the world.

const Roster := preload("res://scripts/roster.gd")
const Gear := preload("res://scripts/gear.gd")
const Skills := preload("res://scripts/skills.gd")

const SURNAMES := ["王", "李", "张", "刘", "陈", "杨", "赵", "黄", "周", "吴", "徐", "孙", "马", "朱", "胡", "郭", "何", "林", "罗", "高", "梁", "宋", "郑", "谢", "韩", "唐", "冯", "于", "董", "萧"]
const GIVEN := ["子轩", "浩然", "一鸣", "宇航", "思远", "嘉豪", "泽宇", "博文", "天佑", "俊杰", "明哲", "晨阳", "星辰", "皓轩", "景行", "子墨", "亦凡", "沐阳", "承恩", "启航"]


## Fills in whatever a player is missing: the techniques and weak spots he
## starts with, condition and the default gear.
static func ensure(p: Dictionary) -> void:
	if not p.has("skills"):
		# a legend's techniques are its own traits (Skills.known reads them)
		p["skills"] = [] if p.has("traits") else Skills.seed_skills(p)
	if not p.has("flaws"):
		p["flaws"] = [] if p.has("traits") else Skills.seed_flaws(p)
	for k in ["cond", "injured", "gear"]:
		if not p.has(k):
			p[k] = {"cond": 100.0, "injured": 0, "gear": Gear.default_ids(p)}[k]


## A new player around `level` overall, with a unique name and ratings shaped
## by his style (loopers power and spin, fast attackers feet and backhand).
static func make_player(taken: Array, age: int, level: float) -> Dictionary:
	var name := ""
	for i in 80:
		name = SURNAMES.pick_random() + GIVEN.pick_random()
		if not taken.has(name):
			break
	taken.append(name)
	var style: String = ["loop", "fast", "all"].pick_random()
	var lean: Dictionary = {"loop": {"power": 5, "spin": 5, "fh": 3}, "fast": {"foot": 5, "bh": 4, "receive": 3}, "all": {"iq": 5, "serve": 4, "mental": 3}}[style]
	var a := []
	for at in Roster.ATTRS:
		a.append(snappedf(clampf(level + randf_range(-6.0, 6.0) + float(lean.get(at[0], 0)) - 2.0, 42.0, 94.0), 1.0))
	var p := {"name": name, "age": age, "grip": ["shake", "shake", "shake", "rpb", "pen"].pick_random(), "style": style, "a": a}
	ensure(p)
	return p


const NEW_CLUBS := [
	# [id, name, short, colour, division, level]
	["xc", "西川熊猫", "西川", Color(0.300, 0.700, 0.400), 1, 78.0],
	["dh", "东湖白鹭", "东湖", Color(0.600, 0.850, 0.950), 1, 74.0],
	["js", "金沙火焰", "金沙", Color(0.950, 0.400, 0.200), 2, 72.0],
	["xs", "雪山猎鹰", "雪山", Color(0.850, 0.850, 0.950), 2, 70.0],
	["bh", "滨海海燕", "滨海", Color(0.200, 0.500, 0.800), 2, 69.0],
	["gc", "古城青龙", "古城", Color(0.200, 0.600, 0.500), 2, 67.0],
	["xg", "星港闪电", "星港", Color(0.950, 0.850, 0.200), 2, 66.0],
	["yl", "云岭苍鹰", "云岭", Color(0.550, 0.450, 0.800), 2, 64.0],
]


## The rest of the world: eight more clubs of five players each.
static func generate_world(taken: Array) -> Dictionary:
	var clubs := []
	for c in NEW_CLUBS:
		var ps := []
		for i in 5:
			var age := randi_range(18, 32)
			ps.append(make_player(taken, age, float(c[5]) + randf_range(-5.0, 5.0)))
		clubs.append({"id": c[0], "name": c[1], "short": c[2], "color": c[3], "div": c[4], "players": ps})
	return {"clubs": clubs}
