# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name App
extends Control
## The app glue (docs/ARCHITECTURE.md 3.6): boots the data, the saves and the sound,
## switches between screens, keeps panels above them, runs the game flow, saves
## when the app is left, lays everything out for the window and handles the back
## button.
##
## Screens form a stack. Only the top one shows. Modals (Settings, Pause, a
## confirm) sit above the stack; a page opened from a modal hides the modals
## until the player comes back to where it started. The back button closes the
## top modal first, then goes back one page, in a battle it opens Pause, and on
## the front door it quits. Everything is saved the moment it changes, so quitting
## loses nothing.
##
## The flow: Play opens the mode screen. Campaign opens the level list and a
## level's card. Roguelite and Daily open their run card. A battle starts from a card,
## or resumes from the Continue card. One game is saved per mode: a campaign level, a
## run and a daily. A win records its stars; a level that is left or abandoned records
## nothing. A run or daily records its counters when it ends, and an abandoned one
## counts as lost at its current wave (RULES 14.7).

## The player turned sound effects on or off in Settings.
signal sound_changed(on: bool)
## The player turned music on or off in Settings.
signal music_changed(on: bool)
## Taps on the mode screen. The App answers all four itself.
signal continue_requested()
signal campaign_requested()
signal roguelite_requested()
signal daily_requested()

## Stars the roguelite and the daily need until the rules file says otherwise.
const RUN_STARS_DEFAULT: int = 12
## The run mode exists. Roguelite and Daily open with the stars rules.json asks for (RULES 16).
const RUNS_BUILT: bool = true
## Two back presses closer than this are one press.
const BACK_GUARD_MS: int = 150

## Tests set these before build(); a real launch leaves them and the App makes its own.
## The App frees only the AudioService it made itself.
var data_root: String = "res://data"
var game: GameData = null
var store: SaveStore = null
var audio: AudioService = null
## Seconds between the last creature and the end panel, so the last sparkles show.
var end_delay: float = 1.2
## Where the phone's date comes from: a Callable that returns a Time date dictionary
## (year, month, day). Empty means the phone's clock. Tests put a stand-in here.
var date_source: Callable = Callable()
## Where a new run's seed comes from: a Callable that returns a whole number from 0 to
## 2^32 - 1. Empty means a fresh random draw, the one unseeded draw in the game.
var seed_source: Callable = Callable()

var settings: Settings = null
var progress: Progress = null
## The daily's best result and streak.
var daily_record: DailyRecord = null
## Every saved game, most recent first.
var saved_games: Array[SavedGame] = []
var probe: PerfProbe = null
## True when a bundled data file failed its check. Nothing else starts then.
var damaged: bool = false

var sound_on: bool = true
var music_on: bool = true
## rules.json keys, once the data is loaded. Only the Info guide uses them.
var rules: Dictionary = {}
## Creature and tower names by id, once the data is loaded. Only Info uses them.
var names: Dictionary = {}
var stars: int = 0
var runs_open: bool = false

var _backdrop: Backdrop
var _screens: Control
var _modal_layer: Control
var _stack: Array[ScreenFrame] = []
var _modals: Array[Modal] = []
var _front_door: FrontDoor
var _trash: Array[Node] = []
var _window: Vector2 = Vector2(1080.0, 2400.0)
var _safe: Rect2 = Rect2(0.0, 0.0, 1080.0, 2400.0)
## The stack size when a page first hid the modals; -1 when they are showing.
var _hidden_depth: int = -1

var _active: SavedGame = null
var _battle_screen: BattleScreen = null
var _end: Dictionary = {}
var _end_wait: float = 0.0
var _save_failed: bool = false
var _last_back_ms: int = -1000


func _ready() -> void:
	build()
	get_tree().quit_on_go_back = false
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


## Builds the backdrop, the layers and the front door, then loads the data, the saves
## and the sound. _ready calls it; a test may call it first to work without a scene
## tree. It runs once.
func build() -> void:
	if _front_door != null:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# The icons are drawn in code. Draw them now, not in the first wave.
	IconTex.prewarm()
	theme = UiTheme.build()
	_backdrop = Backdrop.new()
	# Behind the battle map, which sits at -5.
	_backdrop.z_index = -10
	add_child(_backdrop)
	_screens = _full_rect_control()
	add_child(_screens)
	_modal_layer = _full_rect_control()
	add_child(_modal_layer)
	_front_door = FrontDoor.new()
	_front_door.play_pressed.connect(open_mode)
	_front_door.info_pressed.connect(open_info)
	_front_door.about_pressed.connect(open_about)
	_front_door.settings_pressed.connect(open_settings)
	_screens.add_child(_front_door)
	_stack.append(_front_door)
	set_process(false)
	continue_requested.connect(_on_continue)
	campaign_requested.connect(_on_campaign)
	roguelite_requested.connect(_on_roguelite)
	daily_requested.connect(_on_daily)
	_boot()
	apply_layout(_window, _safe)


# Boot (flow step 1).

func _boot() -> void:
	if game == null:
		game = GameData.load_from(data_root)
	if not game.problems.is_empty():
		_show_damaged()
		return
	if store == null:
		store = SaveStore.new()
	settings = store.load_settings()
	progress = store.load_progress()
	daily_record = store.load_daily()
	saved_games = store.load_games(game)
	sound_on = settings.sound_on
	music_on = settings.music_on
	if audio == null:
		# The App owns the service it makes. A test that passes its own keeps it.
		audio = AudioService.new()
		add_child(audio)
	audio.set_enabled(sound_on)
	audio.set_music_on(music_on)
	audio.set_music(&"menu")
	_fill_info()
	_refresh_progress()


## The damaged message. Nothing else starts after it.
func _show_damaged() -> void:
	damaged = true
	var screen: DamagedScreen = DamagedScreen.new()
	screen.close_requested.connect(_quit)
	push_screen(screen)


## The numbers and names the Info guide reads, from the Catalog.
func _fill_info() -> void:
	var r: GameRules = game.catalog.rules
	rules = {
		"start_lives": r.start_lives, "relaxed_lives_pct": r.relaxed_lives_pct,
		"relaxed_gold_pct": r.relaxed_gold_pct, "refund_pct": r.refund_pct,
		"early_bonus_pct": r.early_bonus_pct, "star2_lives": r.star2_lives,
		"max_waves_running": r.max_waves_running, "max_gates": r.max_gates, "run_stars": r.run_stars,
		"runs_built": RUNS_BUILT,
	}
	names = {}
	for id: StringName in game.catalog.tower_ids():
		names[id] = game.catalog.tower(id).name
	for id: StringName in game.catalog.enemy_ids():
		names[id] = game.catalog.enemy(id).name


func _refresh_progress() -> void:
	stars = progress.stars()
	runs_open = progress.runs_open(game)


func _exit_tree() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.disconnect(_on_viewport_resized)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back_pressed()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		leave_app()
	elif what == NOTIFICATION_PREDELETE:
		for node: Node in _trash:
			if is_instance_valid(node):
				node.free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_back_pressed()


func _process(delta: float) -> void:
	if _end.is_empty():
		set_process(false)
		return
	_end_wait -= delta
	if _end_wait <= 0.0:
		_show_end()


# Screens.

## The screen that is showing.
func current_screen() -> ScreenFrame:
	return _stack.back()


func screen_count() -> int:
	return _stack.size()


func modal_count() -> int:
	return _modals.size()


## The modal on top, or null.
func top_modal() -> Modal:
	return null if _modals.is_empty() else _modals.back()


## False while a page hides the modals.
func modals_showing() -> bool:
	return _modal_layer.visible


func front_door() -> FrontDoor:
	return _front_door


## The battle on screen, or null.
func battle_screen() -> BattleScreen:
	return _battle_screen


## The game being played, or null.
func active_game() -> SavedGame:
	return _active


## Puts a screen on top of the stack. Only it shows until it is popped.
func push_screen(screen: ScreenFrame) -> void:
	if not _modals.is_empty() and _hidden_depth < 0:
		_hidden_depth = _stack.size()
		_modal_layer.visible = false
	_stack.back().visible = false
	_stack.append(screen)
	_screens.add_child(screen)
	screen.back_requested.connect(pop_screen)
	screen.apply_layout(_window, _safe)


## Removes the top screen. The front door is never removed.
func pop_screen() -> void:
	if _stack.size() <= 1:
		return
	var gone: ScreenFrame = _stack.pop_back()
	if gone == _battle_screen:
		_battle_screen = null
	_screens.remove_child(gone)
	_discard(gone)
	_stack.back().visible = true
	if _hidden_depth == _stack.size():
		_hidden_depth = -1
		_modal_layer.visible = true
	var top: ScreenFrame = _stack.back()
	if top is ModeScreen and progress != null:
		_fill_mode(top as ModeScreen)


func open_mode() -> void:
	if damaged:
		return
	var screen: ModeScreen = ModeScreen.new()
	_fill_mode(screen)
	screen.continue_pressed.connect(func() -> void: continue_requested.emit())
	screen.campaign_pressed.connect(func() -> void: campaign_requested.emit())
	screen.roguelite_pressed.connect(func() -> void: roguelite_requested.emit())
	screen.daily_pressed.connect(func() -> void: daily_requested.emit())
	push_screen(screen)


## The Continue card and the run locks, from the saved games and the progress.
func _fill_mode(screen: ModeScreen) -> void:
	screen.set_runs(runs_open, stars, int(rules.get("run_stars", RUN_STARS_DEFAULT)), RUNS_BUILT, daily_detail(), daily_regions())
	if saved_games.is_empty():
		screen.set_continue("", "")
		return
	screen.set_continue("Continue", _saved_text(saved_games[0]))


## The Daily button's second line: the day's best and the shown streak. "" keeps the plain line.
func daily_detail() -> String:
	var day: String = today()
	if day.is_empty():
		return "Check the phone's date."
	var saved: SavedGame = saved_game(SavedGame.DAILY)
	var saved_today: bool = saved != null and saved.run.day == day
	return ModeScreen.daily_detail(_best_for(day), _shown_streak(day), saved_today)


## The tier of the daily that is saved for today, or else of the day's record, or else the
## player's tier, and never above the tiers run.json has (contract 14.8). A daily in progress
## keeps its own tier, so the buttons and the card always name the regions it covers.
func daily_tier() -> int:
	if game == null or game.run == null:
		return 0
	var day: String = today()
	var tier: int = progress.tier(game)
	var saved: SavedGame = saved_game(SavedGame.DAILY)
	if saved != null and not day.is_empty() and saved.run.day == day:
		tier = saved.run.tier
	elif daily_record != null and daily_record.day == day and not day.is_empty():
		tier = daily_record.tier
	return clampi(tier, 0, game.run.tiers.size())


## "Regions 1 to 6": what the daily covers (RULES 15). "" without run data.
func daily_regions() -> String:
	if game == null or game.run == null:
		return ""
	return RunCard.regions_text(RunCard.regions_last(game, daily_tier()))


## The phone's date as a day key such as "2026-10-24". "" when the date is not one a daily
## can use (before 2026 or after 2200), so no new daily starts (RULES 15).
func today() -> String:
	var date: Dictionary = date_source.call() if date_source.is_valid() else Time.get_date_dict_from_system()
	var key: String = RunSeeds.day_key(date)
	return key if RunSeeds.is_day_key(key) else ""


## The best daily result of this day, or {} for none. Another day's best is not shown.
func _best_for(day: String) -> Dictionary:
	if daily_record == null or daily_record.day != day:
		return {}
	return daily_record.best.duplicate()


## The streak the screens show: the saved one while its last day is today or yesterday.
func _shown_streak(day: String) -> int:
	if daily_record == null:
		return 0
	return Daily.shown_streak(daily_record.streak, daily_record.streak_day, day)


## "Level 1-2, The Fork. Wave 3 of 8." for the Continue card. A Twist says so: "Level 1-2 Twist".
## A run says "Roguelite run. Wave 3 of 18." and a daily "Daily 2026-10-24. Wave 3 of 18.".
func _saved_text(saved: SavedGame) -> String:
	if saved.mode != SavedGame.LEVEL:
		var head: String = "Daily %s" % saved.run.day if saved.mode == SavedGame.DAILY else "Roguelite run"
		return head + _progress_text(saved.battle)
	var level: LevelData = saved.battle.level
	var text: String = "Level %s, %s" % [CampaignText.number(game, saved.level_id), level.name]
	if saved.twist:
		text = "Level %s Twist, %s" % [CampaignText.number(game, saved.level_id), level.name]
	return text + _progress_text(saved.battle)


## ". Wave 3 of 8." or ". Ready to start.", then " Relaxed." on Relaxed.
func _progress_text(battle: Battle) -> String:
	var text: String = ". Ready to start."
	if battle.waves_started > 0:
		text = ". Wave %d of %d." % [BattleText.wave_number(battle), battle.wave_count()]
	if battle.relaxed:
		text += " Relaxed."
	return text


func open_info() -> void:
	push_screen(InfoScreen.new(rules, names, InfoContent.from_game(game)))


func open_about() -> void:
	var screen: AboutScreen = AboutScreen.new()
	screen.license_requested.connect(open_license)
	push_screen(screen)


## The license reader for one About row (a LicenseText kind).
func open_license(kind: StringName) -> void:
	var titles: Dictionary[StringName, String] = {
		LicenseText.FORKLINE: "Forkline",
		LicenseText.GODOT: "Godot Engine",
		LicenseText.FONT: "Outfit font",
	}
	push_screen(LicenseViewer.new(titles.get(kind, "License"), LicenseText.build(kind)))


# Modals.

func open_settings() -> void:
	var panel: SettingsPanel = SettingsPanel.new(sound_on, music_on)
	panel.sound_changed.connect(_on_sound_changed)
	panel.music_changed.connect(_on_music_changed)
	panel.about_requested.connect(open_about)
	open_modal(panel)


## Shows a modal above everything. It frees itself from here when it closes.
func open_modal(modal: Modal) -> void:
	_modals.append(modal)
	_modal_layer.add_child(modal)
	modal.closed.connect(_modal_closed.bind(modal))
	modal.apply_layout(_window, _safe)


func _modal_closed(modal: Modal) -> void:
	if not _modals.has(modal):
		return
	_modals.erase(modal)
	_modal_layer.remove_child(modal)
	_discard(modal)


## Closes every modal, the top one first.
func close_all_modals() -> void:
	for modal: Modal in _modals.duplicate():
		modal.closed.emit()
	_hidden_depth = -1
	_modal_layer.visible = true


## The sound toggle (the master switch, sound effects and music together), from Settings or the
## level's sound button: kept in Settings, saved, applied to the AudioService, and shown on the
## level's button. The music setting is not touched.
func _on_sound_changed(on: bool) -> void:
	sound_on = on
	if settings != null:
		settings.sound_on = on
		if store != null and not store.save_settings(settings):
			_log_save_failure()
	if audio != null:
		audio.set_enabled(on)
	_show_sound_state()
	sound_changed.emit(on)


## The music toggle, from Settings: kept in Settings, saved, applied to the AudioService.
func _on_music_changed(on: bool) -> void:
	music_on = on
	if settings != null:
		settings.music_on = on
		if store != null and not store.save_settings(settings):
			_log_save_failure()
	if audio != null:
		audio.set_music_on(on)
	music_changed.emit(on)


## Tells the level on screen whether the sound is on.
func _show_sound_state() -> void:
	if _battle_screen != null:
		_battle_screen.set_sound_state(sound_on)


# Back button.

## Does what the back button does and says what it did: &"modal" (closed or
## answered the top modal, or opened Pause in a battle), &"page" (went back one
## page), or &"quit" (nothing left to close; the caller quits).
func handle_back() -> StringName:
	if damaged:
		return &"quit"
	if not _modals.is_empty() and _modal_layer.visible:
		_modals.back().request_close()
		return &"modal"
	if not _end.is_empty():
		_show_end()
		return &"modal"
	if _battle_screen != null and current_screen() == _battle_screen:
		# One press, one step: an open panel closes first, then the next press opens Pause.
		if not _battle_screen.close_panel_for_back():
			_battle_screen.pause()
		return &"modal"
	if _stack.size() > 1:
		pop_screen()
		return &"page"
	return &"quit"


## The one entry for a back press from the phone (the go-back notification) or from a
## keyboard (ui_cancel). If both ever arrive for one press, the second is ignored, so a
## press does exactly one step.
func _back_pressed() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_back_ms < BACK_GUARD_MS:
		return
	_last_back_ms = now
	if handle_back() == &"quit":
		_quit()


func _quit() -> void:
	leave_app()
	get_tree().quit()


# Layout.

## Lays every screen and panel out for a window of this size. The App calls it
## on every resize; tests call it directly.
func apply_layout(window: Vector2, safe: Rect2) -> void:
	_window = window
	_safe = safe
	for screen: ScreenFrame in _stack.duplicate():
		screen.apply_layout(window, safe)
	for modal: Modal in _modals.duplicate():
		modal.apply_layout(window, safe)


func _on_viewport_resized() -> void:
	var viewport: Viewport = get_viewport()
	apply_layout(viewport.get_visible_rect().size, Layout.safe_rect(viewport))


func _full_rect_control() -> Control:
	var c: Control = Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Frees a node that has been taken off the screen: at the end of the frame
## when the app is running. With no running scene tree (tests) the node waits in
## the trash and goes when the App itself is freed.
func _discard(node: Node) -> void:
	if is_inside_tree():
		node.queue_free()
	else:
		_trash.append(node)


# Saving (flow step 4, docs/ARCHITECTURE.md 5.1).

## The app is being left: home, another app, a call, a close. A wave that is running
## is paused first, then the game is saved at that exact moment.
func leave_app() -> void:
	if _active == null:
		return
	if _battle_screen != null and _battle_screen.pause_for_leave():
		return
	save_active()


## Saves the game on screen at this moment, and remembers it for the Continue card.
func save_active() -> void:
	if _active == null or store == null or not _active.can_save():
		return
	if store.save_game(_active):
		_remember(_active)
	else:
		_log_save_failure()


## Saves the progress (stars, Twists, first sights) and refreshes the star count.
func save_progress() -> void:
	if store != null and progress != null and not store.save_progress(progress):
		_log_save_failure()
	if progress != null:
		_refresh_progress()


func _log_save_failure() -> void:
	if not _save_failed:
		_save_failed = true
		push_warning("Forkline: a save could not be written. The game goes on.")


## Keeps the saved game in the list: one per mode, the most recent first.
func _remember(saved: SavedGame) -> void:
	_forget(saved.mode)
	saved_games.insert(0, saved)
	saved_games.sort_custom(func(a: SavedGame, b: SavedGame) -> bool: return a.order > b.order)


func _forget(mode: StringName) -> void:
	for i: int in range(saved_games.size() - 1, -1, -1):
		if saved_games[i].mode == mode:
			saved_games.remove_at(i)


func saved_game(mode: StringName) -> SavedGame:
	for saved: SavedGame in saved_games:
		if saved.mode == mode:
			return saved
	return null


## Ends the saved game of a mode, as if it were abandoned: deleted, nothing recorded.
func _end_saved(mode: StringName) -> void:
	if store != null:
		store.delete_game(mode)
	_forget(mode)


# The flow (flow steps 2, 3 and 5).

func _on_continue() -> void:
	if damaged or _battle_screen != null or saved_games.is_empty():
		return
	resume_game(saved_games[0])


func _on_campaign() -> void:
	if damaged:
		return
	var screen: LevelSelect = LevelSelect.new()
	_fill_levels(screen)
	screen.level_chosen.connect(open_level_card)
	push_screen(screen)


func _fill_levels(screen: LevelSelect) -> void:
	var saved: SavedGame = saved_game(SavedGame.LEVEL)
	screen.populate(game, progress, saved.level_id if saved != null else &"")


## Pushes the card of an open level.
func open_level_card(id: StringName) -> void:
	if damaged or not game.levels.has(id) or not progress.level_open(game, id):
		return
	var saved: SavedGame = saved_game(SavedGame.LEVEL)
	var is_saved: bool = saved != null and saved.level_id == id
	var card: LevelCard = LevelCard.new(game, progress, id, is_saved, is_saved and saved.battle.relaxed, is_saved and saved.twist)
	card.play_requested.connect(request_start.bind(id))
	card.twist_requested.connect(request_start.bind(id, true))
	card.resume_requested.connect(func() -> void: resume_game(saved_game(SavedGame.LEVEL)))
	card.twist_resume_requested.connect(func() -> void: resume_game(saved_game(SavedGame.LEVEL)))
	push_screen(card)


## Starts a level, or its Twist. A saved level game ends first, and asks before it does.
func request_start(relaxed: bool, id: StringName, twist: bool = false) -> void:
	var saved: SavedGame = saved_game(SavedGame.LEVEL)
	if saved == null:
		start_level(id, relaxed, twist)
		return
	var dialog: ConfirmDialog = ConfirmDialog.new("Start a new game?",
		"Your saved game on %s ends. Nothing from it is recorded." % _saved_name(saved),
		"Start new game", "Keep saved game")
	dialog.confirmed.connect(func() -> void: start_level(id, relaxed, twist))
	open_modal(dialog)


## "level 1-2" or "the Twist of level 1-2", for the question above.
func _saved_name(saved: SavedGame) -> String:
	if saved.twist:
		return "the Twist of level %s" % CampaignText.number(game, saved.level_id)
	return "level %s" % CampaignText.number(game, saved.level_id)


## Starts a fresh level, or its Twist with the Twist's effects (docs/ARCHITECTURE.md 3.6). A Twist
## needs the level's three stars. Any saved level game is ended first.
func start_level(id: StringName, relaxed: bool, twist: bool = false) -> void:
	if damaged or _battle_screen != null or not game.levels.has(id):
		return
	var level: LevelData = game.levels[id]
	var effects: Array[Dictionary] = [] as Array[Dictionary]
	if twist:
		if level.twist_effects.is_empty() or not progress.twist_open(id):
			return
		effects = level.twist_effects
	var battle: Battle = Battle.create(level, game.catalog, relaxed, effects)
	if battle == null:
		return
	_end_saved(SavedGame.LEVEL)
	var saved: SavedGame = SavedGame.new()
	saved.mode = SavedGame.LEVEL
	saved.level_id = id
	saved.twist = twist
	saved.battle = battle
	_begin(saved, false)


## Opens a saved game on the Pause menu, at the exact moment it was left.
func resume_game(saved: SavedGame) -> void:
	if saved == null or _battle_screen != null or damaged:
		return
	_begin(saved, true)


func _begin(saved: SavedGame, resumed: bool) -> void:
	_active = saved
	_end = {}
	if probe == null and OS.is_debug_build():
		probe = PerfProbe.new()
		add_child(probe)
	var screen: BattleScreen = BattleScreen.new()
	screen.info_requested.connect(open_info)
	screen.settings_requested.connect(open_settings)
	screen.modal_requested.connect(open_modal)
	screen.probe = probe
	screen.save_requested.connect(save_active)
	screen.progress_changed.connect(save_progress)
	screen.ended.connect(_on_battle_ended)
	screen.restart_confirmed.connect(_on_battle_restart)
	screen.left.connect(_on_battle_left)
	screen.sound_changed.connect(_on_sound_changed)
	_battle_screen = screen
	push_screen(screen)
	screen.setup(saved.battle, audio, progress, region_of(saved))
	screen.set_sound_state(sound_on)
	if saved.run != null:
		screen.set_run(saved.run)
	audio.set_music(&"battle")
	if resumed:
		screen.pause()
	else:
		save_active()


## The ground a saved game is played on (docs/ARCHITECTURE.md 14.11): the campaign region that holds
## its level or Twist, and &"" for a run or daily, whose ground comes from the map's own features.
func region_of(saved: SavedGame) -> StringName:
	if saved.run != null:
		return &""
	for region: Dictionary in game.campaign:
		if (region["levels"] as Array).has(saved.level_id):
			return region["id"]
	return &""


## "Restart" in Pause, after its question (RULES 4.10, 14.7). The game on screen ends and the
## same one starts again, on the same difficulty, at 1x. A campaign level or Twist records
## nothing, as when it is abandoned. A run or daily counts as lost at its current wave and
## records what an ended run records, then a new run starts (the daily starts again for the
## day it belongs to, at its tier).
func _on_battle_restart() -> void:
	var saved: SavedGame = _active
	if saved == null:
		return
	_active = null
	_end = {}
	close_all_modals()
	if saved.run != null:
		_record_run(saved.run)
	_end_saved(saved.mode)
	if _battle_screen != null and current_screen() == _battle_screen:
		pop_screen()
	if saved.run == null:
		start_level(saved.level_id, saved.battle.relaxed, saved.twist)
	elif saved.run.daily:
		if not damaged and _battle_screen == null and RUNS_BUILT and runs_open:
			_begin_daily(saved.run.day, saved.run.tier)
	else:
		start_run(saved.battle.relaxed)


## "Back to menu" in Pause: the game stays saved.
func _on_battle_left() -> void:
	save_active()
	_active = null
	_leave_to_front_door()


func _leave_to_front_door() -> void:
	close_all_modals()
	_end = {}
	_battle_screen = null
	while _stack.size() > 1:
		pop_screen()
	if audio != null:
		audio.set_music(&"menu")


## The level was won, lost or abandoned (flow step 5).
func _on_battle_ended(result: Dictionary) -> void:
	var saved: SavedGame = _active
	if saved == null:
		return
	_active = null
	_end_saved(saved.mode)
	if saved.run != null:
		_run_ended(saved, bool(result.get("abandoned", false)))
		return
	if bool(result.get("abandoned", false)):
		_leave_to_front_door()
		return
	var id: StringName = saved.level_id
	var previous: int = progress.levels.get(id, 0)
	if bool(result.get("won", false)):
		if saved.twist:
			# A won Twist is cleared on either difficulty and earns no stars (RULES 13).
			progress.record_twist(id)
		else:
			progress.record_level(id, int(result.get("stars", 0)))
		save_progress()
	_end = {"result": result, "level": id, "previous": previous, "twist": saved.twist}
	_end_wait = end_delay
	if end_delay <= 0.0 or not is_inside_tree():
		_show_end()
	else:
		set_process(true)


func end_pending() -> bool:
	return not _end.is_empty()


func _show_end() -> void:
	if _end.is_empty():
		return
	var pending: Dictionary = _end
	_end = {}
	set_process(false)
	close_all_modals()
	if pending.has("run"):
		_show_run_end(pending)
		return
	var id: StringName = pending["level"]
	var result: Dictionary = pending["result"]
	var twist: bool = bool(pending.get("twist", false))
	result["twist"] = twist
	# A Twist leads nowhere new: no next level, only a replay or the list.
	var next_id: StringName = &"" if twist else CampaignText.next_level(game, id)
	var panel: EndPanel = EndPanel.new(game, id, result, int(pending["previous"]), next_id)
	panel.next_requested.connect(_end_next.bind(id))
	panel.retry_requested.connect(_end_retry.bind(id, bool(result.get("relaxed", false)), twist))
	panel.levels_requested.connect(_end_levels)
	open_modal(panel)
	if audio != null and bool(result.get("won", false)):
		audio.play_ui(&"star")


func _end_levels() -> void:
	_show_levels()


func _end_next(id: StringName) -> void:
	_show_levels()
	var next: StringName = CampaignText.next_level(game, id)
	if next != &"":
		open_level_card(next)


func _end_retry(id: StringName, relaxed: bool, twist: bool = false) -> void:
	if _battle_screen != null and current_screen() == _battle_screen:
		pop_screen()
	start_level(id, relaxed, twist)


# Runs and the daily (flow steps 2, 3 and 5; RULES 14, 15).

func _on_roguelite() -> void:
	open_run_card(false)


func _on_daily() -> void:
	open_run_card(true)


## Pushes the card before a run or the daily. It needs the stars of RULES 16.
func open_run_card(daily: bool) -> void:
	if damaged or _battle_screen != null or not RUNS_BUILT or not runs_open:
		return
	var mode: StringName = SavedGame.DAILY if daily else SavedGame.RUN
	var day: String = today() if daily else ""
	var saved: SavedGame = saved_game(mode)
	var card: RunCard = RunCard.new(game, game.run, daily, day, _best_for(day) if daily else {}, _shown_streak(day) if daily else 0,
		_saved_run_line(saved), saved != null and saved.battle.relaxed, daily_regions() if daily else "")
	card.start_requested.connect(request_start_run.bind(daily))
	card.resume_requested.connect(func() -> void: resume_game(saved_game(mode)))
	push_screen(card)


## "Your saved run is on wave 4 of 18." for the run card, or "" when no game is saved.
func _saved_run_line(saved: SavedGame) -> String:
	if saved == null:
		return ""
	var what: String = "run"
	if saved.mode == SavedGame.DAILY:
		what = "daily" if saved.run.day == today() else "daily from %s" % saved.run.day
	if saved.battle.waves_started == 0:
		return "Your saved %s is ready to start." % what
	return "Your saved %s is on wave %d of %d." % [what, BattleText.wave_number(saved.battle), saved.battle.wave_count()]


## Starts a run or the daily. A saved game of that mode ends first, after a question, and it
## counts as lost at its current wave (RULES 14.7), so starting over never dodges a loss.
func request_start_run(relaxed: bool, daily: bool) -> void:
	var saved: SavedGame = saved_game(SavedGame.DAILY if daily else SavedGame.RUN)
	if saved == null:
		_start_mode(daily, relaxed)
		return
	var what: String = "daily" if daily else "run"
	var dialog: ConfirmDialog = ConfirmDialog.new("Start a new %s?" % what,
		"Your saved %s ends now and counts as lost on its current wave." % what,
		"Start new %s" % what, "Keep saved game")
	dialog.confirmed.connect(func() -> void:
		if _battle_screen != null or saved_game(saved.mode) != saved:
			return
		_record_run(saved.run)
		_end_saved(saved.mode)
		_start_mode(daily, relaxed))
	open_modal(dialog)


func _start_mode(daily: bool, relaxed: bool) -> void:
	if daily:
		start_daily()
	else:
		start_run(relaxed)


## Starts a normal run: a fresh seed and the pool the progress unlocked. Any saved run is
## ended by the caller first.
func start_run(relaxed: bool = false) -> void:
	if damaged or _battle_screen != null or not RUNS_BUILT or not runs_open:
		return
	var tier: int = clampi(progress.tier(game), 0, game.run.tiers.size())
	var pool: Array[StringName] = game.run.pool(progress.unlock_counters(), tier)
	_begin_run(RunSession.start(_new_seed(), "", relaxed, pool, game.run, game.catalog, tier), SavedGame.RUN)


## Starts today's daily: the seed is the phone's date, always Normal, with every card in the pool.
## It does nothing when the date is no good (the card says so).
func start_daily() -> void:
	if damaged or _battle_screen != null or not RUNS_BUILT or not runs_open:
		return
	var day: String = today()
	if day.is_empty():
		return
	_begin_daily(day, daily_tier())


## Starts the daily of `day` at `tier`: always Normal, every card of the tier in the pool.
func _begin_daily(day: String, tier: int) -> void:
	_begin_run(RunSession.start(RunSeeds.daily_seed(day), day, false, game.run.card_ids(tier), game.run, game.catalog, tier), SavedGame.DAILY)


## A run that could not be made means the bundled files are broken (docs/ARCHITECTURE.md 3.4).
func _begin_run(session: RunSession, mode: StringName) -> void:
	if session == null:
		_show_damaged()
		return
	_end_saved(mode)
	var saved: SavedGame = SavedGame.new()
	saved.mode = mode
	saved.battle = session.battle
	saved.run = session
	_begin(saved, false)


func _new_seed() -> int:
	if seed_source.is_valid():
		return int(seed_source.call())
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.randomize()
	return int(generator.randi())


## A run or daily ended: won, lost or abandoned. The counters and the daily record are
## written, and a won or lost one shows its end panel.
func _run_ended(saved: SavedGame, abandoned: bool) -> void:
	var run: RunSession = saved.run
	var outcome: Dictionary = _record_run(run)
	if abandoned:
		_leave_to_front_door()
		return
	_end = {"run": outcome, "relaxed": saved.battle.relaxed, "daily": run.daily, "day": run.day}
	_end_wait = end_delay
	if end_delay <= 0.0 or not is_inside_tree():
		_show_end()
	else:
		set_process(true)


## Records a finished run (flow step 5, RULES 14.6, 15): the highest wave reached, the wins,
## and for a daily the count, the day's best and the streak. An abandoned run counts as lost
## at its current wave, which is what `result()` says of it. Returns that result.
func _record_run(run: RunSession) -> Dictionary:
	var outcome: Dictionary = run.result()
	progress.raise(&"best_run_wave", int(outcome["reached"]))
	if bool(outcome["won"]):
		progress.bump(&"runs_won", 1)
		if not run.battle.relaxed:
			progress.bump(&"runs_won_normal", 1)
		if int(outcome["risks"]) >= 3:
			progress.bump(&"risky_wins", 1)
	if run.daily:
		progress.bump(&"dailies_finished", 1)
		daily_record.record_finish(run.day, {"won": outcome["won"], "waves": outcome["waves"], "lives": outcome["lives"]}, run.tier)
		if store != null and not store.save_daily(daily_record):
			_log_save_failure()
	save_progress()
	return outcome


func _show_run_end(pending: Dictionary) -> void:
	var outcome: Dictionary = pending["run"]
	var daily: bool = bool(pending.get("daily", false))
	var relaxed: bool = bool(pending.get("relaxed", false))
	var day: String = String(pending.get("day", ""))
	var best: Dictionary = {}
	var streak: int = 0
	var now: String = ""
	if daily:
		best = _best_for(day)
		now = today()
		streak = _shown_streak(now if not now.is_empty() else day)
	var panel: RunEndPanel = RunEndPanel.new(game, outcome, relaxed, day, best, streak, now)
	panel.retry_requested.connect(_run_retry.bind(daily, relaxed))
	panel.menu_requested.connect(_run_menu)
	open_modal(panel)
	if audio != null and bool(outcome.get("won", false)):
		audio.play_ui(&"star")


func _run_retry(daily: bool, relaxed: bool) -> void:
	if _battle_screen != null and current_screen() == _battle_screen:
		pop_screen()
	_start_mode(daily, relaxed)


## Back to the mode screen, where the Daily button shows the new best and streak.
func _run_menu() -> void:
	_leave_to_front_door()
	open_mode()


## The front door, the mode screen and the level list, with the lists up to date.
func _show_levels() -> void:
	_battle_screen = null
	while _stack.size() > 1:
		pop_screen()
	if audio != null:
		audio.set_music(&"menu")
	open_mode()
	_on_campaign()
