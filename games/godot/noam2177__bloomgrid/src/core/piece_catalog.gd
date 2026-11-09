class_name PieceCatalog
extends RefCounted
## צורות קבועות (פוליאומינו). בלי סיבוב חופשי — רק Spin מוגבל ב-GameSession.
## i2v / i3v / i4v הן גרסאות אנכיות מוכנות, לא סיבוב בזמן אמת.

static func cells(key: String) -> Array[Vector2i]:
	match key:
		"dot":
			return [Vector2i(0, 0)]
		"i2":
			return [Vector2i(0, 0), Vector2i(1, 0)]
		"i2v":
			return [Vector2i(0, 0), Vector2i(0, 1)]
		"i3":
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
		"i3v":
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
		"l3":
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
		"o":
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
		"i4":
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
		"i4v":
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]
		"t":
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
		"l4":
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
		"j4":
			return [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)]
		"s":
			return [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
		"z":
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
		"plus":
			return [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
		"u":
			return [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
		"i5":
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
		_:
			# מפתח לא מוכר — נקודה, כדי שהמשחק לא ייפול.
			return [Vector2i(0, 0)]


## סיבוב 90° עם כיוון השעון, אחרי נרמול לפינה. rot 0 = בלי סיבוב.
static func cells_of(key: String, rot: int = 0) -> Array[Vector2i]:
	var src: Array[Vector2i] = cells(key)
	var turns := ((rot % 4) + 4) % 4
	var spun: Array[Vector2i] = []
	for c in src:
		var p := c
		for _i in range(turns):
			p = Vector2i(-p.y, p.x)
		spun.append(p)
	var min_x := 0
	var min_y := 0
	var first := true
	for p in spun:
		if first:
			min_x = p.x
			min_y = p.y
			first = false
		else:
			min_x = mini(min_x, p.x)
			min_y = mini(min_y, p.y)
	var out: Array[Vector2i] = []
	for p in spun:
		out.append(Vector2i(p.x - min_x, p.y - min_y))
	return out


static func size_of(key: String, rot: int = 0) -> Vector2i:
	var max_x := 0
	var max_y := 0
	for c in cells_of(key, rot):
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	return Vector2i(max_x + 1, max_y + 1)


static func is_known(key: String) -> bool:
	return tray_keys().find(key) >= 0


static func tray_keys() -> PackedStringArray:
	return PackedStringArray([
		"dot", "i2", "i2v", "i3", "i3v", "l3", "o", "i4", "i4v",
		"t", "l4", "j4", "s", "z", "plus", "u", "i5",
	])


static func color_of(key: String) -> int:
	return 1 + (absi(key.hash()) % 6)


static func cell_count(key: String) -> int:
	return cells(key).size()


## משקל גבוה = יותר סיכוי. tier 0 מעדיף חלקים קטנים (קליל).
static func pick_weighted(rng: RngStream, tier: int) -> String:
	var keys := tray_keys()
	var weights: Array[int] = []
	var sum := 0
	for k in keys:
		var n := cell_count(str(k))
		var w := 8
		if tier <= 1:
			w = 12 - n
		elif tier >= 3:
			w = 4 + n
		else:
			w = 6
		w = maxi(w, 1)
		weights.append(w)
		sum += w
	var roll := rng.randrange(sum)
	var acc := 0
	for i in range(keys.size()):
		acc += weights[i]
		if roll < acc:
			return str(keys[i])
	return str(keys[keys.size() - 1])
