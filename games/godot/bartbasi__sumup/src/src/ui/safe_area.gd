class_name SafeArea extends RefCounted
## The device safe area in a viewport's own coordinates (DESIGN_SYSTEM.md
## 2.2): the part of the screen clear of the notch, punch hole, rounded
## corners and the gesture or button bar. No text and no touch target sits
## outside it; backgrounds, the board tray, the scrim and sheets reach the
## screen edges. Also the content column inside it (2.8).

## Review scenes and tests set this to simulate a phone: x is the top inset
## and y the bottom inset, in viewport px. Negative (the default) reads the
## real display.
static var simulated_insets: Vector2 = Vector2(-1.0, -1.0)

## The board widths the content column samples (any two distinct widths do:
## a board's preferred height is linear in its width).
const _SAMPLE_NARROW: float = 1000.0
const _SAMPLE_WIDE: float = 2000.0
## The play screen board's grid (GameConfig's defaults, GDD section 18).
const _BOARD_COLUMNS: int = 5
const _BOARD_ROWS: int = 8

## By skin resource: Vector2(slope, offset) of the board's preferred height
## as a function of its width, so the board view is built only once per skin.
static var _height_lines: Dictionary[int, Vector2] = {}


## QA6-08, DESIGN_SYSTEM.md 2.8. The content column inside the safe area,
## centered: as wide as the smaller of the safe width and B plus board_margin
## on each side, where B is the widest board whose preferred height fits
## between the HUD (hud_height, never the offer) and the booster bar, space_s
## from each (2.3). On phones the board is limited by width, so the column is
## the whole safe width. It follows the viewport, so a live resize (fold and
## unfold) gives the new column at the next layout.
static func content_column(viewport: Viewport, skin: SkinData) -> Rect2:
	return column_in(viewport_safe_rect(viewport), skin)


## The content column for a given safe rect (content_column without a
## viewport, for layouts worked out by hand and for tests).
static func column_in(safe: Rect2, skin: SkinData) -> Rect2:
	if skin == null or safe.size.x <= 0.0:
		return safe
	var margin: float = skin.num(&"board_margin")
	var space: float = safe.size.y - skin.num(&"hud_height") - skin.num(&"bar_height") - 2.0 * skin.num(&"space_s")
	var board_width: float = board_width_for_height(skin, space)
	if board_width <= 0.0:
		return safe
	var width: float = minf(safe.size.x, board_width + 2.0 * margin)
	return Rect2(safe.position.x + (safe.size.x - width) * 0.5, safe.position.y, width, safe.size.y)


## The width at which the skin's play screen board is height tall, or 0 when
## there is none (height 0 or less, or a board that does not grow).
static func board_width_for_height(skin: SkinData, height: float) -> float:
	if skin == null or height <= 0.0:
		return 0.0
	var line: Vector2 = _height_line(skin)
	if line.x <= 0.0:
		return 0.0
	return maxf(0.0, (height - line.y) / line.x)


static func _height_line(skin: SkinData) -> Vector2:
	var key: int = skin.get_instance_id()
	if _height_lines.has(key):
		return _height_lines[key]
	var view: SkinBoardView = SkinCatalog.make_board_view(skin)
	view.setup(skin, _BOARD_COLUMNS, _BOARD_ROWS)
	var narrow: float = view.preferred_height(_SAMPLE_NARROW)
	var wide: float = view.preferred_height(_SAMPLE_WIDE)
	view.free()
	var slope: float = (wide - narrow) / (_SAMPLE_WIDE - _SAMPLE_NARROW)
	var line: Vector2 = Vector2(slope, narrow - slope * _SAMPLE_NARROW)
	_height_lines[key] = line
	return line


## The display safe area mapped into viewport coordinates, inside the
## viewport's visible rect. The whole visible rect when there is no display
## to ask (headless, or a SubViewport) or the answer makes no sense.
static func viewport_safe_rect(viewport: Viewport) -> Rect2:
	if viewport == null:
		return Rect2()
	var visible: Rect2 = viewport.get_visible_rect()
	if simulated_insets.x >= 0.0 and simulated_insets.y >= 0.0:
		var height: float = maxf(0.0, visible.size.y - simulated_insets.x - simulated_insets.y)
		return Rect2(visible.position.x, visible.position.y + simulated_insets.x, visible.size.x, height)
	if not (viewport is Window) or DisplayServer.get_name() == "headless":
		return visible
	var window: Window = viewport as Window
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return visible
	# The safe area is in screen pixels: move it into the window, then undo
	# the stretch transform to reach viewport coordinates.
	var window_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(window.size))
	var in_window: Rect2 = Rect2(Vector2(safe.position - window.position), Vector2(safe.size)).intersection(window_rect)
	if in_window.size.x <= 0.0 or in_window.size.y <= 0.0:
		return visible
	var mapped: Rect2 = viewport.get_final_transform().affine_inverse() * in_window
	mapped = mapped.intersection(visible)
	if mapped.size.x <= 0.0 or mapped.size.y <= 0.0:
		return visible
	return mapped
