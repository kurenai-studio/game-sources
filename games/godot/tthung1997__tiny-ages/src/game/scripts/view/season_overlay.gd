class_name SeasonOverlay
extends RefCounted
## The few pieces a season adds on top of the palette shift: snow on the hills, the tree line and
## the ground in winter, blossom and flowers in spring, russet leaves and litter in autumn. They
## are drawn from the backdrop art itself (the top edge of a layer, or a sparse scatter over its
## green), so they sit exactly on every page and need no art of their own. Deterministic: a pixel is
## chosen by a hash of its place and the season, never by a random number. Pure and headless.

const LAYERS: Array[StringName] = [&"near_hills", &"trees", &"ground"]
const SNOW: Color = Color("eef3fa")
const SNOW_SHADE: Color = Color("cfdaea")
const BLOSSOM: Array[Color] = [Color("f4b6d0"), Color("ffffff"), Color("f9d3e2")]
const FLOWERS: Array[Color] = [Color("ffe27a"), Color("ffffff"), Color("f4b6d0")]
const LEAVES: Array[Color] = [Color("e8872a"), Color("c8501e"), Color("d9a03a")]


## The overlay for `layer` of the backdrop in `season`, the same size as `source`, or null when the
## season adds nothing there (summer, or a layer the season does not touch).
static func build(source: Image, layer: StringName, season: int) -> Image:
	if season == Season.SUMMER or not LAYERS.has(layer):
		return null
	var width: int = source.get_width()
	var height: int = source.get_height()
	var rgba: Image = source.duplicate()
	rgba.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = rgba.get_data()
	var overlay: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var any: bool = false
	for y: int in height:
		for x: int in width:
			var at: int = (y * width + x) * 4
			if data[at + 3] < 128:
				continue
			var edge: bool = y == 0 or data[at - width * 4 + 3] < 128
			var here: Color = Color8(data[at], data[at + 1], data[at + 2])
			var pick: Color = _pixel(season, layer, here, edge, _hash(x, y, season))
			if pick.a > 0.0:
				overlay.set_pixel(x, y, pick)
				any = true
	return overlay if any else null


static func _pixel(season: int, layer: StringName, here: Color, edge: bool, roll: int) -> Color:
	var green: bool = here.g > here.r and here.g > here.b
	match season:
		Season.WINTER:
			if layer == &"ground":
				if edge and green:
					return SNOW
				return SNOW_SHADE if green and roll % 100 < 9 else Color(0, 0, 0, 0)
			if edge:
				return SNOW
			return SNOW_SHADE if roll % 100 < 22 and _below_edge(roll) else Color(0, 0, 0, 0)
		Season.SPRING:
			if layer == &"trees" and edge and roll % 100 < 30:
				return BLOSSOM[roll % BLOSSOM.size()]
			if layer == &"ground" and green and roll % 100 < 3:
				return FLOWERS[roll % FLOWERS.size()]
		Season.AUTUMN:
			if layer == &"trees" and edge and roll % 100 < 40:
				return LEAVES[roll % LEAVES.size()]
			if layer == &"ground" and green and roll % 100 < 5:
				return LEAVES[roll % LEAVES.size()]
	return Color(0, 0, 0, 0)


## Snow also lies a little below the top edge of a hill or tree line, on about a third of its
## places.
static func _below_edge(roll: int) -> bool:
	return (roll / 100) % 3 == 0


static func _hash(x: int, y: int, season: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ ((season + 1) * 83492791))
