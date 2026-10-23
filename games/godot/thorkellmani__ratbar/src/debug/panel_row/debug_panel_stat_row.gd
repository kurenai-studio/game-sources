class_name DebugPanelStatRow extends VBoxContainer

signal edit_requested

@onready var field_value: LineEdit = $Values/Value
@onready var field_label: Label = $Values/Item

var _stat_getter: Callable
var _stat_setter: Callable
var _binding_failed: bool = false

func bind(getter: Callable, setter: Callable) -> void:
	_stat_getter = getter
	_stat_setter = setter
	field_value.text_changed.connect(_on_value_text_changed)


func _on_value_text_changed(text: String) -> void:
	if _binding_failed:
		return

	edit_requested.emit()

	if not is_edit_input_valid():
		return

	_stat_setter.call(text.to_float())


func is_edit_input_valid() -> bool:
	var text: String = field_value.text
	return text.is_valid_float() and is_finite(text.to_float())


func update_field() -> void:
	if _binding_failed:
		return

	if not _stat_getter.is_valid() or not _stat_setter.is_valid():
		_disable_invalid_binding("Getter or setter is invalid.")
		return

	var value: Variant = _stat_getter.call()

	if not (value is float or value is int):
		_disable_invalid_binding("Expected a numeric value.")
		return

	if not is_finite(float(value)):
		_disable_invalid_binding("Expected a finite numeric value.")
		return

	field_value.text = "%.0f" % value


func _disable_invalid_binding(reason: String) -> void:
	_binding_failed = true
	field_value.editable = false
	field_value.text = "Unavailable"

	push_error(
		"Debug field '%s' has an invalid binding: %s"
		% [field_label.text, reason]
	)
