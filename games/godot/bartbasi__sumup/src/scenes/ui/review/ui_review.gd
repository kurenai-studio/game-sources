extends Control
## Review page for the production screens, 1080 by 2400, for the
## senior-graphic-designer. Each scene in scenes/ui/review/ sets the skin and
## the page:
##   splash      the splash screen with records, at rest; prints the brand
##               block's center as a share of the screen height and the
##               coffee button's rect
##   splash_first  the same with no best tile yet
##   play        the play screen mid game; prints where the coffee button
##               went (DESIGN_SYSTEM.md 7.15). The Fold5 cover and inner
##               pages set the insets of 7.15 and are captured at 1080x2767
##               and 1999x2400; the fold_inner_hint_hidden pages set the
##               inner screen's insets with the gesture hint hidden (94, 0)
##   pause       Pause over the play screen
##   settings    Settings over the play screen
##   offer       the out of moves offer, Shuffle suggested
##   offer_none  the offer with nothing suggested (costs overridden as in
##               GDD AT-109 (d): with the GDD 18 costs this state never
##               shows, because whenever Shuffle and Undo are unusable
##               nothing else is either and the run ends)
##   end         the end of run panel with the New best badge
##   end_no_moves  the end of run panel after a run that ended at once with
##               nothing usable, so it says "No moves left."
##   splash_long, end_long  the splash and the end of run with the longest
##               numbers of a real run (DESIGN_SYSTEM.md 14): Best score
##               "9,999,999,999zz", final score the same, Best tile and this
##               run's highest tile 512aa (2^69)
##   confirm     the New game confirmation over Pause
##   first_launch  the real App on first launch with an empty save folder and
##               no simulated insets; prints where the brand block sits
##   offer_free  the offer with a free booster held ("Shuffle for free")
##   info        Info, top; prints its content height in screen heights
##   info_boosters  Info scrolled to the Hammer section (the booster icons)
##   info_end    Info, scrolled to the end
##   info_open   the splash, then Info opened as the App opens it, with vsync
##               off; prints the longest frame from the tap until the guide
##               is built and faded in, then quits (QA SPL-02)
##   about       About
##   about_support  About scrolled to "Offline, no data", so the added
##               sentence, "Supporting SumUp" and its button show together
##   license_game, license_godot, license_outfit
##               a license text inside About; prints the time to build it
##   license_godot_rules  Godot's text scrolled to the FreeType license, to
##               judge the rule lines drawn as dividers
## Every page prints the content column and the height of its panel, if any.
## Capture with tools/capture.tscn, for example:
##   godot --path . res://tools/capture.tscn -- --scene res://scenes/ui/review/review_gumdrop_splash.tscn --out docs/design/review/prod-screens-gumdrop-splash.png
##
## Everything here is the real screen and panel code fed a crafted session;
## nothing is saved. Panels show at rest (no dialog_in), so a capture after a
## few frames shows their final look. The safe area is simulated as the
## capture tool's default phone: 120 px on top, 66 px at the bottom.

const GAME_SCENE: PackedScene = preload("res://scenes/ui/game_screen.tscn")
const SPLASH_SCENE: PackedScene = preload("res://scenes/ui/splash_screen.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/pause_panel.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_panel.tscn")
const CONFIRM_SCENE: PackedScene = preload("res://scenes/ui/confirm_dialog.tscn")
const END_SCENE: PackedScene = preload("res://scenes/ui/end_panel.tscn")
const INFO_SCENE: PackedScene = preload("res://scenes/ui/info_panel.tscn")
const ABOUT_SCENE: PackedScene = preload("res://scenes/ui/about_panel.tscn")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")
## The run highest tile on the free offer page: 3 stars, 1 free booster.
const FREE_RUN_HIGHEST: int = 8192
## Frames before the measurements, and before scrolling info_end.
const MEASURE_AFTER_FRAMES: int = 3

const APP_SCENE: PackedScene = preload("res://scenes/ui/app.tscn")
## Where the first launch page keeps its throwaway save folder.
const FIRST_LAUNCH_ROOT: String = "user://review_first_launch"
## Frames to wait for the containers to settle before measuring.
const REPORT_AFTER_FRAMES: int = 4

## The capture tool's default simulated safe area (tools/capture.gd).
const SAFE_INSETS: Vector2 = Vector2(120.0, 66.0)

## The Phase 1 mock moments (tools/directions/shared/mock_state.gd), as tile
## values; _board turns them into the exponents the game holds.
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
const NO_MOVES: Array[int] = [
	4, 32, 2, 16, 8,
	16, 8, 64, 4, 2,
	2, 128, 2, 512, 32,
	64, 16, 32, 8, 4,
	8, 4096, 2, 128, 16,
	2, 64, 16, 4, 256,
	32, 4, 1024, 64, 8,
	8, 16, 2, 32, 2,
]
const SCORE: int = 41286
const FINAL_SCORE: int = 76410
const BEST_SCORE: int = 96520
const BEST_TILE: int = 13    # 8192, as an exponent
## The long pages: 2^69 reads "512aa", and 1,753 nines read "9,999,999,999zz".
const LONG_TILE: int = 69
const LONG_DIGITS: int = 1753
## The Best Score before the run on the end page, below its final score.
const END_OLD_BEST: int = 70000
## A score below every cost on the no moves board (4096 is its highest tile).
const NO_MOVES_SCORE: int = 1200

@export var skin_id: StringName = &"gumdrop"
## One of the pages listed above.
@export var page: String = "menu"
## When above 0, touch_min and button_height take this value on a copy of the
## skin, to measure the panels before QA6-05 (144) against now (160).
@export var touch_px: float = 0.0
## The simulated safe area: top and bottom insets in px. The Fold5 pages
## use the insets of DESIGN_SYSTEM.md 7.15 (tools/coffee_space.gd).
@export var insets: Vector2 = SAFE_INSETS

var _skin: SkinData = null
var _app: App = null
var _folder: String = ""
var _frames: int = 0
var _best_score: BigNum = BigNum.from_int(BEST_SCORE)
var _session: GameSession = null
var _audio: AudioService = null
## The page's reading screen or dialog panel, for the measurements.
var _shown: Control = null
var _game_screen: GameScreen = null
var _measure_frames: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if page == "first_launch":
		_first_launch()
		return
	SafeArea.simulated_insets = insets
	_skin = SkinCatalog.get_skin(skin_id)
	if touch_px > 0.0:
		_skin = _skin.duplicate(true) as SkinData
		_skin.numbers = _skin.numbers.duplicate()
		_skin.numbers[&"touch_min"] = touch_px
		_skin.numbers[&"button_height"] = touch_px
	theme = UiKit.build_theme(_skin)
	_audio = AudioService.new()
	add_child(_audio)
	match page:
		"info_open":
			var opener: SplashScreen = SPLASH_SCENE.instantiate() as SplashScreen
			add_child(opener)
			opener.setup(_skin, _records())
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			get_tree().process_frame.connect(_time_info_open)
			return
		"splash", "splash_first", "splash_long":
			var splash: SplashScreen = SPLASH_SCENE.instantiate() as SplashScreen
			add_child(splash)
			var records: Records = _records()
			if page == "splash_first":
				records.best_tile = 0
			elif page == "splash_long":
				records.best_score = _long_score()
				records.best_tile = LONG_TILE
			splash.setup(_skin, records)
			_shown = splash
		"play":
			_game(_board(MID_GAME), SCORE, null)
		"pause":
			_game(_board(MID_GAME), SCORE, null)
			(_panel(PAUSE_SCENE) as PausePanel).setup(_skin)
		"settings":
			_game(_board(MID_GAME), SCORE, null)
			var settings: Settings = Settings.new()
			settings.set_skin_id(_skin.id)
			(_panel(SETTINGS_SCENE) as SettingsPanel).setup(_skin, settings)
		"offer":
			_game(_board(NO_MOVES), FINAL_SCORE, null)
		"offer_free":
			_game(_board(NO_MOVES), FINAL_SCORE, null, FREE_RUN_HIGHEST)
		"info", "info_end", "info_boosters":
			(_panel(INFO_SCENE) as InfoPanel).setup(_skin)
		"about", "about_support":
			(_panel(ABOUT_SCENE) as AboutPanel).setup(_skin)
		"license_game", "license_godot", "license_outfit", "license_godot_rules":
			var about: AboutPanel = _panel(ABOUT_SCENE) as AboutPanel
			about.setup(_skin)
			about.open_license(StringName(page.trim_prefix("license_").trim_suffix("_rules")))
		"offer_none":
			var config: GameConfig = GameConfig.new()
			config.cost_shift[&"shuffle"] = 2
			config.cost_shift[&"undo"] = 2
			_game(_board(NO_MOVES), 5000, config)
		"end_long":
			var summary: RunSummary = RunSummary.new()
			summary.final_score = _long_score()
			summary.best_score = _long_score()
			summary.best_tile = LONG_TILE
			summary.run_highest = LONG_TILE
			summary.new_best_score = true
			_show_end(summary)
		"end":
			# A run that beat the old Best Score, so the New best badge shows,
			# ended from the offer with End run.
			_best_score = BigNum.from_int(END_OLD_BEST)
			_game(_board(NO_MOVES), FINAL_SCORE, null)
			_session.run_ended.connect(_show_end)
			_session.end_run()
		"end_no_moves":
			# No valid move and nothing affordable: the run ends at once, and
			# the panel says no moves were left (GDD 12.2 step 3, QA4-01).
			_best_score = BigNum.from_int(END_OLD_BEST)
			var rng: RunRandom = RunRandom.new()
			rng.set_seed(1)
			_session = GameSession.new(null, rng, _records())
			var game: GameScreen = GAME_SCENE.instantiate() as GameScreen
			add_child(game)
			game.setup(_session, Settings.new(), _audio, _skin)
			_session.run_ended.connect(_show_end)
			_session.resume(RunState.create(_board(NO_MOVES), BigNum.from_int(NO_MOVES_SCORE)))
			if _session.is_waiting_for_view():
				_session.move_shown()
		"confirm":
			_game(_board(MID_GAME), SCORE, null)
			(_panel(PAUSE_SCENE) as PausePanel).setup(_skin)
			(_panel(CONFIRM_SCENE) as ConfirmDialog).setup(_skin, Copy.CONFIRM_TITLE, Copy.CONFIRM_BODY, Copy.NEW_GAME, Copy.CANCEL)
		_:
			push_error("ui_review: unknown page '%s'" % page)
	get_tree().process_frame.connect(_measure)


## The measurements the screens review asks for, printed once the layout has
## settled: the content column, the panel's height, Info's length in
## screen heights, the time a license text took to build.
func _measure() -> void:
	_measure_frames += 1
	if _measure_frames < MEASURE_AFTER_FRAMES:
		return
	var screen: Vector2 = get_viewport_rect().size
	var column: Rect2 = SafeArea.content_column(get_viewport(), _skin)
	var tag: String = "ui_review: %s %s %dx%d" % [_skin.id, page, roundi(screen.x), roundi(screen.y)]
	var reading: Control = _shown if _shown != null and _shown.has_method(&"scroll") else null
	if _shown is AboutPanel and (_shown as AboutPanel).license_view() != null:
		reading = (_shown as AboutPanel).license_view()
		if not bool(reading.call(&"is_built")):
			return
		print("%s: first screenful in %.1f ms, built in %.1f ms, %d labels, %d dividers" % [tag, float(reading.get(&"first_screen_usec")) / 1000.0, float(reading.get(&"build_usec")) / 1000.0, int(reading.call(&"label_count")), int(reading.call(&"rule_count"))])
		if page == "license_godot_rules":
			_scroll_to_text(reading, "The FreeType Project LICENSE")
	if _measure_frames == MEASURE_AFTER_FRAMES or reading != null:
		get_tree().process_frame.disconnect(_measure)
	print("%s: content column x %.0f, width %.0f" % [tag, column.position.x, column.size.x])
	if _shown != null and _shown.has_method(&"panel"):
		var panel: Control = _shown.call(&"panel")
		print("%s: panel %.0f px tall, %.0f px wide" % [tag, panel.size.y, panel.size.x])
	if reading != null:
		var scroll: ScrollContainer = reading.call(&"scroll")
		var content: float = scroll.get_child(0).get_combined_minimum_size().y
		print("%s: scroll content %.0f px in a %.0f px view, %.2f screen heights" % [tag, content, scroll.size.y, content / maxf(1.0, scroll.size.y)])
		if page == "info_end":
			scroll.scroll_vertical = roundi(scroll.get_v_scroll_bar().max_value)
		elif page == "info_boosters":
			_scroll_to_text(reading, _skin.cased(&"heading", "Hammer"))
		elif page == "about_support":
			_scroll_to_text(reading, _skin.cased(&"heading", "Offline, no data"))
	if _shown is SplashScreen:
		var splash_shown: SplashScreen = _shown as SplashScreen
		var brand: Rect2 = splash_shown.brand_rect()
		print("%s: brand block center %.1f%% of the screen height" % [tag, brand.get_center().y / screen.y * 100.0])
		print("%s: coffee button %s" % [tag, splash_shown.coffee_button().get_global_rect()])
	if page == "about" and _shown is AboutPanel:
		var copyright: Rect2 = (_shown as AboutPanel).copyright_label().get_global_rect()
		print("%s: the attribution ends %.0f px down the screen" % [tag, copyright.end.y])
	if page == "play" and _game_screen != null:
		var coffee: Control = _game_screen.coffee_button()
		print("%s: coffee %s, shown %s, rect %s; board %s, bar %s, HUD %s" % [tag, GameScreen.CoffeePlace.keys()[_game_screen.coffee_place()], _game_screen.is_coffee_shown(), coffee.get_global_rect(), _game_screen.board().get_global_rect(), _game_screen.booster_bar().get_global_rect(), _game_screen.hud().get_global_rect()])
	if page == "pause" and _shown is PausePanel:
		var settings_button: Control = _shown.find_child("Settings", true, false) as Control
		print("%s: pause coffee %s, Settings %s" % [tag, (_shown as PausePanel).coffee_button().get_global_rect(), settings_button.get_global_rect()])
	if page.begins_with("offer") and _game_screen != null:
		var offer: OfferPanel = _game_screen.offer_panel()
		print("%s: offer panel %.0f px tall, buy button '%s'" % [tag, offer.size.y, offer.buy_button().text if offer.buy_button() != null else "none"])


var _open_frames: int = 0
var _open_last_usec: int = 0
var _open_worst_usec: int = 0
var _open_info: InfoPanel = null
var _open_frames_done: int = 0
## The longest frame before Info opens, the splash alone, for comparison.
var _idle_worst_usec: int = 0
var _open_slow: PackedStringArray = PackedStringArray()
var _open_usec: int = 0
var _fade_usec: int = 0


## info_open: opens Info on frame 30 and times every frame after it until the
## guide is built, faded in and 10 more frames have run.
func _time_info_open() -> void:
	_open_frames += 1
	var now: int = Time.get_ticks_usec()
	if _open_info != null:
		if now - _open_last_usec > 12000:
			_open_slow.append("%.1f ms at stage %d, %d parts" % [float(now - _open_last_usec) / 1000.0, _open_info.stage(), _open_info.built_parts()])
		_open_worst_usec = maxi(_open_worst_usec, now - _open_last_usec)
		if _fade_usec == 0 and _open_info.stage() != InfoPanel.Stage.FIRST:
			_fade_usec = now - _open_usec
		if _open_info.stage() == InfoPanel.Stage.DONE and _open_info.modulate.a >= 1.0:
			_open_frames_done += 1
			if _open_frames_done >= 10:
				get_tree().process_frame.disconnect(_time_info_open)
				print("ui_review: %s info_open: worst frame %.1f ms (splash alone %.1f ms), worst build step %.1f ms, fade starts %.0f ms after the tap" % [_skin.id, float(_open_worst_usec) / 1000.0, float(_idle_worst_usec) / 1000.0, float(_open_info.worst_build_usec) / 1000.0, float(_fade_usec) / 1000.0])
				if not _open_slow.is_empty():
					print("ui_review: frames over 12 ms: %s" % "; ".join(_open_slow))
				get_tree().quit()
				return
	elif _open_frames > 10 and _open_frames < 30:
		_idle_worst_usec = maxi(_idle_worst_usec, now - _open_last_usec)
	elif _open_frames == 30:
		_open_info = INFO_SCENE.instantiate() as InfoPanel
		add_child(_open_info)
		_open_info.setup(_skin)
		_open_info.play_in()
		_open_usec = now
	_open_last_usec = now


## Scrolls a reading screen so the label that starts with text is at the top.
func _scroll_to_text(reading: Control, text: String) -> void:
	var scroll: ScrollContainer = reading.call(&"scroll")
	for node: Node in reading.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label.text.begins_with(text):
			var top: float = label.get_global_rect().position.y - scroll.get_global_rect().position.y + float(scroll.scroll_vertical)
			scroll.scroll_vertical = roundi(top)
			return


func _exit_tree() -> void:
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)
	if not _folder.is_empty():
		for file_name: String in DirAccess.get_files_at(_folder):
			DirAccess.remove_absolute(_folder.path_join(file_name))
		DirAccess.remove_absolute(_folder)
		DirAccess.remove_absolute(FIRST_LAUNCH_ROOT)


## The real App on first launch: an empty save folder (only the chosen skin
## in the profile, for Slate and Nova), no simulated insets, like a capture
## of scenes/main.tscn. Prints where the brand block's center sits.
func _first_launch() -> void:
	_folder = FIRST_LAUNCH_ROOT.path_join(String(skin_id))
	DirAccess.make_dir_recursive_absolute(_folder)
	for file_name: String in DirAccess.get_files_at(_folder):
		DirAccess.remove_absolute(_folder.path_join(file_name))
	if skin_id != SkinCatalog.DEFAULT_ID:
		var settings: Settings = Settings.new()
		settings.set_skin_id(skin_id)
		SaveService.new(_folder).save_profile(settings, Records.new())
	_app = APP_SCENE.instantiate() as App
	_app.save_folder = _folder
	add_child(_app)
	get_tree().process_frame.connect(_report_brand)


func _report_brand() -> void:
	_frames += 1
	if _frames < REPORT_AFTER_FRAMES or _app.splash_screen() == null:
		return
	get_tree().process_frame.disconnect(_report_brand)
	var brand: Rect2 = _app.splash_screen().brand_rect()
	var height: float = get_viewport_rect().size.y
	print("ui_review: %s first launch, brand block %.0f to %.0f px, center %.1f%% of the screen height" % [skin_id, brand.position.y, brand.end.y, brand.get_center().y / height * 100.0])


func _records() -> Records:
	var records: Records = Records.new()
	records.best_score = _best_score
	records.best_tile = BEST_TILE
	return records


func _show_end(summary: RunSummary) -> void:
	var end: EndPanel = _panel(END_SCENE) as EndPanel
	end.setup(_skin)
	end.show_summary(summary)


## The mock tile values as the exponents the game holds.
func _board(values: Array[int]) -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for value: int in values:
		cells.append(SkinData.exponent_of(value))
	return cells


static func _long_score() -> BigNum:
	return BigNum.parse("9".repeat(LONG_DIGITS), LONG_DIGITS)


## The play screen showing a resumed run: the board appears at once and the
## move check opens the offer when there is no valid move.
func _game(cells: PackedInt64Array, score: int, config: GameConfig, run_highest: int = 0) -> void:
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(1)
	_session = GameSession.new(config, rng, _records())
	var game: GameScreen = GAME_SCENE.instantiate() as GameScreen
	add_child(game)
	_game_screen = game
	game.setup(_session, Settings.new(), _audio, _skin)
	_session.resume(RunState.create(cells, BigNum.from_int(score), PackedInt64Array(), null, SkinData.exponent_of(run_highest) if run_highest > 0 else 0))

	if _session.is_waiting_for_view():
		_session.move_shown()


func _panel(scene: PackedScene) -> Control:
	var panel: Control = scene.instantiate() as Control
	add_child(panel)
	_shown = panel
	return panel
