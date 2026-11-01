extends RefCounted
## Base for the per skin tile painters. A painter draws tiles of one skin at
## one tile side into a canvas item; the board view and the tile view both
## draw through it, so a tile looks the same alone and on the board.
##
## Tiles are drawn in tile space: (0, 0) is the tile center, and base places
## that space in the canvas item. On the board every tile has its own canvas
## item and base is the identity: the item's own transform moves, scales and
## turns the tile, so effects never redraw it.
##
## It also owns the skin's board geometry rule (DESIGN_SYSTEM.md 2.3), since
## the tile side the px tokens were drawn for comes from it.
##
## Lengths the skin gives as a share of the tile side scale with the side.
## Lengths it gives in px are for the board tile on the base canvas; they are
## multiplied by unit, which is 1 on that tile and shrinks or grows with it.

const TileLabels: GDScript = preload("res://src/skins/common/tile_labels.gd")
const MotionMath: GDScript = preload("res://src/skins/common/motion_math.gd")

var skin: SkinData = null
var labels: TileLabels = null
## Tile side in px (Nova: the orb diameter), and px per token px.
var side: float = 0.0
var unit: float = 1.0

## Every tile is passed by its exponent k (the tile is 2^k, ARCHITECTURE.md
## 17). Its looks are held per style: style k - 1 for k from 1 to 17 (the
## ramp), then one style per entry of tile_cycle, shared by every k above 17
## that lands on it (style_of). So the arrays below stay small however high k
## goes. Per style: fill, number color, tier, and the ramp position the
## colors come from (DESIGN_SYSTEM.md 3.3). Colors follow the position, size
## follows the value through the tier (beyond_tier for every style above the
## ramp).
var fills: PackedColorArray = PackedColorArray()
var inks: PackedColorArray = PackedColorArray()
var tiers: PackedInt32Array = PackedInt32Array()
var positions: PackedInt32Array = PackedInt32Array()
## Exponent of special_from: a tile is special when k is at least this
## (DESIGN_SYSTEM.md 14.3).
var special_exponent: int = 0
## false draws tiles with no label: shape, fill, lip, rim and glow only
## (SkinTileView.set_label_shown). The board keeps it true.
var label_shown: bool = true

var _cycle_size: int = 1
var _reference_side: float = 0.0


func setup(p_skin: SkinData) -> void:
	skin = p_skin
	labels = TileLabels.new()
	labels.setup(skin)
	_cycle_size = maxi(1, skin.tile_cycle.size())
	var count: int = SkinData.RAMP_SIZE + _cycle_size
	fills.resize(count)
	inks.resize(count)
	tiers.resize(count)
	positions.resize(count)
	for style: int in count:
		var exponent: int = style + 1
		if style >= SkinData.RAMP_SIZE:
			exponent = SkinData.CYCLE_FIRST_POWER + style - SkinData.RAMP_SIZE
		fills[style] = skin.fill_for(exponent)
		inks[style] = skin.ink_for(exponent)
		tiers[style] = skin.tier_for(exponent)
		positions[style] = skin.color_position(exponent)
	special_exponent = skin.token_exponent(&"special_from")
	if special_exponent < 0:
		special_exponent = SkinData.max_exponent() + 1
	# The px tokens are drawn for the base canvas width and the game's column
	# count.
	var canvas_width: float = float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var reference_columns: int = GameConfig.new().columns
	_reference_side = board_metrics(canvas_width - 2.0 * skin.num(&"board_margin"), reference_columns).x
	side = 0.0
	_setup()


## Prepares everything that depends on the tile side. Returns at once when
## nothing changed, so callers may call it every draw.
func set_side(p_side: float, p_unit: float) -> void:
	if is_equal_approx(p_side, side) and is_equal_approx(p_unit, unit):
		return
	side = p_side
	unit = p_unit
	labels.set_side(side)
	_on_side()


## The board tile side the px tokens were drawn for: the board on the base
## canvas (DESIGN_SYSTEM.md 2.1), board_margin from each side.
func reference_side() -> float:
	return _reference_side


## Tile side, gap and padding (x, y, z) of a board of this width and column
## count with the skin's own gaps (DESIGN_SYSTEM.md 2.3). Gumdrop and Slate:
## board_gap between tiles and board_padding round them. Nova overrides it.
func board_metrics(width: float, columns: int) -> Vector3:
	var gap: float = skin.num(&"board_gap")
	var pad: float = skin.num(&"board_padding")
	var tile_side: float = (width - 2.0 * pad - float(columns - 1) * gap) / float(maxi(columns, 1))
	return Vector3(tile_side, gap, pad)


## Draws one resting tile 2^exponent centered on center, as the tile view
## shows it.
func draw_single(_canvas: RID, _center: Vector2, _exponent: int) -> void:
	push_error("tile painter does not implement draw_single()")


## Label index of a tile exponent: k - 1, or -1 when it is not a tile. The
## board keys its cells by it.
static func index_of(exponent: int) -> int:
	return exponent - 1 if SkinData.is_tile(exponent) else -1


## Style of a tile exponent (see fills): k - 1 up to 17, then the tile_cycle
## entry k lands on. -1 when it is not a tile.
func style_of(exponent: int) -> int:
	if not SkinData.is_tile(exponent):
		return -1
	if exponent <= SkinData.RAMP_SIZE:
		return exponent - 1
	return SkinData.RAMP_SIZE + (exponent - SkinData.CYCLE_FIRST_POWER) % _cycle_size


## True when the tile 2^exponent gets its skin's special look.
func is_special(exponent: int) -> bool:
	return exponent >= special_exponent


## Places tile space in a canvas item with base.
static func begin(canvas: RID, base: Transform2D) -> void:
	RenderingServer.canvas_item_add_set_transform(canvas, base)


static func end(canvas: RID) -> void:
	RenderingServer.canvas_item_add_set_transform(canvas, Transform2D.IDENTITY)


## Tile space centered on a point.
static func at(center: Vector2) -> Transform2D:
	return Transform2D(0.0, center)


static func faded(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)


func _setup() -> void:
	pass


func _on_side() -> void:
	pass


static func make_box(corner_detail: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.anti_aliasing = true
	box.corner_detail = corner_detail
	return box


static func make_ring(corner_detail: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = make_box(corner_detail)
	box.draw_center = false
	return box


## Points round an arc of a circle centered on (0, 0), from one angle to
## another, for a polyline. Made once per size.
static func arc_points(radius: float, from_angle: float, to_angle: float, count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(count + 1)
	for i: int in count + 1:
		var angle: float = lerpf(from_angle, to_angle, float(i) / float(count))
		points[i] = Vector2(cos(angle), sin(angle)) * radius
	return points
