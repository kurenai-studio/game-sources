@tool
extends EditorPlugin

const WaveTimelineScript: Script = preload("res://scripts/waves/wave_timeline.gd")
const WaveDefinitionScript: Script = preload("res://scripts/waves/wave_definition.gd")
const WaveEnemyRuleScript: Script = preload("res://scripts/waves/wave_enemy_rule.gd")
const WaveEventScript: Script = preload("res://scripts/waves/wave_event.gd")

const ENEMY_SCENE_PATH: String = "res://scenes/enemy.tscn"
const ENEMY_2_SCENE_PATH: String = "res://scenes/enemy_2.tscn"
const FIELD_LABEL_MIN_WIDTH: float = 128.0

var _dock: PanelContainer
var _output_root: LineEdit
var _stage_id: LineEdit
var _stage_name: LineEdit
var _timeline_file_name: LineEdit
var _wave_count: SpinBox
var _duration: SpinBox
var _base_budget: SpinBox
var _budget_growth: SpinBox
var _base_max_alive: SpinBox
var _max_alive_growth: SpinBox
var _spawn_interval: SpinBox
var _spawn_interval_step_seconds: SpinBox
var _spawn_interval_step_amount: SpinBox
var _basic_weight: SpinBox
var _pressure_weight: SpinBox
var _horde_every: SpinBox
var _horde_count: SpinBox
var _status: Label


func _enter_tree() -> void:
	_dock = _build_dock()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _dock)


func _exit_tree() -> void:
	if _dock == null:
		return

	remove_control_from_docks(_dock)
	_dock.queue_free()
	_dock = null


func _build_dock() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "WaveBuilder"

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Wave Builder"
	title.add_theme_font_size_override("font_size", 18)
	content.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 6)
	scroll.add_child(fields)

	_output_root = _add_line(fields, "Output root", "res://resources/waves")
	_stage_id = _add_line(fields, "Stage ID", "stage1")
	_stage_name = _add_line(fields, "Stage name", "Stage 1")
	_timeline_file_name = _add_line(fields, "Timeline file", "default_timeline")
	_wave_count = _add_spin(fields, "Waves", 1.0, 99.0, 1.0, 12.0)
	_duration = _add_spin(fields, "Duration", 5.0, 600.0, 0.5, 45.0)
	_base_budget = _add_spin(fields, "Base budget", 0.0, 5000.0, 1.0, 18.0)
	_budget_growth = _add_spin(fields, "Budget growth %", 0.0, 200.0, 1.0, 18.0)
	_base_max_alive = _add_spin(fields, "Base max alive", 1.0, 2000.0, 1.0, 60.0)
	_max_alive_growth = _add_spin(fields, "Max alive growth", 0.0, 200.0, 1.0, 5.0)
	_spawn_interval = _add_spin(fields, "Spawn interval", 0.05, 30.0, 0.05, 1.2)
	_spawn_interval_step_seconds = _add_spin(fields, "Interval step every", 0.0, 600.0, 0.5, 10.0)
	_spawn_interval_step_amount = _add_spin(fields, "Interval step +", -10.0, 10.0, 0.05, 0.1)
	_basic_weight = _add_spin(fields, "Enemy weight", 0.0, 1000.0, 1.0, 80.0)
	_pressure_weight = _add_spin(fields, "Enemy 2 weight", 0.0, 1000.0, 1.0, 20.0)
	_horde_every = _add_spin(fields, "Horde every", 0.0, 99.0, 1.0, 4.0)
	_horde_count = _add_spin(fields, "Horde count", 1.0, 512.0, 1.0, 18.0)

	var generate_button := Button.new()
	generate_button.text = "Generate files"
	generate_button.pressed.connect(_on_generate_pressed)
	content.add_child(generate_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)

	return panel


func _add_line(parent: VBoxContainer, label_text: String, default_value: String) -> LineEdit:
	var row := _add_field_row(parent, label_text)
	var line := LineEdit.new()
	line.text = default_value
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line)
	return line


func _add_spin(parent: VBoxContainer, label_text: String, min_value: float, max_value: float, step: float, default_value: float) -> SpinBox:
	var row := _add_field_row(parent, label_text)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = default_value
	spin.allow_greater = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spin)
	return spin


func _add_field_row(parent: VBoxContainer, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.custom_minimum_size = Vector2(FIELD_LABEL_MIN_WIDTH, 0.0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	return row


func _on_generate_pressed() -> void:
	var output_root := _output_root.text.strip_edges()
	if not output_root.begins_with("res://"):
		_set_status("Output root must start with res://")
		return

	var stage_id := _sanitize_id(_stage_id.text)
	if stage_id.is_empty():
		_set_status("Stage ID cannot be empty.")
		return

	var stage_name := _stage_name.text.strip_edges()
	if stage_name.is_empty():
		stage_name = _humanize_id(stage_id)

	var timeline_file_name := _sanitize_id(_timeline_file_name.text)
	if timeline_file_name.is_empty():
		_set_status("Timeline file cannot be empty.")
		return

	var output_dir := "%s/%s" % [output_root.trim_suffix("/"), stage_id]
	var make_dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	if make_dir_error != OK:
		_set_status("Could not create %s: error %d" % [output_dir, make_dir_error])
		return

	var timeline = WaveTimelineScript.new()
	timeline.id = StringName(stage_id)
	timeline.display_name = stage_name
	timeline.loop_last_wave = true

	var generated_paths: Array[String] = []
	var count := int(_wave_count.value)
	for index in range(count):
		var wave_number := index + 1
		var wave := _build_wave(stage_id, stage_name, wave_number)
		var wave_path := "%s/wave_%02d.tres" % [output_dir, wave_number]
		var wave_save_error := ResourceSaver.save(wave, wave_path)
		if wave_save_error != OK:
			_set_status("Could not save %s: error %d" % [wave_path, wave_save_error])
			return

		timeline.waves.append(load(wave_path))
		generated_paths.append(wave_path)

	var timeline_path := "%s/%s.tres" % [output_dir, timeline_file_name]
	var timeline_save_error := ResourceSaver.save(timeline, timeline_path)
	if timeline_save_error != OK:
		_set_status("Could not save %s: error %d" % [timeline_path, timeline_save_error])
		return

	generated_paths.append(timeline_path)
	get_editor_interface().get_resource_filesystem().scan()
	_set_status("Generated %d files. Assign %s to EnemyField.wave_timeline." % [generated_paths.size(), timeline_path])


func _build_wave(stage_id: String, stage_name: String, wave_number: int) -> Resource:
	var index := wave_number - 1
	var wave = WaveDefinitionScript.new()
	wave.wave = wave_number
	wave.id = StringName("%s_wave_%02d" % [stage_id, wave_number])
	wave.display_name = "%s Wave %02d" % [stage_name, wave_number]
	wave.duration = float(_duration.value)
	wave.spawn_budget = maxi(int(round(float(_base_budget.value) * pow(1.0 + float(_budget_growth.value) / 100.0, float(index)))), 0)
	wave.max_alive = maxi(int(round(float(_base_max_alive.value) + float(index) * float(_max_alive_growth.value))), 1)
	wave.spawn_interval = maxf(float(_spawn_interval.value), 0.05)
	wave.spawn_interval_step_seconds = maxf(float(_spawn_interval_step_seconds.value), 0.0)
	wave.spawn_interval_step_amount = float(_spawn_interval_step_amount.value)
	wave.enemy_pools.append(_build_enemy_rule(&"enemy", ENEMY_SCENE_PATH, int(_basic_weight.value), 1.0, 1.0, 1.0))

	var pressure_weight := int(_pressure_weight.value)
	if pressure_weight > 0:
		var pressure_hp := 1.0 + float(index) * 0.05
		var pressure_damage := 1.0 + float(index) * 0.03
		wave.enemy_pools.append(_build_enemy_rule(&"enemy_2", ENEMY_2_SCENE_PATH, pressure_weight, pressure_hp, pressure_damage, 1.0))

	var horde_every := int(_horde_every.value)
	if horde_every > 0 and wave_number % horde_every == 0:
		var event = WaveEventScript.new()
		event.id = &"mini_horde"
		event.time = wave.duration * 0.55
		event.enemy_rule = _build_enemy_rule(&"enemy", ENEMY_SCENE_PATH, 100, 1.0, 1.0, 1.08)
		event.count = int(_horde_count.value) + index
		wave.events.append(event)

	return wave


func _build_enemy_rule(
	id: StringName,
	scene_path: String,
	weight: int,
	hp_multiplier: float,
	damage_multiplier: float,
	speed_multiplier: float
) -> Resource:
	var rule = WaveEnemyRuleScript.new()
	rule.id = id
	rule.enemy_scene = load(scene_path) as PackedScene
	rule.weight = maxi(weight, 0)
	rule.hp_multiplier = maxf(hp_multiplier, 0.1)
	rule.damage_multiplier = maxf(damage_multiplier, 0.1)
	rule.speed_multiplier = maxf(speed_multiplier, 0.1)
	return rule


func _sanitize_id(value: String) -> String:
	var sanitized := value.strip_edges().to_lower()
	sanitized = sanitized.replace(" ", "_")
	sanitized = sanitized.replace("-", "_")
	var output := ""
	for index in range(sanitized.length()):
		var character := sanitized.substr(index, 1)
		if character >= "a" and character <= "z":
			output += character
		elif character >= "0" and character <= "9":
			output += character
		elif character == "_":
			output += character

	while output.contains("__"):
		output = output.replace("__", "_")

	while output.begins_with("_"):
		output = output.substr(1)
	while output.ends_with("_"):
		output = output.substr(0, output.length() - 1)

	return output


func _humanize_id(value: String) -> String:
	var words := value.replace("_", " ").split(" ", false)
	for index in range(words.size()):
		words[index] = words[index].capitalize()

	return " ".join(words)


func _set_status(message: String) -> void:
	if _status != null:
		_status.text = message
