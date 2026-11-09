extends RefCounted
## Signature skills (特色技术): the bosses' traits made learnable. A player who
## meets a skill's rating requirements can pick it up in training (now and then
## on his own, much faster with dedicated skill training); a learned skill acts
## in matches exactly like the boss trait of the same id (see has_trait).

const Roster := preload("res://scripts/roster.gd")

const SKILLS := {
	"twist": {"cat": "tech", "name": "霸王拧", "desc": "台内短球到反手，直接反手拧拉上手", "req": {"bh": 80}, "grips": ["shake", "rpb"]},
	"early": {"cat": "tech", "name": "上升期快打", "desc": "站位近、借力快，打上升期不吃转", "req": {"foot": 78, "receive": 76}},
	"fighter": {"cat": "mind", "name": "逆境顽强", "desc": "落后或被逼到局点时更凶更稳", "req": {"mental": 80}},
	"clutch": {"cat": "mind", "name": "大心脏", "desc": "关键分越打越稳", "req": {"mental": 88, "iq": 80}},
	"third": {"cat": "tech", "name": "前三板", "desc": "多发短下旋，第三板抢攻", "req": {"serve": 82}},
	"adapt": {"cat": "mind", "name": "读比赛", "desc": "很快看出对手在哪丢分，一直打那里", "req": {"iq": 86}},
	"heavy": {"cat": "tech", "name": "重炮", "desc": "每一板都又转又沉", "req": {"power": 86, "spin": 84}},
	"grind": {"cat": "tech", "name": "相持型", "desc": "回合越长越强", "req": {"stamina": 84, "foot": 76}},
	"cloud": {"cat": "tech", "name": "云手", "desc": "退台正手大幅度拉冲，侧旋重、角度大", "req": {"fh": 87, "foot": 82}},
	"fh_heavy": {"cat": "tech", "name": "侧身抢攻", "desc": "多用正手，侧身覆盖反手位", "req": {"fh": 82}},
}


## Weak spots (短板), the other side of the coin: 技术 ones from a low rating,
## 心态 ones from the head. Each comes with a player whose `attr` is under `below`,
## and is grown out of once training lifts it to `fix` (慢热 has no rating
## behind it: some players just are). The match code reads them as traits.
const FLAWS := {
	"weak_bh": {"cat": "tech", "name": "反手薄弱", "desc": "反手出手质量差、失误多，对手会一直压他反手", "attr": "bh", "below": 72, "fix": 80},
	"poor_recv": {"cat": "tech", "name": "接发球差", "desc": "接发球读不准旋转，接发失误和回球冒高多", "attr": "receive", "below": 70, "fix": 78},
	"soft": {"cat": "tech", "name": "回球软", "desc": "挡和搓没有质量，球速慢、容易被抢攻", "attr": "power", "below": 68, "fix": 76},
	"choke": {"cat": "mind", "name": "怯场", "desc": "关键分手软，失误明显变多", "attr": "mental", "below": 70, "fix": 80},
	"hothead": {"cat": "mind", "name": "急躁", "desc": "落后时急于搏杀，失误变多", "attr": "iq", "below": 70, "fix": 78},
	"fragile": {"cat": "mind", "name": "玻璃心", "desc": "连丢几分后心态崩盘", "attr": "mental", "below": 66, "fix": 76},
	"slow_start": {"cat": "mind", "name": "慢热", "desc": "每局开头几分进入不了状态", "attr": "", "below": 0, "fix": 999},
}
const CAT_NAMES := {"tech": "技术", "mind": "心态"}


## The techniques a player has: the ones learned, plus a legend's own traits
## that are techniques (龙马's 大心脏 and so on). Anything else is ignored.
static func known(p: Dictionary) -> Array:
	var out := []
	for k in p.get("skills", []) + p.get("traits", []):
		if k is String and SKILLS.has(k) and not out.has(k):
			out.append(k)
	return out


static func names(p: Dictionary, cat := "") -> String:
	var ks := known(p).filter(func(k): return cat == "" or SKILLS[k].cat == cat)
	return "、".join(PackedStringArray(ks.map(func(k): return SKILLS[k].name))) if not ks.is_empty() else "无"


## His weak spots (of one kind, or all): ids, from the player's flaws and, for a
## legend, its traits.
static func flaws(p: Dictionary, cat := "") -> Array:
	var out := []
	for k in p.get("flaws", []) + p.get("traits", []):
		if k is String and FLAWS.has(k) and not out.has(k) and (cat == "" or FLAWS[k].cat == cat):
			out.append(k)
	return out


static func flaw_names(p: Dictionary, cat := "") -> String:
	var fs := flaws(p, cat)
	return "、".join(PackedStringArray(fs.map(func(k): return FLAWS[k].name))) if not fs.is_empty() else ""


## "技术 霸王拧、重炮 · 短板 反手薄弱" for one category.
static func line(p: Dictionary, cat: String) -> String:
	var fl := flaw_names(p, cat)
	return "%s %s%s" % [CAT_NAMES[cat], names(p, cat), ("   短板 " + fl) if fl != "" else ""]


## Weak spots a player starts with: those his low ratings point to (not all of
## them, and never more than two), now and then a slow starter.
static func seed_flaws(p: Dictionary) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = absi(hash(p.name + "flaws"))
	var out := []
	for k in FLAWS:
		var f: Dictionary = FLAWS[k]
		if f.attr == "":
			if r.randf() < 0.12:
				out.append(k)
		elif Roster.attr(p, f.attr) < f.below and r.randf() < 0.45:
			out.append(k)
	while out.size() > 2:
		out.remove_at(r.randi_range(0, out.size() - 1))
	return out


## Flaws grown out of: the rating behind it is up to `fix` now. Returns their names.
static func outgrow(p: Dictionary) -> Array:
	var gone := []
	for k in p.get("flaws", []).duplicate():
		var f: Dictionary = FLAWS.get(k, {})
		if not f.is_empty() and f.attr != "" and Roster.attr(p, f.attr) >= f.fix:
			p.flaws.erase(k)
			gone.append(f.name)
	return gone


static func grip_ok(p: Dictionary, k: String) -> bool:
	return not SKILLS[k].has("grips") or SKILLS[k].grips.has(p.grip)


static func meets(p: Dictionary, k: String) -> bool:
	if not grip_ok(p, k):
		return false
	for a in SKILLS[k].req:
		if Roster.attr(p, a) < SKILLS[k].req[a]:
			return false
	return true


## Skills he could still learn (right grip, not known yet).
static func learnable(p: Dictionary) -> Array:
	return SKILLS.keys().filter(func(k): return not known(p).has(k) and grip_ok(p, k))


## "正手 84/87 · 步法 80/82" for the requirements not met yet ("" when ready).
static func missing(p: Dictionary, k: String) -> String:
	var parts := []
	for a in SKILLS[k].req:
		var v: int = Roster.attr(p, a)
		if v < SKILLS[k].req[a]:
			parts.append("%s %d/%d" % [_attr_name(a), v, SKILLS[k].req[a]])
	return " · ".join(PackedStringArray(parts))


## The requirement furthest from being met, to train towards a skill.
static func gap_attr(p: Dictionary, k: String) -> String:
	var best := ""
	var gap := 0
	for a in SKILLS[k].req:
		var g: int = SKILLS[k].req[a] - Roster.attr(p, a)
		if g > gap:
			gap = g
			best = a
	return best


static func _attr_name(key: String) -> String:
	for a in Roster.ATTRS:
		if a[0] == key:
			return a[1]
	return key


## Skills a player already has when the world is made: some of those he
## qualifies for, chosen by a generator seeded with his name.
static func seed_skills(p: Dictionary) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = absi(hash(p.name + "skills"))
	var out := []
	for k in SKILLS:
		if meets(p, k) and r.randf() < 0.5:
			out.append(k)
	return out
