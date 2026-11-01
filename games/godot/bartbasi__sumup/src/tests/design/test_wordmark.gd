extends "res://tests/base_test.gd"
## The drawn wordmark (DESIGN_SYSTEM.md 7.2, 7.13, 7.9): its splash fit, its
## drawn box, input, and Slate's masthead rule.

## The sum row widths 7.2 measured, and the wordmark sizes it quotes for them.
const ROW_WIDTH: Dictionary[StringName, float] = {&"gumdrop": 948.0, &"slate": 902.0, &"nova": 951.0}
const QUOTED_PX: Dictionary[StringName, int] = {&"gumdrop": 281, &"slate": 266, &"nova": 280}
## Slate's size was measured in Segoe UI on Windows; Roboto lands within a few px.
const PX_SLACK: int = 6

var _made: Array[Node] = []


func after_each() -> void:
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _mark(skin_id: StringName) -> SkinWordmark:
	var mark: SkinWordmark = UiKit.make_wordmark(SkinCatalog.get_skin(skin_id))
	_made.append(mark)
	return mark


func test_factory_returns_the_skin_wordmark() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		assert_true(mark is SkinWordmark, "%s wordmark" % skin_id)
		var path: String = (mark.get_script() as Script).resource_path
		assert_true(path.begins_with("res://src/design/%s/" % skin_id), "%s wordmark comes from its own folder: %s" % [skin_id, path])


func test_starts_at_the_display_size() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		assert_eq(mark._px, SkinCatalog.get_skin(skin_id).font_size(&"display"), "%s About size" % skin_id)


func test_fits_the_quoted_sizes_on_the_splash() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		var width: float = ROW_WIDTH[skin_id]
		mark.fit_width(width)
		assert_true(absi(mark._px - QUOTED_PX[skin_id]) <= PX_SLACK, "%s fits at %d px, 7.2 quotes about %d" % [skin_id, mark._px, QUOTED_PX[skin_id]])
		assert_true(mark.get_minimum_size().x <= width, "%s drawn width %.1f within %.0f" % [skin_id, mark.get_minimum_size().x, width])
		assert_true(mark._drawn_width_at(mark._px + 1) > width, "%s is the largest size that fits" % skin_id)


func test_never_draws_wider_than_its_fit() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		var base_width: float = mark.get_minimum_size().x
		var width: float = base_width
		while width < 1500.0:
			mark.fit_width(width)
			assert_true(mark.get_minimum_size().x <= width, "%s at %.0f draws %.1f" % [skin_id, width, mark.get_minimum_size().x])
			width += 37.0


func test_never_below_the_display_size() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		mark.fit_width(100.0)
		assert_eq(mark._px, SkinCatalog.get_skin(skin_id).font_size(&"display"), "%s keeps the display size" % skin_id)


func test_minimum_size_is_the_drawn_box() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var mark: SkinWordmark = _mark(skin_id)
		mark.fit_width(ROW_WIDTH[skin_id])
		var face: Font = skin.font(&"display")
		var px: int = mark._px
		var advances: float = 0.0
		for part: String in ["Sum", "Up"]:
			advances += face.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
		var extra_w: float = 0.21 * float(px) if skin_id == &"nova" else 0.0
		var lip: float = float(roundi(0.06 * float(px))) if skin_id == &"gumdrop" else 0.0
		var expected: Vector2 = Vector2(ceilf(advances + extra_w), ceilf(face.get_ascent(px) + face.get_descent(px) + lip))
		assert_eq(mark.get_minimum_size(), expected, "%s drawn box" % skin_id)


func test_gumdrop_lip_depth() -> void:
	var mark: SkinWordmark = _mark(&"gumdrop")
	assert_eq(mark._lip_depth(281), 17, "lip at 281")
	assert_eq(mark._lip_depth(120), 7, "lip at the About size")


func test_ignores_input() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		assert_eq(mark.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignores the mouse" % skin_id)
		assert_eq(mark.get_child_count(), 0, "%s has no child that could take input" % skin_id)


func test_masthead_only_in_slate_when_on() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var mark: SkinWordmark = _mark(skin_id)
		mark.fit_width(ROW_WIDTH[skin_id])
		var off_height: float = mark.get_minimum_size().y
		assert_eq(mark._masthead_height(), 0.0, "%s draws no rule by default" % skin_id)
		mark.set_masthead(true)
		var rule: float = skin.num(&"space_s") + skin.num(&"hairline") if skin_id == &"slate" else 0.0
		assert_eq(mark._masthead_height(), rule, "%s rule when on" % skin_id)
		assert_eq(mark.get_minimum_size().y, ceilf(off_height + rule), "%s height with the rule" % skin_id)
		mark.set_masthead(false)
		assert_eq(mark.get_minimum_size().y, off_height, "%s rule gone when off" % skin_id)


func test_redraws_only_on_change() -> void:
	# Built once per size: fitting the same width twice keeps the size.
	for skin_id: StringName in SkinCatalog.IDS:
		var mark: SkinWordmark = _mark(skin_id)
		mark.fit_width(ROW_WIDTH[skin_id])
		var first: Vector2 = mark.get_minimum_size()
		mark.setup(SkinCatalog.get_skin(skin_id))
		assert_eq(mark.get_minimum_size(), first, "%s keeps its fit across setup" % skin_id)
