extends ScreenBase
## Account: who is signed in, how syncing is going, a summary of local progress, and Sync now,
## Sign out, and Delete account (which asks for the password first).

var _confirming := false
var _busy := false

var _back: TileButton
var _caption: Label
var _title: Label
var _status: _StatusRow
var _stats: Array[StatTile] = []
var _links: Array[TileButton] = []
var _note: Label
var _password: TextField
var _message: Label
var _primary: TileButton
var _secondary: TileButton
var _tertiary: TileButton


func _build() -> void:
	if not app.signed_in():
		navigate.emit.call_deferred("sign_in", {})
		return
	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back"
	_back.pressed.connect(go_back)
	add_child(_back)
	_caption = UiKit.label("SIGNED IN", 14, Palette.MUTE, 3)
	add_child(_caption)
	_title = UiKit.label(app.account.email.to_upper(), 24, Palette.INK, 1)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_title)
	_status = _StatusRow.new()
	add_child(_status)
	for caption in ["SOLVED", "LEVELS", "POINTS"]:
		var stat := StatTile.new()
		stat.caption = caption
		add_child(stat)
		_stats.append(stat)
	_note = UiKit.label(
		"PROGRESS SAVES ON THIS DEVICE FIRST AND SYNCS WHEN YOU ARE ONLINE.", 13, Palette.MUTE, 1
	)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_note)
	_add_links()
	_password = TextField.new()
	_password.secret = true
	_password.placeholder = "Your password"
	_password.accessible_label = "Password to confirm deleting the account"
	_password.visible = false
	add_child(_password)
	_message = UiKit.label("", 14, Palette.INK, 1)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_message)

	_primary = TileButton.make(TileButton.Kind.PRIMARY, "SYNC NOW", "", 24)
	_primary.pressed.connect(_on_primary)
	add_child(_primary)
	_secondary = TileButton.make(TileButton.Kind.SECONDARY, "SIGN OUT", "", 18)
	_secondary.pressed.connect(_on_secondary)
	add_child(_secondary)
	_tertiary = TileButton.make(TileButton.Kind.TERTIARY, "DELETE ACCOUNT", "", 16)
	_tertiary.pressed.connect(_on_tertiary)
	add_child(_tertiary)
	if app.account_sync != null:
		app.account_sync.changed.connect(_refresh)
	_refresh()


## Profile, Badges, and Leaderboard: the social features, which need the server.
func _add_links() -> void:
	if not app.has_social():
		return
	var targets := [["PROFILE", "profile", {}], ["BADGES", "badges", {}]]
	targets.append(["LEADERBOARD", "leaderboard", {"scope": "points"}])
	for item: Array in targets:
		var button := TileButton.make(TileButton.Kind.TERTIARY, item[0], "", 15)
		var target_args: Dictionary = item[2].duplicate()
		target_args["back"] = "account"
		button.pressed.connect(func() -> void: navigate.emit(item[1], target_args))
		add_child(button)
		_links.append(button)
	_links[0].align = HORIZONTAL_ALIGNMENT_LEFT
	_links[2].align = HORIZONTAL_ALIGNMENT_RIGHT


func _exit_tree() -> void:
	if app != null and app.account_sync != null and app.account_sync.changed.is_connected(_refresh):
		app.account_sync.changed.disconnect(_refresh)


func go_back() -> void:
	if _confirming:
		_set_confirming(false)
		return
	navigate.emit("home", {})


func _layout() -> void:
	if _tertiary == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 12.0)
	_back.position = Vector2(m, top)
	_back.size = Vector2(44.0, 44.0)
	_caption.position = Vector2(m, top + 54.0)
	_caption.size = Vector2(width, 18.0)
	_title.position = Vector2(m, top + 70.0)
	_title.size = Vector2(width, 34.0)
	_status.position = Vector2(m, top + 116.0)
	_status.size = Vector2(width, 36.0)
	var stats_top := top + 168.0
	var stat_gap := 10.0
	var stat_w := floorf((width - 2.0 * stat_gap) / 3.0)
	for i in _stats.size():
		_stats[i].position = Vector2(m + i * (stat_w + stat_gap), stats_top)
		_stats[i].size = Vector2(stat_w, 72.0)
	_note.position = Vector2(m, stats_top + 88.0)
	_note.size = Vector2(width, 40.0)
	_password.position = Vector2(m, stats_top + 140.0)
	_password.size = Vector2(width, 52.0)
	for i in _links.size():
		var link_w := floorf(width / _links.size())
		_links[i].position = Vector2(m + i * link_w, stats_top + 130.0)
		_links[i].size = Vector2(link_w if i < _links.size() - 1 else width - i * link_w, 44.0)
	_message.position = Vector2(m, stats_top + 200.0)
	_message.size = Vector2(width, 44.0)
	var bottom := size.y - inset_bottom() - m
	_tertiary.size = Vector2(width, 48.0)
	_tertiary.position = Vector2(m, bottom - 48.0)
	_secondary.size = Vector2(width, 52.0)
	_secondary.position = Vector2(m, bottom - 48.0 - 8.0 - 52.0)
	var primary_h := 64.0 if size.y >= 700.0 else 56.0
	_primary.size = Vector2(width, primary_h)
	_primary.position = Vector2(m, _secondary.position.y - 10.0 - primary_h)


func _refresh() -> void:
	if _status == null:
		return
	var sync := app.account_sync
	var state := "idle" if sync == null else sync.status
	_status.state = state
	_status.text = _status_text(state)
	_status.queue_redraw()
	var solved := app.progress.completions()
	_stats[0].value = "%02d" % solved.size()
	_stats[1].value = "%02d" % app.campaign.entries.size()
	var total := app.progress.results.total
	_stats[2].value = str(total) if total >= 0 else "-"
	for stat in _stats:
		stat.queue_redraw()
	if sync != null and state in ["offline", "failed"] and not sync.message.is_empty():
		_message.text = sync.message
	elif not _confirming and not app.progress.results.badges.is_empty():
		_message.text = "NEW BADGES: %s" % ", ".join(app.progress.results.badges).to_upper()
	_primary.set_disabled(_busy or state == "syncing")


func _status_text(state: String) -> String:
	match state:
		"syncing":
			return "SYNCING"
		"offline":
			return "OFFLINE. WILL SYNC WHEN YOU ARE ONLINE"
		"failed":
			return "SYNC FAILED. WILL TRY AGAIN"
		"signed_out":
			return "SIGNED OUT"
		_:
			var at := app.account.last_sync_at
			return "NOT SYNCED YET" if at <= 0.0 else "SYNCED %s" % _ago(at)


static func _ago(unix_seconds: float) -> String:
	var seconds := int(Time.get_unix_time_from_system() - unix_seconds)
	if seconds < 60:
		return "JUST NOW"
	if seconds < 3600:
		return "%d MIN AGO" % (seconds / 60)
	if seconds < 86400:
		return "%d H AGO" % (seconds / 3600)
	return "%d DAYS AGO" % (seconds / 86400)


func _on_primary() -> void:
	if _confirming:
		await _delete_account()
		return
	if app.account_sync != null:
		_message.text = ""
		await app.account_sync.sync_now()


func _on_secondary() -> void:
	if _confirming:
		_set_confirming(false)
		return
	_busy = true
	await app.account_client.sign_out()
	if app.account_sync != null:
		app.account_sync.reset()
	if is_inside_tree():
		navigate.emit("home", {})


func _on_tertiary() -> void:
	_set_confirming(true)


func _set_confirming(value: bool) -> void:
	_confirming = value
	_password.visible = value
	_password.text = ""
	_message.text = (
		(
			"DELETING REMOVES THE ACCOUNT AND ITS SAVED PROGRESS FROM THE SERVER. "
			+ "PROGRESS ON THIS DEVICE STAYS."
		)
		if value
		else ""
	)
	_primary.label = "DELETE ACCOUNT" if value else "SYNC NOW"
	_primary.accessibility_name = _primary.label
	_secondary.label = "CANCEL" if value else "SIGN OUT"
	_secondary.accessibility_name = _secondary.label
	_tertiary.visible = not value
	for link in _links:
		link.visible = not value
	_primary.queue_redraw()
	_secondary.queue_redraw()
	if value:
		_password.grab_edit_focus()


func _delete_account() -> void:
	if _busy or _password.text.is_empty():
		_message.text = "ENTER YOUR PASSWORD TO DELETE THE ACCOUNT"
		return
	_busy = true
	_primary.set_disabled(true)
	var result := await app.account_client.delete_account(_password.text)
	_busy = false
	if not is_inside_tree():
		return
	if result["ok"]:
		if app.account_sync != null:
			app.account_sync.reset()
		navigate.emit("home", {})
	else:
		_primary.set_disabled(false)
		_message.text = str(result["message"])


## The sync line: an icon tile that is solid when synced and outlined otherwise, then the words.
class _StatusRow:
	extends Control

	var state := "idle"
	var text := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var tile := Rect2(Vector2(0, (size.y - 28.0) / 2.0), Vector2(28.0, 28.0))
		var good := state == "synced" or state == "idle"
		if good:
			UiKit.fill_chamfer(self, tile, Palette.SIGNAL)
			UiKit.icon(self, "check", tile.get_center(), 18.0, Palette.ON_SIGNAL)
		else:
			UiKit.outline_chamfer(self, tile, Palette.INK)
			var icon := "reset" if state == "syncing" else "offline"
			UiKit.icon(self, icon, tile.get_center(), 18.0, Palette.INK)
		UiKit.text(
			self,
			text,
			Rect2(40.0, 0.0, size.x - 40.0, size.y),
			15,
			Palette.INK,
			1,
			HORIZONTAL_ALIGNMENT_LEFT
		)
