class_name WorldTooltip
extends Control
## The small plate that names what the pointer rests on in the world. It only ever appears because
## the pointer is resting, makes no sound and never moves on its own (docs/gameplay.md P12). It is
## drawn inside the viewport so it exists inside the click region: while it is up the game adds
## `region()` to the window's clickable areas, as it does for the arrows.

## Room between the plate and the pointer's tip, above it, and where it drops below when there is
## no room above.
const GAP_ABOVE: float = 4.0
const GAP_BELOW: float = 14.0
const PADDING: Vector2 = Vector2(4.0, 1.0)

var _label: Label = Label.new()
var _plate: StyleBoxFlat = StyleBoxFlat.new()
var _font: Font
## Where the viewport's top-left corner is in the window; the plate is placed inside it.
var origin: Vector2 = Vector2.ZERO:
	set(value):
		position += value - origin
		origin = value


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_plate.set_border_width_all(1)
	_plate.anti_aliasing = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", PanelSkin.FONT_SIZE)
	add_child(_label)
	set_skin(PanelSkin.cave())


## The plate takes the age's paper and ink, like the panels.
func set_skin(skin: PanelSkin) -> void:
	_font = skin.font()
	_plate.bg_color = skin.tooltip_fill
	_plate.border_color = skin.muted
	_label.add_theme_font_override("font", _font)
	_label.add_theme_color_override("font_color", skin.ink)
	queue_redraw()


## Shows `text` near a pointer at `at` (viewport pixels).
func show_at(text: String, at: Vector2) -> void:
	_label.text = text
	var text_size: Vector2 = _font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, PanelSkin.FONT_SIZE
	)
	var inner: Vector2 = Vector2(ceilf(text_size.x), ceilf(_font.get_height(PanelSkin.FONT_SIZE)))
	_label.position = PADDING + Vector2.ONE
	_label.size = inner
	size = inner + (PADDING + Vector2.ONE) * 2.0
	position = origin + place(at, size, WorldLayout.VIEW_SIZE)
	visible = true
	queue_redraw()


func hide_tip() -> void:
	visible = false


## Where the plate is, in viewport pixels, or an empty rectangle while it is hidden.
func region() -> Rect2i:
	if not visible:
		return Rect2i()
	return Rect2i(Vector2i(position - origin), Vector2i(size))


## The plate's top-left for a pointer at `at`: centred over the pointer and above it, dropping
## below when there is no room (a thing near the top of the strip), and always inside the view.
static func place(at: Vector2, plate: Vector2, view: Vector2i) -> Vector2:
	var x: float = clampf(at.x - plate.x / 2.0, 0.0, maxf(float(view.x) - plate.x, 0.0))
	var y: float = at.y - plate.y - GAP_ABOVE
	if y < 0.0:
		y = at.y + GAP_BELOW
	y = clampf(y, 0.0, maxf(float(view.y) - plate.y, 0.0))
	return Vector2(roundf(x), roundf(y))


func _draw() -> void:
	draw_style_box(_plate, Rect2(Vector2.ZERO, size))
