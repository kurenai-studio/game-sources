class_name ArtifactHudController
extends RefCounted

signal artifact_activation_requested(item_kind: StringName)

const ITEM_PRESENTATION_SCRIPT = preload("res://scripts/ui/item_presentation.gd")
const ARTIFACT_BUTTON_SCRIPT = preload("res://scripts/ui/artifact_button.gd")
const ARTIFACT_DROP_PANEL_SCRIPT = preload("res://scripts/ui/artifact_drop_panel.gd")

const ARTIFACT_BUTTON_SIZE: Vector2 = Vector2(54.0, 54.0)
const ARTIFACT_HUD_MARGIN: float = 16.0
const ARTIFACT_HUD_HEIGHT: float = 82.0
const ARTIFACT_MAX_STACK_BLOCKS: int = 4
const ARTIFACT_REORDER_ANIMATION_DURATION: float = 0.18
const ARTIFACT_DRAG_SCALE: Vector2 = Vector2(0.9, 0.9)
const ARTIFACT_DROP_TARGET_SCALE: Vector2 = Vector2(1.08, 1.08)

var _galaxy: Node2D
var _item_presentation: RefCounted
var _artifact_hud: PanelContainer
var _artifact_buttons_container: HBoxContainer
var _artifact_button_by_kind: Dictionary = {}
var _artifact_button_position_tweens: Dictionary = {}
var _artifact_button_visual_tweens: Dictionary = {}
var _artifact_hud_item_kinds: Array[StringName] = []
var _artifact_preferred_item_kinds: Array[StringName] = []
var _artifact_cooldown_states: Dictionary = {}
var _artifact_inventory_levels: Dictionary = {}
var _artifact_activation_enabled_by_kind: Dictionary = {}
var _artifact_drag_item_kind: StringName = &""
var _artifact_drag_original_item_kinds: Array[StringName] = []
var _artifact_drag_drop_committed: bool = false
var _artifact_drop_target_kind: StringName = &""
var _artifact_activation_suppressed_until_msec: int = 0


func configure(galaxy: Node2D, item_presentation: RefCounted) -> void:
	_galaxy = galaxy
	_item_presentation = item_presentation
	if _item_presentation == null:
		_item_presentation = ITEM_PRESENTATION_SCRIPT.new()


func setup() -> void:
	_ensure_artifact_hud_ui()


func refresh_inventory(inventory_levels: Dictionary) -> void:
	_ensure_artifact_hud_ui()
	if _artifact_hud == null:
		return

	_artifact_inventory_levels = inventory_levels.duplicate(true)
	var artifact_kinds := _get_artifact_kinds_from_inventory(inventory_levels)
	_sync_artifact_hud_order(artifact_kinds)
	_refresh_artifact_buttons()
	_layout_artifact_hud()
	_artifact_hud.visible = not _artifact_hud_item_kinds.is_empty()


func refresh_cooldowns(cooldown_states: Dictionary) -> void:
	_artifact_cooldown_states = cooldown_states.duplicate(true)
	_refresh_artifact_buttons()


func get_artifact_kind_at_shortcut(shortcut_index: int) -> StringName:
	if shortcut_index < 0 or shortcut_index >= _artifact_hud_item_kinds.size():
		return &""

	return _artifact_hud_item_kinds[shortcut_index]


func _get_artifact_kinds_from_inventory(inventory_levels: Dictionary) -> Array[StringName]:
	var artifact_lookup: Dictionary = {}
	for artifact_kind in _item_presentation.get_artifact_item_kinds():
		artifact_lookup[artifact_kind] = true

	var artifact_kinds: Array[StringName] = []
	for item_kind_variant in inventory_levels.keys():
		var item_kind := StringName(item_kind_variant)
		if not artifact_lookup.has(item_kind):
			continue
		if int(inventory_levels.get(item_kind_variant, 0)) <= 0:
			continue

		artifact_kinds.append(item_kind)

	return artifact_kinds


func _sync_artifact_hud_order(artifact_kinds: Array[StringName]) -> void:
	var next_lookup: Dictionary = {}
	for item_kind in artifact_kinds:
		next_lookup[item_kind] = true

	var next_order: Array[StringName] = []
	for item_kind in _artifact_preferred_item_kinds:
		if next_lookup.has(item_kind) and not next_order.has(item_kind):
			next_order.append(item_kind)
	for item_kind in _artifact_hud_item_kinds:
		if next_lookup.has(item_kind) and not next_order.has(item_kind):
			next_order.append(item_kind)
	for item_kind in _item_presentation.get_artifact_item_kinds():
		if next_lookup.has(item_kind) and not next_order.has(item_kind):
			next_order.append(item_kind)
	for item_kind in artifact_kinds:
		if next_lookup.has(item_kind) and not next_order.has(item_kind):
			next_order.append(item_kind)

	_artifact_hud_item_kinds = next_order


func _refresh_artifact_buttons(animate_reorder: bool = false) -> void:
	if _artifact_buttons_container == null:
		return

	var previous_positions := _capture_artifact_button_global_positions() if animate_reorder else {}
	for item_kind_variant in _artifact_button_by_kind.keys():
		var item_kind := StringName(item_kind_variant)
		if _artifact_hud_item_kinds.has(item_kind):
			continue

		var old_button := _artifact_button_by_kind.get(item_kind, null) as Button
		_artifact_button_by_kind.erase(item_kind)
		_artifact_activation_enabled_by_kind.erase(item_kind)
		_kill_artifact_button_tweens(old_button)
		if old_button != null and is_instance_valid(old_button):
			old_button.queue_free()

	for index in range(_artifact_hud_item_kinds.size()):
		var item_kind := _artifact_hud_item_kinds[index]
		var button := _artifact_button_by_kind.get(item_kind, null) as Button
		if button == null or not is_instance_valid(button):
			button = _create_artifact_button(item_kind)
			_artifact_button_by_kind[item_kind] = button
			_artifact_buttons_container.add_child(button)

		_update_artifact_button(button, item_kind, index)
		_artifact_buttons_container.move_child(button, index)

	if animate_reorder:
		_play_artifact_reorder_animation(previous_positions)


func _capture_artifact_button_global_positions() -> Dictionary:
	var positions: Dictionary = {}
	for item_kind_variant in _artifact_button_by_kind.keys():
		var item_kind := StringName(item_kind_variant)
		var button := _artifact_button_by_kind.get(item_kind, null) as Button
		if button != null and is_instance_valid(button):
			positions[item_kind] = button.global_position

	return positions


func _play_artifact_reorder_animation(previous_positions: Dictionary) -> void:
	for item_kind_variant in _artifact_hud_item_kinds:
		var item_kind := StringName(item_kind_variant)
		if not previous_positions.has(item_kind):
			continue

		var button := _artifact_button_by_kind.get(item_kind, null) as Button
		if button == null or not is_instance_valid(button):
			continue

		var target_position := button.position
		var start_offset: Vector2 = (previous_positions.get(item_kind, button.global_position) as Vector2) - button.global_position
		if start_offset.length_squared() < 0.5:
			continue

		_kill_artifact_button_position_tween(button)
		button.pivot_offset = ARTIFACT_BUTTON_SIZE * 0.5
		button.position = target_position + start_offset
		var tween := button.create_tween()
		_artifact_button_position_tweens[button] = tween
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "position", target_position, ARTIFACT_REORDER_ANIMATION_DURATION)
		tween.tween_callback(func() -> void:
			if _artifact_button_position_tweens.get(button, null) == tween:
				_artifact_button_position_tweens.erase(button)
		)


func _move_artifact_kind_to_target_slot(dragged_item_kind: StringName, target_item_kind: StringName) -> bool:
	if dragged_item_kind == &"" or target_item_kind == &"" or dragged_item_kind == target_item_kind:
		return false
	if not _artifact_hud_item_kinds.has(dragged_item_kind) or not _artifact_hud_item_kinds.has(target_item_kind):
		return false

	var target_index := _artifact_hud_item_kinds.find(target_item_kind)
	if target_index < 0:
		return false

	return _move_artifact_kind_to_index(dragged_item_kind, target_index)


func _move_artifact_kind_to_index(dragged_item_kind: StringName, insertion_index: int) -> bool:
	if dragged_item_kind == &"" or not _artifact_hud_item_kinds.has(dragged_item_kind):
		return false

	var next_order: Array[StringName] = []
	for item_kind in _artifact_hud_item_kinds:
		if item_kind != dragged_item_kind:
			next_order.append(item_kind)

	next_order.insert(clampi(insertion_index, 0, next_order.size()), dragged_item_kind)
	if _artifact_orders_match(_artifact_hud_item_kinds, next_order):
		return false

	_artifact_hud_item_kinds = next_order
	_refresh_artifact_buttons(true)
	_layout_artifact_hud()
	return true


func _get_artifact_target_kind_at_position(screen_position: Vector2, dragged_item_kind: StringName) -> StringName:
	var closest_kind: StringName = &""
	var closest_distance := INF
	for item_kind in _artifact_hud_item_kinds:
		if item_kind == dragged_item_kind:
			continue

		var button := _artifact_button_by_kind.get(item_kind, null) as Button
		if button == null or not is_instance_valid(button):
			continue

		var button_center_x := button.global_position.x + button.size.x * 0.5
		var distance := absf(screen_position.x - button_center_x)
		if distance < closest_distance:
			closest_distance = distance
			closest_kind = item_kind

	return closest_kind


func _move_artifact_kind_to_position(dragged_item_kind: StringName, screen_position: Vector2) -> bool:
	var target_item_kind := _get_artifact_target_kind_at_position(screen_position, dragged_item_kind)
	if target_item_kind == &"":
		return false

	return _move_artifact_kind_to_target_slot(dragged_item_kind, target_item_kind)


func _artifact_orders_match(left_order: Array[StringName], right_order: Array[StringName]) -> bool:
	if left_order.size() != right_order.size():
		return false

	for index in range(left_order.size()):
		if left_order[index] != right_order[index]:
			return false

	return true


func _commit_artifact_preferred_order() -> void:
	var next_preferred_order: Array[StringName] = []
	for item_kind in _artifact_hud_item_kinds:
		if not next_preferred_order.has(item_kind):
			next_preferred_order.append(item_kind)
	for item_kind in _artifact_preferred_item_kinds:
		if not next_preferred_order.has(item_kind):
			next_preferred_order.append(item_kind)
	for item_kind in _item_presentation.get_artifact_item_kinds():
		if not next_preferred_order.has(item_kind):
			next_preferred_order.append(item_kind)

	_artifact_preferred_item_kinds = next_preferred_order


func _copy_artifact_order(source_order: Array[StringName]) -> Array[StringName]:
	var copied_order: Array[StringName] = []
	for item_kind in source_order:
		copied_order.append(item_kind)
	return copied_order


func _on_artifact_drag_started(item_kind: StringName, button: Button) -> void:
	if not _artifact_hud_item_kinds.has(item_kind):
		return

	_artifact_drag_item_kind = item_kind
	_artifact_drag_original_item_kinds = _copy_artifact_order(_artifact_hud_item_kinds)
	_artifact_drag_drop_committed = false
	_set_artifact_drop_target(&"")
	if button != null and is_instance_valid(button):
		button.z_index = 12
		_tween_artifact_button_visual(button, ARTIFACT_DRAG_SCALE, Color(1.0, 1.0, 1.0, 0.46), 0.1)


func _on_artifact_drag_hovered(target_item_kind: StringName, _before_target: bool) -> void:
	if _artifact_drag_item_kind == &"" or target_item_kind == _artifact_drag_item_kind:
		return

	_set_artifact_drop_target(target_item_kind)


func _on_artifact_drag_dropped(dragged_item_kind: StringName, target_item_kind: StringName, _before_target: bool) -> void:
	if dragged_item_kind == &"" or target_item_kind == &"" or dragged_item_kind == target_item_kind:
		return

	_move_artifact_kind_to_target_slot(dragged_item_kind, target_item_kind)
	_commit_artifact_preferred_order()
	_artifact_drag_drop_committed = true


func _on_artifact_drag_position_hovered(dragged_item_kind: StringName, screen_position: Vector2) -> void:
	if _artifact_drag_item_kind == &"" or dragged_item_kind != _artifact_drag_item_kind:
		return

	_set_artifact_drop_target(_get_artifact_target_kind_at_position(screen_position, dragged_item_kind))


func _on_artifact_drag_position_dropped(dragged_item_kind: StringName, screen_position: Vector2) -> void:
	if dragged_item_kind == &"":
		return

	_move_artifact_kind_to_position(dragged_item_kind, screen_position)
	_commit_artifact_preferred_order()
	_artifact_drag_drop_committed = true


func _on_artifact_drag_ended(was_successful: bool) -> void:
	var completed_item_kind := _artifact_drag_item_kind
	if not was_successful or not _artifact_drag_drop_committed:
		if not _artifact_drag_original_item_kinds.is_empty():
			_artifact_hud_item_kinds = _copy_artifact_order(_artifact_drag_original_item_kinds)
			_refresh_artifact_buttons(true)
			_layout_artifact_hud()

	_finish_artifact_drag()
	if was_successful and completed_item_kind != &"":
		_play_artifact_drop_pulse(completed_item_kind)


func _finish_artifact_drag() -> void:
	_artifact_activation_suppressed_until_msec = Time.get_ticks_msec() + 180
	_artifact_drag_item_kind = &""
	_artifact_drag_original_item_kinds.clear()
	_artifact_drag_drop_committed = false
	_set_artifact_drop_target(&"")
	for item_kind_variant in _artifact_button_by_kind.keys():
		var button := _artifact_button_by_kind.get(item_kind_variant, null) as Button
		if button != null and is_instance_valid(button):
			button.z_index = 0
			_tween_artifact_button_visual(button, Vector2.ONE, Color.WHITE, 0.12)


func _set_artifact_drop_target(item_kind: StringName) -> void:
	if _artifact_drop_target_kind == item_kind:
		return

	var previous_button := _artifact_button_by_kind.get(_artifact_drop_target_kind, null) as Button
	if previous_button != null and is_instance_valid(previous_button) and _artifact_drop_target_kind != _artifact_drag_item_kind:
		_tween_artifact_button_visual(previous_button, Vector2.ONE, Color.WHITE, 0.1)

	_artifact_drop_target_kind = item_kind
	var next_button := _artifact_button_by_kind.get(_artifact_drop_target_kind, null) as Button
	if next_button != null and is_instance_valid(next_button) and _artifact_drop_target_kind != _artifact_drag_item_kind:
		_tween_artifact_button_visual(next_button, ARTIFACT_DROP_TARGET_SCALE, Color(0.82, 1.0, 1.0, 1.0), 0.1)


func _tween_artifact_button_visual(button: Button, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	if button == null or not is_instance_valid(button):
		return

	_kill_artifact_button_visual_tween(button)
	button.pivot_offset = ARTIFACT_BUTTON_SIZE * 0.5
	var tween := button.create_tween()
	_artifact_button_visual_tweens[button] = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", target_scale, duration)
	tween.tween_property(button, "modulate", target_modulate, duration)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if _artifact_button_visual_tweens.get(button, null) == tween:
			_artifact_button_visual_tweens.erase(button)
	)


func _play_artifact_drop_pulse(item_kind: StringName) -> void:
	var button := _artifact_button_by_kind.get(item_kind, null) as Button
	if button == null or not is_instance_valid(button):
		return

	_kill_artifact_button_visual_tween(button)
	button.pivot_offset = ARTIFACT_BUTTON_SIZE * 0.5
	button.scale = Vector2(1.16, 1.16)
	button.modulate = Color.WHITE
	var tween := button.create_tween()
	_artifact_button_visual_tweens[button] = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.24)
	tween.tween_callback(func() -> void:
		if _artifact_button_visual_tweens.get(button, null) == tween:
			_artifact_button_visual_tweens.erase(button)
	)


func _kill_artifact_button_tweens(button: Control) -> void:
	_kill_artifact_button_position_tween(button)
	_kill_artifact_button_visual_tween(button)


func _kill_artifact_button_position_tween(button: Control) -> void:
	if button == null:
		return

	var tween := _artifact_button_position_tweens.get(button, null) as Tween
	if tween != null:
		tween.kill()
	_artifact_button_position_tweens.erase(button)


func _kill_artifact_button_visual_tween(button: Control) -> void:
	if button == null:
		return

	var tween := _artifact_button_visual_tweens.get(button, null) as Tween
	if tween != null:
		tween.kill()
	_artifact_button_visual_tweens.erase(button)


func _ensure_artifact_hud_ui() -> void:
	if _artifact_hud != null and is_instance_valid(_artifact_hud):
		return

	var ui_layer := _get_node("UI") as CanvasLayer
	if ui_layer == null:
		return

	_artifact_hud = ARTIFACT_DROP_PANEL_SCRIPT.new() as PanelContainer
	_artifact_hud.name = "ArtifactHud"
	_artifact_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_artifact_hud.mouse_filter = Control.MOUSE_FILTER_STOP
	_artifact_hud.hide()
	_artifact_hud.connect("artifact_drag_position_hovered", Callable(self, "_on_artifact_drag_position_hovered"))
	_artifact_hud.connect("artifact_drag_position_dropped", Callable(self, "_on_artifact_drag_position_dropped"))
	_artifact_hud.add_theme_stylebox_override(
		"panel",
		_make_artifact_panel_style(Color(0.035, 0.045, 0.052, 0.9), Color(0.26, 0.64, 0.76, 0.72))
	)
	ui_layer.add_child(_artifact_hud)

	var margin_container := MarginContainer.new()
	margin_container.name = "MarginContainer"
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	_artifact_hud.add_child(margin_container)

	var content := VBoxContainer.new()
	content.name = "VBoxContainer"
	content.add_theme_constant_override("separation", 5)
	margin_container.add_child(content)

	var title_label := Label.new()
	title_label.name = "ArtifactTitle"
	title_label.text = "Artifact Hud"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.96, 1.0))
	content.add_child(title_label)

	_artifact_buttons_container = HBoxContainer.new()
	_artifact_buttons_container.name = "ArtifactButtons"
	_artifact_buttons_container.alignment = BoxContainer.ALIGNMENT_END
	_artifact_buttons_container.add_theme_constant_override("separation", 8)
	content.add_child(_artifact_buttons_container)
	_layout_artifact_hud()


func _layout_artifact_hud() -> void:
	if _artifact_hud == null:
		return

	var button_count := maxi(_artifact_hud_item_kinds.size(), 1)
	var buttons_width := ARTIFACT_BUTTON_SIZE.x * float(button_count) + 8.0 * float(maxi(button_count - 1, 0))
	var hud_width := maxf(150.0, buttons_width + 20.0)
	_artifact_hud.custom_minimum_size = Vector2(hud_width, ARTIFACT_HUD_HEIGHT)
	_artifact_hud.anchor_left = 1.0
	_artifact_hud.anchor_top = 1.0
	_artifact_hud.anchor_right = 1.0
	_artifact_hud.anchor_bottom = 1.0
	_artifact_hud.offset_left = -hud_width - ARTIFACT_HUD_MARGIN
	_artifact_hud.offset_top = -ARTIFACT_HUD_HEIGHT - ARTIFACT_HUD_MARGIN
	_artifact_hud.offset_right = -ARTIFACT_HUD_MARGIN
	_artifact_hud.offset_bottom = -ARTIFACT_HUD_MARGIN


func _create_artifact_button(item_kind: StringName) -> Button:
	var button := ARTIFACT_BUTTON_SCRIPT.new() as Button
	button.name = "ArtifactButton"
	button.custom_minimum_size = ARTIFACT_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_stylebox_override("normal", _make_artifact_button_style(Color(0.055, 0.065, 0.074, 0.94), Color(0.24, 0.52, 0.64, 0.88)))
	button.add_theme_stylebox_override("hover", _make_artifact_button_style(Color(0.07, 0.09, 0.1, 0.98), Color(0.54, 0.84, 0.9, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_artifact_button_style(Color(0.025, 0.11, 0.13, 0.98), Color(0.76, 1.0, 0.92, 1.0)))
	button.add_theme_stylebox_override("focus", _make_artifact_button_style(Color(0.07, 0.09, 0.1, 0.98), Color(0.54, 0.84, 0.9, 0.95)))
	button.add_theme_stylebox_override("disabled", _make_artifact_button_style(Color(0.04, 0.045, 0.05, 0.96), Color(0.38, 0.46, 0.48, 0.82)))
	button.pressed.connect(_emit_artifact_activation_requested.bind(item_kind))
	button.connect("artifact_drag_started", Callable(self, "_on_artifact_drag_started"))
	button.connect("artifact_drag_hovered", Callable(self, "_on_artifact_drag_hovered"))
	button.connect("artifact_drag_dropped", Callable(self, "_on_artifact_drag_dropped"))
	button.connect("artifact_drag_ended", Callable(self, "_on_artifact_drag_ended"))

	var shortcut_label := Label.new()
	shortcut_label.name = "ShortcutLabel"
	shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shortcut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shortcut_label.add_theme_font_size_override("font_size", 11)
	shortcut_label.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0, 1.0))
	shortcut_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	shortcut_label.add_theme_constant_override("shadow_outline_size", 3)
	shortcut_label.anchor_left = 0.0
	shortcut_label.anchor_top = 0.0
	shortcut_label.anchor_right = 0.0
	shortcut_label.anchor_bottom = 0.0
	shortcut_label.offset_left = 4.0
	shortcut_label.offset_top = 3.0
	shortcut_label.offset_right = 18.0
	shortcut_label.offset_bottom = 18.0
	shortcut_label.z_index = 2
	button.add_child(shortcut_label)

	var cooldown_label := Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	cooldown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))
	cooldown_label.add_theme_constant_override("shadow_outline_size", 5)
	cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_label.visible = false
	cooldown_label.z_index = 3
	button.add_child(cooldown_label)

	var stack_container := HBoxContainer.new()
	stack_container.name = "StackIndicators"
	stack_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stack_container.add_theme_constant_override("separation", 2)
	stack_container.anchor_left = 0.0
	stack_container.anchor_top = 1.0
	stack_container.anchor_right = 1.0
	stack_container.anchor_bottom = 1.0
	stack_container.offset_left = 7.0
	stack_container.offset_top = -9.0
	stack_container.offset_right = -7.0
	stack_container.offset_bottom = -4.0
	stack_container.z_index = 4
	button.add_child(stack_container)

	return button


func _update_artifact_button(button: Button, item_kind: StringName, index: int) -> void:
	var shortcut_number := index + 1
	var cooldown_state: Dictionary = _artifact_cooldown_states.get(item_kind, {}) as Dictionary
	var stack_count := _get_artifact_stack_count(item_kind, cooldown_state)
	var ready_count := _get_artifact_ready_count(stack_count, cooldown_state)
	var cooldown_time_left := maxf(float(cooldown_state.get("time_left", 0.0)), 0.0)
	var cooldown_duration := maxf(float(cooldown_state.get("duration", 0.0)), 0.0)
	var is_on_cooldown := stack_count > 0 and ready_count <= 0 and cooldown_duration > 0.0 and cooldown_time_left > 0.01
	var can_activate := stack_count > 0 and not is_on_cooldown
	var item_texture: Texture2D = _item_presentation.get_item_icon_texture(item_kind)
	var display_name: String = _item_presentation.format_inventory_item_name(item_kind)

	button.icon = item_texture
	button.disabled = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_artifact_activation_enabled_by_kind[item_kind] = can_activate
	button.tooltip_text = _format_artifact_tooltip(shortcut_number, item_kind, ready_count, stack_count, cooldown_time_left, is_on_cooldown)
	if button.has_method("configure_artifact_drag"):
		button.call("configure_artifact_drag", item_kind, item_texture, str(shortcut_number), display_name)

	var shortcut_label := button.get_node_or_null("ShortcutLabel") as Label
	if shortcut_label != null:
		shortcut_label.text = str(shortcut_number)

	var cooldown_label := button.get_node_or_null("CooldownLabel") as Label
	if cooldown_label != null:
		cooldown_label.visible = is_on_cooldown
		cooldown_label.text = str(maxi(int(ceil(cooldown_time_left)), 1)) if is_on_cooldown else ""

	_update_artifact_stack_indicators(button, stack_count, cooldown_state)


func _format_artifact_tooltip(
	shortcut_number: int,
	item_kind: StringName,
	ready_count: int,
	stack_count: int,
	cooldown_time_left: float,
	is_on_cooldown: bool
) -> String:
	var tooltip := "%d: %s" % [shortcut_number, _item_presentation.format_inventory_item_name(item_kind)]
	if stack_count > 1:
		tooltip += "\nReady: %d/%d" % [ready_count, stack_count]
	if is_on_cooldown:
		tooltip += "\nCooldown: %.1fs" % cooldown_time_left
	return tooltip


func _get_artifact_stack_count(item_kind: StringName, cooldown_state: Dictionary) -> int:
	if cooldown_state.has("stack_count"):
		return clampi(int(cooldown_state.get("stack_count", 0)), 0, ARTIFACT_MAX_STACK_BLOCKS)

	return clampi(int(_artifact_inventory_levels.get(item_kind, 1)), 0, ARTIFACT_MAX_STACK_BLOCKS)


func _get_artifact_ready_count(stack_count: int, cooldown_state: Dictionary) -> int:
	if stack_count <= 0:
		return 0
	if cooldown_state.has("ready_count"):
		return clampi(int(cooldown_state.get("ready_count", 0)), 0, stack_count)

	return stack_count


func _update_artifact_stack_indicators(button: Button, stack_count: int, cooldown_state: Dictionary) -> void:
	var stack_container := button.get_node_or_null("StackIndicators") as HBoxContainer
	if stack_container == null:
		return

	var safe_stack_count := clampi(stack_count, 0, ARTIFACT_MAX_STACK_BLOCKS)
	while stack_container.get_child_count() > safe_stack_count:
		var child := stack_container.get_child(stack_container.get_child_count() - 1)
		stack_container.remove_child(child)
		child.queue_free()

	while stack_container.get_child_count() < safe_stack_count:
		stack_container.add_child(_create_artifact_stack_block())

	var unit_states: Array = cooldown_state.get("units", [])
	for index in range(stack_container.get_child_count()):
		var block := stack_container.get_child(index) as ProgressBar
		if block == null:
			continue

		block.value = _get_artifact_stack_block_fill(index, unit_states)


func _create_artifact_stack_block() -> ProgressBar:
	var block := ProgressBar.new()
	block.custom_minimum_size = Vector2(8.0, 5.0)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.min_value = 0.0
	block.max_value = 1.0
	block.step = 0.001
	block.value = 1.0
	block.show_percentage = false
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_theme_stylebox_override("background", _make_artifact_stack_style(Color(0.02, 0.045, 0.035, 0.92), Color(0.10, 0.35, 0.22, 0.88)))
	block.add_theme_stylebox_override("fill", _make_artifact_stack_style(Color(0.25, 1.0, 0.18, 0.96), Color(0.66, 1.0, 0.54, 0.9)))
	return block


func _get_artifact_stack_block_fill(index: int, unit_states: Array) -> float:
	if index < 0 or index >= unit_states.size():
		return 1.0

	var unit_state_variant: Variant = unit_states[index]
	if not (unit_state_variant is Dictionary):
		return 1.0

	var unit_state := unit_state_variant as Dictionary
	if unit_state.has("fill_ratio"):
		return clampf(float(unit_state.get("fill_ratio", 1.0)), 0.0, 1.0)

	var duration := maxf(float(unit_state.get("duration", 0.0)), 0.0)
	if duration <= 0.0:
		return 1.0

	var time_left := maxf(float(unit_state.get("time_left", 0.0)), 0.0)
	return 1.0 - clampf(time_left / duration, 0.0, 1.0)


func _make_artifact_panel_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _make_artifact_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 5.0
	style.content_margin_top = 5.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 5.0
	return style


func _make_artifact_stack_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _emit_artifact_activation_requested(item_kind: StringName) -> void:
	if _artifact_drag_item_kind != &"":
		return
	if Time.get_ticks_msec() <= _artifact_activation_suppressed_until_msec:
		return
	if not bool(_artifact_activation_enabled_by_kind.get(item_kind, true)):
		return

	artifact_activation_requested.emit(item_kind)


func _get_node(path: NodePath) -> Node:
	if _galaxy == null:
		return null

	return _galaxy.get_node_or_null(path)
