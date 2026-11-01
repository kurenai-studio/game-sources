extends Control
## The shell: loads the campaign and progress once, shows one screen at a time, and handles the
## Android back button. Screens never know about each other; they ask to navigate by name.

const SCREENS := {
	"home": "res://scenes/home.tscn",
	"worlds": "res://scenes/worlds.tscn",
	"world": "res://scenes/world.tscn",
	"play": "res://scenes/play.tscn",
	"sign_in": "res://scenes/sign_in.tscn",
	"account": "res://scenes/account.tscn",
	"how_to_play": "res://scenes/how_to_play.tscn",
	"load_error": "res://scenes/load_error.tscn",
	"update_required": "res://scenes/update_required.tscn",
	"settings": "res://scenes/settings.tscn",
	"profile": "res://scenes/profile.tscn",
	"badges": "res://scenes/badges.tscn",
	"leaderboard": "res://scenes/leaderboard.tscn",
	"daily": "res://scenes/daily.tscn",
}

var _state: AppState
var _screen: ScreenBase
## Debug screenshots: kept here because a Callable does not keep its object alive.
var _shot_servers: Array[ShotServer] = []


func _ready() -> void:
	var options := _debug_options()
	# Screenshots use a clean store of their own, never the player's real files.
	var store := ProgressStore.new(
		"user://progress_shot.json" if options.has("shot") else "user://progress.json"
	)
	if not options.has("shot"):
		store.load_data()
	if options.has("shot"):
		# Screenshots always use the bundled levels, never whatever is cached on this machine.
		_state = AppState.new(
			Campaign.load_bundled(), store, ContentStore.new("user://content_shot")
		)
		_debug_screenshot(options)
		return
	var api := ApiClient.new()
	add_child(api)
	_state = AppState.new(Campaign.load_bundled(), store, ContentStore.new(), api)
	_state.feedback = Feedback.new(store.settings)
	add_child(_state.feedback)
	var account := Account.new()
	account.load_data()
	_state.account = account
	_state.account_client = AccountClient.new(account, api.send_json)
	_state.account_sync = AccountSync.new(_state.account_client, store)
	add_child(_state.account_sync)
	_state.social = SocialClient.new(_state.account_client)
	_state.daily = DailyStore.new()
	_state.daily.load_data()
	_state.request_sync()
	for message in _state.campaign.errors:
		push_warning(message)
	_show("home", {})
	_state.refresh_content()
	if _state.has_social():
		_state.refresh_daily()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _screen != null:
		_screen.go_back()


func _show(target: String, args: Dictionary) -> void:
	_state.apply_theme()
	if _screen != null and _screen.get_parent() != null:
		_screen.get_parent().remove_child(_screen)
		_screen.queue_free()
	var packed: PackedScene = load(SCREENS[target])
	_screen = packed.instantiate()
	_screen.setup(_state, args)
	_screen.navigate.connect(_on_navigate)
	add_child(_screen)


func _on_navigate(target: String, args: Dictionary) -> void:
	_show.call_deferred(target, args)


# ----- debug screenshots (not available in release builds) -----
# godot --path apps/game -- --shot=out.png --screen=play --level=the-wall --theme=dark
#   --size=390x844 --program=MMLMM --steps=-1 --done=3
# Renders one screen into an off-screen viewport of the given size, saves a PNG, and quits.
# The social screens use canned answers (ShotServer, no network): --account=you@example.com signs
# a player in; --fake=ok|offline|empty|notopted|off_page|error picks the situation; --cached
# loads the daily first and then goes offline; --daily=DATE plays the daily of that date;
# --daily-slots=N, --streak=CURRENT,BEST, --newbadges=1 and --period=week fill in the rest.


func _debug_options() -> Dictionary:
	var options := {}
	if not OS.is_debug_build():
		return options
	for argument in OS.get_cmdline_user_args():
		var parts := argument.trim_prefix("--").split("=", true, 1)
		options[parts[0]] = parts[1] if parts.size() > 1 else ""
	return options


func _debug_screenshot(options: Dictionary) -> void:
	var dimensions := String(options.get("size", "390x844")).split("x")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	if options.has("account"):
		# Pretend a player is signed in (nothing is sent anywhere).
		var shot_account := Account.new("user://account_shot.json")
		shot_account.start(String(options["account"]), "shot-refresh-token")
		shot_account.last_sync_at = Time.get_unix_time_from_system() - 120.0
		_state.account = shot_account
	await _fake_social(options)
	_state.progress.settings.set_theme(String(options.get("theme", "light")))
	_state.progress.settings.set_reduce_motion(true)
	if options.has("look"):
		_state.progress.settings.set_look(String(options["look"]))
	for i in int(options.get("done", "0")):
		var entry: Dictionary = _state.campaign.entries[i]
		_state.progress.record_completion(entry["id"], int(entry["level"]["levelVersion"]), 5)
	_state.apply_theme()

	var target := String(options.get("screen", "home"))
	if target == "depth_kit":
		var sample := DepthKitSample.new()
		sample.set_anchors_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(sample)
		await _capture(viewport, options)
		return
	var packed: PackedScene = load(SCREENS[target])
	var screen: ScreenBase = packed.instantiate()
	var level_id := String(options.get("level", _state.campaign.entries[0]["id"]))
	if options.has("loops"):
		# Debug only: let this level offer REPEAT (no loop level is published yet), with a roomier limit.
		var level: Dictionary = _state.campaign.entry_by_id(level_id)["level"]
		level["availableCommands"].append("REPEAT")
		level["constraints"]["maxCommands"] = 12
	var screen_args := {
		"level_id": level_id,
		"world": int(options.get("world", "0")),
		"title": String(options.get("title", "Around the wall")),
		"scope": String(options.get("scope", "points")),
		"key": String(options.get("key", "")),
		"period": String(options.get("period", "all")),
	}
	if options.has("daily"):
		screen_args["daily"] = String(options["daily"])
	screen.setup(_state, screen_args)
	if target == "play":
		screen.persist = false
	viewport.add_child(screen)
	await get_tree().process_frame
	if target == "play" and options.has("program"):
		screen.debug_show(String(options["program"]), int(options.get("steps", "0")))
	if target == "play" and options.has("select"):
		PlayDebug.select(screen, int(options["select"]))
	if target == "play" and options.has("overlay"):
		PlayDebug.overlay(screen, String(options["overlay"]))
	await _capture(viewport, options)


## Waits for the controls to settle, saves the viewport as a PNG, and quits.
func _capture(viewport: SubViewport, options: Dictionary) -> void:
	# Controls settle their size over a few frames; wait before capturing.
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png(String(options["shot"]))
	get_tree().quit()


## Debug only: a signed-in or signed-out player and a server that answers from ShotServer.
func _fake_social(options: Dictionary) -> void:
	var level: Dictionary = _state.campaign.entry_by_id("first-turn")["level"]
	var online := ShotServer.new("ok", level)
	var server := ShotServer.new(String(options.get("fake", "ok")), level)
	_shot_servers.assign([online, server])
	_state.fetcher = server.fetch
	if _state.account == null:
		_state.account = Account.new("user://account_shot.json")
	_state.daily = DailyStore.new("user://daily_shot.json", "user://daily_shot")
	_state.daily.content.clear()
	if options.has("cached"):
		await _state.daily.refresh(online.fetch)
	_state.account_client = AccountClient.new(_state.account, server.send)
	_state.social = SocialClient.new(_state.account_client)
	var results := _state.progress.results
	if options.has("daily-slots"):
		results.daily_best[ShotServer.DATE] = {
			"levelSlug": "daily-elm", "slots": int(options["daily-slots"])
		}
	if options.has("streak"):
		var parts := String(options["streak"]).split(",")
		results.streak = {"current": int(parts[0]), "best": int(parts[parts.size() - 1])}
	if options.has("newbadges"):
		results.badges = ["First clear", "Daily start"]
	await _state.refresh_daily()
