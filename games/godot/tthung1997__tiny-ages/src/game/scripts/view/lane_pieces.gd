class_name LanePieces
extends RefCounted
## What the view needs to know to put a building or a prop in the lane spaces (issue #50): which
## lane it stands on, how many spaces it takes, what ground it may stand on and how much the world
## needs it. View only: a building's rules (`BuildingDef`) never mention where it stands.
##
## Ranks say who gives way when every space is taken, and the sim keeps whatever the view hides:
##   1  the age's own headline piece (the Field, the Smithy or the Trading Post, the Bloomery or the
##      Granary, the market arcade, the harbour); the signature building itself is not in a space
##   2  a living need: shelter, food, water, a craft the town lives on
##   3  answer scenery: what a fork or a milestone put on the ground (the village's roofs too)
##   4  flavour
##   5  decor (`SceneProps.is_decor`: the bushes, rocks and stumps): always there, and the first thing
##      hidden when a prop needs the room
## Ranks 1 and 2 always show (`test_lane_spaces.gd` checks every age has the spaces for them); 3 and
## 4 compete for what is left, best rank first and newest first within a rank. A piece that
## replaces others (`SceneProps` `replaced_by`) never ranks below them, so it never makes the group
## lose a piece by gaining a tidier one.
##
## Only the root of a group of alternatives is listed (`SceneProps` `alt_of`: the market's stalls,
## ring and tally post stand in the same spaces, only one was ever taken), and an overlay (the dyed
## cloth) follows its base. Not here, because they are continuous backdrop and no space's own: the
## low wall, the town wall and the rampart, the street, the crossing and its bridges, the flood
## bank, the camp's road and the cave's standard (`BACKDROP`).

const BACK: StringName = LaneSpaces.BACK
const MID: StringName = LaneSpaces.MID
const GROUND: StringName = LaneSpaces.GROUND
const SHALLOWS: StringName = LaneSpaces.SHALLOWS
const DEEP: StringName = LaneSpaces.DEEP
const SHORE: StringName = LaneSpaces.SHORE
const FLATS: StringName = LaneSpaces.FLATS
const SEA: StringName = LaneSpaces.SEA
const COAST: StringName = LaneSpaces.COAST

## Each piece's [lane, spaces, terrain, rank]. A space is 28 px wide on both lanes: a house is one
## or two, a hall three; a prop is usually one, and stands between buildings.
const TABLE: Dictionary = {
	# Buildings (`WorldLayout.BUILDINGS`).
	&"lookout": [BACK, 2, GROUND, 3],
	&"drying_rack": [BACK, 1, GROUND, 2],
	&"knapping_spot": [MID, 1, GROUND, 2],
	&"hut": [BACK, 2, GROUND, 2],
	&"field": [BACK, 2, GROUND, 1],
	&"smithy": [BACK, 2, GROUND, 1],
	&"trading_post": [BACK, 2, GROUND, 1],
	&"quay": [BACK, 2, SHALLOWS, 3],
	&"bloomery": [BACK, 1, GROUND, 1],
	&"granary": [BACK, 1, GROUND, 1],
	# The village: homes, yards and the crafts around them.
	&"west_roof_a": [BACK, 1, GROUND, 3],
	&"west_roof_b": [BACK, 1, GROUND, 3],
	&"west_pen": [BACK, 2, GROUND, 2],
	&"farmstead_herd": [BACK, 3, GROUND, 2],
	&"west_kiln": [BACK, 1, GROUND, 3],
	&"potters_yard": [BACK, 2, GROUND, 2],
	&"weavers_row": [BACK, 3, GROUND, 2],
	&"west_well": [MID, 1, GROUND, 2],
	&"water_court": [MID, 1, GROUND, 2],
	&"pots": [MID, 1, GROUND, 4],
	&"cloth_line": [MID, 2, GROUND, 4],
	&"loom": [MID, 1, GROUND, 4],
	&"hens": [MID, 1, GROUND, 4],
	&"green_stones": [MID, 1, GROUND, 4],
	&"clay_pits": [MID, 1, GROUND, 4],
	&"flax_beaten": [MID, 1, GROUND, 4],
	# The market and what the roads brought.
	&"market_stalls": [BACK, 2, GROUND, 3],
	&"market_arcade": [BACK, 2, GROUND, 1],
	&"writing_post": [BACK, 1, GROUND, 3],
	&"law_pillar": [BACK, 1, GROUND, 3],
	&"cart": [MID, 1, GROUND, 4],
	&"donkeys": [MID, 1, GROUND, 4],
	&"coin_tray": [MID, 1, GROUND, 4],
	&"slag_heap": [MID, 1, GROUND, 4],
	&"shearing_pen": [MID, 2, GROUND, 4],
	&"standing_stone": [MID, 1, GROUND, 3],
	&"reed_bundles": [MID, 1, GROUND, 4],
	# On the river.
	&"river_trap": [MID, 1, SHALLOWS, 4],
	&"flax_thread": [MID, 1, SHALLOWS, 4],
	&"boat_dugout": [MID, 1, DEEP, 3],
	&"quay_boats": [MID, 1, DEEP, 3],
	# The east spit and the sea.
	&"east_theatre": [BACK, 2, GROUND, 3],
	&"east_harbour": [BACK, 3, COAST, 1],
	&"east_sail": [BACK, 1, SEA, 4],
	&"east_deep_ship": [BACK, 1, SEA, 3],
	&"east_beacon": [MID, 1, SHORE, 3],
	&"east_tide_weir": [MID, 1, FLATS, 4],
	&"east_salt_pans": [MID, 2, SHORE, 3],
	&"east_shell_heap": [MID, 1, SHORE, 4],
	&"east_driftwood_stack": [MID, 1, SHORE, 4],
	&"east_tide_baskets": [MID, 1, SHORE, 4],
	# Decor, below every prop: hidden first when props need the room (`SceneProps.is_decor`).
	&"decor_camp_0": [MID, 1, GROUND, 5],
	&"decor_camp_1": [MID, 1, GROUND, 5],
	&"west_decor_0": [MID, 1, GROUND, 5],
	&"west_decor_1": [MID, 1, GROUND, 5],
	&"west_decor_2": [MID, 1, GROUND, 5],
	&"west_decor_3": [MID, 1, GROUND, 5],
	&"west_decor_4": [MID, 1, GROUND, 5],
	&"west_decor_5": [MID, 1, GROUND, 5],
	&"west_decor_6": [MID, 1, GROUND, 5],
	&"west_decor_7": [MID, 1, GROUND, 5],
	&"east_decor_0": [MID, 1, SHORE, 5],
	&"east_decor_1": [MID, 1, SHORE, 5],
	&"east_decor_2": [MID, 1, SHORE, 5],
	&"east_decor_3": [MID, 1, SHORE, 5],
	&"east_decor_4": [MID, 1, SHORE, 5],
	&"east_decor_5": [MID, 1, SHORE, 5],
}

## Props drawn as continuous backdrop, not in spaces; they stay where their art was drawn.
const BACKDROP: Array[StringName] = [
	&"low_wall", &"town_wall", &"rampart", &"crossing_stones", &"east_crossing_stones",
	&"crossing_log", &"east_crossing_log", &"crossing_planks", &"east_crossing_planks",
	&"river_bank", &"road_camp", &"road_market", &"road_west", &"road_hall", &"road_bank",
	&"cave_standard_cave", &"paved_street_market",
	&"paved_street_west", &"paved_street_hall", &"paved_street", &"paved_street_bank",
]

## The pieces a trader's market is: the arcade of the Classical Age once there is one, else the
## stalls, the council ring or the tally post (one group, one set of spaces).
const MARKET_KEYS: Array[StringName] = [&"market_arcade", &"market_stalls"]

## Props that are an alternative to another in `SceneProps` (`alt_of`) but stand on other ground, so
## they cannot share its spaces: the beaten flax is in the village, the soaking flax in the river.
const OWN_SPACES: Array[StringName] = [&"flax_beaten"]

## Pieces that run out from the shore into the water (the Quay's pier, the harbour's mole): their
## landward end is on the left, and it stands at the left edge of their spaces so the piece touches
## the bank instead of floating in the middle of them.
const ANCHORED: Array[StringName] = [&"quay", &"east_harbour"]

static var _used: Dictionary = {}


## Whether a piece is joined to the shore at the left edge of its spaces.
static func is_anchored(key: StringName) -> bool:
	return ANCHORED.has(key)


## The key a piece is placed under: its own id, the root of its group of alternatives, or the base
## it overlays. Pieces that share a key share their spaces.
static func key_of(id: StringName) -> StringName:
	if OWN_SPACES.has(id):
		return id
	var spec: Dictionary = SceneProps.PROPS.get(id, {})
	if spec.has("alt_of"):
		return key_of(spec["alt_of"])
	if spec.has("overlays"):
		return key_of(spec["overlays"])
	return id


## Whether a building or a prop stands in a space (not backdrop).
static func has(id: StringName) -> bool:
	return TABLE.has(key_of(id))


static func lane_of(key: StringName) -> StringName:
	return TABLE[key][0]


static func spaces_of(key: StringName) -> int:
	return int(TABLE[key][1])


static func terrain_of(key: StringName) -> StringName:
	return TABLE[key][2]


static func rank_of(key: StringName) -> int:
	return int(TABLE[key][3])


## Whether a piece may never be hidden for lack of room (ranks 1 and 2).
static func is_essential(key: StringName) -> bool:
	return rank_of(key) <= 2


## Whether a piece stands on the shared prop foot row (`WorldLayout.PROP_FOOT`): the prop lane's
## pieces on ground or shore. The river's own keep the rows they were drawn on, in the water.
static func is_on_prop_foot(key: StringName) -> bool:
	return TABLE.has(key) and lane_of(key) == MID and [GROUND, SHORE, FLATS].has(terrain_of(key))


## Where a piece's drawn pixels are inside its sprite, in the newest art the age has for it:
## `Rect2i()` if it has none. Cached, because reading pixels is the slow part.
static func art_rect(layer: StringName, era_order: int) -> Rect2i:
	var path: String = WorldLayout.piece_path(layer, era_order)
	if path.is_empty():
		return Rect2i()
	if _used.has(path):
		return _used[path]
	var texture: Texture2D = load(path) as Texture2D
	var rect: Rect2i = Rect2i()
	if texture != null:
		rect = texture.get_image().get_used_rect()
	_used[path] = rect
	return rect
