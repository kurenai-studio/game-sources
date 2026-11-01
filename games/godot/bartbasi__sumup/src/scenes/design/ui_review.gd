extends Control
## Review sheet for one skin's production interface layer, 1080 by 2400 at
## true scale, built only through UiKit and the base classes, like a screen.
## Four pages per skin:
##   play: the HUD with the clear notice over the board's top edge (Slate: in
##     its context row, plus the context row while dragging and in
##     targeting), then the booster bar normal, targeting, in the out of
##     moves offer (disabled boosters and the Suggested badge), and targeting
##     from the offer (the badge hides while a booster is active).
##   parts: every icon in every look on the fill it sits on, the buttons and
##     icon buttons in every state, the chips, the sound toggle on and off,
##     and a card with every label type, a badge and a divider.
##   stars: the 2026-10-13 samples: the star counter at count 0; count 4
##     with 1 free and the bar all Free with Undo disabled (normal, then
##     targeting); the notice "No more 2s" with "+1" as it shows; and the
##     star, chevron and arrow icons in every look.
##   flight: frames of the star moment at 25%, 50% and 75% of the flight,
##     the star on its badge_ink edge (Slate: the counter's paper flash),
##     then the same moment at 25% and 75% of the rise while the offer hides
##     the HUD (QA6-04): the notice on the board's top edge and the star
##     rising (Slate: only the notice). They draw on a notice layer, as the
##     play screen does.
##   coffee: the 2026-10-17 coffee icon at 216 px in the normal, active and
##     disabled looks on the fill each look sits on, then at the body font
##     size next to "Buy me a coffee" in ink_muted, as the button draws it
##     (DESIGN_SYSTEM.md 7.2), on the page and at twice that size.
##   numbers: the 2026-10-21 unlimited numbers (DESIGN_SYSTEM.md 14): the HUD
##     with Bart's score "9,221,253,119B" as score and best, 12 stars and 1
##     free; the HUD with "9,999,999,999zz" (15 characters) as score and
##     best, 12 stars and 10 free, and the notice "No more 128aa to 512aa";
##     then the booster bar with "256aa" costs (Double disabled).
## Small captions in the skin's CaptionLabel name each sample. Every text,
## icon and button rect is kept clear of Nova's star dust.
##
## Capture with:
##   godot --path . res://tools/capture.tscn -- --scene res://scenes/design/ui_<id>_<page>.tscn --out docs/design/review/prod-ui-<id>-<page>.png

@export var skin_id: StringName = &"gumdrop"
@export var page: String = "play"

const CANVAS: Vector2 = Vector2(1080.0, 2400.0)
## Top of the content, like a status bar inset.
const TOP: float = 72.0
## The mock board: rows shown under the HUD, and the values on it.
const BOARD_ROWS_SHOWN: float = 2.4
## Tile exponents (the tile is 2^k): 4, 16, 4, 2, 8, 2, 1024 and so on.
const BOARD_VALUES: Array[int] = [
	2, 4, 2, 1, 3, 1, 10, 6, 3, 1, 4, 7, 1, 5, 2, 2, 3, 9, 4, 6,
	5, 3, 3, 1, 4, 2, 11, 4, 2, 2, 3, 2, 5, 8, 3, 6, 2, 2, 3, 2,
]
const BOOSTERS: Array[StringName] = [&"hammer", &"swap", &"shuffle", &"double", &"undo"]

var _skin: SkinData = null
var _margin: float = 0.0
var _gap: float = 0.0
var _y: float = TOP
var _texts: Array[Control] = []
var _backdrop: SkinBackdrop = null


func _ready() -> void:
	_skin = SkinCatalog.get_skin(skin_id)
	position = Vector2.ZERO
	size = CANVAS
	theme = UiKit.build_theme(_skin)
	_margin = _skin.num(&"board_margin")
	_gap = _skin.num(&"space_s")
	_backdrop = UiKit.make_backdrop(_skin)
	_place(_backdrop, Vector2.ZERO, CANVAS)
	match page:
		"parts":
			_parts_page()
		"stars":
			_stars_page()
		"flight":
			_flight_page()
		"coffee":
			_coffee_page()
		"numbers":
			_numbers_page()
		_:
			_play_page()
	# Containers lay out on the next frames; then the text rects are final.
	await get_tree().process_frame
	await get_tree().process_frame
	var rects: Array[Rect2] = []
	for holder: Control in _texts:
		rects.append(holder.get_global_rect())
	_backdrop.set_clear_rects(rects)


# Play page

func _play_page() -> void:
	var hud: SkinHud = _hud()
	hud.set_scores(BigNum.from_int(41286), BigNum.from_int(96520))
	if skin_id == &"slate":
		hud.show_clear_notice(PackedInt64Array([1, 2]), Rect2())
		_y += _gap
		_caption("context row while dragging, with the preview tile")
		var dragging: SkinHud = _hud()
		dragging.set_scores(BigNum.from_int(41286), BigNum.from_int(96520))
		dragging.set_context("Chain 6", false)
		_tile_in(dragging.preview_slot(), 8)
		_y += _gap
		_caption("context row in targeting")
		var targeting: SkinHud = _hud()
		targeting.set_scores(BigNum.from_int(41286), BigNum.from_int(96520))
		targeting.set_context("Hammer: Tap a tile to smash it", true)
	else:
		var board: Rect2 = _board_strip(_y + _gap)
		hud.show_clear_notice(PackedInt64Array([1, 2]), board)
	_y += _gap
	_caption("booster bar: normal")
	_bar(_statuses(-1, [], -1), "")
	_caption("targeting: hammer active, undo has no snapshot")
	_bar(_statuses(0, [4], -1), "Tap a tile to smash it")
	_caption("out of moves offer: shuffle suggested")
	if skin_id == &"slate":
		# Slate's badge straddles the strip's top hairline; leave it room.
		_y += _gap
	_bar(_statuses(-1, [0, 1, 3], 2), "")
	_caption("targeting from the offer: no badge")
	_bar(_statuses(0, [1, 3], 2), "Tap a tile to smash it")


func _hud() -> SkinHud:
	var hud: SkinHud = UiKit.make_hud(_skin)
	_place(hud, Vector2(0.0, _y), Vector2(CANVAS.x, hud.preferred_height()))
	_texts.append(hud)
	_y += hud.preferred_height()
	return hud


## The top rows of a real board view for this skin, clipped, at _y. Returns
## the board's full global rect, as a screen would pass it.
func _board_strip(top: float, rows: float = BOARD_ROWS_SHOWN) -> Rect2:
	var width: float = CANVAS.x - _margin * 2.0
	var clip: Control = Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var view: SkinBoardView = SkinCatalog.make_board_view(_skin)
	view.setup(_skin, 5, 8)
	var full: float = view.preferred_height(width)
	var shown: float = full * rows / 8.0
	_place(clip, Vector2(_margin, top), Vector2(width, shown))
	clip.add_child(view)
	view.position = Vector2.ZERO
	view.size = Vector2(width, full)
	view.set_board(PackedInt64Array(BOARD_VALUES))
	_y = top + shown
	return Rect2(_margin, top, width, full)


func _tile_in(slot: Control, value: int) -> void:
	if slot == null:
		return
	var tile: SkinTileView = SkinCatalog.make_tile_view(_skin)
	slot.add_child(tile)
	tile.position = Vector2.ZERO
	tile.size = slot.size
	tile.set_value(value)


## Statuses in bar order: active is the index targeting (-1 none), disabled
## the indexes not usable, suggested the suggested index (-1 none).
func _statuses(active: int, disabled: Array[int], suggested: int) -> Array[BoosterStatus]:
	var costs: Array[int] = [11, 11, 11, 12, 10]
	var statuses: Array[BoosterStatus] = []
	for i: int in BOOSTERS.size():
		var status: BoosterStatus = BoosterStatus.new()
		status.id = BOOSTERS[i]
		status.cost = costs[i]
		status.usable = not disabled.has(i)
		status.reason = BoosterStatus.Usability.USABLE if status.usable else BoosterStatus.Usability.CANNOT_AFFORD
		status.active = i == active
		status.suggested = i == suggested
		statuses.append(status)
	return statuses


func _bar(statuses: Array[BoosterStatus], hint: String) -> void:
	var bar: SkinBoosterBar = UiKit.make_booster_bar(_skin)
	bar.show_boosters(statuses)
	bar.set_hint(hint)
	_place(bar, Vector2(0.0, _y), Vector2(CANVAS.x, bar.preferred_height()))
	_texts.append(bar)
	_y += bar.preferred_height() + _gap


# Stars page

func _stars_page() -> void:
	_caption("star counter: count 0")
	var start: SkinHud = _hud()
	start.set_scores(BigNum.from_int(41286), BigNum.from_int(96520))
	start.set_stars(0, 0)
	_y += _gap
	_caption("count 4 with 1 free; the bar all Free, undo disabled")
	var held: SkinHud = _hud()
	held.set_scores(BigNum.from_int(312480), BigNum.from_int(412900))
	held.set_stars(4, 1)
	_y += _gap
	if skin_id == &"slate":
		_y += _gap
	_bar(_free_statuses(-1), "")
	_caption("Free while targeting: hammer active")
	if skin_id == &"slate":
		_y += _gap
	_bar(_free_statuses(0), "Tap a tile to smash it")
	_caption("the notice with +1 as it shows, from count 0")
	var layer: Control = _notice_layer()
	var hud: SkinHud = _hud()
	hud.set_scores(BigNum.from_int(41286), BigNum.from_int(96520))
	hud.set_stars(0, 0)
	hud.set_notice_layer(layer)
	var board: Rect2 = _board_strip(_y + _gap, 1.4)
	move_child(layer, get_child_count() - 1)
	hud.show_clear_notice(PackedInt64Array([1]), board, 1)
	hud.set_stars(1, 0)
	_hold_moment(hud, 0.0)
	_y += _gap * 2.0
	_caption("star, chevron, arrow: normal, active, disabled")
	_new_icons()


# Flight page

func _flight_page() -> void:
	var layer: Control = _notice_layer()
	# The star leaves at delay and lands delay + star_earn later.
	var delay: float = float(_skin.motion_spec(&"star_earn").get("delay", 0.0))
	var flight: float = _skin.duration(&"star_earn")
	var shares: Array[float] = [0.25, 0.5, 0.75]
	var rises: Array[float] = [0.25, 0.75]
	if skin_id == &"slate":
		shares = [0.5]
		rises = [0.5]
	for share: float in shares:
		if skin_id == &"slate":
			_caption("star moment: the counter's paper flash")
		else:
			_caption("star moment, %d%% of the flight" % roundi(share * 100.0))
		var hud: SkinHud = _hud()
		hud.set_scores(BigNum.from_int(41286), BigNum.from_int(96520))
		hud.set_stars(2, 0)
		hud.set_notice_layer(layer)
		var board: Rect2 = _board_strip(_y + _gap, 1.0)
		move_child(layer, get_child_count() - 1)
		hud.show_clear_notice(PackedInt64Array([1]), board, 1)
		hud.set_stars(3, 1)
		_hold_moment(hud, delay + flight * share)
		_y += _gap * 2.0
	for rise: float in rises:
		if skin_id == &"slate":
			_caption("while the offer hides the HUD (QA6-04)")
		else:
			_caption("while the offer hides the HUD (QA6-04), %d%% of the rise" % roundi(rise * 100.0))
		var hidden: SkinHud = UiKit.make_hud(_skin)
		_place(hidden, Vector2(0.0, _y), Vector2(CANVAS.x, hidden.preferred_height()))
		hidden.set_notice_layer(layer)
		hidden.visible = false
		var offer_board: Rect2 = _board_strip(_y + _skin.num(&"notice_height"), 1.0)
		move_child(layer, get_child_count() - 1)
		hidden.show_clear_notice(PackedInt64Array([1]), offer_board, 1)
		_hold_moment(hidden, delay + flight * rise)
		_y += _gap * 2.0


## A full canvas notice layer above everything placed so far.
func _notice_layer() -> Control:
	var layer: Control = Control.new()
	layer.name = "NoticeLayer"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(layer, Vector2.ZERO, CANVAS)
	return layer


## Holds a HUD's notice at rest and its star moment at t seconds, so the
## capture shows that one frame.
func _hold_moment(hud: SkinHud, t: float) -> void:
	var notice_tween: Tween = hud.get(&"_notice_tween") as Tween
	if notice_tween != null and notice_tween.is_valid():
		notice_tween.custom_step(_skin.duration(&"clear_notice"))
		notice_tween.pause()
	var clock: Tween = hud.call(&"star_moment") as Tween
	if clock != null and clock.is_valid():
		clock.pause()
	hud.call(&"seek_star_moment", t)
	var notice: Control = hud.call(&"clear_notice") as Control
	if notice != null:
		_texts.append(notice)


## Every booster free (D-46), undo disabled with no snapshot, active the
## index targeting (-1 none).
func _free_statuses(active: int) -> Array[BoosterStatus]:
	var statuses: Array[BoosterStatus] = _statuses(active, [4], -1)
	for status: BoosterStatus in statuses:
		status.free = true
	return statuses


# Numbers page

## 2^63 less a little: Bart's real score, shown as 9,221,253,119B.
const BART_SCORE: String = "9221253119629040934"
## Digits of a score that shows as 9,999,999,999zz: 10 shown digits and 581
## dropped groups of three (zz is the 581st suffix).
const ZZ_DIGITS: int = 1753
## 256aa: 2^8 times 1024^6.
const COST_256AA: int = 68


func _numbers_page() -> void:
	_caption("Bart's score as score and best")
	var bart: SkinHud = _hud()
	var bart_score: BigNum = BigNum.parse(BART_SCORE, BART_SCORE.length())
	bart.set_scores(bart_score, bart_score)
	bart.set_stars(12, 1)
	_y += _gap * 2.0
	_caption("15 characters as score and best, 10 free")
	var longest: SkinHud = _hud()
	var nines: BigNum = BigNum.parse("9".repeat(ZZ_DIGITS), ZZ_DIGITS)
	longest.set_scores(nines, nines)
	longest.set_stars(12, 10)
	var values: PackedInt64Array = PackedInt64Array([67, 68, 69])
	if skin_id == &"slate":
		longest.show_clear_notice(values, Rect2())
	else:
		longest.show_clear_notice(values, _board_strip(_y + _gap, 1.0))
	_hold_notice(longest)
	_y += _gap * 2.0
	_caption("booster bar: costs past Q, double disabled")
	if skin_id == &"slate":
		_y += _gap
	var statuses: Array[BoosterStatus] = _statuses(-1, [3], -1)
	for status: BoosterStatus in statuses:
		status.cost = COST_256AA
	_bar(statuses, "")


## Holds a HUD's notice at rest, so the capture shows it.
func _hold_notice(hud: SkinHud) -> void:
	var notice_tween: Tween = hud.get(&"_notice_tween") as Tween
	if notice_tween != null and notice_tween.is_valid():
		notice_tween.custom_step(_skin.duration(&"clear_notice"))
		notice_tween.pause()
	var notice: Control = hud.call(&"clear_notice") as Control
	if notice != null:
		_texts.append(notice)


# Coffee page

const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")


func _coffee_page() -> void:
	_caption("coffee at 216 px: normal, active, disabled")
	var side: float = 216.0
	var pad: float = _skin.num(&"space_xs")
	var cell: float = floorf((CANVAS.x - _margin * 2.0) / 3.0)
	var looks: Array[int] = [SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_DISABLED]
	for l: int in looks.size():
		var box: Rect2 = Rect2(_margin + cell * float(l) + (cell - side) * 0.5 - pad, _y, side + pad * 2.0, side + pad * 2.0)
		var fill: Color = _look_fill(looks[l])
		if fill.a > 0.0:
			var swatch: ColorRect = ColorRect.new()
			swatch.color = fill
			swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_place(swatch, box.position, box.size)
		var icon: SkinIcon = UiKit.make_icon(_skin)
		icon.set_icon(&"coffee")
		icon.set_look(looks[l])
		_place(icon, box.position + Vector2(pad, pad), Vector2(side, side))
		_texts.append(icon)
	_y += side + pad * 2.0 + _gap * 2.0
	_caption("the button's content at the body font size")
	_coffee_row(1.0)
	_y += _gap * 2.0
	_caption("the same, twice as large, to check the fit")
	_coffee_row(2.0)


## The Buy me a coffee button's content (7.2) at zoom times its size: the
## icon in a box the body font size, centered on the label's cap middle, a
## gap of 0.25 of the font size, then the label in MutedLabel.
func _coffee_row(zoom: float) -> void:
	var font: Font = _skin.font(&"body")
	var font_size: int = roundi(float(_skin.font_size(&"body")) * zoom)
	var box: float = float(font_size)
	var label: Label = Label.new()
	label.theme_type_variation = &"MutedLabel"
	label.text = _skin.cased(&"body", "Buy me a coffee")
	label.add_theme_font_size_override(&"font_size", font_size)
	var height: float = font.get_height(font_size)
	var x: float = _margin
	if skin_id != &"slate":
		var width: float = box + box * 0.25 + font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		x = (CANVAS.x - width) * 0.5
	var cap_middle: float = _y + font.get_ascent(font_size) - box * FontMetrics.CAP_HEIGHT * 0.5
	var icon: SkinIcon = UiKit.make_icon(_skin)
	icon.set_icon(&"coffee")
	icon.set_color(_skin.color(&"ink_muted"))
	_place(icon, Vector2(x, cap_middle - box * 0.5), Vector2(box, box))
	_texts.append(icon)
	_place(label, Vector2(x + box * 1.25, _y), Vector2(CANVAS.x - x - box * 1.25, height))
	_texts.append(label)
	_y += height


# Parts page

func _parts_page() -> void:
	_caption("icons: normal, active (on the active fill), disabled")
	_icons(SkinIcon.ICON_NAMES.slice(0, SkinIcon.ICON_NAMES.find(&"star")))
	_caption("buttons: normal, pressed, disabled, focus")
	_buttons(&"PrimaryButton", "Shuffle for 4K")
	_buttons(&"SecondaryButton", "End run")
	_caption("icon buttons (make_icon_button); toggle on, off")
	_icon_buttons_and_toggles()
	_caption("chips: selected, normal, disabled, focus")
	_chips()
	_caption("card with every label type")
	_card()


func _icons(names: Array[StringName]) -> void:
	var count: int = names.size()
	var side: float = _skin.num(&"icon_hud")
	var pad: float = _skin.num(&"space_xs") * 0.5
	var cell: float = floorf((CANVAS.x - _margin * 2.0) / float(count))
	for look: int in [SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_DISABLED]:
		for i: int in count:
			var box: Rect2 = Rect2(_margin + cell * float(i) + (cell - side) * 0.5 - pad, _y, side + pad * 2.0, side + pad * 2.0)
			var fill: Color = _look_fill(look)
			if fill.a > 0.0:
				var swatch: ColorRect = ColorRect.new()
				swatch.color = fill
				swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_place(swatch, box.position, box.size)
			var icon: SkinIcon = UiKit.make_icon(_skin)
			icon.set_icon(names[i])
			icon.set_look(look)
			_place(icon, box.position + Vector2(pad, pad), Vector2(side, side))
			_texts.append(icon)
		_y += side + pad * 2.0 + _skin.num(&"space_xs")
	_y += _gap - _skin.num(&"space_xs")


## The 2026-10-13 icons in one row: each of star, chevron and arrow in the
## normal, active and disabled looks, on the fill each look sits on.
func _new_icons() -> void:
	var names: Array[StringName] = [&"star", &"chevron", &"arrow"]
	var side: float = _skin.num(&"icon_hud")
	var pad: float = _skin.num(&"space_xs") * 0.5
	var cell: float = floorf((CANVAS.x - _margin * 2.0) / 9.0)
	var looks: Array[int] = [SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_DISABLED]
	for n: int in names.size():
		for l: int in looks.size():
			var i: int = n * looks.size() + l
			var box: Rect2 = Rect2(_margin + cell * float(i) + (cell - side) * 0.5 - pad, _y, side + pad * 2.0, side + pad * 2.0)
			var fill: Color = _look_fill(looks[l])
			if fill.a > 0.0:
				var swatch: ColorRect = ColorRect.new()
				swatch.color = fill
				swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_place(swatch, box.position, box.size)
			var icon: SkinIcon = UiKit.make_icon(_skin)
			icon.set_icon(names[n])
			icon.set_look(looks[l])
			_place(icon, box.position + Vector2(pad, pad), Vector2(side, side))
			_texts.append(icon)
	_y += side + pad * 2.0 + _gap


## The fill an icon in a look sits on: the active fill of each skin's
## booster, the disabled face for Gumdrop, the page for the rest.
func _look_fill(look: int) -> Color:
	if look == SkinIcon.LOOK_ACTIVE:
		return _skin.color(&"ink") if skin_id == &"slate" else _skin.color(&"accent")
	if look == SkinIcon.LOOK_DISABLED and skin_id == &"gumdrop":
		return _skin.color(&"disabled_surface")
	if look == SkinIcon.LOOK_NORMAL and skin_id == &"gumdrop":
		return _skin.color(&"surface_raised")
	return Color.TRANSPARENT


func _buttons(variation: StringName, text: String) -> void:
	var width: float = (CANVAS.x - _margin * 2.0 - _gap) / 2.0
	var height: float = _skin.num(&"button_height")
	for state: int in 4:
		var button: Button = Button.new()
		button.theme_type_variation = variation
		button.text = _skin.cased(&"body", text)
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		if skin_id == &"slate":
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = state == 1
		button.button_pressed = state == 1
		button.disabled = state == 2
		var at: Vector2 = Vector2(_margin + (width + _gap) * float(state % 2), _y + (height + _skin.num(&"space_xs")) * (1.0 if state >= 2 else 0.0))
		_place(button, at, Vector2(width, height))
		_texts.append(button)
		if state == 3:
			_focus_over(button, variation)
	_y += height * 2.0 + _skin.num(&"space_xs") + _gap


## Draws a type's focus style over a control, so the focus look shows next
## to the others (only one control can hold focus).
func _focus_over(target: Control, variation: StringName) -> void:
	var overlay: Control = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBox = theme.get_stylebox(&"focus", variation)
	overlay.draw.connect(func() -> void: overlay.draw_style_box(style, Rect2(Vector2.ZERO, overlay.size)))
	_place(overlay, target.position, target.size)


func _icon_buttons_and_toggles() -> void:
	var touch: float = _skin.num(&"touch_min")
	var icons: Array[StringName] = [&"settings", &"close", &"sound_on", &"check"]
	var x: float = _margin
	for state: int in 4:
		var button: BaseButton = UiKit.make_icon_button(_skin, icons[state])
		button.toggle_mode = state == 1
		button.button_pressed = state == 1
		button.disabled = state == 2
		_place(button, Vector2(x, _y), Vector2(touch, touch))
		_texts.append(button)
		if state == 3:
			_focus_over(button, &"IconButton")
		# Touch areas side by side: the drawn faces are smaller, so they stand apart.
		x += touch
	x += _gap
	for on: bool in [true, false]:
		var toggle: SkinToggle = UiKit.make_toggle(_skin)
		toggle.set_on(on)
		_place(toggle, Vector2(x, _y), toggle.custom_minimum_size)
		_texts.append(toggle)
		x += toggle.custom_minimum_size.x + _gap
	_y += touch + _gap


func _chips() -> void:
	var names: PackedStringArray = PackedStringArray(["Gumdrop", "Slate", "Nova", "Locked"])
	var width: float = (CANVAS.x - _margin * 2.0 - _gap * 3.0) / 4.0
	var height: float = _skin.num(&"button_height")
	for i: int in 4:
		var chip: Button = Button.new()
		chip.theme_type_variation = &"ChipButton"
		chip.text = _skin.cased(&"body", names[i])
		chip.focus_mode = Control.FOCUS_NONE
		chip.toggle_mode = true
		chip.button_pressed = i == 0
		chip.disabled = i == 3
		_place(chip, Vector2(_margin + (width + _gap) * float(i), _y), Vector2(width, height))
		_texts.append(chip)
		if i == 2:
			_focus_over(chip, &"ChipButton")
	_y += height + _gap


func _card() -> void:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", roundi(_skin.num(&"space_xs")))
	card.add_child(stack)
	var signal_role: StringName = &"label" if skin_id == &"slate" else &"title"
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override(&"separation", roundi(_gap))
	top_row.add_child(_label(&"SignalLabel", _skin.cased(signal_role, "Run over"), false))
	var badge: PanelContainer = PanelContainer.new()
	badge.theme_type_variation = &"BadgePanel"
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_label(&"BadgeLabel", _skin.cased(&"label", "New best"), false))
	top_row.add_child(badge)
	stack.add_child(top_row)
	stack.add_child(_label(&"DisplayLabel", NumberFormat.score(BigNum.from_int(41286)), false))
	stack.add_child(_label(&"TitleLabel", _skin.cased(&"title", "Settings"), false))
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = &"Hairline"
	stack.add_child(rule)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", roundi(_gap))
	row.add_child(_label(&"BodyLabel", _skin.cased(&"body", "Best score 96,520"), false))
	var caption: Label = _label(&"CaptionLabel", _skin.cased(&"label", "Skin"), false)
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	stack.add_child(row)
	stack.add_child(_label(&"MutedLabel", _skin.cased(&"body", "Pick a booster to keep this run going."), false))
	var x: float = 0.0 if skin_id == &"slate" else _margin
	_place(card, Vector2(x, _y), Vector2(CANVAS.x - x * 2.0, 0.0))
	_texts.append(card)


func _label(variation: StringName, text: String, wrap: bool) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.text = text
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


# Shared

## A small caption naming the next sample, in CaptionLabel (ink_muted on the
## page, a listed pair in every skin).
func _caption(text: String) -> void:
	var label: Label = Label.new()
	label.theme_type_variation = &"CaptionLabel"
	label.text = _skin.cased(&"label", text)
	var height: float = _skin.font(&"label").get_height(_skin.font_size(&"label"))
	_place(label, Vector2(_margin, _y), Vector2(CANVAS.x - _margin * 2.0, height))
	_texts.append(label)
	_y += height + _skin.num(&"space_xs")


func _place(control: Control, at: Vector2, extent: Vector2) -> void:
	add_child(control)
	control.position = at
	control.size = extent
