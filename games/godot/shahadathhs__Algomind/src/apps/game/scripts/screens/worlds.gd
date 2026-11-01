extends ScreenBase
## Worlds: the campaign as a list. Each row is a world with its state: solved (solid), current
## (yellow), locked (faint outline with a lock), or not downloaded (outline with a download
## icon). A line under the list says where the levels came from, with Retry when offline.

const ROW_HEIGHT := 72.0
## In the depth look a world is a plate with a picture of its first level.
const PLATE_HEIGHT := 100.0
const THUMB_MAX := 112.0
const THUMB_MIN := 84.0

var _back: TileButton
var _caption: Label
var _title: Label
var _count: Label
var _status: Label
var _retry: TileButton
var _scroll: ScrollContainer
var _list: VBoxContainer
var _continue: TileButton


func _build() -> void:
	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back"
	_back.pressed.connect(go_back)
	add_child(_back)
	_caption = UiKit.label("CAMPAIGN", 14, Palette.MUTE, 3)
	add_child(_caption)
	_title = UiKit.label("WORLDS", 34, Palette.INK, 1)
	add_child(_title)
	_count = UiKit.label("", 14, Palette.MUTE, 3)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.visible = UiLook.depth
	add_child(_count)

	_status = UiKit.label("", 14, Palette.MUTE, 1)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_retry = TileButton.make(TileButton.Kind.SECONDARY, "RETRY", "", 14)
	_retry.pressed.connect(func() -> void: app.refresh_content())
	add_child(_retry)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16 if UiLook.depth else 8)
	_scroll.add_child(_list)

	_continue = TileButton.make(TileButton.Kind.PRIMARY, "", "", 24)
	_continue.pressed.connect(_on_continue)
	add_child(_continue)

	_fill()
	app.content_changed.connect(_on_content_changed)


func _exit_tree() -> void:
	if app != null and app.content_changed.is_connected(_on_content_changed):
		app.content_changed.disconnect(_on_content_changed)


func go_back() -> void:
	navigate.emit("home", {})


func _layout() -> void:
	if _continue == null:
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
	_count.position = Vector2(m, top + 86.0)
	_count.size = Vector2(width, 18.0)
	var play_h := 64.0 if size.y >= 700.0 else 52.0
	_continue.size = Vector2(width, play_h)
	_continue.position = Vector2(m, size.y - inset_bottom() - m - play_h)
	var list_top := top + 122.0
	if _status.visible:
		_status.position = Vector2(m, list_top - 4.0)
		_status.size = Vector2(width - (84.0 if _retry.visible else 0.0), 44.0)
		list_top += 48.0
	_retry.position = Vector2(size.x - m - 76.0, top + 118.0)
	_retry.size = Vector2(76.0, 44.0)
	_scroll.position = Vector2(m, list_top)
	_scroll.size = Vector2(width, _continue.position.y - 16.0 - list_top)
	_list.custom_minimum_size = Vector2(width, 0)


func _on_content_changed() -> void:
	for child in _list.get_children():
		child.queue_free()
	_fill()
	_layout()


func _row_height() -> float:
	return PLATE_HEIGHT if UiLook.depth else ROW_HEIGHT


func _fill() -> void:
	_count.text = "%d WORLDS" % app.campaign.worlds.size()
	var current_world := _current_world()
	for world_index in app.campaign.worlds.size():
		var world: Dictionary = app.campaign.worlds[world_index]
		var row := _WorldRow.new()
		row.number = world_index + 1
		row.title = str(world["title"]).to_upper()
		var entries := _entries_of(world)
		var solved := 0
		for entry in entries:
			if app.progress.is_completed(entry["id"]):
				solved += 1
		row.subtitle = "%02d OF %02d SOLVED" % [solved, entries.size()]
		if entries.is_empty():
			row.subtitle = "NEEDS A NEWER VERSION OF THE GAME"
			row.state = "update"
		elif solved == entries.size():
			row.state = "done"
		elif world_index == current_world:
			row.state = "current"
		elif app.progress.level_state(app.campaign, int(entries[0]["number"]) - 1) == "locked":
			row.state = "locked"
			row.subtitle = "LOCKED · %02d LEVELS" % entries.size()
		else:
			row.state = "current"
		if UiLook.depth and not entries.is_empty():
			row.show_picture(entries[0]["level"])
		row.accessibility_name = "World %d, %s, %s" % [row.number, world["title"], row.subtitle]
		if row.state == "locked":
			row.accessibility_name += ", opens a preview of its levels"
		row.custom_minimum_size = Vector2(0, _row_height())
		if row.state == "update":
			row.pressed.connect(
				func() -> void: navigate.emit("update_required", {"title": world["title"]})
			)
		else:
			# A locked world can still be opened to look at its chapters and levels.
			row.pressed.connect(func() -> void: navigate.emit("world", {"world": world_index}))
		_list.add_child(row)
	for pending_index in app.campaign.pending_worlds.size():
		var pending: Dictionary = app.campaign.pending_worlds[pending_index]
		var row := _WorldRow.new()
		row.number = app.campaign.worlds.size() + pending_index + 1
		row.title = str(pending["title"]).to_upper()
		row.subtitle = "NOT DOWNLOADED"
		row.state = "pending"
		row.accessibility_name = "%s, not downloaded" % pending["title"]
		row.custom_minimum_size = Vector2(0, _row_height())
		row.pressed.connect(
			func() -> void:
				navigate.emit("load_error", {"title": pending["title"], "back": "worlds"})
		)
		_list.add_child(row)

	var target := app.progress.level_to_play(app.campaign)
	if target >= 0:
		_continue.label = "CONTINUE LEVEL %02d" % app.campaign.entries[target]["number"]
	else:
		_continue.label = "NO LEVELS"
	_continue.set_disabled(target < 0)
	_update_status()


func _entries_of(world: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for chapter: Dictionary in world["chapters"]:
		for entry: Dictionary in chapter["entries"]:
			out.append(entry)
	return out


## The index of the world holding the level Continue opens, or -1.
func _current_world() -> int:
	var target := app.progress.level_to_play(app.campaign)
	if target < 0:
		return -1
	return int(app.campaign.entries[target]["world"])


func _on_continue() -> void:
	var target := app.progress.level_to_play(app.campaign)
	if target >= 0:
		navigate.emit("play", {"level_id": app.campaign.entries[target]["id"]})


## One short line about where the levels came from. Never blocks play.
func _update_status() -> void:
	var text := ""
	var can_retry := false
	match app.sync_status:
		"loading":
			text = "CHECKING FOR NEW LEVELS"
		"offline":
			text = "OFFLINE. CONNECT TO GET NEW WORLDS"
			can_retry = true
		"invalid":
			text = "THE LEVEL SERVER SENT SOMETHING UNREADABLE"
			can_retry = true
		_:
			text = ""
	_status.text = text
	_status.visible = not text.is_empty()
	_retry.visible = can_retry


## A world in the list: a number tile, a title and a state line, and a chevron.
class _WorldRow:
	extends Control

	signal pressed

	var number := 1
	var title := ""
	var subtitle := ""
	## "done", "current", "locked", "pending" (not downloaded), or "update" (needs a newer game).
	var state := "locked"
	var _down := false
	var _press_at := Vector2.ZERO
	var _picture: BoardView

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	## Shows the first level of the world, as the depth board, at the right of the plate.
	func show_picture(level: Dictionary) -> void:
		_picture = BoardViews.make(Settings.LOOK_DEPTH)
		add_child(_picture)
		_picture.set_level(level)

	## The picture is a third of the plate on a wide phone and smaller on a narrow one.
	func _thumb() -> Vector2:
		var width := clampf(size.x * 0.3, THUMB_MIN, THUMB_MAX)
		return Vector2(width, width * 0.75)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and _picture != null:
			var thumb := _thumb()
			_picture.size = thumb
			_picture.position = Vector2(size.x - thumb.x - 12.0, (size.y - thumb.y) / 2.0 - 3.0)

	## The largest font size, down to `least`, at which `value` fits in `width`.
	func _fit(value: String, width: float, start: int, least: int, spacing: int) -> int:
		var px := start
		while px > least and UiKit.text_width(value, px, spacing) > width:
			px -= 1
		return px

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		var motion := event as InputEventMouseMotion
		if click != null and click.button_index == MOUSE_BUTTON_LEFT:
			if click.pressed:
				_down = true
				_press_at = click.position
			else:
				var fire := (
					_down
					and Rect2(Vector2.ZERO, size).has_point(click.position)
					and click.position.distance_to(_press_at) <= 12.0
				)
				_down = false
				if fire:
					pressed.emit()
			queue_redraw()
		elif motion != null and _down and motion.position.distance_to(_press_at) > 12.0:
			_down = false
			queue_redraw()

	func _draw_plate() -> void:
		var dim := state == "locked" or state == "pending"
		# A locked or not-downloaded world dims with its picture; its words and icon still say which.
		modulate.a = 0.6 if dim else 1.0
		var tone := TileDraw.Tone.ACTIVE if state == "current" else TileDraw.Tone.PLAIN
		var face := TileDraw.tile(self, Rect2(Vector2.ZERO, size), tone)
		var on := Palette.ON_SIGNAL if state == "current" else Palette.INK
		var quiet := Palette.ON_SIGNAL if state == "current" else Palette.MUTE
		var middle := Rect2(0.0, 0.0, 64.0, face.size.y)
		if state == "pending":
			UiKit.icon(self, "download", middle.get_center() + Vector2(8.0, 0.0), 30.0, on)
		elif state == "update":
			UiKit.icon(self, "up", middle.get_center() + Vector2(8.0, 0.0), 30.0, on)
		else:
			UiKit.text(self, "%02d" % number, middle, 38, quiet if dim else on, 0)
		var left := 76.0
		var text_w := size.x - left - _thumb().x - 24.0
		var title_color := Palette.MUTE if dim else on
		var title_px := _fit(title, text_w - (26.0 if state == "locked" else 0.0), 28, 18, 1)
		UiKit.text(
			self,
			title,
			Rect2(left, face.size.y * 0.22, text_w, 32.0),
			title_px,
			title_color,
			1,
			HORIZONTAL_ALIGNMENT_LEFT
		)
		if state == "locked":
			var after := left + UiKit.text_width(title, title_px, 1) + 10.0
			UiKit.icon(self, "lock", Vector2(after + 8.0, face.size.y * 0.22 + 16.0), 18.0, quiet)
		UiKit.text(
			self,
			subtitle,
			Rect2(left, face.size.y * 0.22 + 38.0, text_w, 20.0),
			_fit(subtitle, text_w, 13, 9, 2),
			quiet,
			2,
			HORIZONTAL_ALIGNMENT_LEFT
		)

	func _draw() -> void:
		if UiLook.depth:
			_draw_plate()
			return
		modulate.a = 1.0
		var tile := Rect2(Vector2(0, (size.y - 56.0) / 2.0), Vector2(56.0, 56.0))
		var dim := state == "locked" or state == "pending"
		var ink := Palette.FAINT if dim else Palette.INK
		var on := Palette.ON_INK
		match state:
			"done":
				UiKit.fill_chamfer(self, tile, Palette.INK)
			"current":
				UiKit.fill_chamfer(self, tile, Palette.SIGNAL)
				on = Palette.ON_SIGNAL
			_:
				UiKit.outline_chamfer(self, tile, ink)
				on = ink
		if state == "pending":
			UiKit.icon(self, "download", tile.get_center(), 28.0, on)
		elif state == "update":
			UiKit.icon(self, "up", tile.get_center(), 28.0, on)
		else:
			UiKit.text(self, "%02d" % number, tile, 24, on, 0)
		var text_left := 72.0
		var text_w := size.x - text_left - 32.0
		UiKit.text(
			self,
			title,
			Rect2(text_left, 8.0, text_w, 30.0),
			26,
			Palette.MUTE if dim else Palette.INK,
			1,
			HORIZONTAL_ALIGNMENT_LEFT
		)
		UiKit.text(
			self,
			subtitle,
			Rect2(text_left, 38.0, text_w, 22.0),
			13,
			Palette.MUTE,
			2,
			HORIZONTAL_ALIGNMENT_LEFT
		)
		UiKit.icon(self, "next", Vector2(size.x - 14.0, size.y / 2.0), 22.0, ink)
