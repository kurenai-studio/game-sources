extends ScreenBase
## One world: its chapters and level tiles. A tile shows its state by shape and icon as well as
## fill: solved (solid, check), current (yellow, play), locked (outline, lock), and a level that
## needs a newer game (outline, up arrow). `args["world"]` is the index into the campaign.

const COLUMNS := 3
const TILE_GAP := 10.0

var _world_index := 0
var _world: Dictionary
var _back: TileButton
var _caption: Label
var _title: Label
var _summary: Label
var _scroll: ScrollContainer
var _content: VBoxContainer
var _play: TileButton


func _build() -> void:
	_world_index = int(args.get("world", 0))
	if _world_index < 0 or _world_index >= app.campaign.worlds.size():
		navigate.emit.call_deferred("worlds", {})
		return
	_world = app.campaign.worlds[_world_index]

	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back to worlds"
	_back.pressed.connect(go_back)
	add_child(_back)

	_caption = UiKit.label("WORLD %02d" % (_world_index + 1), 14, Palette.MUTE, 3)
	add_child(_caption)
	_title = UiKit.label(str(_world["title"]).to_upper(), 34, Palette.INK, 1)
	add_child(_title)

	var solved := _solved_count()
	var total := _level_count()
	var target := _level_to_play()
	var locked := target >= 0 and not app.progress.is_unlocked(app.campaign, target)
	var line := "%02d OF %02d SOLVED." % [solved, total]
	if locked:
		line = "LOCKED. SOLVE THE WORLD BEFORE IT TO PLAY."
	if not str(_world["summary"]).is_empty():
		line += " " + str(_world["summary"]).to_upper()
	_summary = UiKit.label(line, 14, Palette.MUTE, 1)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_scroll.add_child(_content)

	var label := (
		"PLAY LEVEL %02d" % app.campaign.entries[target]["number"] if target >= 0 else "NO LEVELS"
	)
	if locked:
		label = "LOCKED"
	_play = TileButton.make(TileButton.Kind.PRIMARY, label, "", 24)
	_play.set_disabled(target < 0 or locked)
	_play.pressed.connect(_open.bind(target))
	add_child(_play)

	_fill_content()


func go_back() -> void:
	navigate.emit("worlds", {})


func _layout() -> void:
	if _play == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 12.0)
	_back.position = Vector2(m, top)
	_back.size = Vector2(44.0, 44.0)
	_caption.position = Vector2(m, top + 54.0)
	_caption.size = Vector2(width, 18.0)
	_title.position = Vector2(m, top + 70.0)
	_title.size = Vector2(width, 40.0)
	_summary.position = Vector2(m, top + 114.0)
	_summary.size = Vector2(width, 0.0)
	var summary_h := maxf(40.0, _summary.get_minimum_size().y)
	_summary.size = Vector2(width, summary_h)
	var play_h := 64.0 if size.y >= 700.0 else 52.0
	_play.size = Vector2(width, play_h)
	_play.position = Vector2(m, size.y - inset_bottom() - m - play_h)
	var list_top := top + 114.0 + summary_h + 8.0
	_scroll.position = Vector2(m, list_top)
	_scroll.size = Vector2(width, _play.position.y - 16.0 - list_top)
	_content.custom_minimum_size = Vector2(width, 0)


func _entries_of_world() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for chapter: Dictionary in _world["chapters"]:
		for entry: Dictionary in chapter["entries"]:
			out.append(entry)
	return out


func _level_count() -> int:
	return _entries_of_world().size()


func _solved_count() -> int:
	var solved := 0
	for entry in _entries_of_world():
		if app.progress.is_completed(entry["id"]):
			solved += 1
	return solved


## Index (in the whole campaign) of the level this world's Play button opens: the first
## unfinished level here, else the last one.
func _level_to_play() -> int:
	var entries := _entries_of_world()
	if entries.is_empty():
		return -1
	for entry in entries:
		if not app.progress.is_completed(entry["id"]):
			return int(entry["number"]) - 1
	return int(entries[entries.size() - 1]["number"]) - 1


func _fill_content() -> void:
	var width := size.x - 2.0 * margin()
	if width <= 0.0:
		width = 350.0
	var tile := floorf((width - TILE_GAP * (COLUMNS - 1)) / COLUMNS)
	for chapter_index in _world["chapters"].size():
		var chapter: Dictionary = _world["chapters"][chapter_index]
		var caption := "CHAPTER %d · %s" % [chapter_index + 1, str(chapter["title"]).to_upper()]
		_content.add_child(_spacer(6.0 if chapter_index > 0 else 0.0))
		_content.add_child(UiKit.label(caption, 14, Palette.MUTE, 2))
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", int(TILE_GAP))
		grid.add_theme_constant_override("v_separation", int(TILE_GAP))
		for entry: Dictionary in chapter["entries"]:
			grid.add_child(_level_tile(entry, tile))
		for blocked: Dictionary in chapter["blocked"]:
			grid.add_child(_blocked_tile(blocked, tile))
		_content.add_child(grid)
	_content.add_child(_spacer(10.0))
	_content.add_child(_Legend.new())


func _level_tile(entry: Dictionary, tile: float) -> TileButton:
	var index: int = entry["number"] - 1
	var number := "%02d" % entry["number"]
	var state := app.progress.level_state(app.campaign, index)
	var button := LevelTile.new()
	button.kind = {"done": TileButton.Kind.SOLID, "current": TileButton.Kind.PRIMARY}.get(
		state, TileButton.Kind.LOCKED
	)
	button.icon = {"done": "check", "current": "play"}.get(state, "lock")
	button.label = number
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.show_board(entry["level"], number, state == "locked")
	button.stacked = true
	button.accessibility_name = "Level %s, %s" % [number, state]
	if state == "done":
		button.stars = LevelStars.of(app.progress, entry)
		if button.stars > 0:
			button.accessibility_name += ", %s" % LevelStars.words(button.stars)
	button.custom_minimum_size = Vector2(tile, tile + LevelTile.STRIP)
	if state != "locked":
		button.pressed.connect(_open.bind(index))
	return button


## A level this version of the game cannot play: an outlined tile with an up arrow.
func _blocked_tile(blocked: Dictionary, tile: float) -> TileButton:
	var button := TileButton.make(TileButton.Kind.SECONDARY, "UPDATE", "up", 22)
	button.stacked = true
	button.font_size = 12
	button.accessibility_name = "%s, needs a newer version of the game" % blocked["title"]
	button.custom_minimum_size = Vector2(tile, tile + LevelTile.STRIP)
	button.pressed.connect(
		func() -> void:
			navigate.emit("update_required", {"title": blocked["title"], "world": _world_index})
	)
	return button


func _open(index: int) -> void:
	if index >= 0 and app.progress.is_unlocked(app.campaign, index):
		navigate.emit("play", {"level_id": app.campaign.entries[index]["id"]})


func _spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## The key under the tiles: one small swatch per state, each with its icon and a word.
class _Legend:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(0, 32)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := 0.0
		var items := [["SOLVED", "star"], ["CURRENT", "play"], ["LOCKED", "lock"]]
		for i in items.size():
			var rect := Rect2(Vector2(x, 4.0), Vector2(24.0, 24.0))
			var icon_color := Palette.ON_INK
			var face := rect
			if UiLook.depth:
				var tone: TileDraw.Tone = [
					TileDraw.Tone.SOLID, TileDraw.Tone.ACTIVE, TileDraw.Tone.PLAIN
				][i]
				face = TileDraw.tile(self, rect, tone)
				icon_color = [Palette.ON_INK, Palette.ON_SIGNAL, Palette.MUTE][i]
			elif i == 0:
				UiKit.fill_chamfer(self, rect, Palette.INK)
			elif i == 1:
				UiKit.fill_chamfer(self, rect, Palette.SIGNAL)
				icon_color = Palette.ON_SIGNAL
			else:
				UiKit.outline_chamfer(self, rect, Palette.FAINT)
				icon_color = Palette.FAINT
			UiKit.icon(self, items[i][1], face.get_center(), 15.0, icon_color)
			var word: String = items[i][0]
			var text_rect := Rect2(x + 32.0, 0.0, 90.0, 32.0)
			UiKit.text(self, word, text_rect, 15, Palette.INK, 1, HORIZONTAL_ALIGNMENT_LEFT)
			x += 32.0 + UiKit.text_width(word, 15) + 22.0
