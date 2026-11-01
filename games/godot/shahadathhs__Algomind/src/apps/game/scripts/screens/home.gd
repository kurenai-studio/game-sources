extends ScreenBase
## Home: the wordmark, a board, Play (the one primary), and a row of short text links: Levels,
## Daily, Settings, Account. Daily and Account need the server, so the browser try-out has neither.

var _wordmark: Wordmark
var _board: BoardView
var _play: TileButton
var _levels: TileButton
var _daily: TileButton
var _settings: TileButton
var _account: TileButton
## The links in the order shown, left to right.
var _links: Array[TileButton] = []
var _notice: Label


func _build() -> void:
	_wordmark = Wordmark.new()
	add_child(_wordmark)

	_board = BoardViews.make(app.progress.settings.look())
	add_child(_board)
	if not app.campaign.entries.is_empty():
		# The board is the puzzle the player would play next.
		var next := maxi(app.progress.level_to_play(app.campaign), 0)
		_board.set_level(app.campaign.entries[next]["level"])

	_play = TileButton.make(TileButton.Kind.PRIMARY, "PLAY", "", 28)
	_play.pressed.connect(_on_play)
	_play.set_disabled(app.campaign.entries.is_empty())
	add_child(_play)

	_levels = _link("LEVELS", func() -> void: navigate.emit("worlds", {}))
	_levels.set_disabled(app.campaign.entries.is_empty())
	if app.has_social():
		_daily = _link("DAILY", func() -> void: navigate.emit("daily", {}))
	_settings = _link("SETTINGS", func() -> void: navigate.emit("settings", {}))
	# The browser build is offline-only, so it has no account to sign in to.
	if not OS.has_feature("web"):
		_account = _link(
			"ACCOUNT",
			func() -> void:
				navigate.emit("account" if app.signed_in() else "sign_in", {"back": "home"})
		)
	for i in _links.size():
		var last := i == _links.size() - 1
		_links[i].align = (
			HORIZONTAL_ALIGNMENT_LEFT
			if i == 0
			else (HORIZONTAL_ALIGNMENT_RIGHT if last else HORIZONTAL_ALIGNMENT_CENTER)
		)

	if app.campaign.entries.is_empty():
		_notice = UiKit.label("THE LEVELS COULD NOT LOAD", 18, Palette.INK, 1)
		_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_notice)


func _link(text: String, action: Callable) -> TileButton:
	var button := TileButton.make(
		TileButton.Kind.TERTIARY, text, "", 16 if app.has_social() else 18
	)
	button.pressed.connect(action)
	add_child(button)
	_links.append(button)
	return button


func go_back() -> void:
	# A browser tab is closed by the visitor, not by the game.
	if not OS.has_feature("web"):
		get_tree().quit()


func _layout() -> void:
	if _play == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 16.0)
	_wordmark.position = Vector2(m, top)
	_wordmark.size = Vector2(width, 60.0 if size.y >= 700.0 else 48.0)

	var bottom := size.y - inset_bottom() - m
	var link_h := 48.0
	var play_h := 64.0 if size.y >= 700.0 else 56.0
	var link_w := floorf(width / _links.size())
	for i in _links.size():
		var last := i == _links.size() - 1
		_links[i].position = Vector2(m + i * link_w, bottom - link_h)
		_links[i].size = Vector2(width - i * link_w if last else link_w, link_h)
	_play.position = Vector2(m, bottom - link_h - 12.0 - play_h)
	_play.size = Vector2(width, play_h)

	var free_top := _wordmark.position.y + _wordmark.size.y + 24.0
	var free_bottom := _play.position.y - 24.0
	if UiLook.depth:
		# The tilted board is wider than tall: it takes the free width and height.
		_board.size = Vector2(width, free_bottom - free_top)
		_board.position = Vector2(m, free_top)
	else:
		var side := minf(minf(width * 0.8, free_bottom - free_top), 320.0)
		_board.size = Vector2(side, side)
		_board.position = Vector2(
			(size.x - side) / 2.0, free_top + (free_bottom - free_top - side) / 2.0
		)
	if _notice != null:
		_notice.position = Vector2(m, _play.position.y - 40.0)
		_notice.size = Vector2(width, 24.0)


func _on_play() -> void:
	var index := app.progress.level_to_play(app.campaign)
	if index >= 0:
		navigate.emit("play", {"level_id": app.campaign.entries[index]["id"]})
