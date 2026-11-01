extends RefCounted
## Nova tile painter: round orbs with a lighter rim and a glow in their own
## color that grows wider and brighter with the value. The glow is one radial
## GradientTexture2D made once and drawn tinted per orb. Drawing is split
## into passes (glow, orb, orbit) so the board can put every glow and the
## beam under every orb, and no glow ever crosses another orb's number.
##
## The tile side here is the orb diameter. Every color, size and timing comes
## from the Nova tokens; lengths the tokens give in px are for the real board
## orb and scale with the diameter.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const TileFx: GDScript = preload("res://tools/directions/board_common/tile_fx.gd")
const TileText: GDScript = preload("res://tools/directions/board_common/tile_text.gd")

## Glow never reaches past this many orb radii: the brief lets effects draw
## outside the tile rect by up to 30 percent of the side.
const GLOW_LIMIT: float = 1.6
## Glow texture size in px. It is drawn scaled, and a soft gradient scales well.
const GLOW_TEXTURE_SIZE: int = 128
## Points per full circle for arcs.
const CIRCLE_POINTS: int = 72

var tokens: DirectionTokens = null
var text: TileText = null
## Orb diameter in px, and px per token px (1 on the real board orb).
var side: float = 0.0
var unit: float = 1.0

var _reference_side: float = 1.0
var _special_from: int = 0
var _glow_texture: GradientTexture2D = null
var _ray_directions: PackedVector2Array = PackedVector2Array()


## Board geometry at the composed width: x is the cell pitch, y the orb
## diameter, z the distance from the board rect edge to the outer cell edge.
static func reference_metrics(tile_tokens: DirectionTokens) -> Vector3:
	var width: float = MockState.CANVAS_SIZE.x - 2.0 * tile_tokens.num("board_margin")
	var pitch: float = width / MockState.COLUMNS
	return Vector3(pitch, pitch * tile_tokens.num("orb_scale"), 0.0)


func setup(tile_tokens: DirectionTokens) -> void:
	tokens = tile_tokens
	text = TileText.new()
	text.setup(tokens)
	_reference_side = reference_metrics(tokens).y
	_special_from = int(tokens.num("special_from"))
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 0.75, 0.88, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.45),
		Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0),
	])
	_glow_texture = GradientTexture2D.new()
	_glow_texture.gradient = gradient
	_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_glow_texture.fill_from = Vector2(0.5, 0.5)
	_glow_texture.fill_to = Vector2(1.0, 0.5)
	_glow_texture.width = GLOW_TEXTURE_SIZE
	_glow_texture.height = GLOW_TEXTURE_SIZE
	var ray_count: int = maxi(0, roundi(tokens.num("ray_count")))
	_ray_directions.resize(ray_count)
	for i: int in ray_count:
		var angle: float = TAU * (float(i) + 0.5) / float(ray_count)
		_ray_directions[i] = Vector2(cos(angle), sin(angle))
	side = 0.0


## Prepares everything that depends on the orb diameter. Returns at once when
## it has not changed, so callers can call it every draw.
func set_side(tile_side: float) -> void:
	if is_equal_approx(tile_side, side):
		return
	side = tile_side
	unit = side / _reference_side
	text.set_side(side)


## A whole orb in one go, for TileView: glow, orb, orbit.
func draw_tile(item: CanvasItem, center: Vector2, value: int, chain: float, target: bool, fx: TileFx) -> void:
	var glow: float = lerpf(1.0, tokens.num("chain_glow"), chain)
	if target:
		glow = tokens.num("target_glow")
	draw_glow(item, center, value, glow, fx)
	draw_orb(item, center, value, chain, fx)
	if target:
		draw_orbit(item, center + fx.offset, 0.0, 0.0)


## The glow behind an orb. amount multiplies the resting glow: its alpha, and
## how far it spreads past the orb edge.
func draw_glow(item: CanvasItem, center: Vector2, value: int, amount: float, fx: TileFx) -> void:
	if fx.hidden or TileText.index_of(value) < 0:
		return
	var glow: float = amount * fx.glow
	if glow <= 0.0:
		return
	var t: float = clampf(float(DirectionTokens.ramp_index(value)) / float(DirectionTokens.RAMP_SIZE - 1), 0.0, 1.0)
	var spread: float = lerpf(tokens.num("glow_spread_low"), tokens.num("glow_spread_high"), t)
	var edge_alpha: float = lerpf(tokens.num("glow_alpha_low"), tokens.num("glow_alpha_high"), t) * glow
	var radius: float = side * 0.5 * fx.scale.x
	var reach: float = radius * minf(1.0 + (spread - 1.0) * glow, GLOW_LIMIT)
	# Scale the texture so the glow's alpha right at the orb edge is the
	# token alpha, whatever the spread.
	var texture_alpha: float = _glow_texture.gradient.sample(radius / reach).a
	var tint: Color = tokens.fill_for(value)
	tint.a = clampf(edge_alpha / maxf(texture_alpha, 0.01), 0.0, 1.0) * fx.alpha
	var origin: Vector2 = center + fx.offset
	item.draw_texture_rect(_glow_texture, Rect2(origin - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, tint)


## The orb: flat fill, the rim (lit up to the chain rim as chain goes to 1),
## corona rays on specials, and the number.
func draw_orb(item: CanvasItem, center: Vector2, value: int, chain: float, fx: TileFx) -> void:
	var index: int = TileText.index_of(value)
	if fx.hidden or index < 0 or fx.scale.x <= 0.001:
		return
	item.draw_set_transform(center + fx.offset, fx.rotation, fx.scale)
	var radius: float = side * 0.5
	var fill: Color = tokens.fill_for(value)
	var rim_color: Color = fill.lightened(tokens.num("rim_lighten"))
	var ink: Color = tokens.ink_for(value)
	fill.a *= fx.alpha
	ink.a *= fx.alpha
	rim_color.a *= fx.alpha
	item.draw_circle(Vector2.ZERO, radius, fill, true, -1.0, true)
	if value >= _special_from:
		var ray_width: float = tokens.num("ray_width") * unit
		var ray_inner: float = radius * tokens.num("ray_inner")
		var ray_outer: float = radius * tokens.num("ray_outer")
		for direction: Vector2 in _ray_directions:
			item.draw_line(direction * ray_inner, direction * ray_outer, rim_color, ray_width, true)
	var chain_color: Color = tokens.color("chain")
	chain_color.a *= fx.alpha
	var rim_width: float = lerpf(tokens.num("rim_width"), tokens.num("chain_rim_width"), chain) * unit
	item.draw_arc(Vector2.ZERO, radius - rim_width * 0.5, 0.0, TAU, CIRCLE_POINTS, rim_color.lerp(chain_color, chain), rim_width, true)
	text.draw_centered(item, Vector2.ZERO, index, ink)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)


## The dashed target orbit round an orb. turn is in turns (1 is a full turn),
## breath from 0 to 1 widens the ring by orbit_breath.
func draw_orbit(item: CanvasItem, center: Vector2, turn: float, breath: float) -> void:
	var radius: float = side * 0.5 * (1.0 + tokens.num("orbit_offset")) * (1.0 + tokens.num("orbit_breath") * breath)
	var width: float = tokens.num("orbit_width") * unit
	var orbit_color: Color = tokens.color("target")
	var dashes: int = maxi(1, roundi(tokens.num("orbit_dashes")))
	var step: float = TAU / float(dashes)
	var dash: float = step * tokens.num("orbit_dash_fill")
	@warning_ignore("integer_division")
	var points: int = maxi(3, CIRCLE_POINTS / dashes + 2)
	for i: int in dashes:
		var start: float = TAU * turn + step * float(i)
		item.draw_arc(center, radius, start, start + dash, points, orbit_color, width, true)
