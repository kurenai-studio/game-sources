class_name EnvironmentArt
extends RefCounted
## The forest, painted in code from the palette: the clearing's ground, grass and ferns, the trees
## at its edge and the leaves overhead. The environment has no outlines; characters do.

## A logged clearing a few months on: regrowth over most of it, mud where the machines drove.
static func ground(size: Vector2i, seed_value: int) -> Image:
	var growth := FastNoiseLite.new()
	growth.seed = seed_value
	growth.frequency = 0.006
	growth.fractal_octaves = 4
	var detail := FastNoiseLite.new()
	detail.seed = seed_value + 1
	detail.frequency = 0.08
	var growth_values := growth.get_image(size.x, size.y).get_data()
	var detail_values := detail.get_image(size.x, size.y).get_data()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var data := PackedByteArray()
	data.resize(size.x * size.y * 4)
	for y in size.y:
		for x in size.x:
			var index := y * size.x + x
			var value := growth_values[index] / 255.0 + (detail_values[index] / 255.0 - 0.5) * 0.25
			# Dither one band into the next on a checkerboard, as pixel art does.
			value += 0.02 if (x + y) % 2 == 0 else -0.02
			var color: Color
			if value > 0.66:
				color = Palette.LEAF
			elif value > 0.5:
				color = Palette.JUNGLE
			elif value > 0.4:
				color = Palette.MOSS
			elif value > 0.33:
				color = Palette.MUD_LIGHT
			else:
				color = Palette.MUD
			var litter := random.randf()
			if litter < 0.01:
				color = Palette.DRY_GRASS
			elif litter < 0.016:
				color = Palette.LEAF_LIGHT
			elif litter < 0.02:
				color = Palette.JUNGLE_DARK
			data.encode_u32(index * 4, color.to_abgr32())
	var picture := Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, data)
	_skid_trails(picture, random)
	return picture


## An area of the forest, as the company left it or as it's been since it was freed. Each place
## has its own floor: leaf litter at the village's edge, deep shade and roots in the forest, sawdust
## at the sawpits, the logged clearing's regrowth, the log slide's chute of mud down to the river,
## the offices' gravel, the airstrip's tarmac. Held by the company, it's wrecked: litter and oil,
## ruts and stumps, scorched peat. Freed, it heals: the ruts grassed over, the oil gone, flowers and
## saplings coming back. Sizes in pixels.
static func area_ground(size: Vector2i, seed_value: int, theme: String, healed: bool, smoldering: Array = []) -> Image:
	var picture := ground(size, seed_value) if theme == "clearing" and not healed else _floor(size, seed_value, theme, healed)
	var random := RandomNumberGenerator.new()
	random.seed = seed_value + 7
	match theme:
		"slide":
			_river(picture, healed)
			_chute(picture, healed, random)
		"airstrip":
			_strip(picture, healed, random)
		"offices":
			_gravel_pads(picture, healed, random)
	if not healed:
		# What the company leaves: stumps everywhere it's been, and where it's burned, scorched
		# peat; at the edge and in the forest, litter and oil from the crates.
		var stumps := {"edge": 14, "deep": 50, "sawpits": 60, "clearing": 40, "slide": 26, "offices": 18, "airstrip": 14}.get(theme, 14) as int
		for index in stumps:
			_stump(picture, Vector2(random.randf() * size.x, random.randf() * size.y), random.randi_range(6, 11), false)
		# Trunks felled and left lying, and the ruts of what dragged the rest away.
		for index in {"deep": 10, "sawpits": 14, "clearing": 10, "slide": 8, "edge": 3}.get(theme, 4) as int:
			_felled(picture, Vector2(random.randf() * size.x, random.randf() * size.y), random)
		if theme in ["edge", "deep"]:
			_skid_trails(picture, random)
		var scorched := {"edge": 1, "deep": 2, "clearing": 6, "airstrip": 9, "slide": 3, "offices": 2, "sawpits": 3}.get(theme, 0) as int
		for index in scorched:
			var center := Vector2(random.randf() * size.x, random.randf() * size.y)
			_scorch(picture, center, random.randf_range(30.0, 70.0), random)
			smoldering.append(center)
		var litter := {"edge": 220, "deep": 160, "sawpits": 260, "offices": 300, "airstrip": 200}.get(theme, 80) as int
		for index in litter:
			var at := Vector2i(random.randi_range(0, size.x - 3), random.randi_range(0, size.y - 2))
			picture.fill_rect(Rect2i(at, Vector2i(random.randi_range(1, 3), 1)), [Palette.STEEL, Palette.CREAM, Palette.HI_VIS, Palette.STEEL_DARK][random.randi_range(0, 3)])
		for index in {"edge": 5, "deep": 4, "slide": 6}.get(theme, 2) as int:
			_oil(picture, Vector2(random.randf() * size.x, random.randf() * size.y), random)
	else:
		# Healed: stumps sprouting, and flowers through the grass.
		for index in {"deep": 30, "sawpits": 36, "clearing": 24}.get(theme, 8) as int:
			_stump(picture, Vector2(random.randf() * size.x, random.randf() * size.y), random.randi_range(4, 6), true)
		# Flowers in little clumps, and saplings: the forest coming back.
		for index in 420:
			var at := Vector2i(random.randi_range(2, size.x - 3), random.randi_range(2, size.y - 3))
			var color: Color = [Palette.PINK, Palette.BRASS_LIGHT, Palette.CREAM, Palette.SCARF_RED][random.randi_range(0, 3)]
			for petal in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				if random.randf() < 0.8:
					picture.set_pixelv(at + petal, color)
			picture.set_pixelv(at + Vector2i(0, 2), Palette.LEAF)
		for index in 40:
			_sapling(picture, Vector2(random.randf() * size.x, random.randf() * size.y))
	return picture


## The floor of a place, before anything is done to it.
static func _floor(size: Vector2i, seed_value: int, theme: String, healed: bool) -> Image:
	var growth := FastNoiseLite.new()
	growth.seed = seed_value
	growth.frequency = 0.008
	growth.fractal_octaves = 3
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	# Each place's ground, as its bands from lowest to highest: on a healed one, greener throughout.
	var bands: Array = {
		"edge": [Palette.MUD, Palette.MOSS, Palette.JUNGLE, Palette.LEAF],
		"deep": [Palette.MUD_DARK, Palette.JUNGLE_DARK, Palette.JUNGLE, Palette.MOSS],
		"sawpits": [Palette.MUD, Palette.MUD_LIGHT, Palette.DRY_GRASS, Palette.BRASS],
		"clearing": [Palette.MOSS, Palette.JUNGLE, Palette.LEAF, Palette.LEAF_LIGHT],
		"slide": [Palette.MUD, Palette.MOSS, Palette.JUNGLE, Palette.LEAF],
		"offices": [Palette.STEEL_DARK, Palette.SMOKE, Palette.STEEL, Palette.MUD_LIGHT],
		"airstrip": [Palette.BURNT, Palette.DRY_GRASS, Palette.MOSS, Palette.JUNGLE],
	}.get(theme, [Palette.MUD, Palette.MOSS, Palette.JUNGLE, Palette.LEAF])
	if healed:
		bands = [Palette.MOSS, Palette.JUNGLE, Palette.LEAF, Palette.LEAF_LIGHT] if theme != "deep" else [Palette.JUNGLE_DARK, Palette.JUNGLE, Palette.MOSS, Palette.LEAF]
	var data := PackedByteArray()
	data.resize(size.x * size.y * 4)
	for y in size.y:
		for x in size.x:
			var value := growth.get_noise_2d(x, y) * 0.5 + 0.5 + (0.03 if (x + y) % 2 == 0 else -0.03)
			var color: Color = bands[clampi(int(value * bands.size()), 0, bands.size() - 1)]
			if random.randf() < 0.01:
				color = Palette.DRY_GRASS if not healed else Palette.LEAF_LIGHT
			data.encode_u32((y * size.x + x) * 4, color.to_abgr32())
	return Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, data)


## A trunk felled and left lying where it dropped, its cut end pale.
static func _felled(picture: Image, at: Vector2, random: RandomNumberGenerator) -> void:
	var length := random.randf_range(50.0, 110.0)
	var along := Vector2.from_angle(random.randf_range(-0.4, 0.4))
	for step in int(length):
		var point := at + along * step
		_stamp(picture, point, 4.0, Palette.BARK)
		_stamp(picture, point + Vector2(0, -1), 2.0, Palette.BARK_LIGHT)
	_stamp(picture, at + along * length, 4.0, Palette.DRY_GRASS)


## Oil spilled from a drum: dark, uneven, with a sheen on it.
static func _oil(picture: Image, center: Vector2, random: RandomNumberGenerator) -> void:
	for blob in 5:
		_stamp(picture, center + Vector2(random.randf_range(-14.0, 14.0), random.randf_range(-6.0, 6.0)), random.randf_range(5.0, 11.0), Palette.GRAPHITE)
	for glint in 6:
		var at := Vector2i(center + Vector2(random.randf_range(-12.0, 12.0), random.randf_range(-5.0, 5.0)))
		picture.fill_rect(Rect2i(at, Vector2i(3, 1)), [Palette.CLOTH_LIGHT, Palette.PAINT_TEAL, Palette.NOSE][glint % 3])


## A sapling: a young tree's crown of leaves on a thin stem.
static func _sapling(picture: Image, at: Vector2) -> void:
	picture.fill_rect(Rect2i(Vector2i(at) + Vector2i(0, -3), Vector2i(1, 4)), Palette.BARK)
	_stamp(picture, at + Vector2(0, -6), 3.0, Palette.LEAF)
	_stamp(picture, at + Vector2(-1, -7), 1.5, Palette.LEAF_LIGHT)


## A stump: rings of bark, cut flat; healed, a sprout coming up out of it.
static func _stump(picture: Image, center: Vector2, radius: int, sprouting: bool) -> void:
	_stamp(picture, center, radius, Palette.BARK)
	_stamp(picture, center, radius - 1, Palette.BARK_LIGHT)
	_stamp(picture, center, maxf(radius - 3, 1), Palette.DRY_GRASS)
	if sprouting:
		picture.fill_rect(Rect2i(Vector2i(center) + Vector2i(1, -2), Vector2i(1, 3)), Palette.LEAF)
		picture.fill_rect(Rect2i(Vector2i(center) + Vector2i(0, -3), Vector2i(3, 1)), Palette.LEAF_LIGHT)


## Peat burned black, smoldering at its heart.
static func _scorch(picture: Image, center: Vector2, radius: float, random: RandomNumberGenerator) -> void:
	# Burned peat isn't a circle: it creeps out in blotches, char at the heart, ash at the edges.
	radius *= 0.55
	for blotch in 9:
		var at := center + Vector2.from_angle(random.randf() * TAU) * random.randf() * radius
		_stamp(picture, at, random.randf_range(radius * 0.25, radius * 0.55), Palette.BURNT)
	for blotch in 4:
		var at := center + Vector2.from_angle(random.randf() * TAU) * random.randf() * radius * 0.5
		_stamp(picture, at, random.randf_range(radius * 0.15, radius * 0.3), Palette.GRAPHITE)
	for ash in 40:
		var at := Vector2i(center + Vector2.from_angle(random.randf() * TAU) * random.randf() * radius * 1.3)
		picture.set_pixelv(at.clamp(Vector2i.ZERO, picture.get_size() - Vector2i.ONE), Palette.SMOKE)
	for ember in 12:
		var at := center + Vector2.from_angle(random.randf() * TAU) * random.randf() * radius * 0.5
		picture.set_pixelv(Vector2i(at).clamp(Vector2i.ZERO, picture.get_size() - Vector2i.ONE), Palette.SCARF_RED if ember % 3 else Palette.HI_VIS)


## The river along the bottom: oily and gray where the company runs its barges, clear once freed.
static func _river(picture: Image, healed: bool) -> void:
	var size := picture.get_size()
	var top := size.y - 70
	picture.fill_rect(Rect2i(0, top, size.x, size.y - top), Palette.CLOTH_SHADOW)
	for x in range(0, size.x, 2):
		var ripple := int(sin(x * 0.08) * 3.0)
		picture.fill_rect(Rect2i(x, top + 20 + ripple, 2, 1), Palette.CLOTH_LIGHT if healed else Palette.CLOTH)
		if not healed and x % 9 == 0:
			picture.fill_rect(Rect2i(x, top + 40 - ripple, 5, 1), Palette.GRAPHITE)
	picture.fill_rect(Rect2i(0, top, size.x, 2), Palette.MUD_DARK)


## The chute the logs slide down: churned mud, top to bottom; healed, grass over it.
static func _chute(picture: Image, healed: bool, random: RandomNumberGenerator) -> void:
	var size := picture.get_size()
	var left := size.x / 2 - 200
	for y in range(0, size.y - 70):
		var wobble := int(sin(y * 0.02) * 12.0)
		picture.fill_rect(Rect2i(left + wobble, y, 400, 1), Palette.MUD if not healed else Palette.MOSS)
		if y % 6 == 0 and not healed:
			picture.fill_rect(Rect2i(left + wobble + random.randi_range(0, 380), y, 18, 1), Palette.MUD_DARK)


## The airstrip's tarmac down the middle, its dashes; healed, grass coming up through its cracks.
static func _strip(picture: Image, healed: bool, random: RandomNumberGenerator) -> void:
	var size := picture.get_size()
	var top := size.y / 2 - 90
	picture.fill_rect(Rect2i(0, top, size.x, 180), Palette.STEEL_DARK)
	for x in range(20, size.x, 70):
		picture.fill_rect(Rect2i(x, size.y / 2 - 2, 36, 4), Palette.CREAM)
	if healed:
		for crack in 160:
			var at := Vector2i(random.randi_range(0, size.x - 1), top + random.randi_range(0, 179))
			picture.fill_rect(Rect2i(at, Vector2i(random.randi_range(2, 8), 1)), Palette.LEAF)


## The offices' poured pads, where the cabins stood; healed, the grass taking them back.
static func _gravel_pads(picture: Image, healed: bool, random: RandomNumberGenerator) -> void:
	for pad in 6:
		var at := Vector2i(random.randi_range(40, picture.get_width() - 240), random.randi_range(40, picture.get_height() - 160))
		picture.fill_rect(Rect2i(at, Vector2i(200, 120)), Palette.SMOKE if not healed else Palette.MOSS)
		picture.fill_rect(Rect2i(at, Vector2i(200, 2)), Palette.STEEL)


## The way into the village: forest floor to the left, deep in leaf litter, the village's
## trodden earth to the right, and a path of bare earth running through both. Sizes in pixels.
static func village_ground(size: Vector2i, seed_value: int, village_from: int, path_top: int, path_bottom: int) -> Image:
	var growth := FastNoiseLite.new()
	growth.seed = seed_value
	growth.frequency = 0.01
	growth.fractal_octaves = 3
	var wobble := FastNoiseLite.new()
	wobble.seed = seed_value + 1
	wobble.frequency = 0.02
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var picture := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var value := growth.get_noise_2d(x, y) * 0.5 + 0.5 + (0.03 if (x + y) % 2 == 0 else -0.03)
			var edge := wobble.get_noise_1d(x) * 6.0
			var in_village := x + wobble.get_noise_1d(y) * 14.0 > village_from
			# Through the village the path is a worn track, narrower than the way through the trees.
			var narrowing := 18.0 if in_village else 0.0
			var on_path := y > path_top + narrowing + edge and y < path_bottom - narrowing + edge
			# Grass keeps to the village's edges, where nobody walks.
			var from_edge := minf(y, size.y - y) / size.y
			var color: Color
			if on_path:
				color = (Palette.MUD if value > 0.45 else Palette.MUD_DARK) if in_village else (Palette.MUD_LIGHT if value > 0.42 else Palette.MUD)
			elif in_village:
				var grassy := value + (0.18 - from_edge) * 1.6
				color = Palette.MOSS if grassy > 0.62 else (Palette.DRY_GRASS if grassy > 0.5 else Palette.MUD_LIGHT)
			else:
				color = Palette.JUNGLE if value > 0.55 else (Palette.JUNGLE_DARK if value > 0.4 else Palette.MOSS)
			var litter := random.randf()
			if litter < 0.012:
				color = Palette.DRY_GRASS
			elif litter < 0.02 and not on_path:
				color = Palette.LEAF_LIGHT
			picture.set_pixel(x, y, color)
	return picture


## Where the logging machines dragged trunks out: bands of churned mud with tire tracks in them.
static func _skid_trails(picture: Image, random: RandomNumberGenerator) -> void:
	var size := picture.get_size()
	for trail in 3:
		var start := Vector2(random.randf_range(0.0, size.x), -20.0)
		var end := Vector2(random.randf_range(0.0, size.x), size.y + 20.0)
		if trail == 2:
			start = Vector2(-20.0, random.randf_range(0.2, 0.8) * size.y)
			end = Vector2(size.x + 20.0, random.randf_range(0.2, 0.8) * size.y)
		var bend := Vector2(random.randf_range(-300.0, 300.0), random.randf_range(-200.0, 200.0))
		var width := random.randf_range(34.0, 48.0)
		var steps := int(start.distance_to(end) / 3.0)
		var previous := start
		for step in steps + 1:
			var along := float(step) / steps
			var point := start.lerp(end, along) + bend * sin(along * PI)
			var across := (point - previous).normalized().orthogonal()
			previous = point
			var wobble := sin(along * 40.0) * 2.0
			_stamp(picture, point, width * 0.5 + wobble, Palette.MUD)
			_stamp(picture, point, width * 0.4 + wobble, Palette.MUD_LIGHT)
			# Two tire tracks, treads every few pixels.
			if step % 2 == 0:
				for side in [-1.0, 1.0]:
					var track: Vector2 = point + across * side * width * 0.22
					picture.fill_rect(Rect2i(Vector2i(track.round()) - Vector2i(2, 1), Vector2i(4, 2)), Palette.MUD_DARK)


static func _stamp(picture: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := int(radius)
	for dy in range(-r, r + 1):
		var half := int(sqrt(maxf(radius * radius - dy * dy, 0.0)))
		picture.fill_rect(Rect2i(int(center.x) - half, int(center.y) + dy, half * 2 + 1, 1), color)


## A grass tuft, upright or bent over by something passing: its blades lean, the roots stay put.
static func tuft(lean: int) -> Image:
	var rows := ["...5...", ".5.4.5.", ".4.45.4", "4.444.4", ".34443.", "..333.."]
	return _greens(rows, lean, 3)


## A fern: low, wide fronds.
static func fern(lean: int) -> Image:
	var rows := [
		"......5......",
		"..5..454..5..",
		".454.444.454.",
		"4544443444454",
		".34433333443.",
		"..333222333..",
	]
	return _greens(rows, lean, 3)


static func _greens(rows: Array, lean: int, bending_rows: int) -> Image:
	var legend := {"2": Palette.JUNGLE_DARK, "3": Palette.JUNGLE, "4": Palette.LEAF, "5": Palette.LEAF_LIGHT}
	var width: int = rows[0].length() + 2
	var picture := Image.create_empty(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		# The tips lean furthest, the base not at all.
		var shift := 1 + (lean * (bending_rows - y) / bending_rows if y < bending_rows else 0)
		for x in rows[y].length():
			var key: String = rows[y][x]
			if legend.has(key):
				picture.set_pixel(clampi(x + shift, 0, width - 1), y, legend[key])
	return picture


## A tree at the jungle's edge: a trunk lit from the left, with bark streaks and buttress roots
## flaring at its foot.
static func trunk(height: int, width: int, seed_value: int) -> Image:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var flare := width * 2
	var picture := Image.create_empty(width + flare * 2, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var near_foot := clampf(float(y - height + 18) / 18.0, 0.0, 1.0)
		var half := width * 0.5 + flare * near_foot * near_foot
		var center := picture.get_width() * 0.5
		for x in picture.get_width():
			var across := (x - center) / half
			if absf(across) > 1.0:
				continue
			var color := Palette.BARK
			if across < -0.45:
				color = Palette.BARK_LIGHT
			elif across > 0.5:
				color = Palette.MUD_DARK
			# Bark runs in vertical streaks.
			if (x * 5 + int(y / 6.0) * 3 + seed_value) % 9 == 0:
				color = Palette.MUD_DARK if color != Palette.MUD_DARK else Palette.BARK
			if near_foot > 0.0 and random.randf() < 0.05:
				color = Palette.MOSS
			picture.set_pixel(x, y, color)
	return picture


## A cluster of leaves, lit from the top left: many small leaves, not one blob.
static func leaves(radius: int, seed_value: int, dark: bool) -> Image:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var size := radius * 2 + 4
	var picture := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var shades := [Palette.JUNGLE_DEEP, Palette.JUNGLE_DARK, Palette.JUNGLE] if dark else [Palette.JUNGLE_DARK, Palette.JUNGLE, Palette.LEAF]
	for leaf in radius * 6:
		var at := center + Vector2.from_angle(random.randf() * TAU) * sqrt(random.randf()) * radius
		# Leaves toward the top left catch the light.
		var lit := (Vector2(-1, -1).normalized().dot((at - center) / radius) + 1.0) * 0.5
		var shade: Color = shades[clampi(int(lit * 3.0 + random.randf_range(-0.4, 0.4)), 0, 2)]
		var length := random.randi_range(2, 4)
		var direction := Vector2.from_angle(random.randf() * TAU)
		for step in length:
			var pixel := (at + direction * step).round()
			if Rect2(Vector2.ZERO, Vector2(size, size)).has_point(pixel):
				picture.set_pixelv(Vector2i(pixel), shade)
				picture.set_pixelv(Vector2i(pixel + Vector2(0, 1)).clamp(Vector2i.ZERO, Vector2i(size - 1, size - 1)), shade)
	return picture


## A banana plant's leaf, long and drooping, torn at the edges.
static func banana_leaf(length: int, seed_value: int) -> Image:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var picture := Image.create_empty(length + 2, length / 2 + 4, false, Image.FORMAT_RGBA8)
	for x in length:
		var along := float(x) / length
		var droop := int(along * along * length * 0.3)
		var half := int(sin(along * PI) * length * 0.13) + 1
		for dy in range(-half, half + 1):
			# Torn: the odd slit through to the rib.
			if dy != 0 and (x + seed_value) % 7 == 0 and random.randf() < 0.7:
				continue
			var color := Palette.LEAF if dy < 0 else Palette.JUNGLE
			if dy == 0:
				color = Palette.LEAF_LIGHT
			var y := 2 + half + droop + dy - int(length * 0.13)
			if y >= 0 and y < picture.get_height():
				picture.set_pixel(x, y, color)
	return picture
