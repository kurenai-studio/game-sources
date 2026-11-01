extends "res://tests/base_test.gd"
## The Buy me a coffee row in Pause (DESIGN_SYSTEM.md 7.3, GDD 15.5 BC12,
## AT-155, AT-157). The hand off is captured (TH24), so no browser opens.
## Headless tests never enter the scene tree, so the panel is placed with
## layout_in, sized by hand and its containers sorted with U.layout.

const U := preload("res://tests/ui/ui_fixtures.gd")
const Copy := preload("res://src/ui/screen_copy.gd")
const CoffeeButton := preload("res://src/ui/coffee_button.gd")
const PlayScreenTest := preload("res://tests/ui/test_coffee_play_screen.gd")
const UiParts := preload("res://src/ui/ui_parts.gd")

const PHONE: Vector2i = Vector2i(1080, 2400)
## 16:9 with a 48 dp button bar (7.15).
const WIDE: Vector2i = Vector2i(1350, 2400)
const WIDE_SAFE: Rect2 = Rect2(0.0, 90.0, 1350.0, 2130.0)

var _hosts: Array[Control] = []
var _sent: Array[String] = []


func before_each() -> void:
	_hosts = []
	_sent = []
	CoffeeButton.opener = _capture
	Motion.bind_tweens = false


func after_each() -> void:
	for host: Control in _hosts:
		U.free_stage(host)
	CoffeeButton.use_system_opener()
	Motion.bind_tweens = true


func _capture(address: String) -> Error:
	_sent.append(address)
	return OK


## Pause in skin on a size_px screen with safe area safe, laid out.
func _pause(skin_id: StringName, size_px: Vector2i, safe: Rect2) -> PausePanel:
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	var host: Control = U.stage(size_px, skin_id)
	_hosts.append(host)
	var pause: PausePanel = (load("res://scenes/ui/pause_panel.tscn") as PackedScene).instantiate() as PausePanel
	host.add_child(pause)
	U.fit(pause, Vector2(size_px))
	pause.setup(skin)
	var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(size_px))
	pause.layout_in(screen, SafeArea.column_in(safe, skin), skin_id == &"gumdrop")
	_place_by_hand(pause, size_px)
	return pause


## Outside the tree neither anchors nor containers place anything, so this
## places the panel from its offsets and its column the way the boxes would:
## each child its minimum height, the separation between them, full width
## unless it shrinks to its minimum width, centered.
func _place_by_hand(pause: PausePanel, size_px: Vector2i) -> void:
	var panel: PanelContainer = pause.panel()
	var width: float = float(size_px.x) - panel.offset_left + panel.offset_right
	var style: StyleBox = panel.get_theme_stylebox(&"panel")
	var column: VBoxContainer = panel.get_child(0) as VBoxContainer
	column.position = Vector2(style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP))
	column.size = Vector2(width - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT), 0.0)
	var column_height: float = _stack(column, pause.get(&"_skin") as SkinData)
	column.size.y = column_height
	var height: float = column_height + style.get_margin(SIDE_TOP) + style.get_margin(SIDE_BOTTOM)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(panel.offset_left, float(size_px.y) + panel.offset_bottom - height)
	panel.size = Vector2(width, height)


## Places box's children as the box would and returns the height it needs.
## Labels measure nothing outside the tree, so they take their font's line
## height, and the coffee button its content_size.
func _stack(box: Container, skin: SkinData) -> float:
	var separation: float = float(box.get_theme_constant(&"separation")) if box is BoxContainer else 0.0
	var top: float = 0.0
	var left: float = 0.0
	var inner_width: float = box.size.x
	if box is MarginContainer:
		top = float(box.get_theme_constant(&"margin_top"))
		left = float(box.get_theme_constant(&"margin_left"))
		inner_width -= left + float(box.get_theme_constant(&"margin_right"))
	var used: float = top
	for node: Node in box.get_children():
		var child: Control = node as Control
		if child == null or not child.visible:
			continue
		var minimum: Vector2 = child.get_combined_minimum_size()
		if child is Label:
			var role: StringName = UiParts.role(skin, (child as Label).theme_type_variation)
			minimum.y = maxf(minimum.y, skin.font(role).get_height(skin.font_size(role)))
		elif child.get_script() == CoffeeButton:
			minimum = child.call(&"content_size")
		var child_width: float = inner_width
		var x: float = left
		if child.size_flags_horizontal == Control.SIZE_SHRINK_CENTER:
			child_width = minimum.x
			x = left + (inner_width - minimum.x) * 0.5
		child.position = Vector2(x, top)
		child.size = Vector2(child_width, 0.0)
		var height: float = minimum.y
		if child is VBoxContainer or child is MarginContainer:
			height = maxf(height, _stack(child as Container, skin))
		child.size = Vector2(child_width, height)
		used = top + height
		if box is BoxContainer:
			top += height + separation
	if box is MarginContainer:
		used += float(box.get_theme_constant(&"margin_bottom"))
	return used


func _rect(control: Control, root: Control) -> Rect2:
	return U.rect_in(control, root)


func test_pause_has_the_coffee_button_last_in_every_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var pause: PausePanel = _pause(skin_id, PHONE, U.safe_rect(PHONE))
		var coffee: Control = pause.coffee_button()
		var found: Array[Node] = pause.find_children("Coffee", "", true, false)
		assert_eq(found.size(), 1, "%s: one Coffee control" % skin_id)
		assert_eq(found[0], coffee, "%s: the one Pause reports" % skin_id)
		assert_true(coffee.get_script() == CoffeeButton, "%s: the one button component" % skin_id)
		assert_eq((coffee.call(&"label") as Label).text, "Buy me a coffee", "%s: reads as written" % skin_id)
		assert_eq((coffee.call(&"icon") as SkinIcon).get(&"_override"), skin.color(&"ink_muted"), "%s: the icon in ink_muted" % skin_id)
		assert_eq(coffee.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "%s: centered, as wide as its content" % skin_id)
		var all: Array[Node] = pause.panel().find_children("*", "Control", true, false)
		var last_interactive: Control = null
		for node: Node in all:
			var control: Control = node as Control
			if control is Button or control.get_script() == CoffeeButton:
				last_interactive = control
		assert_eq(last_interactive, coffee, "%s: the last control in Pause" % skin_id)
		var settings: Control = pause.find_child("Settings", true, false) as Control
		var settings_rect: Rect2 = _rect(settings, pause)
		var coffee_rect: Rect2 = _rect(coffee, pause)
		assert_near(coffee_rect.position.y - settings_rect.end.y, skin.num(&"space_l"), 0.5, "%s: space_l below Settings (%d px)" % [skin_id, roundi(coffee_rect.position.y - settings_rect.end.y)])
		var reach: float = skin.num(&"space_s")
		var touch: Rect2 = coffee_rect.grow_individual(reach, 0.0, reach, 0.0)
		assert_true(touch.size.x < settings_rect.size.x, "%s: narrower than Settings" % skin_id)
		assert_near(coffee_rect.get_center().x, settings_rect.get_center().x, 0.5, "%s: centered in the panel" % skin_id)
		assert_near(coffee_rect.size.y, skin.num(&"touch_min"), 0.01, "%s: touch_min tall" % skin_id)
		for button_name: String in ["Resume", "Newgame", "Info", "Settings"]:
			var other: Rect2 = _rect(pause.find_child(button_name, true, false) as Control, pause)
			assert_false(touch.intersects(other), "%s: clear of %s" % [skin_id, button_name])
		print("  %s Pause panel: %d px tall with the coffee row" % [skin_id, roundi(pause.panel().size.y)])


func test_pause_still_fits_the_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for shape: Array in [[PHONE, U.safe_rect(PHONE)], [WIDE, WIDE_SAFE]]:
			var size_px: Vector2i = shape[0]
			var safe: Rect2 = shape[1]
			var label: String = "%s %s" % [skin_id, size_px]
			var pause: PausePanel = _pause(skin_id, size_px, safe)
			var panel: Rect2 = _rect(pause.panel(), pause)
			var column: Rect2 = SafeArea.column_in(safe, skin)
			assert_true(panel.position.x >= column.position.x - 0.01 and panel.end.x <= column.end.x + 0.01, "%s: inside the column's width" % label)
			assert_true(panel.position.y >= safe.position.y, "%s: below the safe area's top (panel top %d)" % [label, roundi(panel.position.y)])
			var coffee: Rect2 = _rect(pause.coffee_button(), pause)
			assert_true(coffee.end.y <= safe.end.y + 0.01, "%s: the coffee button above the bottom inset (%s in %s, safe %s)" % [label, coffee, panel, safe])


func test_pause_tap_hands_off_once_and_a_slide_from_settings_does_not() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var pause: PausePanel = _pause(skin_id, PHONE, U.safe_rect(PHONE))
		var chosen: Array[int] = []
		pause.settings_chosen.connect(func() -> void: chosen.append(1))
		var router: PlayScreenTest.Router = PlayScreenTest.Router.new(pause)
		var coffee: Control = pause.coffee_button()
		var at: Vector2 = _rect(coffee, pause).get_center()
		assert_eq(router.find_at(at), coffee, "%s: the button takes a touch on it" % skin_id)
		router.tap(at)
		assert_eq(_sent.size(), 1, "%s: one tap, one hand off" % skin_id)
		for index: int in 3:
			router.tap(at)
		assert_eq(_sent.size(), 4, "%s: four taps, four hand offs" % skin_id)
		for address: String in _sent:
			assert_eq(address, Copy.COFFEE_URL, "%s: the one constant" % skin_id)
		_sent = []
		var settings: Control = pause.find_child("Settings", true, false) as Control
		var from: Vector2 = _rect(settings, pause).get_center()
		assert_eq(router.find_at(from), settings, "%s: the press lands on Settings" % skin_id)
		router.down(0, from)
		router.slide(0, from, at)
		router.up(0, at)
		assert_true(_sent.is_empty(), "%s: a press on Settings released on the coffee button: no hand off" % skin_id)
