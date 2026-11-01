extends NoticeScreen
## Load error: a world or level could not be loaded. Retry asks the API again; the other action
## goes back to what is already on the device. `args["title"]` names what failed.


func _prepare() -> void:
	icon_kind = "offline"
	var what := str(args.get("title", "THIS LEVEL")).to_upper()
	heading = "%s COULD NOT LOAD" % what
	body = (
		"Check your connection and try again. "
		+ "Levels you have already downloaded still work offline."
	)
	detail = "NOTHING WAS CHANGED ON THIS DEVICE"
	primary_label = "RETRY"
	secondary_label = "PLAY A DOWNLOADED LEVEL"


func go_back() -> void:
	navigate.emit(str(args.get("back", "worlds")), {})


func _on_primary() -> void:
	await app.refresh_content()
	# Back to the list: it now shows the downloaded world, or this screen again if it failed.
	navigate.emit(str(args.get("back", "worlds")), {})


func _on_secondary() -> void:
	var target := app.progress.level_to_play(app.campaign)
	if target >= 0:
		navigate.emit("play", {"level_id": app.campaign.entries[target]["id"]})
	else:
		navigate.emit("home", {})
