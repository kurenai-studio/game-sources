extends "res://tests/base_test.gd"
## The Buy me a coffee button on the play screen (GDD 15.5, BC7 to BC11,
## AT-155, AT-157, AT-170, AT-171; DESIGN_SYSTEM.md 7.15).
##
## Every test swaps the hand off for a capture (TH24), so no browser opens.
## Headless tests never enter the scene tree, so the play screen is laid out
## through layout_in with the phone rects of 7.15, and touches go through
## Router below: it delivers events the way Godot's viewport does (a touch
## and its emulated mouse copy go to the topmost control under the point that
## does not ignore the mouse; moves and the release go to the control that
## took the press; only the first finger gets a mouse copy).

const U := preload("res://tests/ui/ui_fixtures.gd")
const Copy := preload("res://src/ui/screen_copy.gd")
const CoffeeButton := preload("res://src/ui/coffee_button.gd")

## Phones of DESIGN_SYSTEM.md 7.15 as tools/coffee_space.gd works them out:
## physical px, density, the status inset and the bottom inset in physical
## px (the Fold5 numbers read from Bart's phone), and where the button goes
## in every skin. The first four keep their order, so COVER and INNER keep
## their indexes.
const PHONES: Array[Dictionary] = [
	{"name": "20:9 1080 x 2400", "px": Vector2(1080, 2400), "density": 3.0, "top_px": 120.0, "bottom_px": 66.0, "place": GameScreen.CoffeePlace.NONE},
	{"name": "Fold5 cover, hint shown", "px": Vector2(904, 2316), "density": 2.625, "top_px": 85.0, "bottom_px": 58.0, "place": GameScreen.CoffeePlace.BELOW_BOARD},
	{"name": "Fold5 inner, hint shown", "px": Vector2(1812, 2176), "density": 2.625, "top_px": 85.0, "bottom_px": 58.0, "place": GameScreen.CoffeePlace.GUTTER},
	{"name": "16:9 with button bar", "px": Vector2(1080, 1920), "density": 3.0, "top_px": 72.0, "bottom_px": 144.0, "place": GameScreen.CoffeePlace.NONE},
	{"name": "Fold5 cover, hint hidden", "px": Vector2(904, 2316), "density": 2.625, "top_px": 85.0, "bottom_px": 0.0, "place": GameScreen.CoffeePlace.BELOW_BOARD},
	{"name": "Fold5 inner, hint hidden", "px": Vector2(1812, 2176), "density": 2.625, "top_px": 85.0, "bottom_px": 0.0, "place": GameScreen.CoffeePlace.GUTTER},
	{"name": "Fold5 inner, no insets", "px": Vector2(1812, 2176), "density": 2.625, "top_px": 0.0, "bottom_px": 0.0, "place": GameScreen.CoffeePlace.GUTTER},
]
const COVER: int = 1
const INNER: int = 2
const BASE: Vector2 = Vector2(1080, 2400)


## Godot's routing of touches, for controls outside the scene tree.
class Router extends RefCounted:
	var root: Control
	var mouse_focus: Control = null
	var touch_focus: Dictionary[int, Control] = {}

	func _init(top: Control) -> void:
		root = top

	## The topmost control under point that takes the mouse, as Godot's
	## _gui_find_control_at_pos: children in reverse order before the parent.
	func find_at(point: Vector2) -> Control:
		return _find(root, point)

	func _find(control: Control, point: Vector2) -> Control:
		if not control.visible:
			return null
		for index: int in range(control.get_child_count() - 1, -1, -1):
			var child: Control = control.get_child(index) as Control
			if child == null:
				continue
			var hit: Control = _find(child, point)
			if hit != null:
				return hit
		if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			return null
		var local: Vector2 = point - U.rect_in(control, root).position
		var inside: bool = Rect2(Vector2.ZERO, control.size).has_point(local)
		if control.get_script() == CoffeeButton:
			inside = control._has_point(local)
		return control if inside else null

	## Delivers to control and up through its parents until one stops it.
	func _deliver(control: Control, event: InputEvent, point: Vector2) -> void:
		var node: Control = control
		while node != null:
			if node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				var copy: InputEvent = event.duplicate()
				var local: Vector2 = point - U.rect_in(node, root).position
				if copy is InputEventMouse:
					(copy as InputEventMouse).position = local
					(copy as InputEventMouse).global_position = point
				elif copy is InputEventScreenTouch:
					(copy as InputEventScreenTouch).position = local
				elif copy is InputEventScreenDrag:
					(copy as InputEventScreenDrag).position = local
				# Engine controls (Button, PanelContainer) handle input in
				# C++, out of reach here; they only need to take the event.
				if _reads_input(node):
					node._gui_input(copy)
				if node.mouse_filter == Control.MOUSE_FILTER_STOP:
					return
			if node == root:
				return
			node = node.get_parent() as Control

	static func _reads_input(node: Control) -> bool:
		var script: Script = node.get_script() as Script
		while script != null:
			for method: Dictionary in script.get_script_method_list():
				if String(method.get("name", "")) == "_gui_input":
					return true
			script = script.get_base_script()
		return false

	func down(index: int, point: Vector2) -> void:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.index = index
		touch.pressed = true
		touch.position = point
		var over: Control = find_at(point)
		if over != null:
			touch_focus[index] = over
			_deliver(over, touch, point)
		if index == 0:
			var button: InputEventMouseButton = InputEventMouseButton.new()
			button.device = InputEvent.DEVICE_ID_EMULATION
			button.button_index = MOUSE_BUTTON_LEFT
			button.pressed = true
			mouse_focus = find_at(point)
			if mouse_focus != null:
				_deliver(mouse_focus, button, point)

	func move(index: int, point: Vector2) -> void:
		if touch_focus.has(index):
			var drag: InputEventScreenDrag = InputEventScreenDrag.new()
			drag.index = index
			drag.position = point
			_deliver(touch_focus[index], drag, point)
		if index == 0 and mouse_focus != null:
			var motion: InputEventMouseMotion = InputEventMouseMotion.new()
			motion.device = InputEvent.DEVICE_ID_EMULATION
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			_deliver(mouse_focus, motion, point)

	## Moves in steps of at most 20 px, as a finger's drag events come.
	func slide(index: int, from: Vector2, to: Vector2) -> void:
		var steps: int = maxi(1, ceili(from.distance_to(to) / 20.0))
		for step: int in steps:
			move(index, from.lerp(to, float(step + 1) / float(steps)))

	## The release goes only to the control that took the press.
	func up(index: int, point: Vector2) -> void:
		if touch_focus.has(index):
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.index = index
			touch.pressed = false
			touch.position = point
			var target: Control = touch_focus[index]
			touch_focus.erase(index)
			_deliver(target, touch, point)
		if index == 0:
			if mouse_focus != null:
				var button: InputEventMouseButton = InputEventMouseButton.new()
				button.device = InputEvent.DEVICE_ID_EMULATION
				button.button_index = MOUSE_BUTTON_LEFT
				button.pressed = false
				var target_mouse: Control = mouse_focus
				mouse_focus = null
				_deliver(target_mouse, button, point)

	func tap(point: Vector2) -> void:
		down(0, point)
		up(0, point)


var _hosts: Array[Control] = []
var _dir: String = ""
var _app: App = null
var _quits: Array[int] = []
var _sent: Array[String] = []


func before_each() -> void:
	_hosts = []
	_dir = ""
	_app = null
	_quits = []
	_sent = []
	CoffeeButton.opener = _capture
	Motion.bind_tweens = false


func after_each() -> void:
	if _app != null:
		U.stop_app(_app)
	if not _dir.is_empty():
		U.remove_temp_dir(_dir)
	for host: Control in _hosts:
		U.free_stage(host)
	CoffeeButton.use_system_opener()
	Motion.bind_tweens = true


## TH24: records each address instead of opening a browser.
func _capture(address: String) -> Error:
	_sent.append(address)
	return OK


# Phones and layouts.

## The logical canvas: 2400 tall, or 1080 wide on screens narrower than 9:20
## (DESIGN_SYSTEM.md 2.1).
func _canvas(phone: Dictionary) -> Vector2:
	var px: Vector2 = phone["px"]
	var scale: float = px.y / BASE.y
	if px.x / px.y < BASE.x / BASE.y:
		scale = px.x / BASE.x
	return px / scale


func _safe(phone: Dictionary) -> Rect2:
	var px: Vector2 = phone["px"]
	var canvas: Vector2 = _canvas(phone)
	var per_px: float = canvas.x / px.x
	var top: float = float(phone["top_px"]) * per_px
	var bottom: float = float(phone["bottom_px"]) * per_px
	return Rect2(0.0, top, canvas.x, canvas.y - top - bottom)


## Lays game out for phone, as _layout does on a real screen of that shape.
func _lay_out(game: GameScreen, phone: Dictionary) -> void:
	var canvas: Vector2 = _canvas(phone)
	var safe: Rect2 = _safe(phone)
	U.fit(game, canvas)
	game.layout_in(Rect2(Vector2.ZERO, canvas), SafeArea.column_in(safe, game.get(&"_skin") as SkinData), safe)


## A play screen on its own: Board P at 5,000, shown and at rest.
func _game(skin_id: StringName, phone: Dictionary, cells: PackedInt64Array = U.board_p()) -> GameScreen:
	var canvas: Vector2 = _canvas(phone)
	var host: Control = U.stage(Vector2i(roundi(canvas.x), roundi(canvas.y)), skin_id)
	_hosts.append(host)
	var session: GameSession = GameSession.new()
	var audio: AudioService = AudioService.new()
	host.add_child(audio)
	var game: GameScreen = (load("res://scenes/ui/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	host.add_child(game)
	game.setup(session, Settings.new(), audio, SkinCatalog.get_skin(skin_id))
	session.resume(U.run(cells, 5000))
	_settle(game)
	_lay_out(game, phone)
	return game


## A started App in skin, the saved run state playing, its play screen laid
## out for phone and at rest.
func _start(skin_id: StringName, state: RunState, phone: Dictionary, best: int = 6000, best_tile: int = 6) -> App:
	_dir = U.make_temp_dir()
	var settings: Settings = Settings.new()
	settings.set_skin_id(skin_id)
	U.save_game(_dir, state, best, best_tile, settings)
	_app = U.start_app(_dir, _quits)
	U.play(_app)
	U.settle(_app)
	_settle(_app.game_screen())
	_lay_out(_app.game_screen(), phone)
	return _app


## Runs the board's frames until its move has been shown, as the board would.
func _settle(game: GameScreen) -> void:
	var board: BoardController = game.board()
	for frame: int in 900:
		if not board.is_animating():
			return
		board._process(1.0 / 60.0)


func _view(game: GameScreen) -> SkinBoardView:
	var found: Array[Node] = game.board().find_children("*", "SkinBoardView", true, false)
	return found[0] as SkinBoardView if not found.is_empty() else null


## A cell's center in the play screen's coordinates.
func _cell(game: GameScreen, cell: Vector2i) -> Vector2:
	var board: BoardController = game.board()
	board.notification(Control.NOTIFICATION_RESIZED)
	var view: SkinBoardView = _view(game)
	view.size = board.size
	return board.position + view.position + BoardGeometry.cell_center(cell, view.grid_origin(), view.cell_pitch())


func _rect(control: Control, root: Control) -> Rect2:
	return U.rect_in(control, root)


func _touch_rect(game: GameScreen, root: Control) -> Rect2:
	var reach: float = (game.get(&"_skin") as SkinData).num(&"space_s")
	return _rect(game.coffee_button(), root).grow_individual(reach, 0.0, reach, 0.0)


func _coffee_center(game: GameScreen, root: Control) -> Vector2:
	return _rect(game.coffee_button(), root).get_center()


## Rects equal to within float rounding (1/1000 px).
func _assert_rect(got: Rect2, expected: Rect2, message: String) -> void:
	var same: bool = got.position.distance_to(expected.position) < 0.001 and got.size.distance_to(expected.size) < 0.001
	assert_true(same, "%s: expected %s, got %s" % [message, expected, got])


## The rects the play screen had before the coffee button (layout_in as it
## was at 5093eb2), worked out from the same parts: HUD, bar, board.
func _layout_before(game: GameScreen, phone: Dictionary) -> Dictionary:
	var skin: SkinData = game.get(&"_skin") as SkinData
	var screen: Rect2 = Rect2(Vector2.ZERO, _canvas(phone))
	var column: Rect2 = SafeArea.column_in(_safe(phone), skin)
	var inner: Rect2 = Rect2(column.position - screen.position, column.size)
	var margin: float = skin.num(&"board_margin")
	var gap: float = skin.num(&"space_s")
	var hud_height: float = game.hud().preferred_height()
	var hud: Rect2 = Rect2(inner.position, Vector2(inner.size.x, hud_height))
	var bar_height: float = game.booster_bar().preferred_height()
	var bar: Rect2 = Rect2(Vector2(inner.position.x, inner.end.y - bar_height), Vector2(inner.size.x, bar_height))
	var region_top: float = inner.position.y + hud_height + gap
	var region_height: float = maxf(0.0, bar.position.y - gap - region_top)
	var width: float = maxf(0.0, inner.size.x - margin * 2.0)
	var board: BoardController = game.board()
	var height: float = board.preferred_height(width)
	if height > region_height and height > 0.0:
		var half: float = width * 0.5
		var at_half: float = board.preferred_height(half)
		var slope: float = (height - at_half) / (width - half)
		width = clampf(half + (region_height - at_half) / slope, 0.0, width) if slope > 0.0 else 0.0
		height = board.preferred_height(width)
	var board_rect: Rect2 = Rect2(Vector2(inner.position.x + (inner.size.x - width) * 0.5, region_top + maxf(0.0, region_height - height) * 0.5), Vector2(width, height))
	return {"hud": hud, "bar": bar, "board": board_rect}


# AT-155: placement.

func test_at_155_placement_on_every_phone_in_every_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var gap: float = skin.num(&"space_s")
		for phone: Dictionary in PHONES:
			var label: String = "%s %s" % [skin_id, phone["name"]]
			var game: GameScreen = _game(skin_id, phone)
			var place: GameScreen.CoffeePlace = phone["place"]
			assert_eq(game.coffee_place(), place, "%s: placed as 7.15 says" % label)
			var coffee: Control = game.coffee_button()
			var board: Rect2 = _rect(game.board(), game)
			var bar: Rect2 = _rect(game.booster_bar(), game)
			var hud: Rect2 = _rect(game.hud(), game)
			var safe: Rect2 = _safe(phone)
			var column: Rect2 = SafeArea.column_in(safe, skin)
			# Nothing else moves or shrinks.
			var before: Dictionary = _layout_before(game, phone)
			_assert_rect(board, before["board"], "%s: the board's rect as before" % label)
			_assert_rect(bar, before["bar"], "%s: the bar's rect as before" % label)
			_assert_rect(hud, before["hud"], "%s: the HUD's rect as before" % label)
			if place == GameScreen.CoffeePlace.NONE:
				assert_false(game.is_coffee_shown(), "%s: not shown" % label)
				assert_false(coffee.visible, "%s: hidden" % label)
				assert_eq(coffee.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: takes no touch" % label)
				continue
			assert_true(game.is_coffee_shown(), "%s: shown" % label)
			assert_true(coffee.visible, "%s: visible" % label)
			assert_eq(coffee.modulate.a, 1.0, "%s: opaque" % label)
			assert_eq(coffee.mouse_filter, Control.MOUSE_FILTER_PASS, "%s: takes a tap" % label)
			assert_true(coffee.get_index() == 1 and game.get_child(0).name == &"Backdrop", "%s: just above the backdrop" % label)
			assert_true(coffee.get_index() < game.offer_panel().get_index() and coffee.get_index() < game.notice_layer().get_index(), "%s: under the offer and the notice layer" % label)
			var touch: Rect2 = _touch_rect(game, game)
			assert_false(touch.intersects(board), "%s: off the board" % label)
			assert_false(touch.intersects(bar), "%s: off the bar" % label)
			assert_false(touch.intersects(hud), "%s: off the HUD" % label)
			assert_true(safe.encloses(touch), "%s: inside the safe area" % label)
			if place == GameScreen.CoffeePlace.BELOW_BOARD:
				var space: float = bar.position.y - board.end.y
				var to_board: float = touch.position.y - board.end.y
				var to_bar: float = bar.position.y - touch.end.y
				var hint_hidden: bool = float(phone["bottom_px"]) == 0.0
				var expected_gap: Dictionary[StringName, float] = {&"gumdrop": 37.1, &"slate": 35.2, &"nova": 58.7}
				if hint_hidden:
					expected_gap = {&"gumdrop": 54.4, &"slate": 52.5, &"nova": 76.0}
				assert_false(bool(coffee.call(&"is_stacked")), "%s: the one line form" % label)
				assert_near(touch.size.y, skin.num(&"touch_min"), 0.01, "%s: touch_min tall" % label)
				assert_true(space >= skin.num(&"touch_min") + 2.0 * gap, "%s: room for touch_min plus space_s each side" % label)
				assert_true(touch.position.y >= board.end.y + gap - 0.01, "%s: at least space_s below the board" % label)
				assert_true(touch.end.y <= bar.position.y - gap + 0.01, "%s: at least space_s above the bar" % label)
				assert_near(to_board, to_bar, 0.01, "%s: equal gaps to the board and the bar" % label)
				assert_near(to_board, expected_gap[skin_id], 0.6, "%s: the gap 7.15 measures" % label)
				assert_near(touch.get_center().x, column.get_center().x, 0.01, "%s: centered in the column" % label)
				print("  %s: below the board, %d px from board to bar, gaps %.1f and %.1f px (space_s %d)" % [label, roundi(space), to_board, to_bar, roundi(gap)])
			else:
				assert_true(bool(coffee.call(&"is_stacked")), "%s: the stacked form" % label)
				assert_true(touch.size.y >= skin.num(&"touch_min"), "%s: at least touch_min tall" % label)
				assert_near(touch.size.y, coffee.size.y, 0.01, "%s: the touch area is the button's full height" % label)
				assert_true(touch.size.x >= skin.num(&"touch_min"), "%s: at least touch_min wide" % label)
				assert_true(touch.end.x <= column.position.x, "%s: entirely left of the column" % label)
				assert_true(touch.position.x >= safe.position.x, "%s: right of the safe area's edge" % label)
				assert_near(touch.get_center().x, (safe.position.x + column.position.x) * 0.5, 0.01, "%s: centered in the gutter" % label)
				assert_near(touch.get_center().y, bar.get_center().y, 0.01, "%s: centered on the bar" % label)
				print("  %s: in the gutter, %d px, the touch area %d px wide" % [label, roundi(column.position.x - safe.position.x), roundi(touch.size.x)])


func test_placement_follows_a_live_resize() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var game: GameScreen = _game(skin_id, PHONES[INNER])
		for index: int in [COVER, 0, INNER, 3, 4, 5, 6, COVER, INNER]:
			var phone: Dictionary = PHONES[index]
			_lay_out(game, phone)
			var label: String = "%s %s after a resize" % [skin_id, phone["name"]]
			assert_eq(game.coffee_place(), phone["place"], "%s: placed for the new size" % label)
			assert_eq(game.is_coffee_shown(), phone["place"] != GameScreen.CoffeePlace.NONE, "%s: shown only with a place" % label)
			_assert_form(game, label)
			var before: Dictionary = _layout_before(game, phone)
			_assert_rect(_rect(game.board(), game), before["board"], "%s: the board as before" % label)
			_assert_rect(_rect(game.booster_bar(), game), before["bar"], "%s: the bar as before" % label)


func test_a_skin_switch_keeps_one_button() -> void:
	var game: GameScreen = _game(&"gumdrop", PHONES[COVER])
	game.apply_skin(SkinCatalog.get_skin(&"nova"))
	_lay_out(game, PHONES[COVER])
	_assert_form(game, "below the board after the switch")
	assert_eq(game.find_children("Coffee", "", true, false).size(), 1, "one button after the switch")
	assert_eq(game.coffee_button().get_index(), 1, "still just above the new backdrop")
	assert_true(game.is_coffee_shown(), "and shown")
	var icon: SkinIcon = game.coffee_button().call(&"icon") as SkinIcon
	assert_eq(icon.get(&"_override"), SkinCatalog.get_skin(&"nova").color(&"ink_muted"), "in the new skin's ink_muted")
	# In the gutter, a switch keeps the stacked form, in the new skin.
	var wide: GameScreen = _game(&"gumdrop", PHONES[INNER])
	_assert_form(wide, "gumdrop in the gutter")
	wide.apply_skin(SkinCatalog.get_skin(&"slate"))
	_lay_out(wide, PHONES[INNER])
	assert_eq(wide.coffee_place(), GameScreen.CoffeePlace.GUTTER, "slate: still in the gutter")
	_assert_form(wide, "slate in the gutter after the switch")
	assert_eq(wide.find_children("Coffee", "", true, false).size(), 1, "one button after the switch in the gutter")
	var lines: Array[Label] = wide.coffee_button().call(&"labels")
	assert_eq(lines.size(), 2, "two lines after the switch")
	assert_eq(lines[0].text, "Buy me", "the top line as written")
	assert_eq(lines[1].text, "a coffee", "the bottom line as written")


## The form follows the place: stacked in the gutter, one line below the
## board (and left as it was with no place).
func _assert_form(game: GameScreen, label: String) -> void:
	var stacked: bool = bool(game.coffee_button().call(&"is_stacked"))
	match game.coffee_place():
		GameScreen.CoffeePlace.GUTTER:
			assert_true(stacked, "%s: stacked in the gutter" % label)
		GameScreen.CoffeePlace.BELOW_BOARD:
			assert_false(stacked, "%s: one line below the board" % label)


# QA21-05: the stacked form in the Fold5 inner screen's gutter.

func test_qa21_05_fold5_inner_gutter_has_room_in_every_skin() -> void:
	# 7.15 Measured, the touch area's clearance on both sides, per inset case.
	var expected: Dictionary[int, Dictionary] = {
		INNER: {&"gumdrop": 111.0, &"slate": 120.0, &"nova": 101.0},
		5: {&"gumdrop": 101.0, &"slate": 110.0, &"nova": 91.0},
		6: {&"gumdrop": 87.0, &"slate": 96.0, &"nova": 76.0},
	}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for index: int in expected:
			var phone: Dictionary = PHONES[index]
			var label: String = "%s %s" % [skin_id, phone["name"]]
			assert_near(_canvas(phone).x, 1998.5, 0.05, "%s: the inner screen's logical width" % label)
			var game: GameScreen = _game(skin_id, phone)
			assert_eq(game.coffee_place(), GameScreen.CoffeePlace.GUTTER, "%s: in the gutter" % label)
			assert_true(game.is_coffee_shown(), "%s: shown" % label)
			var coffee: Control = game.coffee_button()
			assert_true(bool(coffee.call(&"is_stacked")), "%s: stacked" % label)
			var lines: Array[Label] = coffee.call(&"labels")
			assert_eq(lines.size(), 2, "%s: two lines" % label)
			if lines.size() == 2:
				assert_eq(lines[0].text, "Buy me", "%s: the top line as written" % label)
				assert_eq(lines[1].text, "a coffee", "%s: the bottom line as written" % label)
			var icon: SkinIcon = coffee.call(&"icon") as SkinIcon
			assert_eq(icon.get(&"_icon"), &"coffee", "%s: the coffee icon" % label)
			assert_eq(icon.get(&"_override"), skin.color(&"ink_muted"), "%s: in ink_muted" % label)
			var safe: Rect2 = _safe(phone)
			var column: Rect2 = SafeArea.column_in(safe, skin)
			var touch: Rect2 = _touch_rect(game, game)
			var to_safe: float = touch.position.x - safe.position.x
			var to_column: float = column.position.x - touch.end.x
			assert_true(to_safe >= 24.0, "%s: at least 24 px from the safe edge" % label)
			assert_true(to_column >= 24.0, "%s: at least 24 px from the column" % label)
			assert_true(to_safe >= skin.num(&"space_m") - 0.01 and to_column >= skin.num(&"space_m") - 0.01, "%s: at least space_m on both sides" % label)
			var wanted: float = float(expected[index][skin_id])
			assert_near(to_safe, wanted, 2.0, "%s: the clearance to the safe edge 7.15 measures" % label)
			assert_near(to_column, wanted, 2.0, "%s: the clearance to the column 7.15 measures" % label)
			var before: Dictionary = _layout_before(game, phone)
			_assert_rect(_rect(game.board(), game), before["board"], "%s: the board as before" % label)
			_assert_rect(_rect(game.hud(), game), before["hud"], "%s: the HUD as before" % label)
			_assert_rect(_rect(game.booster_bar(), game), before["bar"], "%s: the bar as before" % label)
			print("  %s: gutter %.1f px, stacked %d x %d, touch %.1f px wide, clear %.1f px of the safe edge and %.1f px of the column" % [label, column.position.x - safe.position.x, roundi(coffee.size.x), roundi(coffee.size.y), touch.size.x, to_safe, to_column])


func test_setting_the_current_form_does_nothing() -> void:
	var host: Control = U.stage(Vector2i(1080, 2400), &"gumdrop")
	_hosts.append(host)
	var button: Control = CoffeeButton.new()
	host.add_child(button)
	button.call(&"setup", SkinCatalog.get_skin(&"gumdrop"))
	var changes: Array[int] = []
	var count: Callable = func() -> void: changes.append(1)
	button.minimum_size_changed.connect(count)
	var title: Label = button.call(&"label") as Label
	button.call(&"set_stacked", false)
	assert_eq(changes.size(), 0, "one line to one line: no size change")
	assert_eq(button.call(&"label"), title, "and no rebuild")
	button.call(&"set_stacked", true)
	assert_true(bool(button.call(&"is_stacked")), "stacked")
	var top: Label = button.call(&"label") as Label
	changes.clear()
	button.call(&"set_stacked", true)
	assert_eq(changes.size(), 0, "stacked to stacked: no size change")
	assert_eq(button.call(&"label"), top, "and no rebuild")
	button.minimum_size_changed.disconnect(count)


# AT-155: hidden while something is open over the play screen.

func _assert_hidden(game: GameScreen, root: Control, label: String) -> void:
	var coffee: Control = game.coffee_button()
	assert_false(game.is_coffee_shown(), "%s: hidden" % label)
	assert_false(coffee.visible, "%s: not drawn" % label)
	assert_eq(coffee.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: ignores touches" % label)
	var before: int = _sent.size()
	var at: Vector2 = _coffee_center(game, root)
	var router: Router = Router.new(root)
	assert_ne(router.find_at(at), coffee, "%s: a touch where it was never reaches it" % label)
	router.tap(at)
	assert_eq(_sent.size(), before, "%s: a tap where it was does nothing" % label)


func _assert_shown(game: GameScreen, label: String) -> void:
	assert_true(game.is_coffee_shown(), "%s: shown" % label)
	assert_true(game.coffee_button().visible, "%s: drawn" % label)
	assert_eq(game.coffee_button().mouse_filter, Control.MOUSE_FILTER_PASS, "%s: takes taps" % label)


func test_at_155_hidden_with_targeting_pause_and_the_confirmation() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var app: App = _start(skin_id, U.run(U.board_p(), 5000, U.snapshot_board(), 40), PHONES[COVER])
		var game: GameScreen = app.game_screen()
		_assert_shown(game, "%s plain" % skin_id)
		app.session.press_booster(&"hammer")
		_assert_hidden(game, app, "%s targeting (BC9)" % skin_id)
		app.session.cancel_targeting()
		_assert_shown(game, "%s after targeting" % skin_id)
		app.open_pause()
		_assert_hidden(game, app, "%s Pause" % skin_id)
		(app.top_panel() as PausePanel).settings_chosen.emit()
		_assert_hidden(game, app, "%s Settings over Pause" % skin_id)
		(app.top_panel() as SettingsPanel).about_row().emit_signal(&"tapped")
		_assert_hidden(game, app, "%s About over Settings over Pause" % skin_id)
		app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		_assert_hidden(game, app, "%s back to Pause" % skin_id)
		(app.top_panel() as PausePanel).info_chosen.emit()
		_assert_hidden(game, app, "%s Info over Pause" % skin_id)
		app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		(app.top_panel() as PausePanel).new_game_chosen.emit()
		assert_true(app.top_panel() is ConfirmDialog, "%s: the confirmation is open" % skin_id)
		_assert_hidden(game, app, "%s the new game confirmation" % skin_id)
		(app.top_panel() as ConfirmDialog).cancelled.emit()
		_assert_hidden(game, app, "%s Pause again" % skin_id)
		app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		assert_true(app.open_panels().is_empty(), "%s: back resumed" % skin_id)
		_assert_shown(game, "%s after Pause" % skin_id)
		U.stop_app(_app)
		_app = null
		U.remove_temp_dir(_dir)
		_dir = ""


func test_at_155_hidden_with_the_offer_and_the_end_of_run_screen() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var app: App = _start(skin_id, U.run(U.board_d1024(), 5000), PHONES[COVER])
		var game: GameScreen = app.game_screen()
		assert_true(app.session.is_offer_open(), "%s: the offer is open" % skin_id)
		_lay_out(game, PHONES[COVER])
		_assert_hidden(game, app, "%s the offer (BC10)" % skin_id)
		game.offer_panel().buy_button().pressed.emit()
		U.settle(app)
		_settle(game)
		assert_false(app.session.is_offer_open(), "%s: Shuffle closed the offer" % skin_id)
		_lay_out(game, PHONES[COVER])
		_assert_shown(game, "%s after the offer" % skin_id)
		# Shuffle again until the offer comes back is not certain, so end the
		# run from a fresh offer instead.
		U.stop_app(_app)
		U.remove_temp_dir(_dir)
		app = _start(skin_id, U.run(U.board_d1024(), 300), PHONES[COVER])
		game = app.game_screen()
		assert_true(app.top_panel() is EndPanel or app.session.is_offer_open(), "%s: the offer, or the end at once" % skin_id)
		if app.session.is_offer_open():
			game.offer_panel().end_run_button().pressed.emit()
		assert_true(app.top_panel() is EndPanel, "%s: the end of run screen" % skin_id)
		_lay_out(game, PHONES[COVER])
		_assert_hidden(game, app, "%s the end of run screen" % skin_id)
		(app.top_panel() as EndPanel).new_game_chosen.emit()
		U.settle(app)
		_settle(game)
		_lay_out(game, PHONES[COVER])
		assert_true(app.open_panels().is_empty(), "%s: a new run" % skin_id)
		_assert_shown(game, "%s after the end of run screen" % skin_id)
		U.stop_app(_app)
		_app = null
		U.remove_temp_dir(_dir)
		_dir = ""


func test_a_press_held_when_pause_opens_never_taps() -> void:
	var app: App = _start(&"gumdrop", U.run(U.board_p(), 5000), PHONES[COVER])
	var game: GameScreen = app.game_screen()
	var router: Router = Router.new(app)
	var at: Vector2 = _coffee_center(game, app)
	router.down(0, at)
	assert_true(game.coffee_button().call(&"is_held"), "held")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.top_panel() is PausePanel, "back opened Pause")
	assert_false(game.coffee_button().call(&"is_held"), "the press is dropped")
	router.up(0, at)
	assert_true(_sent.is_empty(), "the release behind Pause makes no hand off")


# AT-170: never the tail of a drag.

func _at_170_shapes() -> Array[int]:
	return [COVER, INNER]


func test_at_170_a_chain_lifted_on_the_button() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var session: GameSession = game.get(&"_session") as GameSession
			router.down(0, _cell(game, Vector2i(1, 6)))
			router.slide(0, _cell(game, Vector2i(1, 6)), _cell(game, Vector2i(2, 6)))
			router.slide(0, _cell(game, Vector2i(2, 6)), _cell(game, Vector2i(3, 6)))
			_slide_off_to_button(router, game, _cell(game, Vector2i(3, 6)))
			router.up(0, _coffee_center(game, game))
			assert_true(_sent.is_empty(), "%s (a): no hand off" % label)
			assert_eq(U.text(session.state.score), "5008", "%s (a): the chain committed (D-06)" % label)


func test_at_170_a_one_tile_chain_lifted_on_the_button() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var session: GameSession = game.get(&"_session") as GameSession
			var cells: PackedInt64Array = session.state.cells.duplicate()
			router.down(0, _cell(game, Vector2i(2, 7)))
			_slide_off_to_button(router, game, _cell(game, Vector2i(2, 7)))
			router.up(0, _coffee_center(game, game))
			assert_true(_sent.is_empty(), "%s (b): no hand off" % label)
			assert_eq(U.text(session.state.score), "5000", "%s (b): nothing scored" % label)
			assert_eq(session.state.cells, cells, "%s (b): the board unchanged" % label)
			assert_false(session.is_dragging(), "%s (b): the drag ended" % label)


func test_at_170_a_targeting_press_lifted_on_the_button() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var session: GameSession = game.get(&"_session") as GameSession
			var at: Vector2 = _coffee_center(game, game)
			var cells: PackedInt64Array = session.state.cells.duplicate()
			session.press_booster(&"hammer")
			assert_false(game.is_coffee_shown(), "%s (c): hidden while targeting" % label)
			router.down(0, _cell(game, Vector2i(0, 0)))
			assert_false(game.is_coffee_shown(), "%s (c): hidden throughout" % label)
			router.slide(0, _cell(game, Vector2i(0, 0)), at)
			assert_false(game.is_coffee_shown(), "%s (c): hidden throughout" % label)
			router.up(0, at)
			assert_true(_sent.is_empty(), "%s (c): no hand off" % label)
			assert_eq(session.state.cells, cells, "%s (c): nothing hammered" % label)
			assert_eq(U.text(session.state.score), "5000", "%s (c): nothing charged" % label)
			assert_eq(session.targeting_booster(), &"hammer", "%s (c): Hammer stays active (D-43)" % label)
			session.cancel_targeting()
			assert_true(game.is_coffee_shown(), "%s (c): back once targeting ends" % label)


func test_at_170_a_second_finger_on_the_button() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var session: GameSession = game.get(&"_session") as GameSession
			var at: Vector2 = _coffee_center(game, game)
			router.down(0, _cell(game, Vector2i(1, 6)))
			router.slide(0, _cell(game, Vector2i(1, 6)), _cell(game, Vector2i(2, 6)))
			router.down(1, at)
			router.up(1, at)
			assert_true(_sent.is_empty(), "%s (d): the second finger does nothing" % label)
			assert_true(session.is_dragging(), "%s (d): the chain is still held" % label)
			router.up(0, _cell(game, Vector2i(2, 6)))
			assert_true(_sent.is_empty(), "%s (d): no hand off" % label)
			assert_eq(U.text(session.state.score), "5004", "%s (d): the chain commits on the first finger's lift" % label)


func test_at_170_a_press_on_the_button_dragged_away() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var session: GameSession = game.get(&"_session") as GameSession
			var cells: PackedInt64Array = session.state.cells.duplicate()
			var at: Vector2 = _coffee_center(game, game)
			router.down(0, at)
			router.slide(0, at, _cell(game, Vector2i(2, 4)))
			router.up(0, _cell(game, Vector2i(2, 4)))
			assert_true(_sent.is_empty(), "%s (e): moved onto the board: no hand off" % label)
			assert_eq(session.state.cells, cells, "%s (e): the board unchanged" % label)
			assert_false(session.is_dragging(), "%s (e): no chain" % label)
			# Beyond the 24 px tap movement and back is not a tap either.
			router.down(0, at)
			router.slide(0, at, at + Vector2(0.0, 30.0))
			router.slide(0, at + Vector2(0.0, 30.0), at)
			router.up(0, at)
			assert_true(_sent.is_empty(), "%s (e): out and back: no hand off" % label)


func test_at_170_a_press_from_the_hud_or_bar_lifted_on_the_button() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var at: Vector2 = _coffee_center(game, game)
			var hud: Rect2 = _rect(game.hud(), game)
			var bar: Rect2 = _rect(game.booster_bar(), game)
			var starts: Array[Vector2] = [hud.position + Vector2(hud.size.x * 0.5, 4.0), bar.position + Vector2(2.0, 2.0), bar.end - Vector2(2.0, 2.0)]
			for start: Vector2 in starts:
				assert_ne(router.find_at(start), game.coffee_button(), "%s (f): the press is not on the button" % label)
				router.down(0, start)
				router.slide(0, start, at)
				router.up(0, at)
			assert_true(_sent.is_empty(), "%s (f): no hand off" % label)


func test_at_170_and_at_157_a_clean_tap() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for shape: int in _at_170_shapes():
			var label: String = "%s %s" % [skin_id, PHONES[shape]["name"]]
			var game: GameScreen = _game(skin_id, PHONES[shape])
			var router: Router = Router.new(game)
			var at: Vector2 = _coffee_center(game, game)
			assert_eq(router.find_at(at), game.coffee_button(), "%s: the button is on top at its center" % label)
			_sent = []
			router.tap(at)
			assert_eq(_sent.size(), 1, "%s (g): exactly one hand off" % label)
			for index: int in 3:
				router.tap(at + Vector2(6.0, -5.0))
			assert_eq(_sent.size(), 4, "%s: four taps, four hand offs (AT-157)" % label)
			for address: String in _sent:
				assert_eq(address, Copy.COFFEE_URL, "%s: the one constant" % label)
			# The edge of the touch area, space_s past the content, counts.
			var touch: Rect2 = _touch_rect(game, game)
			router.tap(Vector2(touch.position.x + 1.0, touch.get_center().y))
			assert_eq(_sent.size(), 5, "%s: the touch area's edge" % label)
			_sent = []


## From a point on the board, off its right edge in the same row, down below
## the board, then onto the button: only tiles of that row to the right are
## crossed, and the path never comes back over the chain.
func _slide_off_to_button(router: Router, game: GameScreen, from: Vector2) -> void:
	var board: Rect2 = _rect(game.board(), game)
	var side: Vector2 = Vector2(board.end.x + 16.0, from.y)
	var below: Vector2 = Vector2(board.end.x + 16.0, board.end.y + 8.0)
	router.slide(0, from, side)
	router.slide(0, side, below)
	router.slide(0, below, _coffee_center(game, game))


# AT-171: a tap changes nothing in the run or the save.

func _files(folder: String) -> Dictionary[String, PackedByteArray]:
	var found: Dictionary[String, PackedByteArray] = {}
	for file_name: String in DirAccess.get_files_at(folder):
		found[file_name] = FileAccess.get_file_as_bytes(folder.path_join(file_name))
	return found


## The save files equal files byte for byte, and the run equals state, in
## the session and as read back from the save. After a lifecycle save
## (app pause or focus loss, GDD 15.1) the run and profile files are written
## again with the same bytes, and each .bak then holds those same bytes (the
## previous file, SaveService's backup rule), so a .bak is compared with
## its file instead.
func _assert_untouched(app: App, files: Dictionary[String, PackedByteArray], state: RunState, label: String, saved_again: bool) -> void:
	U.settle(app)
	var now: Dictionary[String, PackedByteArray] = _files(_dir)
	assert_eq(now.keys(), files.keys(), "%s: the same save files" % label)
	for file_name: String in files:
		var expected: PackedByteArray = files[file_name]
		if saved_again and file_name.ends_with(".bak"):
			expected = files.get(file_name.trim_suffix(".bak"), PackedByteArray())
		assert_true(now.get(file_name, PackedByteArray()) == expected, "%s: %s byte for byte" % [label, file_name])
	assert_true(app.session.state.equals(state), "%s: the run as noted" % label)
	var service: SaveService = SaveService.new(_dir)
	var loaded: RunState = service.load_run(app.config)
	assert_not_null(loaded, "%s: the saved run loads" % label)
	if loaded != null:
		assert_true(loaded.equals(state), "%s: and equals the run as noted" % label)


func test_at_171_a_tap_leaves_the_run_and_the_save_untouched() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var label: String = "%s" % skin_id
		# 3 stars and 1 free booster held (the 8192 tile), Undo after a chain.
		var app: App = _start(skin_id, U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 13), 9000), PHONES[COVER], 9000, 13)
		var game: GameScreen = app.game_screen()
		var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
		assert_true(app.session.commit_chain(chain).accepted, "%s: a chain" % label)
		U.settle(app)
		_settle(game)
		_lay_out(game, PHONES[COVER])
		assert_true(app.session.stars() >= 3 and app.session.free_held() >= 1, "%s: 3 stars and a free booster held" % label)
		var undo: BoosterStatus = null
		for status: BoosterStatus in app.session.booster_statuses():
			if status.id == &"undo":
				undo = status
		assert_true(undo != null and undo.usable, "%s: Undo enabled" % label)
		var noted: RunState = app.session.state.copy()
		var files: Dictionary[String, PackedByteArray] = _files(_dir)
		var statuses: String = _statuses(app)
		var best: String = U.text(app.records.best_score)
		var skin_before: StringName = app.settings.skin_id
		var sound_before: bool = app.settings.sound_on
		var clicks: int = app.audio.click_requests
		var router: Router = Router.new(app)
		# (a) Tap, the app goes to the background and comes back.
		router.tap(_coffee_center(game, app))
		assert_eq(_sent.size(), 1, "%s (a): one hand off" % label)
		assert_eq(app.audio.click_requests, clicks, "%s (a): no click" % label)
		_assert_untouched(app, files, noted, "%s (a) right after the tap" % label, false)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		assert_eq(app.game_screen(), game, "%s (a): the play screen as left" % label)
		assert_true(app.open_panels().is_empty(), "%s (a): no splash, no panel" % label)
		_assert_untouched(app, files, noted, "%s (a) after pause and resume" % label, true)
		assert_eq(_statuses(app), statuses, "%s (a): booster costs and usability" % label)
		assert_eq(U.text(app.records.best_score), best, "%s (a): Best Score" % label)
		assert_eq(app.settings.skin_id, skin_before, "%s (a): skin" % label)
		assert_eq(app.settings.sound_on, sound_before, "%s (a): sound" % label)
		# (b) Another chain, and a tap while it is still showing.
		assert_true(_commit_any_pair(app.session), "%s (b): another chain" % label)
		assert_true(game.board().is_animating(), "%s (b): the move is still showing" % label)
		U.settle(app)
		var noted_b: RunState = app.session.state.copy()
		var files_b: Dictionary[String, PackedByteArray] = _files(_dir)
		assert_true(game.board().is_animating(), "%s (b): still showing at the tap" % label)
		router.tap(_coffee_center(game, app))
		assert_eq(_sent.size(), 2, "%s (b): one hand off mid move" % label)
		_assert_untouched(app, files_b, noted_b, "%s (b) right after the tap" % label, false)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		_assert_untouched(app, files_b, noted_b, "%s (b) after pause" % label, true)
		_settle(game)
		assert_true(app.session.state.equals(noted_b), "%s (b): the move finished as noted" % label)
		U.stop_app(_app)
		_app = null
		U.remove_temp_dir(_dir)
		_dir = ""
		_sent = []


## Commits the first two tile chain the board accepts (side by side, equal).
func _commit_any_pair(session: GameSession) -> bool:
	var config: GameConfig = session.config
	for y: int in config.rows:
		for x: int in config.columns:
			for step: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var other: Vector2i = Vector2i(x, y) + step
				if other.x >= config.columns or other.y >= config.rows:
					continue
				if session.state.value_at(Vector2i(x, y)) != session.state.value_at(other):
					continue
				var chain: Array[Vector2i] = [Vector2i(x, y), other]
				if session.commit_chain(chain).accepted:
					return true
	return false


func _statuses(app: App) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for status: BoosterStatus in app.session.booster_statuses():
		parts.append("%s %d %s %s" % [status.id, status.cost, status.usable, status.free])
	return ", ".join(parts)


## AT-171 (c) and (d): the app ended while the browser is open, and the
## Pause row (BC12).
func test_at_171_after_a_kill_and_from_pause() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var label: String = "%s" % skin_id
		var app: App = _start(skin_id, U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 13), 9000), PHONES[COVER], 9000, 13)
		var game: GameScreen = app.game_screen()
		var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
		assert_true(app.session.commit_chain(chain).accepted, "%s: a chain" % label)
		U.settle(app)
		_settle(game)
		_lay_out(game, PHONES[COVER])
		var noted: RunState = app.session.state.copy()
		var statuses: String = _statuses(app)
		# (d) Pause, its row, the browser, back, Resume.
		app.open_pause()
		var pause: PausePanel = app.top_panel() as PausePanel
		var row: Control = pause.coffee_button()
		_press(row, true)
		_press(row, false)
		assert_eq(_sent.size(), 1, "%s (d): one hand off from Pause" % label)
		assert_eq(_sent[0], Copy.COFFEE_URL, "%s (d): the one constant" % label)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		assert_eq(app.top_panel(), pause, "%s (d): Pause as it was" % label)
		assert_false(pause.is_closing(), "%s (d): still open" % label)
		assert_eq(app.game_screen(), game, "%s (d): over the same play screen, no splash" % label)
		assert_false(game.is_coffee_shown(), "%s (d): the play screen button hidden behind it" % label)
		pause.resume_chosen.emit()
		assert_true(app.open_panels().is_empty(), "%s (d): resumed" % label)
		assert_true(game.is_coffee_shown(), "%s (d): the play screen button back" % label)
		assert_true(app.session.state.equals(noted), "%s (d): the run as noted" % label)
		assert_eq(_statuses(app), statuses, "%s (d): booster costs and usability" % label)
		# (c) A tap, the app goes to the background and the system ends it.
		Router.new(app).tap(_coffee_center(game, app))
		assert_eq(_sent.size(), 2, "%s (c): one hand off" % label)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		U.stop_app(_app)
		_app = U.start_app(_dir, _quits)
		assert_not_null(_app.splash_screen(), "%s (c): a launch shows the splash" % label)
		assert_null(_app.game_screen(), "%s (c): not the play screen" % label)
		U.play(_app)
		assert_true(_app.session.state.equals(noted), "%s (c): PLAY shows the run as noted" % label)
		assert_eq(_statuses(_app), statuses, "%s (c): booster costs and usability" % label)
		U.stop_app(_app)
		_app = null
		U.remove_temp_dir(_dir)
		_dir = ""
		_sent = []


func _press(target: Control, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = Vector2(40.0, 40.0)
	event.global_position = Vector2(40.0, 40.0)
	target._gui_input(event)
