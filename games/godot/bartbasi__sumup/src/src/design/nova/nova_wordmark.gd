extends SkinWordmark
## Nova wordmark (DESIGN_SYSTEM.md 7.2): light rising from "Up".
## Behind "Up", the shared glow texture tinted accent at alpha 0.25 at its
## center, drawn into Up's box (its advance by the cap height, on the
## baseline) grown by 0.30 x size on every side. The light may reach past the
## control's rect; it is a glow, not part of the drawn box.
## After "Up", the star icon's star, filled in accent, with no glow of its
## own: its box 0.18 x size, its left edge 0.03 x size after Up's advance, its
## center on the cap top line. The drawn width is the two advances plus
## 0.21 x size for the star.
## Text pairs: accent and ink on the glow over bg_glow (6.3).

const Glow: GDScript = preload("res://src/design/shared/glow.gd")
const StarShape: GDScript = preload("res://src/design/shared/star_shape.gd")
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
const NovaIcon: GDScript = preload("res://src/design/nova/nova_icon.gd")
const GRID: float = 24.0

## Fixed shares of the size (7.9).
const GLOW_ALPHA: float = 0.25
const GLOW_GROW: float = 0.30
const STAR_BOX: float = 0.18
const STAR_GAP: float = 0.03
const STAR_WIDTH: float = 0.21
## The star's center sits this share of the size above the baseline.
const CAP_TOP: float = FontMetrics.CAP_HEIGHT

## The star outline in grid units, worked out once.
static var _star_grid: PackedVector2Array = PackedVector2Array()

var _ink: Color = Color.WHITE
var _accent: Color = Color.WHITE
var _glow: Color = Color.TRANSPARENT
# Worked out once per size, relative to the wordmark's left edge and top.
var _glow_rect: Rect2 = Rect2()
var _star: PackedVector2Array = PackedVector2Array()


func _on_setup() -> void:
	_ink = _skin.color(&"ink")
	_accent = _skin.color(&"accent")
	_glow = Color(_accent, GLOW_ALPHA)
	if _star_grid.is_empty():
		var star_spec: Dictionary = NovaIcon.STAR
		_star_grid = StarShape.outline(star_spec)


func _extra_width(at_px: int) -> float:
	return STAR_WIDTH * float(at_px)


func _on_built() -> void:
	var px: float = float(_px)
	var cap: float = CAP_TOP * px
	_glow_rect = Rect2(_sum_width, _ascent - cap, _up_width, cap).grow(GLOW_GROW * px)
	var box: float = STAR_BOX * px
	var scale: float = box / GRID
	# The star's own center (not its box's) sits on the cap top line.
	var star_center: Vector2 = NovaIcon.STAR["center"]
	var box_origin: Vector2 = Vector2(_sum_width + _up_width + STAR_GAP * px, _ascent - cap - star_center.y * scale)
	_star = PackedVector2Array()
	for point: Vector2 in _star_grid:
		_star.append(box_origin + point * scale)


func _draw_mark(left: float, baseline: float) -> void:
	draw_set_transform(Vector2(left, 0.0))
	draw_texture_rect(Glow.texture(), _glow_rect, false, _glow)
	_word(0, 0.0, baseline, _ink)
	_word(1, _sum_width, baseline, _accent)
	draw_colored_polygon(_star, _accent)
	draw_set_transform(Vector2.ZERO)
