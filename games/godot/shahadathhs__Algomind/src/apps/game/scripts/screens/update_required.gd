extends NoticeScreen
## Update required: a level needs a newer version of the game (a mechanic or a level format this
## version does not know). The primary action opens the download page.


func _prepare() -> void:
	icon_kind = "up"
	heading = "UPDATE ALGOMIND"
	body = (
		"%s uses something this version of the game does not know yet. Update the app to play it."
		% str(args.get("title", "This level"))
	)
	detail = "YOUR VERSION IS %s" % Links.version()
	primary_label = "GET THE UPDATE"
	secondary_label = "BACK TO LEVELS"


func go_back() -> void:
	navigate.emit("worlds", {})


func _on_primary() -> void:
	Links.open("/download")


func _on_secondary() -> void:
	navigate.emit("worlds", {})
