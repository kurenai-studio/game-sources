class_name AccountSync
extends Node
## Decides when progress is synced and shows the state to the screens. Sync runs after sign-in,
## after a level is solved, after a synced setting changes, and when the app starts; a failure
## is retried with growing waits (30 s up to 15 min) for as long as the app runs, which also
## covers the connection coming back. Signed out, `request` does nothing at all.

signal changed

const FIRST_RETRY_SECONDS := 30.0
const MAX_RETRY_SECONDS := 900.0

## Seconds a request waits so several close together become one sync.
var debounce_seconds := 2.0
## "idle", "syncing", "synced", "offline", "failed", or "signed_out".
var status := "idle"
var message := ""

var _client: AccountClient
var _progress: ProgressStore
var _timer: Timer
var _wait := FIRST_RETRY_SECONDS
var _running := false
## A sync was requested while one was running; it runs as soon as that one ends.
var _pending := false


func _init(client: AccountClient = null, store: ProgressStore = null) -> void:
	_client = client
	_progress = store


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(sync_now)
	add_child(_timer)


## Asks for a sync soon; several requests close together become one.
func request() -> void:
	if _client == null or not _client.account.signed_in() or _timer == null:
		return
	if _running:
		_pending = true
		return
	_timer.start(debounce_seconds)


## Syncs now. Returns when it is done.
func sync_now() -> void:
	if _client == null:
		return
	if _running:
		_pending = true
		return
	_running = true
	status = "syncing"
	message = ""
	changed.emit()
	var result := await ProgressSync.run(_client, _progress)
	_running = false
	status = str(result["status"])
	message = str(result["message"])
	if status == "synced":
		_wait = FIRST_RETRY_SECONDS
	elif status in ["offline", "failed"] and _timer != null:
		_timer.start(_wait)
		_wait = minf(_wait * 2.0, MAX_RETRY_SECONDS)
	if _pending and status == "synced" and _timer != null:
		# What changed during the sync is not in it; send it now.
		_pending = false
		_timer.start(debounce_seconds)
	else:
		_pending = false
	changed.emit()


## Forget the state after signing out or deleting the account.
func reset() -> void:
	if _progress != null:
		# The points were the old account's; programs still waiting stay for the next sign-in.
		_progress.results.clear_points()
		_progress.results.save()
	status = "signed_out"
	message = ""
	_wait = FIRST_RETRY_SECONDS
	if _timer != null:
		_timer.stop()
	changed.emit()
