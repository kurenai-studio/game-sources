extends Control
## A grand battle's whole field, small: both armies, the flags, the part
## the camera shows, and a ring where each new arrival comes on. Tap or drag
## on it to look there.

const TerrainView := preload("res://scripts/terrain_view.gd")
## How often the armies are redrawn, and how long an arrival's ring shows.
const REDRAW_EVERY := 0.2
const PING_TIME := 6.0

var screen
var _terrain: Node2D
var _marks: Marks
var _since := 0.0
## A press began on the minimap and is still held: only then does dragging
## over it move the view. A drag from the field that crosses it passes on.
var _pressing := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_terrain = TerrainView.new()
	add_child(_terrain)
	_terrain.show_terrain(screen.battle.terrain, hash(screen.title))
	_marks = Marks.new()
	_marks.screen = screen
	add_child(_marks)
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _terrain != null:
		_fit()


func _fit() -> void:
	var s := field_scale()
	for child in [_terrain, _marks]:
		child.scale = Vector2(s, s)


## Minimap pixels per world unit.
func field_scale() -> float:
	var field: Vector2 = screen.battle.terrain.size
	return minf(size.x / field.x, size.y / field.y)


func ping(at: Vector2, team: int) -> void:
	_marks.pings.append({"at": at, "team": team, "left": PING_TIME})


func _process(delta: float) -> void:
	for p in _marks.pings:
		p.left -= delta
	_marks.pings = _marks.pings.filter(func(p): return p.left > 0.0)
	_since += delta
	if _since >= REDRAW_EVERY:
		_since = 0.0
		_marks.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
		elif _pressing:
			_pressing = false
			accept_event()
			return
	var held: bool = event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0
	if _pressing and ((event is InputEventMouseButton and event.pressed) or held):
		screen.look_at(event.position / field_scale())
		_marks.queue_redraw()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.DESK)


## The armies as dots, the flags, the view, and arrivals' rings, drawn in
## world units under the minimap's scale.
class Marks extends Node2D:
	var screen
	var pings: Array = []

	func _draw() -> void:
		var b: Battle = screen.battle
		var p := 1.0 / maxf(scale.x, 0.001)
		for f in b.flags:
			var owner: int = f.owner
			draw_circle(f.pos, 5.0 * p, Palette.NEUTRAL if owner < 0 else Palette.TEAM[owner])
			draw_arc(f.pos, 5.0 * p, 0, TAU, 12, Color.WHITE, 1.0 * p)
		for r in b.regiments:
			if not r.alive():
				continue
			var c: Color = Palette.TEAM_LIGHT[r.team] if r.id in screen.selected else Palette.TEAM[r.team]
			if not r.fighting():
				c = Color(c, 0.45)
			var half := Vector2(r.width() * 0.5, 2.5 * p).max(Vector2(2.5, 2.5) * p)
			draw_set_transform(r.pos, r.facing + PI * 0.5)
			draw_rect(Rect2(-half, half * 2.0), c)
		draw_set_transform(Vector2.ZERO)
		for ping in pings:
			var k: float = ping.left / PING_TIME
			var ring := (1.0 - fmod(k * 3.0, 1.0)) * 14.0 * p + 4.0 * p
			draw_arc(ping.at, ring, 0, TAU, 20, Color(Palette.GOLD, k), 1.5 * p)
		draw_rect(screen.view_rect(), Color(1, 1, 1, 0.85), false, 1.2 * p)
