extends RefCounted
## Simple auto-player used for balance simulation and screenshots. Not used in normal play.

const Defs = preload("res://scripts/data/defs.gd")

var battle: Node2D
var allowed: Array = []
var samples: Array = []   # path sample points
var skill := 1.0          # 1.0 = decent player; lower = wastes money
var _n := 0


func _init(b: Node2D, towers_allowed: Array) -> void:
	battle = b
	allowed = towers_allowed
	for p in battle.paths:
		var d := 0.0
		while d < p["len"]:
			var pt: Vector2 = battle.path_point(battle.paths.find(p), d)[0]
			if pt.x >= 0 and pt.x < 512 and pt.y >= 0 and pt.y < 352:
				samples.append([pt, 0.8 + 0.4 * d / p["len"]])
			d += 8.0


func coverage(tile: Vector2i, r: float) -> float:
	var c: Vector2 = battle.tile_center(tile)
	var n := 0.0
	for s in samples:
		if c.distance_to(s[0]) <= r:
			n += s[1]
	return n


func best_tile(r: float, type := "") -> Vector2i:
	var best := Vector2i(-1, -1)
	var bs := 0.0
	for y in battle.ROWS:
		for x in battle.COLS:
			var t := Vector2i(x, y)
			if not battle.can_place(t, type):
				continue
			var s := 0.0
			if type == "garage":
				# cars should enter late on the road so they drive through everything
				var rd: Array = battle.nearest_road(battle.tile_center(t))
				s = 1.0 + rd[1] / battle.paths[rd[0]]["len"]
			else:
				s = coverage(t, r)
			if s > bs:
				bs = s
				best = t
	return best


func step() -> void:
	# buy / upgrade as long as it makes sense
	for guard in 6:
		if not _act():
			break
	if battle.can_start_wave() and not battle.has_hostiles():
		battle.start_wave()


## Like a player who notices ghosts: once invisible enemies can show up, make sure some tower spots them.
func _camo_upgrade() -> int:
	if battle.wave < 9:
		return 0
	var cand: Node2D = null
	for tw in battle.towers.values():
		if tw.stats.get("camo", false) and tw.type != "garage":
			return 0
		if tw.type in ["gunner", "soldier"] and (cand == null or tw.damage_dealt > cand.damage_dealt):
			cand = tw
	if cand == null:
		return 0
	var c: int = battle.upgrade_cost(cand)
	if battle.cash < c:
		return -1   # save up for it
	battle.upgrade_tower(cand)
	return 1


func _act() -> bool:
	var cu := _camo_upgrade()
	if cu != 0:
		return cu > 0
	var count: int = battle.towers.size()
	var want_towers: int = 3 + battle.wave / 2
	var cheapest_up: Node2D = null
	var cheapest_cost := 1 << 30
	for tw in battle.towers.values():
		var c: int = battle.upgrade_cost(tw)
		if c > 0 and c < cheapest_cost:
			cheapest_cost = c
			cheapest_up = tw
	if count < want_towers or cheapest_up == null:
		var t: String = allowed[_n % allowed.size()]
		if battle.cash < battle.tower_cost(t):
			return false
		var tile := best_tile(float(Defs.TOWERS[t]["base"]["range"]), t)
		if tile.x < 0:
			return false
		battle.place_tower(t, tile)
		_n += 1
		return true
	if battle.cash >= cheapest_cost:
		battle.upgrade_tower(cheapest_up)
		return true
	return false
