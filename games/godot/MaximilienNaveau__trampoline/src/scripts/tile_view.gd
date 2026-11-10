# How a `Tile` gets drawn, shared by every view that shows one (BoardView,
# HandView, ...) — the yellow/green color mapping, a helper to turn a
# color into a drawable style, and the "2.5D" board holes the tiles sit
# in (see oblique.gd), so each view doesn't redefine its own copy.
# Deliberately only about *drawing*, never touching board/scoring/turn
# logic, per this project's "separate logic from graphics" rule — this
# file is graphics code, but it's graphics code that knows about `Tile`,
# not the other way around.
class_name TileView
extends RefCounted

# Face colors and letter ink taken from the physical tiles (see
# doc/ART_DIRECTION.md's palette, from photos of the original): a pale
# butter-lime yellow, a muted sage green, and slate-charcoal letters.
const YELLOW_COLOR := Color("eae5a0")
const GREEN_COLOR := Color("9cb46b")
const LETTER_COLOR := Color("363a42")
# The cork base under a tile's printed face, seen on its sides once it's
# off the board (`tile_edge` in doc/ART_DIRECTION.md's palette); the right
# side, facing away from the light, a little darker.
const CORK_COLOR := Color("c9b98a")
const _CORK_SHADE := 0.25
# An empty hole cut into the board's painted wood: its walls and floor
# are that same paint (the plain painted middle of the box's lid texture,
# like the Tray around the holes in board_view.tscn), tinted by how much
# shadow each gets. The light comes from the back-left, so the far (top)
# and left walls face away from it and are darkest; the floor, facing up,
# is only partly shaded. That shading is what reads as a slot.
const _PAINT := preload("res://assets/textures/box_lid.jpg")
const _PAINT_REGION := Rect2(40, 40, 460, 880)
const _HOLE_TOP_WALL_TINT := Color(0.45, 0.45, 0.45)
const _HOLE_LEFT_WALL_TINT := Color(0.55, 0.55, 0.55)
const _HOLE_FLOOR_TINT := Color(0.72, 0.72, 0.72)

# How deep a hole is, as a fraction of the cell's side. A tile is as
# thick as its hole is deep, so once in it, its face is flush with the
# board and its cork sides are hidden — only the face shows.
const _HOLE_DEPTH_RATIO := 0.22
# Gap, in px, between a tile and its hole's walls on each side.
const _TILE_GAP := 1.0

# Jost SemiBold — a geometric sans close to the real tiles' lettering.
# `preload` loads a resource once, when this script itself is loaded
# (like a module-level constant in Python), rather than on every call.
# jost_semibold.tres is a FontVariation: Godot's way of picking one weight
# out of a variable font file that holds them all.
const LETTER_FONT := preload("res://assets/fonts/jost_semibold.tres")

# Sizes relative to the tile's side: the main letter, the corner square,
# and the corner square's letter. Tuned by rendering every letter A-Z at
# 32/40/48 px tiles and measuring the gap between the letter's ink and
# the corner square: with these values (and the shift below) even the
# widest letters (W, V, H, K) keep at least 3 px clear of it. A bigger
# main letter or square made W/V touch or overlap the square.
const _LETTER_SIZE_RATIO := 0.55
const _CORNER_SIZE_RATIO := 0.34
const _CORNER_LETTER_SIZE_RATIO := 0.30

# How far the main letter sits below and left of center, as fractions of
# the side — away from the top-right square. Moving it down buys the most
# clearance for the least shrinking (the real tiles' letters also sit a
# little low); the small left shift balances it in the space the square
# leaves free.
const _LETTER_DROP_RATIO := 0.09
const _LETTER_LEFT_RATIO := 0.05

# Godot centers a label's whole line box, which in Jost leaves more room
# below the capitals (for descenders) than above — so the corner letter
# rendered about 2 px low, with J's tail poking out under the square.
# Lifting it by this fraction of the side re-centers it (measured: equal
# gaps above and below a capital E).
const _CORNER_LETTER_LIFT_RATIO := 0.04

# Tile corners are only slightly rounded — the real tiles are cut squares.
const _CORNER_RADIUS := 3

# The red used to flag a cell that's part of why the current turn can't
# end yet (see GameSession.invalid_cells/invalid_words) — a thick border
# rather than replacing the fill color, so the letter underneath (and
# whether it's yellow or green) stays readable.
const INVALID_BORDER_COLOR := Color(0.85, 0.2, 0.2)


# The style to draw an occupied cell/tile with, based on which face it's
# currently showing.
static func style_for_tile(tile: Tile) -> StyleBoxFlat:
	var color := GREEN_COLOR if tile.current_is_green() else YELLOW_COLOR
	return _make_style(color)


# The style for the face of a tile sunk into a board hole: just the
# matte face color, flush with the board — its cork sides (see
# `add_cork`) are hidden in the hole.
# `invalid` adds a red border (see `INVALID_BORDER_COLOR`).
static func board_face_style(tile: Tile, invalid: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GREEN_COLOR if tile.current_is_green() else YELLOW_COLOR
	style.set_corner_radius_all(_CORNER_RADIUS)
	if invalid:
		style.border_color = INVALID_BORDER_COLOR
		style.set_border_width_all(4)
	return style


# Where a tile's face goes in a cell `side` px wide (a cell = one hole):
# the hole minus a small gap, flush with the board.
static func face_rect(side: float) -> Rect2:
	return Rect2(0, 0, side, side).grow(-_TILE_GAP)


# Draws onto `canvas` an empty hole sunk into the board, whose rim is
# `rim`. Its floor shows shifted down-right by the hole's depth, and the
# strips between floor and rim are its two inner walls we can see — the
# far (top) one and the left one. The near walls, and everything of the
# floor past the rim, are hidden under the board's surface.
static func draw_hole(canvas: CanvasItem, rim: Rect2) -> void:
	var depth := -Oblique.UP * rim.size.x * _HOLE_DEPTH_RATIO
	# The floor: the hole moved down-right by the depth, cut off by the rim.
	var floor_rect := Rect2(rim.position + depth, rim.size - depth)
	# Which piece of the paint to show there: the one at the floor's place
	# on screen (`get_global_transform()` maps this node's coordinates to
	# the screen's), so the floors of neighbouring holes line up like one
	# painted board. `fposmod` is a float modulo that's never negative,
	# wrapping around the paint if the board is bigger than it.
	var at := canvas.get_global_transform() * floor_rect.position
	var offset := Vector2(
		fposmod(at.x, _PAINT_REGION.size.x - floor_rect.size.x),
		fposmod(at.y, _PAINT_REGION.size.y - floor_rect.size.y)
	)
	var source := Rect2(_PAINT_REGION.position + offset, floor_rect.size)
	canvas.draw_texture_rect_region(_PAINT, floor_rect, source, _HOLE_FLOOR_TINT)
	# The top wall: from the rim's top edge down to the floor's, its left
	# end slanting with the depth, its right end cut off by the rim.
	var top_right := Vector2(rim.end.x, rim.position.y)
	var top_wall := [rim.position, top_right, top_right + Vector2(0, depth.y), rim.position + depth]
	Oblique.fill(canvas, top_wall, _HOLE_TOP_WALL_TINT, _PAINT)
	# The left wall: from the rim's left edge across to the floor's.
	var bottom_left := Vector2(rim.position.x, rim.end.y)
	var left_wall := [
		rim.position + depth, Vector2(floor_rect.position.x, rim.end.y), bottom_left, rim.position
	]
	Oblique.fill(canvas, left_wall, _HOLE_LEFT_WALL_TINT, _PAINT)


# The letter a tile would show if flipped right now — whichever face ISN'T
# currently showing. Lets a player see what's "behind" a tile before
# committing to flip it (see doc/RULES.md's "trampoline" mechanic). A
# blank back face (the "shorten" mechanic) has no letter: it's shown as a
# plain dark square instead (see `other_face_color`), as on the physical
# tile.
static func other_face_letter(tile: Tile) -> String:
	if tile.is_showing_front():
		return tile.back_letter()
	return tile.front_letter()


# The color other_face_letter() above would be shown in — the front face
# is always yellow (see tile.gd); the back is green unless it's one of the
# two special all-yellow tiles, or ink-dark when it's blank.
static func other_face_color(tile: Tile) -> Color:
	if tile.is_showing_front():
		if tile.back_letter() == "":
			return LETTER_COLOR
		return GREEN_COLOR if tile.back_is_green() else YELLOW_COLOR
	return YELLOW_COLOR


# Creates the big centered letter every tile view shows (BoardCell,
# TilePanel, drag previews), in the tiles' own font and ink color, so the
# three places that draw a tile can't drift apart. Its size is set
# separately by `fit_to_side` below, once the tile's size is known.
static func build_letter_label() -> Label:
	var label := Label.new()
	# PRESET_FULL_RECT stretches the label to fill its parent panel
	# entirely, rather than sizing itself to just the text.
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", LETTER_FONT)
	label.add_theme_color_override("font_color", LETTER_COLOR)
	return label


# Scales a tile's letter and corner square to a tile `side` pixels wide —
# called whenever tiles change size (see BoardView._update_cell_sizes,
# HandView.refresh), so the proportions match the real tile at any size.
static func fit_to_side(letter: Label, badge: Panel, side: float) -> void:
	letter.add_theme_font_size_override("font_size", int(side * _LETTER_SIZE_RATIO))
	# The label fills the tile (see `build_letter_label`); its `offset_*`
	# values are pixel distances from those anchored edges, so adding the
	# same amount to both top and bottom slides it down without resizing
	# it (and the same for left/right, sliding it left).
	var drop := roundf(side * _LETTER_DROP_RATIO)
	letter.offset_top = drop
	letter.offset_bottom = drop
	var left := roundf(side * _LETTER_LEFT_RATIO)
	letter.offset_left = -left
	letter.offset_right = -left
	var corner_side := roundf(side * _CORNER_SIZE_RATIO)
	badge.custom_minimum_size = Vector2(corner_side, corner_side)
	var badge_label: Label = badge.get_node("Label")
	badge_label.add_theme_font_size_override("font_size", int(side * _CORNER_LETTER_SIZE_RATIO))
	var lift := roundf(side * _CORNER_LETTER_LIFT_RATIO)
	badge_label.offset_top = -lift
	badge_label.offset_bottom = -lift


# Creates the small top-right badge every tile view (BoardCell, TilePanel,
# and this file's own drag-preview builder below) uses to show
# other_face_letter/other_face_color — matching the physical tiles, which
# print this hint on its own small colored patch rather than as plain
# colored text (which would be unreadable whenever it happened to match
# the tile's own CURRENT color, e.g. a tile whose two faces are both
# yellow). Starts empty/invisible; call update_corner_badge() once there's
# an actual tile to describe.
static func build_corner_badge() -> Panel:
	var badge := Panel.new()
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# A control anchored to a corner still needs to know which way to grow
	# from that zero-size point to fit its actual size — left/down here, so
	# the badge stays inside ITS OWN tile instead of spilling into the next
	# one. Setting this explicitly rather than trusting the preset's own
	# default avoids exactly that overflow.
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.grow_vertical = Control.GROW_DIRECTION_END
	# `custom_minimum_size` (a genuine, persistent size *request*), not a
	# one-time `size` assignment — a plain Panel has no content of its own
	# to otherwise justify a non-zero size, so an anchored-but-content-less
	# Panel like this one would just get resolved back down to 0x0 the next
	# time anything re-runs layout on it (unlike a Label, whose own text
	# already gives it a real size to grow from).
	# (Its real size is set by `fit_to_side` above; this is just a
	# placeholder until then.)
	badge.custom_minimum_size = Vector2(14, 14)
	# Lets clicks/drags through to the tile underneath — the badge is part
	# of the tile's picture, not something to interact with on its own.
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false

	var label := build_letter_label()
	# A node's `name` lets a later lookup find it again via get_node() (see
	# update_corner_badge below) — like a dictionary key, except it's how
	# Godot's scene tree itself is addressed.
	label.name = "Label"
	badge.add_child(label)

	return badge


# Refreshes a badge built by build_corner_badge() above to match `tile`'s
# current state — needed after a flip, since which face counts as "the
# other one" swaps too. Drawn as a flat square flush in the tile's
# top-right corner, like the patch printed on the physical tile: no
# border or shadow of its own, and only its top-right corner rounded, to
# follow the tile's own rounded corner.
static func update_corner_badge(badge: Panel, tile: Tile) -> void:
	badge.visible = true
	var style := StyleBoxFlat.new()
	style.bg_color = other_face_color(tile)
	style.corner_radius_top_right = _CORNER_RADIUS
	badge.add_theme_stylebox_override("panel", style)
	var label: Label = badge.get_node("Label")
	label.text = other_face_letter(tile)


# Hides a badge built by build_corner_badge() above — used wherever a cell
# has no tile at all (nothing to hint at).
static func hide_corner_badge(badge: Panel) -> void:
	badge.visible = false


# Builds a floating preview of `tile` for Control.set_drag_preview(),
# shared by every draggable tile view (TilePanel, BoardCell) — already
# centered on the cursor. Godot forcibly re-centers whatever ROOT control
# it's given on the mouse position every frame, overwriting any position we
# set on it ourselves, but it never touches a CHILD's position — so this
# returns an otherwise-empty root Control with the actual visible tile as
# an offset child, which is what keeps the tile looking centered no matter
# where Godot moves the root.
static func build_drag_preview(tile: Tile, tile_size: Vector2) -> Control:
	var root := Control.new()
	var side := _lifted(tile_size)
	var visual := build_tile_visual(tile, side)
	visual.position = -side / 2
	root.add_child(visual)
	_cast_shadow(visual)
	return root


# Same idea, but for several tiles dragged together (see BoardCell's block
# drag): each of `tiles` drawn `offsets[i]` cells (columns, rows) away from
# the one under the cursor, as they sit on the board.
static func build_block_drag_preview(
	tiles: Array[Tile], offsets: Array[Vector2i], tile_size: Vector2
) -> Control:
	var root := Control.new()
	var side := _lifted(tile_size)
	for i in range(tiles.size()):
		var visual := build_tile_visual(tiles[i], side)
		# `Vector2(offsets[i])` turns the whole-number cell offset into a
		# float one, to scale by the tile's size in pixels.
		visual.position = Vector2(offsets[i]) * side - side / 2
		root.add_child(visual)
		_cast_shadow(visual)
	return root


# A picked-up tile looks a little bigger (see doc/ART_DIRECTION.md's
# "Motion"): the size of a dragged tile `tile_size` big, in whole pixels.
# Drawn at that size rather than scaled up afterwards (or tilted), so its
# letters stay sharp: scaling or rotating a drawn tile smooths, so blurs,
# its text.
static func _lifted(tile_size: Vector2) -> Vector2:
	return (tile_size * 1.08).round()


# A dragged tile's soft shadow, as if held above the table: a copy of the
# tile's style (see `style_for_tile`), so only this preview gets it.
static func _cast_shadow(visual: Control) -> void:
	var style: StyleBoxFlat = visual.get_theme_stylebox("panel").duplicate()
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2(2, 6)
	visual.add_theme_stylebox_override("panel", style)


# The actual colored, lettered rectangle both preview builders above
# position (and the "Comment jouer" cards, see how_to_play_view.gd) —
# meant for a parent that isn't a container, so nothing runs a layout pass
# on it: setting only `custom_minimum_size` (a mere size *request* for a
# parent container to honor) would leave its actual `size` at (0, 0).
# Setting `size` directly gives it real, immediate dimensions to render
# and to position against.
static func build_tile_visual(tile: Tile, tile_size: Vector2) -> Control:
	var visual := Panel.new()
	visual.size = tile_size
	visual.add_theme_stylebox_override("panel", style_for_tile(tile))
	var label := build_letter_label()
	label.text = tile.current_letter()
	visual.add_child(label)
	var corner := build_corner_badge()
	update_corner_badge(corner, tile)
	visual.add_child(corner)
	fit_to_side(label, corner, tile_size.x)
	add_cork(visual, tile_size.x)
	return visual


# Gives `tile` (a tile's face, `side` px wide) the cork base a tile off
# the board shows: a little block, as thick as a board hole is deep (see
# `_HOLE_DEPTH_RATIO`), seen in the game's oblique view (see oblique.gd).
# It's a child named "Cork" drawn BEHIND its parent (`show_behind_parent`):
# a stack of the face's own rounded shape, shifted step by step down and
# to the right, from the far edge (darker) up to the face — so the block
# keeps the face's round corners.
static func add_cork(tile: Control, side: float) -> void:
	var cork := Control.new()
	cork.name = "Cork"
	cork.show_behind_parent = true
	cork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(cork)
	var depth := -Oblique.UP * side * _HOLE_DEPTH_RATIO
	# One shape per pixel of depth, so the edge stays smooth; their styles
	# made once, here, not on every redraw.
	var steps := ceili(depth.length())
	var styles: Array[StyleBoxFlat] = []
	for i in range(steps + 1):
		styles.append(_make_style(CORK_COLOR.darkened(_CORK_SHADE * i / steps)))
	cork.draw.connect(
		func() -> void:
			for i in range(steps, 0, -1):
				cork.draw_style_box(styles[i], Rect2(depth * i / steps, Vector2.ONE * side))
	)


# A StyleBoxFlat is Godot's simplest drawable: a solid-colored (optionally
# rounded/bordered) rectangle. Deliberately kept flat rather than
# embossed/beveled — a stronger "3D" look (tried and rejected earlier)
# reads fine on one isolated tile but turns into a busy, repetitive
# waffle pattern once tiled edge-to-edge 117 times across the board. The
# real tiles are flat printed card on a thin cork base, so: a matte face
# — the base's sides are drawn apart, see `add_cork`.
static func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(_CORNER_RADIUS)
	return style
