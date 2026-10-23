class_name VillageView
extends EntitiesView
## The village and the forest path into it: the ground, the trees along the path, the houses on
## their stilts, the cats walking about, and the leaves overhead. Cats are drawn the way they are
## in the clearing; the rest is environment, painted in code with no outlines.

## How high a house's floor stands on its stilts, its walls, and its roof's peak over them, in
## meters.
const FLOOR := 0.35
const WALL := 0.9
const ROOF := 0.55
## Where the umbul-umbul stand: two at the village's way in, two before the longhouse.
const FLAG_POLES: Array[Vector2] = [Vector2(12.8, 3.3), Vector2(12.8, 6.9), Vector2(15.2, 3.1), Vector2(20.8, 3.1)]
## The umbul-umbul's colorways, bought from the weaver: festival, the brand's rhodonite, lagoon.
const BANNERS := {
	"festival": [Palette.SCARF_RED, Palette.BRASS_LIGHT, Palette.CREAM, Palette.PAINT_TEAL],
	"rhodonite": [Palette.PINK, Palette.GRAPHITE, Palette.PINK, Palette.CREAM],
	"lagoon": [Palette.PAINT_TEAL, Palette.CREAM, Palette.CLOTH_LIGHT, Palette.CREAM],
}
## Jogiboy's trot: the dogs' frames with all four feet down (reaching, then gathered under him),
## and how far he goes in one whole stride, in meters.
const JOGI_TROT: Array[int] = [0, 1, 0, 1]
const JOGI_STRIDE := 1.0
## Paint for restored walls and bunting: each hut its own.
const PAINTS: Array[Color] = [Palette.SCARF_RED, Palette.PAINT_TEAL, Palette.BRASS_LIGHT, Palette.PINK, Palette.CLOTH_LIGHT, Palette.LEAF_LIGHT]

var village: VillageMap
## What the village keeps, for the board's marks.
var village_record: Village
## The umbul-umbul's colors, as the village wears them, and a building being restored right now,
## with how long its dust has left to settle.
var banners := "festival"
var _restoring := ""
var _restoring_for := 0.0
var _ground: ImageTexture
var _trees: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []


func _ready() -> void:
	var size := VillageMap.SIZE * World.PIXELS_PER_METER
	_ground = ImageTexture.create_from_image(EnvironmentArt.village_ground(
		Vector2i(size), 17, int(VillageMap.VILLAGE_FROM * World.PIXELS_PER_METER),
		int(VillageMap.PATH_TOP * World.PIXELS_PER_METER), int(VillageMap.PATH_BOTTOM * World.PIXELS_PER_METER)))
	var random := RandomNumberGenerator.new()
	random.seed = 23
	# The forest the path runs through: trees thick on either side of it.
	var x := 0.3
	while x < VillageMap.VILLAGE_FROM + 0.5:
		for band: Array in [[0.4, VillageMap.PATH_TOP - 0.5], [VillageMap.PATH_BOTTOM + 0.6, VillageMap.SIZE.y + 0.4]]:
			_plant_tree(Vector2(x + random.randf_range(-0.3, 0.3), random.randf_range(band[0], band[1])), random)
		x += random.randf_range(0.9, 1.5)
	# Behind the village, the forest it was cut back from.
	x = VillageMap.VILLAGE_FROM
	while x < VillageMap.SIZE.x:
		_plant_tree(Vector2(x, random.randf_range(0.05, 0.3)), random)
		x += random.randf_range(1.4, 2.4)
	# Leaves overhead: heavy over the forest path, open over the village.
	for index in 70:
		var spot := Vector2(random.randf_range(0.0, VillageMap.VILLAGE_FROM + 1.0), random.randf_range(-0.2, VillageMap.SIZE.y + 0.2))
		if spot.y > VillageMap.PATH_TOP + 0.4 and spot.y < VillageMap.PATH_BOTTOM - 0.4 and random.randf() < 0.7:
			continue
		var picture := EnvironmentArt.leaves(random.randi_range(12, 22), random.randi(), random.randf() < 0.6)
		_leaves.append({"texture": ImageTexture.create_from_image(picture), "at": (World.to_screen(spot) - Vector2(picture.get_size()) / 2.0).round()})


func _plant_tree(foot: Vector2, random: RandomNumberGenerator) -> void:
	var height := random.randi_range(80, 130)
	var picture := EnvironmentArt.trunk(height, random.randi_range(8, 14), random.randi())
	_trees.append({"texture": ImageTexture.create_from_image(picture), "at": (World.to_screen(foot) - Vector2(picture.get_width() / 2, height)).round(), "y": foot.y})


func _process(delta: float) -> void:
	if village == null:
		return
	var walkers: Array = [village.cat, village.elder, village.jogi] + village.villagers
	var walked := {}
	var last := {}
	for walker: Cat in walkers:
		var moved: float = walker.body.position.distance_to(_last.get(walker, walker.body.position))
		walked[walker] = _walked.get(walker, 0.0) + moved
		last[walker] = walker.body.position
	_walked = walked
	_last = last
	_clock += delta
	_restoring_for = maxf(_restoring_for - delta, 0.0)
	_settle_dust(delta)
	queue_redraw()


## A building just restored: a burst of dust and wood chips over it as it comes back.
func restoring(building_name: String) -> void:
	for building in village.buildings:
		if building.name != building_name:
			continue
		var footprint: Rect2 = building.footprint
		for index in 40:
			_dust.append({
				"position": Vector2(randf_range(footprint.position.x, footprint.end.x), footprint.end.y + randf_range(-0.2, 0.3)),
				"height": randf_range(0.0, 1.0), "velocity": Vector2(randf_range(-0.8, 0.8), randf_range(-0.3, 0.3)),
				"rise": randf_range(0.4, 1.4), "life": randf_range(0.5, 1.2),
			})


func _draw() -> void:
	if village == null:
		return
	draw_texture(_ground, Vector2.ZERO)
	var standing: Array[Array] = []
	for tree in _trees:
		standing.append([tree.y, tree])
	for building in village.buildings:
		standing.append([(building.footprint as Rect2).end.y, building])
	standing.append([village.cat.body.position.y, village.cat])
	standing.append([village.elder.body.position.y, village.elder])
	standing.append([village.jogi.body.position.y, {"jogi": village.jogi}])
	for villager in village.villagers:
		standing.append([villager.body.position.y, villager])
	var longhouse_restored: bool = village.buildings.any(func(building: Dictionary) -> bool: return building.name == "longhouse" and building.restored)
	for pole: Vector2 in FLAG_POLES:
		standing.append([pole.y, {"pole": pole, "restored": longhouse_restored}])
	standing.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for building in village.buildings:
		if building.restored:
			_draw_flowers(building.footprint)
	for entry in standing:
		if entry[1] is Cat:
			_draw_shadow(entry[1])
	for entry in standing:
		var thing: Variant = entry[1]
		if thing is Cat:
			_draw_cat(thing)
		elif thing.has("texture"):
			draw_texture(thing.texture, thing.at)
		elif thing.has("pole"):
			_draw_flag(thing.pole, thing.restored)
		elif thing.has("jogi"):
			_draw_jogi(thing.jogi)
		else:
			_draw_building(thing)
	for speck in _dust:
		draw_rect(Rect2(World.to_screen(speck.position, speck.height), Vector2.ONE), Palette.SMOKE)
	for cluster in _leaves:
		draw_texture(cluster.texture, cluster.at)


func _draw_building(building: Dictionary) -> void:
	var footprint: Rect2 = building.footprint
	var restored: bool = building.restored
	match building.kind:
		"board": _draw_board(footprint)
		"smithy": _draw_smithy(footprint, restored)
		"longhouse": _draw_house(footprint, restored, -1)
		"watchtower": _draw_watchtower(footprint, restored)
		"market": _draw_market(footprint, restored)
		"healer":
			_draw_house(footprint, restored, building.paint)
			_draw_herbs(footprint, restored)
		_: _draw_house(footprint, restored, building.paint)


## A house on stilts: posts under its floor, its walls with a door and a window, and a thatched
## roof whose back slope shows over its ridge.
##
## Restored, it's painted (each hut its own color, trimmed in cream), with a flower box under the
## window and bunting under the eaves; the longhouse carries a painted band along its walls and
## carved, painted gable boards. A ruin is the same house after the machines: the walls holed,
## scorched and broken off along the top, half the roof gone to bare rafters, planks on the
## ground, a scrap of bunting left hanging.
func _draw_house(footprint: Rect2, restored: bool, paint: int) -> void:
	var longhouse := paint < 0
	var front := footprint.end.y
	var back := footprint.position.y
	var left := footprint.position.x
	var right := footprint.end.x
	var eaves := FLOOR + WALL
	var peak := eaves + ROOF * (1.25 if longhouse else 1.0)
	var ridge := (front + back) / 2.0
	var overhang := 0.25
	var color: Color = Palette.CREAM if longhouse else PAINTS[paint % PAINTS.size()]
	# The stilts, and the shadow under the floor.
	_quad([Vector2(left, front), Vector2(right, front)], 0.0, FLOOR, Palette.JUNGLE_DARK)
	var post := left + 0.1
	while post <= right - 0.05:
		_quad([Vector2(post, front), Vector2(post + 0.07, front)], 0.0, FLOOR if restored or fmod(post, 1.3) > 0.4 else FLOOR * 0.5, Palette.BARK)
		post += 0.6
	_quad([Vector2(left - 0.05, front + 0.05), Vector2(right + 0.05, front + 0.05)], FLOOR - 0.05, FLOOR + 0.03, Palette.BARK_LIGHT)
	var middle := (left + right) / 2.0
	if restored:
		_quad([Vector2(left, front), Vector2(right, front)], FLOOR, eaves, color)
		_quad([Vector2(left, front), Vector2(right, front)], FLOOR, FLOOR + 0.06, Palette.CREAM if not longhouse else Palette.SCARF_RED)
		_quad([Vector2(left, front), Vector2(right, front)], eaves - 0.06, eaves, Palette.CREAM if not longhouse else Palette.SCARF_RED)
		if longhouse:
			_band(left, right, front, FLOOR + 0.32)
		# The door, in its painted frame, and an open window with its flower box.
		_quad([Vector2(middle - 0.26, front), Vector2(middle + 0.26, front)], FLOOR, FLOOR + 0.64, Palette.BARK_LIGHT if longhouse else Palette.CREAM)
		_quad([Vector2(middle - 0.2, front), Vector2(middle + 0.2, front)], FLOOR, FLOOR + 0.58, Palette.BARK)
		for window_x in ([left + 0.35, right - 0.7] if longhouse else [left + 0.3]):
			_quad([Vector2(window_x, front), Vector2(window_x + 0.35, front)], FLOOR + 0.33, FLOOR + 0.6, Palette.JUNGLE_DEEP)
			_quad([Vector2(window_x - 0.05, front), Vector2(window_x + 0.4, front)], FLOOR + 0.27, FLOOR + 0.33, Palette.BARK_LIGHT)
			for flower in 4:
				var at := World.to_screen(Vector2(window_x + 0.05 + flower * 0.09, front), FLOOR + 0.36)
				draw_rect(Rect2(at, Vector2(1, 1)), [Palette.PINK, Palette.BRASS_LIGHT, Palette.SCARF_RED, Palette.CREAM][flower])
				draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 1)), Palette.LEAF)
	else:
		_quad([Vector2(left, front), Vector2(right, front)], FLOOR, eaves, Palette.DRY_GRASS)
		var row := FLOOR + 0.1
		while row < eaves:
			draw_line(World.to_screen(Vector2(left, front), row), World.to_screen(Vector2(right, front), row), Palette.MOSS)
			row += 0.15
		# Scorched along one side, holed through, the door hanging open on the dark.
		_quad([Vector2(right - (right - left) * 0.35, front), Vector2(right, front)], FLOOR, eaves, Palette.BURNT)
		_quad([Vector2(middle - 0.22, front), Vector2(middle + 0.22, front)], FLOOR, FLOOR + 0.6, Palette.JUNGLE_DEEP)
		_quad([Vector2(left + 0.25, front), Vector2(left + 0.55, front)], FLOOR + 0.25, FLOOR + 0.5, Palette.JUNGLE_DEEP)
		# The wall broken off along its top: what's left stands at uneven heights.
		var column := left
		var step := 0
		while column < right:
			var lost: float = [0.0, 0.25, 0.12, 0.35, 0.05, 0.2][step % 6]
			_quad([Vector2(column, front), Vector2(minf(column + 0.18, right), front)], eaves - lost, eaves, Palette.JUNGLE_DARK)
			column += 0.18
			step += 1
	# The roof: whole and thatched once restored; on a ruin, the back slope gone, half the front
	# fallen in, and bare rafters where it was.
	if restored:
		_slope(Vector2(left - overhang, ridge), Vector2(right + overhang, ridge), peak, Vector2(left - overhang, back - 0.1), Vector2(right + overhang, back - 0.1), eaves, Palette.BARK)
		_slope(Vector2(left - overhang, ridge), Vector2(right + overhang, ridge), peak, Vector2(left - overhang, front + 0.2), Vector2(right + overhang, front + 0.2), eaves - 0.05, Palette.BARK_LIGHT)
		_thatch(left - overhang, right + overhang, ridge, peak, front + 0.2, eaves - 0.05)
		_bunting(left - overhang, right + overhang, front + 0.2, eaves - 0.05)
		if longhouse:
			for end_x in [left - overhang, right + overhang]:
				var top := World.to_screen(Vector2(end_x, ridge), peak)
				draw_line(top, top + Vector2(-5, -6), Palette.SCARF_RED)
				draw_line(top, top + Vector2(5, -6), Palette.BRASS_LIGHT)
		else:
			# A pennant at the ridge's end, in the house's own color.
			var top := World.to_screen(Vector2(right + overhang - 0.1, ridge), peak)
			draw_line(top, top + Vector2(0, -8), Palette.BARK)
			draw_colored_polygon(PackedVector2Array([top + Vector2(1, -8), top + Vector2(7, -6), top + Vector2(1, -4)]), color)
	else:
		var kept := left - overhang + (right - left + overhang * 2.0) * 0.45
		_slope(Vector2(left - overhang, ridge), Vector2(kept, ridge), peak, Vector2(left - overhang, front + 0.2), Vector2(kept - 0.3, front + 0.2), eaves - 0.05, Palette.BARK)
		_thatch(left - overhang, kept - 0.3, ridge, peak, front + 0.2, eaves - 0.05)
		var rafter := kept
		while rafter < right + overhang:
			draw_line(World.to_screen(Vector2(rafter, ridge), peak), World.to_screen(Vector2(rafter - 0.1, front + 0.2), eaves - 0.05), Palette.BARK)
			rafter += 0.4
		draw_line(World.to_screen(Vector2(kept, ridge), peak), World.to_screen(Vector2(right + overhang, ridge), peak - 0.15), Palette.BARK)
		# Planks fallen in front, and what's left of the bunting.
		for plank in 3:
			var from := Vector2(left + 0.2 + plank * (right - left) * 0.3, front + 0.25 + plank % 2 * 0.15)
			draw_line(World.to_screen(from), World.to_screen(from + Vector2(0.5, 0.08 - plank * 0.06)), Palette.BARK_LIGHT)
		var hook := World.to_screen(Vector2(left - overhang + 0.1, front + 0.2), eaves - 0.05)
		draw_colored_polygon(PackedVector2Array([hook, hook + Vector2(3, 0), hook + Vector2(1, 4)]), Palette.PINK)
		draw_colored_polygon(PackedVector2Array([hook + Vector2(4, 1), hook + Vector2(7, 1), hook + Vector2(5, 4)]), Palette.BRASS)


## The map of the forest, carved on a board on two posts: green where it's free, the company's
## orange marks where it isn't, and the paths between.
func _draw_board(footprint: Rect2) -> void:
	var front := footprint.end.y
	for post_x in [footprint.position.x + 0.05, footprint.end.x - 0.12]:
		_quad([Vector2(post_x, front), Vector2(post_x + 0.07, front)], 0.0, 1.0, Palette.BARK)
	_quad([Vector2(footprint.position.x - 0.1, front + 0.02), Vector2(footprint.end.x + 0.1, front + 0.02)], 0.45, 1.05, Palette.BARK_LIGHT)
	var top_left := World.to_screen(Vector2(footprint.position.x - 0.05, front + 0.02), 1.0)
	var freed: Array = village_record.liberated if village_record != null else []
	var ids := Areas.ids()
	for index in ids.size():
		var at := top_left + Vector2(4 + index * 7, 4 + (index % 2) * 6)
		draw_rect(Rect2(at, Vector2(4, 4)), Palette.LEAF if ids[index] in freed else Palette.HI_VIS)
		if index > 0:
			draw_line(at + Vector2(-3, 2 - (index % 2) * 6 + 3), at + Vector2(0, 2), Palette.BARK)


## The smithy: an open shed, its roof on four posts over the forge and the anvil. Restored, the
## forge glows; as a ruin, its roof has come down on one side and the hearth is cold and broken.
func _draw_smithy(footprint: Rect2, restored: bool) -> void:
	var front := footprint.end.y
	var back := footprint.position.y
	var left := footprint.position.x
	var right := footprint.end.x
	var eaves := 1.1
	var ridge := (front + back) / 2.0
	for corner in [Vector2(left, back + 0.2), Vector2(right - 0.08, back + 0.2)]:
		_quad([corner, corner + Vector2(0.08, 0.0)], 0.0, eaves if restored else eaves * 0.6, Palette.BARK)
	var hearth := Vector2(left + 0.4, ridge + 0.2)
	_quad([hearth, hearth + Vector2(0.9, 0.0)], 0.0, 0.5 if restored else 0.3, Palette.STEEL_DARK)
	if restored:
		# Coals glowing, flickering as they breathe.
		for coal in 6:
			var at := World.to_screen(hearth + Vector2(0.15 + coal * 0.11, 0.0), 0.48)
			var glow: Color = [Palette.SPARK, Palette.BRASS_LIGHT, Palette.SCARF_RED][(coal + int(_clock * 6.0)) % 3]
			draw_rect(Rect2(at, Vector2(3, 2)), glow)
	else:
		_quad([hearth + Vector2(0.15, 0.0), hearth + Vector2(0.75, 0.0)], 0.2, 0.3, Palette.BURNT)
	var block := Vector2(right - 1.0, front - 0.3)
	_quad([block, block + Vector2(0.3, 0.0)], 0.0, 0.3, Palette.BARK)
	_quad([block + Vector2(-0.1, 0.0), block + Vector2(0.4, 0.0)], 0.3, 0.42, Palette.STEEL)
	if restored:
		for corner in [Vector2(left, front), Vector2(right - 0.08, front)]:
			_quad([corner, corner + Vector2(0.08, 0.0)], 0.0, eaves, Palette.BARK_LIGHT)
		_slope(Vector2(left - 0.2, ridge), Vector2(right + 0.2, ridge), eaves + 0.55, Vector2(left - 0.2, back - 0.1), Vector2(right + 0.2, back - 0.1), eaves, Palette.BARK)
		_slope(Vector2(left - 0.2, ridge), Vector2(right + 0.2, ridge), eaves + 0.55, Vector2(left - 0.2, front + 0.15), Vector2(right + 0.2, front + 0.15), eaves - 0.05, Palette.BARK_LIGHT)
		_thatch(left - 0.2, right + 0.2, ridge, eaves + 0.55, front + 0.15, eaves - 0.05)
		_bunting(left - 0.2, right + 0.2, front + 0.15, eaves - 0.05)
	else:
		# The roof slid off its front posts and lies against the ground.
		_slope(Vector2(left - 0.2, back + 0.2), Vector2(right + 0.2, back + 0.2), eaves * 0.6, Vector2(left - 0.1, front + 0.3), Vector2(right + 0.3, front + 0.2), 0.0, Palette.BARK)
		_thatch(left - 0.2, right + 0.2, back + 0.2, eaves * 0.6, front + 0.25, 0.0)


## Jogiboy: his own drawing, facing the way he's going (or toward Tompel, standing). He trots,
## never gallops: legs reaching and gathering in turn, every foot on the ground, the stride long
## enough that his legs keep up with the ground he covers. Standing, his legs are under him.
func _draw_jogi(jogi: Cat) -> void:
	var moving := jogi.body.velocity.length() > 0.1
	if moving and absf(jogi.body.velocity.x) > 0.3:
		jogi.facing = Vector2(signf(jogi.body.velocity.x), 0.0)
	var facing_left := jogi.facing.x < 0.0
	var frame := JOGI_TROT[int(_walked.get(jogi, 0.0) / JOGI_STRIDE * JOGI_TROT.size()) % JOGI_TROT.size()] if moving else 1
	if village.jogi_digging:
		# Digging: his paws going, and the dirt flying out behind him.
		frame = JOGI_TROT[int(_clock * 10.0) % 2]
		var behind := World.to_screen(jogi.body.position) + Vector2(10 if facing_left else -10, -2)
		for fleck in 5:
			var arc := fmod(_clock * 3.0 + fleck * 0.37, 1.0)
			var out := Vector2((1 if facing_left else -1) * (arc * 9.0 + fleck), -sin(arc * PI) * 7.0)
			draw_rect(Rect2((behind + out).round(), Vector2.ONE), Palette.MUD_LIGHT if fleck % 2 else Palette.MUD_DARK)
	var texture := Sprites.lit(Sprites.jogi_art(frame), facing_left)
	var feet := Sprites.JOGI_FEET
	if facing_left:
		feet.x = texture.get_width() - 1 - feet.x
	var corner := World.to_screen(jogi.body.position) - feet
	# His shadow under him, a dog's length.
	draw_rect(Rect2(World.to_screen(jogi.body.position) + Vector2(-9, -1), Vector2(18, 3)), Palette.GROUND_SHADOW)
	draw_texture(texture, corner)


## Jingga's watchtower: four bamboo posts up to a lookout platform, a ladder, and a little thatched
## roof over it. A ruin is its posts snapped short and the platform down in the grass.
func _draw_watchtower(footprint: Rect2, restored: bool) -> void:
	var left := footprint.position.x + 0.15
	var right := footprint.end.x - 0.15
	var back := footprint.position.y + 0.15
	var front := footprint.end.y - 0.15
	var deck := 1.9 if restored else 0.0
	var posts: Array[Vector2] = [Vector2(left, back), Vector2(right - 0.08, back), Vector2(left, front), Vector2(right - 0.08, front)]
	for index in posts.size():
		var post: Vector2 = posts[index]
		var height: float = deck + 0.5 if restored else [0.9, 0.5, 0.7, 0.35][index]
		_quad([post, post + Vector2(0.08, 0.0)], 0.0, height, Palette.DRY_GRASS if index >= 2 else Palette.MOSS)
	if not restored:
		# The platform, fallen flat, and its ladder beside it.
		_slope(Vector2(left - 0.3, front + 0.1), Vector2(right + 0.2, front + 0.2), 0.02, Vector2(left - 0.2, front + 0.6), Vector2(right + 0.3, front + 0.7), 0.02, Palette.BARK)
		for rung in 4:
			_quad([Vector2(right + 0.3, front + 0.2 + rung * 0.12), Vector2(right + 0.6, front + 0.2 + rung * 0.12)], 0.0, 0.03, Palette.DRY_GRASS)
		return
	# The ladder up the front, rung by rung.
	var ladder := Vector2((left + right) / 2.0 - 0.15, front + 0.02)
	_quad([ladder, ladder + Vector2(0.03, 0.0)], 0.0, deck, Palette.BARK_LIGHT)
	_quad([ladder + Vector2(0.3, 0.0), ladder + Vector2(0.33, 0.0)], 0.0, deck, Palette.BARK_LIGHT)
	for rung in 6:
		_quad([ladder, ladder + Vector2(0.33, 0.0)], 0.25 + rung * 0.28, 0.29 + rung * 0.28, Palette.BARK_LIGHT)
	# The deck, its rail, and the roof over it.
	_slope(Vector2(left - 0.1, back - 0.1), Vector2(right + 0.1, back - 0.1), deck, Vector2(left - 0.1, front + 0.1), Vector2(right + 0.1, front + 0.1), deck, Palette.BARK)
	_quad([Vector2(left - 0.1, front + 0.1), Vector2(right + 0.1, front + 0.1)], deck, deck + 0.3, Palette.BARK_LIGHT)
	var middle := (back + front) / 2.0
	_slope(Vector2(left - 0.2, middle), Vector2(right + 0.2, middle), deck + 1.0, Vector2(left - 0.25, front + 0.25), Vector2(right + 0.25, front + 0.25), deck + 0.5, Palette.DRY_GRASS)
	_thatch(left - 0.25, right + 0.25, middle, deck + 1.0, front + 0.25, deck + 0.5)


## Kopi and Susu's stall: posts under a striped awning, and a counter heaped with fruit. A ruin is
## the awning torn down over the counter's broken boards.
func _draw_market(footprint: Rect2, restored: bool) -> void:
	var left := footprint.position.x + 0.1
	var right := footprint.end.x - 0.1
	var back := footprint.position.y + 0.1
	var front := footprint.end.y - 0.1
	var awning := 1.2 if restored else 0.5
	for post: Vector2 in [Vector2(left, back), Vector2(right - 0.08, back)]:
		_quad([post, post + Vector2(0.08, 0.0)], 0.0, awning + 0.25, Palette.BARK)
	# The counter: boards along the front, broken through in a ruin.
	if restored:
		_quad([Vector2(left, front - 0.3), Vector2(right, front - 0.3)], 0.0, 0.5, Palette.BARK_LIGHT)
		_quad([Vector2(left - 0.05, front - 0.3), Vector2(right + 0.05, front - 0.3)], 0.5, 0.56, Palette.BARK)
		# Fruit heaped on it, a few colors, the same every time.
		var random := RandomNumberGenerator.new()
		random.seed = 11
		for fruit in 16:
			var at := World.to_screen(Vector2(random.randf_range(left + 0.15, right - 0.15), front - 0.32), 0.58 + random.randf_range(0.0, 0.08))
			draw_rect(Rect2(at.round(), Vector2(2, 2)), [Palette.HI_VIS, Palette.LEAF_LIGHT, Palette.BRASS_LIGHT, Palette.SCARF_RED][fruit % 4])
	else:
		_quad([Vector2(left, front - 0.3), Vector2(left + 0.8, front - 0.3)], 0.0, 0.35, Palette.BARK_LIGHT)
		_quad([Vector2(right - 0.6, front - 0.3), Vector2(right, front - 0.3)], 0.0, 0.2, Palette.BARK_LIGHT)
	for post: Vector2 in [Vector2(left, front), Vector2(right - 0.08, front)]:
		_quad([post, post + Vector2(0.08, 0.0)], 0.0, awning if restored else awning * 0.5, Palette.BARK_LIGHT)
	# The awning in stripes, sloping down toward the counter, over the back of the stall; fallen
	# flat in a ruin, torn through in places.
	var stripes := 8
	for stripe in stripes:
		if not restored and stripe % 3 == 1:
			continue
		var from := lerpf(left - 0.1, right + 0.1, float(stripe) / stripes)
		var to := lerpf(left - 0.1, right + 0.1, float(stripe + 1) / stripes)
		var color := Palette.SCARF_RED if stripe % 2 == 0 else Palette.CREAM
		if restored:
			_slope(Vector2(from, back - 0.05), Vector2(to, back - 0.05), awning + 0.3, Vector2(from, front - 0.45), Vector2(to, front - 0.45), awning, color)
		else:
			_slope(Vector2(from, back + 0.1), Vector2(to, back + 0.1), 0.25, Vector2(from, front + 0.1), Vector2(to, front + 0.1), 0.02, color)


## Bu Jamu's pots of herbs out front of the healer's hut: turmeric, ginger and lemongrass growing,
## or knocked over in the ruin.
func _draw_herbs(footprint: Rect2, restored: bool) -> void:
	for index in 3:
		var pot := Vector2(footprint.position.x + 0.3 + index * 0.6, footprint.end.y + 0.25)
		if restored:
			_quad([pot, pot + Vector2(0.25, 0.0)], 0.0, 0.18, Palette.MUD_LIGHT)
			var at := World.to_screen(pot + Vector2(0.12, 0.0), 0.2)
			for leaf in 4:
				draw_rect(Rect2((at + Vector2(-3 + leaf * 2, -2 - leaf % 2 * 2)).round(), Vector2(1, 3)), Palette.LEAF if index != 1 else Palette.BRASS_LIGHT)
		else:
			_slope(pot, pot + Vector2(0.25, 0.0), 0.05, pot + Vector2(0.05, 0.12), pot + Vector2(0.3, 0.12), 0.0, Palette.MUD_LIGHT)


## An umbul-umbul: a tall bamboo pole bowed at its tip, its long banner hanging in bands of color
## and stirring in the air. Until the longhouse is restored, a snapped stump with its banner in the
## mud.
func _draw_flag(foot: Vector2, restored: bool) -> void:
	var base := World.to_screen(foot)
	if not restored:
		draw_line(base, base + Vector2(1, -14), Palette.DRY_GRASS)
		draw_line(base + Vector2(2, 0), base + Vector2(14, -2), Palette.SCARF_RED)
		draw_line(base + Vector2(2, 1), base + Vector2(12, -1), Palette.BRASS)
		return
	var top := base + Vector2(0, -88)
	draw_line(base, top, Palette.DRY_GRASS)
	draw_line(base + Vector2(1, 0), top + Vector2(1, 2), Palette.MOSS)
	# The tip bows over, and the banner hangs from it.
	var tip := top + Vector2(6, 3)
	draw_line(top, tip, Palette.DRY_GRASS)
	var colors: Array = BANNERS.get(banners, BANNERS.festival)
	for band in 14:
		var sway := roundf(sin(_clock * 2.0 + band * 0.4 + foot.x) * minf(band * 0.4, 3.0))
		draw_rect(Rect2(tip + Vector2(-2 + sway, 1 + band * 4), Vector2(4, 4)), colors[band / 3 % colors.size()])


## Flowers in the grass about a restored building, in the same places every time.
func _draw_flowers(footprint: Rect2) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = hash(footprint)
	var colors: Array[Color] = [Palette.PINK, Palette.BRASS_LIGHT, Palette.CREAM, Palette.SCARF_RED]
	for flower in 10:
		var side := random.randf() < 0.5
		var spot := Vector2(
			footprint.position.x - 0.3 if side else footprint.end.x + 0.3,
			random.randf_range(footprint.position.y + 0.2, footprint.end.y + 0.3)) + Vector2(random.randf_range(-0.25, 0.25), 0.0)
		var at := World.to_screen(spot)
		draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 2)), Palette.LEAF)
		draw_rect(Rect2(at, Vector2(1, 1)), colors[random.randi_range(0, colors.size() - 1)])


## The longhouse's painted band: a zigzag in red and yellow along the wall.
func _band(left: float, right: float, front: float, height: float) -> void:
	var x := left
	var up := true
	while x < right - 0.1:
		var from := World.to_screen(Vector2(x, front), height + (0.0 if up else 0.12))
		var to := World.to_screen(Vector2(x + 0.12, front), height + (0.12 if up else 0.0))
		draw_line(from, to, Palette.SCARF_RED)
		draw_line(from + Vector2(0, 2), to + Vector2(0, 2), Palette.BRASS)
		x += 0.12
		up = not up


## Bunting under the eaves: little flags in turn, stirring in the air.
func _bunting(left: float, right: float, eave: float, height: float) -> void:
	var x := left + 0.1
	var index := 0
	while x < right - 0.1:
		var at := World.to_screen(Vector2(x, eave), height) + Vector2(0, 2)
		var sway := 1 if (int(_clock * 2.0) + index) % 4 == 0 else 0
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(4, 0), at + Vector2(2 + sway, 4)]), PAINTS[index % PAINTS.size()])
		x += 0.16
		index += 1


## Palm thatch on a front slope, weathered brown, laid in courses from the eave up: each course's
## lower edge darker, the ridge capped, and the eave's dark edge with its shadow on the wall under
## it.
func _thatch(left: float, right: float, ridge: float, peak: float, eave: float, eave_height: float) -> void:
	var courses := 5
	for course in range(1, courses):
		var share := float(course) / courses
		var y := lerpf(eave, ridge, share)
		var height := lerpf(eave_height, peak, share)
		draw_line(World.to_screen(Vector2(left, y), height), World.to_screen(Vector2(right, y), height), Palette.BARK)
	draw_line(World.to_screen(Vector2(left, ridge), peak), World.to_screen(Vector2(right, ridge), peak), Palette.MUD_DARK)
	var eave_left := World.to_screen(Vector2(left, eave), eave_height)
	var eave_right := World.to_screen(Vector2(right, eave), eave_height)
	draw_line(eave_left, eave_right, Palette.MUD_DARK)
	draw_rect(Rect2(eave_left + Vector2(2, 1), Vector2(eave_right.x - eave_left.x - 4, 2)), Palette.JUNGLE_DARK)


## A flat upright face along the ground from one point to another, from one height to another.
func _quad(along: Array, bottom: float, top: float, color: Color) -> void:
	var a: Vector2 = along[0]
	var b: Vector2 = along[1]
	draw_colored_polygon(PackedVector2Array([World.to_screen(a, bottom), World.to_screen(b, bottom), World.to_screen(b, top), World.to_screen(a, top)]), color)


## A roof slope from its ridge, at one height, down to its eave, at another.
func _slope(ridge_left: Vector2, ridge_right: Vector2, ridge_height: float, eave_left: Vector2, eave_right: Vector2, eave_height: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		World.to_screen(ridge_left, ridge_height), World.to_screen(ridge_right, ridge_height),
		World.to_screen(eave_right, eave_height), World.to_screen(eave_left, eave_height),
	]), color)
