extends Control
## One mockup page of the 2026-10-13 additions, 1080 by 2400, in one skin
## (tools/ only). tools/additions/additions_capture.tscn renders them all to
## docs/design/additions/. Pages:
##   menu        the main menu with the fitted two tone wordmark and How to play
##   play_star   the star moment: the clear notice with its star, the star on
##               its way to the counter (Slate: the counter's flash)
##   play_free   4 stars and 1 free booster held: the counter, the free count
##               and Free on every booster
##   pause       Pause with How to play
##   settings    Settings with the About row
##   howto       How to play, top
##   howto_end   How to play, scrolled to the end
##   about       About
##   license     a license text view (Godot's own text, which needs no file)
## The real Theme, HUD, board, bar, panels, tile views and board views are
## used; the new pieces (stars, Free, sections, rows) are drawn by
## tools/additions/. The safe area is the capture tool's phone: 120 px on
## top, 66 px at the bottom.

const Spec: GDScript = preload("res://tools/additions/additions_spec.gd")
const Kit: GDScript = preload("res://tools/additions/additions_kit.gd")
const AddedIcon: GDScript = preload("res://tools/additions/additions_icon.gd")
const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")
const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")
const ClearNotice: GDScript = preload("res://src/design/shared/clear_notice.gd")
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")

const GAME_SCENE: PackedScene = preload("res://scenes/ui/game_screen.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/pause_panel.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_panel.tscn")

const SAFE_INSETS: Vector2 = Vector2(120.0, 66.0)

## The review scenes' mid game board (scenes/ui/review/ui_review.gd).
const MID_GAME: Array[int] = [
	2, 16, 4, 2, 8,
	4, 1024, 64, 8, 2,
	16, 128, 2, 32, 4,
	2, 4, 512, 16, 64,
	32, 8, 8, 2, 16,
	4, 2048, 16, 4, 2,
	8, 2, 32, 256, 8,
	64, 4, 2, 8, 4,
]
## Later in a run: the highest tile is 16K, so 4 stars and 1 free booster.
const LATE_GAME: Array[int] = [
	32, 256, 64, 32, 128,
	64, 8192, 1024, 128, 32,
	256, 2048, 32, 512, 64,
	32, 64, 4096, 256, 1024,
	512, 128, 128, 32, 256,
	64, 16384, 256, 64, 32,
	128, 32, 512, 4096, 128,
	1024, 64, 32, 128, 64,
]

## The How to play text, GDD section 21.2 (HP1 to HP7).
const HOW_TO_PLAY: Array[Dictionary] = [
	{"title": "Make a chain", "text": "Slide across touching tiles, diagonals too, starting with two equal ones. Each next tile must match the last one or double it.", "row": [2, 2, 4], "result": 8},
	{"title": "What it makes", "text": "Lift to merge, or lift on one tile to cancel. The tiles add up and round down to a tile number, so 6 becomes 4.", "row": [2, 2, 2], "result": 4},
	{"title": "After a merge", "text": "The merged tile lands where your chain ended, tiles above fall and new ones drop in. While you drag, highlighted tiles can join next.", "row": [], "result": 0},
	{"title": "Score", "text": "A chain scores the sum of its tiles. Boosters cost points, your score never drops below zero, and best score and best tile are saved.", "row": [], "result": 0},
	{"title": "Move up, earn stars", "text": "Each new highest tile from 2K up removes the smallest number and earns a star. Every 3 stars make your next booster free.", "row": [1024, 1024], "result": 2048},
	{"title": "Boosters", "text": "Hammer smashes a tile, Swap swaps two, Shuffle mixes the board, Double doubles one, Undo takes back your last chain. Prices grow as you go.", "row": [], "result": 0},
	{"title": "Out of moves", "text": "When no two touching tiles match, you can pick a booster to keep going. If you can't, or you tap End run, the run ends.", "row": [], "result": 0},
]

@export var skin_id: StringName = &"gumdrop"
@export var page: String = "menu"

var _skin: SkinData = null
var _session: GameSession = null
var _game: GameScreen = null
var _scroll: ScrollContainer = null
var _frames: int = 0
## Drawn once the play screen has its layout.
var _overlay: Callable = Callable()
## Measurements printed by the capture driver.
var report: PackedStringArray = PackedStringArray()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SafeArea.simulated_insets = SAFE_INSETS
	_skin = SkinCatalog.get_skin(skin_id)
	Spec.preview_on(_skin)
	var built: Theme = UiKit.build_theme(_skin)
	Kit.extend_theme(built, _skin)
	theme = built
	match page:
		"menu":
			_menu()
		"play_star":
			_play(MID_GAME, 41286)
			_overlay = _overlay_star_moment
		"play_free":
			_play(LATE_GAME, 312480)
			_overlay = _overlay_free
		"pause":
			_play(MID_GAME, 41286)
			var pause: PausePanel = PAUSE_SCENE.instantiate() as PausePanel
			add_child(pause)
			pause.setup(_skin)
			var content: VBoxContainer = pause.get("_content")
			var how: Button = UiParts.button(_skin, &"SecondaryButton", "How to play")
			content.add_child(how)
			content.move_child(how, 3)
		"settings":
			_play(MID_GAME, 41286)
			var settings: Settings = Settings.new()
			settings.set_skin_id(_skin.id)
			var panel: SettingsPanel = SETTINGS_SCENE.instantiate() as SettingsPanel
			add_child(panel)
			panel.setup(_skin, settings)
			var column: VBoxContainer = panel.get("_content")
			var version: Control = column.get_child(column.get_child_count() - 1)
			column.add_child(UiParts.divider())
			column.add_child(Kit.open_row(_skin, "About", ""))
			column.move_child(version, column.get_child_count() - 1)
		"howto", "howto_end":
			_how_to_play()
		"about":
			_about()
		"license":
			_license()
		"icons":
			_icons()
		_:
			push_error("additions_page: unknown page '%s'" % page)
	get_tree().process_frame.connect(_after_layout)


func _exit_tree() -> void:
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)


# --- Main menu (7.2) -------------------------------------------------------

func _menu() -> void:
	var backdrop: SkinBackdrop = UiKit.make_backdrop(_skin)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var safe: Rect2 = _safe()
	var margin: float = _skin.num(&"board_margin")
	var start: bool = UiParts.align_start(_skin)
	var root: VBoxContainer = UiParts.vbox(0.0)
	root.position = safe.position
	root.size = safe.size
	add_child(root)
	var top: MarginContainer = _margins(root, UiParts.icon_button_inset(_skin), UiParts.icon_button_inset(_skin))
	var top_row: HBoxContainer = UiParts.hbox(0.0)
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(top_row)
	top_row.add_child(UiParts.icon_button(_skin, &"settings"))
	root.add_child(_ratio_spacer(2.0))
	var brand_box: MarginContainer = _margins(root, margin, margin)
	var brand: VBoxContainer = UiParts.vbox(_skin.num(&"space_m"))
	brand_box.add_child(brand)
	var row_width: float = Kit.menu_row_width(_skin)
	var word_px: int = Kit.fitted_wordmark_size(_skin, row_width)
	report.append("wordmark %d px (display role is %d), tile row %d px wide" % [word_px, _skin.font_size(&"display"), roundi(row_width)])
	brand.add_child(Kit.wordmark(_skin, word_px, start))
	var tiles: HBoxContainer = UiParts.hbox(_skin.num(&"space_s"))
	tiles.alignment = BoxContainer.ALIGNMENT_BEGIN if start else BoxContainer.ALIGNMENT_CENTER
	brand.add_child(tiles)
	for value: int in [2, 4, 8, 16]:
		tiles.add_child(UiParts.tile(_skin, Kit.exponent(value), 160.0))
	root.add_child(_ratio_spacer(3.0))
	var records_box: MarginContainer = _margins(root, margin, margin)
	var records: VBoxContainer = UiParts.vbox(0.0)
	records_box.add_child(records)
	records.add_child(UiParts.record_row(_skin, "Best score", UiParts.label(_skin, &"BodyLabel", "96,520")))
	records.add_child(UiParts.divider())
	records.add_child(UiParts.record_row(_skin, "Best tile", UiParts.tile(_skin, Kit.exponent(8192), 72.0)))
	root.add_child(Kit.spacer(_skin.num(&"space_l")))
	var buttons_box: MarginContainer = _margins(root, margin, margin)
	var buttons: VBoxContainer = UiParts.vbox(_skin.num(&"space_s"))
	buttons_box.add_child(buttons)
	buttons.add_child(UiParts.button(_skin, &"PrimaryButton", "New game"))
	buttons.add_child(UiParts.button(_skin, &"SecondaryButton", "How to play"))
	brand.set_meta(&"measure", true)
	set_meta(&"brand", brand)
	backdrop.set_clear_rects([])
	set_meta(&"backdrop", backdrop)
	set_meta(&"clear", [brand, records, buttons, top_row])


# --- Play screen ------------------------------------------------------------

func _play(values: Array[int], score: int) -> void:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(96520 if score < 96520 else 412900)
	records.best_tile = Kit.exponent(16384)
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(1)
	_session = GameSession.new(null, rng, records)
	var audio: AudioService = AudioService.new()
	add_child(audio)
	_game = GAME_SCENE.instantiate() as GameScreen
	add_child(_game)
	_game.setup(_session, Settings.new(), audio, _skin)
	var cells: PackedInt64Array = PackedInt64Array()
	for value: int in values:
		cells.append(Kit.exponent(value))
	_session.resume(RunState.create(cells, BigNum.from_int(score)))
	if _session.is_waiting_for_view():
		_session.move_shown()


## The star moment: count 0 going to 1, a clear notice naming the 2s with
## "+1" and a star, and (Gumdrop, Nova) the star on its way to the counter.
func _overlay_star_moment() -> void:
	var hud: SkinHud = _game.hud()
	var overlay: Control = _overlay_over(hud)
	var notice: Control = _star_notice(PackedInt64Array([Kit.exponent(2)]), 1)
	if _skin.id == &"slate":
		# Slate flashes the counter in paper as the notice cuts in.
		_draw_counter(overlay, 1, 0, true)
		return
	var counter: Dictionary = _draw_counter(overlay, 0, 0, false)
	# The star part way: a quadratic curve from the notice's star to the
	# counter's star, its control point at (end x, start y), so it slides out
	# along the notice, then swings up past the left of the score.
	var start: Vector2 = notice.get_meta(&"star_center")
	var finish: Vector2 = counter["star_center"]
	var control: Vector2 = Vector2(finish.x, start.y)
	var side: float = Spec.num(_skin, &"star_icon")
	var color: Color = _reward_color()
	for i: int in 4:
		var t: float = 0.22 + 0.14 * float(i)
		var at: Vector2 = start.lerp(control, t).lerp(control.lerp(finish, t), t)
		var star: AddedIcon = AddedIcon.new()
		var alpha: float = 0.18 + 0.27 * float(i)
		var scale_here: float = 0.6 + 0.13 * float(i)
		star.setup(_skin, &"star", Color(color, alpha if i < 3 else 1.0), side * scale_here)
		star.fill_share = 1.0
		if _skin.id == &"nova" and i == 3:
			star.glow_color = Color(_skin.color(&"accent"), _skin.num(&"icon_glow_alpha"))
			star.glow_reach = 1.1
		star.position = at - star.size * 0.5
		star.top_level = true
		star.z_index = 20
		add_child(star)


## 4 stars, 1 free booster: the counter, the free count and Free on the bar.
func _overlay_free() -> void:
	var hud: SkinHud = _game.hud()
	var overlay: Control = _overlay_over(hud)
	_draw_counter(overlay, 4, 1, false)
	var bar: SkinBoosterBar = _game.booster_bar()
	var buttons: Array = bar.call(&"buttons")
	for button: Control in buttons:
		_free_cost(button)


func _overlay_over(target: Control) -> Control:
	var overlay: Control = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.top_level = true
	overlay.z_index = 15
	overlay.position = target.get_global_rect().position
	overlay.size = target.get_global_rect().size
	add_child(overlay)
	return overlay


func _reward_color() -> Color:
	return _skin.color(&"badge") if _skin.id == &"gumdrop" else _skin.color(&"accent")


## Draws the star counter in the HUD space of overlay. flash draws Slate's
## star in paper. Returns the star's global center.
func _draw_counter(overlay: Control, count: int, free_held: int, flash: bool) -> Dictionary:
	var side: float = Spec.num(_skin, &"star_icon")
	var share: float = float(count % 3) / 3.0
	var star: AddedIcon = AddedIcon.new()
	star.setup(_skin, &"star", _reward_color(), side)
	star.fill_share = share
	var out: Dictionary = {}
	match _skin.id:
		&"gumdrop":
			var face: float = _skin.num(&"hud_button_face")
			var pill_height: float = _skin.num(&"pill_height")
			var lip: float = _skin.num(&"button_lip")
			var pad: float = _skin.num(&"space_s")
			var gap: float = _skin.num(&"space_xs")
			var body: Font = _skin.font(&"body")
			var body_size: int = _skin.font_size(&"body")
			var count_text: String = str(count)
			var count_width: float = body.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, body_size).x
			# space_s right of the pause face, but never inside its touch area.
			var margin: float = _skin.num(&"board_margin")
			var touch_right: float = margin + face * 0.5 + _skin.num(&"touch_min") * 0.5
			var pill_x: float = maxf(margin + face + _skin.num(&"space_s"), touch_right)
			var pill_top: float = face * 0.5 - (pill_height - lip) * 0.5
			var pill_width: float = pad + side + gap + count_width + pad
			var pill: Panel = _box(Candy.raised(_skin.color(&"surface"), _skin.color(&"surface_lip"), _skin.num(&"pill_radius"), lip), Rect2(pill_x, pill_top, pill_width, pill_height))
			overlay.add_child(pill)
			star.position = Vector2(pill_x + pad, face * 0.5 - side * 0.5)
			overlay.add_child(star)
			var baseline: float = pill_top + (pill_height - lip) * 0.5 + body.get_ascent(body_size) * 0.5 - body.get_descent(body_size) * 0.5
			overlay.add_child(_text(count_text, body, body_size, _skin.color(&"ink"), Vector2(pill_x + pad + side + gap, baseline)))
			var right: float = pill_x + pill_width
			if free_held > 0:
				var free_text: String = "%d free" % free_held
				var free_width: float = body.get_string_size(free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, body_size).x
				var free_x: float = right + gap
				var free_pill: Panel = _box(Candy.raised(_skin.color(&"badge"), _skin.color(&"badge_lip"), _skin.num(&"pill_radius"), lip), Rect2(free_x, pill_top, pad + free_width + pad, pill_height))
				overlay.add_child(free_pill)
				overlay.add_child(_text(free_text, body, body_size, _skin.color(&"badge_ink"), Vector2(free_x + pad, baseline)))
				right = free_x + pad + free_width + pad
			report.append("counter: star pill from %d to %d px, free pill to %d px (Best pill starts at about %d px)" % [roundi(pill_x), roundi(pill_x + pill_width), roundi(right), roundi(overlay.size.x - _skin.num(&"board_margin") - 280.0)])
		&"slate":
			var label: Font = _skin.font(&"label")
			var label_size: int = _skin.font_size(&"label")
			var gap: float = _skin.num(&"space_xs")
			var baseline: float = label.get_ascent(label_size)
			var touch: float = _skin.num(&"touch_min")
			var icon: float = _skin.num(&"icon_hud")
			var right: float = overlay.size.x - _skin.num(&"board_margin") - (touch + icon) * 0.5
			var count_text: String = str(count)
			var caption: String = _skin.cased(&"label", "Stars")
			var count_width: float = label.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
			var caption_width: float = label.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
			var count_x: float = right - count_width
			var star_x: float = count_x - gap - side
			var caption_x: float = star_x - gap - caption_width
			var cap_middle: float = baseline - FontMetrics.CAP_HEIGHT * float(label_size) * 0.5
			overlay.add_child(_text(caption, label, label_size, _skin.color(&"ink_muted"), Vector2(caption_x, baseline)))
			if flash:
				star.color = _skin.color(&"ink")
				star.fill_share = 1.0
			star.position = Vector2(star_x, cap_middle - side * 0.5)
			overlay.add_child(star)
			overlay.add_child(_text(count_text, label, label_size, _skin.color(&"ink"), Vector2(count_x, baseline)))
			var left: float = caption_x
			if free_held > 0:
				var free_text: String = _skin.cased(&"label", "%d free" % free_held)
				var free_width: float = label.get_string_size(free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
				left = caption_x - _skin.num(&"space_m") - free_width
				overlay.add_child(_text(free_text, label, label_size, _skin.color(&"accent"), Vector2(left, baseline)))
			report.append("counter: caption line from %d to %d px; star %d to %d px tall on a %d px line" % [roundi(left), roundi(right), roundi(cap_middle - side * 0.5), roundi(cap_middle + side * 0.5), roundi(label.get_height(label_size))])
		_:
			# On the best line: the best text stays centered; the star and the
			# count end space_m left of it, the free count starts space_m right
			# of it.
			var label: Font = _skin.font(&"label")
			var label_size: int = _skin.font_size(&"label")
			var gap: float = _skin.num(&"space_xs")
			var notice_top: float = _skin.num(&"hud_height") + _skin.num(&"space_s") - _skin.num(&"notice_height") * 0.5
			var baseline: float = minf(notice_top, _skin.num(&"hud_height")) - gap
			var cap: float = FontMetrics.CAP_HEIGHT * float(label_size)
			var hud: SkinHud = _game.hud()
			var best_text: String = String(hud.call(&"best_text")) if hud.has_method(&"best_text") else "best 96,520"
			var best_width: float = label.get_string_size(best_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
			var center: float = overlay.size.x * 0.5
			var count_text: String = str(count)
			var count_width: float = label.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
			var count_x: float = center - best_width * 0.5 - _skin.num(&"space_m") - count_width
			var star_x: float = count_x - gap - side
			if share > 0.0:
				star.glow_color = Color(_skin.color(&"accent"), _skin.num(&"icon_glow_alpha"))
			star.position = Vector2(star_x, baseline - cap * 0.5 - side * 0.5)
			overlay.add_child(star)
			overlay.add_child(_text(count_text, label, label_size, _skin.color(&"ink_muted"), Vector2(count_x, baseline)))
			var right: float = center + best_width * 0.5
			if free_held > 0:
				var free_text: String = _skin.cased(&"label", "%d free" % free_held)
				var free_x: float = right + _skin.num(&"space_m")
				overlay.add_child(_text(free_text, label, label_size, _skin.color(&"accent"), Vector2(free_x, baseline)))
				right = free_x + label.get_string_size(free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
			report.append("counter: best line from %d to %d px; star %d to %d px, letters from %d px" % [roundi(star_x), roundi(right), roundi(baseline - cap * 0.5 - side * 0.5), roundi(baseline - cap * 0.5 + side * 0.5), roundi(baseline - cap)])
	out["star_center"] = overlay.position + star.position + star.size * 0.5
	return out


## A clear notice like the HUD's, at rest, with "+n" and a star after the
## copy. Gumdrop and Nova on the board's top edge, Slate in the context row.
func _star_notice(values: PackedInt64Array, stars: int) -> Control:
	var notice: ClearNotice = ClearNotice.new()
	notice.top_level = true
	notice.z_index = 12
	add_child(notice)
	var role: StringName = &"body" if _skin.id == &"gumdrop" else &"label"
	var font: Font = _skin.font(role)
	var font_size: int = _skin.font_size(role)
	var board: Rect2 = _game.board().get_global_rect()
	var height: float = _skin.num(&"notice_height")
	var lip: float = 0.0
	var pad: float = _skin.num(&"space_s")
	var box: StyleBox = null
	match _skin.id:
		&"gumdrop":
			lip = _skin.num(&"button_lip")
			box = Candy.badge(_skin, height - lip)
		&"slate":
			height = _skin.num(&"hint_height")
			pad = _skin.num(&"space_m")
			box = ThemeKit.box(_skin.color(&"badge"), 0.0)
		_:
			box = ThemeKit.box(_skin.color(&"badge"), height * 0.5)
	notice.build(_skin, values, role, box, height, lip, pad, pad, board.size.x)
	# The star part: space_s, "+n" in the notice's role, a gap of a quarter of
	# its size, then the star, its side the role's font size.
	var plus: String = "+%d" % stars
	var plus_width: float = font.get_string_size(plus, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var star_side: float = float(font_size)
	var part_x: float = notice.content_width() - pad + _skin.num(&"space_s")
	var width: float = part_x + plus_width + float(font_size) * 0.25 + star_side + pad
	var face: float = height - lip
	var line: float = font.get_height(font_size)
	var baseline: float = (face - line) * 0.5 + font.get_ascent(font_size)
	notice.add_child(_text(plus, font, font_size, _skin.color(&"badge_ink"), Vector2(part_x, baseline)))
	var star: AddedIcon = AddedIcon.new()
	star.setup(_skin, &"star", _skin.color(&"badge_ink"), star_side)
	star.fill_share = 1.0
	var cap_middle: float = baseline - FontMetrics.CAP_HEIGHT * float(font_size) * 0.5
	star.position = Vector2(part_x + plus_width + float(font_size) * 0.25, cap_middle - star_side * 0.5)
	notice.add_child(star)
	if _skin.id == &"slate":
		var hud: Rect2 = _game.hud().get_global_rect()
		notice.size = Vector2(hud.size.x, height)
		notice.global_position = Vector2(hud.position.x, hud.position.y + _skin.num(&"hud_height") - height)
	else:
		notice.size = Vector2(width, height)
		notice.global_position = Vector2(board.get_center().x - width * 0.5, board.position.y - height * 0.5)
	notice.set_meta(&"star_center", notice.global_position + star.position + star.size * 0.5)
	return notice


## Replaces a booster's cost with the star and Free in the look's colors.
func _free_cost(button: Control) -> void:
	button.set("cost_text", "")
	button.queue_redraw()
	var look: int = int(button.get("look"))
	var font: Font = _skin.font(&"label")
	var font_size: int = _skin.font_size(&"label")
	var word: String = _skin.cased(&"label", "Free")
	var word_width: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var star_side: float = float(font_size)
	var gap: float = float(font_size) * 0.25
	var group: float = star_side + gap + word_width
	var color: Color = _reward_color()
	var origin: Vector2 = Vector2.ZERO
	var left: float = 0.0
	match _skin.id:
		&"gumdrop":
			origin = button.get("_text_origin")
			left = origin.x + (button.size.x - group) * 0.5
			if look == SkinIcon.LOOK_ACTIVE:
				color = _skin.color(&"ink_dark")
			elif look == SkinIcon.LOOK_DISABLED:
				color = _skin.color(&"disabled_ink")
		&"slate":
			origin = button.get("_cost_origin")
			left = origin.x
			if look == SkinIcon.LOOK_ACTIVE:
				color = _skin.color(&"ink_dark")
			elif look == SkinIcon.LOOK_DISABLED:
				color = _skin.color(&"disabled_ink")
		_:
			origin = button.get("_text_origin")
			left = (button.size.x - group) * 0.5
			if look == SkinIcon.LOOK_DISABLED:
				color = _skin.color(&"disabled_ink")
	var overlay: Control = _overlay_over(button)
	var cap_middle: float = origin.y - FontMetrics.CAP_HEIGHT * float(font_size) * 0.5
	var star: AddedIcon = AddedIcon.new()
	star.setup(_skin, &"star", color, star_side)
	star.fill_share = 1.0
	star.position = Vector2(left, cap_middle - star_side * 0.5)
	overlay.add_child(star)
	overlay.add_child(_text(word, font, font_size, color, Vector2(left + star_side + gap, origin.y)))
	if look == SkinIcon.LOOK_DISABLED and _skin.id != &"gumdrop":
		var hairline: float = _skin.num(&"hairline")
		var strike: ColorRect = ColorRect.new()
		strike.color = color
		strike.position = Vector2(left - hairline, roundf(cap_middle) - hairline * 0.5)
		strike.size = Vector2(group + hairline * 2.0, hairline)
		overlay.add_child(strike)


func _box(style: StyleBox, rect: Rect2) -> Panel:
	var panel: Panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(&"panel", style)
	panel.position = rect.position
	panel.size = rect.size
	return panel


## A one line text drawn at a baseline origin.
func _text(text: String, font: Font, font_size: int, color: Color, baseline_origin: Vector2) -> Control:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(baseline_origin.x, baseline_origin.y - font.get_ascent(font_size))
	label.size = Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x + 2.0, font.get_height(font_size))
	return label


# --- Reading screens (7.11 to 7.14) ----------------------------------------

## The reading screen frame: backdrop, the header (title and close), Slate's
## hairline, and the scroll area down to the screen's bottom edge. Returns
## the content column.
func _reading_screen(title: String) -> VBoxContainer:
	var backdrop: SkinBackdrop = UiKit.make_backdrop(_skin)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var safe: Rect2 = _safe()
	var screen: Rect2 = get_viewport_rect()
	var margin: float = _skin.num(&"board_margin")
	var root: VBoxContainer = UiParts.vbox(0.0)
	root.position = safe.position
	root.size = Vector2(safe.size.x, screen.end.y - safe.position.y)
	add_child(root)
	var header_box: MarginContainer = _margins(root, margin, UiParts.icon_button_inset(_skin))
	var header: HBoxContainer = UiParts.hbox(_skin.num(&"space_s"))
	header.custom_minimum_size = Vector2(0.0, _skin.num(&"touch_min"))
	header_box.add_child(header)
	var title_label: Label = UiParts.label(_skin, &"TitleLabel", title)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	header.add_child(UiParts.icon_button(_skin, &"close"))
	if _skin.id == &"slate":
		var rule_box: MarginContainer = _margins(root, margin, margin)
		rule_box.add_child(UiParts.divider())
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	_scroll.scroll_deadzone = Spec.SCROLL_DEADZONE
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_scroll)
	var pad: MarginContainer = MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override(&"margin_left", roundi(margin))
	pad.add_theme_constant_override(&"margin_right", 0)
	pad.add_theme_constant_override(&"margin_top", roundi(_skin.num(&"space_s")))
	pad.add_theme_constant_override(&"margin_bottom", roundi(_skin.num(&"space_xl") + SAFE_INSETS.y))
	_scroll.add_child(pad)
	var gap: float = _skin.num(&"space_s")
	if _skin.id == &"slate":
		gap = 0.0
	elif _skin.id == &"nova":
		gap = _skin.num(&"space_l")
	var column: VBoxContainer = UiParts.vbox(gap)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(column)
	set_meta(&"backdrop", backdrop)
	return column


## Sections in order; Slate splits them with hairlines.
func _add_section(column: VBoxContainer, panel: Control) -> void:
	if _skin.id == &"slate" and column.get_child_count() > 0:
		column.add_child(UiParts.divider())
	column.add_child(panel)


func _how_to_play() -> void:
	var column: VBoxContainer = _reading_screen("How to play")
	for entry: Dictionary in HOW_TO_PLAY:
		var parts: Array = Kit.section(_skin)
		var inner: VBoxContainer = parts[1]
		inner.add_child(Kit.heading(_skin, String(entry["title"])))
		inner.add_child(Kit.reading(String(entry["text"])))
		var row_values: Array[int] = []
		for value: int in entry["row"]:
			row_values.append(value)
		if not row_values.is_empty():
			inner.add_child(Kit.spacer(_skin.num(&"space_m") - _skin.num(&"space_xs")))
			inner.add_child(Kit.example_row(_skin, row_values, int(entry["result"])))
		_add_section(column, parts[0])


func _about() -> void:
	var column: VBoxContainer = _reading_screen("About")
	var start: bool = true
	# The brand block sits on the backdrop in every skin.
	var brand_parts: Array = Kit.section(_skin)
	var brand_panel: PanelContainer = brand_parts[0]
	brand_panel.theme_type_variation = &""
	brand_panel.add_theme_stylebox_override(&"panel", _brand_padding())
	var brand: VBoxContainer = brand_parts[1]
	brand.add_child(Kit.wordmark(_skin, _skin.font_size(&"display"), start))
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	brand.add_child(UiParts.label(_skin, &"CaptionLabel", "Version %s" % version))
	brand.add_child(Kit.spacer(_skin.num(&"space_m") - _skin.num(&"space_xs")))
	brand.add_child(UiParts.label(_skin, &"BodyLabel", "Made by Bart Basi"))
	brand.add_child(UiParts.label(_skin, &"BodyLabel", "Copyright 2026 Play, Inc."))
	_add_section(column, brand_panel)
	var texts: Array[Array] = [
		["What it is", "SumUp is a number merge puzzle. Join touching tiles of the same number into bigger ones and see how high you can go."],
		["Offline, no data", "SumUp works fully offline. It collects no data, has no ads or accounts and asks for no permissions."],
	]
	for item: Array in texts:
		var parts: Array = Kit.section(_skin)
		(parts[1] as VBoxContainer).add_child(Kit.heading(_skin, String(item[0])))
		(parts[1] as VBoxContainer).add_child(Kit.reading(String(item[1])))
		_add_section(column, parts[0])
	var licenses: Array = Kit.section(_skin)
	var inner: VBoxContainer = licenses[1]
	inner.add_child(Kit.heading(_skin, "Licenses"))
	inner.add_child(Kit.reading("SumUp is free software: you can share and change it under the GNU General Public License, version 3, with additional terms (see the SumUp license below). Any work based on SumUp keeps its attribution, and changed versions are marked as changed. SumUp comes with no warranty."))
	inner.add_child(Kit.spacer(_skin.num(&"space_s")))
	var rows: Array[Array] = [
		["SumUp", "GNU GPL version 3, added terms"],
		["Godot Engine", "MIT license and its parts"],
		["Outfit font", "SIL Open Font License 1.1"],
	]
	for i: int in rows.size():
		if i > 0:
			inner.add_child(UiParts.divider())
		inner.add_child(Kit.open_row(_skin, String(rows[i][0]), String(rows[i][1])))
	_add_section(column, licenses[0])


func _brand_padding() -> StyleBox:
	var box: StyleBoxEmpty = StyleBoxEmpty.new()
	var pad: float = _skin.num(&"space_m") if _skin.id == &"gumdrop" else 0.0
	ThemeKit.pad(box, pad, _skin.num(&"space_s"), pad, _skin.num(&"space_m"))
	return box


func _license() -> void:
	var column: VBoxContainer = _reading_screen("Godot Engine")
	var parts: Array = Kit.section(_skin)
	var panel: PanelContainer = parts[0]
	panel.theme_type_variation = &""
	panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var inner: VBoxContainer = parts[1]
	inner.add_theme_constant_override(&"separation", roundi(_skin.num(&"space_s")))
	inner.add_child(Kit.heading(_skin, "Godot Engine license"))
	for paragraph: String in Kit.reflow(Engine.get_license_text()):
		inner.add_child(Kit.reading(paragraph))
	inner.add_child(Kit.spacer(_skin.num(&"space_m")))
	inner.add_child(Kit.heading(_skin, "Third party parts"))
	var shown: int = 0
	for component: Dictionary in Engine.get_copyright_info():
		if shown >= 6:
			break
		shown += 1
		# Component names can be long: every text on a reading screen wraps.
		inner.add_child(UiParts.paragraph(_skin, &"BodyLabel", String(component["name"]), HORIZONTAL_ALIGNMENT_LEFT))
		for part: Dictionary in component["parts"]:
			for line: String in part["copyright"]:
				inner.add_child(Kit.reading("Copyright %s" % line))
			inner.add_child(Kit.reading("License: %s" % part["license"]))
	_add_section(column, panel)


# --- Icon sheet ---------------------------------------------------------------

## The new icons large and at their real sizes: the star empty, a third, two
## thirds and full; the chevron and the arrow.
func _icons() -> void:
	var backdrop: SkinBackdrop = UiKit.make_backdrop(_skin)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	set_meta(&"backdrop", backdrop)
	var color: Color = _reward_color()
	var shares: Array[float] = [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
	var spec: Dictionary = Spec.star(_skin)
	var outline: PackedVector2Array = AddedIcon.star_outline(spec)
	var cuts: PackedStringArray = PackedStringArray()
	for share: float in [1.0 / 3.0, 2.0 / 3.0]:
		var cut: float = AddedIcon.fill_cut(outline, share)
		var top: float = float((spec["center"] as Vector2).y) - float(spec["outer"])
		var bottom: float = float((spec["center"] as Vector2).y) + float(spec["outer"]) * cos(deg_to_rad(36.0))
		cuts.append("%.0f%% filled: cut at grid y %.2f, %.1f%% of the star's height from its bottom" % [share * 100.0, cut, (bottom - cut) / (bottom - top) * 100.0])
	report.append("star fill levels: " + "; ".join(cuts))
	var y: float = 200.0
	for side: float in [216.0, Spec.num(_skin, &"star_icon"), float(_skin.font_size(&"label"))]:
		var x: float = 60.0
		for share: float in shares:
			var star: AddedIcon = AddedIcon.new()
			star.setup(_skin, &"star", color, side)
			star.fill_share = share
			if _skin.id == &"nova" and share > 0.0:
				star.glow_color = Color(_skin.color(&"accent"), _skin.num(&"icon_glow_alpha"))
			star.position = Vector2(x, y)
			add_child(star)
			x += side + 40.0
		y += side + 60.0
	for icon: StringName in [&"chevron", &"arrow"]:
		var x2: float = 60.0
		for side: float in [216.0, _skin.num(&"icon_hud"), Spec.ARROW_ICON]:
			var made: AddedIcon = AddedIcon.new()
			made.setup(_skin, icon, _skin.color(&"ink"), side)
			made.position = Vector2(x2, y)
			add_child(made)
			x2 += side + 60.0
		y += 276.0


# --- Shared ----------------------------------------------------------------

func _after_layout() -> void:
	_frames += 1
	if _frames == 2 and _overlay.is_valid():
		_overlay.call()
	if _frames == 3:
		_measure()
	if _frames == 4 and page == "howto_end" and _scroll != null:
		_scroll.scroll_vertical = roundi(_scroll.get_v_scroll_bar().max_value)
	if _frames >= 5:
		get_tree().process_frame.disconnect(_after_layout)


func _measure() -> void:
	if has_meta(&"backdrop"):
		var backdrop: SkinBackdrop = get_meta(&"backdrop")
		var clear: Array[Rect2] = [get_viewport_rect()]
		if has_meta(&"clear"):
			clear.clear()
			for item: Control in get_meta(&"clear"):
				clear.append(item.get_global_rect())
		backdrop.set_clear_rects(clear)
	if has_meta(&"brand"):
		var brand: Control = get_meta(&"brand")
		var rect: Rect2 = brand.get_global_rect()
		report.append("brand block %d to %d px, center at %.1f%% of the screen height" % [roundi(rect.position.y), roundi(rect.end.y), rect.get_center().y / get_viewport_rect().size.y * 100.0])
	if _scroll != null:
		var content: float = _scroll.get_child(0).get_combined_minimum_size().y
		var visible_height: float = _scroll.size.y
		report.append("scroll content %d px in a %d px view: %.2f screen heights" % [roundi(content), roundi(visible_height), content / visible_height])


func _safe() -> Rect2:
	return SafeArea.viewport_safe_rect(get_viewport())


func _margins(parent: Node, left: float, right: float) -> MarginContainer:
	var box: MarginContainer = MarginContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"margin_left", roundi(left))
	box.add_theme_constant_override(&"margin_right", roundi(right))
	parent.add_child(box)
	return box


func _ratio_spacer(ratio: float) -> Control:
	var gap: Control = Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.size_flags_stretch_ratio = ratio
	return gap
