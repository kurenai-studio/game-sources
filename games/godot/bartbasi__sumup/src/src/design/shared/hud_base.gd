extends SkinHud
## What the three skins' HUDs share (docs/ARCHITECTURE.md section 7):
## - the clear notice's life (D-38, D-45, AT-104) and where it lives: on
##   the play screen's notice layer once one is set (QA6-04, DESIGN_SYSTEM.md
##   7.1), else on the HUD itself, drawn over the board;
## - the star counter's values (D-45, D-46) and the star moment that brings
##   new ones in (3.6), on one clock that a later notice, a hidden HUD or a
##   set_stars the moment does not end on can jump to its end.
## Each skin's HUD extends this, lays out and draws its own parts, and gives
## the hooks below: how its notice looks and moves, how its counter shows,
## and how its star moment plays.
##
## Nothing here takes input: the notice, the counter and the flying stars all
## ignore the mouse.

const ClearNotice: GDScript = preload("res://src/design/shared/clear_notice.gd")
const StarMoment: GDScript = preload("res://src/design/shared/star_moment.gd")
const CounterStar: GDScript = preload("res://src/design/shared/counter_star.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")

## Draw order above the board when the HUD draws the notice and the flying
## stars itself (no layer).
const NOTICE_Z_INDEX: int = 10
const FLIGHT_Z_INDEX: int = 11

var _skin: SkinData = null
var _layer: Control = null
var _notice: ClearNotice = null
var _notice_tween: Tween = null
## Whether the notice took its offer placement (shown while the HUD was
## hidden, or moved there when the HUD hid).
var _notice_offer: bool = false
## The board rect of the last notice, global.
var _board_rect: Rect2 = Rect2()
## The notice's top left corner at rest, global (before it springs or rises
## into place), so the flying stars leave from where its star settles.
var _notice_rest: Vector2 = Vector2.ZERO
## The counter's values once any star moment has ended.
var _count: int = 0
var _free: int = 0
var _moment: StarMoment = null
var _moment_tween: Tween = null
var _moment_time: float = 0.0
## The moment's flying stars, on the notice layer (or the HUD).
var _flyers: Array[Control] = []


func set_notice_layer(layer: Control) -> void:
	if layer == _layer:
		return
	_finish_moment()
	_drop_notice()
	_layer = layer


func set_stars(count: int, free_held: int) -> void:
	if _moment != null and _moment.delivers(count, free_held):
		# The running moment ends on exactly these values.
		return
	_finish_moment()
	_count = count
	_free = free_held
	_show_stars(count, free_held)


func show_clear_notice(values: PackedInt64Array, board_rect: Rect2, stars_earned: int = 0) -> void:
	if _skin == null:
		return
	_finish_moment()
	_drop_notice()
	if values.is_empty():
		return
	_board_rect = board_rect
	_notice_offer = _layer != null and not visible
	_notice = ClearNotice.new()
	_notice.name = "ClearNotice"
	if _layer != null:
		_layer.add_child(_notice)
	else:
		_notice.top_level = true
		_notice.z_index = NOTICE_Z_INDEX
		add_child(_notice)
	_show_notice(values, board_rect, maxi(stars_earned, 0))
	if stars_earned > 0:
		_start_moment(stars_earned)


## The notice showing now (waiting or showing), or null. For tests.
func clear_notice() -> Control:
	return _notice


## The count and the free boosters held as the counter shows them now, the
## star moment included. For tests.
func shown_stars() -> Vector2i:
	if _moment != null and not _moment.offer:
		return Vector2i(_moment.count_at(_moment_time), _moment.free_at(_moment_time))
	return Vector2i(_count, _free)


## The running star moment's clock, or null. For tests and review captures.
func star_moment() -> Tween:
	return _moment_tween


## Shows the star moment as it is t seconds after the notice started. For
## tests and review captures; the moment's clock does this every frame.
func seek_star_moment(t: float) -> void:
	if _moment != null:
		_set_moment_time(clampf(t, 0.0, _moment.total))


## The flying stars of the running moment. For tests.
func flying_stars() -> Array[Control]:
	return _flyers


# Hooks each skin gives.

## Builds _notice for values (with "+n" and the star for stars > 0), places
## it (its offer placement when _notice_offer) and starts _notice_tween, which
## ends by calling _on_notice_done().
func _show_notice(_values: PackedInt64Array, _board: Rect2, _stars: int) -> void:
	pass


## Moves a notice still showing to its offer placement when the HUD hides.
## Gumdrop's and Nova's placement is the same either way.
func _notice_to_offer() -> void:
	pass


## Shows the counter at once with no effect: count stars, free_held free
## boosters (the free count hides at 0).
func _show_stars(_count_now: int, _free_now: int) -> void:
	pass


## Plans moment with the skin's timings for stars earned (moment.offer is
## already set).
func _plan_moment(_moment_plan: StarMoment, _stars: int) -> void:
	pass


## Makes the moment's flying stars (in _flyers, through _add_flyer).
func _begin_moment() -> void:
	pass


## Shows the moment at time t: the flyers, the counter's count, fill, pops
## and the free count.
func _render_moment(_t: float) -> void:
	pass


# Shared helpers for the skins.

## The score's font size for a slot this wide: score_font_size (2.6), which
## stops at display_fit_min. display_fit_min is made for 15 characters
## (9,999,999,999zz, the longest normal play reaches, 14.2). A longer score
## (16 characters, only from a score of 1,754 digits or more) keeps shrinking
## below it until it fits, so it never runs into the parts beside its slot
## (the QA6-10 rule, kept). When the score fits at score_font_size's size,
## that size is kept unchanged.
func _fit_score_size(text: String, slot_width: float) -> int:
	var fitted: int = _skin.font_size(&"display")
	if slot_width <= 0.0:
		return fitted
	fitted = _skin.score_font_size(text, slot_width)
	var display: Font = _skin.font(&"display")
	var width: float = display.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	if width <= slot_width:
		return fitted
	fitted = maxi(floori(float(fitted) * slot_width / width), 1)
	width = display.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	while width > slot_width and fitted > 1:
		fitted -= 1
		width = display.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	return fitted


## Where the notice and the flying stars live.
func _effect_parent() -> Control:
	return _layer if _layer != null else self


## Adds a flying star on the notice layer, or on the HUD over the board.
func _add_flyer(flyer: Control) -> void:
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flyer.visible = false
	if _layer != null:
		_layer.add_child(flyer)
	else:
		flyer.top_level = true
		flyer.z_index = FLIGHT_Z_INDEX
		add_child(flyer)
	_flyers.append(flyer)


## Places control so its top left corner is at the global point.
func _place_global(control: Control, point: Vector2) -> void:
	control.position = _to_local_of(control, point)
	if control == _notice:
		_notice_rest = point


## Whether a notice is showing (it lives on the layer, which may go first).
func _has_notice() -> bool:
	return _notice != null and is_instance_valid(_notice)


## A global point in the space control is positioned in.
func _to_local_of(control: Control, point: Vector2) -> Vector2:
	if control.top_level:
		return point
	var parent: CanvasItem = control.get_parent() as CanvasItem
	if parent == null:
		return point
	return parent.get_global_transform().affine_inverse() * point


## A point of this HUD, global.
func _to_global(local_point: Vector2) -> Vector2:
	return get_global_transform() * local_point


## The notice's star center at rest, global, or (-1, -1) with no star.
func _notice_star_global() -> Vector2:
	if not _has_notice():
		return Vector2(-1.0, -1.0)
	var local: Vector2 = _notice.star_center()
	if local.x < 0.0:
		return local
	return _notice_rest + local


## The point of a quadratic curve at progress e, from start to finish with
## its control point at (finish.x, start.y): out along the notice, then up
## past the score (DESIGN_SYSTEM.md 4.7).
static func _flight_point(start: Vector2, finish: Vector2, e: float) -> Vector2:
	var control: Vector2 = Vector2(finish.x, start.y)
	return start.lerp(control, e).lerp(control.lerp(finish, e), e)


func _on_notice_done() -> void:
	_notice_tween = null
	_drop_notice()


func _drop_notice() -> void:
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice_tween = null
	if _notice != null and is_instance_valid(_notice):
		var parent: Node = _notice.get_parent()
		if parent != null:
			parent.remove_child(_notice)
		_notice.queue_free()
	_notice = null
	_notice_offer = false
	_notice_dropped()


## Called after the notice is gone, for a skin to tidy its layout.
func _notice_dropped() -> void:
	pass


func _start_moment(stars: int) -> void:
	_moment = StarMoment.new()
	_moment.offer = _notice_offer
	_plan_moment(_moment, stars)
	if _moment.offer:
		# The counter is hidden with the HUD: it shows the end values at
		# once, and the HUD brings them back with no effect (7.5).
		_count = _moment.final_count()
		_free = _moment.final_free()
		_show_stars(_count, _free)
	_begin_moment()
	_set_moment_time(0.0)
	if _moment.total <= 0.0:
		_end_moment()
		return
	_moment_tween = Motion.tween_for(self, _skin, &"star_earn")
	# The clock runs evenly; every part eases itself on its own curve.
	_moment_tween.set_trans(Tween.TRANS_LINEAR)
	_moment_tween.tween_method(_set_moment_time, 0.0, _moment.total, _moment.total)
	_moment_tween.tween_callback(_end_moment)


func _set_moment_time(t: float) -> void:
	if _moment == null:
		return
	for flyer: Control in _flyers:
		if not is_instance_valid(flyer):
			# The layer went first: nothing left to draw on.
			_end_moment()
			return
	_moment_time = t
	_render_moment(t)


## Jumps a running moment to its end state and ends it.
func _finish_moment() -> void:
	if _moment == null:
		return
	if _moment_tween != null and _moment_tween.is_valid():
		_moment_tween.kill()
	_moment_tween = null
	_set_moment_time(_moment.total)
	_end_moment()


func _end_moment() -> void:
	if _moment == null:
		return
	_count = _moment.final_count()
	_free = _moment.final_free()
	_moment = null
	_moment_tween = null
	for flyer: Control in _flyers:
		if is_instance_valid(flyer):
			var parent: Node = flyer.get_parent()
			if parent != null:
				parent.remove_child(flyer)
			flyer.queue_free()
	_flyers.clear()
	_show_stars(_count, _free)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not visible:
				# The offer took the HUD's place: the counter jumps to its
				# end values, and a notice still showing takes its offer
				# placement on the layer, so it stays in view (QA6-04).
				if _moment != null and not _moment.offer:
					_finish_moment()
				if _has_notice() and _layer != null and not _notice_offer:
					_notice_offer = true
					_notice_to_offer()
		NOTIFICATION_PREDELETE:
			# The notice and the flyers on the layer are not the HUD's
			# children: take them with it.
			_finish_moment()
			_drop_notice()
