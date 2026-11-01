class_name App extends Control
## The root of the game (docs/ARCHITECTURE.md section 11), scenes/ui/app.tscn.
## Creates GameConfig, Records, Settings, SaveService, AudioService and
## GameSession once and passes them down. Loads the profile and the saved
## run, routes between screens, applies the skin's theme, saves on
## save_requested and on lifecycle events, and handles the back button.
##
## Flow:
## - Start (flow 1, D-47): the profile loads first, before any listener is
##   connected. Then the saved run is loaded and checked (a broken one is
##   deleted) and folded into the records, and the splash shows, at every
##   launch. The valid run is held, untouched, until Play. A return from the
##   background is not a launch: nothing here runs again.
## - Play (flow 2): resumes the held run, or starts a new one when there is
##   none. Home on the end of run panel shows the splash again, with no run.
## - Saving: on save_requested, the run (only while one is in progress) and
##   the profile are queued, so SaveService writes them off the move's frame.
##   On app pause, focus loss and close, after the drag and targeting are
##   cancelled (GDD 13.1), they are written at once, after anything queued.
## - Run end: the saved run is deleted, the profile saved, EndPanel shown.
## - The show gate (QA6-06): the board shows a move only once SaveService is
##   idle, so the player never sees a move that is not on disk.
## - Info opens over the splash or Pause; About over the splash or Settings,
##   and a license text inside About (flow 11 and 12).
## - Back: cancel targeting; else close the top panel (an open license text
##   inside About first; closing Pause resumes); else on the play screen open
##   Pause; else (the splash, the end of run panel) quit after saving, which
##   leaves a held run saved as it was. On desktop, Escape does the same.
## - Skin switch: a new theme, apply_skin on every live screen and panel, and
##   a cross-fade from a still of the old look over the new skin's
##   skin_switch motion.

const GAME_SCENE: PackedScene = preload("res://scenes/ui/game_screen.tscn")
const SPLASH_SCENE: PackedScene = preload("res://scenes/ui/splash_screen.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/pause_panel.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_panel.tscn")
const CONFIRM_SCENE: PackedScene = preload("res://scenes/ui/confirm_dialog.tscn")
const END_SCENE: PackedScene = preload("res://scenes/ui/end_panel.tscn")
const INFO_SCENE: PackedScene = preload("res://scenes/ui/info_panel.tscn")
const ABOUT_SCENE: PackedScene = preload("res://scenes/ui/about_panel.tscn")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")

## Test seam: the save folder. Tests set a temp folder inside user:// before
## the App enters the tree. The game never changes it.
var save_folder: String = "user://"
## Test seam: when valid, called instead of quitting, so a test can see the
## quit without ending the test run. The game never sets it.
var quit_handler: Callable = Callable()

var config: GameConfig = null
var records: Records = null
var settings: Settings = null
var save: SaveService = null
var audio: AudioService = null
var session: GameSession = null
var skin: SkinData = null

var _screen_layer: Control = null
var _panel_layer: Control = null
var _game: GameScreen = null
var _splash: SplashScreen = null
## The valid saved run loaded at launch, held until Play (flow 1 and 2).
var _held_run: RunState = null
## Open panels, the top one last.
var _panels: Array[Control] = []
var _still: TextureRect = null
## True while saves of the run, or of the profile, keep failing, so each
## failure is logged once, not on every move (SEC-04: a file that cannot be
## opened blocks saves for the whole session).
var _run_save_failing: bool = false
var _profile_save_failing: bool = false


func _ready() -> void:
	start()


## Builds everything and shows the first screen. _ready calls it. Headless
## tests run before the scene tree starts, so they call it themselves. Safe
## to call twice: the second call does nothing.
func start() -> void:
	if session != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	config = GameConfig.new()
	records = Records.new()
	settings = Settings.new()
	save = SaveService.new(save_folder)
	save.load_profile(settings, records)
	skin = SkinCatalog.get_skin(settings.skin_id)
	if skin.id != settings.skin_id:
		settings.set_skin_id(skin.id)
	audio = AudioService.new()
	audio.name = "Audio"
	add_child(audio)
	audio.set_enabled(settings.sound_on)
	session = GameSession.new(config, null, records)
	theme = UiKit.build_theme(skin)
	_screen_layer = _layer("Screens")
	_panel_layer = _layer("Panels")

	settings.sound_changed.connect(_on_sound_changed)
	settings.skin_changed.connect(_on_skin_changed)
	session.save_requested.connect(_on_save_requested)
	session.run_ended.connect(_on_run_ended)
	if is_inside_tree():
		get_tree().quit_on_go_back = false

	# Flow 1: load and check the saved run (a broken one is deleted), fold it
	# into the records so the splash shows them up to date (GDD 15.1), and
	# hold it until Play. The splash shows at every launch.
	_held_run = save.load_run(config)
	if _held_run != null and records.update_from(_held_run):
		_queue_profile()
	_show_splash()


# Reads for tests.

func game_screen() -> GameScreen:
	return _game


func splash_screen() -> SplashScreen:
	return _splash


## True while the splash holds a saved run for Play.
func has_held_run() -> bool:
	return _held_run != null


## The open panels, the top one last.
func open_panels() -> Array[Control]:
	return _panels.duplicate()


func top_panel() -> Control:
	return _panels.back() if not _panels.is_empty() else null


# Screens.

func _show_game() -> void:
	if _splash != null:
		_screen_layer.remove_child(_splash)
		_splash.queue_free()
		_splash = null
	if _game != null:
		return
	_game = GAME_SCENE.instantiate() as GameScreen
	_game.name = "Game"
	_screen_layer.add_child(_game)
	_game.setup(session, settings, audio, skin)
	_game.board().set_show_gate(save.is_idle)
	_game.pause_requested.connect(open_pause)
	_sync_cover()


## Shows the splash anew, with its entrance (launch and Home).
func _show_splash() -> void:
	if _game != null:
		_screen_layer.remove_child(_game)
		_game.queue_free()
		_game = null
	if _splash == null:
		_splash = SPLASH_SCENE.instantiate() as SplashScreen
		_splash.name = "Splash"
		_screen_layer.add_child(_splash)
		_splash.play_chosen.connect(_on_play)
		_splash.info_chosen.connect(open_info)
		_splash.about_chosen.connect(open_about)
		_splash.settings_chosen.connect(open_settings)
	_splash.setup(skin, records)
	_splash.play_entrance()


## Flow 2: Play resumes the held run exactly, or starts a new one. Ignored
## while a panel covers the splash.
func _on_play() -> void:
	if _splash == null or not _panels.is_empty():
		return
	var held: RunState = _held_run
	_held_run = null
	if held == null:
		_start_new_game()
		return
	_show_game()
	session.resume(held)


func _start_new_game() -> void:
	_held_run = null
	_close_all_panels()
	_show_game()
	session.start_new_run()


# Panels.

func _open_panel(scene: PackedScene) -> Control:
	var panel: Control = scene.instantiate() as Control
	_panel_layer.add_child(panel)
	_panels.append(panel)
	_sync_cover()
	return panel


func _close_panel(panel: Control) -> void:
	if not _panels.has(panel):
		return
	_panels.erase(panel)
	panel.call(&"close")
	_sync_cover()


## The play screen's coffee button hides while any panel is open over it
## (GDD 15.5, DESIGN_SYSTEM.md 7.15).
func _sync_cover() -> void:
	if _game != null:
		_game.set_covered(not _panels.is_empty())


func _close_all_panels() -> void:
	while not _panels.is_empty():
		_close_panel(_panels.back())


## Opens Pause over the play screen (flow 9). The drag and targeting are
## cancelled first. Ignored when a panel is already open.
func open_pause() -> void:
	if _game == null or not _panels.is_empty():
		return
	_interrupt()
	var pause: PausePanel = _open_panel(PAUSE_SCENE) as PausePanel
	pause.setup(skin)
	pause.resume_chosen.connect(_close_panel.bind(pause))
	pause.new_game_chosen.connect(_ask_new_game)
	pause.settings_chosen.connect(open_settings)
	pause.info_chosen.connect(open_info)
	pause.play_in()


func open_settings() -> void:
	var panel: SettingsPanel = _open_panel(SETTINGS_SCENE) as SettingsPanel
	panel.setup(skin, settings)
	panel.closed.connect(_close_panel.bind(panel))
	panel.about_chosen.connect(open_about)
	panel.play_in()


## Flow 11 (D-44): Info over the splash or Pause. Only its buttons open it.
## Closing it returns to where it was opened; from Pause the run stays
## paused.
func open_info() -> void:
	if top_panel() is InfoPanel:
		return
	var panel: InfoPanel = _open_panel(INFO_SCENE) as InfoPanel
	panel.setup(skin)
	panel.closed.connect(_close_panel.bind(panel))
	panel.play_in()


## Flow 12: About over the splash or Settings. Its license rows open their
## texts inside it.
func open_about() -> void:
	if top_panel() is AboutPanel:
		return
	var panel: AboutPanel = _open_panel(ABOUT_SCENE) as AboutPanel
	panel.setup(skin)
	panel.closed.connect(_close_panel.bind(panel))
	panel.play_in()


## New game from Pause: asks first while a run is in progress (D-34).
func _ask_new_game() -> void:
	if not session.is_run_in_progress():
		_start_new_game()
		return
	var dialog: ConfirmDialog = _open_panel(CONFIRM_SCENE) as ConfirmDialog
	dialog.setup(skin, Copy.CONFIRM_TITLE, Copy.CONFIRM_BODY, Copy.NEW_GAME, Copy.CANCEL)
	dialog.confirmed.connect(_start_new_game)
	dialog.cancelled.connect(_close_panel.bind(dialog))
	dialog.play_in()


# Session events.

## A move resolved (D-33). The data is checked and encoded now; the files are
## written off this frame by SaveService's writer, well before the move's
## animation ends (QA4-02).
func _on_save_requested() -> void:
	if session.is_run_in_progress():
		_note_run_save(save.queue_run(session.state))
	_note_profile_save(save.queue_profile(settings, records))


## The run and the profile, written now after anything queued; the run only
## while one is in progress, so an ended run is never written again. For app
## pause, focus loss, close and quit, when the process may end at any moment.
func _save_all() -> void:
	if session.is_run_in_progress():
		_note_run_save(save.save_run(session.state))
	_note_profile_save(save.save_profile(settings, records))


## Logs the first of a row of failed run saves.
func _note_run_save(ok: bool) -> void:
	if not ok and not _run_save_failing:
		push_warning("App: the run could not be saved")
	_run_save_failing = not ok


## Logs the first of a row of failed profile saves.
func _note_profile_save(ok: bool) -> void:
	if not ok and not _profile_save_failing:
		push_warning("App: the profile could not be saved")
	_profile_save_failing = not ok


## Flow 6: delete the saved run, save the profile, show the end of run panel.
## delete_run waits for any queued write, so the ended run cannot come back.
func _on_run_ended(summary: RunSummary) -> void:
	save.delete_run()
	_queue_profile()
	_close_all_panels()
	var panel: EndPanel = _open_panel(END_SCENE) as EndPanel
	panel.setup(skin)
	panel.show_summary(summary)
	panel.new_game_chosen.connect(_start_new_game)
	panel.home_chosen.connect(_go_home)
	panel.play_in()


## Home on the end of run panel: the splash, with no run to hold.
func _go_home() -> void:
	_close_all_panels()
	_held_run = null
	_show_splash()


# Settings events.

func _on_sound_changed(on: bool) -> void:
	audio.set_enabled(on)
	_queue_profile()


func _queue_profile() -> void:
	_note_profile_save(save.queue_profile(settings, records))


func _on_skin_changed(skin_id: StringName) -> void:
	_cover_with_still()
	skin = SkinCatalog.get_skin(skin_id)
	theme = UiKit.build_theme(skin)
	if _game != null:
		_game.apply_skin(skin)
	if _splash != null:
		_splash.apply_skin(skin)
	for panel: Control in _panels:
		panel.call(&"apply_skin", skin)
	_fade_still()
	_queue_profile()


## A still of the current frame on top of everything, so the switch reads as
## one cross-fade (ARCHITECTURE.md section 12). Skipped where nothing renders.
func _cover_with_still() -> void:
	if _still != null:
		_still.queue_free()
		_still = null
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return
	_still = TextureRect.new()
	_still.name = "SkinSwitchStill"
	_still.texture = ImageTexture.create_from_image(image)
	_still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_still.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_still.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_still)


func _fade_still() -> void:
	if _still == null:
		return
	var still: TextureRect = _still
	var tween: Tween = Motion.tween_for(still, skin, &"skin_switch")
	tween.tween_property(still, "modulate:a", 0.0, skin.duration(&"skin_switch"))
	tween.tween_callback(still.queue_free)
	_still = null


# Lifecycle and the back button.

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			# Nothing queued is lost when the App goes away.
			if save != null:
				save.flush()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			if session != null:
				_interrupt()
				_save_all()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if session != null:
				_on_back()


## QA4-05: on desktop, Escape does what Android's back button does (flow 10),
## so Pause can be reached while the offer hides the HUD. Android sends its
## back button as NOTIFICATION_WM_GO_BACK_REQUEST and never takes this path.
func _unhandled_key_input(event: InputEvent) -> void:
	if session == null or OS.has_feature("android"):
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	_on_back()


## Drops a drag and targeting with no penalty (GDD 13.1).
func _interrupt() -> void:
	if _game != null:
		_game.board().cancel_drag()
	session.cancel_targeting()


## Flow 10: cancel targeting; else close the top panel (ConfirmDialog, an
## open license text inside AboutPanel, AboutPanel, InfoPanel,
## SettingsPanel, PausePanel, where closing Pause resumes); else on the play
## screen (offer included) open Pause; else, on the splash or the end of run
## panel, quit after saving. A held run is not in progress, so its file stays
## exactly as it was.
func _on_back() -> void:
	if session.targeting_booster() != &"":
		session.cancel_targeting()
		return
	var top: Control = top_panel()
	if top is AboutPanel and (top as AboutPanel).close_license():
		return
	if top is ConfirmDialog or top is AboutPanel or top is InfoPanel or top is SettingsPanel or top is PausePanel:
		_close_panel(top)
		return
	if top == null and _game != null:
		open_pause()
		return
	_save_all()
	if quit_handler.is_valid():
		quit_handler.call()
	elif is_inside_tree():
		get_tree().quit()


func _layer(layer_name: String) -> Control:
	var layer: Control = Control.new()
	layer.name = layer_name
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	return layer
