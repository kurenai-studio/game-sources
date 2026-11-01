# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name AboutScreen
extends PageFrame
## About (playbook 6.3). The brand block comes first, so the wordmark, version,
## credit, copyright line and source link are in the first screenful. Then the
## four sections in the playbook's order, and the feedback block. The license
## rows ask the App to open a LicenseViewer.

signal license_requested(kind: StringName)

const WHAT_IT_IS: String = "Forkline is a tower defense game. You build towers and place gates on forking roads to steer night creatures away from your village."
const OFFLINE: String = "Forkline works fully offline. It collects no data, has no ads or accounts and asks for no permissions. Three buttons hand a fixed address to another app on your phone: Buy me a coffee and the source code link open a web page in your browser, and Send feedback opens a message in your email app. The app itself sends nothing."
const SUPPORTING: String = "Forkline is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated."
const LICENSES: String = "Forkline is free software: you can share and change it under the GNU General Public License, version 3, with additional terms. Any copy keeps the attribution above, and changed versions are marked as changed. Forkline comes with no warranty."
const FEEDBACK_ASK: String = "I'd love to hear what you think: what you enjoyed, where you got stuck, and what you'd like to see next."

var wordmark: Wordmark
var version_label: Label
var made_by_label: Label
var copyright_label: Label
var source_button: TapButton
var coffee_button: CoffeeButton
var feedback_button: TapButton
var license_buttons: Dictionary[StringName, TapButton] = {}


func _init() -> void:
	super("About")
	_brand_block()
	_text_section("What it is", WHAT_IT_IS)
	_text_section("Offline, no data", OFFLINE)
	_supporting()
	_licenses()
	_feedback()


func _brand_block() -> void:
	var box: VBoxContainer = UiKit.section()
	wordmark = Wordmark.new()
	wordmark.custom_minimum_size = Vector2(Layout.MIN_TOUCH, 230.0)
	box.add_child(wordmark)
	var version: String = Links.version()
	if not version.is_empty():
		version_label = UiKit.label("Version %s" % version)
		box.add_child(version_label)
	made_by_label = UiKit.label("Made by Bart Basi")
	box.add_child(made_by_label)
	copyright_label = UiKit.label("Copyright 2026 Play, Inc.")
	box.add_child(copyright_label)
	source_button = UiKit.button("Source code: %s" % Links.SOURCE_SHOWN)
	source_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source_button.add_theme_color_override(&"font_color", Palette.HONEY)
	source_button.add_theme_color_override(&"font_hover_color", Palette.HONEY)
	source_button.add_theme_color_override(&"font_pressed_color", Palette.HONEY)
	source_button.add_theme_color_override(&"font_hover_pressed_color", Palette.HONEY)
	source_button.add_theme_font_size_override(&"font_size", UiTheme.FONT_SMALL)
	source_button.tapped.connect(Links.open_source)
	box.add_child(source_button)
	column.add_child(box.get_parent())


func _text_section(title: String, text: String) -> VBoxContainer:
	var box: VBoxContainer = UiKit.section()
	box.add_child(UiKit.heading(title))
	box.add_child(UiKit.label(text))
	column.add_child(box.get_parent())
	return box


func _supporting() -> void:
	var box: VBoxContainer = _text_section("Supporting Forkline", SUPPORTING)
	coffee_button = CoffeeButton.new()
	box.add_child(coffee_button)


func _licenses() -> void:
	var box: VBoxContainer = _text_section("Licenses", LICENSES)
	_license_row(box, LicenseText.FORKLINE, "Forkline", "GNU GPL version 3, with additional terms")
	_license_row(box, LicenseText.GODOT, "Godot Engine", "MIT license and its parts")
	_license_row(box, LicenseText.FONT, "Outfit font", "SIL Open Font License 1.1")


func _license_row(box: VBoxContainer, kind: StringName, title: String, detail: String) -> void:
	var row: TapButton = UiKit.two_line_button(title, detail, &"Button", &"Label", &"SoftLabel")
	row.custom_minimum_size.y = 200.0
	row.tapped.connect(func() -> void: license_requested.emit(kind))
	license_buttons[kind] = row
	box.add_child(row)


func _feedback() -> void:
	var box: VBoxContainer = UiKit.section()
	box.add_child(UiKit.label(FEEDBACK_ASK))
	feedback_button = UiKit.button("Send feedback")
	feedback_button.tapped.connect(Links.send_feedback)
	box.add_child(feedback_button)
	column.add_child(box.get_parent())
