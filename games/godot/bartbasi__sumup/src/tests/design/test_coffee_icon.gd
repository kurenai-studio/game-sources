extends "res://tests/base_test.gd"
## The 2026-10-17 coffee icon for the Buy me a coffee button in every skin
## (DESIGN_SYSTEM.md 4.7, 5.7, 6.7): it is a listed name, it draws in every
## look at every size without an unknown name report, its normal look is
## ink_muted, and its drawing stays inside the span the design gives.

## Grid span of the recorded points (line points, fill points, disc centers)
## per skin: left, top, right, bottom. Slate's square ends extend each segment
## by half the stroke, so its points reach one unit past the drawn corners.
const SPANS: Dictionary[StringName, Rect2] = {
	&"gumdrop": Rect2(3.0, 4.0, 16.25, 17.5),
	&"slate": Rect2(1.0, 2.5, 20.0, 19.5),
	&"nova": Rect2(5.5, 4.5, 12.75, 16.0),
}
const SIDE: float = 240.0
const SLACK: float = 0.02

var _made: Array[Node] = []


func after_each() -> void:
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _icon(skin: SkinData) -> SkinIcon:
	var icon: SkinIcon = UiKit.make_icon(skin)
	_made.append(icon)
	return icon


func test_coffee_is_a_listed_icon() -> void:
	assert_true(SkinIcon.ICON_NAMES.has(&"coffee"), "coffee is in ICON_NAMES")


func test_every_skin_draws_coffee_in_every_look_and_size() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = _icon(skin)
		icon.set_icon(&"coffee")
		# An unknown name is reported and leaves the icon unchanged.
		assert_eq(icon.get(&"_icon"), &"coffee", "%s takes the coffee name" % skin_id)
		var sides: Array[float] = [24.0, float(skin.font_size(&"body")), 216.0, 512.0]
		for look: int in [SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_DISABLED]:
			icon.set_look(look)
			for side: float in sides:
				icon.size = Vector2(side, side)
				assert_true(int(icon.call(&"drawn_parts")) > 0, "%s coffee look %d at %d px draws" % [skin_id, look, side])


func test_coffee_draws_in_ink_muted_and_follows_the_looks() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = _icon(skin)
		icon.set_icon(&"coffee")
		assert_eq(icon.call(&"ink"), skin.color(&"ink_muted"), "%s normal coffee is ink_muted" % skin_id)
		icon.set_look(SkinIcon.LOOK_ACTIVE)
		assert_eq(icon.call(&"ink"), skin.color(&"ink_dark"), "%s active coffee is ink_dark" % skin_id)
		icon.set_look(SkinIcon.LOOK_DISABLED)
		var disabled: Color = skin.color(&"disabled_ink")
		if skin_id == &"nova":
			disabled.a *= skin.num(&"disabled_icon_alpha")
		assert_true((icon.call(&"ink") as Color).is_equal_approx(disabled), "%s disabled coffee" % skin_id)
		icon.set_look(SkinIcon.LOOK_NORMAL)
		icon.set_color(skin.color(&"ink_muted"))
		assert_eq(icon.call(&"ink"), skin.color(&"ink_muted"), "%s the button's set_color holds" % skin_id)


func test_coffee_stays_inside_its_design_span() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = _icon(skin)
		icon.size = Vector2(SIDE, SIDE)
		icon.set_icon(&"coffee")
		assert_true(int(icon.call(&"drawn_parts")) > 0, "%s coffee draws" % skin_id)
		var fit: float = skin.num(&"icon_fit") if skin_id == &"nova" else 1.0
		var scale: float = SIDE * fit / 24.0
		var origin: Vector2 = Vector2.ONE * SIDE * (1.0 - fit) * 0.5
		var shapes: Array = icon.get(&"_pen").get(&"_shapes")
		var low: Vector2 = Vector2(INF, INF)
		var high: Vector2 = Vector2(-INF, -INF)
		for shape: PackedVector2Array in shapes:
			for p: Vector2 in shape:
				var grid: Vector2 = (p - origin) / scale
				low = low.min(grid)
				high = high.max(grid)
		var span: Rect2 = SPANS[skin_id]
		assert_near(low.x, span.position.x, SLACK, "%s left edge" % skin_id)
		assert_near(low.y, span.position.y, SLACK, "%s top edge" % skin_id)
		assert_near(high.x, span.end.x, SLACK, "%s right edge" % skin_id)
		assert_near(high.y, span.end.y, SLACK, "%s bottom edge" % skin_id)
