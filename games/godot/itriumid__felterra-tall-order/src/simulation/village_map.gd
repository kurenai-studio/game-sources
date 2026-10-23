class_name VillageMap
extends RefCounted
## The cats' village at the forest's edge, as a place to walk: a forest path coming in from the
## left, the village itself, and on its far side the path out to the clearing. Everything
## between runs happens here. The cats he's rescued live in it.
##
## When the story starts, the company's machines have already been through: every building is a
## ruin. Bringing them back, one by one, is how the village grows, and each opens what it holds.
## Runs headless at the arena's step, in meters and seconds.

## The whole of it, in meters: the forest path to the left of VILLAGE_FROM, the village to the
## right. The path runs along the middle, between PATH_TOP and PATH_BOTTOM.
const SIZE := Vector2(37.0, 9.0)
const VILLAGE_FROM := 12.0
const PATH_TOP := 3.6
const PATH_BOTTOM := 6.4
## Where he stands on the title, on the forest path, and where he walks in to, in the village.
const TITLE_SPOT := Vector2(5.0, 5.0)
const HOME_SPOT := Vector2(19.0, 5.2)
## Where the Elder meets him, the first time he walks in: just inside the village.
const MEETING_SPOT := Vector2(14.6, 5.0)
## The exit: walking out through the gate, on the path, starts a run: he's seen off, and walks on
## off the village's right edge, into the forest. Off the path, the edge is trees. Coming home
## from a run, he walks back in from there.
const EXIT_FROM := 35.6
const RETURN_SPOT := Vector2(33.5, 5.0)
## Where he walks on to as he's seen off, past the edge and out of sight; and where the villagers
## stand to see him off, either side of the path inside the gate.
const OFF_INTO_THE_FOREST := Vector2(38.6, 5.0)
const SEE_OFF_FROM := 30.6
## How close to the gate he is, along the path, when the villagers start over to see him off, and
## how fast they trot there.
const GATHER_FROM := 5.0
const TROT_SPEED := 1.8
## How close to a door he has to be to use it, past a share of the building's width.
const DOOR_REACH := 0.7
## How fast he walks in a cutscene with a story to tell over it, how fast with none (his own
## full pace: nothing to wait for), and how fast the villagers amble.
const STROLL_SPEED := 1.4
const WALK_IN_SPEED := Cat.SPEED
const AMBLE_SPEED := 0.7
## Where the Elder keeps, before the longhouse; where he stands to see him off, at the gate; and
## how far from him he stops when he walks out to meet him.
const ELDER_SPOT := Vector2(18.0, 3.3)
const ELDER_AT_THE_GATE := Vector2(34.6, 3.3)
const ELDER_MEETS := 1.0
## How far behind Tompel Jogiboy keeps, and how fast he trots to catch up.
const JOGI_HEEL := 0.9
const JOGI_SPEED := 3.0
## How far from his spot he lets Tompel get before setting off, and how close he comes to settle.
const JOGI_SET_OFF := 1.2
const JOGI_SETTLE := 0.25
## His play: what he can get up to, how long he stands before he's bored (from, to), how fast he
## plays, how wide and fast his zoomies go round Tompel, and how long a sniff and a dig take.
const JOGI_PLAYS: Array[String] = ["zoomies", "chase", "dig"]
const JOGI_BORED := Vector2(2.5, 6.0)
const JOGI_PLAY_SPEED := 4.5
const ZOOMIES_RADIUS := 1.4
const ZOOMIES_TURN := 3.2
const JOGI_SNIFF_TIME := 0.9
const JOGI_DIG_TIME := 1.8
## How far outside a wall something pushed out of it ends up, in meters.
const EDGE_GAP := 0.001
## The buildings, by name: his home, the Elder's longhouse, the smithy, the huts, and the
## watchtower, the market and the healer's hut. Each is a ruin until
## it's restored, and stays solid either way: a ruin is still in the way.
const LONGHOUSE := Rect2(15.5, 1.3, 5.0, 1.6)
const SMITHY := Rect2(22.5, 1.4, 3.2, 1.5)
## The map of the forest, carved on a board at the gate: where the next run goes. It was never a
## ruin.
const BOARD := Rect2(34.3, 6.7, 1.2, 0.45)
## What the cats freed in the story bring back, by the gate: Jingga's watchtower, Kopi and Susu's
## market stall, and Bu Jamu's healer's hut.
const WATCHTOWER := Rect2(30.0, 1.5, 1.4, 1.2)
const MARKET := Rect2(28.4, 7.1, 2.4, 1.2)
const HEALER := Rect2(32.0, 1.6, 2.0, 1.3)
## His own home: the first house in from the forest.
const HOME := Rect2(12.6, 1.6, 2.0, 1.3)
const HUTS: Array[Rect2] = [
	Rect2(14.0, 7.0, 2.0, 1.4), Rect2(17.5, 7.2, 2.0, 1.4), Rect2(21.0, 7.0, 2.0, 1.4),
	Rect2(24.5, 7.2, 2.0, 1.4), Rect2(26.8, 1.6, 2.0, 1.3),
]

var cat := Cat.new()
## The Elder, who has always been here, ruin or no ruin: gray, in his batik headcloth. He keeps by
## the longhouse, walks out to meet him when there's something to say, and comes to the gate to see
## him off. Where he's walking to, or nowhere (INF).
var elder := Cat.new()
var elder_to := Vector2.INF
## Jogiboy, who lives next door to the Elder and has decided Tompel is his friend: in Felterra
## everyone is equal, a dog as much as anyone. He goes everywhere Tompel goes in the village,
## trotting after him, and stands by him when he stops.
var jogi := Cat.new()
var _jogi_trotting := false
## What Jogiboy's playing at ("" for nothing: following Tompel), and whether he's digging now; how
## long he's stood, and how long before he's bored of it; and where his play has got to.
var jogi_playing := ""
var jogi_digging := false
var _jogi_idle := 0.0
var _jogi_bored_after := 3.0
var _jogi_play_for := 0.0
var _jogi_dug_for := 0.0
var _jogi_lap := 0.0
var _jogi_spot := Vector2.ZERO
## The cats he's rescued, ambling about: each a Cat in its own coat, with where it's going.
var villagers: Array[Cat] = []
var names: Array[String] = []
var buildings: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var time := 0.0
## Where he's being walked to in a cutscene, or nowhere (INF): while he is, steering is ignored.
## And how fast: slower while a story is told over the walk.
var walking_to := Vector2.INF
var stroll_speed := STROLL_SPEED
## Whether the villagers have come to the gate to see him off: they stay there, watching him go.
var seeing_off := false
## Whether they're on their way to the gate, because he's heading out.
var gathering := false
var _amble_to: Array[Vector2] = []
## The villagers called over to say something, by index: they stay put until let go.
var _staying := {}


## Every building's name, in the order they stand.
static func building_names() -> Array[String]:
	var names_in_order: Array[String] = ["home", "longhouse", "smithy"]
	for index in HUTS.size():
		names_in_order.append("hut_%d" % index)
	names_in_order.append_array(["watchtower", "market", "healer"])
	return names_in_order


func _init(rescued: Array = [], restored: Array = [], seed_value := 39) -> void:
	random.seed = seed_value
	cat.weapons.clear()
	cat.body.position = TITLE_SPOT
	elder.weapons.clear()
	elder.coat = "gray"
	elder.gear = {"head": "batik_headcloth"}
	elder.body.position = ELDER_SPOT
	elder.facing = Vector2.DOWN
	jogi.weapons.clear()
	jogi.body.position = ELDER_SPOT + Vector2(1.2, 0.5)
	buildings.append({"name": "home", "kind": "home", "footprint": HOME, "paint": 5})
	buildings.append({"name": "longhouse", "kind": "longhouse", "footprint": LONGHOUSE})
	buildings.append({"name": "smithy", "kind": "smithy", "footprint": SMITHY})
	for index in HUTS.size():
		buildings.append({"name": "hut_%d" % index, "kind": "hut", "footprint": HUTS[index], "paint": index})
	buildings.append({"name": "watchtower", "kind": "watchtower", "footprint": WATCHTOWER})
	buildings.append({"name": "market", "kind": "market", "footprint": MARKET})
	buildings.append({"name": "healer", "kind": "healer", "footprint": HEALER, "paint": 5})
	for building in buildings:
		building.restored = building.name in restored
	buildings.append({"name": "board", "kind": "board", "footprint": BOARD, "restored": true})
	for each: Dictionary in rescued:
		var villager := Cat.new()
		villager.weapons.clear()
		villager.coat = each.get("coat", "orange")
		villager.body.position = _somewhere_in_the_village()
		villagers.append(villager)
		names.append(each.get("name", ""))
		_amble_to.append(_somewhere_in_the_village())


## The building he's at the door of, by name, or "" if he isn't at one: close to the middle of
## its front, where its door is.
func at_door() -> String:
	for building in buildings:
		var footprint: Rect2 = building.footprint
		var door := Vector2(footprint.get_center().x, footprint.end.y)
		if cat.body.position.distance_to(door) <= DOOR_REACH + footprint.size.x * 0.25:
			return building.name
	return ""


## Marks a building restored, as he sees it: the village keeps the record.
func show_restored(building_name: String) -> void:
	for building in buildings:
		if building.name == building_name:
			building.restored = true


## Walks him to a spot on his own, for a cutscene.
func walk_to(spot: Vector2) -> void:
	walking_to = spot


func walking() -> bool:
	return walking_to.is_finite()


## Everyone comes to the gate to see him off: the villagers line the path either side, and stay
## there, and he walks on out of the village.
func see_off() -> void:
	seeing_off = true
	_gather()
	walk_to(OFF_INTO_THE_FOREST)


## The Elder walks out to meet him where he's going, stopping a step short of it and facing him.
func elder_meets(spot: Vector2) -> void:
	elder_to = spot + (ELDER_SPOT - spot).normalized() * ELDER_MEETS


## A villager with something to say comes over to where he'll be, and stays there until let go.
func call_over(who: String, spot: Vector2) -> void:
	var index := names.find(who)
	if index < 0:
		return
	_amble_to[index] = spot + Vector2(1.0, -0.6)
	_staying[index] = true


## Everyone who was called over goes about their day again.
func let_go() -> void:
	for index in _staying:
		_amble_to[index] = _somewhere_in_the_village()
	_staying.clear()


## The Elder goes back to his place by the longhouse.
func elder_home() -> void:
	elder_to = ELDER_SPOT


## Who's speaking a line, by who they are: "elder", "tompel", "jogiboy", or a villager's name. Nobody, if
## they aren't in the village.
func speaker_named(who: String) -> Cat:
	match who:
		"elder": return elder
		"tompel": return cat
		"jogiboy": return jogi
	var index := names.find(who)
	return villagers[index] if index >= 0 else null


## Whether he's heading out: on the path, close to the gate. The villagers come over.
func heading_out() -> bool:
	var at := cat.body.position
	return at.x >= EXIT_FROM - GATHER_FROM and at.y > PATH_TOP - 1.0 and at.y < PATH_BOTTOM + 1.0


## The villagers make for the gate, a place each along the path, and the Elder to the front.
func _gather() -> void:
	gathering = true
	elder_to = ELDER_AT_THE_GATE
	for index in villagers.size():
		# Two to a stretch of the path, one either side; a big village stands a row further back.
		var along := SEE_OFF_FROM + (index / 2) % 6 * 0.75
		var back := 0.45 + index / 12 * 0.6
		_amble_to[index] = Vector2(along, PATH_TOP - back if index % 2 == 0 else PATH_BOTTOM + back)


## Whether he's out of sight past the village's edge, seen off.
func gone() -> bool:
	return cat.body.position.x >= SIZE.x + 1.0


## Whether he's walked out through the gate onto the path to the forest: he's seen off.
func leaving() -> bool:
	var at := cat.body.position
	return at.x >= EXIT_FROM and at.y > PATH_TOP and at.y < PATH_BOTTOM


func step(delta: float) -> void:
	time += delta
	# Heading out, the villagers come over to the gate; turning back, they go about their day.
	if not seeing_off and heading_out() != gathering:
		if heading_out():
			_gather()
		else:
			gathering = false
			elder_home()
			for index in villagers.size():
				_amble_to[index] = _somewhere_in_the_village()
	_step_elder(delta)
	_step_jogi(delta)
	if walking():
		var toward := walking_to - cat.body.position
		if toward.length() < 0.05:
			walking_to = Vector2.INF
			cat.steering = Vector2.ZERO
		else:
			cat.steering = toward.normalized() * minf(stroll_speed / Cat.SPEED, 1.0)
	_move(cat, cat.steering * Cat.SPEED, delta)
	for index in villagers.size():
		var villager := villagers[index]
		var toward := _amble_to[index] - villager.body.position
		if toward.length() < 0.2:
			# A moment's pause, then somewhere else.
			if gathering or _staying.has(index):
				# At the gate watching him go, or by him, talking.
				villager.facing = (cat.body.position - villager.body.position).normalized()
			elif random.randf() < delta * 0.5:
				_amble_to[index] = _somewhere_in_the_village()
			_move(villager, Vector2.ZERO, delta)
		else:
			villager.steering = toward.normalized()
			_move(villager, toward.normalized() * (TROT_SPEED if gathering else AMBLE_SPEED), delta)


## The Elder walks where he's going, at a trot to the gate and an old cat's pace otherwise; there,
## he turns to him.
func _step_elder(delta: float) -> void:
	var toward := (elder_to - elder.body.position) if elder_to.is_finite() else Vector2.ZERO
	if toward.length() < 0.05:
		elder_to = Vector2.INF
		_move(elder, Vector2.ZERO, delta)
		if elder.body.position.distance_to(cat.body.position) < 4.0:
			elder.facing = (cat.body.position - elder.body.position).normalized()
		return
	_move(elder, toward.normalized() * (TROT_SPEED if gathering else AMBLE_SPEED * 1.6), delta)


## Jogiboy follows Tompel at his heels, a step behind and to the side. While Tompel walks, he keeps
## pace with him, smoothly, catching up a little faster when he's fallen behind; when Tompel stops,
## he comes up and stands by him, and only sets off again once Tompel has got well ahead. Not
## fussing at every step keeps him from stopping and starting. Seeing him off, he waits at the gate.
func _step_jogi(delta: float) -> void:
	var goal := cat.body.position - cat.facing * JOGI_HEEL + cat.facing.orthogonal() * 0.35
	if gathering:
		goal = ELDER_AT_THE_GATE + Vector2(0.8, 0.5)
	var toward := goal - jogi.body.position
	var walking := cat.body.velocity.length() > 0.2 and not gathering
	if walking or gathering:
		jogi_playing = ""
		jogi_digging = false
		_jogi_idle = 0.0
	if walking:
		# Keeping pace: going the way Tompel goes, as fast, and closing on his spot a little more
		# for every step behind, never past a trot.
		_jogi_trotting = true
		_move(jogi, (cat.body.velocity + toward * 2.0).limit_length(JOGI_SPEED), delta)
		return
	if not jogi_playing.is_empty():
		_jogi_play(delta)
		return
	if _jogi_trotting and toward.length() < JOGI_SETTLE:
		_jogi_trotting = false
	elif not _jogi_trotting and toward.length() > JOGI_SET_OFF:
		_jogi_trotting = true
	if not _jogi_trotting:
		_move(jogi, Vector2.ZERO, delta)
		# Standing, he turns to Tompel, once he's clearly to one side.
		var to_him := cat.body.position - jogi.body.position
		if absf(to_him.x) > 0.4:
			jogi.facing = Vector2(signf(to_him.x), 0.0)
		# Left standing a while, he finds something to play at.
		_jogi_idle += delta
		if _jogi_idle >= _jogi_bored_after and not gathering:
			_start_playing()
		return
	# Coming up to him: slowing as he arrives, not stopping dead.
	_move(jogi, toward.normalized() * minf(JOGI_SPEED, maxf(toward.length() * 3.0, 0.8)), delta)


## Bored of standing, Jogiboy plays: zoomies round Tompel, a dash after something only he can see
## and a sniff at it, or a dig a little way off.
func _start_playing() -> void:
	jogi_playing = JOGI_PLAYS[random.randi_range(0, JOGI_PLAYS.size() - 1)]
	_jogi_idle = 0.0
	_jogi_bored_after = random.randf_range(JOGI_BORED.x, JOGI_BORED.y)
	_jogi_play_for = 0.0
	_jogi_lap = (jogi.body.position - cat.body.position).angle()
	var away := Vector2.from_angle(random.randf() * TAU) * random.randf_range(1.2, 2.6)
	_jogi_spot = (cat.body.position + away).clamp(Vector2(VILLAGE_FROM + 0.6, 0.8), SIZE - Vector2(0.8, 0.8))


func _jogi_play(delta: float) -> void:
	_jogi_play_for += delta
	match jogi_playing:
		"zoomies":
			# Round and round him, flat out, twice.
			_jogi_lap += ZOOMIES_TURN * delta
			var round_him := cat.body.position + Vector2.from_angle(_jogi_lap) * ZOOMIES_RADIUS
			_move(jogi, (round_him - jogi.body.position).limit_length(1.0) * JOGI_PLAY_SPEED, delta)
			if _jogi_play_for >= TAU * 2.0 / ZOOMIES_TURN:
				jogi_playing = ""
		"chase", "dig":
			var toward := _jogi_spot - jogi.body.position
			if toward.length() > 0.2 and _jogi_play_for < 3.0:
				_move(jogi, toward.normalized() * JOGI_PLAY_SPEED, delta)
				_jogi_dug_for = 0.0
				return
			# There: a sniff, or a dig, then back to Tompel.
			_move(jogi, Vector2.ZERO, delta)
			_jogi_dug_for += delta
			jogi_digging = jogi_playing == "dig"
			if _jogi_dug_for >= (JOGI_DIG_TIME if jogi_playing == "dig" else JOGI_SNIFF_TIME):
				jogi_playing = ""
				jogi_digging = false


## Moves a cat at a pace, facing the way it goes, kept out of the buildings and on the ground
## there is: the path, in the forest, and the whole village beyond it.
func _move(walker: Cat, velocity: Vector2, delta: float) -> void:
	walker.body.velocity = velocity
	if velocity.length_squared() > 0.0001:
		walker.facing = velocity.normalized()
	var next := walker.body.position + velocity * delta
	for building in buildings:
		var footprint: Rect2 = (building.footprint as Rect2).grow(walker.body.radius)
		if footprint.has_point(next):
			# Against a wall, he slides along it, the way that's still open; failing that, out. A
			# villager, going somewhere on its own, slides at its full pace, or it would creep.
			var pace := velocity.length() if walker != cat else 0.0
			var across := walker.body.position + Vector2(signf(velocity.x) * maxf(absf(velocity.x), pace), 0.0) * delta
			var along := walker.body.position + Vector2(0.0, signf(velocity.y) * maxf(absf(velocity.y), pace)) * delta
			if not footprint.has_point(along) and absf(velocity.y) > 0.0001:
				next = along
			elif not footprint.has_point(across) and absf(velocity.x) > 0.0001:
				next = across
			else:
				next = _push_out(next, footprint)
	var top := PATH_TOP if next.x < VILLAGE_FROM else 0.4
	var bottom := PATH_BOTTOM if next.x < VILLAGE_FROM else SIZE.y - 0.4
	# Off the right edge only along the path: that's the way out. Seen off, he walks on out of
	# sight.
	var right := SIZE.x if next.y > PATH_TOP and next.y < PATH_BOTTOM else SIZE.x - 0.4
	if walker == cat and seeing_off:
		right = OFF_INTO_THE_FOREST.x
	walker.body.position = Vector2(clampf(next.x, 0.4, right), clampf(next.y, top, bottom))


func _push_out(point: Vector2, box: Rect2) -> Vector2:
	var distances := [point.x - box.position.x, box.end.x - point.x, point.y - box.position.y, box.end.y - point.y]
	var nearest: int = distances.find(distances.min())
	# Just past the edge, not on it: on it still counts as inside, and nothing could slide.
	match nearest:
		0: return Vector2(box.position.x - EDGE_GAP, point.y)
		1: return Vector2(box.end.x + EDGE_GAP, point.y)
		2: return Vector2(point.x, box.position.y - EDGE_GAP)
	return Vector2(point.x, box.end.y + EDGE_GAP)


func _somewhere_in_the_village() -> Vector2:
	for attempt in 20:
		var spot := Vector2(random.randf_range(VILLAGE_FROM + 1.0, SIZE.x - 2.0), random.randf_range(1.0, SIZE.y - 1.0))
		if not buildings.any(func(building: Dictionary) -> bool: return (building.footprint as Rect2).grow(0.3).has_point(spot)):
			return spot
	return HOME_SPOT
