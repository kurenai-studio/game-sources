class_name UnitTypes
extends RefCounted
## Regiment types and their base stats. Pure data.

## New kinds go at the end: saved campaigns store kinds by number.
enum Kind { SWORDS, PIKES, ARCHERS, CAVALRY, CANNONS, GENERAL, MUSKETS, RIFLES, LINE }

## men: soldiers at full strength. hp: per soldier. atk: damage per second
## per fighting soldier. def: fraction of incoming damage ignored.
## speed: world units per second. cols: soldiers per rank. spacing: gap
## between soldiers. range/reload/shot: ranged units only. pierce: share
## of the target's armour a shot goes through. shock: morale a volley
## costs its target on top of the losses.
const STATS := {
	Kind.SWORDS: {
		"name": "Swords", "men": 48, "hp": 10.0, "atk": 1.0, "def": 0.30,
		"speed": 30.0, "morale": 70.0, "cols": 12, "spacing": 8.0,
	},
	Kind.PIKES: {
		"name": "Pikes", "men": 48, "hp": 10.0, "atk": 0.8, "def": 0.30,
		"speed": 27.0, "morale": 70.0, "cols": 12, "spacing": 8.0,
	},
	Kind.ARCHERS: {
		"name": "Archers", "men": 36, "hp": 7.0, "atk": 0.5, "def": 0.10,
		"speed": 31.0, "morale": 55.0, "cols": 12, "spacing": 8.5,
		"range": 230.0, "reload": 3.5, "shot": 3.4, "accuracy": 0.4,
		"shock": 1.5,
	},
	Kind.CAVALRY: {
		"name": "Cavalry", "men": 24, "hp": 16.0, "atk": 1.4, "def": 0.25,
		"speed": 68.0, "morale": 75.0, "cols": 8, "spacing": 10.5,
	},
	Kind.CANNONS: {
		"name": "Cannons", "men": 12, "hp": 8.0, "atk": 0.4, "def": 0.05,
		"speed": 16.0, "morale": 60.0, "cols": 6, "spacing": 9.0,
		"range": 430.0, "reload": 6.5, "shot": 11.0, "guns": 2,
	},
	Kind.GENERAL: {
		"name": "General", "men": 10, "hp": 24.0, "atk": 1.6, "def": 0.40,
		"speed": 64.0, "morale": 100.0, "cols": 5, "spacing": 10.5,
	},
	Kind.MUSKETS: {
		"name": "Muskets", "men": 40, "hp": 8.0, "atk": 0.55, "def": 0.10,
		"speed": 28.0, "morale": 60.0, "cols": 14, "spacing": 7.5,
		"range": 170.0, "reload": 7.5, "shot": 6.0, "accuracy": 0.3,
		"pierce": 0.7, "shock": 6.0,
	},
	## Rifled muskets, the 1860s: farther and truer than smoothbores, and a
	## brigade that can form and fire with the bayonet fixed.
	Kind.RIFLES: {
		"name": "Rifles", "men": 40, "hp": 8.0, "atk": 0.7, "def": 0.12,
		"speed": 28.0, "morale": 65.0, "cols": 14, "spacing": 7.5,
		"range": 230.0, "reload": 8.0, "shot": 6.0, "accuracy": 0.4,
		"pierce": 0.8, "shock": 5.0,
	},
	## Napoleonic line infantry: a smoothbore musket and the bayonet, and
	## drill enough to form square when horse comes (see Battle._squares).
	Kind.LINE: {
		"name": "Line", "men": 40, "hp": 8.0, "atk": 0.7, "def": 0.12,
		"speed": 28.0, "morale": 68.0, "cols": 14, "spacing": 7.5,
		"range": 170.0, "reload": 7.0, "shot": 6.0, "accuracy": 0.3,
		"pierce": 0.7, "shock": 6.0,
	},
}

const RECRUITABLE: Array[int] = [
	Kind.SWORDS, Kind.PIKES, Kind.ARCHERS, Kind.CAVALRY, Kind.CANNONS,
]


static func stat(kind: int, key: String) -> Variant:
	return STATS[kind][key]


static func label(kind: int) -> String:
	return STATS[kind]["name"]


static func is_ranged(kind: int) -> bool:
	return kind == Kind.ARCHERS or kind == Kind.CANNONS or is_shot(kind)


## Firearms carried by the men themselves: muskets and rifles fire a
## volley that lands at once.
static func is_shot(kind: int) -> bool:
	return kind == Kind.MUSKETS or kind == Kind.RIFLES or kind == Kind.LINE


static func is_mounted(kind: int) -> bool:
	return kind == Kind.CAVALRY or kind == Kind.GENERAL
