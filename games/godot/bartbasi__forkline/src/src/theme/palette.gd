# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Palette
extends RefCounted
## Color tokens for the dusk storybook theme (docs/art/THEME.md).
##
## Warm is ours, cool is theirs: towers, lanterns and the HUD accents are warm,
## night creatures are cool. Everything that matters has an INK_LINE outline,
## so contrast never depends on a fill color. Text sits on an opaque panel or
## has an ink outline. The pairs at the bottom are checked by tests/theme/.

# Sky and far hills.
const SKY_TOP: Color = Color("1e1a3c")
const SKY_MID: Color = Color("4b3767")
const SKY_LOW: Color = Color("b8676d")
const SKY_GLOW: Color = Color("f0ad7c")
const MOON: Color = Color("fff1c9")
const STAR: Color = Color("fff6e0")
const HILL_FAR: Color = Color("4a4775")
const HILL_MID: Color = Color("35506b")
const HILL_NEAR: Color = Color("253e45")

# The map: meadow, roads, build spots, route lines. This is Lantern Hill's
# ground. Regions 2 to 4 share its road, border and pebbles.
const MEADOW: Color = Color("3f644b")
const MEADOW_LIGHT: Color = Color("507458")
const MEADOW_DARK: Color = Color("33543f")
const ROAD: Color = Color("e2c18e")
const ROAD_EDGE: Color = Color("856143")
const ROAD_DOT: Color = Color("cba774")
const ROUTE: Color = Color("fff4cc")
const PAD: Color = Color("d0c6b3")
const PAD_EDGE: Color = Color("8c8274")
const THICKET: Color = Color("16122a")

# The grounds of regions 2 to 8 (docs/art/EXPANSION_LOOK.md 3). Each keeps
# about the meadow's luminance, so roads, spots, outlines and route lines keep
# their contrast. Every ground has GROUND, GROUND_LIGHT and GROUND_DARK under
# its prefix; regions 5 to 8 also have their own ROAD, ROAD_EDGE and ROAD_DOT.
# ground_token() gives the name for a region and a role. Scenery colors follow.
# 2 Millbrook: water meadow, millponds, poplars.
const MILLBROOK_GROUND: Color = Color("2d6168")
const MILLBROOK_GROUND_LIGHT: Color = Color("38757d")
const MILLBROOK_GROUND_DARK: Color = Color("26535a")
const MILLBROOK_WATER: Color = Color("24506a")
const MILLBROOK_RIPPLE: Color = Color("a3cad6")
const MILLBROOK_POPLAR: Color = Color("24483c")
const MILLBROOK_POPLAR_LIGHT: Color = Color("356550")
const MILLBROOK_KINGCUP: Color = Color("f2c14e")
const MILLBROOK_MEADOWSWEET: Color = Color("f3e6d0")
# 3 Willow Fen: misty sage, boardwalks, willows, peat pools and reeds.
const FEN_GROUND: Color = Color("505c57")
const FEN_GROUND_LIGHT: Color = Color("616e68")
const FEN_GROUND_DARK: Color = Color("444e4a")
const FEN_SEAM: Color = Color("c4a06c")
const FEN_PEAT: Color = Color("29332b")
const FEN_LILY: Color = Color("7f9a55")
const FEN_LILY_FLOWER: Color = Color("f3d9c4")
const FEN_REED: Color = Color("c3a565")
const FEN_REED_HEAD: Color = Color("6e4b33")
const FEN_WILLOW: Color = Color("93a67c")
const FEN_WILLOW_DARK: Color = Color("617556")
const FEN_MARIGOLD: Color = Color("f2b544")
# 4 Moonspire Keep: old rose stone, broken walls, clipped yews, roses.
const KEEP_GROUND: Color = Color("634749")
const KEEP_GROUND_LIGHT: Color = Color("866164")
const KEEP_GROUND_DARK: Color = Color("553c3e")
const KEEP_FLAG: Color = Color("765759")
const KEEP_IVY: Color = Color("557a4a")
const KEEP_YEW: Color = Color("2b4636")
const KEEP_YEW_LIGHT: Color = Color("3b5e47")
const KEEP_ROSE: Color = Color("f0a58f")
# 5 Hollow Lanes: deep hedge green, sunken lanes between dark banks.
const LANES_GROUND: Color = Color("41592f")
const LANES_GROUND_LIGHT: Color = Color("587340")
const LANES_GROUND_DARK: Color = Color("33482a")
const LANES_ROAD: Color = Color("e6c793")
const LANES_ROAD_EDGE: Color = Color("76563a")
const LANES_ROAD_DOT: Color = Color("cdab78")
const LANES_BANK: Color = Color("2b3b24")
const LANES_HEDGE: Color = Color("2d4b2f")
const LANES_HEDGE_LIGHT: Color = Color("3f6a3c")
const LANES_BERRY: Color = Color("4a2f5c")
const LANES_HAW: Color = Color("c24a4a")
const LANES_BLOSSOM: Color = Color("f3e6d0")
const LANES_PRIMROSE: Color = Color("f2d36b")
# 6 Russet Orchards: amber brown stubble, apple trees, hay bales.
const ORCHARD_GROUND: Color = Color("655531")
const ORCHARD_GROUND_LIGHT: Color = Color("7d6c3b")
const ORCHARD_GROUND_DARK: Color = Color("51442a")
const ORCHARD_ROAD: Color = Color("e8c99a")
const ORCHARD_ROAD_EDGE: Color = Color("85603e")
const ORCHARD_ROAD_DOT: Color = Color("cfa878")
const ORCHARD_LEAF_RUSSET: Color = Color("b4552f")
const ORCHARD_LEAF_AMBER: Color = Color("d99a3c")
const ORCHARD_APPLE: Color = Color("c7413a")
const ORCHARD_CANOPY: Color = Color("8b7d36")
const ORCHARD_CANOPY_DARK: Color = Color("6a5f2b")
const ORCHARD_HAY: Color = Color("dcb768")
const ORCHARD_HAY_DARK: Color = Color("a9843f")
# 7 Frostpine Ridge: snow at dusk, packed snow roads, snowy pines and rocks.
const FROST_GROUND: Color = Color("4d5f86")
const FROST_GROUND_LIGHT: Color = Color("667aa3")
const FROST_GROUND_DARK: Color = Color("3d4c70")
const FROST_ROAD: Color = Color("efdfc4")
const FROST_ROAD_EDGE: Color = Color("8a7764")
const FROST_ROAD_DOT: Color = Color("d8c5a6")
const FROST_PINE: Color = Color("23423f")
const FROST_PINE_LIGHT: Color = Color("2f5a52")
const FROST_SNOW_CAP: Color = Color("eef3fb")
const FROST_ROCK: Color = Color("7d8297")
# 8 Starglen: violet moss, standing stones, warm toadstools, cream motes.
const GLEN_GROUND: Color = Color("55456a")
const GLEN_GROUND_LIGHT: Color = Color("716290")
const GLEN_GROUND_DARK: Color = Color("3f3252")
const GLEN_ROAD: Color = Color("e2cfb2")
const GLEN_ROAD_EDGE: Color = Color("7f6a62")
const GLEN_ROAD_DOT: Color = Color("c8b496")
const GLEN_STONE: Color = Color("a19eb3")
const GLEN_STONE_MOSS: Color = Color("5d7a6a")
const GLEN_CAP: Color = Color("f2a77f")
const GLEN_CAP_GLOW: Color = Color("ffd3a8")
const GLEN_STEM: Color = Color("efe3cf")
const GLEN_FERN: Color = Color("2f4a4f")
const GLEN_MOTE: Color = Color("fff1c9")

# Map features (EXPANSION_LOOK.md 4), the same on every ground.
const MOUND: Color = Color("6c9150")
const MOUND_LIGHT: Color = Color("86a964")
const ICE: Color = Color("d3eaf6")
const ICE_EDGE: Color = Color("5e7fae")
const ICE_DEEP: Color = Color("4f6fa0")
## A little darker than the concept's #9a6a45, so a stump reaches 3:1 on
## every region's road, not only Starglen's.
const BARK: Color = Color("8c603e")
const BARK_TOP: Color = Color("d9bf98")

# Buildings.
const LANTERN: Color = Color("ffc65c")
const LANTERN_CORE: Color = Color("fff3c2")
const GLOW: Color = Color("ffa94a")
const PLASTER: Color = Color("f1e2c4")
const PLASTER_SHADE: Color = Color("cdb796")
const TIMBER: Color = Color("6a4836")
const WOOD: Color = Color("94633f")
const ROOF_CLAY: Color = Color("b9573f")
const ROOF_SLATE: Color = Color("50607f")
const ROOF_MOSS: Color = Color("71844a")
const ROOF_PLUM: Color = Color("7c4b73")
const STONE: Color = Color("aaa192")
const STONE_DARK: Color = Color("7a7266")
const IRON: Color = Color("4b4f63")
const PUMPKIN: Color = Color("e8873a")
const JAM: Color = Color("a8325a")
const TREE: Color = Color("3d6450")
const TREE_DARK: Color = Color("2a4a3e")
const INK_LINE: Color = Color("211a2e")
const SMOKE: Color = Color("c9c0dc")
const SHADOW: Color = Color(0.05, 0.03, 0.1, 0.28)
# The expansion towers (docs/art/EXPANSION_LOOK.md 2). Our snow is warm cream,
# so a Snow Fort's snowball never shares a color with a creature's.
const THATCH: Color = Color("d2a35a")
const SNOW_WARM: Color = Color("f6efe2")
const SNOW_WARM_SHADE: Color = Color("d9cdb8")
const HOLLY: Color = Color("4f7d4c")
const CROW: Color = Color("4f3f46")

# Night creatures and their sparkles.
const CREATURE_BASIC: Color = Color("8a93d8")
const CREATURE_FAST: Color = Color("62c8b3")
const CREATURE_ARMOR: Color = Color("8d97a8")
const CREATURE_ARMOR_SHELL: Color = Color("5f6880")
const CREATURE_SWARM: Color = Color("bf96e8")
const CREATURE_FLY: Color = Color("6fa8c9")
const CREATURE_BUBBLE: Color = Color("7fd3e3")
const CREATURE_PUFF: Color = Color("b9b4dc")
const CREATURE_MEND: Color = Color("7cbf9a")
const CREATURE_MEND_CAP: Color = Color("6b78c4")
const CREATURE_BRUTE: Color = Color("6d72b3")
const CREATURE_MOTH: Color = Color("8077ad")
const BOSS_SACK: Color = Color("9a8fcf")
const BOSS_SHELL: Color = Color("4c5470")
const BOSS_MOON: Color = Color("b9c6f4")
const BOSS_TUSK: Color = Color("7a80a8")
# The expansion creatures and bosses: periwinkle, mint, lilac, slate, teal and
# blue-white, all cool.
const CREATURE_MOSS: Color = Color("68ab95")
const CREATURE_MOSS_BUD: Color = Color("c4a8ec")
const CREATURE_MIST: Color = Color("a9b6ea")
const CREATURE_MIST_CURL: Color = Color("e4e9ff")
const CREATURE_GLEAM: Color = Color("80b8d8")
const CREATURE_GLEAM_FAN: Color = Color("a6dbe8")
const CREATURE_SLEEPY: Color = Color("989ee2")
const CREATURE_SLEEPY_CAP: Color = Color("c9b8f0")
const CREATURE_SNOWBALL: Color = Color("e2ebfb")
const CREATURE_ROLLER: Color = Color("7b98e0")
const CREATURE_YAWN: Color = Color("7c86bc")
const CREATURE_QUILT: Color = Color("b0a2de")
const CREATURE_BLINK: Color = Color("6fcac4")
const CREATURE_HOOT: Color = Color("9799c8")
const CREATURE_HOOT_FACE: Color = Color("dcdff4")
const BOSS_BURROW: Color = Color("7a76a8")
const BOSS_BURROW_NOSE: Color = Color("d6a7d8")
const BOSS_HAY: Color = Color("b4bbd2")
const BOSS_HAY_DARK: Color = Color("858caa")
const BOSS_SNORE: Color = Color("8a97cf")
const BOSS_TOAD: Color = Color("5c8aaf")
const BOSS_TOAD_SPOT: Color = Color("c4f4ff")
## The dirt mound a digging Burrowbelly shows instead of itself.
const DIRT: Color = Color("856143")
const BONE: Color = Color("efe6d2")
const EYE: Color = Color("f4fff6")
const SPARKLE: Color = Color("fff6d6")
const SPARKLE_LILAC: Color = Color("d5c2ff")
const FLOUR: Color = Color("e8f0ff")
const BUBBLE: Color = Color("dff6ff")

# Interface.
const PANEL: Color = Color("2a2140")
const PANEL_RAISED: Color = Color("3d3159")
const PANEL_HOVER: Color = Color("4a3d6b")
const PANEL_EDGE: Color = Color("8a79ad")
const CARD: Color = Color("f4e6cb")
const CARD_DIM: Color = Color("cfc3ad")
const TEXT_LIGHT: Color = Color("f7ebd3")
const TEXT_SOFT: Color = Color("c9bcd9")
const TEXT_DARK: Color = Color("2a2033")
const TEXT_MUTED: Color = Color("5a4760")
const HONEY: Color = Color("f2b544")
const HONEY_PRESSED: Color = Color("d99a2b")
const HEART: Color = Color("e8697d")
const COIN: Color = Color("ffd166")
const HP_BACK: Color = Color("2a2140")
const HP_FILL: Color = Color("a6e39a")


## Text pairs: [foreground token, background token, where it shows]. Each must
## reach 4.5:1. A token name is a constant above.
static func text_pairs() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = [
		PackedStringArray(["TEXT_LIGHT", "PANEL", "HUD numbers, hints, panels, toasts"]),
		PackedStringArray(["TEXT_SOFT", "PANEL", "secondary text on panels"]),
		PackedStringArray(["TEXT_LIGHT", "PANEL_RAISED", "buttons"]),
		PackedStringArray(["TEXT_LIGHT", "PANEL_HOVER", "a button while pressed or hovered"]),
		PackedStringArray(["TEXT_SOFT", "PANEL_RAISED", "secondary text on buttons, a disabled button"]),
		PackedStringArray(["TEXT_DARK", "HONEY", "the primary button (Start wave, Play)"]),
		PackedStringArray(["TEXT_DARK", "HONEY_PRESSED", "the primary button while pressed"]),
		PackedStringArray(["TEXT_DARK", "CARD", "tower cards, info cards"]),
		PackedStringArray(["TEXT_MUTED", "CARD", "costs and small lines on cards"]),
		PackedStringArray(["TEXT_DARK", "CARD_DIM", "a card when gold is short"]),
		PackedStringArray(["TEXT_MUTED", "CARD_DIM", "a cost when gold is short"]),
		PackedStringArray(["TEXT_LIGHT", "SKY_TOP", "titles on the night sky"]),
		PackedStringArray(["TEXT_LIGHT", "INK_LINE", "map labels with an ink outline"]),
		PackedStringArray(["COIN", "INK_LINE", "floating gold with an ink outline"]),
		PackedStringArray(["HONEY", "PANEL", "highlighted numbers on panels"]),
		PackedStringArray(["CARD", "INK_LINE", "the wordmark letters in their ink outline"]),
	]
	for ground: StringName in GROUND_PREFIX:
		# No text sits on the map ground today. This holds if it ever does.
		out.append(PackedStringArray(["TEXT_LIGHT", ground_token(ground, "GROUND"), "text on %s's ground" % ground]))
	return out


## Graphic pairs: icons, outlines, shapes against what they sit on. Each must
## reach 3:1.
static func graphic_pairs() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = [
		PackedStringArray(["ROAD", "MEADOW", "road against grass"]),
		PackedStringArray(["ROAD_EDGE", "ROAD", "the road's border"]),
		PackedStringArray(["INK_LINE", "ROAD", "creature and gate outlines on the road"]),
		PackedStringArray(["INK_LINE", "PAD", "tower outlines on their build spot"]),
		PackedStringArray(["INK_LINE", "MEADOW_LIGHT", "outlines on the lightest grass"]),
		PackedStringArray(["PAD", "MEADOW", "an empty build spot on grass"]),
		PackedStringArray(["PLASTER", "MEADOW", "cottage walls against grass"]),
		PackedStringArray(["ROUTE", "INK_LINE", "route line core inside its ink casing"]),
		PackedStringArray(["INK_LINE", "ROUTE", "route line casing against its core"]),
		PackedStringArray(["ROUTE", "MEADOW", "a flyer's dotted line over grass"]),
		PackedStringArray(["HEART", "PANEL", "lives icon"]),
		PackedStringArray(["COIN", "PANEL", "gold icon"]),
		PackedStringArray(["MOON", "PANEL", "wave icon"]),
		PackedStringArray(["HONEY", "PANEL", "primary button edge, selection ring"]),
		PackedStringArray(["CARD", "PANEL", "tower card edge"]),
		PackedStringArray(["PANEL_EDGE", "PANEL", "panel border"]),
		PackedStringArray(["INK_LINE", "HONEY", "primary button border"]),
		PackedStringArray(["LANTERN", "INK_LINE", "lantern windows in their frames"]),
		PackedStringArray(["HP_FILL", "HP_BACK", "creature health bar"]),
		PackedStringArray(["BUBBLE", "INK_LINE", "a Bubbler's bubble ring and the low mark's ring in their casing"]),
		PackedStringArray(["FLOUR", "INK_LINE", "the drowsy, fright, awake and doze marks in their casing"]),
		PackedStringArray(["HEART", "INK_LINE", "the refused gate cross in its casing"]),
		PackedStringArray(["TIMBER", "ROAD", "an open gate's arch and posts over the road"]),
		PackedStringArray(["EYE", "INK_LINE", "creature eyes"]),
		PackedStringArray(["TEXT_LIGHT", "PANEL_RAISED", "icons on buttons"]),
		PackedStringArray(["TEXT_DARK", "CARD", "tower silhouettes on cards"]),
		# The expansion's marks (Silhouettes.MARKS).
		PackedStringArray(["CREATURE_MIST_CURL", "INK_LINE", "the hidden mark's curl in its casing"]),
		PackedStringArray(["MOON", "INK_LINE", "the napping mark's moon in its outline"]),
		PackedStringArray(["DIRT", "ROAD", "the dug mound on the road"]),
		PackedStringArray(["BONE", "INK_LINE", "the dug mound's claw tips in their outline"]),
		# The expansion's cast: each body against the ink outline that holds it.
		PackedStringArray(["INK_LINE", "THATCH", "the Scarecrow's straw"]),
		PackedStringArray(["INK_LINE", "SNOW_WARM", "the Snow Fort's walls and snowballs"]),
		PackedStringArray(["INK_LINE", "HOLLY", "the Holly Crown's leaves"]),
		PackedStringArray(["INK_LINE", "CREATURE_MOSS", "the Mossbud"]),
		PackedStringArray(["INK_LINE", "CREATURE_MIST", "the Mistwisp"]),
		PackedStringArray(["INK_LINE", "CREATURE_MIST_CURL", "the Mistwisp's curl"]),
		PackedStringArray(["INK_LINE", "CREATURE_GLEAM", "the Gleamer"]),
		PackedStringArray(["INK_LINE", "CREATURE_GLEAM_FAN", "the Gleamer's fan"]),
		PackedStringArray(["INK_LINE", "CREATURE_SLEEPY", "the Sleepyhead"]),
		PackedStringArray(["INK_LINE", "CREATURE_SLEEPY_CAP", "the Sleepyhead's nightcap"]),
		PackedStringArray(["INK_LINE", "CREATURE_SNOWBALL", "the Snowroller's and Snowsnore's snowballs"]),
		PackedStringArray(["INK_LINE", "CREATURE_ROLLER", "the Snowroller"]),
		PackedStringArray(["INK_LINE", "CREATURE_YAWN", "the Yawner"]),
		PackedStringArray(["INK_LINE", "CREATURE_QUILT", "the Yawner's quilt"]),
		PackedStringArray(["INK_LINE", "CREATURE_BLINK", "the Blinker"]),
		PackedStringArray(["INK_LINE", "CREATURE_HOOT", "the Hootling"]),
		PackedStringArray(["INK_LINE", "BOSS_BURROW", "Burrowbelly"]),
		PackedStringArray(["INK_LINE", "BOSS_HAY", "Old Hayrick"]),
		PackedStringArray(["INK_LINE", "BOSS_SNORE", "Snowsnore"]),
		PackedStringArray(["INK_LINE", "BOSS_TOAD", "Glimmertoad"]),
	]
	var listed: Dictionary[String, bool] = {}
	for pair: PackedStringArray in out:
		listed[pair[0] + "/" + pair[1]] = true
	for pair: PackedStringArray in ground_pairs() + feature_pairs():
		if not listed.has(pair[0] + "/" + pair[1]):
			listed[pair[0] + "/" + pair[1]] = true
			out.append(pair)
	return out


## The token prefix of each region's ground, in campaign order (the same
## order as MapArt.GROUNDS). Lantern Hill's tokens have no prefix: its ground
## is MEADOW.
const GROUND_PREFIX: Dictionary[StringName, String] = {
	&"lantern_hill": "", &"millbrook": "MILLBROOK_", &"willow_fen": "FEN_", &"moonspire_keep": "KEEP_",
	&"hollow_lanes": "LANES_", &"russet_orchards": "ORCHARD_", &"frostpine_ridge": "FROST_", &"starglen": "GLEN_",
}
## The grounds that use Lantern Hill's ROAD, ROAD_EDGE and ROAD_DOT.
const SHARED_ROAD: Array[StringName] = [&"lantern_hill", &"millbrook", &"willow_fen", &"moonspire_keep"]
## The grounds a map feature can stand on: a run map with a feature takes
## one of these (MapArt.ground_of), and regions 1 to 4 have no features.
const FEATURE_GROUNDS: Array[StringName] = [&"hollow_lanes", &"russet_orchards", &"frostpine_ridge", &"starglen"]


## The token name of a ground's color. `role` is GROUND, GROUND_LIGHT,
## GROUND_DARK, ROAD, ROAD_EDGE or ROAD_DOT. An unknown ground is Lantern Hill.
static func ground_token(ground: StringName, role: String) -> String:
	var g: StringName = ground if GROUND_PREFIX.has(ground) else &"lantern_hill"
	if role.begins_with("ROAD") and SHARED_ROAD.has(g):
		return role
	if g == &"lantern_hill":
		return role.replace("GROUND", "MEADOW")
	return GROUND_PREFIX[g] + role


## A ground's color by role, as ground_token().
static func ground_color(ground: StringName, role: String) -> Color:
	return token(ground_token(ground, role))


## Graphic pairs on every ground: roads, spots, outlines, walls, route lines
## and the features that sit on any ground. Bridge decks only on the grounds
## where bridges can stand.
static func ground_pairs() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	for g: StringName in GROUND_PREFIX:
		var ground: String = ground_token(g, "GROUND")
		var light: String = ground_token(g, "GROUND_LIGHT")
		var road: String = ground_token(g, "ROAD")
		out.append_array([
			PackedStringArray([road, ground, "%s: road against the ground" % g]),
			PackedStringArray([road, light, "%s: road against a light patch" % g]),
			PackedStringArray([ground_token(g, "ROAD_EDGE"), road, "%s: the road's border" % g]),
			PackedStringArray(["INK_LINE", road, "%s: outlines on the road" % g]),
			PackedStringArray(["INK_LINE", light, "%s: outlines on the lightest ground" % g]),
			PackedStringArray(["PAD", ground, "%s: an empty build spot" % g]),
			PackedStringArray(["PLASTER", ground, "%s: cottage walls" % g]),
			PackedStringArray(["ROUTE", ground, "%s: a flyer's dotted line" % g]),
			PackedStringArray(["TIMBER", road, "%s: an open gate over the road" % g]),
			PackedStringArray(["ICE", ground, "%s: an ice slide on the ground" % g]),
			PackedStringArray(["ICE", light, "%s: an ice slide on a light patch" % g]),
			PackedStringArray(["BARK", road, "%s: a stump on the road" % g]),
		])
		if FEATURE_GROUNDS.has(g):
			out.append(PackedStringArray(["WOOD", road, "%s: a bridge deck over the road below" % g]))
	return out


## Graphic pairs inside the map features, the same on every ground.
static func feature_pairs() -> Array[PackedStringArray]:
	return [
		PackedStringArray(["INK_LINE", "MOUND", "a tunnel mound's outline"]),
		PackedStringArray(["THICKET", "STONE", "a dark tunnel mouth in its stone arch"]),
		PackedStringArray(["INK_LINE", "WOOD", "a bridge deck's outline"]),
		PackedStringArray(["ICE_EDGE", "ICE", "an ice slide's border"]),
		PackedStringArray(["ICE_DEEP", "ICE", "the carved chevrons on a slide"]),
		PackedStringArray(["INK_LINE", "ICE", "outlines on a slide"]),
		PackedStringArray(["INK_LINE", "BARK", "a stump's outline"]),
		PackedStringArray(["MOON", "BARK", "the crescent and star on a stump"]),
		PackedStringArray(["THICKET", "BARK_TOP", "a stump's dark hollow in its pale top"]),
	]


## The color of a token by name, or transparent black when there is none.
static func token(token_name: String) -> Color:
	var tokens: Dictionary = (Palette as Script).get_script_constant_map()
	var value: Variant = tokens.get(token_name, null)
	if value is Color:
		return value
	return Color(0.0, 0.0, 0.0, 0.0)


## WCAG 2 contrast ratio between two opaque colors, from 1 to 21.
static func contrast(a: Color, b: Color) -> float:
	var la: float = luminance(a)
	var lb: float = luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## WCAG 2 relative luminance of an sRGB color.
static func luminance(c: Color) -> float:
	return 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b)


static func _channel(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
