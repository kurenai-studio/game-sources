class_name LaneSpaces
extends RefCounted
## The reserved spaces on each lane (issue #50): the ground the view may put a building or a prop
## on, cut into equal-width spaces, so the number of spaces is the limit on what the view shows.
## Pure geometry and no nodes; `LanePlacer` decides which piece goes where.
##
## Two lanes, each its own row of spaces over the whole world (camp pixels, -384 to 768), both in
## spaces 28 px wide with a 4 px gap between them (a pitch of 32): the **building lane** (`BACK`, the
## back lane that every building stands on) and
## the **prop lane** (`MID`, what is smaller than a building). The prop lane is **offset by half a
## pitch**, so each prop space is centred on the gap between two building spaces: props stand
## between buildings, not in front of their doors (`LanePlacer` also refuses a prop space that
## lies inside a building that spans it). A piece takes as many spaces as it needs and may be
## smaller than them; the gap keeps two pieces that fill their spaces apart.
##
## A space is not a piece's own: `terrain` says what may stand on it, by where the space lies
## (`ZONES`, from the art: the near bank's shallows take the Quay and the fish trap, the middle of
## the river the boats, the harbour the coast, the open sea the ships, the east flats the weir and
## the baskets; ground takes the rest), and `needs_crossing` says whether it is ground out past the
## river, which villagers can reach only once the group has laid a crossing
## (`WorldLayout.crossing_open`). A space that straddles two zones, say half bank and half water,
## takes nothing. The number of spaces is the same in every age: an earlier age simply has fewer
## pieces to show.
##
## Never free: the signature building's footprint (`HALL`) and the lone pine (`PINE`); on the prop
## lane the spaces the camp's baked-in decor stands on (`is_fixed`: the bushes, rocks and stumps
## drawn into the static layers count as pieces that are always there); and the Cave Age's mammoth
## holds one building space until it is gone.
## Mirrors the camp's art (tools/art/cave_strip.js, cave_river.js, cave_pages.js): change both
## together.

const BACK: StringName = &"back"
const MID: StringName = &"mid"
const LANES: Array[StringName] = [&"back", &"mid"]

const GROUND: StringName = &"ground"
## Near the river's bank, where the water is shallow: the Quay, the fish trap, the soaking flax.
const SHALLOWS: StringName = &"shallows"
## The middle of the river: boats.
const DEEP: StringName = &"deep"
## The east spit's grass and sand, as far as the land goes at the prop row (x 616 at its foot): the salt
## pans, the baskets, the beacon, the driftwood and the spit's bushes and rocks.
const SHORE: StringName = &"shore"
## The wet flats the sea leaves at low tide, past the sand: the weir. Nothing else stands in the sea.
const FLATS: StringName = &"flats"
## Where the beach meets the sea: the harbour.
const COAST: StringName = &"coast"
## The open sea, far enough out: ships.
const SEA: StringName = &"sea"
const RESERVED: StringName = &"reserved"
## A space held by decor baked into the art, or one that lies half on one thing and half on another.
const NONE: StringName = &"none"

const WIDTH: int = 28
## The gap between one space and the next, so two pieces that fill their spaces never touch. A piece of
## `n` spaces spans `span_px(n)`: its spaces and the gaps between them.
const GAP: int = 4
const PITCH: int = WIDTH + GAP
## The left edge of each lane's first space; the world's own edge is WorldLayout.WORLD_LEFT. The
## prop lane starts half a pitch earlier, so each prop space is centred on the gap between two
## building spaces.
const ORIGINS: Dictionary = {&"back": -356, &"mid": -372}
const COUNTS: Dictionary = {&"back": 35, &"mid": 35}

## The signature building and its yard (the cave's footprint, the fire pit and the cold gathering
## spot in front), and the lone pine's trunk and crown: nothing is placed on either.
const HALL: Vector2i = Vector2i(-2, 104)
const PINE: Vector2i = Vector2i(188, 216)
const HALL_CENTER: float = 48.0
## Where the camp's river runs (x at the foot rows of the art, `tools/art/cave_pages.js`): its near
## bank's shallows, the middle, and the far bank.
const RIVER_FROM: int = 300
const FAR_BANK_FROM: int = 468
## What may stand where, by span: `[from, to, terrain]`, a space belonging to the first zone that
## holds all of it. The two lanes differ: the Quay, the harbour and the ships are on the building
## lane, the boats, the weir and the baskets on the prop lane. A building's foot row is higher up
## the bank than a prop's, so the building lane's ground reaches a little further (the river's
## near bank slopes from x 328 at the back to 302 at the front).
const ZONES: Dictionary = {
	&"back": [
		[-1000, 316, &"ground"], [316, 380, &"shallows"], [380, 444, &"deep"],
		[468, 580, &"ground"], [604, 700, &"coast"], [700, 1000, &"sea"],
	],
	&"mid": [
		[-1000, 300, &"ground"], [300, 360, &"shallows"], [360, 444, &"deep"],
		[476, 616, &"shore"], [616, 684, &"flats"],
	],
}
## The Cave Age's mammoth stands on the camp's back lane, so its spaces are not free until the
## age turns and the mammoth is gone (it is art, not a limit: the number of spaces is the same in
## every age).
const MAMMOTH: Vector2i = Vector2i(216, 244)
## The baked-in decor lives in these layers (the world's static props, each with the x its page
## starts at); a prop space is held by it when the decor stands in its middle `FIXED_WINDOW` px
## and rows `FIXED_ROWS`. Props are narrower than their space, so the margin is theirs.
const FIXED_LAYERS: Array = [
	[&"static_mid", 0], [&"west_static_mid", -384], [&"east_static_mid", 384],
]
const FIXED_WINDOW: int = 14
const FIXED_ROWS: Vector2i = Vector2i(66, 80)

static var _by_distance: Dictionary = {}
static var _fixed: Array[bool] = []
static var _fixed_ready: bool = false


static func width(_lane: StringName) -> int:
	return WIDTH


## How wide a piece of `spaces` spaces is: its spaces and the gaps between them.
static func span_px(spaces: int) -> int:
	return spaces * WIDTH + (spaces - 1) * GAP


static func count(lane: StringName) -> int:
	return int(COUNTS[lane])


## The camp x of a space's left edge.
static func left(lane: StringName, index: int) -> int:
	return int(ORIGINS[lane]) + index * PITCH


## The camp x of the middle of `spaces` spaces from `index` on.
static func center(lane: StringName, index: int, spaces: int = 1) -> float:
	return float(left(lane, index)) + float(span_px(spaces)) / 2.0


## The index of the space (or the gap after it) that holds camp x `x`, or -1 outside the lane.
static func index_at(lane: StringName, x: float) -> int:
	var index: int = floori((x - float(ORIGINS[lane])) / float(PITCH))
	return index if index >= 0 and index < count(lane) else -1


## Whether decor drawn into the world's static layers stands in a prop space. Read from the art
## once, so a new bush is a space it takes, not a number to keep in step.
static func is_fixed(lane: StringName, index: int) -> bool:
	if lane != MID:
		return false
	if not _fixed_ready:
		_read_fixed()
	return index >= 0 and index < _fixed.size() and _fixed[index]


static func _read_fixed() -> void:
	_fixed_ready = true
	_fixed.clear()
	var columns: Dictionary = {}
	for layer: Array in FIXED_LAYERS:
		var path: String = WorldLayout.piece_path(layer[0], 0)
		var texture: Texture2D = load(path) as Texture2D if not path.is_empty() else null
		if texture == null:
			continue
		var image: Image = texture.get_image()
		for x: int in image.get_width():
			for y: int in range(FIXED_ROWS.x, mini(FIXED_ROWS.y, image.get_height())):
				if image.get_pixel(x, y).a > 0.05:
					columns[x + int(layer[1])] = true
					break
	for index: int in count(MID):
		var middle: int = left(MID, index) + (WIDTH - FIXED_WINDOW) / 2
		var held: bool = false
		for x: int in range(middle, middle + FIXED_WINDOW):
			if columns.has(x):
				held = true
				break
		_fixed.append(held)


static func terrain(lane: StringName, index: int) -> StringName:
	var from: int = left(lane, index)
	var to: int = from + WIDTH
	if (from < HALL.y and to > HALL.x) or (from < PINE.y and to > PINE.x):
		return RESERVED
	if is_fixed(lane, index):
		return NONE
	for zone: Array in ZONES[lane]:
		if from >= int(zone[0]) and to <= int(zone[1]):
			return zone[2]
	return NONE


## The first era order from which a space is free, or -1 for one that never is (the hall, the pine,
## decor, a space on two things). Every other space is free from the start except the one the Cave
## Age's mammoth stands on: an age does not own spaces, a piece shows once it is unlocked if there
## is room.
static func open_era(lane: StringName, index: int) -> int:
	var kind: StringName = terrain(lane, index)
	if kind == RESERVED or kind == NONE:
		return -1
	var from: int = left(lane, index)
	if lane == BACK and from >= MAMMOTH.x and from < MAMMOTH.y:
		return 1
	return 0


## Whether a space is out past the river on the ground, where villagers walk only over a crossing.
## The river, the flats and the sea are looked at, not walked on, and need none.
static func needs_crossing(lane: StringName, index: int) -> bool:
	return terrain(lane, index) == GROUND and left(lane, index) >= FAR_BANK_FROM


static func is_open(lane: StringName, index: int, era_order: int, crossed: bool) -> bool:
	var first: int = open_era(lane, index)
	if first < 0 or era_order < first:
		return false
	return crossed or not needs_crossing(lane, index)


## Whether `spaces` spaces from `index` on are all open, all of `kind` and inside the lane.
static func span_open(
	lane: StringName, index: int, spaces: int, kind: StringName, era_order: int, crossed: bool
) -> bool:
	if index < 0 or index + spaces > count(lane):
		return false
	for at: int in range(index, index + spaces):
		if terrain(lane, at) != kind or not is_open(lane, at, era_order, crossed):
			return false
	return true


## How far a span's middle is from the hall: the default is the free space nearest it.
static func hall_distance(lane: StringName, index: int, spaces: int = 1) -> float:
	return absf(center(lane, index, spaces) - HALL_CENTER)


## Every start index for a piece of `spaces` spaces, nearest the hall first (the lower index wins
## a tie). Cached: the order only depends on the lane's geometry.
static func starts_by_distance(lane: StringName, spaces: int) -> Array[int]:
	var key: String = "%s:%d" % [lane, spaces]
	if _by_distance.has(key):
		return _by_distance[key]
	var starts: Array[int] = []
	for index: int in range(0, count(lane) - spaces + 1):
		starts.append(index)
	starts.sort_custom(func(a: int, b: int) -> bool:
		var da: float = hall_distance(lane, a, spaces)
		var db: float = hall_distance(lane, b, spaces)
		return a < b if is_equal_approx(da, db) else da < db
	)
	_by_distance[key] = starts
	return starts
