class_name WorldLayout
extends RefCounted
## Where things are in the Cave Age scene, in art pixels (384x80, ground line at y=56). Mirrors
## the slots in tools/art/cave_strip.js: change both together.

const ASSET_DIR: String = "res://assets/world/cave/"
const ASSET_ROOT: String = "res://assets/world/"
## Art folders by era order. A piece is found by looking from the current age back to the first, so
## a later age can redraw one slot (the hut, the field) and leave everything else as it was
## (docs/ages.md V10: the world accumulates, and a slot is upgraded in place).
const ERA_DIRS: Array[String] = ["cave", "settled", "bronze", "iron", "classical"]
## The fur sheets, the first outfit; the others are in `VillagerOutfit.DIRS`.
const VILLAGER_DIR: String = "res://assets/world/cave/villagers/"
## Role overlays (an apron, a pack) drawn over any villager, one sheet per profession.
const ROLE_DIR: String = "res://assets/world/roles/"

## What the viewport shows at once: one "page", the camp. Everything below is in camp pixels
## (the camp page's top-left is 0, 0); the world extends one page west and one page east.
const VIEW_SIZE: Vector2i = Vector2i(384, 80)
const WORLD_LEFT: int = -384
const WORLD_RIGHT: int = 768
const WORLD_WIDTH: int = WORLD_RIGHT - WORLD_LEFT
## Pages the world is made of, for the position dots.
const PAGE_COUNT: int = WORLD_WIDTH / 384
## How far an arrow press, and one wheel notch, pan.
const PAN_STEP: float = 288.0
const WHEEL_STEP: float = 48.0
## The pages beside the camp: asset-name prefix -> the camp x of the page's left edge, and the
## static prop layers each has (drawn by tools/art/cave_pages.js).
const SIDE_PAGES: Dictionary = {"west_": -384, "east_": 384}
const SIDE_STATIC: Dictionary = {
	"west_": [&"static_back", &"static_mid"], "east_": [&"static_back", &"static_mid"],
}

## Villager sheet cells are 28x30; the feet are at (14, 28) inside a cell.
const CELL_SIZE: Vector2i = Vector2i(28, 30)
const FOOT_OFFSET: Vector2 = Vector2(-14.0, -28.0)

const BACKDROP: Array[StringName] = [&"sky", &"far_hills", &"near_hills", &"trees", &"ground"]
## Backdrop layers that stay in strip and corner mode; the sky only shows in the opaque window.
const DESKTOP_BACKDROP: Array[StringName] = [&"far_hills", &"near_hills", &"trees", &"ground"]
const STATIC_Z: Dictionary = {&"static_back": 10, &"static_mid": 70}

## Where props live (docs/ages.md B10): a place is a named patch of the world, in camp pixels
## (x, y, width, height), tied to something real: the yard in front of the cave, the river bank, the
## village at the west forest's edge, the east shore. A prop (`SceneProps`) names its place and its
## art must sit inside it, so "where does this go?" has one answer. Mirrors the art scripts. The cave
## mouth takes in the opening (where the door goes, from its crown at y 47 down) as well as the
## ground in front, where the pots stand.
const PLACES: Dictionary = {
	&"cave_mouth": Rect2(0, 46, 88, 35),
	# The top of the cave's cliff, above the mouth: the standard stands on its edge (tools/art).
	&"cave_cliff": Rect2(0, 0, 88, 40),
	&"cave_yard": Rect2(88, 62, 176, 19),
	&"river_bank": Rect2(264, 56, 120, 25),
	&"west_market": Rect2(-384, 36, 56, 45),
	&"west_village": Rect2(-328, 36, 328, 45),
	&"east_shore": Rect2(384, 40, 384, 41),
}

## State-driven buildings: art slot and draw order (z is the foot row, so villagers walk
## behind or in front correctly). The world has three lanes (docs/ages.md B10): the back lane, whose
## foot row is `BACK_LANE` (the cave's base), where every building stands; the mid lane (foot rows
## 72-76) for what is smaller than a building; and the front lane (75-79) where people walk. The art
## is drawn with the first pieces on the bottom rows, so a piece is lifted onto its lane by `at`
## (dx, dy: how far its sprite is moved), and `cx`, `foot` and `z` are where it ends up. `cx` and the
## dx of `at` are only where the art was drawn: the view stands each building in the spaces
## `LanePlacer` gives it (`LaneSpaces`, issue #50) and slides the sprite there.
const BACK_LANE: int = 67
## Where the prop lane's pieces stand: one bottom row for every prop on the ground and the shore,
## whatever row each was drawn on, a little above the front lane where villagers walk (75 to 79) so
## nobody is hidden behind one (these pieces draw at `PROP_FOOT - 1` at most). The water court and
## the clay pots stood on it before the lanes. (Boats and the river's pieces keep their rows: they
## stand in the water.)
const PROP_FOOT: int = 75
const BUILDINGS: Dictionary = {
	&"lookout": {"cx": 300, "foot": 66, "z": 66, "at": Vector2(0, 0)},
	&"drying_rack": {"cx": 138, "foot": 67, "z": 67, "at": Vector2(6, -4)},
	&"knapping_spot": {"cx": 160, "foot": 76, "z": 75, "at": Vector2(0, -3)},
	&"hut": {"cx": 268, "foot": 67, "z": 67, "at": Vector2(0, -4)},
	# The Field stands on the back lane against the hall's flank in the west village, where the farmers'
	# plot and farmstead used to be (its art was drawn at the camp, x 201..251, so it is moved 269 west).
	&"field": {"cx": -41, "foot": 67, "z": 67, "at": Vector2(-269, -11)},
	# The Bronze Age's workshops stand on the back lane in the cave yard: the smithy beside the
	# rack (west of the lone pine, whose trunk would cover it), the trading post where the road
	# comes in from the west.
	&"smithy": {"cx": 172, "foot": 67, "z": 67, "at": Vector2(-12, -12)},
	&"trading_post": {"cx": 108, "foot": 67, "z": 67, "at": Vector2(0, -12)},
	# The Quay stands in the river's far lane above the stepping stones.
	&"quay": {"cx": 338, "foot": 72, "z": 72, "at": Vector2(0, 0)},
	# The Iron Age's two buildings (art drawn in place, tools/art/iron_camp.js): the Bloomery
	# against the cave's flank, beside the Smithy's yard, and the Granary, a raised store on
	# staddles, in front of the mammoth so the animal shows between its legs.
	&"bloomery": {"cx": 85, "foot": 67, "z": 67, "at": Vector2(0, 0)},
	&"granary": {"cx": 138, "foot": 67, "z": 67, "at": Vector2(-96, -1)},
}
## A building the view hides while another stands (or is going up) on its ground: the Granary takes
## the Drying Rack's place, so a field and a store do not stand on each other. The sim keeps both.
const BUILDING_FOLDED_INTO: Dictionary = {&"drying_rack": &"granary"}
## A building the view stops drawing when an age arrives, because what it was for is done another
## way: the knapping spot made stone tools, and the Bronze Age has metal. The sim keeps it.
const BUILDING_RETIRED_IN: Dictionary = {&"knapping_spot": 2}
const FLOWER_Z: int = 73

const CAVE_DOOR: Vector2 = Vector2(40.0, 78.0)
## Newcomers and returning scouts arrive along the forest path from beyond the west end: the
## east is water.
const WEST_EDGE: Vector2 = Vector2(-394.0, 77.0)
const FIRE_X: float = 72.0
const PINE_X: float = 204.0
## The stump at the forest's edge (west page), where wood is cut.
const CHOP_X: float = -66.0
## The fire pit is state-driven like a building: it appears once the fire is found. It is drawn
## with the firelight inside the cave mouth (tools/art/cave_strip.js), in FIRE_FRAMES flame frames
## named fire_pit_0.. that swap every FIRE_FRAME_SECONDS while it is in view.
const FIRE_PIT: StringName = &"fire_pit"
const FIRE_PIT_Z: int = 70
const FIRE_FRAMES: int = 4
## Where the fire pit itself is (the art piece also holds the firelight in the cave mouth).
const FIRE_HIT: Rect2 = Rect2(64, 64, 16, 14)
const FIRE_FRAME_SECONDS: float = 0.2
## How bright the glow is on each flame frame, so it breathes with the fire.
const FIRE_GLOW_FLICKER: Array[float] = [1.0, 0.9, 0.96, 0.84]
## The camp x range the fire lights; the animation sleeps while none of it is on screen.
const FIRE_LIGHT_X: Vector2 = Vector2(20.0, 120.0)
## The sea off the east page (tools/art/cave_pages.js): east_sea_0.. are the sea alone in
## SEA_FRAMES surf and swell phases, laid over the east ground (which carries phase 0) and swapped
## every SEA_FRAME_SECONDS while any of it is on screen. SEA_X is the camp x range it covers.
const SEA_FRAMES: int = 3
const SEA_FRAME_SECONDS: float = 0.8
const SEA_X: Vector2 = Vector2(587.0, 768.0)
const SEA_Z: int = -95
## The sea states: each has its own set of SEA_FRAMES phases (east_sea_choppy_0.., east_sea_rough_0..)
## with wider surf and white caps; the weather picks one (`WeatherLook.sea_state`).
const SEA_STATE_PREFIX: Array[String] = ["", "choppy_", "rough_"]
## The fire's glow is drawn over everything in the world (villagers included) but under the HUD.
const FIRE_GLOW: StringName = &"fire_glow"
const FIRE_GLOW_Z: int = 90
## The Iron Age beacon's own night light (tools/art/iron_camp.js), a full east page drawn the same
## way as the fire's glow; it is not a prop and only shows while the beacon is lit.
const BEACON_GLOW: StringName = &"east_beacon_glow"
## The beacon's flame has BEACON_FRAMES frames (`east_beacon`, `east_beacon_1..`), swapped on the
## fire's clock while any of its light is on screen. BEACON_LIGHT_X is the camp x range it lights.
const BEACON: StringName = &"east_beacon"
const BEACON_FRAMES: int = 4
## The age (an index in ERA_DIRS) whose `east_beacon_glow` is drawn round the beacon. The Classical
## folder has a glow of the same name drawn round the lighthouse, which is not where the beacon is.
const BEACON_ERA: int = 3
const BEACON_LIGHT_X: Vector2 = Vector2(580.0, 650.0)
## The lighthouse that takes the beacon's place in the Classical Age (its harbour), and the camp x range it lights.
const LIGHTHOUSE_LIGHT_X: Vector2 = Vector2(650.0, 730.0)
## The sky bodies: stars, then a sheet of the sun (cell 0) and the moon (cell 1). They sit in front
## of the sky and behind the far hills (z -100 and -99), and do not scroll with the world.
const STARS: StringName = &"stars"
const CELESTIAL: StringName = &"celestial"
const CELESTIAL_CELL: Vector2i = Vector2i(16, 16)
const SKY_Z: int = -100

## Where the group gathers while there is no fire: the cave mouth.
const COLD_X: float = 40.0
const COLD_SPOTS: Array[Vector2] = [Vector2(32, 78), Vector2(46, 79), Vector2(56, 78)]
## Hunters go to the far end of the west forest, beyond where anyone wanders, and stand watch
## facing further west.
const HUNT_X: float = -400.0
const HUNT_SPOTS: Array[Vector2] = [Vector2(-318, 77), Vector2(-296, 79), Vector2(-338, 78)]
const FIRE_SPOTS: Array[Vector2] = [Vector2(88, 78), Vector2(96, 79), Vector2(60, 79)]
const SOCIAL_SPOTS: Array[Vector2] = [Vector2(62, 78), Vector2(84, 79), Vector2(98, 78)]
const WOOD_SPOTS: Array[Vector2] = [Vector2(-82, 78), Vector2(-74, 79), Vector2(-54, 78)]
## Foragers gather round the lone pine, on its east side: the Smithy stands west of it.
const FORAGE_SPOTS: Array[Vector2] = [Vector2(212, 78), Vector2(220, 79), Vector2(228, 77)]
## The Bronze Age's workers: a Smith hammers beside the Smithy, facing it, and a Trader walks the
## road between the Trading Post and the market at the west edge of the village (docs/ages.md B4).
## Both buildings stand on the back lane, so these spots are in front of them.
const SMITHY_SPOTS: Array[Vector2] = [Vector2(182, 73), Vector2(190, 74), Vector2(176, 75)]
const POST_SPOTS: Array[Vector2] = [Vector2(100, 73), Vector2(112, 74), Vector2(120, 73)]
const MARKET_SPOTS: Array[Vector2] = [Vector2(-346, 80), Vector2(-336, 79), Vector2(-356, 79)]
const MARKET_X: float = -348.0
## The forest to the west is walkable; the camp's river stops the east at about x = 298 until a
## crossing is laid (`crossing_open`), and then the spit beyond it is walkable too.
const WANDER_X: Vector2 = Vector2(-150.0, 290.0)
const WANDER_X_CROSSED: Vector2 = Vector2(-150.0, 545.0)
const WANDER_Y: Vector2 = Vector2(75.0, 79.0)
## The two answers to "The hard crossing" (flags); either opens the way over the river, which runs
## from about x = 302 to x = 476 along the foot rows. Mirrors tools/art/cave_river.js.
const CROSSING_FLAGS: Array[StringName] = [&"stepping_stones", &"log_bridge", &"road_laid"]
const CROSSING_X: Vector2 = Vector2(302.0, 476.0)
## Foragers fish from the near bank once the group has fished, cut reeds on the far bank once there
## is a crossing, and gather shellfish on the flats at low tide (the view's picture of foraging: the
## sim only knows they forage). Each is where to stand and what to face.
const FISH_FLAGS: Array[StringName] = [&"fish_by_hand", &"fish_trap"]
const REED_FLAGS: Array[StringName] = [&"path_foraging", &"reed_beds", &"reed_teachers"]
const FISH_SPOTS: Array[Vector2] = [Vector2(294, 78), Vector2(288, 79), Vector2(297, 77)]
const FISH_FOCUS_X: float = 340.0
const REED_SPOTS: Array[Vector2] = [Vector2(494, 77), Vector2(502, 78), Vector2(498, 79)]
const REED_FOCUS_X: float = 480.0
const FLATS_SPOTS: Array[Vector2] = [Vector2(640, 78), Vector2(646, 79), Vector2(637, 77)]
const FLATS_FOCUS_X: float = 720.0
## The wet flats the sea leaves at low tide (tools/art/cave_pages.js): an overlay on the east page's
## shore, laid over the sea. It has FLATS_STEPS steps of how far out the sea is (`TideLook`), each in
## FLATS_FRAMES frames (`east_tide_flats_<step>_<frame>`) that lap in and out on the sea's clock.
const FLATS_STEPS: int = 3
const FLATS_FRAMES: int = 3
const FLATS_Z: int = -94
## The ambient life on the river and its far bank (tools/art/cave_pages.js): fish rising and birds
## on the reeds (`east_life_0..`, swapped every LIFE_FRAME_SECONDS while any of it is on screen),
## and a deer that drinks at dawn and dusk (`east_deer_0..`). LIFE_X is the camp x range they cover.
const LIFE_FRAMES: int = 3
const DEER_FRAMES: int = 2
const LIFE_FRAME_SECONDS: float = 0.9
## The fish also rise on the camp page's half of the river: the first LIFE_WEST_WIDTH columns of each frame,
## laid at LIFE_WEST_X and a frame ahead, so the two halves are not in step. They are drawn under the
## crossing (z 70), the deer (on the far bank) over it.
const LIFE_X: Vector2 = Vector2(318.0, 500.0)
const LIFE_WEST_X: float = 318.0
const LIFE_WEST_WIDTH: int = 66
const LIFE_Z: int = 68
const DEER_Z: int = 72


## Whether the group has laid a way over the river.
static func crossing_open(world: WorldState) -> bool:
	for flag: StringName in CROSSING_FLAGS:
		if world.has_flag(flag):
			return true
	return false


## How far east and west the unhurried walkers may wander.
static func wander_range(world: WorldState) -> Vector2:
	return WANDER_X_CROSSED if crossing_open(world) else WANDER_X


static func flats_frame_name(step: int, frame: int) -> StringName:
	return StringName("east_tide_flats_%d_%d" % [
		clampi(step, 1, FLATS_STEPS), posmod(frame, FLATS_FRAMES)
	])


static func life_frame_name(frame: int) -> StringName:
	return StringName("east_life_%d" % posmod(frame, LIFE_FRAMES))


static func deer_frame_name(frame: int) -> StringName:
	return StringName("east_deer_%d" % posmod(frame, DEER_FRAMES))


## The sheet that draws a villager (`VillagerOutfit.for_world` says what they wear). If the outfit
## has no sheet for the look, the next simpler outfit's is used, down to the furs; a look nobody
## has drawn wears Mira's, and a missing sheet is never an error.
static func villager_sheet_path(look: StringName, outfit: StringName) -> String:
	var start: int = maxi(VillagerOutfit.ORDER.find(outfit), 0)
	for who: StringName in [look, &"mira"]:
		for index: int in range(start, -1, -1):
			var path: String = VillagerOutfit.sheet_path(VillagerOutfit.ORDER[index], who)
			if not path.is_empty():
				return path
	return "%smira.png" % VILLAGER_DIR


## The overlay a profession adds on top of a villager's body (the Smith's apron, the Trader's
## pack): same sheet layout as the villagers', in `ROLE_DIR`. "" for a profession with none.
static func role_sheet_path(profession: StringName) -> String:
	if profession == &"":
		return ""
	var path: String = "%s%s.png" % [ROLE_DIR, profession]
	return path if ResourceLoader.exists(path) else ""


static func fire_frame_name(frame: int) -> StringName:
	return StringName("%s_%d" % [FIRE_PIT, posmod(frame, FIRE_FRAMES)])


static func beacon_frame_name(frame: int) -> StringName:
	var index: int = posmod(frame, BEACON_FRAMES)
	return BEACON if index == 0 else StringName("%s_%d" % [BEACON, index])


static func sea_frame_name(frame: int, state: int = 0) -> StringName:
	return StringName("east_sea_%s%d" % [
		SEA_STATE_PREFIX[clampi(state, 0, SEA_STATE_PREFIX.size() - 1)], posmod(frame, SEA_FRAMES)
	])


## The newest art for a piece at `era_order`: the latest age's folder that has it, or "" if none.
static func piece_path(layer: StringName, era_order: int) -> String:
	for index: int in range(mini(era_order, ERA_DIRS.size() - 1), -1, -1):
		var path: String = "%s%s/%s.png" % [ASSET_ROOT, ERA_DIRS[index], layer]
		if ResourceLoader.exists(path):
			return path
	return ""


static func spot(spots: Array[Vector2], index: int) -> Vector2:
	return spots[posmod(index, spots.size())]


## Whether the view draws a completed building: it does unless a building that takes its ground
## (`BUILDING_FOLDED_INTO`) stands or is going up.
static func building_shown(building_id: StringName, world: WorldState) -> bool:
	if not world.has_building(building_id):
		return false
	if world.era_order >= int(BUILDING_RETIRED_IN.get(building_id, 1 << 30)):
		return false
	var successor: StringName = BUILDING_FOLDED_INTO.get(building_id, &"")
	if successor == &"":
		return true
	var site: BuildingState = world.constructing()
	return not (world.has_building(successor) or (site != null and site.def_id == successor))


## How far a building's art is moved from where it was drawn (its `at`), in camp pixels.
static func building_offset(building_id: StringName) -> Vector2:
	var slot: Dictionary = BUILDINGS.get(building_id, {})
	return slot.get("at", Vector2.ZERO)


## Where a villager stands to work on a building site, in front of it. `center_x` is where the
## building stands (`LaneLayout.center_x`), its home slot if not given.
static func build_spot(building_id: StringName, index: int, center_x: float = NAN) -> Vector2:
	var slot: Dictionary = BUILDINGS.get(building_id, {})
	if is_nan(center_x):
		center_x = float(slot.get("cx", 150))
	var foot: float = float(slot.get("foot", 70))
	return Vector2(center_x - 10.0 - float(posmod(index, 3)) * 7.0, minf(foot + 3.0, 79.0))
