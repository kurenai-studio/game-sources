class_name BattleDebugBar extends Node

signal end_turn_requested
signal undo_requested
signal win_requested
signal reroll_requested
signal clear_requested
signal level_changed(value: float)
signal enemy_selected(cls: Variant, size: Vector2i)
signal obstacle_selected(cls: Variant, size: Vector2i)

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const BOTTOM_BAR_H := 38.0

var _undo_button: Button = null
var _place_dropdown: OptionButton = null
var _obstacle_dropdown: OptionButton = null
var _level_spinbox: SpinBox = null
var _monsters: Array = []
var _obstacles: Array = []


func setup(parent: Node) -> void:
	_build_monsters_list()
	_build_obstacles_list()
	_build_ui(parent)


func set_undo_enabled(enabled: bool) -> void:
	if _undo_button != null:
		_undo_button.disabled = not enabled


func get_level() -> int:
	return int(_level_spinbox.value) if _level_spinbox != null else 1


func reset_place_dropdown() -> void:
	_place_dropdown.select(0)


func reset_obstacle_dropdown() -> void:
	_obstacle_dropdown.select(0)


func _build_obstacles_list() -> void:
	var seen: Dictionary = {}
	for biome: BiomeData in BiomesData.all():
		for cls in biome.obstacle_pool:
			if seen.has(cls):
				continue
			seen[cls] = true
			var instance: ObstacleData = cls.new()
			_obstacles.append([instance.display_name, cls])
	_obstacles.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _build_monsters_list() -> void:
	var seen: Dictionary = {}
	for biome: BiomeData in BiomesData.all():
		for cls in biome.monster_pool:
			if seen.has(cls):
				continue
			seen[cls] = true
			var instance: EnemyData = cls.new()
			_monsters.append([instance.display_name, cls])
	_monsters.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _build_ui(parent: Node) -> void:
	var layer := CanvasLayer.new()
	parent.add_child(layer)

	var bg := ColorRect.new()
	bg.color = Palette.COLOR_DEBUG_BG
	bg.position = Vector2(0, SCREEN_H - BOTTOM_BAR_H)
	bg.size = Vector2(SCREEN_W, BOTTOM_BAR_H)
	layer.add_child(bg)

	var sep := ColorRect.new()
	sep.color = Palette.COLOR_DEBUG_SEP
	sep.position = Vector2(0, SCREEN_H - BOTTOM_BAR_H)
	sep.size = Vector2(SCREEN_W, 1)
	layer.add_child(sep)

	var battle_label := Label.new()
	battle_label.text = "Battle %d" % (GameState.battle_count + 1)
	battle_label.position = Vector2(16, SCREEN_H - BOTTOM_BAR_H)
	battle_label.size = Vector2(200, BOTTOM_BAR_H)
	battle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battle_label.add_theme_color_override("font_color", Palette.COLOR_DEBUG_LABEL)
	layer.add_child(battle_label)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.size = Vector2(70, BOTTOM_BAR_H - 10)
	clear_button.position = Vector2(220, SCREEN_H - BOTTOM_BAR_H + 5)
	clear_button.pressed.connect(func(): clear_requested.emit())
	layer.add_child(clear_button)

	_place_dropdown = OptionButton.new()
	_place_dropdown.size = Vector2(160, BOTTOM_BAR_H - 10)
	_place_dropdown.position = Vector2(298, SCREEN_H - BOTTOM_BAR_H + 5)
	_place_dropdown.add_item("Monster...")
	for entry in _monsters:
		_place_dropdown.add_item(entry[0])
	_place_dropdown.item_selected.connect(_on_place_item_selected)
	layer.add_child(_place_dropdown)

	_obstacle_dropdown = OptionButton.new()
	_obstacle_dropdown.size = Vector2(160, BOTTOM_BAR_H - 10)
	_obstacle_dropdown.position = Vector2(466, SCREEN_H - BOTTOM_BAR_H + 5)
	_obstacle_dropdown.add_item("Obstacle...")
	for entry in _obstacles:
		_obstacle_dropdown.add_item(entry[0])
	_obstacle_dropdown.item_selected.connect(_on_obstacle_item_selected)
	layer.add_child(_obstacle_dropdown)

	var level_label := Label.new()
	level_label.text = "Lvl"
	level_label.position = Vector2(634, SCREEN_H - BOTTOM_BAR_H)
	level_label.size = Vector2(28, BOTTOM_BAR_H)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Palette.COLOR_DEBUG_LABEL)
	layer.add_child(level_label)

	var biome := GameState.current_biome if GameState.current_biome != null else BiomesData.all()[0]
	var biome_level: int = GameState.battle_count_by_biome.get(biome.name, 0) + 1
	_level_spinbox = SpinBox.new()
	_level_spinbox.min_value = 1
	_level_spinbox.max_value = BattleComposer.MAX_LEVEL
	_level_spinbox.step = 1
	_level_spinbox.value = mini(biome_level, BattleComposer.MAX_LEVEL)
	_level_spinbox.size = Vector2(66, BOTTOM_BAR_H - 10)
	_level_spinbox.position = Vector2(662, SCREEN_H - BOTTOM_BAR_H + 5)
	_level_spinbox.value_changed.connect(func(v: float): level_changed.emit(v))
	layer.add_child(_level_spinbox)

	var end_turn_button := Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.size = Vector2(100, BOTTOM_BAR_H - 10)
	end_turn_button.position = Vector2(SCREEN_W - 420, SCREEN_H - BOTTOM_BAR_H + 5)
	end_turn_button.pressed.connect(func(): end_turn_requested.emit())
	layer.add_child(end_turn_button)

	var win_button := Button.new()
	win_button.text = "🏆 Win"
	win_button.size = Vector2(90, BOTTOM_BAR_H - 10)
	win_button.position = Vector2(SCREEN_W - 310, SCREEN_H - BOTTOM_BAR_H + 5)
	win_button.pressed.connect(func(): win_requested.emit())
	layer.add_child(win_button)

	var reroll_button := Button.new()
	reroll_button.text = "↺ Reroll"
	reroll_button.size = Vector2(90, BOTTOM_BAR_H - 10)
	reroll_button.position = Vector2(SCREEN_W - 210, SCREEN_H - BOTTOM_BAR_H + 5)
	reroll_button.pressed.connect(func(): reroll_requested.emit())
	layer.add_child(reroll_button)

	_undo_button = Button.new()
	_undo_button.text = "↩ Undo  Ctrl+Z"
	_undo_button.size = Vector2(148, BOTTOM_BAR_H - 10)
	_undo_button.position = Vector2(SCREEN_W - 112, SCREEN_H - BOTTOM_BAR_H + 5)
	_undo_button.pressed.connect(func(): undo_requested.emit())
	layer.add_child(_undo_button)


func _on_place_item_selected(index: int) -> void:
	if index == 0:
		enemy_selected.emit(null, Vector2i.ZERO)
		return
	var entry: Array = _monsters[index - 1]
	var cls: Variant = entry[1]
	var size: Vector2i = (cls.new() as EnemyData).grid_size
	enemy_selected.emit(cls, size)


func _on_obstacle_item_selected(index: int) -> void:
	if index == 0:
		obstacle_selected.emit(null, Vector2i.ZERO)
		return
	var entry: Array = _obstacles[index - 1]
	var cls: Variant = entry[1]
	var size: Vector2i = (cls.new() as ObstacleData).grid_size
	obstacle_selected.emit(cls, size)
