extends Control
## Nova icons: thin, precise line pictograms with round ends and, where it
## suits, a small spark dot. Drawn in code on a 24 unit grid scaled to
## min(size.x, size.y) and centered, kept inside a circle so they sit well
## in Nova's ring buttons. The active look adds a soft cyan glow behind the
## icon. The geometry is built only when the icon or the size changes;
## _draw() replays it.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconPen: GDScript = preload("res://tools/directions/ui_common/icon_pen.gd")
const Glow: GDScript = preload("res://tools/directions/ui_common/glow.gd")

const LOOK_NORMAL: int = 0
const LOOK_ACTIVE: int = 1
const LOOK_DISABLED: int = 2
const ICONS: PackedStringArray = ["hammer", "swap", "shuffle", "double", "undo", "settings", "sound_on", "sound_off", "close", "check"]


var _tokens: DirectionTokens = null
var _icon: String = ""
var _look: int = LOOK_NORMAL
var _color: Color = Color.WHITE
var _glow_color: Color = Color.TRANSPARENT
var _has_override: bool = false
var _override: Color = Color.WHITE
var _pen: IconPen = IconPen.new()
## Size and icon the recorded geometry was built for.
var _built_size: Vector2 = Vector2(-1.0, -1.0)
var _built_icon: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	_glow_color = Color(tokens.color("accent"), tokens.num("icon_glow_alpha"))
	_pick_color()
	_rebuild()


func set_icon(icon_name: String) -> void:
	if not ICONS.has(icon_name):
		push_error("nova icon_view: unknown icon '%s'" % icon_name)
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
	if _look == LOOK_ACTIVE:
		Glow.draw(self, size * 0.5, minf(size.x, size.y) * 0.5, _glow_color)
	_pen.replay(self, _color)


func _pick_color() -> void:
	if _has_override:
		_color = _override
	elif _tokens == null:
		_color = Color.WHITE
	elif _look == LOOK_ACTIVE:
		_color = _tokens.color("accent")
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
	# The grid is fitted to icon_fit of the size, so Nova's thin icons keep
	# air inside their ring. Strokes widen by the same share, so they stay
	# icon_stroke units of the full icon size.
	var fit: float = _tokens.num("icon_fit")
	_pen.begin(Rect2(size * (1.0 - fit) * 0.5, size * fit))
	_pen.cap = IconPen.CAP_ROUND
	var w: float = _tokens.num("icon_stroke") / fit
	var spark: float = _tokens.num("icon_spark")
	match _icon:
		"hammer":
			_pen.rotate_around(-40.0)
			_pen.outline(_pen.round_rect_points(Rect2(6.5, 5.0, 11.0, 4.5), 1.2), w)
			_pen.line(Vector2(12.0, 9.5), Vector2(12.0, 19.5), w)
			_pen.rotate_around(0.0)
			_pen.disc(Vector2(5.0, 17.0), spark)
		"swap":
			# Two thin arrows passing each other, each trailing a spark.
			_pen.line(Vector2(7.0, 8.5), Vector2(19.0, 8.5), w)
			_pen.chevron(Vector2(19.5, 8.5), 0.0, 2.5, 2.5, w)
			_pen.disc(Vector2(4.25, 8.5), spark)
			_pen.line(Vector2(17.0, 15.5), Vector2(5.0, 15.5), w)
			_pen.chevron(Vector2(4.5, 15.5), 180.0, 2.5, 2.5, w)
			_pen.disc(Vector2(19.75, 15.5), spark)
		"shuffle":
			_pen.polyline(_pen.curve_points(Vector2(4.5, 8.0), Vector2(10.5, 8.0), Vector2(11.5, 16.0), Vector2(18.5, 16.0)), w)
			_pen.chevron(Vector2(19.5, 16.0), 0.0, 2.5, 2.5, w)
			_pen.polyline(_pen.curve_points(Vector2(4.5, 16.0), Vector2(10.5, 16.0), Vector2(11.5, 8.0), Vector2(18.5, 8.0)), w)
			_pen.chevron(Vector2(19.5, 8.0), 0.0, 2.5, 2.5, w)
		"double":
			# "x2" in strokes, with a spark.
			_pen.line(Vector2(5.0, 9.0), Vector2(10.0, 15.0), w)
			_pen.line(Vector2(10.0, 9.0), Vector2(5.0, 15.0), w)
			var two: PackedVector2Array = _pen.arc_points(Vector2(16.25, 10.75), 2.5, 190.0, 395.0)
			two.append(Vector2(13.5, 15.25))
			two.append(Vector2(19.25, 15.25))
			_pen.polyline(two, w)
			_pen.disc(Vector2(19.5, 5.5), spark)
		"undo":
			# A counterclockwise orbit ending in an arrow pointing down.
			_pen.arc(Vector2(12.5, 12.0), 6.5, 45.0, -180.0, w)
			_pen.chevron(Vector2(6.0, 12.75), 90.0, 2.5, 2.5, w)
		"settings":
			_pen.outline(_gear_points(), w)
			_pen.ring(Vector2(12.0, 12.0), 2.75, w)
		"sound_on":
			_speaker(w)
			_pen.arc(Vector2(11.0, 12.0), 4.0, -45.0, 45.0, w)
			_pen.arc(Vector2(11.0, 12.0), 7.0, -45.0, 45.0, w)
		"sound_off":
			_speaker(w)
			_pen.line(Vector2(15.0, 9.75), Vector2(19.5, 14.25), w)
			_pen.line(Vector2(19.5, 9.75), Vector2(15.0, 14.25), w)
		"close":
			_pen.line(Vector2(7.0, 7.0), Vector2(17.0, 17.0), w)
			_pen.line(Vector2(17.0, 7.0), Vector2(7.0, 17.0), w)
		"check":
			_pen.polyline(PackedVector2Array([Vector2(5.5, 12.5), Vector2(10.0, 17.0), Vector2(18.5, 7.5)]), w)


## A point on the circle of radius around the grid center.
func _on_circle(radius: float, degrees: float) -> Vector2:
	return Vector2(12.0, 12.0) + Vector2.from_angle(deg_to_rad(degrees)) * radius


## Outline of an eight tooth gear around the grid center.
func _gear_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 8:
		var middle: float = 45.0 * float(i)
		points.append(_on_circle(6.25, middle - 15.0))
		points.append(_on_circle(8.5, middle - 9.0))
		points.append(_on_circle(8.5, middle + 9.0))
		points.append(_on_circle(6.25, middle + 15.0))
	return points


func _speaker(w: float) -> void:
	_pen.outline(PackedVector2Array([
		Vector2(4.0, 9.75), Vector2(7.25, 9.75), Vector2(11.0, 6.5),
		Vector2(11.0, 17.5), Vector2(7.25, 14.25), Vector2(4.0, 14.25),
	]), w)
