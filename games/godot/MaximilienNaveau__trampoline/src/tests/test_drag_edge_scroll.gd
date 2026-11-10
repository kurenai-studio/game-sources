# Standalone checks for drag_steady_scroll.gd, runnable via:
#   godot4 --headless --path . --script tests/test_drag_edge_scroll.gd
# See tests/test_tiles.gd for why this isn't a test-framework addon.
#
# A page taller than its ScrollContainer, a drag started by script
# (`force_drag`, what a picked-up tile does, see tile_panel.gd) and fake
# mouse moves (`push_input`, which is how Godot hands real ones over):
# the page must hold still mid-screen, and scroll near its edges.
extends SceneTree

const DragSteadyScroll := preload("res://scripts/drag_steady_scroll.gd")

var _failures := 0
var _scroll: ScrollContainer


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


# A SceneTree script's entry point. The checks need frames to go by
# (`await`, below), so they run in `_run`, which Godot resumes frame after
# frame while this returns straight away.
func _initialize() -> void:
	_run()


func _run() -> void:
	# The phone's logical screen (see project.godot), unscaled: a script
	# run like this one gets a 64x64 window, onto which Godot would scale
	# the 480x854 screen — and every fake mouse position with it.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(480, 854)
	# The page: 400 px of screen showing a 2000 px tall content.
	_scroll = DragSteadyScroll.new()
	_scroll.size = Vector2(480, 400)
	var content := Control.new()
	content.custom_minimum_size = Vector2(480, 2000)
	# PASS: let the press reach the page too, as tiles and cells do.
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(content)
	root.add_child(_scroll)
	await _frames(2)
	_scroll.scroll_vertical = 1000

	# A finger goes down mid-page and picks a tile up there.
	_mouse(Vector2(240, 200), true)
	content.force_drag("tile", null)
	await _frames(10)
	_check(_scroll.scroll_vertical == 1000, "the page holds still with the tile mid-screen")

	_mouse(Vector2(240, 395))
	_check(await _scrolls(func(v: int) -> bool: return v > 1000), "near the bottom edge, the page scrolls down")

	_mouse(Vector2(240, 5))
	var from := _scroll.scroll_vertical
	_check(await _scrolls(func(v: int) -> bool: return v < from), "near the top edge, the page scrolls up")
	_check(await _scrolls(func(v: int) -> bool: return v == 0), "it stops at the top of the page")

	# The finger lifts, dropping the tile nowhere: the drag ends.
	_mouse(Vector2(240, 5), false)
	await _frames(2)
	_check(not _scroll.is_processing(), "the edge scrolling stops with the drag")

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


# Moves the fake mouse to `at`, pressing or releasing the left button
# first when `pressed` is given (true/false; null: just a move).
func _mouse(at: Vector2, pressed: Variant = null) -> void:
	if pressed != null:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		button.position = at
		button.global_position = at
		root.push_input(button)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed != false else 0
	root.push_input(motion)


# Lets `count` frames go by.
func _frames(count: int) -> void:
	for i in count:
		await process_frame


# Whether the page's scroll position satisfies `reached` within 3 seconds
# of frames (headless frames are as fast as the machine, so their number
# says nothing about how far the page went).
func _scrolls(reached: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		if reached.call(_scroll.scroll_vertical):
			return true
		await process_frame
	return false
