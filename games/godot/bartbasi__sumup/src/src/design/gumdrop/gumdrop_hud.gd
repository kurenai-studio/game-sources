extends "res://src/design/shared/hud_base.gd"
## Gumdrop HUD (DESIGN_SYSTEM.md 4.7), hud_height tall, laid out from its own
## rect only (the content column, QA6-08):
## - the top row, hud_top_row tall: the pause button on the left (a raised
##   squircle face hud_button_face wide at board_margin, touch area
##   touch_min), and a Best pill on the right (surface with a surface_lip lip,
##   pill_height tall, pill_radius corners, sides padded space_s; "Best" in
##   the label role ink_muted, the number in the body role ink);
## - the star pill in the top row, from the pause button's touch area's right
##   edge (space_s right of its face, never inside the touch area): surface
##   with a surface_lip lip like the Best pill, the counter star (star_icon,
##   outline and progress fill in badge), space_xs, the count in the body
##   role ink; then, while a free booster is held, the free pill space_xs to
##   its right: badge with a badge_lip lip, "1 free" in the body role
##   badge_ink, padded space_s;
## - under the top row, the score centered in the display role, auto fitting
##   the width inside board_margin (2.6), its comma tail space_xs above the
##   top of the clear notice. No caption.
## Text pairs: ink on bg, ink_muted and ink on surface, badge on surface (the
## counter star), badge_ink on badge.
##
## The clear notice is a lemon badge pill with a badge_lip lip, notice_height
## tall, centered on the board's top edge, in play and while the offer is
## open alike. It springs in from from_scale, holds, and fades out over out
## with the skin's screen_fade curve.
##
## The star moment: a lemon star on a target_edge_width edge in badge_ink
## leaves the notice's star delay after the notice, at from_scale, and flies
## star_earn on a curve to the counter star,
## growing to full size; there the counter star pops like merge_pop and the
## count goes up. A landing on a multiple of 3 shows the star full, sends a
## full star to the free pill (shrinking to half, star_convert), pops the free
## pill in from star_convert's from_scale (or pops it to peak_scale), then
## fades the fill to empty over empty. While the offer hides the HUD the star
## rises space_l from the notice and fades instead.

const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")
const PauseButton: GDScript = preload("res://src/design/gumdrop/gumdrop_pause_button.gd")
const GumdropIcon: GDScript = preload("res://src/design/gumdrop/gumdrop_icon.gd")
const StarFlyer: GDScript = preload("res://src/design/shared/star_flyer.gd")
## Cap height and comma depth (DESIGN_SYSTEM.md 3.4), defined once.
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")

var _pause: PauseButton = null
var _score: Label = null
var _star: CounterStar = null
var _pill: StyleBoxFlat = null
var _free_style: StyleBoxFlat = null
var _best_caption: String = ""
var _best_text: String = ""
var _score_text: String = ""
var _count_text: String = "0"
var _free_text: String = ""
var _caption_font: Font = null
var _caption_size: int = 1
var _number_font: Font = null
var _number_size: int = 1
## The Best number's size: the body size, or smaller when a long best score
## would reach the star and free pills (4.7).
var _best_size: int = 1
var _pill_rect: Rect2 = Rect2()
var _caption_origin: Vector2 = Vector2.ZERO
var _number_origin: Vector2 = Vector2.ZERO
var _star_pill_rect: Rect2 = Rect2()
var _count_origin: Vector2 = Vector2.ZERO
var _free_rect: Rect2 = Rect2()
var _free_origin: Vector2 = Vector2.ZERO
var _free_scale: float = 1.0
## The running moment's flying stars, by star, and its conversion stars, by
## star (null where a landing does not convert). Both are also in _flyers.
var _star_flyers: Array[StarFlyer] = []
var _convert_flyers: Array[StarFlyer] = []
var _shown_count: int = -1
var _shown_free: int = -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData) -> void:
	_skin = skin
	if _pause == null:
		_pause = PauseButton.new()
		_pause.name = "Pause"
		_pause.tapped.connect(_on_pause_tapped)
		add_child(_pause)
		_score = Label.new()
		_score.name = "Score"
		_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_score)
		_star = CounterStar.new()
		_star.name = "CounterStar"
		add_child(_star)
	_pause.setup(skin)
	_score.add_theme_font_override(&"font", skin.font(&"display"))
	_score.add_theme_color_override(&"font_color", skin.color(&"ink"))
	_pill = Candy.raised(skin.color(&"surface"), skin.color(&"surface_lip"), skin.num(&"pill_radius"), skin.num(&"button_lip"))
	_free_style = Candy.raised(skin.color(&"badge"), skin.color(&"badge_lip"), skin.num(&"pill_radius"), skin.num(&"button_lip"))
	_caption_font = skin.font(&"label")
	_caption_size = skin.font_size(&"label")
	_number_font = skin.font(&"body")
	_number_size = skin.font_size(&"body")
	_best_caption = skin.cased(&"label", "Best")
	_star.setup(GumdropIcon.STAR, skin.color(&"badge"), skin.num(&"star_icon"))
	if _score_text.is_empty():
		set_scores(BigNum.zero(), BigNum.zero())
	_shown_count = -1
	_show_stars(_count, _free)


func set_scores(score: BigNum, best_score: BigNum) -> void:
	_score_text = NumberFormat.score(score)
	_best_text = NumberFormat.score(best_score)
	_score.text = _score_text
	_layout()


## Gumdrop has no context row.
func set_context(_text: String, _highlight: bool) -> void:
	pass


## Gumdrop shows the merge preview on the board.
func preview_slot() -> Control:
	return null


func score_label() -> Label:
	return _score


func preferred_height() -> float:
	return _skin.num(&"hud_height") if _skin != null else 0.0


## The counter star. For tests.
func counter_star() -> Control:
	return _star


## The texts the counter shows now: the count and the free count ("" while
## none is held). For tests.
func counter_texts() -> PackedStringArray:
	return PackedStringArray([_count_text, _free_text])


## The Best number's font size. For tests.
func best_number_size() -> int:
	return _best_size


## The star pill's, the free pill's (empty while none is held) and the Best
## pill's rects, local. For tests.
func pill_rects() -> Array[Rect2]:
	return [_star_pill_rect, _free_rect if not _free_text.is_empty() else Rect2(), _pill_rect]


func _show_notice(values: PackedInt64Array, board: Rect2, stars: int) -> void:
	var height: float = _skin.num(&"notice_height")
	var lip: float = _skin.num(&"button_lip")
	var pad: float = _skin.num(&"space_s")
	_notice.build(_skin, values, &"body", Candy.badge(_skin, height - lip), height, lip, pad, pad, board.size.x, stars)
	_place_global(_notice, Vector2(board.get_center().x - _notice.size.x * 0.5, board.position.y - height * 0.5))
	_notice.pivot_offset = _notice.size * 0.5
	var spec: Dictionary = _skin.motion_spec(&"clear_notice")
	var from_scale: float = maxf(float(spec.get("from_scale", 1.0)), Motion.MIN_SCALE)
	_notice.scale = Vector2(from_scale, from_scale)
	_notice_tween = Motion.tween_for(_notice, _skin, &"clear_notice")
	_notice_tween.tween_property(_notice, "scale", Vector2.ONE, _skin.duration(&"clear_notice"))
	_notice_tween.tween_interval(float(spec.get("hold", 0.0)))
	var fade: Dictionary = _skin.motion_spec(&"screen_fade")
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, float(spec.get("out", 0.0))) \
		.set_trans(int(fade.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType) \
		.set_ease(int(fade.get("ease", Tween.EASE_IN_OUT)) as Tween.EaseType)
	_notice_tween.tween_callback(_on_notice_done)


func _show_stars(count_now: int, free_now: int) -> void:
	if _skin == null:
		return
	_star.scale = Vector2.ONE
	_star.show_progress(count_now % 3, 1.0, _skin.color(&"badge"))
	_free_scale = 1.0
	_set_counts(count_now, free_now)
	queue_redraw()


func _plan_moment(moment: StarMoment, stars: int) -> void:
	var delay: float = StarMoment.extra(_skin, &"star_earn", "delay", 0.0)
	var flight: float = _skin.duration(&"star_earn")
	var stagger: float = StarMoment.extra(_skin, &"star_earn", "stagger", 0.0)
	if moment.offer:
		moment.plan(_count, _free, stars, delay, flight, stagger, 0.0, 0.0, 0.0)
		return
	var travel: float = _skin.duration(&"star_convert")
	var empty: float = StarMoment.extra(_skin, &"star_convert", "empty", 0.0)
	moment.plan(_count, _free, stars, delay, flight, stagger, travel, travel + empty, _skin.duration(&"merge_pop"))


func _begin_moment() -> void:
	_star_flyers.clear()
	_convert_flyers.clear()
	var side: float = _skin.num(&"star_icon")
	var color: Color = _skin.color(&"badge")
	for i: int in _moment.stars:
		var flyer: StarFlyer = StarFlyer.new()
		# On a target_edge_width edge in badge_ink, so it shows on the lemon
		# notice it leaves from (3.6).
		flyer.setup(_skin, color, side, Color.TRANSPARENT, 0.0, GumdropIcon.STAR, _skin.num(&"target_edge_width"), _skin.color(&"badge_ink"))
		_add_flyer(flyer)
		_star_flyers.append(flyer)
		var converting: StarFlyer = null
		if not _moment.offer and _moment.converts[i] == 1:
			converting = StarFlyer.new()
			converting.setup(_skin, color, side, Color.TRANSPARENT, 0.0)
			_add_flyer(converting)
		_convert_flyers.append(converting)


func _render_moment(t: float) -> void:
	var start_point: Vector2 = _notice_star_global()
	var from_scale: float = maxf(StarMoment.extra(_skin, &"star_earn", "from_scale", 1.0), Motion.MIN_SCALE)
	var rise: float = _skin.num(&"space_l")
	for i: int in _star_flyers.size():
		var flyer: StarFlyer = _star_flyers[i]
		var start: float = _moment.starts[i]
		if t < start or t >= _moment.lands[i] or start_point.x < 0.0:
			flyer.visible = false
			continue
		var e: float = StarMoment.eased(_skin, &"star_earn", (t - start) / _moment.flight)
		var grow: float = lerpf(from_scale, 1.0, e)
		if _moment.offer:
			# The counter is hidden with the HUD: rise and fade (7.5).
			flyer.show_at(_to_local_of(flyer, start_point + Vector2(0.0, -rise * e)), grow, 1.0 - e)
		else:
			var point: Vector2 = _flight_point(start_point, _to_global(_star_center()), e)
			flyer.show_at(_to_local_of(flyer, point), grow, 1.0)
	if not _moment.offer:
		_render_counter(t)


func _render_counter(t: float) -> void:
	var count_now: int = _moment.count_at(t)
	_set_counts(count_now, _moment.free_at(t))
	var travel: float = _skin.duration(&"star_convert")
	var empty: float = StarMoment.extra(_skin, &"star_convert", "empty", 0.0)
	var badge: Color = _skin.color(&"badge")
	# The counter star: full while a star turns into a free booster, then its
	# fill fades to empty; otherwise the progress to the next free booster.
	var converting: int = _moment.converting_at(t)
	if converting >= 0:
		var since: float = t - _moment.lands[converting]
		var alpha: float = 1.0
		if since >= travel and empty > 0.0:
			alpha = 1.0 - StarMoment.eased(_skin, &"screen_fade", (since - travel) / empty)
		_star.show_progress(3, alpha, badge)
	else:
		_star.show_progress(count_now % 3, 1.0, badge)
	# The counter star pops like merge_pop on each landing.
	var pop: float = _skin.duration(&"merge_pop")
	var peak: float = StarMoment.extra(_skin, &"merge_pop", "peak_scale", 1.0)
	var landed: int = _moment.last_landing(t)
	var star_scale: float = 1.0
	if landed >= 0 and pop > 0.0 and t - _moment.lands[landed] < pop:
		star_scale = lerpf(peak, 1.0, StarMoment.eased(_skin, &"merge_pop", (t - _moment.lands[landed]) / pop))
	_star.scale = Vector2(star_scale, star_scale)
	# A conversion star travels to the free pill, then the pill pops in (or,
	# already shown, pops to peak_scale with its new number).
	_free_scale = 1.0
	var pill_from: float = maxf(StarMoment.extra(_skin, &"star_convert", "from_scale", 1.0), Motion.MIN_SCALE)
	for i: int in _convert_flyers.size():
		var traveller: StarFlyer = _convert_flyers[i]
		if traveller == null:
			continue
		var land: float = _moment.lands[i]
		if t >= land and t < land + travel:
			var e: float = StarMoment.eased(_skin, &"star_convert", (t - land) / travel)
			var point: Vector2 = _to_global(_star_center()).lerp(_to_global(_free_center()), e)
			traveller.show_at(_to_local_of(traveller, point), lerpf(1.0, 0.5, e), 1.0)
		else:
			traveller.visible = false
		var arrived: float = land + travel
		if pop > 0.0 and t >= arrived and t < arrived + pop:
			var q: float = StarMoment.eased(_skin, &"merge_pop", (t - arrived) / pop)
			var first: bool = _moment.free_at(arrived - travel * 0.5) == 0
			_free_scale = lerpf(pill_from if first else peak, 1.0, q)
	queue_redraw()


## The counter star's center, local.
func _star_center() -> Vector2:
	return _star.position + _star.size * 0.5


## The free pill's face center, local, where it is or will be.
func _free_center() -> Vector2:
	var held: int = maxi(_moment.final_free() if _moment != null else _free, 1)
	var text: String = UiCopy.free_held(_skin, &"body", held)
	var width: float = _skin.num(&"space_s") * 2.0 + _number_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _number_size).x
	var face: float = _star_pill_rect.size.y - _skin.num(&"button_lip")
	return Vector2(_star_pill_rect.end.x + _skin.num(&"space_xs") + width * 0.5, _star_pill_rect.position.y + face * 0.5)


func _set_counts(count_now: int, free_now: int) -> void:
	if count_now == _shown_count and free_now == _shown_free:
		return
	_shown_count = count_now
	_shown_free = free_now
	_count_text = str(count_now)
	_free_text = UiCopy.free_held(_skin, &"body", free_now) if free_now > 0 else ""
	_layout()


## The Best number's size for this much room: the body size when it fits,
## else the largest size that fits, down to the label role size (4.7). Only
## when even that size does not fit (star and free counts in the thousands,
## far past any real run) does it keep shrinking until it fits, the QA6-10
## rule the score follows, so the pills never overlap.
func _fit_best_size(room: float) -> int:
	var floor_size: int = _skin.font_size(&"label")
	var fitted: int = _number_size
	var width: float = _number_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	if width <= room:
		return fitted
	fitted = clampi(floori(float(fitted) * maxf(room, 0.0) / width), floor_size, fitted)
	width = _number_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	while width > room and fitted > floor_size:
		fitted -= 1
		width = _number_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	if width <= room:
		return fitted
	fitted = maxi(floori(float(fitted) * maxf(room, 0.0) / width), 1)
	width = _number_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	while width > room and fitted > 1:
		fitted -= 1
		width = _number_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x
	return fitted


func _on_pause_tapped() -> void:
	pause_pressed.emit()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized outside the tree gets
	# no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _skin == null or _pause == null:
		return
	var margin: float = _skin.num(&"board_margin")
	var face: float = _skin.num(&"hud_button_face")
	var touch: float = _skin.num(&"touch_min")
	var lip: float = _skin.num(&"button_lip")
	# The face's left edge on the margin; the touch area centered across it.
	_pause.position = Vector2(margin + face * 0.5 - touch * 0.5, 0.0)
	_pause.size = Vector2(touch, touch)

	# Every pill's face is centered on the pause face, and every pill's texts
	# share one baseline, the digits centered on the face.
	var pad: float = _skin.num(&"space_s")
	var gap: float = _skin.num(&"space_xs")
	var pill_height: float = _skin.num(&"pill_height")
	var pill_face: float = pill_height - lip
	var pill_top: float = face * 0.5 - pill_face * 0.5
	var baseline: float = pill_top + pill_face * 0.5 + _number_font.get_ascent(_number_size) * 0.5 		- _number_font.get_descent(_number_size) * 0.5

	# Star pill: space_s right of the pause face, but never inside the pause
	# button's touch area (QA6-05): with touch_min 160 it starts at 164.
	var star_side: float = _skin.num(&"star_icon")
	var count_width: float = _number_font.get_string_size(_count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _number_size).x
	var star_x: float = maxf(margin + face + pad, _pause.position.x + touch)
	_star_pill_rect = Rect2(star_x, pill_top, pad + star_side + gap + count_width + pad, pill_height)
	_star.size = Vector2(star_side, star_side)
	_star.position = Vector2(star_x + pad, face * 0.5 - star_side * 0.5)
	_count_origin = Vector2(star_x + pad + star_side + gap, baseline)
	var row_end: float = _star_pill_rect.end.x
	if not _free_text.is_empty():
		var free_width: float = pad * 2.0 + _number_font.get_string_size(_free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _number_size).x
		_free_rect = Rect2(_star_pill_rect.end.x + gap, pill_top, free_width, pill_height)
		_free_origin = Vector2(_free_rect.position.x + pad, baseline)
		row_end = _free_rect.end.x

	# Best pill, right edge on the margin. Its left edge stays at least
	# space_s right of the free pill's end (the star pill's end when none
	# shows): the number shrinks from the body size to fit, never below the
	# label role size (4.7). Up to 13 characters it keeps the body size.
	var caption_width: float = _caption_font.get_string_size(_best_caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _caption_size).x
	var room: float = size.x - margin - (row_end + pad) - pad - caption_width - gap - pad
	_best_size = _fit_best_size(room)
	var number_width: float = _number_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _best_size).x
	var pill_width: float = pad + caption_width + gap + number_width + pad
	_pill_rect = Rect2(size.x - margin - pill_width, pill_top, pill_width, pill_height)
	_caption_origin = Vector2(_pill_rect.position.x + pad, baseline)
	_number_origin = Vector2(_caption_origin.x + caption_width + gap, baseline)

	# Score: centered, fitted to the width inside the margins. Its comma tail
	# ends space_xs above the top of the clear notice, which is centered on the
	# board's top edge space_s under the HUD; it stays put with or without one.
	var width: float = size.x - margin * 2.0
	var fitted: int = _fit_score_size(_score_text, width)
	_score.add_theme_font_size_override(&"font_size", fitted)
	var display: Font = _skin.font(&"display")
	var notice_top: float = _skin.num(&"hud_height") + _skin.num(&"space_s") - _skin.num(&"notice_height") * 0.5
	var score_baseline: float = notice_top - _skin.num(&"space_xs") - FontMetrics.COMMA_DEPTH * float(fitted)
	_score.position = Vector2(margin, score_baseline - display.get_ascent(fitted))
	_score.size = Vector2(maxf(width, 0.0), display.get_height(fitted))
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var ink: Color = _skin.color(&"ink")
	draw_style_box(_pill, _pill_rect)
	draw_string(_caption_font, _caption_origin, _best_caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _caption_size, _skin.color(&"ink_muted"))
	draw_string(_number_font, _number_origin, _best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _best_size, ink)
	draw_style_box(_pill, _star_pill_rect)
	draw_string(_number_font, _count_origin, _count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _number_size, ink)
	if _free_text.is_empty():
		return
	# The free pill, popping around its face's center.
	var lip: float = _skin.num(&"button_lip")
	var center: Vector2 = Vector2(_free_rect.get_center().x, _free_rect.position.y + (_free_rect.size.y - lip) * 0.5)
	draw_set_transform(center, 0.0, Vector2(_free_scale, _free_scale))
	draw_style_box(_free_style, Rect2(_free_rect.position - center, _free_rect.size))
	draw_string(_number_font, _free_origin - center, _free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _number_size, _skin.color(&"badge_ink"))
	draw_set_transform_matrix(Transform2D.IDENTITY)
