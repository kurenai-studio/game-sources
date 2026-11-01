class_name PlayShare
extends RefCounted
## The Share and Ranking actions of the solved screen. Share copies the result card as text; when
## the player is signed in and the server answers, the link to the card's page goes on a following
## line. The Android share sheet needs a plugin and is not used: this only copies.


## The plain result card for the level or daily that was just solved.
static func card_text(p: PlayScreen) -> String:
	var par: int = int(p._entry.get("par", {}).get("commands", 0))
	if p._entry.has("daily"):
		return ShareCard.daily_text(str(p._entry["daily"]), p._tape.slots(), par)
	var title := str(p._level["title"])
	return ShareCard.level_text(int(p._entry["number"]), title, p._tape.slots(), par)


## Copies the card (and the link, when the server gives one) and shows COPIED for a moment.
static func share(p: PlayScreen) -> void:
	p._share.set_disabled(true)
	var link := ""
	var app := p.app
	if p.persist and app.signed_in() and app.social != null:
		if app.account_sync != null:
			await app.account_sync.sync_now()
		var date := str(p._entry.get("daily", ""))
		var answer := await app.social.share(str(p._entry["id"]), date)
		if answer["ok"]:
			link = Links.site(str(answer["data"]["path"]))
	if not is_instance_valid(p):
		return
	DisplayServer.clipboard_set(ShareCard.with_link(card_text(p), link))
	p._share.set_disabled(false)
	_show(p, "COPIED", "check")
	await p.get_tree().create_timer(2.0).timeout
	if is_instance_valid(p):
		_show(p, "SHARE", "")


## Opens the board of this level, or of the day for a daily; Back returns to the play screen.
static func ranking(p: PlayScreen) -> void:
	var back_args := {"level_id": p._entry["id"]}
	var board := {"scope": "level", "key": p._entry["id"], "title": p._level["title"]}
	if p._entry.has("daily"):
		back_args = {"daily": p._entry["daily"]}
		board = {"scope": "daily", "key": p._entry["daily"]}
	board["back"] = "play"
	board["back_args"] = back_args
	p.navigate.emit("leaderboard", board)


static func _show(p: PlayScreen, label: String, icon: String) -> void:
	p._share.label = label
	p._share.icon = icon
	p._share.accessibility_name = label
	p._share.queue_redraw()
