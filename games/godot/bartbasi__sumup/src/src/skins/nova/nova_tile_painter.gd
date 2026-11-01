extends "res://src/skins/common/tile_painter.gd"
## Nova tile painter (DESIGN_SYSTEM.md 6.7): round orbs with a lighter rim, a
## glow in their own color that grows wider and brighter with the value,
## corona rays on specials, and the chained, joinable, press and selected
## looks. The glow is drawn on its own (the board puts every glow under the
## beam and every orb), so no glow ever crosses another orb's number.
##
## The tile side here is the orb diameter, orb_scale of the cell pitch.

## Glow texture size in px. It is drawn scaled, and a soft gradient scales
## well.
const GLOW_TEXTURE_SIZE: int = 128
## The glow texture's falloff from its center (offset 0) to its edge
## (offset 1), white with these alphas, tinted per orb when drawn. Drawing
## scales the tint so the alpha right at the orb edge is the skin's glow
## alpha; this only shapes how it fades out from there.
const GLOW_OFFSETS: PackedFloat32Array = [0.0, 0.6, 0.75, 0.88, 1.0]
const GLOW_ALPHAS: PackedFloat32Array = [1.0, 0.75, 0.45, 0.18, 0.0]
## Lowest texture alpha the tint divides by, so it never divides by zero.
const GLOW_FLOOR: float = 0.01
## Points per full circle for orbits.
const CIRCLE_POINTS: int = 72

static var _glow_texture: GradientTexture2D = null

var _rim_colors: PackedColorArray = PackedColorArray()
var _ray_colors: PackedColorArray = PackedColorArray()
## Per label index: the color of the chained rim and of the clear sparks.
var _chain_rims: PackedColorArray = PackedColorArray()
var _spark_colors: PackedColorArray = PackedColorArray()
var _glow_spreads: PackedFloat32Array = PackedFloat32Array()
var _glow_alphas: PackedFloat32Array = PackedFloat32Array()
var _ray_directions: PackedVector2Array = PackedVector2Array()
var _spark_directions: PackedVector2Array = PackedVector2Array()
var _joinable_points: PackedVector2Array = PackedVector2Array()
var _dash_points: Array[PackedVector2Array] = []
## Full strength orbit colors, made once; a fading orbit fills _one_color.
var _joinable_array: PackedColorArray = PackedColorArray()
var _target_array: PackedColorArray = PackedColorArray()
var _one_color: PackedColorArray = PackedColorArray([Color.WHITE])

var _rim_width: float = 0.0
var _chain_ring: float = 0.0
var _joinable_ring: float = 0.0
var _target_ring: float = 0.0
var _joinable_orbit: float = 0.0
var _orbit_offset: float = 0.0
var _orbit_breath: float = 0.0
var _orbit_dashes: int = 1
var _orbit_dash_fill: float = 0.0
var _ray_inner: float = 0.0
var _ray_outer: float = 0.0
var _ray_width: float = 0.0
var _spark_size: float = 0.0
var _spark_reach: float = 0.0
var _chain_glow: float = 1.0
var _joinable_glow: float = 1.0
var _target_glow: float = 1.0
var _chain_color: Color = Color.MAGENTA
var _joinable_color: Color = Color.MAGENTA
var _target_color: Color = Color.MAGENTA


func _setup() -> void:
	_rim_width = skin.num(&"rim_width")
	_chain_ring = skin.num(&"chain_ring")
	_joinable_ring = skin.num(&"joinable_ring")
	_target_ring = skin.num(&"target_ring")
	_joinable_orbit = skin.num(&"joinable_orbit")
	_orbit_offset = skin.num(&"orbit_offset")
	_orbit_breath = skin.num(&"orbit_breath")
	_orbit_dashes = maxi(1, roundi(skin.num(&"orbit_dashes")))
	_orbit_dash_fill = skin.num(&"orbit_dash_fill")
	_ray_inner = skin.num(&"ray_inner")
	_ray_outer = skin.num(&"ray_outer")
	_ray_width = skin.num(&"ray_width")
	_spark_size = MotionMath.extra(skin, &"clear", "spark_size")
	_spark_reach = MotionMath.extra(skin, &"clear", "spark_reach")
	_chain_glow = skin.num(&"chain_glow")
	_joinable_glow = skin.num(&"joinable_glow")
	_target_glow = skin.num(&"target_glow")
	_chain_color = skin.color(&"chain")
	_joinable_color = skin.color(&"joinable")
	_target_color = skin.color(&"target")
	_joinable_array = PackedColorArray([_joinable_color])
	_target_array = PackedColorArray([_target_color])
	var rim_lighten: float = skin.num(&"rim_lighten")
	var ray_lighten: float = skin.num(&"ray_lighten")
	var ray_alpha: float = skin.num(&"ray_alpha")
	var spread_low: float = skin.num(&"glow_spread_low")
	var spread_high: float = skin.num(&"glow_spread_high")
	var alpha_low: float = skin.num(&"glow_alpha_low")
	var alpha_high: float = skin.num(&"glow_alpha_high")
	var count: int = fills.size()
	# On every orb with the colors of dark_rim_from (the white hole) the
	# chained rim is ink_dark: a white rim on a white orb vanishes. It goes by
	# the color position, since the color cycle puts other colors above it.
	var dark_rim_exponent: int = skin.token_exponent(&"dark_rim_from")
	var dark_rim_position: int = skin.color_position(dark_rim_exponent) if dark_rim_exponent > 0 else -1
	var dark_rim: Color = skin.color(&"ink_dark")
	_rim_colors.resize(count)
	_ray_colors.resize(count)
	_chain_rims.resize(count)
	_spark_colors.resize(count)
	_glow_spreads.resize(count)
	_glow_alphas.resize(count)
	for index: int in count:
		_rim_colors[index] = fills[index].lightened(rim_lighten)
		var ray: Color = fills[index].lightened(ray_lighten)
		# Sparks take the rays' lightened fill, so they show on deep space.
		_spark_colors[index] = ray
		ray.a *= ray_alpha
		_ray_colors[index] = ray
		_chain_rims[index] = dark_rim if dark_rim_position >= 0 and positions[index] == dark_rim_position else _chain_color
		# Both run by k from 1 to 17 (styles 0 to 16); every style above the
		# ramp stays at the top.
		var t: float = clampf(float(index) / float(SkinData.RAMP_SIZE - 1), 0.0, 1.0)
		_glow_spreads[index] = lerpf(spread_low, spread_high, t)
		_glow_alphas[index] = lerpf(alpha_low, alpha_high, t)
	_ray_directions = _directions(roundi(skin.num(&"ray_count")))
	_spark_directions = _directions(roundi(MotionMath.extra(skin, &"clear", "sparks")))
	_build_glow_texture()


func _on_side() -> void:
	var radius: float = side * 0.5
	_joinable_points = arc_points(radius * (1.0 + _joinable_orbit), 0.0, TAU, CIRCLE_POINTS)
	_dash_points.clear()
	var step: float = TAU / float(_orbit_dashes)
	@warning_ignore("integer_division")
	var points: int = maxi(3, CIRCLE_POINTS / _orbit_dashes + 2)
	for i: int in _orbit_dashes:
		var start: float = step * float(i)
		_dash_points.append(arc_points(radius * (1.0 + _orbit_offset), start, start + step * _orbit_dash_fill, points))


## Nova has no gaps of its own: the cell pitch is the board width over the
## columns, the orb is orb_scale of it, and half the leftover gap sits round
## the outer orbs (DESIGN_SYSTEM.md 2.3).
func board_metrics(width: float, columns: int) -> Vector3:
	var pitch: float = width / float(maxi(columns, 1))
	var orb: float = pitch * skin.num(&"orb_scale")
	var gap: float = pitch - orb
	return Vector3(orb, gap, gap * 0.5)


## The glow multiplier of an orb's looks: chained, joinable and targeted
## orbs glow more (chain_glow, joinable_glow, target_glow).
func glow_of(chain: float, join: float, target: float) -> float:
	return 1.0 + (_chain_glow - 1.0) * chain + (_joinable_glow - 1.0) * join + (_target_glow - 1.0) * target


## The glow behind an orb in tile space. glow multiplies it: how bright it
## is at the orb edge and how far it spreads.
func draw_glow(canvas: RID, base: Transform2D, exponent: int, glow: float) -> void:
	var index: int = style_of(exponent)
	var radius: float = side * 0.5
	if index < 0 or glow <= 0.0 or radius <= 0.0:
		return
	var reach: float = radius * (1.0 + (_glow_spreads[index] - 1.0) * glow)
	if reach <= radius:
		return
	var texture_alpha: float = _glow_texture.gradient.sample(radius / reach).a
	var tint: Color = fills[index]
	tint.a = clampf(_glow_alphas[index] * glow / maxf(texture_alpha, GLOW_FLOOR), 0.0, 1.0)
	begin(canvas, base)
	RenderingServer.canvas_item_add_texture_rect(canvas, Rect2(-Vector2(reach, reach), Vector2(reach, reach) * 2.0), _glow_texture.get_rid(), false, tint)
	end(canvas)


## The orb in tile space: flat fill, corona rays on specials, the rim
## (widening to the chain rim in chain as chain goes to 1), the number, and
## the joinable orbit as join goes to 1.
func draw_orb(canvas: RID, base: Transform2D, exponent: int, chain: float, join: float) -> void:
	var index: int = style_of(exponent)
	if index < 0:
		return
	begin(canvas, base)
	var radius: float = side * 0.5
	if is_special(exponent):
		var inner: float = radius * _ray_inner
		var outer: float = radius * _ray_outer
		for direction: Vector2 in _ray_directions:
			RenderingServer.canvas_item_add_line(canvas, direction * inner, direction * outer, _ray_colors[index], _ray_width * unit, true)
	# The rim is the fill circle in the rim color with the fill laid inside it.
	var rim_width: float = lerpf(_rim_width, _chain_ring, chain) * unit
	var rim: Color = _rim_colors[index].lerp(_chain_rims[index], chain)
	RenderingServer.canvas_item_add_circle(canvas, Vector2.ZERO, radius, rim, true)
	RenderingServer.canvas_item_add_circle(canvas, Vector2.ZERO, maxf(0.0, radius - rim_width), fills[index], true)
	if label_shown:
		labels.draw_centered(canvas, Vector2.ZERO, exponent, inks[index])
	if join > 0.0:
		RenderingServer.canvas_item_add_polyline(canvas, _joinable_points, _colors(_joinable_array, _joinable_color, join), _joinable_ring * unit, true)
	end(canvas)


## The dashed target orbit round an orb centered on center. turn is in whole
## turns, breath from 0 to 1 widens it by orbit_breath.
func draw_dashed_orbit(canvas: RID, center: Vector2, turn: float, breath: float, alpha: float) -> void:
	var grow: float = 1.0 + _orbit_breath * breath
	begin(canvas, Transform2D(TAU * turn, Vector2(grow, grow), 0.0, center))
	var colors: PackedColorArray = _colors(_target_array, _target_color, alpha)
	var width: float = _target_ring * unit / grow
	for dash: PackedVector2Array in _dash_points:
		RenderingServer.canvas_item_add_polyline(canvas, dash, colors, width, true)
	end(canvas)


## The sparks of a clearing orb centered on center at a progress from 0 to 1,
## in its fill lightened by ray_lighten: they drift from the orb edge out to
## spark_reach of the diameter and fade.
func draw_sparks(canvas: RID, center: Vector2, exponent: int, progress: float) -> void:
	var index: int = style_of(exponent)
	if index < 0 or progress <= 0.0 or progress >= 1.0:
		return
	var distance: float = lerpf(side * 0.5, side * _spark_reach, progress)
	var color: Color = faded(_spark_colors[index], 1.0 - progress)
	var spark_radius: float = _spark_size * unit * 0.5
	for direction: Vector2 in _spark_directions:
		RenderingServer.canvas_item_add_circle(canvas, center + direction * distance, spark_radius, color, true)


func draw_single(canvas: RID, center: Vector2, exponent: int) -> void:
	draw_glow(canvas, at(center), exponent, 1.0)
	draw_orb(canvas, at(center), exponent, 0.0, 0.0)


## The full strength array when alpha is 1, so a steady orbit never writes
## to an array; a fading one fills the scratch array.
func _colors(full: PackedColorArray, color: Color, alpha: float) -> PackedColorArray:
	if alpha >= 1.0:
		return full
	_one_color[0] = faded(color, alpha)
	return _one_color


static func _directions(count: int) -> PackedVector2Array:
	var directions: PackedVector2Array = PackedVector2Array()
	for i: int in maxi(count, 0):
		var angle: float = TAU * (float(i) + 0.5) / float(count)
		directions.append(Vector2(cos(angle), sin(angle)))
	return directions


static func _build_glow_texture() -> void:
	if _glow_texture != null:
		return
	var gradient: Gradient = Gradient.new()
	gradient.offsets = GLOW_OFFSETS
	var colors: PackedColorArray = PackedColorArray()
	for alpha: float in GLOW_ALPHAS:
		colors.append(Color(1.0, 1.0, 1.0, alpha))
	gradient.colors = colors
	_glow_texture = GradientTexture2D.new()
	_glow_texture.gradient = gradient
	_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_glow_texture.fill_from = Vector2(0.5, 0.5)
	_glow_texture.fill_to = Vector2(1.0, 0.5)
	_glow_texture.width = GLOW_TEXTURE_SIZE
	_glow_texture.height = GLOW_TEXTURE_SIZE
