class_name ArtifactButton
extends Button

signal artifact_drag_started(item_kind: StringName, button: ArtifactButton)
signal artifact_drag_hovered(target_item_kind: StringName, before_target: bool)
signal artifact_drag_dropped(dragged_item_kind: StringName, target_item_kind: StringName, before_target: bool)
signal artifact_drag_ended(was_successful: bool)

const DRAG_DATA_TYPE: String = "unobserved_artifact_button"

var _item_kind: StringName = &""
var _preview_texture: Texture2D
var _shortcut_text: String = ""
var _display_name: String = ""


func configure_artifact_drag(item_kind: StringName, preview_texture: Texture2D, shortcut_text: String, display_name: String) -> void:
	_item_kind = item_kind
	_preview_texture = preview_texture
	_shortcut_text = shortcut_text
	_display_name = display_name


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _item_kind == &"":
		return null

	artifact_drag_started.emit(_item_kind, self)
	set_drag_preview(_create_drag_preview())
	return {
		"type": DRAG_DATA_TYPE,
		"item_kind": _item_kind,
	}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var dragged_item_kind := _get_dragged_item_kind(data)
	if dragged_item_kind == &"" or dragged_item_kind == _item_kind:
		return false

	artifact_drag_hovered.emit(_item_kind, at_position.x < size.x * 0.5)
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dragged_item_kind := _get_dragged_item_kind(data)
	if dragged_item_kind == &"" or dragged_item_kind == _item_kind:
		return

	artifact_drag_dropped.emit(dragged_item_kind, _item_kind, at_position.x < size.x * 0.5)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		var viewport := get_viewport()
		artifact_drag_ended.emit(viewport != null and viewport.gui_is_drag_successful())


func _get_dragged_item_kind(data: Variant) -> StringName:
	if not (data is Dictionary):
		return &""

	var drag_data := data as Dictionary
	if str(drag_data.get("type", "")) != DRAG_DATA_TYPE:
		return &""

	return StringName(drag_data.get("item_kind", &""))


func _create_drag_preview() -> Control:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(68.0, 68.0)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.052, 0.94)
	style.border_color = Color(0.52, 0.92, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 7.0
	style.content_margin_top = 7.0
	style.content_margin_right = 7.0
	style.content_margin_bottom = 7.0
	preview.add_theme_stylebox_override("panel", style)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(54.0, 54.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _preview_texture
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(icon)

	var shortcut_label := Label.new()
	shortcut_label.text = _shortcut_text
	shortcut_label.tooltip_text = _display_name
	shortcut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shortcut_label.add_theme_font_size_override("font_size", 12)
	shortcut_label.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0, 1.0))
	shortcut_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	shortcut_label.add_theme_constant_override("shadow_outline_size", 4)
	shortcut_label.anchor_left = 0.0
	shortcut_label.anchor_top = 0.0
	shortcut_label.anchor_right = 0.0
	shortcut_label.anchor_bottom = 0.0
	shortcut_label.offset_left = 5.0
	shortcut_label.offset_top = 4.0
	shortcut_label.offset_right = 20.0
	shortcut_label.offset_bottom = 20.0
	shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(shortcut_label)

	return preview
