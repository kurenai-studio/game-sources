extends Control
## Slate icons: geometric signage pictograms. Straight segments and true
## circles, square ends, no fills, drawn in code on a 24 unit grid scaled to
## min(size.x, size.y) and centered. The geometry is built only when the
## icon or the size changes; _draw() replays it.
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
		push_error("slate icon_view: unknown icon '%s'" % icon_name)
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
	_pen.cap = IconPen.CAP_SQUARE
	match _icon:
		"hammer":
			# Tipped over to strike, like a pictogram on a sign.
			_pen.rotate_around(-45.0)
			_pen.outline(_rect(6.0, 4.0, 18.0, 9.0), _stroke)
			_pen.line(Vector2(12.0, 9.0), Vector2(12.0, 20.5), _stroke)
			_pen.rotate_around(0.0)
		"swap":
			_pen.line(Vector2(4.0, 8.0), Vector2(19.0, 8.0), _stroke)
			_pen.chevron(Vector2(20.0, 8.0), 0.0, 4.0, 4.0, _stroke)
			_pen.line(Vector2(20.0, 16.0), Vector2(5.0, 16.0), _stroke)
			_pen.chevron(Vector2(4.0, 16.0), 180.0, 4.0, 4.0, _stroke)
		"shuffle":
			_pen.polyline(PackedVector2Array([Vector2(3.0, 7.0), Vector2(8.0, 7.0), Vector2(15.0, 17.0), Vector2(20.0, 17.0)]), _stroke)
			_pen.chevron(Vector2(21.0, 17.0), 0.0, 3.5, 3.5, _stroke)
			_pen.polyline(PackedVector2Array([Vector2(3.0, 17.0), Vector2(8.0, 17.0), Vector2(15.0, 7.0), Vector2(20.0, 7.0)]), _stroke)
			_pen.chevron(Vector2(21.0, 7.0), 0.0, 3.5, 3.5, _stroke)
		"double":
			# "x2" in strokes: a cross and a two built from straight segments.
			_pen.line(Vector2(4.0, 8.0), Vector2(10.0, 16.0), _stroke)
			_pen.line(Vector2(10.0, 8.0), Vector2(4.0, 16.0), _stroke)
			_pen.polyline(PackedVector2Array([
				Vector2(13.5, 8.0), Vector2(20.0, 8.0), Vector2(20.0, 12.0),
				Vector2(13.5, 12.0), Vector2(13.5, 16.0), Vector2(20.0, 16.0),
			]), _stroke)
		"undo":
			_pen.polyline(PackedVector2Array([Vector2(5.0, 8.0), Vector2(19.0, 8.0), Vector2(19.0, 17.0), Vector2(10.0, 17.0)]), _stroke)
			_pen.chevron(Vector2(4.0, 8.0), 180.0, 4.0, 4.0, _stroke)
		"settings":
			# Three sliders, each with a square knob.
			_slider(5.0, 7.5)
			_slider(12.0, 16.5)
			_slider(19.0, 10.5)
		"sound_on":
			_speaker()
			_pen.line(Vector2(15.5, 10.0), Vector2(15.5, 14.0), _stroke)
			_pen.line(Vector2(19.5, 7.5), Vector2(19.5, 16.5), _stroke)
		"sound_off":
			_speaker()
			_pen.line(Vector2(15.5, 9.5), Vector2(20.5, 14.5), _stroke)
			_pen.line(Vector2(20.5, 9.5), Vector2(15.5, 14.5), _stroke)
		"close":
			_pen.line(Vector2(6.0, 6.0), Vector2(18.0, 18.0), _stroke)
			_pen.line(Vector2(18.0, 6.0), Vector2(6.0, 18.0), _stroke)
		"check":
			_pen.polyline(PackedVector2Array([Vector2(4.5, 12.5), Vector2(9.5, 17.5), Vector2(19.5, 7.5)]), _stroke)


## Corner points of a rectangle, in grid units.
func _rect(left: float, top: float, right: float, bottom: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)])


## One slider track at row y with a square knob centered at knob_x.
func _slider(y: float, knob_x: float) -> void:
	var half: float = 2.25
	_pen.line(Vector2(3.0, y), Vector2(knob_x - half, y), _stroke)
	_pen.outline(_rect(knob_x - half, y - half, knob_x + half, y + half), _stroke)
	_pen.line(Vector2(knob_x + half, y), Vector2(21.0, y), _stroke)


## A speaker outline. Its sharp corners use plain joins: square ends would
## poke out past the acute corners.
func _speaker() -> void:
	_pen.cap = IconPen.CAP_BUTT
	_pen.outline(PackedVector2Array([
		Vector2(3.5, 9.5), Vector2(7.0, 9.5), Vector2(12.0, 5.5),
		Vector2(12.0, 18.5), Vector2(7.0, 14.5), Vector2(3.5, 14.5),
	]), _stroke)
	_pen.cap = IconPen.CAP_SQUARE
