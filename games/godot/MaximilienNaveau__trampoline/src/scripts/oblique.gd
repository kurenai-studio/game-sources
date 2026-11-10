# Shared drawing helpers for the game's "2.5D" look (see
# doc/ART_DIRECTION.md): every object — the box, the board, the tiles —
# is seen from above and a little to the front-right, in an oblique view.
# Top faces stay flat, undistorted rectangles (so text and the grid read
# normally); anything standing up off the table is shifted up-left by its
# height, and its front and right sides show as slanted strips below and
# to the right of its top face.
#
# Pure drawing math, no state: `static func`s (like C++ static member
# functions) called on the class itself, e.g. `Oblique.draw_sides(...)`.
class_name Oblique
extends RefCounted

# Where a point lifted 1 px off the table moves on screen: up, and a
# little left. Everything in the game uses this one direction, so they
# all look seen from the same viewpoint.
const UP := Vector2(-0.22, -0.44)


# Draws onto `canvas` the front and right sides of a block whose top face
# is `top` and whose bottom edge sits `depth` further down-right (for a
# block `h` px tall, `depth` is `-UP * h`). Each side is a parallelogram,
# filled with `front`/`right` — plain colors, or tints of `texture` when
# one is given (a thin band through its middle, stretched along the side).
static func draw_sides(
	canvas: CanvasItem,
	top: Rect2,
	depth: Vector2,
	front: Color,
	right: Color,
	texture: Texture2D = null
) -> void:
	var top_right := Vector2(top.end.x, top.position.y)
	var bottom_right := top.end
	var bottom_left := Vector2(top.position.x, top.end.y)
	# Front side: hanging under the top face's bottom edge.
	fill(
		canvas,
		[bottom_left, bottom_right, bottom_right + depth, bottom_left + depth],
		front,
		texture
	)
	# Right side: along the top face's right edge.
	fill(canvas, [top_right, top_right + depth, bottom_right + depth, bottom_right], right, texture)


# Fills the 4-corner polygon `corners` with `color`, or with `texture`
# tinted by `color` when one is given.
static func fill(
	canvas: CanvasItem, corners: Array, color: Color, texture: Texture2D = null
) -> void:
	if texture == null:
		canvas.draw_colored_polygon(PackedVector2Array(corners), color)
		return
	# `uvs` say which part of the texture lands on each corner, in 0..1
	# texture coordinates: here a thin band through the middle, so the
	# texture's brush strokes run along the side.
	var uvs := PackedVector2Array(
		[Vector2(0.1, 0.48), Vector2(0.9, 0.48), Vector2(0.9, 0.52), Vector2(0.1, 0.52)]
	)
	canvas.draw_polygon(PackedVector2Array(corners), PackedColorArray([color]), uvs, texture)
