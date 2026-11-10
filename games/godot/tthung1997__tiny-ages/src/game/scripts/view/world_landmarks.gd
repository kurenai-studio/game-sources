class_name WorldLandmarks
extends RefCounted
## The always-present things that are drawn into a shared art layer, so hover cannot tell them
## apart by their pixels alone: the camp's cave, pine and mammoth (`static_back`), and the fish and
## egrets of the river (`east_life_*`). Each has a name and the camp-pixel rectangles it lives in.
## Mirrors tools/art/cave_strip.js (obj(...) slots) and tools/art/cave_pages.js (RINGS and the reed
## tops the egrets stand on); change them together. A test checks every rectangle still holds
## something drawn.
##
## `source` is the layer whose pixels must be opaque under the pointer (`&""` takes the whole
## rectangle, for small things that move). `z` is the draw order, like `SceneProps`.
##
## The `cave` landmark is the camp's signature building (docs/ages.md, "One signature building per
## age"): the same footprint every age, a different building, so its name follows the age
## (`SIGNATURE_NAMES`, by era order) while its id and rectangle stay.

const EAST_X: float = 384.0
const WEST_X: float = 318.0
## What the camp's big landmark is called in each age, by era order.
const SIGNATURE_NAMES: Array[String] = [
	"The cave", "Longhouse", "Gatehouse", "Hill-fort hall", "Civic hall",
]

const LANDMARKS: Dictionary = {
	&"cave": {
		"name": "The cave", "z": 10, "source": &"static_back", "rects": [Rect2(0, 12, 100, 54)],
	},
	&"pine": {
		"name": "Pine", "z": 10, "source": &"static_back", "rects": [Rect2(196, 39, 16, 26)],
	},
	&"mammoth": {
		"name": "Woolly mammoth", "z": 10, "source": &"static_back",
		"rects": [Rect2(215, 36, 42, 28)],
	},
	&"fish": {
		"name": "Fish", "z": 68, "source": &"",
		"rects": [
			Rect2(EAST_X + 15, 61, 11, 6), Rect2(EAST_X + 42, 68, 11, 6),
			Rect2(EAST_X + 28, 74, 11, 6), Rect2(EAST_X + 55, 64, 11, 6),
			Rect2(EAST_X + 9, 71, 11, 6),
			# The camp page's half of the river (the same fish, laid at WEST_X).
			Rect2(WEST_X + 15, 61, 11, 6), Rect2(WEST_X + 42, 68, 11, 6),
			Rect2(WEST_X + 28, 74, 11, 6), Rect2(WEST_X + 55, 64, 11, 6),
			Rect2(WEST_X + 9, 71, 11, 6),
		],
	},
	&"egrets": {
		"name": "Egrets", "z": 71, "source": &"", "rects": [Rect2(EAST_X + 66, 38, 15, 15)],
	},
}


static func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for id: StringName in LANDMARKS:
		found.append(id)
	return found


static func name_of(id: StringName, era_order: int = 0) -> String:
	if id == &"cave":
		return SIGNATURE_NAMES[clampi(era_order, 0, SIGNATURE_NAMES.size() - 1)]
	return String(LANDMARKS[id]["name"])


static func z_of(id: StringName) -> int:
	return int(LANDMARKS[id]["z"])


static func source_of(id: StringName) -> StringName:
	return LANDMARKS[id]["source"]


## Whether a point of the world (camp pixels) is inside one of the landmark's rectangles.
static func contains(id: StringName, point: Vector2) -> bool:
	for rect: Rect2 in LANDMARKS[id]["rects"]:
		if rect.has_point(point):
			return true
	return false
