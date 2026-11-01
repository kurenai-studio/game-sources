extends "res://tests/base_test.gd"
## Tile labels never grow wider than label_fit times the tile side
## (DESIGN_SYSTEM.md 2.5 and 14.1), for the long labels of the unlimited
## numbers (2026-10-21): 4 characters with a capital (64Q), two lowercase
## letters (1aa, 128aa) and three (128aaa, 32kiv), at the small tiles, at
## each skin's smallest board tile on 18:9 and on 16:9, and at its board
## tile. Labels are measured through each skin's own painter, the path the
## board, the tile view and the Info rows all draw with. Every tile is given
## by its exponent k (the tile is 2^k).

const PAINTERS: Dictionary[StringName, String] = {
	&"gumdrop": "res://src/skins/gumdrop/gumdrop_tile_painter.gd",
	&"slate": "res://src/skins/slate/slate_tile_painter.gd",
	&"nova": "res://src/skins/nova/nova_tile_painter.gd",
}
## The record row mini tile (96 px), the old 72 px one, a 48 px chip.
const SMALL_SIDES: PackedFloat32Array = [96.0, 72.0, 48.0]
## Each skin's smallest board tile in px on the 1080 px canvas (3 px per
## dp, DESIGN_SYSTEM.md 2.4 and 14.1): the full spec tile, then 16:9 with a
## button bar.
const SMALLEST_SIDES: Dictionary = {
	&"gumdrop": [170.7, 140.7],
	&"slate": [178.8, 147.9],
	&"nova": [168.9, 144.0],
}
## The exponents the brief names, with their labels: 64Q (Bart's board),
## 1aa (the first lowercase suffix), 128aa (the first 5 characters), 512aa
## (the widest digits with two letters), 128aaa (the first 6) and the ceiling.
const LABELS: Dictionary[int, String] = {
	56: "64Q",
	59: "512Q",
	60: "1aa",
	67: "128aa",
	69: "512aa",
	5827: "128aaa",
	65535: "32kiv",
}
## Two lowercase letters: digits at least 15% of the side (14.1).
const TWO_LETTER_DIGITS: float = 0.15


func _painter(skin_id: StringName) -> RefCounted:
	var script: GDScript = load(PAINTERS[skin_id]) as GDScript
	var painter: RefCounted = script.new() as RefCounted
	painter.call(&"setup", SkinCatalog.get_skin(skin_id))
	return painter


func _sides(skin_id: StringName, painter: RefCounted) -> PackedFloat32Array:
	var sides: PackedFloat32Array = PackedFloat32Array()
	for side: float in SMALL_SIDES:
		sides.append(side)
	for side: float in _smallest(skin_id):
		sides.append(side)
	sides.append(float(painter.call(&"reference_side")))
	return sides


func _smallest(skin_id: StringName) -> Array[float]:
	var sides: Array[float] = []
	for side: Variant in SMALLEST_SIDES[skin_id] as Array:
		sides.append(float(side))
	return sides


## Sets the painter to a side and returns its labels.
func _labels_at(painter: RefCounted, side: float) -> RefCounted:
	var reference: float = float(painter.call(&"reference_side"))
	painter.call(&"set_side", side, side / reference)
	return painter.get(&"labels") as RefCounted


func test_the_labels_are_the_number_format_labels() -> void:
	var labels: GDScript = load("res://src/skins/common/tile_labels.gd") as GDScript
	for power: int in LABELS:
		assert_eq(String(labels.call(&"label", power)), LABELS[power], "the label of 2^%d" % power)
		assert_eq(String(labels.call(&"label", power)), NumberFormat.tile_label(power), "2^%d as NumberFormat gives it" % power)
	assert_eq(String(labels.call(&"label", 1)), "2", "the label of 2")
	assert_eq(String(labels.call(&"label", 10)), "1024", "the label of 1024")
	assert_eq(String(labels.call(&"label", 11)), "2K", "the label of 2K")
	assert_eq(String(labels.call(&"label", 0)), "", "no label for 0")
	assert_eq(String(labels.call(&"label", 65536)), "", "no label past the ceiling")


func test_long_labels_fit_in_every_skin_at_every_size() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var painter: RefCounted = _painter(skin_id)
		var limit_share: float = SkinCatalog.get_skin(skin_id).num(&"label_fit")
		for side: float in _sides(skin_id, painter):
			var labels: RefCounted = _labels_at(painter, side)
			for power: int in LABELS:
				var width: float = float(labels.call(&"width", power))
				var limit: float = limit_share * side
				assert_true(width > 0.0, "%s 2^%d at %.1f px has a width" % [skin_id, power, side])
				assert_true(width <= limit, "%s '%s' at %.1f px: width %.1f, limit %.1f" % [skin_id, LABELS[power], side, width, limit])


## 5 and 6 character labels start from the 4 character size and only shrink
## (2.5): never larger than a 4 character label would start.
func test_five_and_six_character_labels_start_from_the_four_character_size() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var painter: RefCounted = _painter(skin_id)
		for side: float in _sides(skin_id, painter):
			var labels: RefCounted = _labels_at(painter, side)
			var start: int = roundi(side * skin.tile_number_scale[3])
			for power: int in [67, 5827]:
				assert_true(int(labels.call(&"font_size", power)) <= start, "%s '%s' at %.1f px is no larger than the 4 character size" % [skin_id, LABELS[power], side])


## The two letter labels the brief names keep their digits at least 15% of
## the side on each skin's smallest tiles (14.1).
func test_two_letter_labels_keep_readable_digits_on_the_smallest_tiles() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var painter: RefCounted = _painter(skin_id)
		for side: float in _smallest(skin_id):
			var labels: RefCounted = _labels_at(painter, side)
			for power: int in [60, 67]:
				var digits: float = float(labels.call(&"cap_height", power))
				assert_true(digits >= TWO_LETTER_DIGITS * side, "%s '%s' at %.1f px: digits %.1f px, at least %.1f" % [skin_id, LABELS[power], side, digits, TWO_LETTER_DIGITS * side])


func test_every_label_up_to_2_to_the_200_fits_the_mini_tile() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var painter: RefCounted = _painter(skin_id)
		var limit: float = SkinCatalog.get_skin(skin_id).num(&"label_fit") * 96.0
		var labels: RefCounted = _labels_at(painter, 96.0)
		for power: int in range(1, 201):
			var width: float = float(labels.call(&"width", power))
			if width > limit:
				fail("%s 2^%d at 96 px: width %.1f, limit %.1f" % [skin_id, power, width, limit])


## Slate sets its label top left, number_inset from the left edge, so its
## label_fit (0.78) is 1 minus twice number_inset: the widest labels keep the
## same 0.11 margin on the right and stay clear of the special frame
## (DESIGN_SYSTEM.md 5.4).
func test_slate_label_right_edge_stays_clear_of_the_special_frame() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	assert_near(skin.num(&"label_fit"), 0.78, 0.0001, "Slate label_fit")
	var painter: RefCounted = _painter(&"slate")
	var reference: float = float(painter.call(&"reference_side"))
	var inset: float = skin.num(&"number_inset")
	var special_inset: float = skin.num(&"special_inset")
	var hairline: float = skin.num(&"hairline")
	# 128M is 2^27, the widest label up to 2^49; then 128aa and 128aaa.
	for power: int in [27, 67, 5827]:
		for side: float in [96.0, 147.9, reference]:
			var unit: float = side / reference
			painter.call(&"set_side", side, unit)
			var labels: RefCounted = painter.get(&"labels") as RefCounted
			var label: String = String(labels.call(&"label", power))
			var right: float = inset * side + float(labels.call(&"width", power))
			var frame_inner: float = (1.0 - special_inset) * side - maxf(1.0, hairline * unit)
			assert_true(right <= 0.89 * side + 0.001, "Slate '%s' at %.1f px: right edge %.1f, at most %.1f" % [label, side, right, 0.89 * side])
			assert_true(right < frame_inner, "Slate '%s' at %.1f px: right edge %.1f clear of the frame at %.1f" % [label, side, right, frame_inner])
