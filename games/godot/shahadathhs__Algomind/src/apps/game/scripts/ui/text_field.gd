class_name TextField
extends Control
## A single-line text field in the Instruction Tape style: a chamfered outline (thicker while it
## has focus) around a plain line edit. `secret` hides what is typed (passwords).

signal submitted(text: String)

var placeholder := ""
var secret := false
var email := false
var accessible_label := ""

var text: String:
	get:
		return _edit.text if _edit != null else ""
	set(value):
		if _edit != null:
			_edit.text = value

var _edit: LineEdit


func _ready() -> void:
	custom_minimum_size = Vector2(0, 52)
	_edit = LineEdit.new()
	_edit.placeholder_text = placeholder
	_edit.secret = secret
	_edit.virtual_keyboard_type = (
		LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS if email else LineEdit.KEYBOARD_TYPE_DEFAULT
	)
	_edit.caret_blink = false
	_edit.context_menu_enabled = false
	_edit.select_all_on_focus = false
	_edit.max_length = 254
	_edit.accessibility_name = accessible_label
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "focus", "read_only"]:
		_edit.add_theme_stylebox_override(state, empty)
	_edit.add_theme_font_override("font", UiKit.font(0))
	_edit.add_theme_font_size_override("font_size", 20)
	_edit.add_theme_color_override("font_color", Palette.INK)
	_edit.add_theme_color_override("font_placeholder_color", Palette.MUTE)
	_edit.add_theme_color_override("caret_color", Palette.INK)
	_edit.add_theme_color_override("selection_color", Palette.SIGNAL)
	_edit.text_submitted.connect(func(value: String) -> void: submitted.emit(value))
	_edit.focus_entered.connect(queue_redraw)
	_edit.focus_exited.connect(queue_redraw)
	add_child(_edit)
	resized.connect(_place)
	_place()


func _place() -> void:
	if _edit == null:
		return
	_edit.position = Vector2(14.0, 4.0)
	_edit.size = Vector2(maxf(size.x - 28.0, 0.0), maxf(size.y - 8.0, 0.0))


func grab_edit_focus() -> void:
	if _edit != null:
		_edit.grab_focus()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if UiLook.depth:
		# A field is recessed into the screen, like the tape trough.
		DepthKit.trough(self, rect)
	else:
		UiKit.fill_chamfer(self, rect, Palette.GROUND)
		UiKit.outline_chamfer(self, rect, Palette.INK)
	if _edit != null and _edit.has_focus():
		UiKit.outline_chamfer(self, rect.grow(-3.0), Palette.INK)
