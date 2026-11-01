extends "res://src/design/shared/hud_base.gd"
## Slate HUD (DESIGN_SYSTEM.md 5.7), hud_height tall, left aligned, laid out
## from its own rect only (the content column, QA6-08):
## - "SCORE" in the label role over the score in the display role, from
##   board_margin. The score's digits start space_xs under the caption.
## - On the right: the pause icon (no container, full touch area) at the top,
##   and "BEST" over the Best Score in the body role, the number on the
##   score's baseline, right edge on board_margin.
## - The star counter on the caption line, like a folio line, its right edge
##   on the left edge of the pause button's touch area. From right to left:
##   the count (label role, ink), space_xs, the counter star (star_icon,
##   outline and progress fill in accent, centered on the caption's cap
##   middle), space_xs, "STARS" (label role, ink_muted); while a free booster
##   is held, "1 FREE" (label role, accent) space_m left of "STARS".
## - A hairline under the header, then the context row, hint_height tall, at
##   the bottom:
##     while dragging, "CHAIN n" on the left and the preview slot on the right
##     (a square hint_height tall, the preview tile at preview_scale of the
##     board tile: 112 px at the full spec size);
##     in targeting, a full width badge bar with the hint;
##     otherwise empty, or the clear notice.
## The score fits the width left of the BEST column (2.6).
## Text pairs: ink and ink_muted on bg, accent on bg, badge_ink on badge.
##
## The clear notice takes the context row for its hold time: a full width
## badge bar, the struck mini tiles from space_m, then the copy in the label
## role, and "+n" and the star when stars were earned. It cuts in and out
## with clear_notice. While the context row is busy (a chain being dragged, a
## targeting hint), the notice waits, and its hold time only runs while it
## shows. While the offer hides the HUD (or once it has), the notice is a
## badge bar of the badge height (7.8), sized to its content, centered on the
## board's top edge, and it stays there until it ends (7.5).
##
## The star moment has no flight: as the notice cuts in, the counter shows
## the new count with its star full in paper (ink) for star_earn, then cuts to
## its accent progress look; a conversion draws the free count in paper for
## star_convert, then cuts to accent. While the offer hides the HUD only the
## notice shows.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")
const PauseButton: GDScript = preload("res://src/design/slate/slate_pause_button.gd")
const SlateIcon: GDScript = preload("res://src/design/slate/slate_icon.gd")
## Cap height and comma depth (DESIGN_SYSTEM.md 3.4), defined once.
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")

var _pause: PauseButton = null
var _score: Label = null
var _slot: Control = null
var _star: CounterStar = null
var _score_text: String = ""
var _best_text: String = ""
var _score_caption: String = ""
var _best_caption: String = ""
var _stars_caption: String = ""
var _count_text: String = "0"
var _free_text: String = ""
var _free_color: Color = Color.BLACK
var _context: String = ""
var _highlight: bool = false
var _label_font: Font = null
var _label_size: int = 1
var _body_font: Font = null
var _body_size: int = 1
var _score_baseline: float = 0.0
var _score_caption_origin: Vector2 = Vector2.ZERO
var _best_caption_origin: Vector2 = Vector2.ZERO
var _best_origin: Vector2 = Vector2.ZERO
var _stars_caption_origin: Vector2 = Vector2.ZERO
var _count_origin: Vector2 = Vector2.ZERO
var _free_origin: Vector2 = Vector2.ZERO
var _rule_rect: Rect2 = Rect2()
var _row_rect: Rect2 = Rect2()
var _context_origin: Vector2 = Vector2.ZERO
## The notice's values and stars, to rebuild it in its offer placement.
var _notice_values: PackedInt64Array = PackedInt64Array()
var _notice_stars: int = 0
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
		add_child(_score)
		_slot = Control.new()
		_slot.name = "PreviewSlot"
		_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_slot)
		_star = CounterStar.new()
		_star.name = "CounterStar"
		add_child(_star)
	_pause.setup(skin)
	_score.add_theme_font_override(&"font", skin.font(&"display"))
	_score.add_theme_color_override(&"font_color", skin.color(&"ink"))
	_label_font = skin.font(&"label")
	_label_size = skin.font_size(&"label")
	_body_font = skin.font(&"body")
	_body_size = skin.font_size(&"body")
	_score_caption = skin.cased(&"label", "Score")
	_best_caption = skin.cased(&"label", "Best")
	_stars_caption = UiCopy.stars_caption(skin, &"label")
	_star.setup(SlateIcon.STAR, skin.color(&"accent"), skin.num(&"star_icon"))
	if _score_text.is_empty():
		set_scores(BigNum.zero(), BigNum.zero())
	_shown_count = -1
	_show_stars(_count, _free)


func set_scores(score: BigNum, best_score: BigNum) -> void:
	_score_text = NumberFormat.score(score)
	_best_text = NumberFormat.score(best_score)
	_score.text = _score_text
	_layout()


func set_context(text: String, highlight: bool) -> void:
	_context = _skin.cased(&"label", text) if _skin != null else text
	_highlight = highlight
	_update_notice_wait()
	queue_redraw()


func preview_slot() -> Control:
	return _slot


func score_label() -> Label:
	return _score


func preferred_height() -> float:
	return _skin.num(&"hud_height") if _skin != null else 0.0


## The context text as shown, cased. For tests.
func context_text() -> String:
	return _context


## The counter star. For tests.
func counter_star() -> Control:
	return _star


## The texts the counter shows now: the count and the free count ("" while
## none is held). For tests.
func counter_texts() -> PackedStringArray:
	return PackedStringArray([_count_text, _free_text])


## Where the counter group starts and ends on the caption line, local x
## (from the free count, or "STARS" while none is held). For tests.
func counter_span() -> Vector2:
	var left: float = _free_origin.x if not _free_text.is_empty() else _stars_caption_origin.x
	return Vector2(left, _count_origin.x + _text_width(_count_text))


func _show_notice(values: PackedInt64Array, board: Rect2, stars: int) -> void:
	_notice_values = values
	_notice_stars = stars
	if _notice_offer:
		_build_offer_notice()
	else:
		var height: float = _skin.num(&"hint_height")
		var pad: float = _skin.num(&"space_m")
		var bar: StyleBoxFlat = ThemeKit.box(_skin.color(&"badge"), 0.0)
		_notice.build(_skin, values, &"label", bar, height, 0.0, pad, pad, size.x, stars)
		_place_notice()
	var spec: Dictionary = _skin.motion_spec(&"clear_notice")
	_notice.modulate.a = 0.0
	_notice_tween = Motion.tween_for(_notice, _skin, &"clear_notice")
	_notice_tween.tween_property(_notice, "modulate:a", 1.0, _skin.duration(&"clear_notice"))
	_notice_tween.tween_interval(float(spec.get("hold", 0.0)))
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, float(spec.get("out", 0.0)))
	_notice_tween.tween_callback(_on_notice_done)
	_update_notice_wait()


## The notice while the offer has the HUD's place (7.5): a badge bar of the
## badge height, sized to its content with space_s each side, square
## corners, centered on the board's top edge.
func _build_offer_notice() -> void:
	var height: float = _label_font.get_height(_label_size) + _skin.num(&"space_xs") * 2.0
	var pad: float = _skin.num(&"space_s")
	var bar: StyleBoxFlat = ThemeKit.box(_skin.color(&"badge"), 0.0)
	_notice.build(_skin, _notice_values, &"label", bar, height, 0.0, pad, pad, _board_rect.size.x, _notice_stars)
	_place_global(_notice, Vector2(_board_rect.get_center().x - _notice.size.x * 0.5, _board_rect.position.y - height * 0.5))


func _notice_to_offer() -> void:
	_build_offer_notice()
	_update_notice_wait()


func _notice_dropped() -> void:
	if _slot != null:
		_slot.visible = true


func _show_stars(count_now: int, free_now: int) -> void:
	if _skin == null:
		return
	_star.show_progress(count_now % 3, 1.0, _skin.color(&"accent"))
	_free_color = _skin.color(&"accent")
	_set_counts(count_now, free_now)
	queue_redraw()


func _plan_moment(moment: StarMoment, stars: int) -> void:
	# No flight: every star lands as the notice cuts in, and the flashes run
	# on from there. Nothing plays while the offer hides the HUD.
	var tail: float = 0.0
	if not moment.offer:
		tail = maxf(_skin.duration(&"star_earn"), _skin.duration(&"star_convert"))
	moment.plan(_count, _free, stars, 0.0, 0.0, 0.0, 0.0, 0.0, tail)


func _render_moment(t: float) -> void:
	if _moment.offer:
		return
	_set_counts(_moment.count_at(t), _moment.free_at(t))
	var paper: Color = _skin.color(&"ink")
	var accent: Color = _skin.color(&"accent")
	if t < _skin.duration(&"star_earn"):
		_star.show_progress(3, 1.0, paper)
	else:
		_star.show_progress(_moment.count_at(t) % 3, 1.0, accent)
	var converted: bool = _moment.final_free() > _moment.free_before
	_free_color = paper if converted and t < _skin.duration(&"star_convert") else accent
	queue_redraw()


func _set_counts(count_now: int, free_now: int) -> void:
	if count_now == _shown_count and free_now == _shown_free:
		return
	_shown_count = count_now
	_shown_free = free_now
	_count_text = str(count_now)
	_free_text = UiCopy.free_held(_skin, &"label", free_now) if free_now > 0 else ""
	_layout()


## The notice waits while the context row is busy and runs while it is free.
## In its offer placement it never waits.
func _update_notice_wait() -> void:
	if not _has_notice():
		if _slot != null:
			_slot.visible = true
		return
	var busy: bool = not _context.is_empty() and not _notice_offer
	_notice.visible = not busy
	_slot.visible = busy or _notice_offer
	if _notice_tween != null and _notice_tween.is_valid():
		if busy:
			_notice_tween.pause()
		else:
			_notice_tween.play()


## Puts the notice in the context row, in the space it lives in.
func _place_notice() -> void:
	if not _has_notice() or _notice_offer:
		return
	_notice.size = Vector2(maxf(_row_rect.size.x, _notice.content_width()), _row_rect.size.y)
	_place_global(_notice, _to_global(_row_rect.position))


func _on_pause_tapped() -> void:
	pause_pressed.emit()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized outside the tree gets
	# no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _text_width(text: String) -> float:
	return _label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size).x


func _layout() -> void:
	if _skin == null or _pause == null:
		return
	var margin: float = _skin.num(&"board_margin")
	var touch: float = _skin.num(&"touch_min")
	var icon: float = _skin.num(&"icon_hud")
	var hairline: float = _skin.num(&"hairline")
	var row_height: float = _skin.num(&"hint_height")

	# The icon's box lines up with the right margin; its touch area reaches past it.
	_pause.position = Vector2(size.x - margin - (touch + icon) * 0.5, 0.0)
	_pause.size = Vector2(touch, touch)

	# SCORE caption, then the score's digits space_xs under it.
	var caption_line: float = _label_font.get_height(_label_size)
	_score_caption_origin = Vector2(margin, _label_font.get_ascent(_label_size))
	var display_size: int = _skin.font_size(&"display")
	_score_baseline = caption_line + _skin.num(&"space_xs") + FontMetrics.CAP_HEIGHT * float(display_size)

	# The star counter on the caption line, right to left from the pause
	# button's touch area.
	var gap: float = _skin.num(&"space_xs")
	var star_side: float = _skin.num(&"star_icon")
	var caption_baseline: float = _score_caption_origin.y
	var cap_middle: float = caption_baseline - FontMetrics.CAP_HEIGHT * float(_label_size) * 0.5
	var right: float = _pause.position.x
	_count_origin = Vector2(right - _text_width(_count_text), caption_baseline)
	_star.size = Vector2(star_side, star_side)
	_star.position = Vector2(_count_origin.x - gap - star_side, cap_middle - star_side * 0.5)
	_stars_caption_origin = Vector2(_star.position.x - gap - _text_width(_stars_caption), caption_baseline)
	_free_origin = Vector2(_stars_caption_origin.x - _skin.num(&"space_m") - _text_width(_free_text), caption_baseline)

	# BEST column on the right: the number on the score's baseline, the
	# caption's line right above the number's line.
	var best_width: float = _body_font.get_string_size(_best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _body_size).x
	var best_caption_width: float = _text_width(_best_caption)
	_best_origin = Vector2(size.x - margin - best_width, _score_baseline)
	var number_top: float = _score_baseline - _body_font.get_ascent(_body_size)
	_best_caption_origin = Vector2(size.x - margin - best_caption_width, number_top - _label_font.get_descent(_label_size))

	# The score fits the width left of the BEST column.
	var column: float = maxf(best_width, best_caption_width)
	var slot_width: float = size.x - margin * 2.0 - column - _skin.num(&"space_s")
	var fitted: int = _fit_score_size(_score_text, slot_width)
	_score.add_theme_font_size_override(&"font_size", fitted)
	var display: Font = _skin.font(&"display")
	_score.position = Vector2(margin, _score_baseline - display.get_ascent(fitted))
	_score.size = Vector2(maxf(slot_width, 0.0), display.get_height(fitted))

	# The context row at the bottom, the hairline right above it.
	var row_top: float = _skin.num(&"hud_height") - row_height
	_rule_rect = Rect2(margin, row_top - hairline, size.x - margin * 2.0, hairline)
	_row_rect = Rect2(0.0, row_top, size.x, row_height)
	_slot.position = Vector2(size.x - margin - row_height, row_top)
	_slot.size = Vector2(row_height, row_height)
	var line: float = _label_font.get_height(_label_size)
	_context_origin = Vector2(margin, row_top + (row_height - line) * 0.5 + _label_font.get_ascent(_label_size))
	_place_notice()
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var muted: Color = _skin.color(&"ink_muted")
	var ink: Color = _skin.color(&"ink")
	draw_string(_label_font, _score_caption_origin, _score_caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, muted)
	draw_string(_label_font, _stars_caption_origin, _stars_caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, muted)
	draw_string(_label_font, _count_origin, _count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, ink)
	if not _free_text.is_empty():
		draw_string(_label_font, _free_origin, _free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, _free_color)
	draw_string(_label_font, _best_caption_origin, _best_caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, muted)
	draw_string(_body_font, _best_origin, _best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _body_size, ink)
	draw_rect(_rule_rect, _skin.color(&"line"))
	if _context.is_empty():
		return
	if _highlight:
		draw_rect(_row_rect, _skin.color(&"badge"))
		draw_string(_label_font, _context_origin, _context, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, _skin.color(&"badge_ink"))
	else:
		draw_string(_label_font, _context_origin, _context, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, ink)
