# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Links and the coffee button: fixed addresses, the feedback draft, and the tap
## rules (one hand-off per clean tap, the deadzone). A recorder replaces the
## phone. Touches pushed through a live GUI are in real_tree_checks.gd.

const Probe: GDScript = preload("res://tests/ui/ui_probe.gd")

var recorder: Probe.Recorder
var button: CoffeeButton


func before_each() -> void:
	recorder = Probe.Recorder.new()
	Links.opener = recorder.record
	button = CoffeeButton.new()
	button.size = Vector2(700, 200)


func after_each() -> void:
	Links.opener = Callable()
	button.free()


func _mouse(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event


func _move(at: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	return event


## Plays a touch on the button the way the GUI does: the script sees each event,
## and a release over the button then presses it.
func _touch(path: Array[Vector2]) -> void:
	button._gui_input(_mouse(true, path[0]))
	for i: int in range(1, path.size() - 1):
		button._gui_input(_move(path[i]))
	var last: Vector2 = path[path.size() - 1]
	button._gui_input(_mouse(false, last))
	if Rect2(Vector2.ZERO, button.size).has_point(last):
		button._pressed()


func test_the_addresses_are_the_fixed_constants() -> void:
	assert_eq(Links.COFFEE_URL, "https://buymeacoffee.com/playinc")
	assert_eq(Links.SOURCE_URL, "https://github.com/bartbasi/forkline")
	assert_eq(Links.SOURCE_SHOWN, "github.com/bartbasi/forkline")
	assert_eq(Links.FEEDBACK_EMAIL, "bartbasi@gmail.com")


func test_open_coffee_and_source_hand_over_their_constants() -> void:
	Links.open_coffee()
	Links.open_source()
	assert_eq(recorder.urls, [Links.COFFEE_URL, Links.SOURCE_URL] as Array[String])


func test_other_addresses_are_refused() -> void:
	Links.open("https://example.com")
	Links.open("https://buymeacoffee.com/playinc/extra")
	Links.open("mailto:someone@example.com?subject=x")
	Links.open("file:///etc/passwd")
	Links.open("")
	assert_eq(recorder.urls.size(), 0)


func test_the_feedback_draft_has_the_subject_and_the_details() -> void:
	var url: String = Links.feedback_url("0.1", "SM-F946B, Android 16")
	assert_true(url.begins_with("mailto:bartbasi@gmail.com?subject="))
	assert_true(url.contains("subject=" + "Forkline feedback (version 0.1)".uri_encode()))
	var body: String = url.get_slice("&body=", 1).uri_decode()
	assert_true(body.contains("Forkline 0.1"))
	assert_true(body.contains("SM-F946B, Android 16"))


func test_the_real_draft_opens() -> void:
	var url: String = Links.feedback_url(Links.version(), Links.device_text())
	assert_true(Links.is_ours(url))
	Links.open(url)
	assert_eq(recorder.urls, [url] as Array[String])


func test_a_draft_with_an_added_header_or_changed_subject_is_refused() -> void:
	var url: String = Links.feedback_url(Links.version(), Links.device_text())
	Links.open(url + "&cc=evil@example.com")
	Links.open(url.replace("subject=", "cc=evil%40example.com&subject="))
	Links.open(url.replace("subject=Forkline", "subject=Other"))
	Links.open("mailto:bartbasi@gmail.com?subject=hello")
	Links.open("mailto:bartbasi@gmail.com?")
	Links.open(Links.feedback_url("9.9.9", "Some other phone"))
	assert_eq(recorder.urls.size(), 0)


func test_a_strange_phone_name_cannot_add_a_recipient_or_header() -> void:
	var url: String = Links.feedback_url("0.1", "X&cc=evil@example.com?bcc=a#b=c\nTo: z")
	assert_eq(url.count("&"), 1, "only the one separator between subject and body is plain")
	assert_eq(url.count("?"), 1)
	assert_false(url.contains("cc=evil"))
	assert_false(url.contains("\n"))
	var body: String = url.get_slice("&body=", 1).uri_decode()
	assert_true(body.contains("X&cc=evil@example.com?bcc=a#b=c"))


func test_send_feedback_uses_the_project_version() -> void:
	Links.send_feedback()
	assert_eq(recorder.urls.size(), 1)
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	assert_eq(Links.version(), version)
	assert_true(recorder.urls[0].contains(("version %s" % version).uri_encode()))


func test_one_clean_tap_hands_the_address_over_exactly_once() -> void:
	_touch([Vector2(50, 50), Vector2(50, 50)])
	assert_eq(recorder.urls, [Links.COFFEE_URL] as Array[String])


func test_a_small_wobble_still_counts_as_a_tap() -> void:
	_touch([Vector2(50, 50), Vector2(50 + TapButton.DEADZONE * 0.5, 50), Vector2(50 + TapButton.DEADZONE * 0.5, 50)])
	assert_eq(recorder.urls.size(), 1)


func test_a_drag_that_ends_on_the_button_is_not_a_tap() -> void:
	_touch([Vector2(50, 50), Vector2(50 + TapButton.DEADZONE * 3.0, 50), Vector2(50 + TapButton.DEADZONE * 3.0, 50)])
	assert_eq(recorder.urls.size(), 0)


func test_a_drag_that_goes_out_and_comes_back_is_not_a_tap() -> void:
	_touch([Vector2(50, 50), Vector2(400, 50), Vector2(50, 50)])
	assert_eq(recorder.urls.size(), 0)


func test_a_press_that_ends_off_the_button_is_not_a_tap() -> void:
	_touch([Vector2(50, 50), Vector2(50, 600)])
	assert_eq(recorder.urls.size(), 0)


func test_a_tap_after_a_drag_works_again() -> void:
	_touch([Vector2(50, 50), Vector2(400, 50), Vector2(50, 50)])
	_touch([Vector2(50, 50), Vector2(50, 50)])
	assert_eq(recorder.urls.size(), 1)


func test_two_taps_hand_over_twice() -> void:
	_touch([Vector2(50, 50), Vector2(50, 50)])
	_touch([Vector2(50, 50), Vector2(50, 50)])
	assert_eq(recorder.urls.size(), 2)


func test_a_press_with_no_matching_touch_does_nothing() -> void:
	button._pressed()
	assert_eq(recorder.urls.size(), 0)


func test_the_coffee_button_is_quiet() -> void:
	assert_eq(button.text, "Buy me a coffee")
	assert_eq(button.theme_type_variation, &"QuietButton")
	assert_not_null(button.icon)
	assert_false(button.disabled)
	assert_eq(button.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "only as wide as its content")
	assert_true(button.custom_minimum_size.y >= Layout.MIN_TOUCH)
	assert_true(button.custom_minimum_size.x >= Layout.MIN_TOUCH)
