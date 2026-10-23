## Displays numeric fields through supplied getter/setter bindings.
class_name DebugPanelGroup extends FoldableContainer


#region State

signal edit_requested

const STAT_ROW := preload(
	"res://debug/panel_row/debug_panel_stat_row.tscn"
)

@onready var _vbox: VBoxContainer = $Rows

#endregion


#region Configuration

func configure_fields(
	field_names: Array[String],
	getter: Callable,
	setter: Callable,
	property_prefix: String = ""
) -> void:
	for field_name in field_names:
		var property_name: String = field_name
		if not property_prefix.is_empty():
			property_name = "%s:%s" % [
				property_prefix, field_name
			]

		var property_path := NodePath(property_name)
		add_child_row(
			field_name,
			getter.bind(property_path),
			setter.bind(property_path)
		)


func add_child_row(
	label: String,
	getter: Callable,
	setter: Callable
) -> void:
	var row: DebugPanelStatRow = STAT_ROW.instantiate()
	_vbox.add_child(row)
	row.field_label.text = label
	row.bind(getter, setter)
	row.edit_requested.connect(edit_requested.emit)

#endregion


#region Display and validation

func update() -> void:
	for child in _vbox.get_children():
		if child is DebugPanelStatRow:
			child.update_field()


func get_invalid_edit_row() -> DebugPanelStatRow:
	for child in _vbox.get_children():
		if child is DebugPanelStatRow:
			if (
				child.field_value.editable
				and not child.is_edit_input_valid()
			):
				return child

	return null

#endregion
