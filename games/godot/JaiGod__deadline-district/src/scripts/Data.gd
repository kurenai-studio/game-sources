extends Node
## Static game data (weapons, zombies, perks, maps) and the save file.

const SAVE_PATH := "user://deadline_district.json"
const WIN_WAVE := 15

# kind: bullet / flame / bolt / rocket / tesla / melee
const WEAPONS := [
	{"id": "pistol", "name": "Pistol", "cost": 0, "dmg": 20.0, "rate": 4.0, "mag": 12, "res": -1, "reload": 1.0, "spread": 0.04, "pellets": 1, "speed": 950.0, "range": 620.0, "kind": "bullet", "pierce": 0, "auto": false, "col": Color(1.0, 0.9, 0.55), "shake": 1.5, "desc": "Trusty sidearm. Infinite reserve."},
	{"id": "smg", "name": "SMG", "cost": 650, "dmg": 13.0, "rate": 12.0, "mag": 32, "res": 192, "reload": 1.5, "spread": 0.11, "pellets": 1, "speed": 980.0, "range": 560.0, "kind": "bullet", "pierce": 0, "auto": true, "col": Color(1.0, 0.85, 0.45), "shake": 1.2, "desc": "Hose the hallway."},
	{"id": "shotgun", "name": "Shotgun", "cost": 900, "dmg": 15.0, "rate": 1.4, "mag": 6, "res": 36, "reload": 2.0, "spread": 0.30, "pellets": 7, "speed": 820.0, "range": 380.0, "kind": "bullet", "pierce": 0, "auto": false, "col": Color(1.0, 0.75, 0.4), "shake": 6.0, "desc": "Seven pellets of close-range regret."},
	{"id": "rifle", "name": "Rifle", "cost": 1400, "dmg": 75.0, "rate": 1.7, "mag": 5, "res": 40, "reload": 1.9, "spread": 0.01, "pellets": 1, "speed": 1700.0, "range": 1100.0, "kind": "bullet", "pierce": 3, "auto": false, "col": Color(0.7, 0.95, 1.0), "shake": 4.0, "desc": "Punches through 3 zombies."},
	{"id": "minigun", "name": "Minigun", "cost": 3200, "dmg": 11.0, "rate": 22.0, "mag": 150, "res": 450, "reload": 3.4, "spread": 0.16, "pellets": 1, "speed": 1000.0, "range": 600.0, "kind": "bullet", "pierce": 0, "auto": true, "col": Color(1.0, 0.8, 0.3), "shake": 1.6, "desc": "Spins up, then shreds."},
	{"id": "flamer", "name": "Flamethrower", "cost": 2200, "dmg": 7.0, "rate": 28.0, "mag": 120, "res": 360, "reload": 2.4, "spread": 0.22, "pellets": 1, "speed": 430.0, "range": 230.0, "kind": "flame", "pierce": 99, "auto": true, "col": Color(1.0, 0.55, 0.15), "shake": 0.6, "desc": "Sets crowds on fire. Burns ignore shields."},
	{"id": "crossbow", "name": "Crossbow", "cost": 1200, "dmg": 120.0, "rate": 1.2, "mag": 1, "res": 30, "reload": 0.75, "spread": 0.0, "pellets": 1, "speed": 1300.0, "range": 1000.0, "kind": "bolt", "pierce": 6, "auto": false, "col": Color(0.6, 1.0, 0.7), "shake": 2.5, "desc": "Silent bolts that skewer a whole line."},
	{"id": "rocket", "name": "Rocket Launcher", "cost": 3800, "dmg": 170.0, "rate": 0.8, "mag": 1, "res": 12, "reload": 1.7, "spread": 0.0, "pellets": 1, "speed": 620.0, "range": 900.0, "kind": "rocket", "pierce": 0, "auto": false, "col": Color(1.0, 0.6, 0.3), "shake": 3.0, "desc": "Big boom, big splash. Mind your feet."},
	{"id": "tesla", "name": "Tesla Gun", "cost": 2800, "dmg": 36.0, "rate": 4.0, "mag": 20, "res": 100, "reload": 2.1, "spread": 0.0, "pellets": 1, "speed": 0.0, "range": 360.0, "kind": "tesla", "pierce": 0, "auto": true, "col": Color(0.55, 0.8, 1.0), "shake": 2.0, "desc": "Lightning that chains to 4 more targets."},
	{"id": "katana", "name": "Katana", "cost": 800, "dmg": 70.0, "rate": 2.6, "mag": 0, "res": 0, "reload": 0.0, "spread": 0.0, "pellets": 1, "speed": 0.0, "range": 95.0, "kind": "melee", "pierce": 99, "auto": true, "col": Color(0.9, 0.95, 1.0), "shake": 2.0, "desc": "No ammo. Wide slash that also cuts spit out of the air."},
]

const ZOMBIES := {
	"shambler": {"name": "Shambler", "hp": 60.0, "spd": 62.0, "dmg": 10.0, "r": 13.0, "cash": 10, "from": 1, "w": 10.0, "col": Color(0.48, 0.74, 0.42), "info": "Slow office drone. Comes in crowds."},
	"runner": {"name": "Runner", "hp": 40.0, "spd": 150.0, "dmg": 7.0, "r": 11.0, "cash": 15, "from": 2, "w": 6.0, "col": Color(0.85, 0.78, 0.35), "info": "Sprints straight at you."},
	"crawler": {"name": "Crawler", "hp": 26.0, "spd": 115.0, "dmg": 5.0, "r": 8.0, "cash": 6, "from": 3, "w": 6.0, "col": Color(0.55, 0.62, 0.5), "info": "Tiny, low and arrives in packs."},
	"spitter": {"name": "Spitter", "hp": 70.0, "spd": 72.0, "dmg": 12.0, "r": 12.0, "cash": 25, "from": 3, "w": 3.0, "col": Color(0.62, 0.86, 0.25), "info": "Keeps its distance and lobs acid."},
	"brute": {"name": "Brute", "hp": 380.0, "spd": 46.0, "dmg": 26.0, "r": 22.0, "cash": 60, "from": 4, "w": 2.0, "col": Color(0.55, 0.45, 0.62), "info": "Huge, tanky, ignores knockback."},
	"exploder": {"name": "Exploder", "hp": 90.0, "spd": 78.0, "dmg": 40.0, "r": 16.0, "cash": 30, "from": 5, "w": 2.5, "col": Color(0.95, 0.55, 0.3), "info": "Bursts when close or killed. Hurts other zombies too."},
	"screamer": {"name": "Screamer", "hp": 110.0, "spd": 82.0, "dmg": 8.0, "r": 13.0, "cash": 45, "from": 6, "w": 1.5, "col": Color(0.86, 0.45, 0.8), "info": "Its shriek makes nearby zombies faster and stronger."},
	"riot": {"name": "Riot Guard", "hp": 200.0, "spd": 56.0, "dmg": 16.0, "r": 16.0, "cash": 50, "from": 7, "w": 2.0, "col": Color(0.42, 0.55, 0.78), "info": "Front shield blocks 70% of bullet damage. Flank it!"},
}

const BOSSES := [
	{"name": "THE MIDDLE MANAGER", "hp": 2600.0, "spd": 70.0, "r": 38.0, "col": Color(0.4, 0.7, 0.45), "moves": ["charge", "summon"]},
	{"name": "THE AUDITOR", "hp": 3800.0, "spd": 64.0, "r": 40.0, "col": Color(0.6, 0.5, 0.85), "moves": ["volley", "charge", "volley"]},
	{"name": "CRUNCH TITAN", "hp": 5600.0, "spd": 60.0, "r": 46.0, "col": Color(0.85, 0.4, 0.35), "moves": ["slam", "summon", "volley", "charge"]},
]

const PERKS := [
	{"id": "tough", "name": "Thick Skin", "cost": 500, "desc": "+40 max health."},
	{"id": "hands", "name": "Quick Hands", "cost": 700, "desc": "Reload 35% faster."},
	{"id": "feet", "name": "Fleet Feet", "cost": 500, "desc": "Move 15% faster."},
	{"id": "pockets", "name": "Deep Pockets", "cost": 600, "desc": "+60% reserve ammo."},
	{"id": "bounty", "name": "Bounty Hunter", "cost": 800, "desc": "+30% cash from kills."},
	{"id": "aim", "name": "Steady Aim", "cost": 600, "desc": "40% less spread."},
	{"id": "overclock", "name": "Overclock", "cost": 900, "desc": "Turrets fire 50% faster and harder."},
	{"id": "battery", "name": "Big Battery", "cost": 400, "desc": "Flashlight reaches 35% further and wider."},
	{"id": "second", "name": "Second Wind", "cost": 1200, "desc": "Once per run, get back up at 50% health."},
]

const BARRICADE_COST := 60
const TURRET_COST := 300
const MEDKIT_COST := 150

var save := {"best": [0, 0, 0], "kills": 0, "wins": 0, "sound": true, "music": true, "runs": 0}

func _ready() -> void:
	load_save()

func weapon(id: String) -> Dictionary:
	for w in WEAPONS:
		if w.id == id:
			return w
	return WEAPONS[0]

func upgrade_cost(w: Dictionary, tier: int) -> int:
	var base = maxi(int(w.cost), 300)
	return int(base * 0.55 * (tier + 1) / 10.0) * 10

func ammo_cost(w: Dictionary) -> int:
	return 40 + int(maxi(int(w.cost), 300) * 0.12 / 10.0) * 10

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		for k in d:
			save[k] = d[k]
	if typeof(save.best) != TYPE_ARRAY or save.best.size() < 3:
		save.best = [0, 0, 0]

func write_save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))

func record_run(map_i: int, wave: int, kills: int, won: bool) -> bool:
	var best = save.best
	var record = wave > int(best[map_i])
	if record:
		best[map_i] = wave
	save.kills = int(save.kills) + kills
	save.runs = int(save.runs) + 1
	if won:
		save.wins = int(save.wins) + 1
	write_save()
	return record

# ------------------------------------------------------------------ maps
const MAP_INFO := [
	{"name": "Cubicle Plaza", "diff": "Normal", "hp": 1.0, "desc": "A dark open-plan office. Partitions make great chokepoints."},
	{"name": "Rush Hour Overpass", "diff": "Hard", "hp": 1.2, "desc": "A jammed highway at midnight. Wide lanes, nowhere to hide."},
	{"name": "Midnight Mall", "diff": "Nightmare", "hp": 1.45, "desc": "Six storefronts spill zombies into the food court."},
]

func build_map(i: int) -> Dictionary:
	var m := {"walls": [], "spawns": [], "decor": []}
	match i:
		0:
			m.size = Vector2(1600, 1200)
			m.floor = [Color(0.16, 0.17, 0.2), Color(0.18, 0.19, 0.22)]
			m.tile = 80.0
			m.wallc = Color(0.36, 0.38, 0.46)
			for y in [200, 420, 760, 980]:
				for x in [180, 450, 990, 1260]:
					m.walls.append([Rect2(x, y, 170, 18), "part"])
					m.walls.append([Rect2(x, y, 18, 100), "part"])
					m.walls.append([Rect2(x + 40, y + 34, 70, 36), "desk"])
			m.walls.append([Rect2(660, 150, 280, 20), "glass"])
			m.walls.append([Rect2(660, 1030, 280, 20), "glass"])
			for p in [Vector2(640, 520), Vector2(960, 520), Vector2(640, 700), Vector2(960, 700)]:
				m.decor.append(["plant", p])
			m.spawns = [Vector2(800, 30), Vector2(30, 600), Vector2(1570, 600), Vector2(800, 1170), Vector2(30, 30), Vector2(1570, 1170)]
			m.bench = Vector2(800, 560)
			m.start = Vector2(800, 650)
		1:
			m.size = Vector2(2000, 1200)
			m.floor = [Color(0.13, 0.135, 0.15), Color(0.14, 0.145, 0.16)]
			m.tile = 100.0
			m.wallc = Color(0.5, 0.52, 0.58)
			var cars = [[300, 300, 0], [520, 820, 1], [760, 400, 0], [1180, 760, 0], [1420, 330, 0], [1650, 860, 1], [990, 170, 0], [860, 960, 0], [300, 960, 0], [1700, 520, 1], [1250, 1000, 0], [560, 160, 1]]
			for c in cars:
				var r = Rect2(c[0], c[1], 112, 54) if c[2] == 0 else Rect2(c[0], c[1], 54, 112)
				m.walls.append([r, "car"])
			m.walls.append([Rect2(1300, 520, 260, 70), "bus"])
			for x in [140, 1760]:
				m.walls.append([Rect2(x, 560, 140, 22), "jersey"])
			m.walls.append([Rect2(620, 610, 22, 140), "jersey"])
			for x in range(0, 2000, 160):
				m.decor.append(["lane", Vector2(x + 40, 600)])
			m.spawns = [Vector2(30, 300), Vector2(30, 900), Vector2(1970, 300), Vector2(1970, 900), Vector2(1000, 30), Vector2(1000, 1170)]
			m.bench = Vector2(1000, 560)
			m.start = Vector2(1000, 660)
		_:
			m.size = Vector2(1800, 1400)
			m.floor = [Color(0.19, 0.16, 0.18), Color(0.21, 0.18, 0.2)]
			m.tile = 70.0
			m.wallc = Color(0.5, 0.38, 0.5)
			for k in 5:
				m.walls.append([Rect2(100 + k * 330, 40, 230, 170), "store"])
				m.walls.append([Rect2(100 + k * 330, 1190, 230, 170), "store"])
			for p in [Vector2(420, 520), Vector2(1290, 520), Vector2(420, 830), Vector2(1290, 830)]:
				m.walls.append([Rect2(p.x, p.y, 90, 56), "kiosk"])
			m.walls.append([Rect2(840, 600, 120, 120), "fountain"])
			m.walls.append([Rect2(170, 600, 56, 200), "escal"])
			m.walls.append([Rect2(1574, 600, 56, 200), "escal"])
			m.spawns = [Vector2(215, 240), Vector2(875, 240), Vector2(1535, 240), Vector2(215, 1160), Vector2(1535, 1160), Vector2(30, 700), Vector2(1770, 700)]
			m.bench = Vector2(700, 760)
			m.start = Vector2(900, 830)
	return m
