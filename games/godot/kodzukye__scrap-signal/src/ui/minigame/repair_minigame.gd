class_name RepairMinigame
extends CanvasLayer

signal repair_complete()

const PUZZLES: Dictionary = {
	"vrac7": {
		"title": "RECONNECTION — MOTOR SYSTEM",
		"colors": [Color("#f4c430"), Color("#5bc8f5"), Color("#f47c3c")]
	},
	"iris3": {
		"title": "RECALIBRATION — OPTICAL SENSOR",
		"colors": [Color("#f4c430"), Color("#5bc8f5")]
	},
	"scrap09": {
		"title": "SELF-REPAIR — SCRAP-09",
		"colors": [Color("#f4c430"), Color("#5bc8f5"), Color("#f47c3c")]
	},
}

const DOT_RADIUS: float = 8.0
const WIRE_WIDTH: float = 4.0

var current_puzzle : Dictionary
var right_order    : Array = []
var connections    : Dictionary = {}
var dragging       : int = -1
var drag_pos       : Vector2 = Vector2.ZERO

@onready var wire_canvas : Control = $Background/Panel/VBoxContainer/WireCanvas
@onready var title_lbl   : Label   = $Background/Panel/VBoxContainer/Title
@onready var status      : Label   = $Background/Panel/VBoxContainer/StatusLabel


func _ready() -> void:
	var vbox: VBoxContainer = $Background/Panel/VBoxContainer
	layer = 1000
	wire_canvas.custom_minimum_size  = Vector2(320, 120)
	wire_canvas.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_cancel()

func open(robot_id: String) -> void:
	current_puzzle = PUZZLES.get(robot_id, {})
	if current_puzzle.is_empty():
		return
	title_lbl.text = current_puzzle["title"] as String
	connections.clear()
	dragging = -1

	var n: int = (current_puzzle["colors"] as Array).size()  # ← FIX ligne 49
	right_order = range(n)
	right_order.shuffle()

	_set_hud_visible(false)
	_set_player_enabled(false)
	_update_status()
	wire_canvas.queue_redraw()
	show()

# ── Drawing ────────────────────────────────────────────────────────────────────

func draw_wires(canvas: Control) -> void:
	if current_puzzle.is_empty():
		return
	var colors: Array = current_puzzle["colors"] as Array
	var n: int = colors.size()
	var w: float = canvas.size.x
	var h: float = canvas.size.y

	canvas.draw_line(Vector2(w * 0.5, 10), Vector2(w * 0.5, h - 10),
		Color(1, 1, 1, 0.08), 1.0)

	for left_idx in connections:
		var right_slot: int = connections[left_idx]
		var from: Vector2 = _left_pos(left_idx, n, w, h)
		var to: Vector2 = _right_pos(right_slot, n, w, h)
		canvas.draw_line(from, to, colors[left_idx], WIRE_WIDTH, true)

	if dragging >= 0:
		var from: Vector2 = _left_pos(dragging, n, w, h)
		canvas.draw_line(from, drag_pos, (colors[dragging] as Color).lightened(0.3), WIRE_WIDTH, true)

	for i in n:
		var pos: Vector2 = _left_pos(i, n, w, h)
		var c: Color = colors[i] as Color
		canvas.draw_circle(pos, DOT_RADIUS, c)
		if not connections.has(i):
			canvas.draw_arc(pos, DOT_RADIUS + 4, 0, TAU, 32, c.lightened(0.5), 2.0)

	for i in n:
		var pos: Vector2 = _right_pos(i, n, w, h)
		var col_idx : int = right_order[i]
		var c: Color = colors[col_idx] as Color
		canvas.draw_circle(pos, DOT_RADIUS, c)
		if not connections.values().has(i):
			canvas.draw_arc(pos, DOT_RADIUS + 4, 0, TAU, 32, c.lightened(0.5), 2.0)

# ── Input ─────────────────────────────────────────────────────────────────────

func on_canvas_input(event: InputEvent) -> void:
	if current_puzzle.is_empty():
		return
	var colors: Array = current_puzzle["colors"] as Array
	var n: int = colors.size()
	var w: float = wire_canvas.size.x
	var h: float = wire_canvas.size.y

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in n:
				if event.position.distance_to(_left_pos(i, n, w, h)) <= DOT_RADIUS + 6.0:
					connections.erase(i)
					dragging = i
					drag_pos = event.position
					_update_status()
					wire_canvas.queue_redraw()
					return
		else:
			if dragging >= 0:
				for i in n:
					if connections.values().has(i):
						continue
					if event.position.distance_to(_right_pos(i, n, w, h)) <= DOT_RADIUS + 6.0:
						if right_order[i] == dragging:
							connections[dragging] = i
							_update_status()
							_check_win()
				dragging = -1
				wire_canvas.queue_redraw()

	elif event is InputEventMouseMotion and dragging >= 0:
		drag_pos = event.position
		wire_canvas.queue_redraw()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _left_pos(i: int, n: int, w: float, h: float) -> Vector2:
	return Vector2(DOT_RADIUS + 20.0, h / (n + 1) * (i + 1))

func _right_pos(i: int, n: int, w: float, h: float) -> Vector2:
	return Vector2(w - DOT_RADIUS - 20.0, h / (n + 1) * (i + 1))

func _check_win() -> void:
	if connections.size() == (current_puzzle["colors"] as Array).size():
		await get_tree().create_timer(0.6).timeout
		repair_complete.emit()
		_close()

func _cancel() -> void:
	dragging = -1
	_close()

func _close() -> void:
	_set_hud_visible(true)
	_set_player_enabled(true)
	hide()

func _update_status() -> void:
	var total: int = (current_puzzle.get("colors", []) as Array).size()
	var done: int = connections.size()
	if done == total:
		status.text = "REPAIR COMPLETE"
		status.add_theme_color_override("font_color", Color("#6daa45"))
	else:
		status.text = "%d / %d connections established" % [done, total]
		status.remove_theme_color_override("font_color")

func _set_hud_visible(v: bool) -> void:
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = v

func _set_player_enabled(enabled: bool) -> void:
	var player: Variant = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process(enabled)
		player.set_physics_process(enabled)
		player.set_process_unhandled_input(enabled)
		player.is_locked = false
		if not enabled and player is CharacterBody2D:
			player.velocity = Vector2.ZERO
