extends RefCounted
## Players and clubs for the team mode. Each player has ten ratings (40..95)
## that replace the old fixed difficulty levels: they are mapped onto the same
## match parameters the levels used (stroke pace, spin, footwork speed, spin
## reading, error, tactics), plus per-wing precision, serve quality, stamina
## economy and nerve under pressure. Clubs, players and the four legends (the
## bosses) are all fictional.

const Gear := preload("res://scripts/gear.gd")

const ATTRS := [
	["fh", "正手"], ["bh", "反手"], ["serve", "发球"], ["receive", "接发"], ["foot", "步法"],
	["power", "力量"], ["spin", "旋转"], ["stamina", "体能"], ["mental", "心理"], ["iq", "战术"],
]
const STYLES := {
	"loop": {"name": "弧圈结合快攻", "desc": "中远台拉冲，旋转重", "loop": 0.25},
	"fast": {"name": "近台快攻", "desc": "站位近、借力快打，抢先上手", "loop": -0.15},
	"all": {"name": "全面型", "desc": "攻防均衡，善于变化", "loop": 0.0},
}
# the old difficulty table's two ends; ratings 40..95 map linearly between them
const LO := {"speed": 0.85, "spin": 0.8, "kick": 0.5, "ai_speed": 2.3, "ai_read": 0.6, "ai_err": 0.6, "tactic": 0.1, "precision": 1.3, "ai_reach": 0.14}
const HI := {"speed": 1.55, "spin": 1.5, "kick": 2.4, "ai_speed": 5.2, "ai_read": 0.97, "ai_err": 0.08, "tactic": 0.95, "precision": 0.42, "ai_reach": 0.22}

const CLUBS := [
	{"id": "jc", "name": "江城龙舟", "short": "江城", "color": Color(0.900, 0.080, 0.120), "players": [
		{"name": "林远航", "age": 24, "grip": "shake", "style": "loop", "a": [88, 82, 80, 78, 80, 86, 88, 76, 74, 80]},
		{"name": "周子墨", "age": 21, "grip": "rpb", "style": "fast", "a": [80, 84, 76, 82, 86, 74, 78, 84, 70, 74]},
		{"name": "许嘉禾", "age": 28, "grip": "shake", "style": "all", "a": [76, 80, 84, 80, 72, 70, 76, 70, 86, 86]},
		{"name": "陈小满", "age": 18, "grip": "pen", "style": "fast", "a": [78, 66, 72, 70, 82, 70, 68, 88, 62, 64]},
	]},
	{"id": "hg", "name": "海港蓝鲸", "short": "海港", "color": Color(0.220, 0.460, 0.780), "players": [
		{"name": "顾承泽", "age": 26, "grip": "shake", "style": "loop", "a": [90, 80, 82, 80, 78, 90, 90, 78, 80, 82]},
		{"name": "沈一帆", "age": 23, "grip": "shake", "style": "all", "a": [80, 86, 80, 84, 80, 76, 80, 80, 78, 80]},
		{"name": "唐秋白", "age": 30, "grip": "pen", "style": "fast", "a": [82, 70, 88, 76, 74, 74, 80, 66, 84, 88]},
		{"name": "叶星河", "age": 19, "grip": "rpb", "style": "loop", "a": [78, 76, 70, 70, 80, 82, 80, 86, 64, 66]},
	]},
	{"id": "bl", "name": "北岭雪狼", "short": "北岭", "color": Color(0.960, 0.960, 0.940), "players": [
		{"name": "韩铁柱", "age": 27, "grip": "shake", "style": "loop", "a": [84, 74, 74, 72, 72, 92, 86, 82, 72, 70]},
		{"name": "魏青松", "age": 25, "grip": "pen", "style": "fast", "a": [80, 68, 80, 74, 84, 76, 72, 78, 76, 76]},
		{"name": "宋知远", "age": 22, "grip": "shake", "style": "all", "a": [74, 78, 72, 78, 76, 70, 74, 80, 70, 76]},
		{"name": "白一鸣", "age": 31, "grip": "shake", "style": "all", "a": [70, 74, 80, 76, 64, 64, 72, 62, 84, 84]},
	]},
	{"id": "nw", "name": "南湾飞鱼", "short": "南湾", "color": Color(0.980, 0.520, 0.150), "players": [
		{"name": "罗海生", "age": 20, "grip": "rpb", "style": "loop", "a": [72, 74, 68, 66, 76, 76, 74, 84, 60, 62]},
		{"name": "苏木", "age": 24, "grip": "shake", "style": "fast", "a": [70, 76, 70, 72, 78, 66, 68, 78, 66, 68]},
		{"name": "郑小舟", "age": 17, "grip": "pen", "style": "fast", "a": [74, 60, 70, 64, 78, 66, 64, 86, 58, 60]},
		{"name": "钱老三", "age": 34, "grip": "pen", "style": "all", "a": [66, 62, 82, 74, 58, 60, 74, 56, 82, 82]},
	]},
]


## Boss challenges (BOSS 战): ratings above the world-class ceiling plus
## signature traits the match code reads (see main.gd has_trait):
##   clutch   tight points make them better, not worse
##   adapt    reads where you lose points much faster and keeps going there
##   third    serves short and attacks the third ball most points
##   lefty    left-handed (the forehand is on the other side)
##   cloud    云手: a huge forehand from mid-distance, heavy sidespin, wide angles
##   fh_heavy steps round to use the forehand from further into the backhand side
##   twist    霸王拧: short balls to the backhand get flicked with a banana flick
##   early    takes the ball early, on the rise
##   fighter  藏獒: plays harder and steadier when behind or facing game point
##   heavy    every stroke carries extra spin and weight (重球)
##   grind    gets stronger the longer the rally (相持)
const BOSSES := [
	{"id": "ml", "name": "龙马", "title": "六边形战士", "age": 36, "grip": "shake", "style": "all",
			"traits": ["clutch", "adapt", "third"], "hand": 1,
			"a": [97, 94, 98, 98, 92, 92, 95, 90, 99, 99],
			"notes": [["六边形", "没有短板，正反手、发接发、相持都顶级"], ["读你", "很快看出你在哪丢分，然后一直打那里"],
					["前三板", "发球变化多，第三板抢攻凶"], ["大心脏", "越到关键分越稳"]]},
	{"id": "xx", "name": "大蟒", "title": "云手", "age": 35, "grip": "rpb", "style": "loop",
			"traits": ["lefty", "cloud", "fh_heavy", "weak_bh"], "hand": -1,
			"a": [98, 80, 92, 86, 96, 95, 97, 88, 84, 92],
			"notes": [["左手直拍横打", "正手在另一侧，落点要反过来想"], ["云手", "退台后正手大幅度拉冲，侧旋重、角度大"],
					["满台跑", "步法大、覆盖广，大部分球都侧身用正手"], ["反手弱点", "反手位是突破口，但他会侧身抢"]]},
	{"id": "zjk", "name": "藏獒", "title": "霸王拧", "age": 37, "grip": "shake", "style": "fast",
			"traits": ["twist", "early", "fighter", "hothead"], "hand": 1,
			"a": [94, 98, 90, 96, 92, 95, 92, 84, 97, 92],
			"notes": [["霸王拧", "台内短球到反手，直接反手拧拉上手"], ["快", "站位近，上升期借力快打"],
					["藏獒", "落后或被逼到局点时更凶更稳"], ["体能", "长回合、多局之后会慢下来"]]},
	{"id": "fzd", "name": "小胖", "title": "正反手重炮", "age": 29, "grip": "shake", "style": "loop",
			"traits": ["heavy", "grind"], "hand": 1,
			"a": [97, 98, 90, 92, 90, 99, 97, 97, 93, 93],
			"notes": [["重炮", "正反手都能发力，每一板都又转又沉"], ["反手", "反手质量和正手一样，压反手没用"],
					["相持", "回合越长越强，体能好"], ["突破口", "前三板快速变线，别跟他拼相持"]]},
]


static func boss(id: String) -> Dictionary:
	for b in BOSSES:
		if b.id == id:
			return b
	return BOSSES[0]


static func club(id: String) -> Dictionary:
	for c in CLUBS:
		if c.id == id:
			return c
	return CLUBS[0]


static func attr(p: Dictionary, key: String) -> int:
	for i in ATTRS.size():
		if ATTRS[i][0] == key:
			return p.a[i]
	return 60


## Ratings as they play today: a player low on condition (状态, 0..100) plays
## up to 12% below their ratings.
static func effective(p: Dictionary) -> Dictionary:
	var cond: float = p.get("cond", 100.0)
	if cond >= 100.0:
		return p
	var e := p.duplicate()
	var k := 0.88 + 0.12 * cond / 100.0
	e.a = p.a.map(func(v): return v * k)
	return e


static func overall(p: Dictionary) -> int:
	var s := 0.0
	for v in p.a:
		s += v
	return int(round(s / p.a.size()))


static func level_name(ovr: int) -> String:
	if ovr >= 90:
		return "BOSS"
	if ovr >= 82:
		return "世界级"
	if ovr >= 74:
		return "专业"
	if ovr >= 66:
		return "业余"
	return "入门"


## 40..95 rating -> 0..1; boss ratings above 95 go a little past world class
static func t(v: float) -> float:
	return clampf((v - 40.0) / 55.0, 0.0, 1.1)


## Boss ratings above 95 sharpen control, reading, feet and tactics, but pace
## and spin stop at world class: past it, shots and serves no longer land.
static func _mix(key: String, v: float) -> float:
	var k := t(v) if key in ["ai_speed", "ai_read", "ai_err", "tactic", "precision", "ai_reach"] else minf(t(v), 1.0)
	return lerpf(LO[key], HI[key], k)


## Match parameters for a player: every key the old difficulty levels had, so
## the match code reads them the same way, plus the extras only ratings give.
static func params(p: Dictionary) -> Dictionary:
	var ctrl := (attr(p, "fh") + attr(p, "bh")) * 0.5
	var ovr := overall(p)
	return {
		"name": level_name(ovr),
		"speed": _mix("speed", attr(p, "power")),
		"spin": _mix("spin", attr(p, "spin")),
		"kick": _mix("kick", ovr),
		"ai_speed": _mix("ai_speed", attr(p, "foot")),
		"ai_read": _mix("ai_read", attr(p, "receive")),
		"ai_err": _mix("ai_err", ctrl),
		"reach": 0.30,
		"tactic": _mix("tactic", attr(p, "iq")),
		"precision": _mix("precision", ctrl),
		"ai_reach": _mix("ai_reach", attr(p, "foot")),
		# extras
		"prec_fh": _mix("precision", attr(p, "fh")),
		"prec_bh": _mix("precision", attr(p, "bh")),
		"pow_fh": lerpf(0.94, 1.05, t(attr(p, "fh"))),
		"pow_bh": lerpf(0.94, 1.05, t(attr(p, "bh"))),
		"serve_q": lerpf(0.72, 1.0, t(attr(p, "serve"))),
		"serve_spin": lerpf(0.85, 1.0, minf(t(attr(p, "serve")), 1.0)),
		"tire": lerpf(1.35, 0.75, t(attr(p, "stamina"))),
		"nerve": t(attr(p, "mental")),
		"loop": float(STYLES[p.style].loop),
		"hand": int(p.get("hand", 1)),
		"traits": p.get("traits", []) + p.get("skills", []) + p.get("flaws", []),   # boss traits, learned techniques, weak spots
		"gear": Gear.resolve(p),
	}


## Two strongest and the weakest rating, for scouting reports.
static func strengths(p: Dictionary) -> Array:
	var idx := range(ATTRS.size())
	idx.sort_custom(func(x, y): return p.a[x] > p.a[y])
	return [[ATTRS[idx[0]][1], ATTRS[idx[1]][1]], ATTRS[idx[idx.size() - 1]][1]]


## A one-line scouting note on how to play against this player.
static func scout_note(p: Dictionary) -> String:
	var fh := attr(p, "fh")
	var bh := attr(p, "bh")
	var notes := []
	if bh + 6 <= fh:
		notes.append("反手偏弱，多压反手")
	elif fh + 6 <= bh:
		notes.append("正手偏弱，调动正手大角")
	if attr(p, "receive") <= 70:
		notes.append("接发球一般，发短下旋抢攻")
	if attr(p, "mental") <= 66:
		notes.append("关键分容易手紧")
	if attr(p, "stamina") <= 66:
		notes.append("体能差，拉长回合")
	if attr(p, "power") >= 86:
		notes.append("发力猛，别给他上手机会")
	if p.grip == "pen":
		notes.append("传统直拍反手推挡，打反手底线")
	if notes.is_empty():
		notes.append("没有明显短板，稳住相持")
	return "；".join(PackedStringArray(notes.slice(0, 2)))
