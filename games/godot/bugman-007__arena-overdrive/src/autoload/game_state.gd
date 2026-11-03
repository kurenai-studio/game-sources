extends Node
## Run/session state, data registries, scene transitions and achievement toasts.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/game.tscn"

var characters: Dictionary = {}
var enemies: Dictionary = {}
var upgrades: Array[UpgradeData] = []
var selected_character: StringName = &"vanguard"
var last_results: Dictionary = {}
var tour_dir: String = ""
var transitioning: bool = false

var _fade: ColorRect
var _toasts: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	characters = DataRegistry.characters()
	enemies = DataRegistry.enemies()
	upgrades = DataRegistry.upgrades()
	_build_overlay()
	EventBus.achievement_unlocked.connect(_show_toast)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tour="):
			tour_dir = arg.get_slice("=", 1)
			var tour: Node = load("res://scripts/tools/screenshot_tour.gd").new()
			add_child(tour)


func is_tour() -> bool:
	return tour_dir != ""


func sorted_characters() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	for id: StringName in characters:
		out.append(characters[id])
	out.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.sort_order < b.sort_order)
	return out


func _build_overlay() -> void:
	var toast_layer := CanvasLayer.new()
	toast_layer.layer = 90
	add_child(toast_layer)
	_toasts = VBoxContainer.new()
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_toasts.position = Vector2(-380, 90)
	_toasts.custom_minimum_size = Vector2(360, 0)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.add_child(_toasts)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(UiTheme.BG, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(_fade)
	fade_layer.add_child(_fade)


func change_scene(path: String) -> void:
	if transitioning:
		return
	transitioning = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_fade, "color:a", 1.0, 0.28)
	await tw.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween().set_ignore_time_scale(true)
	tw2.tween_property(_fade, "color:a", 0.0, 0.4)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transitioning = false


func start_run(character_id: StringName) -> void:
	selected_character = character_id
	change_scene(GAME_SCENE)


func go_to_menu() -> void:
	change_scene(MENU_SCENE)


## Lifetime numbers merged with the current run's numbers.
func lifetime_snapshot(run: Dictionary = {}) -> Dictionary:
	return {
		"total_kills": SaveSystem.stat("total_kills") + int(run.get("kills_unbanked", 0)),
		"bosses_killed": SaveSystem.stat("bosses_killed") + int(run.get("bosses_unbanked", 0)),
		"coins_earned": SaveSystem.stat("coins_earned"),
		"wave": maxi(SaveSystem.stat("best_wave"), int(run.get("wave", 0))),
		"max_combo": int(run.get("max_combo", 0)),
		"level": int(run.get("level", 0)),
		"flawless_waves": int(run.get("flawless_waves", 0)),
		"characters_unlocked": (SaveSystem.data["unlocked_characters"] as Array).size(),
	}


func check_achievements(run: Dictionary = {}) -> Array[StringName]:
	var unlocked := Achievements.evaluate(lifetime_snapshot(run), SaveSystem.data["achievements"])
	for id in unlocked:
		SaveSystem.add_achievement(id)
		EventBus.achievement_unlocked.emit(id)
	if not unlocked.is_empty():
		SaveSystem.save_data()
	return unlocked


func _show_toast(id: StringName) -> void:
	AudioManager.play_ui(&"achievement")
	var panel := PanelContainer.new()
	panel.theme_type_variation = "CardPanel"
	var style := UiTheme.box(Color(UiTheme.PANEL, 0.95), UiTheme.GOLD, 2, 12, Vector4(16, 10, 16, 10))
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var star := UiKit.label("★", "GoldLabel", 34)
	row.add_child(star)
	var col := VBoxContainer.new()
	col.add_child(UiKit.label(tr("ACHIEVEMENT_UNLOCKED"), "MutedLabel", 14))
	col.add_child(UiKit.label(tr(Achievements.name_key(id)), "AccentLabel", 20))
	row.add_child(col)
	panel.add_child(row)
	_toasts.add_child(panel)
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_ignore_time_scale(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5)
	tw.tween_callback(panel.queue_free)
