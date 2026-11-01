# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name PageFrame
extends ScreenFrame
## A page with a back arrow, a title and a scrolling column. Info, About, the
## mode screen and the license reader are pages. It always opens at the top.

var title_label: Label
var scroll: ScrollContainer
## Put the page's content here. It is centered and never wider than
## Layout.CONTENT_MAX.
var column: VBoxContainer
var back_button: TapButton

var _row: HBoxContainer


func _init(title: String) -> void:
	super()
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override(&"separation", 12)
	add_child(root)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 16)
	back_button = UiKit.icon_button(&"back")
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.tapped.connect(func() -> void: back_requested.emit())
	header.add_child(back_button)
	title_label = UiKit.label(title, &"TitleLabel")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)
	root.add_child(header)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = int(TapButton.DEADZONE)
	root.add_child(scroll)
	_row = HBoxContainer.new()
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(_row)
	column = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 24)
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_row.add_child(column)


func _ready() -> void:
	scroll.scroll_vertical = 0


func _relayout() -> void:
	column.custom_minimum_size.x = Layout.content_width(window_size.x, safe)
