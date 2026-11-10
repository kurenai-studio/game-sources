class_name SeasonLook
extends RefCounted
## How each season changes the palette of the whole scene (docs/engine-and-art.md A6): a light
## colour cast, and a shift of the green in the art towards `leaf` by `strength` (autumn goes
## russet, winter goes pale, spring is fresher). Trees can also go `bare` in winter. Pure data the
## view feeds to the season shader; the sim never reads it.

const TINTS: Array[Color] = [
	Color(1.0, 1.03, 1.0), Color.WHITE, Color(1.0, 0.95, 0.88), Color(0.94, 0.96, 1.0),
]
const LEAF: Array[Color] = [
	Color(0.5, 0.95, 0.4), Color(0.3, 0.6, 0.25), Color(0.95, 0.5, 0.15), Color(0.9, 0.95, 1.0),
]
## The sea's own cast: only winter cools and dulls the water, which the palette shader leaves alone.
const SEA_TINTS: Array[Color] = [
	Color.WHITE, Color.WHITE, Color.WHITE, Color(0.86, 0.93, 1.0),
]
const STRENGTH: Array[float] = [0.4, 0.0, 0.65, 0.7]
const BARE: Array[float] = [0.0, 0.0, 0.0, 0.8]


static func tint(season: int) -> Color:
	return TINTS[clampi(season, 0, Season.COUNT - 1)]


static func sea_tint(season: int) -> Color:
	return SEA_TINTS[clampi(season, 0, Season.COUNT - 1)]


## The shader parameters for the ground, hills and everything else that is green.
static func params(season: int) -> Dictionary:
	var index: int = clampi(season, 0, Season.COUNT - 1)
	return {"leaf_color": LEAF[index], "strength": STRENGTH[index], "bare": 0.0}


## The same for the tree line, which also goes bare in winter.
static func tree_params(season: int) -> Dictionary:
	var index: int = clampi(season, 0, Season.COUNT - 1)
	return {"leaf_color": LEAF[index], "strength": STRENGTH[index], "bare": BARE[index]}
