extends RefCounted
## Equipment (器材): a blade (底板) and a rubber on each side (胶皮). The blade
## sets the pace and the feel (control); a rubber sets pace, how much spin you
## can put on the ball, and how much the incoming spin throws your return off
## (`kick`). Short pips barely take spin either way; long pips hand the
## opponent's spin back reversed. Generic types, no brands.

const BLADES := {
	"wood5": {"name": "纯木五夹", "speed": 0.95, "ctrl": 1.10, "desc": "慢、手感好，弧线稳，适合练基本功和防守"},
	"wood7": {"name": "纯木七夹", "speed": 1.00, "ctrl": 1.04, "desc": "均衡，相持和发力都顺手"},
	"inner": {"name": "内置碳", "speed": 1.03, "ctrl": 1.00, "desc": "纯木手感加碳的底劲，弧圈型最常用"},
	"outer": {"name": "外置碳", "speed": 1.08, "ctrl": 0.93, "desc": "快、弹，近台快攻利器，控制更难"},
}
const BLADE_KEYS := ["wood5", "wood7", "inner", "outer"]
const RUBBERS := {
	"tacky": {"name": "粘性胶皮", "speed": 0.96, "spin": 1.12, "ctrl": 1.00, "kick": 1.00,
			"desc": "旋转强、球下沉，但要自己发力"},
	"tensor": {"name": "涩性内能", "speed": 1.07, "spin": 1.00, "ctrl": 0.97, "kick": 1.05,
			"desc": "弹、出球快，对来球的旋转更敏感"},
	"short": {"name": "生胶", "speed": 1.05, "spin": 0.65, "ctrl": 1.00, "kick": 0.60,
			"desc": "颗粒向外：平快，不太吃对方的转，自己也拉不出转"},
	"long": {"name": "长胶", "speed": 0.82, "spin": 0.15, "ctrl": 1.05, "kick": 0.30, "reverse": 0.7,
			"desc": "把对方的旋转反过来送回去：拉来的上旋回过去变下旋"},
}
const RUBBER_KEYS := ["tacky", "tensor", "short", "long"]
## What the club pays once to stock an item (万元); the basics are free.
const PRICE := {"wood5": 0.0, "wood7": 0.0, "inner": 20.0, "outer": 30.0, "tacky": 0.0, "tensor": 0.0, "short": 12.0, "long": 12.0}
## What suits each playing style.
const SUITS := {"loop": ["inner", "tacky", "tensor"], "fast": ["outer", "tensor", "short"], "all": ["wood7", "tacky", "long"]}


## A setup's numbers: speed, forehand and backhand spin, control, and how much
## the other side's spin bites (lower is better).
static func stats(g: Dictionary, grip: String) -> Dictionary:
	var bl: Dictionary = BLADES[g.blade]
	var fh: Dictionary = RUBBERS[g.fh]
	var bh: Dictionary = fh if grip == "pen" else RUBBERS[g.bh]
	return {"speed": bl.speed * (fh.speed + bh.speed) * 0.5, "spin_fh": fh.spin, "spin_bh": bh.spin,
			"ctrl": bl.ctrl * (fh.ctrl + bh.ctrl) * 0.5, "kick": (fh.kick + bh.kick) * 0.5}


## What a player uses when nobody has chosen: loopers inner carbon with a tacky
## forehand, fast attackers outer carbon and springy rubber.
static func default_ids(p: Dictionary) -> Dictionary:
	match p.get("style", "loop"):
		"fast":
			return {"blade": "outer", "fh": "tensor", "bh": "tensor"}
		"all":
			return {"blade": "wood7", "fh": "tacky", "bh": "tensor"}
	return {"blade": "inner", "fh": "tacky", "bh": "tensor"}


static func ids(p: Dictionary) -> Dictionary:
	return p.get("gear", default_ids(p))


## {"blade", "fh", "bh"} stat dictionaries. Traditional penholders play their
## backhand off the front rubber too.
static func resolve(p: Dictionary) -> Dictionary:
	var g := ids(p)
	var fh: Dictionary = RUBBERS[g.fh]
	return {"blade": BLADES[g.blade], "fh": fh, "bh": fh if p.get("grip", "shake") == "pen" else RUBBERS[g.bh]}


## One-line summary of a set-up for menus.
static func summary(p: Dictionary) -> String:
	var r := resolve(p)
	var bl: Dictionary = r.blade
	return "速度 ×%.2f  旋转 正%.2f 反%.2f  控制 ×%.2f" % [bl.speed * r.fh.speed, r.fh.spin, r.bh.spin, bl.ctrl * r.fh.ctrl]
