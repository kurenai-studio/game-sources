# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Silhouettes draws every tower, tier and spec and every creature and boss,
## inside its box, in one color when asked, and each shape stays different
## from the others. The drawings are recorded (InkPen with no canvas) and
## turned into coarse masks, so this runs headless.

const MASK: int = 40
## Two silhouettes whose masks overlap more than this (intersection over
## union) are too alike to tell apart by shape.
const MAX_OVERLAP: float = 0.8
const STATS_DIR: String = "res://data/stats/"
const FLAT: Color = Color(1.0, 0.0, 1.0, 1.0)


func test_every_tower_tier_and_spec_draws_inside_its_box() -> void:
	for type: StringName in Silhouettes.TOWERS:
		for look: Vector2i in [Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, 0), Vector2i(3, 1)]:
			var pen: InkPen = _tower(type, look.x, look.y, false)
			var label: String = "%s tier %d spec %d" % [type, look.x, look.y]
			assert_true(pen.shapes.size() >= 6, "%s draws its shapes" % label)
			var box: Rect2 = _bounds(pen)
			# Size 100 at (0, 0): within 0.52 each side (plus the outline), at
			# most 0.85 above the cell center and 0.42 below it.
			assert_true(box.position.x >= -54.0 and box.end.x <= 54.0, "%s stays within the cell width: %s" % [label, box])
			assert_true(box.position.y >= -86.0, "%s is not too tall: top %.1f" % [label, box.position.y])
			assert_true(box.end.y <= 42.0, "%s stands on its spot: bottom %.1f" % [label, box.end.y])


func test_every_creature_and_boss_draws_inside_its_box() -> void:
	var all: Array[StringName] = Silhouettes.CREATURES + Silhouettes.BOSSES
	assert_eq(Silhouettes.CREATURES.size(), 19, "eighteen creatures plus the Puff")
	assert_eq(Silhouettes.BOSSES.size(), 8, "one boss per region")
	for type: StringName in all:
		assert_true(Silhouettes.ENEMY_SIZE.has(type), "%s has a size" % type)
		var size: float = Silhouettes.enemy_size(type, 100.0)
		# Its box, plus a little room for the outline.
		var limit: Rect2 = Rect2(-0.6 * size, -0.6 * size, 1.2 * size, 1.2 * size)
		for frame: int in 4:
			var pen: InkPen = _enemy(type, frame, false)
			assert_true(pen.shapes.size() >= 3, "%s frame %d draws" % [type, frame])
			var box: Rect2 = _bounds(pen)
			assert_true(limit.encloses(box), "%s frame %d stays in its box %s: %s" % [type, frame, limit, box])


func test_flat_silhouettes_use_one_color() -> void:
	for type: StringName in Silhouettes.TOWERS:
		for look: Vector2i in [Vector2i(1, -1), Vector2i(3, 0), Vector2i(3, 1)]:
			_assert_one_color(_tower(type, look.x, look.y, true), String(type))
	for type: StringName in Silhouettes.CREATURES + Silhouettes.BOSSES:
		_assert_one_color(_enemy(type, 0, true), String(type))


func test_tiers_and_specs_change_the_shape() -> void:
	for type: StringName in Silhouettes.TOWERS:
		var masks: Array[PackedByteArray] = []
		for look: Vector2i in [Vector2i(1, -1), Vector2i(2, -1), Vector2i(3, 0), Vector2i(3, 1)]:
			masks.append(_mask(_tower(type, look.x, look.y, true), Rect2(-55.0, -90.0, 110.0, 135.0)))
		for i: int in masks.size():
			for j: int in range(i + 1, masks.size()):
				assert_true(_overlap(masks[i], masks[j]) < 0.97, "%s looks %d and %d differ in shape" % [type, i, j])


func test_tower_silhouettes_are_distinct() -> void:
	var masks: Array[PackedByteArray] = []
	for type: StringName in Silhouettes.TOWERS:
		masks.append(_mask(_tower(type, 1, -1, true), Rect2(-55.0, -90.0, 110.0, 135.0)))
	_assert_distinct(Silhouettes.TOWERS, masks)


func test_creature_silhouettes_are_distinct() -> void:
	# Each at its own size around its position, as on the map.
	var masks: Array[PackedByteArray] = []
	for type: StringName in Silhouettes.CREATURES:
		masks.append(_mask(_enemy(type, 0, true), Rect2(-50.0, -50.0, 100.0, 100.0)))
	_assert_distinct(Silhouettes.CREATURES, masks)


func test_boss_silhouettes_are_distinct() -> void:
	var masks: Array[PackedByteArray] = []
	for type: StringName in Silhouettes.BOSSES:
		masks.append(_mask(_enemy(type, 0, true), Rect2(-75.0, -75.0, 150.0, 150.0)))
	_assert_distinct(Silhouettes.BOSSES, masks)


func test_spec_list_matches_the_towers() -> void:
	assert_eq(Silhouettes.TOWERS.size(), 10)
	for type: StringName in Silhouettes.TOWERS:
		assert_true(Silhouettes.SPECS.has(type), "%s has specs" % type)
		assert_eq((Silhouettes.SPECS[type] as Array).size(), 2, "%s has two specs" % type)
	assert_true(Silhouettes.has_tower(&"bakery"))
	assert_false(Silhouettes.has_tower(&"nightling"))
	assert_true(Silhouettes.is_flyer(&"flitter"))
	assert_false(Silhouettes.is_flyer(&"scamp"))


## The ids of docs/art/NAMES.md in campaign order: the first four regions'
## cast, then the expansion's (contract 14.1), specs in order. Flyers do not
## change.
func test_ids_follow_the_contract_in_campaign_order() -> void:
	assert_eq(Silhouettes.TOWERS, [
		&"sling_post", &"pumpkin_catapult", &"lullaby_bell", &"longbow_loft", &"firework_tower", &"bakery",
		&"bramble_cottage", &"scarecrow", &"snow_fort", &"moth_lantern",
	] as Array[StringName])
	assert_eq(Silhouettes.SPECS[&"bramble_cottage"], [&"wild_bramble", &"holly_crown"])
	assert_eq(Silhouettes.SPECS[&"scarecrow"], [&"tall_scarecrow", &"crow_keeper"])
	assert_eq(Silhouettes.SPECS[&"snow_fort"], [&"big_snowball", &"flurry"])
	assert_eq(Silhouettes.SPECS[&"moth_lantern"], [&"beacon_lantern", &"lantern_garland"])
	assert_eq(Silhouettes.CREATURES, [
		&"scamp", &"pip", &"skitter", &"flitter", &"shellback", &"bubbler", &"puffball", &"puff", &"mender", &"gatecrasher", &"dusk_moth",
		&"mossbud", &"mistwisp", &"gleamer", &"sleepyhead", &"snowroller", &"yawner", &"blinker", &"hootling",
	] as Array[StringName])
	assert_eq(Silhouettes.BOSSES, [
		&"grumblesack", &"ironshell", &"moon_moth", &"old_tusk", &"burrowbelly", &"old_hayrick", &"snowsnore", &"glimmertoad",
	] as Array[StringName])
	assert_eq(Silhouettes.FLYERS, [&"flitter", &"dusk_moth", &"moon_moth"] as Array[StringName])
	for id: StringName in Silhouettes.TOWERS:
		assert_true(Silhouettes.has_tower(id), "%s has a silhouette" % id)
		assert_eq((Silhouettes.SPECS[id] as Array).size(), 2, "%s has two specs" % id)
	for id: StringName in Silhouettes.CREATURES + Silhouettes.BOSSES:
		assert_true(Silhouettes.has_enemy(id), "%s has a silhouette" % id)
		assert_true(Silhouettes.ENEMY_SIZE.has(id), "%s has a size" % id)
		assert_false(Silhouettes.has_tower(id), "%s is not a tower" % id)
	assert_eq(Silhouettes.ENEMY_SIZE.size(), Silhouettes.CREATURES.size() + Silhouettes.BOSSES.size(), "a size for each and no other")
	assert_eq(Silhouettes.SPECS.size(), Silhouettes.TOWERS.size(), "specs for each tower and no other")


## Each id in the lists draws its own picture: none falls back to the
## placeholder box or circle that an unknown id gets.
func test_listed_ids_never_draw_the_placeholder() -> void:
	var box: int = _tower(&"no_such_tower", 1, -1, true).shapes.size()
	for type: StringName in Silhouettes.TOWERS:
		assert_true(_tower(type, 1, -1, true).shapes.size() > box, "%s draws its own picture" % type)
	var blob: int = _enemy(&"no_such_creature", 0, true).shapes.size()
	for type: StringName in Silhouettes.CREATURES + Silhouettes.BOSSES:
		assert_true(_enemy(type, 0, true).shapes.size() > blob, "%s draws its own picture" % type)


## Once data/stats/ exists, every tower, spec and creature in it must have a
## silhouette, with the specs in the same order.
func test_catalog_ids_have_silhouettes() -> void:
	var towers: Variant = _read_json(STATS_DIR + "towers.json")
	if towers is Dictionary and (towers as Dictionary).get("towers") is Array:
		for t: Variant in (towers as Dictionary)["towers"]:
			if not t is Dictionary:
				continue
			var id: StringName = StringName(str((t as Dictionary).get("id", "")))
			assert_true(Silhouettes.has_tower(id), "tower %s has a silhouette" % id)
			var specs: Variant = (t as Dictionary).get("specs", [])
			if specs is Array and Silhouettes.SPECS.has(id):
				for k: int in mini((specs as Array).size(), 2):
					var spec: Variant = (specs as Array)[k]
					var spec_id: StringName = StringName(str((spec as Dictionary).get("id", ""))) if spec is Dictionary else &""
					assert_eq(spec_id, Silhouettes.SPECS[id][k], "%s spec %d" % [id, k])
	var enemies: Variant = _read_json(STATS_DIR + "enemies.json")
	if enemies is Dictionary and (enemies as Dictionary).get("enemies") is Array:
		for e: Variant in (enemies as Dictionary)["enemies"]:
			if e is Dictionary:
				var id: StringName = StringName(str((e as Dictionary).get("id", "")))
				assert_true(Silhouettes.has_enemy(id), "creature %s has a silhouette" % id)


# Helpers.

func _tower(type: StringName, tier: int, spec: int, flat: bool) -> InkPen:
	var pen: InkPen = InkPen.new(null, FLAT if flat else Color(0.0, 0.0, 0.0, 0.0))
	Silhouettes.tower_into(pen, type, tier, spec, Vector2.ZERO, 100.0)
	return pen


func _enemy(type: StringName, frame: int, flat: bool) -> InkPen:
	var pen: InkPen = InkPen.new(null, FLAT if flat else Color(0.0, 0.0, 0.0, 0.0))
	Silhouettes.enemy_into(pen, type, Vector2.ZERO, Silhouettes.enemy_size(type, 100.0), frame)
	return pen


## The box around every solid shape (soft shadows and glows left out).
func _bounds(pen: InkPen) -> Rect2:
	var box: Rect2 = Rect2()
	var first: bool = true
	for s: InkPen.Shape in pen.shapes:
		if s.color.a < 0.5:
			continue
		for p: Vector2 in s.points:
			var r: Rect2 = Rect2(p, Vector2.ZERO).grow(s.width * 0.5)
			box = r if first else box.merge(r)
			first = false
	return box


func _assert_one_color(pen: InkPen, label: String) -> void:
	for s: InkPen.Shape in pen.shapes:
		if s.color.r != FLAT.r or s.color.g != FLAT.g or s.color.b != FLAT.b:
			fail("%s: flat drawing has a second color #%s" % [label, s.color.to_html()])
			return


func _assert_distinct(types: Array[StringName], masks: Array[PackedByteArray]) -> void:
	for i: int in masks.size():
		assert_true(_count(masks[i]) > 20, "%s has a visible shape" % types[i])
		for j: int in range(i + 1, masks.size()):
			var o: float = _overlap(masks[i], masks[j])
			assert_true(o < MAX_OVERLAP, "%s and %s overlap %.2f by shape" % [types[i], types[j], o])


## A MASK x MASK coverage grid of the recorded shapes over `rect`.
func _mask(pen: InkPen, rect: Rect2) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(MASK * MASK)
	var boxes: Array[Rect2] = []
	for s: InkPen.Shape in pen.shapes:
		boxes.append(Rect2(s.points[0], Vector2.ZERO).expand(s.points[0]))
		for p: Vector2 in s.points:
			boxes[boxes.size() - 1] = boxes[boxes.size() - 1].expand(p)
		boxes[boxes.size() - 1] = boxes[boxes.size() - 1].grow(s.width * 0.5)
	var step: Vector2 = rect.size / float(MASK)
	for y: int in MASK:
		for x: int in MASK:
			var p: Vector2 = rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * step
			for k: int in pen.shapes.size():
				if not boxes[k].has_point(p) or pen.shapes[k].color.a < 0.5:
					continue
				if _covers(pen.shapes[k], p):
					out[y * MASK + x] = 1
					break
	return out


func _covers(s: InkPen.Shape, p: Vector2) -> bool:
	if s.width <= 0.0:
		return Geometry2D.is_point_in_polygon(p, s.points)
	var half: float = s.width * 0.5
	for i: int in s.points.size() - 1:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, s.points[i], s.points[i + 1])) <= half:
			return true
	return false


func _overlap(a: PackedByteArray, b: PackedByteArray) -> float:
	var both: int = 0
	var either: int = 0
	for i: int in a.size():
		if a[i] == 1 and b[i] == 1:
			both += 1
		if a[i] == 1 or b[i] == 1:
			either += 1
	return 0.0 if either == 0 else float(both) / float(either)


func _count(m: PackedByteArray) -> int:
	var n: int = 0
	for v: int in m:
		n += v
	return n


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
