extends Control
## Gumdrop icons: chunky candy pictograms with thick round strokes and
## filled shapes, drawn in code on a 24 unit grid scaled to min(size.x,
## size.y) and centered. The geometry is built only when the icon or the
## size changes; _draw() replays it.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconPen: GDScript = preload("res://tools/directions/ui_common/icon_pen.gd")

const LOOK_NORMAL: int = 0
const LOOK_ACTIVE: int = 1
const LOOK_DISABLED: int = 2
const ICONS: PackedStringArray = ["hammer", "swap", "shuffle", "double", "undo", "settings", "sound_on", "sound_off", "close", "check"]


var _tokens: DirectionTokens = null
var _icon: String = ""
var _look: int = LOOK_NORMAL
var _color: Color = Color.WHITE
var _has_override: bool = false
var _override: Color = Color.WHITE
var _pen: IconPen = IconPen.new()
## Size and icon the recorded geometry was built for.
var _built_size: Vector2 = Vector2(-1.0, -1.0)
var _built_icon: String = ""
## Stroke width on the 24 unit grid, from the icon_stroke token.
var _stroke: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	_pick_color()
	_rebuild()


func set_icon(icon_name: String) -> void:
	if not ICONS.has(icon_name):
		push_error("gumdrop icon_view: unknown icon '%s'" % icon_name)
		return
	_icon = icon_name
	_rebuild()


func set_look(look: int) -> void:
	_look = look
	_pick_color()
	queue_redraw()


## Overrides the color the look picks, for icons that sit on a button or chip.
func set_color(color: Color) -> void:
	_has_override = true
	_override = color
	_pick_color()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild()


func _draw() -> void:
	if _tokens == null or _icon.is_empty():
		return
	# A view sized while outside the tree gets no resize notification, so
	# it builds here when it first draws at a new size.
	if size != _built_size or _icon != _built_icon:
		_build()
	_pen.replay(self, _color)


func _pick_color() -> void:
	if _has_override:
		_color = _override
	elif _tokens == null:
		_color = Color.WHITE
	elif _look == LOOK_ACTIVE:
		_color = _tokens.color("ink_dark")
	elif _look == LOOK_DISABLED:
		_color = _tokens.color("disabled_ink")
	else:
		_color = _tokens.color("ink")


func _rebuild() -> void:
	_build()
	queue_redraw()


## Records the current icon at the current size.
func _build() -> void:
	_built_size = size
	_built_icon = _icon
	if _tokens == null:
		return
	_stroke = _tokens.num("icon_stroke")
	_pen.begin(Rect2(Vector2.ZERO, size))
	_pen.cap = IconPen.CAP_ROUND
	match _icon:
		"hammer":
			_hammer()
		"swap":
			_swap()
		"shuffle":
			_shuffle()
		"double":
			_double()
		"undo":
			_undo()
		"settings":
			_settings()
		"sound_on":
			_speaker()
			_pen.arc(Vector2(10.0, 12.0), 5.25, -42.0, 42.0, _stroke)
			_pen.arc(Vector2(10.0, 12.0), 9.25, -42.0, 42.0, _stroke)
		"sound_off":
			_speaker()
			_pen.line(Vector2(14.5, 9.25), Vector2(20.0, 14.75), _stroke)
			_pen.line(Vector2(20.0, 9.25), Vector2(14.5, 14.75), _stroke)
		"close":
			_pen.line(Vector2(6.5, 6.5), Vector2(17.5, 17.5), _stroke)
			_pen.line(Vector2(17.5, 6.5), Vector2(6.5, 17.5), _stroke)
		"check":
			_pen.polyline(PackedVector2Array([Vector2(5.0, 12.5), Vector2(10.0, 17.0), Vector2(19.0, 7.5)]), _stroke)


## A mallet tipped over to strike: a filled rounded head on a thick handle.
func _hammer() -> void:
	_pen.rotate_around(-40.0)
	_pen.fill(_pen.round_rect_points(Rect2(5.5, 4.0, 13.0, 6.5), 2.2))
	_pen.line(Vector2(12.0, 10.0), Vector2(12.0, 20.0), _stroke)
	_pen.rotate_around(0.0)


## Two fat arrows passing each other.
func _swap() -> void:
	_pen.line(Vector2(4.5, 8.5), Vector2(15.5, 8.5), _stroke)
	_pen.head(Vector2(20.5, 8.5), 0.0, 5.5, 4.2)
	_pen.line(Vector2(19.5, 15.5), Vector2(8.5, 15.5), _stroke)
	_pen.head(Vector2(3.5, 15.5), 180.0, 5.5, 4.2)


## Two soft ropes that cross, each ending in a fat arrow.
func _shuffle() -> void:
	_pen.polyline(_pen.curve_points(Vector2(4.0, 7.5), Vector2(10.5, 7.5), Vector2(10.5, 16.5), Vector2(16.0, 16.5)), _stroke)
	_pen.head(Vector2(20.5, 16.5), 0.0, 5.0, 4.0)
	_pen.polyline(_pen.curve_points(Vector2(4.0, 16.5), Vector2(10.5, 16.5), Vector2(10.5, 7.5), Vector2(16.0, 7.5)), _stroke)
	_pen.head(Vector2(20.5, 7.5), 0.0, 5.0, 4.0)


## "x2" in strokes: a cross, then a two with a round bowl.
func _double() -> void:
	_pen.line(Vector2(4.0, 9.0), Vector2(10.0, 15.5), _stroke)
	_pen.line(Vector2(10.0, 9.0), Vector2(4.0, 15.5), _stroke)
	var two: PackedVector2Array = _pen.arc_points(Vector2(16.75, 10.25), 3.0, 180.0, 395.0)
	two.append(Vector2(13.5, 16.25))
	two.append(Vector2(20.25, 16.25))
	_pen.polyline(two, _stroke)


## A hook arrow turning back to the left.
func _undo() -> void:
	var path: PackedVector2Array = PackedVector2Array([Vector2(9.0, 8.5), Vector2(14.5, 8.5)])
	path.append_array(_pen.arc_points(Vector2(14.5, 13.0), 4.5, -90.0, 90.0))
	path.append(Vector2(8.5, 17.5))
	_pen.polyline(path, _stroke)
	_pen.head(Vector2(3.5, 8.5), 180.0, 5.5, 4.2)


## A ring with eight round candy teeth.
func _settings() -> void:
	_pen.ring(Vector2(12.0, 12.0), 4.75, _stroke)
	for i: int in 8:
		var dir: Vector2 = Vector2.from_angle(deg_to_rad(22.5 + 45.0 * float(i)))
		_pen.line(Vector2(12.0, 12.0) + dir * 7.25, Vector2(12.0, 12.0) + dir * 8.5, _stroke)


## A filled speaker with softened corners.
func _speaker() -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(3.0, 9.5), Vector2(6.25, 9.5), Vector2(10.0, 6.0),
		Vector2(10.0, 18.0), Vector2(6.25, 14.5), Vector2(3.0, 14.5),
	])
	_pen.fill(body)
	_pen.outline(body, 2.0)
