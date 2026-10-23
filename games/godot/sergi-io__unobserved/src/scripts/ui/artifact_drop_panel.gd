class_name ArtifactDropPanel
extends PanelContainer

signal artifact_drag_position_hovered(dragged_item_kind: StringName, screen_position: Vector2)
signal artifact_drag_position_dropped(dragged_item_kind: StringName, screen_position: Vector2)

const DRAG_DATA_TYPE: String = "unobserved_artifact_button"


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var dragged_item_kind := _get_dragged_item_kind(data)
	if dragged_item_kind == &"":
		return false

	artifact_drag_position_hovered.emit(dragged_item_kind, global_position + at_position)
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dragged_item_kind := _get_dragged_item_kind(data)
	if dragged_item_kind == &"":
		return

	artifact_drag_position_dropped.emit(dragged_item_kind, global_position + at_position)


func _get_dragged_item_kind(data: Variant) -> StringName:
	if not (data is Dictionary):
		return &""

	var drag_data := data as Dictionary
	if str(drag_data.get("type", "")) != DRAG_DATA_TYPE:
		return &""

	return StringName(drag_data.get("item_kind", &""))
