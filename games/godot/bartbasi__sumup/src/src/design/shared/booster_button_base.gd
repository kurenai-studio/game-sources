extends "res://src/design/shared/press_button.gd"
## What the three skins' booster buttons share: the booster a button shows
## and how a BoosterStatus maps to its look, cost label and Suggested badge,
## and the Free cost (D-46): while a free booster is held, the cost line shows
## the filled star (its box the label size, centered on the line's cap
## middle), a gap of 0.25 of the label size, then "Free" in the label role,
## disabled boosters included (DESIGN_SYSTEM.md 4.7, 5.7, 6.7). Each skin's
## button extends this, places the group and draws the looks.

## The booster this button shows.
var booster_id: StringName = &""
## SkinIcon.LOOK_NORMAL, LOOK_ACTIVE (targeting) or LOOK_DISABLED (not usable).
var look: int = SkinIcon.LOOK_NORMAL
## The cost as a tile label of the cost exponent (D-32): 2K, never 2,048;
## 256aa past Q. Never cased.
var cost_text: String = ""
## Marked as the suggested rescue (D-42).
var suggested: bool = false
## A free booster is held: the cost line reads Free (D-46).
var free: bool = false
## "Free", cased by the label role.
var free_text: String = ""

const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")
## Cap height (DESIGN_SYSTEM.md 3.4), defined once.
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
## The gap between the star and "Free", a share of the label size (7.9).
const FREE_STAR_GAP: float = 0.25

## The star before "Free", made on first use, hidden while not free.
var _free_star: SkinIcon = null
## Where "Free" starts, on the cost line's baseline.
var _free_origin: Vector2 = Vector2.ZERO


func setup(skin: SkinData) -> void:
	_skin = skin
	free_text = UiCopy.free_cost(skin, &"label")
	if _free_star != null:
		_free_star.setup(skin)
	_on_setup()
	_apply(look)


## Shows one status. The look follows the status: active while targeting,
## else disabled when not usable, else normal.
func show_status(status: BoosterStatus) -> void:
	var was: int = look
	var new_id: bool = status.id != booster_id
	booster_id = status.id
	cost_text = NumberFormat.tile_label(status.cost)
	suggested = status.suggested
	free = status.free
	if status.active:
		look = SkinIcon.LOOK_ACTIVE
	elif not status.usable:
		look = SkinIcon.LOOK_DISABLED
	else:
		look = SkinIcon.LOOK_NORMAL
	enabled = look != SkinIcon.LOOK_DISABLED
	if not enabled:
		drop_hold()
	if new_id:
		_on_booster_changed()
	_apply(was)
	_layout()


## The width of the Free group: the star, the gap and "Free".
func _free_width() -> float:
	var size_px: float = float(_skin.font_size(&"label"))
	var word: float = _skin.font(&"label").get_string_size(free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _skin.font_size(&"label")).x
	return size_px * (1.0 + FREE_STAR_GAP) + word


## Places the Free group with its left edge at left on the cost line's
## baseline, and shows its star in color only while free.
func _place_free(left: float, baseline: float, color: Color) -> void:
	if not free and _free_star == null:
		return
	if _free_star == null:
		_free_star = UiKit.make_icon(_skin)
		_free_star.name = "FreeStar"
		add_child(_free_star)
		_free_star.set_icon(&"star")
	_free_star.visible = free
	var size_px: float = float(_skin.font_size(&"label"))
	var cap_middle: float = baseline - FontMetrics.CAP_HEIGHT * size_px * 0.5
	_free_star.size = Vector2(size_px, size_px)
	_free_star.position = Vector2(left, cap_middle - size_px * 0.5)
	_free_star.set_color(color)
	_free_origin = Vector2(left + size_px * (1.0 + FREE_STAR_GAP), baseline)


## The star before "Free", or null. For tests.
func free_star() -> SkinIcon:
	return _free_star


## Called by setup(), for the skin to read its tokens and build its parts.
func _on_setup() -> void:
	pass


## Called when the button starts showing another booster.
func _on_booster_changed() -> void:
	pass


## Applies the current look, cost and suggested flag. was is the previous
## look, so a pulse starts only when a button becomes active.
func _apply(_was: int) -> void:
	queue_redraw()


## Places the parts in the current size.
func _layout() -> void:
	queue_redraw()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized outside the tree gets
	# no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()
