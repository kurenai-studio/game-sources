class_name SkinWordmark extends Control
## The drawn "SumUp" wordmark (docs/ARCHITECTURE.md section 7, DESIGN_SYSTEM.md
## 7.2 and 7.13). Each skin subclasses it in src/design/<id>/ with its own
## look. Screens get one from UiKit.make_wordmark() and use only the methods
## below.
##
## "Sum" in ink and "Up" in accent, set with no gap in the display role's
## font, weight and tracking, never cased. It starts at the display role's
## size (the About screen); fit_width() sizes it for the splash.
##
## Its minimum size is the drawn box: the drawn width (per skin) by the font's
## ascent plus descent, plus Gumdrop's lip, plus Slate's masthead rule when on.
## Given more room, it draws centered (Slate: on the left edge, and the rule
## spans the whole width). It ignores the mouse. Everything is worked out once
## per skin and size; _draw() only replays it.

const PARTS: Array[String] = ["Sum", "Up"]

var _skin: SkinData = null
var _font: Font = null
## The display role's size: the smallest the wordmark ever gets.
var _base_px: int = 1
## The size the wordmark is drawn at.
var _px: int = 1
## The width given to fit_width(); negative for none (the display size).
var _fit: float = -1.0
var _masthead: bool = false
# Worked out once per size.
var _sum_width: float = 0.0
var _up_width: float = 0.0
var _ascent: float = 0.0
var _descent: float = 0.0
var _drawn_width: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData) -> void:
	_skin = skin
	_font = skin.font(&"display")
	_base_px = maxi(1, skin.font_size(&"display"))
	_on_setup()
	_build(_fitted_px())


## The largest size whose drawn width fits width (DESIGN_SYSTEM.md 7.2):
## floor(display size x width / drawn width at the display size), then 1 px
## smaller until it fits, never below the display size.
func fit_width(width: float) -> void:
	_fit = width
	if _skin != null:
		_build(_fitted_px())


## Slate's masthead rule under the wordmark on the splash (DESIGN_SYSTEM.md
## 7.2): space_s below it, a hairline line in line from edge to edge. The
## other skins ignore it.
func set_masthead(on: bool) -> void:
	_masthead = on
	if _skin != null:
		_build(_px)


func _notification(what: int) -> void:
	# Godot drops minimum size updates made outside the tree, so a wordmark
	# fitted before it was added reports its size again on entering.
	if what == NOTIFICATION_ENTER_TREE:
		update_minimum_size()


func _get_minimum_size() -> Vector2:
	return Vector2(ceilf(_drawn_width), ceilf(_ascent + _descent + float(_lip_depth(_px)) + _masthead_height()))


func _draw() -> void:
	if _skin == null:
		return
	var left: float = 0.0
	if _centered():
		left = maxf(0.0, roundf((size.x - _drawn_width) * 0.5))
	_draw_mark(left, _ascent)


## The drawn width at a size: the two advances plus the skin's extra.
func _drawn_width_at(px: int) -> float:
	return _advance(PARTS[0], px) + _advance(PARTS[1], px) + _extra_width(px)


func _fitted_px() -> int:
	if _fit < 0.0:
		return _base_px
	var at_base: float = _drawn_width_at(_base_px)
	if at_base <= 0.0:
		return _base_px
	var fitted: int = floori(float(_base_px) * _fit / at_base)
	while fitted > _base_px and _drawn_width_at(fitted) > _fit:
		fitted -= 1
	return maxi(_base_px, fitted)


func _build(px: int) -> void:
	_px = px
	_sum_width = _advance(PARTS[0], px)
	_up_width = _advance(PARTS[1], px)
	_ascent = _font.get_ascent(px)
	_descent = _font.get_descent(px)
	_drawn_width = _sum_width + _up_width + _extra_width(px)
	_on_built()
	update_minimum_size()
	queue_redraw()


func _advance(text: String, px: int) -> float:
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x


## Draws one word with its left edge at x and its baseline at baseline.
func _word(index: int, x: float, baseline: float, color: Color) -> void:
	draw_string(_font, Vector2(x, baseline), PARTS[index], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _px, color)


# Hooks for the skins. The defaults draw the plain flat wordmark.

## Reads the skin's colors and numbers, once per setup.
func _on_setup() -> void:
	pass


## Called once the size's metrics are worked out.
func _on_built() -> void:
	pass


## Width the skin adds after the two advances (Nova's star).
func _extra_width(_at_px: int) -> float:
	return 0.0


## Height the skin adds under the text (Gumdrop's lip).
func _lip_depth(_at_px: int) -> int:
	return 0


## Height of the masthead rule and its gap, 0 when not drawn.
func _masthead_height() -> float:
	return 0.0


func _centered() -> bool:
	return true


func _draw_mark(left: float, baseline: float) -> void:
	_word(0, left, baseline, _skin.color(&"ink"))
	_word(1, left + _sum_width, baseline, _skin.color(&"accent"))
