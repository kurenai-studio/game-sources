extends "res://src/design/shared/hud_base.gd"
## Nova HUD (DESIGN_SYSTEM.md 6.7), hud_height tall, no containers, laid out
## from its own rect only (the content column, QA6-08):
## - the score centered in the display role (light), auto fitting a slot
##   kept clear of the pause ring on both sides (2.6);
## - under it, the best line: "best 96,520" in the label role, ink_muted,
##   centered; its letters start space_xs below the score's comma tail (the
##   comma reaches below the baseline, so space_xs under the baseline alone
##   would let the two touch);
## - on the best line, the star counter: the counter star (star_icon, outline
##   and progress fill in accent, a soft accent glow behind it while it holds
##   any fill, centered on the line's cap middle), space_xs, the count in the
##   label role ink_muted, the pair ending space_m before the best text; and
##   while a free booster is held, "1 free" in the label role, accent,
##   starting space_m after it. The best text stays exactly centered;
## - the best line sits space_xs above where the clear notice reaches into
##   the HUD (the notice is centered on the board's top edge, space_s below
##   the HUD), so the notice never covers it; the score sits above it;
## - the pause icon in a hud_ring ring at the top right, its edge on
##   board_margin, its touch area touch_min.
## Text pairs: ink, ink_muted and accent on bg_glow.
##
## The clear notice is a badge pill (a full pill, no lip), notice_height tall,
## centered on the board's top edge, its copy in the label role, in play and
## while the offer is open alike. It fades in from from_alpha while rising
## from_offset px (clear_notice), holds, and fades out over out with the
## skin's screen_fade curve.
##
## The star moment: a spark (the filled star in accent, star_icon, on a
## hairline edge in badge_ink, with its glow) rises out of the notice's star
## delay after the notice, fading in
## from from_alpha over the first quarter of star_earn, and glides on the
## curve to the counter star, whose glow blooms to peak_glow and settles over
## merge_pop as the count goes up. A landing on a multiple of 3 blooms the
## star to star_convert's peak_glow, fades "1 free" in while it rises
## from_offset px (or changes its number in place), and fades the star's fill
## to empty over empty. While the offer hides the HUD the spark rises
## space_l from the notice and fades out instead.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")
const PauseButton: GDScript = preload("res://src/design/nova/nova_pause_button.gd")
const NovaIcon: GDScript = preload("res://src/design/nova/nova_icon.gd")
const StarFlyer: GDScript = preload("res://src/design/shared/star_flyer.gd")
## Cap height and comma depth (DESIGN_SYSTEM.md 3.4), defined once.
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
## The counter star's glow radius, a share of star_icon (6.7).
const STAR_GLOW_REACH: float = 0.85

var _pause: PauseButton = null
var _score: Label = null
var _star: CounterStar = null
var _score_text: String = ""
var _best_text: String = ""
var _count_text: String = "0"
var _free_text: String = ""
var _label_font: Font = null
var _label_size: int = 1
var _best_origin: Vector2 = Vector2.ZERO
var _count_origin: Vector2 = Vector2.ZERO
var _free_origin: Vector2 = Vector2.ZERO
## The free count's fade in and rise while it first appears.
var _free_alpha: float = 1.0
var _free_rise: float = 0.0
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
	_label_font = skin.font(&"label")
	_label_size = skin.font_size(&"label")
	_star.setup(NovaIcon.STAR, skin.color(&"accent"), skin.num(&"star_icon"))
	_star.set_glow(Color(skin.color(&"accent"), skin.num(&"icon_glow_alpha")), STAR_GLOW_REACH)
	if _score_text.is_empty():
		set_scores(BigNum.zero(), BigNum.zero())
	_shown_count = -1
	_show_stars(_count, _free)


func set_scores(score: BigNum, best_score: BigNum) -> void:
	_score_text = NumberFormat.score(score)
	# The word takes the label case (lowercase); the number keeps its commas.
	_best_text = _skin.cased(&"label", "Best") + " " + NumberFormat.score(best_score) if _skin != null else ""
	_score.text = _score_text
	_layout()


## Nova has no context row.
func set_context(_text: String, _highlight: bool) -> void:
	pass


## Nova shows the merge preview on the board.
func preview_slot() -> Control:
	return null


func score_label() -> Label:
	return _score


func preferred_height() -> float:
	return _skin.num(&"hud_height") if _skin != null else 0.0


## The best line as shown. For tests.
func best_text() -> String:
	return _best_text


## The counter star. For tests.
func counter_star() -> Control:
	return _star


## The texts the counter shows now: the count and the free count ("" while
## none is held). For tests.
func counter_texts() -> PackedStringArray:
	return PackedStringArray([_count_text, _free_text])


## Where the best line starts and ends, local x: from the counter star to the
## end of the free count (or of the best text while none is held). For tests.
func best_line_span() -> Vector2:
	var right: float = (size.x + _text_width(_best_text)) * 0.5
	if not _free_text.is_empty():
		right = _free_origin.x + _text_width(_free_text)
	return Vector2(_star.position.x, right)


func _show_notice(values: PackedInt64Array, board: Rect2, stars: int) -> void:
	var height: float = _skin.num(&"notice_height")
	var pad: float = _skin.num(&"space_s")
	var pill: StyleBoxFlat = ThemeKit.box(_skin.color(&"badge"), height * 0.5)
	_notice.build(_skin, values, &"label", pill, height, 0.0, pad, pad, board.size.x, stars)
	_place_global(_notice, Vector2(board.get_center().x - _notice.size.x * 0.5, board.position.y - height * 0.5))
	var rest: Vector2 = _notice.position
	var spec: Dictionary = _skin.motion_spec(&"clear_notice")
	var seconds: float = _skin.duration(&"clear_notice")
	_notice.position = rest + Vector2(0.0, float(spec.get("from_offset", 0.0)))
	_notice.modulate.a = float(spec.get("from_alpha", 1.0))
	_notice_tween = Motion.tween_for(_notice, _skin, &"clear_notice")
	_notice_tween.set_parallel(true)
	_notice_tween.tween_property(_notice, "position", rest, seconds)
	_notice_tween.tween_property(_notice, "modulate:a", 1.0, seconds)
	_notice_tween.chain().tween_interval(float(spec.get("hold", 0.0)))
	var fade: Dictionary = _skin.motion_spec(&"screen_fade")
	_notice_tween.chain().tween_property(_notice, "modulate:a", 0.0, float(spec.get("out", 0.0))) \
		.set_trans(int(fade.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType) \
		.set_ease(int(fade.get("ease", Tween.EASE_IN_OUT)) as Tween.EaseType)
	_notice_tween.chain().tween_callback(_on_notice_done)


func _show_stars(count_now: int, free_now: int) -> void:
	if _skin == null:
		return
	_star.show_progress(count_now % 3, 1.0, _skin.color(&"accent"))
	_star.set_glow_scale(1.0)
	_free_alpha = 1.0
	_free_rise = 0.0
	_set_counts(count_now, free_now)
	queue_redraw()


func _plan_moment(moment: StarMoment, stars: int) -> void:
	var delay: float = StarMoment.extra(_skin, &"star_earn", "delay", 0.0)
	var flight: float = _skin.duration(&"star_earn")
	var stagger: float = StarMoment.extra(_skin, &"star_earn", "stagger", 0.0)
	if moment.offer:
		moment.plan(_count, _free, stars, delay, flight, stagger, 0.0, 0.0, 0.0)
		return
	var conversion: float = maxf(_skin.duration(&"star_convert"), StarMoment.extra(_skin, &"star_convert", "empty", 0.0))
	moment.plan(_count, _free, stars, delay, flight, stagger, 0.0, conversion, _skin.duration(&"merge_pop"))


func _begin_moment() -> void:
	var side: float = _skin.num(&"star_icon")
	var accent: Color = _skin.color(&"accent")
	var glow: Color = Color(accent, _skin.num(&"icon_glow_alpha"))
	for i: int in _moment.stars:
		var flyer: StarFlyer = StarFlyer.new()
		# On a hairline edge in badge_ink, between the star and its glow, so
		# it shows on the accent notice it leaves from (3.6).
		flyer.setup(_skin, accent, side, glow, STAR_GLOW_REACH, NovaIcon.STAR, _skin.num(&"hairline"), _skin.color(&"badge_ink"))
		_add_flyer(flyer)


func _render_moment(t: float) -> void:
	var start_point: Vector2 = _notice_star_global()
	var from_alpha: float = StarMoment.extra(_skin, &"star_earn", "from_alpha", 1.0)
	var rise: float = _skin.num(&"space_l")
	for i: int in _flyers.size():
		var flyer: StarFlyer = _flyers[i] as StarFlyer
		var start: float = _moment.starts[i]
		if t < start or t >= _moment.lands[i] or start_point.x < 0.0:
			flyer.visible = false
			continue
		var p: float = (t - start) / _moment.flight
		var e: float = StarMoment.eased(_skin, &"star_earn", p)
		if _moment.offer:
			# The counter is hidden with the HUD: rise and fade from full (7.5).
			flyer.show_at(_to_local_of(flyer, start_point + Vector2(0.0, -rise * e)), 1.0, 1.0 - e)
		else:
			# Fades in over the first quarter of the glide.
			var alpha: float = lerpf(from_alpha, 1.0, clampf(p * 4.0, 0.0, 1.0))
			var point: Vector2 = _flight_point(start_point, _to_global(_star.position + _star.size * 0.5), e)
			flyer.show_at(_to_local_of(flyer, point), 1.0, alpha)
	if not _moment.offer:
		_render_counter(t)


func _render_counter(t: float) -> void:
	var count_now: int = _moment.count_at(t)
	_set_counts(count_now, _moment.free_at(t))
	var accent: Color = _skin.color(&"accent")
	var landed: int = _moment.last_landing(t)
	var bloom: float = 1.0
	_free_alpha = 1.0
	_free_rise = 0.0
	var converting: int = _moment.converting_at(t)
	if converting >= 0:
		# The star blooms to star_convert's peak_glow and its fill fades to
		# empty; "1 free" fades in while it rises from_offset px.
		var since: float = t - _moment.lands[converting]
		var empty: float = StarMoment.extra(_skin, &"star_convert", "empty", 0.0)
		var fill: float = 1.0
		if empty > 0.0:
			fill = 1.0 - StarMoment.eased(_skin, &"screen_fade", since / empty)
		_star.show_progress(3, fill, accent)
		var length: float = _skin.duration(&"star_convert")
		var q: float = StarMoment.eased(_skin, &"star_convert", since / length) if length > 0.0 else 1.0
		bloom = lerpf(StarMoment.extra(_skin, &"star_convert", "peak_glow", 1.0), 1.0, q)
		if _moment.free_before + _converted_before(converting) == 0:
			_free_alpha = q
			_free_rise = StarMoment.extra(_skin, &"star_convert", "from_offset", 0.0) * (1.0 - q)
	else:
		_star.show_progress(count_now % 3, 1.0, accent)
		var pop: float = _skin.duration(&"merge_pop")
		if landed >= 0 and pop > 0.0 and t - _moment.lands[landed] < pop:
			var q: float = StarMoment.eased(_skin, &"merge_pop", (t - _moment.lands[landed]) / pop)
			bloom = lerpf(StarMoment.extra(_skin, &"star_earn", "peak_glow", 1.0), 1.0, q)
	_star.set_glow_scale(bloom)
	queue_redraw()


## Conversions that land before star index.
func _converted_before(index: int) -> int:
	var made: int = 0
	for i: int in index:
		made += _moment.converts[i]
	return made


func _set_counts(count_now: int, free_now: int) -> void:
	if count_now == _shown_count and free_now == _shown_free:
		return
	_shown_count = count_now
	_shown_free = free_now
	_count_text = str(count_now)
	_free_text = UiCopy.free_held(_skin, &"label", free_now) if free_now > 0 else ""
	_layout()


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
	var ring: float = _skin.num(&"hud_ring")
	# The ring's edge lines up with the right margin; its touch area reaches past it.
	_pause.position = Vector2(size.x - margin - (touch + ring) * 0.5, 0.0)
	_pause.size = Vector2(touch, touch)

	# The best line's baseline sits space_xs above the top of the clear notice,
	# which is centered on the board's top edge, space_s under the HUD.
	var gap: float = _skin.num(&"space_xs")
	var notice_top: float = _skin.num(&"hud_height") + _skin.num(&"space_s") - _skin.num(&"notice_height") * 0.5
	var best_baseline: float = minf(notice_top, _skin.num(&"hud_height")) - gap
	_best_origin = Vector2(0.0, best_baseline)
	# The counter on the best line: star and count end space_m before the
	# centered best text, the free count starts space_m after it.
	var best_width: float = _text_width(_best_text)
	var space_m: float = _skin.num(&"space_m")
	var star_side: float = _skin.num(&"star_icon")
	var cap_middle: float = best_baseline - FontMetrics.CAP_HEIGHT * float(_label_size) * 0.5
	_count_origin = Vector2((size.x - best_width) * 0.5 - space_m - _text_width(_count_text), best_baseline)
	_star.size = Vector2(star_side, star_side)
	_star.position = Vector2(_count_origin.x - gap - star_side, cap_middle - star_side * 0.5)
	_free_origin = Vector2((size.x + best_width) * 0.5 + space_m, best_baseline)
	# The score's comma tail ends space_xs above the best line's letters.
	var display_size: int = _skin.font_size(&"display")
	var letters_top: float = best_baseline - FontMetrics.CAP_HEIGHT * float(_label_size)
	var baseline: float = letters_top - gap - FontMetrics.COMMA_DEPTH * float(display_size)

	# The score, centered in a slot clear of the ring on both sides.
	var clear: float = margin + ring + _skin.num(&"space_xs")
	var slot_width: float = size.x - clear * 2.0
	var fitted: int = _fit_score_size(_score_text, slot_width)
	_score.add_theme_font_size_override(&"font_size", fitted)
	var display: Font = _skin.font(&"display")
	_score.position = Vector2(clear, baseline - display.get_ascent(fitted))
	_score.size = Vector2(maxf(slot_width, 0.0), display.get_height(fitted))
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var muted: Color = _skin.color(&"ink_muted")
	draw_string(_label_font, _best_origin, _best_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, _label_size, muted)
	draw_string(_label_font, _count_origin, _count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, muted)
	if not _free_text.is_empty() and _free_alpha > 0.0:
		var accent: Color = _skin.color(&"accent")
		draw_string(_label_font, _free_origin + Vector2(0.0, _free_rise), _free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label_size, Color(accent, accent.a * _free_alpha))
