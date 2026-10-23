class_name GalaxyUi
extends RefCounted

signal restart_requested
signal exit_to_main_menu_requested
signal invade_requested
signal level_up_choice_requested(option_index: int)
signal debug_slow_down_requested
signal debug_speed_up_requested
signal debug_stop_requested
signal debug_resume_requested
signal debug_add_xp_requested(amount: int)
signal debug_spawn_requested(spawn_count: int)
signal debug_fog_toggle_requested(toggled_on: bool)
signal debug_vacuum_radius_toggled(toggled_on: bool)
signal debug_god_mode_toggled(toggled_on: bool)
signal debug_no_artifact_cooldowns_toggled(toggled_on: bool)
signal debug_item_requested(item_kind: StringName)
signal debug_force_win_requested
signal artifact_activation_requested(item_kind: StringName)
signal artifact_placement_cancel_requested
signal winner_fade_finished

const FLOATING_INCOME_LABEL_SCRIPT = preload("res://scripts/ui/floating_income_label.gd")
const ITEM_PRESENTATION_SCRIPT = preload("res://scripts/ui/item_presentation.gd")
const ARTIFACT_HUD_CONTROLLER_SCRIPT = preload("res://scripts/ui/artifact_hud_controller.gd")
const SHIELD_SEGMENT_BAR_SCRIPT = preload("res://scripts/ui/shield_segment_bar.gd")
const LEVEL_UP_BORDER_SHADER = preload("res://shaders/level_up_border.gdshader")
const LEVEL_UP_DISTORTION_SHADER = preload("res://shaders/level_up_distortion.gdshader")
const DEFAULT_LEVEL_UP_CHOICE_TITLE_FONT_SIZE: int = 20
const DEFAULT_LEVEL_UP_CHOICE_DESCRIPTION_FONT_SIZE: int = 12
const LEVEL_UP_MODAL_ENTRY_DISTANCE: float = 190.0
const LEVEL_UP_MODAL_ENTRY_DURATION: float = 0.34
const LEVEL_UP_DISTORTION_DELAY: float = 0.24
const LEVEL_UP_DISTORTION_DURATION: float = 0.24
const INVENTORY_ADD_FLASH_COLOR: Color = Color(0.25, 1.0, 0.18, 1.0)
const INVENTORY_REMOVE_FLASH_COLOR: Color = Color(1.0, 0.08, 0.05, 1.0)
const INVENTORY_FLASH_DURATION: float = 0.36
const INVENTORY_REMOVE_FLASH_DURATION: float = 0.16
const INVENTORY_REMOVE_FADE_DURATION: float = 0.28
const WINNER_FADE_DURATION: float = 5.0
const WINNER_TYPEWRITE_CHAR_DURATION: float = 0.045
const WINNER_FINAL_LINE_TYPEWRITE_CHAR_DURATION: float = 0.105
const WINNER_CREDIT_TYPEWRITE_CHAR_DURATION: float = 0.045
const WINNER_SIGNATURE_TYPEWRITE_CHAR_DURATION: float = 0.5
const WINNER_FINAL_LINE: String = "Nothing remains unobserved."
const WINNER_MESSAGE: String = "The last world has fallen.\nAll stars answer to you now.\n" + WINNER_FINAL_LINE
const WINNER_CREDIT_TEXT: String = "Thanks for playing my game,"
const WINNER_SIGNATURE_TEXT: String = "Sergi.io"
const WINNER_WEBSITE_URL: String = "https://sergi.io"
const WINNER_SIGNATURE_FONT: Font = preload("res://fonts/BonheurRoyale-Regular.ttf")
const WINNER_SCREEN_SHADER_CODE: String = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;
uniform float black_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale_color = vec3(luminance);
	vec3 desaturated_color = mix(screen_color.rgb, grayscale_color, grayscale_amount);
	COLOR = vec4(mix(desaturated_color, vec3(0.0), black_amount), 1.0);
}
"""

var _galaxy: Node2D
var _item_presentation: RefCounted = ITEM_PRESENTATION_SCRIPT.new()
var level_up_choice_title_font_size: int = DEFAULT_LEVEL_UP_CHOICE_TITLE_FONT_SIZE
var level_up_choice_description_font_size: int = DEFAULT_LEVEL_UP_CHOICE_DESCRIPTION_FONT_SIZE

var _ship_hp_tween: Tween
var _xp_bar_tween: Tween
var _level_up_modal_tween: Tween
var _level_up_distortion_tween: Tween
var _winner_sequence_tween: Tween
var _level_up_icon_cache: Dictionary = {}
var _debug_items_ui_built: bool = false
var _level_up_border_material: ShaderMaterial
var _level_up_distortion_material: ShaderMaterial
var _level_up_modal_base_offsets: Rect2
var _has_level_up_modal_base_offsets: bool = false
var _level_up_modal_animation_offset: Vector2 = Vector2.ZERO
var _inventory_rows: Dictionary = {}
var _inventory_row_tweens: Dictionary = {}
var _inventory_last_levels: Dictionary = {}
var _inventory_empty_label: Label
var _inventory_pending_removal_count: int = 0
var _has_refreshed_inventory: bool = false
var _artifact_hud_controller: RefCounted = ARTIFACT_HUD_CONTROLLER_SCRIPT.new()

var _ship_block: VBoxContainer
var _ship_hp_row: HBoxContainer
var _ship_hp_title_label: Label
var _ship_hp_bar: ProgressBar
var _ship_hp_value_label: Label
var _ship_shield_row: HBoxContainer
var _ship_shield_title_label: Label
var _ship_shield_bar: Control
var _ship_shield_value_label: Label
var _ship_level_value_label: Label
var _xp_bar: ProgressBar
var _xp_value_label: Label
var _enemy_wave_value_label: Label
var _planets_value_label: Label
var _inventory_list_container: VBoxContainer
var _planet_action_info_label: Label
var _planet_hover_info_label: Label
var _winner_label: Label
var _game_over_overlay: PanelContainer
var _game_over_title_label: Label
var _restart_button: Button
var _exit_to_main_menu_button: Button
var _debug_hud: PanelContainer
var _debug_state_value_label: Label
var _debug_speed_value_label: Label
var _debug_slow_button: Button
var _debug_speed_button: Button
var _debug_stop_button: Button
var _debug_resume_button: Button
var _debug_add_xp_1_button: Button
var _debug_add_xp_10_button: Button
var _debug_add_xp_50_button: Button
var _debug_spawn_count_input: LineEdit
var _debug_spawn_button: Button
var _debug_fog_state_value_label: Label
var _debug_fog_toggle_button: CheckButton
var _debug_vacuum_toggle_button: CheckButton
var _debug_god_mode_toggle_button: CheckButton
var _debug_no_artifact_cooldowns_toggle_button: CheckButton
var _debug_force_win_button: Button
var _debug_items_container: HFlowContainer
var _debug_fps_value_label: Label
var _debug_enemy_memory_value_label: Label
var _debug_sprite_memory_value_label: Label
var _debug_object_memory_value_label: Label
var _debug_open_panel_button: Button
var _debug_close_panel_button: Button
var _floating_text_layer: Control
var _level_up_backdrop: ColorRect
var _level_up_modal: PanelContainer
var _level_up_border_fx: ColorRect
var _level_up_distortion_fx: ColorRect
var _level_up_title_label: Label
var _level_up_description_label: Label
var _level_up_level_label: Label
var _level_up_choice_buttons: Array[Button] = []
var _planet_action_popover: PanelContainer
var _planet_hover_tooltip: PanelContainer
var _invade_button: Button
var _artifact_cancel_button: Button
var _winner_sequence_root: Control
var _winner_sequence_screen: ColorRect
var _winner_sequence_label: Label
var _winner_credit_block: VBoxContainer
var _winner_credit_label: Label
var _winner_signature_label: Label
var _winner_website_link: LinkButton
var _winner_sequence_material: ShaderMaterial


func configure(galaxy: Node2D) -> void:
	_galaxy = galaxy
	_artifact_hud_controller.call("configure", _galaxy, _item_presentation)
	var artifact_activation_callable := Callable(self, "_emit_artifact_activation_requested")
	if not _artifact_hud_controller.is_connected("artifact_activation_requested", artifact_activation_callable):
		_artifact_hud_controller.connect("artifact_activation_requested", artifact_activation_callable)


func setup() -> void:
	_bind_nodes()
	_ensure_ship_hp_row_ui()
	_ensure_ship_shield_ui()
	_artifact_hud_controller.call("setup")
	_ensure_artifact_cancel_button()
	_create_level_up_border_fx()
	_create_level_up_distortion_fx()
	_ensure_winner_sequence_ui()
	_ensure_debug_panel_toggle_buttons()
	_style_level_up_modal()
	_connect_controls()

	if _debug_hud != null:
		_debug_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	if _debug_open_panel_button != null:
		_debug_open_panel_button.process_mode = Node.PROCESS_MODE_ALWAYS
	if _debug_close_panel_button != null:
		_debug_close_panel_button.process_mode = Node.PROCESS_MODE_ALWAYS
	if _floating_text_layer != null:
		_floating_text_layer.clip_contents = false

	_set_debug_panel_open(false)
	hide_level_up_modal()
	hide_winner_sequence()
	hide_planet_action_popover()
	hide_planet_hover_tooltip()
	hide_artifact_placement_cancel()
	_refresh_debug_items_ui()


func show_level_up_modal(unlocked_level: int, options: Array[Dictionary]) -> void:
	_layout_level_up_modal()
	_capture_level_up_modal_base_offsets()
	_stop_level_up_modal_tween()
	_set_level_up_modal_animation_offset(Vector2(0.0, LEVEL_UP_MODAL_ENTRY_DISTANCE))
	if _level_up_border_fx != null:
		_sync_level_up_border_fx()
		_level_up_border_fx.show()
	if _level_up_distortion_fx != null:
		_sync_level_up_distortion_fx()
		_set_level_up_distortion_progress(0.0)
	if _level_up_modal != null:
		_level_up_modal.show()
	if _level_up_title_label != null:
		_level_up_title_label.text = "Level Up"
	if _level_up_description_label != null:
		_level_up_description_label.text = "Pick one upgrade to continue."
	if _level_up_level_label != null:
		_level_up_level_label.text = "Level %d unlocked" % unlocked_level

	_update_level_up_choice_buttons(options)
	_play_level_up_modal_entry_animation()


func hide_level_up_modal() -> void:
	_stop_level_up_modal_tween()
	_stop_level_up_distortion_tween()
	if _level_up_backdrop != null:
		_level_up_backdrop.hide()
	if _level_up_border_fx != null:
		_level_up_border_fx.hide()
	if _level_up_distortion_fx != null:
		_level_up_distortion_fx.hide()
	if _level_up_modal != null:
		if _has_level_up_modal_base_offsets:
			_set_level_up_modal_animation_offset(Vector2.ZERO)
		_level_up_modal.hide()


func show_planet_action_popover(planet: Planet, screen_position: Vector2, viewport_size: Vector2, has_colony_beacon: bool = false) -> void:
	if _planet_action_popover == null:
		return

	_planet_action_popover.show()
	_position_popup(_planet_action_popover, screen_position, viewport_size, Vector2(28.0, -24.0), Vector2(176.0, 132.0), true)
	update_planet_action_details(planet, has_colony_beacon)


func hide_planet_action_popover() -> void:
	if _planet_action_popover != null:
		_planet_action_popover.hide()


func show_planet_hover_tooltip(planet: Planet, mouse_position: Vector2, viewport_size: Vector2) -> void:
	if _planet_hover_tooltip == null:
		return

	update_planet_hover_details(planet)
	_planet_hover_tooltip.show()
	_position_popup(_planet_hover_tooltip, mouse_position, viewport_size, Vector2(20.0, 20.0), Vector2(176.0, 84.0), false)


func hide_planet_hover_tooltip() -> void:
	if _planet_hover_tooltip != null:
		_planet_hover_tooltip.hide()


func update_planet_action_details(planet: Planet, has_colony_beacon: bool = false) -> void:
	if _planet_action_info_label != null:
		var details := _format_planet_details(planet, has_colony_beacon)
		_planet_action_info_label.text = details
		_planet_action_info_label.visible = not details.is_empty()

	if _invade_button != null:
		_invade_button.text = "Colonize"
		if planet == null:
			_invade_button.disabled = true
		else:
			_invade_button.disabled = planet.is_conquered() or not has_colony_beacon


func update_planet_hover_details(planet: Planet) -> void:
	if _planet_hover_info_label != null:
		var details := _format_planet_details(planet)
		_planet_hover_info_label.text = details
		_planet_hover_info_label.visible = not details.is_empty()


func refresh_ship_hp(current_hp: int, max_hp: int) -> void:
	if _ship_hp_bar != null:
		_ship_hp_bar.max_value = float(maxi(max_hp, 1))
		_ship_hp_tween = _animate_progress_bar(_ship_hp_bar, float(clampi(current_hp, 0, max_hp)), _ship_hp_tween)

	if _ship_hp_value_label != null:
		_ship_hp_value_label.text = "%d / %d" % [current_hp, max_hp]


func refresh_ship_shield(current_shield_hp: int, max_shield_hp: int, shield_level: int) -> void:
	_ensure_ship_shield_ui()
	if _ship_shield_row == null or _ship_shield_bar == null:
		return

	var safe_max_shield_hp := maxi(max_shield_hp, 0)
	var safe_current_shield_hp := clampi(current_shield_hp, 0, safe_max_shield_hp)
	var has_shield := safe_max_shield_hp > 0 or shield_level > 0
	_ship_shield_row.visible = has_shield or _ship_shield_row.visible
	if not has_shield:
		_ship_shield_bar.call("set_shield", 0, 0, 0)
		if _ship_shield_value_label != null:
			_ship_shield_value_label.text = "0 / 0"
		return

	_ship_shield_row.visible = true
	_ship_shield_bar.call("set_shield", safe_current_shield_hp, safe_max_shield_hp, shield_level)

	if _ship_shield_title_label != null:
		_ship_shield_title_label.text = "Shield"
	if _ship_shield_value_label != null:
		_ship_shield_value_label.text = "%d / %d" % [safe_current_shield_hp, safe_max_shield_hp]


func refresh_xp(ship_xp: int, xp_to_next_level: int, _is_level_up_modal_open: bool) -> void:
	if _xp_bar != null:
		_xp_bar.max_value = float(maxi(xp_to_next_level, 1))
		var xp_value: float = float(clampi(ship_xp, 0, xp_to_next_level))
		_xp_bar_tween = _animate_progress_bar(_xp_bar, xp_value, _xp_bar_tween, true)

	if _xp_value_label != null:
		var display_xp: int = mini(ship_xp, xp_to_next_level)
		_xp_value_label.text = "%d / %d" % [display_xp, xp_to_next_level]


func refresh_top_bar_values(invaded_planets: int, total_planets: int, ship_level: int) -> void:
	if _planets_value_label != null:
		_planets_value_label.text = "%d / %d" % [invaded_planets, total_planets]
	if _ship_level_value_label != null:
		_ship_level_value_label.text = str(ship_level)


func refresh_enemy_wave(time_left: float, next_wave_size: int, has_game_over: bool) -> void:
	if _enemy_wave_value_label == null:
		return

	if has_game_over:
		_enemy_wave_value_label.text = "--"
		return

	var safe_wave_size: int = maxi(next_wave_size, 0)
	var ship_label: String = "ship" if safe_wave_size == 1 else "ships"
	_enemy_wave_value_label.text = "%d %s / %.1fs" % [safe_wave_size, ship_label, maxf(time_left, 0.0)]


func clear_enemy_wave() -> void:
	if _enemy_wave_value_label != null:
		_enemy_wave_value_label.text = "--"


func refresh_inventory(inventory_levels: Dictionary) -> void:
	if _inventory_list_container == null:
		return

	var normalized_inventory := _normalize_inventory_levels(inventory_levels)
	_refresh_artifact_hud(normalized_inventory)
	if not _has_refreshed_inventory:
		_reset_inventory_rows(normalized_inventory)
		_has_refreshed_inventory = true
		return

	if normalized_inventory.is_empty():
		_remove_missing_inventory_rows(normalized_inventory)
		_inventory_last_levels = normalized_inventory
		_update_empty_inventory_label()
		return

	_clear_empty_inventory_label()
	_remove_missing_inventory_rows(normalized_inventory)
	var should_defer_row_order := _inventory_pending_removal_count > 0

	var row_index := 0
	for item_kind in normalized_inventory.keys():
		var item_level: int = int(normalized_inventory.get(item_kind, 0))
		var previous_level: int = int(_inventory_last_levels.get(item_kind, 0))
		var row := _inventory_rows.get(item_kind, null) as Control
		if row == null or not is_instance_valid(row):
			row = _item_presentation.create_inventory_row(item_kind, item_level)
			_inventory_rows[item_kind] = row
			_inventory_list_container.add_child(row)
			_flash_inventory_row_text(row)
		else:
			_update_inventory_row_text(row, item_kind, item_level)
			row.modulate = Color.WHITE
			var is_countdown_decrease: bool = item_kind == &"invisibility" and item_level < previous_level
			if item_level != previous_level and not is_countdown_decrease:
				_flash_inventory_row_text(row)

		if not should_defer_row_order:
			_inventory_list_container.move_child(row, row_index)
			row_index += 1

	_inventory_last_levels = normalized_inventory


func update_debug_hud(
	is_paused: bool,
	time_scale: float,
	has_game_over: bool,
	is_fog_enabled: bool,
	is_vacuum_radius_visible: bool,
	is_god_mode_enabled: bool,
	has_no_artifact_cooldowns: bool,
	can_spawn_enemies: bool,
	frames_per_second: int,
	enemy_count: int,
	sprite_count: int,
	object_count: int
) -> void:
	if _debug_state_value_label != null:
		_debug_state_value_label.text = "Paused" if is_paused else "Running"
	if _debug_speed_value_label != null:
		_debug_speed_value_label.text = "%.2fx" % maxf(time_scale, 0.0)
	if _debug_stop_button != null:
		_debug_stop_button.disabled = is_paused
	if _debug_resume_button != null:
		_debug_resume_button.disabled = false
	if _debug_add_xp_1_button != null:
		_debug_add_xp_1_button.disabled = has_game_over
	if _debug_add_xp_10_button != null:
		_debug_add_xp_10_button.disabled = has_game_over
	if _debug_add_xp_50_button != null:
		_debug_add_xp_50_button.disabled = has_game_over
	if _debug_fog_state_value_label != null:
		_debug_fog_state_value_label.text = "Enabled" if is_fog_enabled else "Disabled"
	if _debug_fog_toggle_button != null:
		_debug_fog_toggle_button.set_pressed_no_signal(is_fog_enabled)
	if _debug_vacuum_toggle_button != null:
		_debug_vacuum_toggle_button.set_pressed_no_signal(is_vacuum_radius_visible)
	if _debug_god_mode_toggle_button != null:
		_debug_god_mode_toggle_button.set_pressed_no_signal(is_god_mode_enabled)
	if _debug_no_artifact_cooldowns_toggle_button != null:
		_debug_no_artifact_cooldowns_toggle_button.set_pressed_no_signal(has_no_artifact_cooldowns)
	if _debug_spawn_button != null:
		_debug_spawn_button.disabled = not can_spawn_enemies
	if _debug_fps_value_label != null:
		_debug_fps_value_label.text = "FPS: %d" % maxi(frames_per_second, 0)
	if _debug_enemy_memory_value_label != null:
		_debug_enemy_memory_value_label.text = "Enemies: %d" % enemy_count
	if _debug_sprite_memory_value_label != null:
		_debug_sprite_memory_value_label.text = "Sprites: %d" % sprite_count
	if _debug_object_memory_value_label != null:
		_debug_object_memory_value_label.text = "Objects: %d" % object_count


func update_end_messages(has_game_over: bool, has_won: bool, winner_text: String = "") -> void:
	if _winner_label != null:
		if not winner_text.is_empty():
			_winner_label.text = winner_text
			_winner_label.visible = true
		elif has_game_over:
			_winner_label.visible = false
		elif has_won:
			_winner_label.visible = false

	if _game_over_overlay != null:
		_game_over_overlay.visible = has_game_over
	if _game_over_title_label != null:
		_game_over_title_label.visible = has_game_over
		if not winner_text.is_empty():
			_game_over_title_label.text = winner_text.capitalize()
	if has_game_over and _restart_button != null:
		_restart_button.grab_focus()


func play_winner_sequence() -> void:
	_ensure_winner_sequence_ui()
	if _winner_sequence_root == null:
		return

	_stop_winner_sequence_tween()
	_set_winner_sequence_progress(0.0)
	if _winner_sequence_label != null:
		_winner_sequence_label.text = WINNER_MESSAGE
		_winner_sequence_label.visible_characters = 0
		_winner_sequence_label.hide()
	_hide_winner_credit()
	_winner_sequence_root.show()

	_winner_sequence_tween = _winner_sequence_root.create_tween()
	_winner_sequence_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_winner_sequence_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_winner_sequence_tween.set_trans(Tween.TRANS_CUBIC)
	_winner_sequence_tween.set_ease(Tween.EASE_IN_OUT)
	_winner_sequence_tween.tween_method(_set_winner_sequence_progress, 0.0, 1.0, WINNER_FADE_DURATION)
	_winner_sequence_tween.tween_callback(_emit_winner_fade_finished)
	_winner_sequence_tween.tween_callback(_start_winner_typewrite)


func hide_winner_sequence() -> void:
	_stop_winner_sequence_tween()
	_set_winner_sequence_progress(0.0)
	if _winner_sequence_label != null:
		_winner_sequence_label.visible_characters = 0
		_winner_sequence_label.hide()
	_hide_winner_credit()
	if _winner_sequence_root != null:
		_winner_sequence_root.hide()


func spawn_xp_label(screen_position: Vector2, amount: int, float_distance: float, duration: float) -> void:
	if _floating_text_layer == null or amount <= 0:
		return

	var local_screen_position := _floating_text_layer.get_global_transform_with_canvas().affine_inverse() * screen_position
	var label := FLOATING_INCOME_LABEL_SCRIPT.new() as Label
	label.call(
		"configure",
		amount,
		local_screen_position - Vector2(36.0, 42.0),
		float_distance,
		duration,
		Color(0.55, 0.87, 1.0, 1.0),
		33
	)
	label.z_index = 600
	_floating_text_layer.add_child(label)


func spawn_damage_label(screen_position: Vector2, amount: int, float_distance: float, duration: float) -> void:
	if _floating_text_layer == null or amount <= 0:
		return

	var local_screen_position := _floating_text_layer.get_global_transform_with_canvas().affine_inverse() * screen_position
	var label := FLOATING_INCOME_LABEL_SCRIPT.new() as Label
	label.call(
		"configure",
		amount,
		local_screen_position - Vector2(30.0, 56.0),
		float_distance / 6.0,
		minf(duration, 0.62),
		Color(1.0, 0.14, 0.1, 1.0),
		16,
		"-%d",
		true
	)
	label.z_index = 601
	_floating_text_layer.add_child(label)


func format_inventory_item_name(item_kind: StringName) -> String:
	return _item_presentation.format_inventory_item_name(item_kind)


func get_item_icon_texture(item_kind: StringName) -> Texture2D:
	return _item_presentation.get_item_icon_texture(item_kind)


func get_artifact_kind_at_shortcut(shortcut_index: int) -> StringName:
	return StringName(_artifact_hud_controller.call("get_artifact_kind_at_shortcut", shortcut_index))


func refresh_artifact_cooldowns(cooldown_states: Dictionary) -> void:
	_artifact_hud_controller.call("refresh_cooldowns", cooldown_states)


func show_artifact_placement_cancel() -> void:
	_ensure_artifact_cancel_button()
	if _artifact_cancel_button != null:
		_artifact_cancel_button.show()


func hide_artifact_placement_cancel() -> void:
	if _artifact_cancel_button != null:
		_artifact_cancel_button.hide()


func _normalize_inventory_levels(inventory_levels: Dictionary) -> Dictionary:
	var normalized_inventory: Dictionary = {}
	for item_kind_variant in inventory_levels.keys():
		var item_kind := StringName(item_kind_variant)
		var item_level: int = maxi(int(inventory_levels.get(item_kind_variant, 0)), 0)
		if item_level > 0:
			normalized_inventory[item_kind] = item_level

	return normalized_inventory


func _reset_inventory_rows(inventory_levels: Dictionary) -> void:
	for child in _inventory_list_container.get_children():
		child.queue_free()

	_inventory_rows.clear()
	_inventory_row_tweens.clear()
	_inventory_last_levels = inventory_levels.duplicate(true)
	_inventory_empty_label = null
	_inventory_pending_removal_count = 0

	if inventory_levels.is_empty():
		_update_empty_inventory_label()
		return

	for item_kind in inventory_levels.keys():
		var item_level: int = int(inventory_levels.get(item_kind, 0))
		var row := _item_presentation.create_inventory_row(item_kind, item_level) as Control
		_inventory_rows[item_kind] = row
		_inventory_list_container.add_child(row)


func _remove_missing_inventory_rows(inventory_levels: Dictionary) -> void:
	var current_item_kinds := _inventory_rows.keys()
	for item_kind in current_item_kinds:
		if inventory_levels.has(item_kind):
			continue

		var row := _inventory_rows.get(item_kind, null) as Control
		_inventory_rows.erase(item_kind)
		_fade_remove_inventory_row(row)


func _flash_inventory_row_text(row: Control) -> void:
	var label := _get_inventory_row_label(row)
	if label == null:
		return

	_kill_inventory_row_tween(row)
	label.modulate = INVENTORY_ADD_FLASH_COLOR
	var tween := label.create_tween()
	_inventory_row_tweens[row] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", Color.WHITE, INVENTORY_FLASH_DURATION)
	tween.tween_callback(func() -> void: _inventory_row_tweens.erase(row))


func _fade_remove_inventory_row(row: Control) -> void:
	if row == null or not is_instance_valid(row):
		_update_empty_inventory_label()
		return

	_kill_inventory_row_tween(row)
	var label := _get_inventory_row_label(row)
	if label != null:
		label.modulate = INVENTORY_REMOVE_FLASH_COLOR

	row.modulate = Color.WHITE
	var tween := row.create_tween()
	_inventory_pending_removal_count += 1
	_inventory_row_tweens[row] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_interval(INVENTORY_REMOVE_FLASH_DURATION)
	tween.tween_property(row, "modulate", Color(1.0, 1.0, 1.0, 0.0), INVENTORY_REMOVE_FADE_DURATION)
	tween.tween_callback(func() -> void:
		_inventory_row_tweens.erase(row)
		_inventory_pending_removal_count = maxi(_inventory_pending_removal_count - 1, 0)
		if is_instance_valid(row):
			row.queue_free()
		if _inventory_pending_removal_count <= 0:
			_sync_inventory_row_order()
			_update_empty_inventory_label()
	)


func _kill_inventory_row_tween(row: Control) -> void:
	var tween := _inventory_row_tweens.get(row, null) as Tween
	if tween != null:
		tween.kill()
	_inventory_row_tweens.erase(row)


func _update_inventory_row_text(row: Control, item_kind: StringName, item_level: int) -> void:
	var label := _get_inventory_row_label(row)
	if label == null:
		return

	label.text = _item_presentation.format_inventory_item_label(item_kind, item_level)


func _sync_inventory_row_order() -> void:
	if _inventory_list_container == null or _inventory_pending_removal_count > 0:
		return

	var row_index := 0
	for item_kind in _inventory_last_levels.keys():
		var row := _inventory_rows.get(item_kind, null) as Control
		if row == null or not is_instance_valid(row):
			continue

		_inventory_list_container.move_child(row, row_index)
		row_index += 1


func _get_inventory_row_label(row: Control) -> Label:
	if row == null:
		return null

	for child in row.get_children():
		var label := child as Label
		if label != null:
			return label

	return null


func _update_empty_inventory_label() -> void:
	if _inventory_list_container == null or not _inventory_rows.is_empty() or _inventory_pending_removal_count > 0:
		_clear_empty_inventory_label()
		return

	if _inventory_empty_label != null and is_instance_valid(_inventory_empty_label):
		return

	_inventory_empty_label = Label.new()
	_inventory_empty_label.text = "No items collected yet."
	_inventory_list_container.add_child(_inventory_empty_label)


func _clear_empty_inventory_label() -> void:
	if _inventory_empty_label == null:
		return

	if is_instance_valid(_inventory_empty_label):
		_inventory_empty_label.queue_free()
	_inventory_empty_label = null


func _refresh_artifact_hud(inventory_levels: Dictionary) -> void:
	_artifact_hud_controller.call("refresh_inventory", inventory_levels)


func _bind_nodes() -> void:
	_ship_block = _get_node("UI/TopBar/MarginContainer/HBoxContainer/ShipBlock") as VBoxContainer
	_ship_hp_title_label = _get_node("UI/TopBar/MarginContainer/HBoxContainer/ShipBlock/ShipTitle") as Label
	_ship_hp_bar = _get_node("UI/TopBar/MarginContainer/HBoxContainer/ShipBlock/ShipHPBar") as ProgressBar
	_ship_hp_value_label = _get_node("UI/TopBar/MarginContainer/HBoxContainer/ShipBlock/ShipHPValue") as Label
	_ship_level_value_label = _get_node("UI/TopBar/MarginContainer/HBoxContainer/LevelBlock/LevelValue") as Label
	_xp_bar = _get_node("UI/TopBar/MarginContainer/HBoxContainer/XpBlock/XpBar") as ProgressBar
	_xp_value_label = _get_node("UI/TopBar/MarginContainer/HBoxContainer/XpBlock/XpValue") as Label
	_enemy_wave_value_label = _get_node("UI/TopBar/MarginContainer/HBoxContainer/WaveBlock/WaveValue") as Label
	_planets_value_label = _get_node("UI/TopBar/MarginContainer/HBoxContainer/PlanetsBlock/PlanetsValue") as Label
	_inventory_list_container = _get_node("UI/InventoryPanel/MarginContainer/VBoxContainer/InventoryScroll/InventoryList") as VBoxContainer
	_planet_action_info_label = _get_node("UI/PlanetActionPopover/MarginContainer/VBoxContainer/PlanetInfoLabel") as Label
	_planet_hover_info_label = _get_node("UI/PlanetHoverTooltip/MarginContainer/VBoxContainer/PlanetHoverInfoLabel") as Label
	_winner_label = _get_node("UI/WinnerLabel") as Label
	_game_over_overlay = _get_node("UI/GameOverOverlay") as PanelContainer
	_game_over_title_label = _get_node("UI/GameOverOverlay/MarginContainer/VBoxContainer/GameOverTitle") as Label
	_restart_button = _get_node("UI/GameOverOverlay/MarginContainer/VBoxContainer/RestartButton") as Button
	_exit_to_main_menu_button = _get_node("UI/GameOverOverlay/MarginContainer/VBoxContainer/ExitToMainMenuButton") as Button
	_debug_hud = _get_node("UI/DebugHud") as PanelContainer
	_debug_state_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/StatusRow/StateBlock/StateValue") as Label
	_debug_speed_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/StatusRow/SpeedBlock/SpeedValue") as Label
	_debug_slow_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/PlaybackRow/SlowDownButton") as Button
	_debug_speed_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/PlaybackRow/SpeedUpButton") as Button
	_debug_stop_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/PlaybackRow/StopButton") as Button
	_debug_resume_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/PlaybackRow/ResumeButton") as Button
	_debug_add_xp_1_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/XPRow/AddXp1Button") as Button
	_debug_add_xp_10_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/XPRow/AddXp10Button") as Button
	_debug_add_xp_50_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/XPRow/AddXp50Button") as Button
	_debug_spawn_count_input = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/SpawnRow/SpawnCount") as LineEdit
	_debug_spawn_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/SpawnRow/SpawnButton") as Button
	_debug_fog_state_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/FogRow/FogStateBlock/FogStateValue") as Label
	_debug_fog_toggle_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/FogRow/FogToggleButton") as CheckButton
	_debug_vacuum_toggle_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/VacuumToggleButton") as CheckButton
	_debug_god_mode_toggle_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/GodModeToggleButton") as CheckButton
	_debug_no_artifact_cooldowns_toggle_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/NoArtifactCooldownsToggleButton") as CheckButton
	_debug_force_win_button = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/ForceWinButton") as Button
	_debug_items_container = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/ItemsBlock/ItemsFlow") as HFlowContainer
	_debug_fps_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/StatsBlock/FpsValue") as Label
	_debug_enemy_memory_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/StatsBlock/EnemyMemoryValue") as Label
	_debug_sprite_memory_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/StatsBlock/SpriteMemoryValue") as Label
	_debug_object_memory_value_label = _get_node("UI/DebugHud/MarginContainer/VBoxContainer/StatsBlock/ObjectMemoryValue") as Label
	_floating_text_layer = _get_node("UI/FloatingTextLayer") as Control
	_level_up_backdrop = _get_node("UI/LevelUpBackdrop") as ColorRect
	_level_up_modal = _get_node("UI/LevelUpModal") as PanelContainer
	_level_up_title_label = _get_node("UI/LevelUpModal/MarginContainer/ContentRow/InfoColumn/LevelUpTitle") as Label
	_level_up_description_label = _get_node("UI/LevelUpModal/MarginContainer/ContentRow/InfoColumn/LevelUpDescription") as Label
	_level_up_level_label = _get_node("UI/LevelUpModal/MarginContainer/ContentRow/InfoColumn/LevelUpLevel") as Label
	_level_up_choice_buttons = [
		_get_node("UI/LevelUpModal/MarginContainer/ContentRow/ChoicesContainer/ChoiceAButton") as Button,
		_get_node("UI/LevelUpModal/MarginContainer/ContentRow/ChoicesContainer/ChoiceBButton") as Button,
		_get_node("UI/LevelUpModal/MarginContainer/ContentRow/ChoicesContainer/ChoiceCButton") as Button,
	]
	_planet_action_popover = _get_node("UI/PlanetActionPopover") as PanelContainer
	_planet_hover_tooltip = _get_node("UI/PlanetHoverTooltip") as PanelContainer
	_invade_button = _get_node("UI/PlanetActionPopover/MarginContainer/VBoxContainer/InvadeButton") as Button


func _ensure_winner_sequence_ui() -> void:
	if _winner_sequence_root != null and is_instance_valid(_winner_sequence_root):
		return
	if _galaxy == null:
		return

	var ui_layer := _get_node("UI") as CanvasLayer
	if ui_layer == null:
		return

	_winner_sequence_root = Control.new()
	_winner_sequence_root.name = "WinnerSequence"
	_winner_sequence_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_winner_sequence_root.visible = false
	_winner_sequence_root.z_index = 2200
	_winner_sequence_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_winner_sequence_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_winner_sequence_root)

	_winner_sequence_screen = ColorRect.new()
	_winner_sequence_screen.name = "ScreenFade"
	_winner_sequence_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_winner_sequence_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_winner_sequence_root.add_child(_winner_sequence_screen)

	var shader := Shader.new()
	shader.code = WINNER_SCREEN_SHADER_CODE
	_winner_sequence_material = ShaderMaterial.new()
	_winner_sequence_material.shader = shader
	_winner_sequence_screen.material = _winner_sequence_material

	var center := CenterContainer.new()
	center.name = "MessageCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_winner_sequence_root.add_child(center)

	var content := VBoxContainer.new()
	content.name = "WinnerContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 34)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)

	_winner_sequence_label = Label.new()
	_winner_sequence_label.name = "WinnerMessage"
	_winner_sequence_label.custom_minimum_size = Vector2(980.0, 240.0)
	_winner_sequence_label.text = WINNER_MESSAGE
	_winner_sequence_label.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	_winner_sequence_label.visible_characters = 0
	_winner_sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_sequence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_winner_sequence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_winner_sequence_label.add_theme_font_size_override("font_size", 56)
	_winner_sequence_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9, 1.0))
	_winner_sequence_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_winner_sequence_label.add_theme_constant_override("shadow_offset_x", 0)
	_winner_sequence_label.add_theme_constant_override("shadow_offset_y", 2)
	_winner_sequence_label.add_theme_constant_override("shadow_outline_size", 10)
	content.add_child(_winner_sequence_label)

	_winner_credit_block = VBoxContainer.new()
	_winner_credit_block.name = "WinnerCredit"
	_winner_credit_block.alignment = BoxContainer.ALIGNMENT_CENTER
	_winner_credit_block.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_winner_credit_block.add_theme_constant_override("separation", 2)
	_winner_credit_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_winner_credit_block)

	_winner_credit_label = Label.new()
	_winner_credit_label.name = "WinnerCreditText"
	_winner_credit_label.text = WINNER_CREDIT_TEXT
	_winner_credit_label.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	_winner_credit_label.visible_characters = 0
	_winner_credit_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_winner_credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_credit_label.add_theme_font_size_override("font_size", 24)
	_winner_credit_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78, 1.0))
	_winner_credit_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	_winner_credit_label.add_theme_constant_override("shadow_outline_size", 5)
	_winner_credit_block.add_child(_winner_credit_label)

	_winner_signature_label = Label.new()
	_winner_signature_label.name = "WinnerSignature"
	_winner_signature_label.text = WINNER_SIGNATURE_TEXT
	_winner_signature_label.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	_winner_signature_label.visible_characters = 0
	_winner_signature_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_winner_signature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_signature_label.add_theme_font_override("font", WINNER_SIGNATURE_FONT)
	_winner_signature_label.add_theme_font_size_override("font_size", 46)
	_winner_signature_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.84, 1.0))
	_winner_signature_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	_winner_signature_label.add_theme_constant_override("shadow_outline_size", 6)
	_winner_credit_block.add_child(_winner_signature_label)

	var website_spacer := Control.new()
	website_spacer.name = "WinnerWebsiteSpacer"
	website_spacer.custom_minimum_size = Vector2(1.0, 22.0)
	_winner_credit_block.add_child(website_spacer)

	_winner_website_link = LinkButton.new()
	_winner_website_link.name = "WinnerWebsiteLink"
	_winner_website_link.text = WINNER_WEBSITE_URL
	_winner_website_link.uri = WINNER_WEBSITE_URL
	_winner_website_link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_winner_website_link.focus_mode = Control.FOCUS_NONE
	_winner_website_link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_winner_website_link.add_theme_font_size_override("font_size", 18)
	_winner_website_link.add_theme_color_override("font_color", Color(0.66, 0.82, 0.9, 1.0))
	_winner_website_link.add_theme_color_override("font_hover_color", Color(0.9, 0.98, 1.0, 1.0))
	_winner_website_link.add_theme_color_override("font_pressed_color", Color(0.84, 0.92, 1.0, 1.0))
	_winner_website_link.pressed.connect(_open_winner_website)
	_winner_credit_block.add_child(_winner_website_link)
	_hide_winner_credit()


func _set_winner_sequence_progress(progress: float) -> void:
	if _winner_sequence_material == null:
		return

	var safe_progress := clampf(progress, 0.0, 1.0)
	_winner_sequence_material.set_shader_parameter("grayscale_amount", minf(safe_progress * 1.4, 1.0))
	_winner_sequence_material.set_shader_parameter("black_amount", safe_progress)


func _emit_winner_fade_finished() -> void:
	winner_fade_finished.emit()


func _start_winner_typewrite() -> void:
	if _winner_sequence_label == null:
		return

	_winner_sequence_label.show()
	_winner_sequence_label.visible_characters = 0
	var character_count := WINNER_MESSAGE.length()
	var final_line_character_count := WINNER_FINAL_LINE.length()
	var fast_character_count := maxi(character_count - final_line_character_count, 0)
	var fast_typewrite_duration := maxf(float(fast_character_count) * WINNER_TYPEWRITE_CHAR_DURATION, 0.1)
	var final_line_typewrite_duration := maxf(float(final_line_character_count) * WINNER_FINAL_LINE_TYPEWRITE_CHAR_DURATION, 0.1)
	_winner_sequence_tween = _winner_sequence_label.create_tween()
	_winner_sequence_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_winner_sequence_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_winner_sequence_tween.set_trans(Tween.TRANS_LINEAR)
	_winner_sequence_tween.tween_property(_winner_sequence_label, "visible_characters", fast_character_count, fast_typewrite_duration)
	_winner_sequence_tween.tween_property(_winner_sequence_label, "visible_characters", character_count, final_line_typewrite_duration)
	_winner_sequence_tween.tween_callback(_show_winner_credit)


func _show_winner_credit() -> void:
	if _winner_credit_block != null:
		_winner_credit_block.show()
	if _winner_credit_label != null:
		_winner_credit_label.visible_characters = 0
		_winner_credit_label.show()
	if _winner_signature_label != null:
		_winner_signature_label.visible_characters = 0
		_winner_signature_label.show()
	if _winner_website_link != null:
		_winner_website_link.hide()

	if _winner_credit_block == null or _winner_credit_label == null or _winner_signature_label == null:
		if _winner_website_link != null:
			_winner_website_link.show()
		return

	var credit_typewrite_duration := maxf(
		float(WINNER_CREDIT_TEXT.length()) * WINNER_CREDIT_TYPEWRITE_CHAR_DURATION,
		0.1
	)
	var signature_typewrite_duration := maxf(
		float(WINNER_SIGNATURE_TEXT.length()) * WINNER_SIGNATURE_TYPEWRITE_CHAR_DURATION,
		WINNER_SIGNATURE_TYPEWRITE_CHAR_DURATION
	)
	_winner_sequence_tween = _winner_credit_block.create_tween()
	_winner_sequence_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_winner_sequence_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_winner_sequence_tween.set_trans(Tween.TRANS_LINEAR)
	_winner_sequence_tween.tween_property(
		_winner_credit_label,
		"visible_characters",
		WINNER_CREDIT_TEXT.length(),
		credit_typewrite_duration
	)
	_winner_sequence_tween.tween_property(
		_winner_signature_label,
		"visible_characters",
		WINNER_SIGNATURE_TEXT.length(),
		signature_typewrite_duration
	)
	_winner_sequence_tween.tween_callback(_show_winner_website_link)


func _hide_winner_credit() -> void:
	if _winner_credit_block != null:
		_winner_credit_block.hide()
	if _winner_credit_label != null:
		_winner_credit_label.visible_characters = 0
		_winner_credit_label.hide()
	if _winner_signature_label != null:
		_winner_signature_label.visible_characters = 0
		_winner_signature_label.hide()
	if _winner_website_link != null:
		_winner_website_link.hide()


func _show_winner_website_link() -> void:
	if _winner_website_link != null:
		_winner_website_link.show()


func _open_winner_website() -> void:
	OS.shell_open(WINNER_WEBSITE_URL)


func _stop_winner_sequence_tween() -> void:
	if _winner_sequence_tween != null and _winner_sequence_tween.is_running():
		_winner_sequence_tween.kill()
	_winner_sequence_tween = null


func _ensure_ship_hp_row_ui() -> void:
	if _ship_hp_row != null and is_instance_valid(_ship_hp_row):
		return
	if _ship_hp_title_label == null or _ship_hp_bar == null or _ship_hp_value_label == null:
		return

	var ship_block := _get_ship_block()
	if ship_block == null:
		return

	_ship_hp_row = HBoxContainer.new()
	_ship_hp_row.name = "ShipHPRow"
	_ship_hp_row.custom_minimum_size = Vector2(240.0, 18.0)
	_ship_hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ship_hp_row.add_theme_constant_override("separation", 8)
	ship_block.add_child(_ship_hp_row)
	ship_block.move_child(_ship_hp_row, 0)

	_reparent_control_to_row(_ship_hp_title_label, _ship_hp_row)
	_ship_hp_title_label.custom_minimum_size = Vector2(44.0, 0.0)
	_ship_hp_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ship_hp_title_label.add_theme_font_size_override("font_size", 12)

	_reparent_control_to_row(_ship_hp_bar, _ship_hp_row)
	_ship_hp_bar.custom_minimum_size = Vector2(140.0, 18.0)
	_ship_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_reparent_control_to_row(_ship_hp_value_label, _ship_hp_row)
	_ship_hp_value_label.custom_minimum_size = Vector2(54.0, 0.0)
	_ship_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ship_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ship_hp_value_label.add_theme_font_size_override("font_size", 12)


func _reparent_control_to_row(control: Control, row: HBoxContainer) -> void:
	if control == null or row == null:
		return
	var parent := control.get_parent()
	if parent != null:
		parent.remove_child(control)
	row.add_child(control)


func _get_ship_block() -> VBoxContainer:
	if _ship_block != null and is_instance_valid(_ship_block):
		return _ship_block
	if _ship_hp_row != null and is_instance_valid(_ship_hp_row):
		_ship_block = _ship_hp_row.get_parent() as VBoxContainer
		return _ship_block
	if _ship_hp_bar != null:
		_ship_block = _ship_hp_bar.get_parent() as VBoxContainer
	return _ship_block


func _ensure_ship_shield_ui() -> void:
	if _ship_shield_row != null and is_instance_valid(_ship_shield_row):
		return

	var ship_block := _get_ship_block()
	if ship_block == null:
		return

	_ship_shield_row = HBoxContainer.new()
	_ship_shield_row.name = "ShipShieldRow"
	_ship_shield_row.custom_minimum_size = Vector2(240.0, 16.0)
	_ship_shield_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ship_shield_row.add_theme_constant_override("separation", 8)
	_ship_shield_row.visible = false

	_ship_shield_title_label = Label.new()
	_ship_shield_title_label.name = "ShipShieldTitle"
	_ship_shield_title_label.custom_minimum_size = Vector2(44.0, 0.0)
	_ship_shield_title_label.text = "Shield"
	_ship_shield_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ship_shield_title_label.add_theme_font_size_override("font_size", 12)
	_ship_shield_title_label.add_theme_color_override("font_color", Color(0.58, 0.88, 1.0, 1.0))
	_ship_shield_row.add_child(_ship_shield_title_label)

	_ship_shield_bar = SHIELD_SEGMENT_BAR_SCRIPT.new() as Control
	_ship_shield_bar.name = "ShipShieldBar"
	_ship_shield_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ship_shield_bar.connect("became_empty", _hide_empty_ship_shield_row)
	_ship_shield_row.add_child(_ship_shield_bar)

	_ship_shield_value_label = Label.new()
	_ship_shield_value_label.name = "ShipShieldValue"
	_ship_shield_value_label.custom_minimum_size = Vector2(54.0, 0.0)
	_ship_shield_value_label.text = "0 / 0"
	_ship_shield_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ship_shield_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ship_shield_value_label.add_theme_font_size_override("font_size", 12)
	_ship_shield_value_label.add_theme_color_override("font_color", Color(0.78, 0.94, 1.0, 1.0))
	_ship_shield_row.add_child(_ship_shield_value_label)

	ship_block.add_child(_ship_shield_row)


func _hide_empty_ship_shield_row() -> void:
	if _ship_shield_row != null:
		_ship_shield_row.visible = false


func _create_level_up_border_fx() -> void:
	if _galaxy == null or _level_up_modal == null:
		return
	if _level_up_border_fx != null and is_instance_valid(_level_up_border_fx):
		return

	var ui_layer := _get_node("UI") as CanvasLayer
	if ui_layer == null:
		return

	_level_up_border_material = ShaderMaterial.new()
	_level_up_border_material.shader = LEVEL_UP_BORDER_SHADER
	_level_up_border_material.set_shader_parameter("core_color", Color(1.0, 0.72, 1.0, 1.0))
	_level_up_border_material.set_shader_parameter("glow_color", Color(0.63, 0.1, 1.0, 1.0))
	_level_up_border_material.set_shader_parameter("spark_color", Color(0.95, 0.36, 1.0, 1.0))

	_level_up_border_fx = ColorRect.new()
	_level_up_border_fx.name = "LevelUpBorderFx"
	_level_up_border_fx.process_mode = Node.PROCESS_MODE_ALWAYS
	_level_up_border_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_up_border_fx.z_index = _level_up_modal.z_index + 1
	_level_up_border_fx.color = Color.TRANSPARENT
	_level_up_border_fx.material = _level_up_border_material
	_level_up_border_fx.hide()
	ui_layer.add_child(_level_up_border_fx)
	_sync_level_up_border_fx()


func _create_level_up_distortion_fx() -> void:
	if _galaxy == null or _level_up_modal == null:
		return
	if _level_up_distortion_fx != null and is_instance_valid(_level_up_distortion_fx):
		return

	var ui_layer := _get_node("UI") as CanvasLayer
	if ui_layer == null:
		return

	_level_up_distortion_material = ShaderMaterial.new()
	_level_up_distortion_material.shader = LEVEL_UP_DISTORTION_SHADER

	_level_up_distortion_fx = ColorRect.new()
	_level_up_distortion_fx.name = "LevelUpDistortionFx"
	_level_up_distortion_fx.process_mode = Node.PROCESS_MODE_ALWAYS
	_level_up_distortion_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_up_distortion_fx.z_index = _level_up_modal.z_index + 2
	_level_up_distortion_fx.color = Color.TRANSPARENT
	_level_up_distortion_fx.material = _level_up_distortion_material
	_level_up_distortion_fx.hide()
	ui_layer.add_child(_level_up_distortion_fx)
	_sync_level_up_distortion_fx()


func _style_level_up_modal() -> void:
	_layout_level_up_modal()

	if _level_up_modal != null:
		var modal_panel := StyleBoxFlat.new()
		modal_panel.bg_color = Color(0.02, 0.021, 0.045, 0.91)
		modal_panel.border_color = Color(0.42, 0.2, 0.72, 0.42)
		modal_panel.set_border_width_all(1)
		modal_panel.set_corner_radius_all(18)
		_level_up_modal.add_theme_stylebox_override("panel", modal_panel)

	if _level_up_title_label != null:
		_level_up_title_label.add_theme_font_size_override("font_size", 34)
		_level_up_title_label.add_theme_color_override("font_color", Color(0.93, 0.88, 1.0, 1.0))
		_level_up_title_label.add_theme_color_override("font_shadow_color", Color(0.6, 0.18, 1.0, 0.68))
		_level_up_title_label.add_theme_constant_override("shadow_offset_x", 0)
		_level_up_title_label.add_theme_constant_override("shadow_offset_y", 0)
		_level_up_title_label.add_theme_constant_override("shadow_outline_size", 12)
	if _level_up_description_label != null:
		_level_up_description_label.add_theme_font_size_override("font_size", 14)
		_level_up_description_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.94, 1.0))
	if _level_up_level_label != null:
		_level_up_level_label.add_theme_font_size_override("font_size", 16)
		_level_up_level_label.add_theme_color_override("font_color", Color(0.76, 0.22, 1.0, 1.0))

	for button in _level_up_choice_buttons:
		_style_level_up_choice_button(button)


func _layout_level_up_modal() -> void:
	if _level_up_modal == null:
		return

	var viewport_size := _galaxy.get_viewport_rect().size if _galaxy != null else Vector2(1600.0, 900.0)
	var modal_width := clampf(viewport_size.x - 560.0, 820.0, 1080.0)
	var modal_height := 126.0
	_level_up_modal.custom_minimum_size = Vector2(modal_width, modal_height)
	_level_up_modal.anchor_left = 0.5
	_level_up_modal.anchor_top = 1.0
	_level_up_modal.anchor_right = 0.5
	_level_up_modal.anchor_bottom = 1.0
	_level_up_modal.offset_left = -modal_width * 0.5
	_level_up_modal.offset_top = -modal_height - 28.0
	_level_up_modal.offset_right = modal_width * 0.5
	_level_up_modal.offset_bottom = -28.0

	if _level_up_border_fx != null:
		_sync_level_up_border_fx()
	if _level_up_distortion_fx != null:
		_sync_level_up_distortion_fx()


func _capture_level_up_modal_base_offsets() -> void:
	if _level_up_modal == null:
		return

	_level_up_modal_base_offsets = Rect2(
		Vector2(_level_up_modal.offset_left, _level_up_modal.offset_top),
		Vector2(_level_up_modal.offset_right, _level_up_modal.offset_bottom)
	)
	_has_level_up_modal_base_offsets = true


func _set_level_up_modal_animation_offset(animation_offset: Vector2) -> void:
	if _level_up_modal == null or not _has_level_up_modal_base_offsets:
		return

	_level_up_modal_animation_offset = animation_offset
	_level_up_modal.offset_left = _level_up_modal_base_offsets.position.x + animation_offset.x
	_level_up_modal.offset_top = _level_up_modal_base_offsets.position.y + animation_offset.y
	_level_up_modal.offset_right = _level_up_modal_base_offsets.size.x + animation_offset.x
	_level_up_modal.offset_bottom = _level_up_modal_base_offsets.size.y + animation_offset.y
	_sync_level_up_border_fx()
	_sync_level_up_distortion_fx()


func _set_level_up_modal_animation_offset_y(offset_y: float) -> void:
	_set_level_up_modal_animation_offset(Vector2(_level_up_modal_animation_offset.x, offset_y))


func _play_level_up_modal_entry_animation() -> void:
	if _level_up_modal == null or not _has_level_up_modal_base_offsets:
		return

	_level_up_modal_tween = _level_up_modal.create_tween()
	_level_up_modal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_level_up_modal_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_level_up_modal_tween.set_trans(Tween.TRANS_BACK)
	_level_up_modal_tween.set_ease(Tween.EASE_OUT)
	_level_up_modal_tween.tween_method(_set_level_up_modal_animation_offset_y, LEVEL_UP_MODAL_ENTRY_DISTANCE, 0.0, LEVEL_UP_MODAL_ENTRY_DURATION)
	_level_up_modal_tween.tween_callback(_set_level_up_modal_animation_offset.bind(Vector2.ZERO))

	_play_level_up_distortion_effect()


func _stop_level_up_modal_tween() -> void:
	if _level_up_modal_tween != null and _level_up_modal_tween.is_running():
		_level_up_modal_tween.kill()
	_level_up_modal_tween = null


func _play_level_up_distortion_effect() -> void:
	if _level_up_distortion_fx == null or _level_up_distortion_material == null:
		return

	_stop_level_up_distortion_tween()
	_set_level_up_distortion_progress(0.0)
	_level_up_distortion_fx.show()
	_level_up_distortion_tween = _level_up_distortion_fx.create_tween()
	_level_up_distortion_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_level_up_distortion_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_level_up_distortion_tween.tween_interval(LEVEL_UP_DISTORTION_DELAY)
	_level_up_distortion_tween.tween_method(_set_level_up_distortion_progress, 0.0, 1.0, LEVEL_UP_DISTORTION_DURATION)
	_level_up_distortion_tween.tween_callback(_hide_level_up_distortion_fx)


func _set_level_up_distortion_progress(progress: float) -> void:
	if _level_up_distortion_material != null:
		_level_up_distortion_material.set_shader_parameter("progress", clampf(progress, 0.0, 1.0))


func _hide_level_up_distortion_fx() -> void:
	_set_level_up_distortion_progress(0.0)
	if _level_up_distortion_fx != null:
		_level_up_distortion_fx.hide()


func _stop_level_up_distortion_tween() -> void:
	if _level_up_distortion_tween != null and _level_up_distortion_tween.is_running():
		_level_up_distortion_tween.kill()
	_level_up_distortion_tween = null


func _sync_level_up_border_fx() -> void:
	if _level_up_border_fx == null or _level_up_modal == null:
		return

	var effect_padding := 34.0
	_level_up_border_fx.anchor_left = _level_up_modal.anchor_left
	_level_up_border_fx.anchor_top = _level_up_modal.anchor_top
	_level_up_border_fx.anchor_right = _level_up_modal.anchor_right
	_level_up_border_fx.anchor_bottom = _level_up_modal.anchor_bottom
	_level_up_border_fx.offset_left = _level_up_modal.offset_left - effect_padding
	_level_up_border_fx.offset_top = _level_up_modal.offset_top - effect_padding
	_level_up_border_fx.offset_right = _level_up_modal.offset_right + effect_padding
	_level_up_border_fx.offset_bottom = _level_up_modal.offset_bottom + effect_padding

	var effect_size := Vector2(
		_level_up_border_fx.offset_right - _level_up_border_fx.offset_left,
		_level_up_border_fx.offset_bottom - _level_up_border_fx.offset_top
	)
	_level_up_border_fx.custom_minimum_size = effect_size
	_level_up_border_fx.size = effect_size
	if _level_up_border_material != null:
		_level_up_border_material.set_shader_parameter("panel_size", effect_size)
		_level_up_border_material.set_shader_parameter("border_margin", effect_padding)
		_level_up_border_material.set_shader_parameter("corner_radius", 18.0)
		_level_up_border_material.set_shader_parameter("border_thickness", 2.6)
		_level_up_border_material.set_shader_parameter("glow_size", 26.0)
		_level_up_border_material.set_shader_parameter("sparkle_density", 0.15)


func _sync_level_up_distortion_fx() -> void:
	if _level_up_distortion_fx == null or _level_up_modal == null:
		return

	var effect_padding := 20.0
	_level_up_distortion_fx.anchor_left = _level_up_modal.anchor_left
	_level_up_distortion_fx.anchor_top = _level_up_modal.anchor_top
	_level_up_distortion_fx.anchor_right = _level_up_modal.anchor_right
	_level_up_distortion_fx.anchor_bottom = _level_up_modal.anchor_bottom
	_level_up_distortion_fx.offset_left = _level_up_modal.offset_left - effect_padding
	_level_up_distortion_fx.offset_top = _level_up_modal.offset_top - effect_padding
	_level_up_distortion_fx.offset_right = _level_up_modal.offset_right + effect_padding
	_level_up_distortion_fx.offset_bottom = _level_up_modal.offset_bottom + effect_padding

	var effect_size := Vector2(
		_level_up_distortion_fx.offset_right - _level_up_distortion_fx.offset_left,
		_level_up_distortion_fx.offset_bottom - _level_up_distortion_fx.offset_top
	)
	_level_up_distortion_fx.custom_minimum_size = effect_size
	_level_up_distortion_fx.size = effect_size


func _style_level_up_choice_button(button: Button) -> void:
	if button == null:
		return

	button.custom_minimum_size = Vector2(180.0, 72.0)
	button.text = ""
	button.icon = null
	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.96, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.93, 0.82, 1.0, 1.0))

	var normal := _make_level_up_button_style(Color(0.045, 0.047, 0.08, 0.88), Color(0.24, 0.2, 0.36, 0.82), 1)
	var hover := _make_level_up_button_style(Color(0.065, 0.052, 0.105, 0.95), Color(0.72, 0.24, 1.0, 0.9), 2)
	var pressed := _make_level_up_button_style(Color(0.1, 0.06, 0.14, 0.98), Color(0.98, 0.64, 1.0, 1.0), 2)
	var disabled := _make_level_up_button_style(Color(0.035, 0.036, 0.052, 0.64), Color(0.18, 0.17, 0.24, 0.5), 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	_ensure_level_up_choice_button_content(button)


func _make_level_up_button_style(background_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	return style


func _connect_controls() -> void:
	_connect_pressed(_invade_button, invade_requested)
	_connect_pressed(_restart_button, restart_requested)
	_connect_pressed(_exit_to_main_menu_button, exit_to_main_menu_requested)
	_connect_pressed(_artifact_cancel_button, artifact_placement_cancel_requested)
	_connect_pressed(_debug_slow_button, debug_slow_down_requested)
	_connect_pressed(_debug_speed_button, debug_speed_up_requested)
	_connect_pressed(_debug_stop_button, debug_stop_requested)
	_connect_pressed(_debug_resume_button, debug_resume_requested)

	if _debug_add_xp_1_button != null:
		_debug_add_xp_1_button.pressed.connect(_emit_debug_add_xp_requested.bind(1))
	if _debug_add_xp_10_button != null:
		_debug_add_xp_10_button.pressed.connect(_emit_debug_add_xp_requested.bind(10))
	if _debug_add_xp_50_button != null:
		_debug_add_xp_50_button.pressed.connect(_emit_debug_add_xp_requested.bind(50))
	if _debug_spawn_button != null:
		_debug_spawn_button.pressed.connect(_emit_debug_spawn_requested)
	if _debug_fog_toggle_button != null:
		_debug_fog_toggle_button.toggled.connect(func(toggled_on: bool) -> void: debug_fog_toggle_requested.emit(toggled_on))
	if _debug_vacuum_toggle_button != null:
		_debug_vacuum_toggle_button.toggled.connect(func(toggled_on: bool) -> void: debug_vacuum_radius_toggled.emit(toggled_on))
	if _debug_god_mode_toggle_button != null:
		_debug_god_mode_toggle_button.toggled.connect(func(toggled_on: bool) -> void: debug_god_mode_toggled.emit(toggled_on))
	if _debug_no_artifact_cooldowns_toggle_button != null:
		_debug_no_artifact_cooldowns_toggle_button.toggled.connect(func(toggled_on: bool) -> void: debug_no_artifact_cooldowns_toggled.emit(toggled_on))
	_connect_pressed(_debug_force_win_button, debug_force_win_requested)
	if _debug_open_panel_button != null:
		_debug_open_panel_button.pressed.connect(func() -> void: _set_debug_panel_open(true))
	if _debug_close_panel_button != null:
		_debug_close_panel_button.pressed.connect(func() -> void: _set_debug_panel_open(false))

	for index in range(_level_up_choice_buttons.size()):
		var choice_button := _level_up_choice_buttons[index]
		if choice_button != null:
			choice_button.pressed.connect(_emit_level_up_choice_requested.bind(index))


func _connect_pressed(button: BaseButton, event_signal: Signal) -> void:
	if button != null:
		button.pressed.connect(func() -> void: event_signal.emit())


func _ensure_artifact_cancel_button() -> void:
	if _artifact_cancel_button != null and is_instance_valid(_artifact_cancel_button):
		return

	var ui_layer := _get_node("UI") as CanvasLayer
	if ui_layer == null:
		return

	_artifact_cancel_button = Button.new()
	_artifact_cancel_button.name = "ArtifactCancelButton"
	_artifact_cancel_button.text = "Cancel"
	_artifact_cancel_button.focus_mode = Control.FOCUS_NONE
	_artifact_cancel_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_artifact_cancel_button.custom_minimum_size = Vector2(108.0, 38.0)
	_artifact_cancel_button.anchor_left = 0.5
	_artifact_cancel_button.anchor_top = 1.0
	_artifact_cancel_button.anchor_right = 0.5
	_artifact_cancel_button.anchor_bottom = 1.0
	_artifact_cancel_button.offset_left = -54.0
	_artifact_cancel_button.offset_top = -68.0
	_artifact_cancel_button.offset_right = 54.0
	_artifact_cancel_button.offset_bottom = -30.0
	_artifact_cancel_button.add_theme_stylebox_override("normal", _make_cancel_button_style(Color(0.045, 0.052, 0.058, 0.94), Color(0.46, 0.72, 0.82, 0.82)))
	_artifact_cancel_button.add_theme_stylebox_override("hover", _make_cancel_button_style(Color(0.058, 0.074, 0.082, 0.98), Color(0.72, 0.92, 0.98, 0.95)))
	_artifact_cancel_button.add_theme_stylebox_override("pressed", _make_cancel_button_style(Color(0.025, 0.1, 0.11, 0.98), Color(0.9, 1.0, 0.96, 1.0)))
	_artifact_cancel_button.add_theme_stylebox_override("focus", _make_cancel_button_style(Color(0.058, 0.074, 0.082, 0.98), Color(0.72, 0.92, 0.98, 0.95)))
	_artifact_cancel_button.add_theme_font_size_override("font_size", 14)
	_artifact_cancel_button.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0, 1.0))
	ui_layer.add_child(_artifact_cancel_button)
	_artifact_cancel_button.hide()


func _ensure_debug_panel_toggle_buttons() -> void:
	var ui_layer := _get_node("UI") as CanvasLayer
	if ui_layer == null:
		return

	if _debug_open_panel_button == null or not is_instance_valid(_debug_open_panel_button):
		_debug_open_panel_button = _create_debug_panel_toggle_button("OpenDebugPanelButton", "Open Debug Panel", 140.0)
		ui_layer.add_child(_debug_open_panel_button)
	if _debug_close_panel_button == null or not is_instance_valid(_debug_close_panel_button):
		_debug_close_panel_button = _create_debug_panel_toggle_button("CloseDebugPanelButton", "Close Debug Panel", 98.0)
		ui_layer.add_child(_debug_close_panel_button)


func _create_debug_panel_toggle_button(button_name: StringName, button_text: String, top_offset: float) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.custom_minimum_size = Vector2(176.0, 36.0)
	button.anchor_left = 1.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = -192.0
	button.offset_top = top_offset
	button.offset_right = -16.0
	button.offset_bottom = top_offset + 36.0
	button.add_theme_font_size_override("font_size", 14)
	return button


func _set_debug_panel_open(is_open: bool) -> void:
	if _debug_hud != null:
		_debug_hud.visible = is_open
	if _debug_open_panel_button != null:
		_debug_open_panel_button.visible = not is_open
	if _debug_close_panel_button != null:
		_debug_close_panel_button.visible = is_open


func _make_cancel_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	return style


func _get_node(path: NodePath) -> Node:
	if _galaxy == null:
		return null

	return _galaxy.get_node_or_null(path)


func _position_popup(popup: Control, origin: Vector2, viewport_size: Vector2, offset: Vector2, fallback_size: Vector2, align_above: bool) -> void:
	var popup_size := popup.get_combined_minimum_size()
	if popup_size == Vector2.ZERO:
		popup_size = fallback_size

	popup.size = popup_size

	var desired_position := origin + offset
	if align_above:
		desired_position.y -= popup_size.y

	desired_position.x = clampf(desired_position.x, 8.0, maxf(8.0, viewport_size.x - popup_size.x - 8.0))
	desired_position.y = clampf(desired_position.y, 8.0, maxf(8.0, viewport_size.y - popup_size.y - 8.0))
	popup.position = desired_position


func _format_planet_details(planet: Planet, has_colony_beacon: bool = true) -> String:
	if planet == null:
		return ""

	if planet.is_conquered():
		return "Colonized"
	if not has_colony_beacon:
		return "Requires Colony Beacon"

	return ""


func _update_level_up_choice_buttons(options: Array[Dictionary]) -> void:
	for index in range(_level_up_choice_buttons.size()):
		_configure_level_up_choice_button(_level_up_choice_buttons[index], index, options)


func _configure_level_up_choice_button(button: Button, option_index: int, options: Array[Dictionary]) -> void:
	if button == null:
		return

	if option_index < 0 or option_index >= options.size():
		_set_level_up_choice_button_content(button, "No option", "", null)
		button.icon = null
		button.tooltip_text = ""
		button.disabled = true
		return

	var option: Dictionary = options[option_index]
	var title: String = str(option.get("title", "Upgrade"))
	var summary: String = str(option.get("summary", option.get("description", "")))
	var tooltip_text: String = str(option.get("tooltip", summary))
	var icon_texture := option.get("icon_texture", null) as Texture2D
	if icon_texture == null:
		icon_texture = _item_presentation.get_item_icon_texture(StringName(option.get("item_kind", &"laser")))
	_set_level_up_choice_button_content(button, title, summary, _get_level_up_icon_texture(icon_texture))
	button.tooltip_text = tooltip_text
	button.disabled = false


func _ensure_level_up_choice_button_content(button: Button) -> HBoxContainer:
	var existing_content := button.get_node_or_null("LevelUpChoiceContent") as HBoxContainer
	if existing_content != null:
		return existing_content

	var content := HBoxContainer.new()
	content.name = "LevelUpChoiceContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14.0
	content.offset_top = 10.0
	content.offset_right = -14.0
	content.offset_bottom = -10.0
	content.add_theme_constant_override("separation", 10)
	button.add_child(content)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(48.0, 48.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)

	var text_column := VBoxContainer.new()
	text_column.name = "TextColumn"
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 1)
	content.add_child(text_column)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", level_up_choice_title_font_size)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.96, 1.0))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(title_label)

	var description_label := Label.new()
	description_label.name = "DescriptionLabel"
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", level_up_choice_description_font_size)
	description_label.add_theme_color_override("font_color", Color(0.82, 0.79, 0.9, 1.0))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(description_label)

	return content


func _set_level_up_choice_button_content(button: Button, title: String, description: String, icon_texture: Texture2D) -> void:
	var content := _ensure_level_up_choice_button_content(button)
	var icon := content.get_node_or_null("Icon") as TextureRect
	var text_column := content.get_node_or_null("TextColumn") as VBoxContainer
	var title_label := text_column.get_node_or_null("TitleLabel") as Label if text_column != null else null
	var description_label := text_column.get_node_or_null("DescriptionLabel") as Label if text_column != null else null

	button.text = ""
	button.icon = null
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.clip_text = true

	if icon != null:
		icon.texture = icon_texture
		icon.visible = icon_texture != null

	if title_label != null:
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", level_up_choice_title_font_size)

	if description_label != null:
		description_label.text = description
		description_label.visible = not description.is_empty()
		description_label.add_theme_font_size_override("font_size", level_up_choice_description_font_size)


func _get_level_up_icon_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null

	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = "%s:%d" % [texture.get_class(), texture.get_instance_id()]

	var cached_texture: Texture2D = _level_up_icon_cache.get(cache_key, null)
	if cached_texture != null:
		return cached_texture

	var source_image: Image = texture.get_image()
	if source_image == null or source_image.is_empty():
		_level_up_icon_cache[cache_key] = texture
		return texture

	var scaled_width := maxi(1, int(round(float(source_image.get_width()) * 0.4)))
	var scaled_height := maxi(1, int(round(float(source_image.get_height()) * 0.4)))
	if scaled_width == source_image.get_width() and scaled_height == source_image.get_height():
		_level_up_icon_cache[cache_key] = texture
		return texture

	var scaled_image := source_image.duplicate()
	scaled_image.resize(scaled_width, scaled_height, Image.INTERPOLATE_LANCZOS)
	var scaled_texture := ImageTexture.create_from_image(scaled_image)
	_level_up_icon_cache[cache_key] = scaled_texture
	return scaled_texture


func _animate_progress_bar(progress_bar: ProgressBar, target_value: float, existing_tween: Tween, animate_increase: bool = false) -> Tween:
	if progress_bar == null:
		return null

	var clamped_target := clampf(target_value, 0.0, progress_bar.max_value)
	var current_value := progress_bar.value
	if is_equal_approx(current_value, clamped_target):
		if existing_tween != null and existing_tween.is_running():
			existing_tween.kill()
		progress_bar.value = clamped_target
		return null

	if current_value < clamped_target and not animate_increase:
		if existing_tween != null and existing_tween.is_running():
			existing_tween.kill()
		progress_bar.value = clamped_target
		return null

	if existing_tween != null and existing_tween.is_running():
		existing_tween.kill()

	var new_tween := progress_bar.create_tween()
	new_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	new_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	new_tween.set_trans(Tween.TRANS_QUAD)
	new_tween.set_ease(Tween.EASE_OUT)
	new_tween.tween_property(progress_bar, "value", clamped_target, 0.22)
	return new_tween


func _refresh_debug_items_ui() -> void:
	if _debug_items_ui_built or _debug_items_container == null:
		return

	for child in _debug_items_container.get_children():
		child.queue_free()

	for item_kind in _item_presentation.get_debug_item_kinds():
		var item_texture: Texture2D = _item_presentation.get_item_icon_texture(item_kind)
		if item_texture == null:
			continue

		var button := TextureButton.new()
		button.custom_minimum_size = Vector2(32.0, 32.0)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_normal = item_texture
		button.texture_hover = item_texture
		button.texture_pressed = item_texture
		button.texture_focused = item_texture
		button.tooltip_text = _item_presentation.format_inventory_item_name(item_kind)
		button.pressed.connect(_emit_debug_item_requested.bind(item_kind))
		_debug_items_container.add_child(button)

	_debug_items_ui_built = true


func _emit_debug_add_xp_requested(amount: int) -> void:
	debug_add_xp_requested.emit(amount)


func _emit_level_up_choice_requested(option_index: int) -> void:
	level_up_choice_requested.emit(option_index)


func _emit_debug_item_requested(item_kind: StringName) -> void:
	debug_item_requested.emit(item_kind)


func _emit_artifact_activation_requested(item_kind: StringName) -> void:
	artifact_activation_requested.emit(item_kind)


func _emit_debug_spawn_requested() -> void:
	var spawn_count: int = 0
	if _debug_spawn_count_input != null:
		spawn_count = maxi(int(_debug_spawn_count_input.text), 0)

	debug_spawn_requested.emit(spawn_count)
