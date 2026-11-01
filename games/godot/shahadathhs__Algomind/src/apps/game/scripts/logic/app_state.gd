class_name AppState
extends RefCounted
## What every screen shares: the campaign, local progress, downloaded content, and the theme.
##
## The campaign always comes from the device: the levels last downloaded from the API when there
## are any, otherwise the ones bundled with the game. `refresh_content` asks the API for newer
## levels in the background; the game is fully playable without it.

## Emitted when the campaign or the download status changed.
signal content_changed

var campaign: Campaign
var progress: ProgressStore
var content: ContentStore
var api: ApiClient
## Sound, music, and vibration; null in tests and screenshots, where the helpers do nothing.
var feedback: Feedback
## The optional account and its sync; null in tests and screenshots.
var account: Account
var account_client: AccountClient
var account_sync: AccountSync
## Profile, boards, badges, and share links (needs an account); null in tests.
var social: SocialClient
## The daily challenges kept on the device; null in tests.
var daily: DailyStore
## Replaces the API for public reads in debug screenshots: Callable(path) -> result.
var fetcher: Callable
## "bundled" or "downloaded": where the current campaign came from.
var source := "bundled"
## "idle", "loading", "updated", "unchanged", "offline", "disabled", or "invalid".
var sync_status := "idle"
## Why individual levels were skipped, from the last campaign build and the last download.
var sync_errors: Array[String] = []

var _bundled: Campaign


func _init(
	bundled_campaign: Campaign,
	store: ProgressStore,
	content_store: ContentStore = null,
	api_client: ApiClient = null
) -> void:
	_bundled = bundled_campaign
	campaign = bundled_campaign
	progress = store
	content = content_store if content_store != null else ContentStore.new()
	api = api_client
	_use_best_campaign()


## Whether the player is signed in on this device.
func signed_in() -> bool:
	return account != null and account.signed_in()


## Asks for progress to be synced soon. Does nothing when signed out.
func request_sync() -> void:
	if account_sync != null:
		account_sync.request()


## Whether the social features (daily, boards, profile, badges) exist in this build: not in the
## browser try-out, which is offline-only.
func has_social() -> bool:
	return not OS.has_feature("web") and (fetcher.is_valid() or (api != null and api.is_enabled()))


## A public read of the API (see ApiClient.fetch_json), or a canned one in debug screenshots.
func fetch_public(path: String) -> Dictionary:
	if fetcher.is_valid():
		return await fetcher.call(path)
	if api == null:
		return {"ok": false, "status": 0, "json": null, "error": "disabled"}
	return await api.fetch_json(path)


## Brings the cached daily challenges up to date. The game plays them offline from the cache.
func refresh_daily() -> Dictionary:
	if daily == null:
		return {"status": "disabled", "errors": []}
	return await daily.refresh(fetch_public)


## Plays a named sound effect when sound is on.
func sfx(effect: String) -> void:
	if feedback != null:
		feedback.play(effect)


## A short vibration when vibration is on.
func haptic(milliseconds: int) -> void:
	if feedback != null:
		feedback.buzz(milliseconds)


func is_dark() -> bool:
	match progress.settings.theme():
		"dark":
			return true
		"light":
			return false
		_:
			return DisplayServer.is_dark_mode()


func apply_theme() -> void:
	var depth := progress.settings.look() == Settings.LOOK_DEPTH
	UiLook.depth = depth
	UiLook.animate = not progress.settings.reduce_motion()
	Palette.apply(is_dark(), depth)
	DepthPalette.apply(is_dark())


## Downloads newer levels in the background, then rebuilds the campaign from the device.
func refresh_content() -> void:
	if api == null or not api.is_enabled():
		sync_status = "disabled"
		content_changed.emit()
		return
	sync_status = "loading"
	content_changed.emit()
	var result: Dictionary = await ContentSync.refresh(api.fetch_json, content)
	sync_status = str(result["status"])
	print(
		(
			"[algomind] content sync: %s, %d level(s) updated, %d problem(s)"
			% [sync_status, int(result["updated"]), (result["errors"] as Array).size()]
		)
	)
	sync_errors.clear()
	for message: Variant in result["errors"]:
		sync_errors.append(str(message))
	_use_best_campaign()
	content_changed.emit()


## Levels the downloaded campaign had to skip (an older game cannot play them).
func skipped_count() -> int:
	return campaign.errors.size() if source == "downloaded" else 0


func _use_best_campaign() -> void:
	var downloaded := ContentSync.build_campaign(content)
	if downloaded.entries.is_empty():
		campaign = _bundled
		source = "bundled"
	else:
		campaign = downloaded
		source = "downloaded"
