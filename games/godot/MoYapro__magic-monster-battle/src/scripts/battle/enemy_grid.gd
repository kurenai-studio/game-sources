class_name EnemyGrid
extends Node2D

const COLS: int = 5
const ROWS: int = 7
var cell_size := Vector2(80.0, 80.0)

# cell position -> EnemyData (one entry per occupied cell)
var _cells: Dictionary = {}
# enemy id -> top-left grid position
var _enemy_positions: Dictionary = {}
var _obstacles: Array[ObstacleData] = []
var _obstacle_positions: Array[Vector2i] = []
var _obstacle_hp: Dictionary = {}
var _ground: Dictionary = {}  # Vector2i -> GroundType.Type
var _highlighted := false
var _hovered_cells: Array[Vector2i] = []
var _intents: Dictionary = {}
var _armors: Dictionary = {}
var _blocks: Dictionary = {}
var _shields: Dictionary = {}
var _enemy_statuses: Dictionary = {}  # enemy_id -> Array[StatusData]


func set_armors(armors: Dictionary) -> void:
	_armors = armors
	queue_redraw()


func set_blocks(blocks: Dictionary) -> void:
	_blocks = blocks
	queue_redraw()


func set_shields(shields: Dictionary) -> void:
	_shields = shields
	queue_redraw()


func set_statuses(enemy_statuses: Dictionary) -> void:
	_enemy_statuses = enemy_statuses
	queue_redraw()


func set_ground(ground: Dictionary) -> void:
	_ground = ground
	queue_redraw()


func set_intents(intents: Dictionary) -> void:
	_intents = intents
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered_cells(cells: Array[Vector2i]) -> void:
	_hovered_cells = cells
	queue_redraw()


static func get_hit_cells(target: Vector2i, pattern: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in pattern:
		var cell := target + offset
		if cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
			continue
		if not result.has(cell):
			result.append(cell)
	return result


func get_cell_at(local_pos: Vector2) -> Vector2i:
	var col := int(local_pos.x / cell_size.x)
	var row := int(local_pos.y / cell_size.y)
	if col < 0 or col >= COLS or row < 0 or row >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(col, row)



# --- pure static helpers (unit-testable, no scene tree needed) ---

static func get_cells_for_enemy(grid_pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in grid_size.y:
		for col in grid_size.x:
			cells.append(grid_pos + Vector2i(col, row))
	return cells


static func is_within_bounds(grid_pos: Vector2i, grid_size: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.y < 0:
		return false
	if grid_pos.x + grid_size.x > COLS:
		return false
	if grid_pos.y + grid_size.y > ROWS:
		return false
	return true


func clear_enemies() -> void:
	_cells.clear()
	_enemy_positions.clear()
	queue_redraw()


func set_obstacles(obstacles: Array[ObstacleData], positions: Array[Vector2i], hp: Dictionary) -> void:
	_obstacles = obstacles
	_obstacle_positions = positions
	_obstacle_hp = hp
	queue_redraw()


# --- placement ---

func can_place_enemy(grid_pos: Vector2i, grid_size: Vector2i) -> bool:
	if not is_within_bounds(grid_pos, grid_size):
		return false
	for cell in get_cells_for_enemy(grid_pos, grid_size):
		if _cells.has(cell):
			return false
	return true


func place_enemy(enemy: EnemyData, grid_pos: Vector2i) -> bool:
	if not can_place_enemy(grid_pos, enemy.grid_size):
		return false
	for cell in get_cells_for_enemy(grid_pos, enemy.grid_size):
		_cells[cell] = enemy
	_enemy_positions[enemy.id] = grid_pos
	queue_redraw()
	return true


func remove_enemy(enemy_id: String) -> void:
	if not _enemy_positions.has(enemy_id):
		return
	var to_remove: Array[Vector2i] = []
	for cell: Vector2i in _cells:
		if (_cells[cell] as EnemyData).id == enemy_id:
			to_remove.append(cell)
	for cell in to_remove:
		_cells.erase(cell)
	_enemy_positions.erase(enemy_id)
	queue_redraw()


func get_enemy_at(grid_pos: Vector2i) -> EnemyData:
	return _cells.get(grid_pos, null)



# --- rendering ---

func _draw() -> void:
	_draw_grid()
	_draw_obstacles()
	_draw_enemies()


func _draw_grid() -> void:
	for row in ROWS:
		for col in COLS:
			var rect := Rect2(Vector2(col, row) * cell_size, cell_size)
			draw_rect(rect, Palette.COLOR_GRID_CELL, true)
			if _ground.get(Vector2i(col, row), GroundType.Type.SOIL) == GroundType.Type.PUDDLE:
				draw_rect(rect, Palette.COLOR_STATUS_PUDDLE, true)
			draw_rect(rect, Palette.COLOR_GRID_BORDER, false)
			if _hovered_cells.has(Vector2i(col, row)):
				draw_rect(rect, Palette.COLOR_TARGET_HOVER, false, 3.0)
			elif _highlighted:
				draw_rect(rect, Palette.COLOR_TARGET_AVAILABLE, false, 2.5)


func _draw_obstacles() -> void:
	var font := ThemeDB.fallback_font
	for i in _obstacles.size():
		var obs := _obstacles[i]
		if not _obstacle_hp.has(obs.id):
			continue
		var grid_pos := _obstacle_positions[i]
		var pixel_pos := Vector2(grid_pos) * cell_size
		var pixel_size := Vector2(obs.grid_size) * cell_size
		draw_rect(Rect2(pixel_pos, pixel_size), obs.color, true)
		draw_rect(Rect2(pixel_pos, pixel_size), Color.WHITE, false, 2.0)
		draw_string(font, pixel_pos + Vector2(5, 16), obs.display_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
		draw_string(font, pixel_pos + Vector2(5, 32),
				"%d / %d" % [_obstacle_hp[obs.id], obs.max_hp],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.COLOR_GRID_HP)


func _draw_enemies() -> void:
	var drawn: Dictionary = {}
	for cell_pos: Vector2i in _cells:
		var enemy: EnemyData = _cells[cell_pos]
		if drawn.has(enemy.id):
			continue
		drawn[enemy.id] = true

		var grid_pos: Vector2i = _enemy_positions[enemy.id]
		var pixel_pos := Vector2(grid_pos) * cell_size
		var pixel_size := Vector2(enemy.grid_size) * cell_size

		var enemy_rect := Rect2(pixel_pos, pixel_size)
		draw_rect(enemy_rect, enemy.color, true)

		var occupied := get_cells_for_enemy(grid_pos, enemy.grid_size)
		var is_hovered := false
		for hc in _hovered_cells:
			if occupied.has(hc):
				is_hovered = true
				break
		var border_color := Palette.COLOR_TARGET_HOVER if is_hovered \
				else (Palette.COLOR_TARGET_AVAILABLE if _highlighted else Color.WHITE)
		var border_width := 3.0 if (is_hovered or _highlighted) else 2.0
		draw_rect(enemy_rect, border_color, false, border_width)

		var font := ThemeDB.fallback_font
		draw_string(font, pixel_pos + Vector2(5, 16), enemy.display_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, enemy.label_color)
		draw_string(font, pixel_pos + Vector2(5, 32),
				"%d / %d" % [enemy.current_hp, enemy.max_hp],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.COLOR_GRID_HP)
		if _armors.has(enemy.id) and _armors[enemy.id] > 0:
			draw_string(font, pixel_pos + Vector2(5, 44),
					"🛡 %d" % _armors[enemy.id],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.COLOR_GRID_INTENT)
		if _shields.has(enemy.id) and _shields[enemy.id] > 0:
			draw_string(font, pixel_pos + Vector2(pixel_size.x - 5, 44),
					"◇ %d" % _shields[enemy.id],
					HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Palette.COLOR_GRID_FROZEN)
		if _blocks.has(enemy.id) and _blocks[enemy.id] > 0:
			draw_string(font, pixel_pos + Vector2(pixel_size.x - 5, 56),
					"🔲 %d" % _blocks[enemy.id],
					HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Palette.COLOR_GRID_BLOCK)
		var status_icons: Array = (_enemy_statuses.get(enemy.id, []) as Array).filter(
				func(s: StatusData) -> bool: return s.display_name != "")
		if not status_icons.is_empty():
			var intent_reserve := 16.0 if _intents.has(enemy.id) else 4.0
			var icon_y := pixel_size.y - intent_reserve - 2.0
			var icon_x := 5.0
			for status: StatusData in status_icons:
				draw_string(font, pixel_pos + Vector2(icon_x, icon_y),
						status.icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, status.display_color)
				icon_x += 12.0
		if _intents.has(enemy.id):
			var intent: Dictionary = _intents[enemy.id]
			var action_name: String = intent.get("action_name", "")
			var target_name: String = intent.get("target_name", "")
			var label := action_name + (" → " + target_name if target_name != "" else "")
			draw_string(font, pixel_pos + Vector2(5, pixel_size.y - 6),
					label, HORIZONTAL_ALIGNMENT_LEFT, pixel_size.x - 10, 10,
					Palette.COLOR_GRID_SHIELD_TEXT)
