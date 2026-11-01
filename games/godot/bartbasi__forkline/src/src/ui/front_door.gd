# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name FrontDoor
extends ScreenFrame
## The front door (playbook 6.1), top to bottom: the Settings gear at the top
## right, the wordmark with a small live picture, the big Play button, Info and
## About side by side, and a quiet Buy me a coffee at the bottom. The buttons
## work from the first frame; the picture is decoration. In the landscape layout
## the picture sits left and the buttons right.
##
## The front door changes nothing: its buttons only ask the App to open things.

signal play_pressed()
signal info_pressed()
signal about_pressed()
signal settings_pressed()

const PLAY_HEIGHT: float = 220.0
## The picture leaves room for the thicket that reaches past the left edge.
const ART_SHARE: float = 0.9

var art: FrontDoorArt
var wordmark: Wordmark
var play_button: TapButton
var info_button: TapButton
var about_button: TapButton
var settings_button: TapButton
var coffee_button: CoffeeButton

var _split: BoxContainer
var _hero: VBoxContainer
var _actions: VBoxContainer


func _init() -> void:
	super()
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override(&"separation", 12)
	add_child(root)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_child(UiKit.spacer())
	settings_button = UiKit.icon_button(&"gear")
	settings_button.tapped.connect(func() -> void: settings_pressed.emit())
	top.add_child(settings_button)
	root.add_child(top)
	_split = BoxContainer.new()
	_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override(&"separation", 48)
	root.add_child(_split)
	_hero = VBoxContainer.new()
	_hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hero.alignment = BoxContainer.ALIGNMENT_CENTER
	_hero.add_theme_constant_override(&"separation", 24)
	_split.add_child(_hero)
	wordmark = Wordmark.new()
	wordmark.custom_minimum_size = Vector2(Layout.MIN_TOUCH, 300.0)
	_hero.add_child(wordmark)
	art = FrontDoorArt.new()
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero.add_child(art)
	_actions = VBoxContainer.new()
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_actions.add_theme_constant_override(&"separation", 24)
	_split.add_child(_actions)
	_actions.add_child(UiKit.spacer())
	play_button = UiKit.button("Play", &"PrimaryButton")
	play_button.custom_minimum_size.y = PLAY_HEIGHT
	play_button.add_theme_font_size_override(&"font_size", UiTheme.FONT_TITLE)
	play_button.tapped.connect(func() -> void: play_pressed.emit())
	_actions.add_child(play_button)
	var pair: HBoxContainer = HBoxContainer.new()
	pair.add_theme_constant_override(&"separation", 24)
	info_button = UiKit.button("Info")
	info_button.tapped.connect(func() -> void: info_pressed.emit())
	pair.add_child(info_button)
	about_button = UiKit.button("About")
	about_button.tapped.connect(func() -> void: about_pressed.emit())
	pair.add_child(about_button)
	_actions.add_child(pair)
	_actions.add_child(UiKit.spacer())
	coffee_button = CoffeeButton.new()
	_actions.add_child(coffee_button)


func _relayout() -> void:
	_split.vertical = not landscape
	var width: float = inner_width()
	if landscape:
		art.fit_width((width - 48.0) * 0.5 * ART_SHARE)
		wordmark.custom_minimum_size = Vector2(Layout.MIN_TOUCH, 260.0)
	else:
		art.fit_width(width * ART_SHARE)
		wordmark.custom_minimum_size = Vector2(Layout.MIN_TOUCH, 300.0)
