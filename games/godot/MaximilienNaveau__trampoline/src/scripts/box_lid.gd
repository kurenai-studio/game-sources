# The start screen: the physical game's closed box (see doc/ART_DIRECTION.md),
# lying on the felt desk mat. The box is the board's painted, mitred
# frame; the lid is a smaller painted panel set inside that frame, over
# the game, with Michel Cheenne's signature in its corner and the menu on
# a card lying on top. An orange ribbon is tied around the whole box.
#
# Everything is drawn in a "2.5D" oblique view, as if seen from above and
# a little to the front-right: the box's and the lid's top faces stay
# flat, undistorted rectangles (so the menu reads normally), and their
# front and right sides show as slanted strips below and to the right.
#
# Choosing a mode unties the ribbon, then opens the lid the way a hand
# would: it lifts on its right edge and turns over its left edge like a
# book page (but stays rigid), showing its bare-wood underside, and is
# carried off the screen. The empty box then fades onto the game, already
# set up underneath. Going back to the menu plays it all in reverse.
#
# Purely visual: knows nothing about game modes or sessions. main.gd
# decides WHEN to `open()`/`close()`, and still owns the menu's buttons
# (they're just children of the lid in main.tscn).
class_name BoxLid
extends Control

const _RIBBON_SECONDS := 0.2
const _TURN_SECONDS := 0.7
const _CARRY_SECONDS := 0.35
const _FADE_SECONDS := 0.3

# Gap between the screen edge and the box, showing the felt desk mat.
const _MARGIN := 10.0
# How far the box's bottom edge sticks out from under its top face: x is
# how wide its right side looks, y how tall its front looks (a taller
# front = looking at the box from the front, where a player sits).
const _BOX_DEPTH := Vector2(12, 24)
# The lid is a solid board, this many px thick (in the same units as
# the box's ~54 px height, so it shows ~0.45x that on screen).
const _LID_THICKNESS := 23.0
# Width of the box's painted frame — the patch margins of `Frame` in
# main.tscn, which draw the frame from the edges of box_lid.jpg.
const _FRAME_WIDTH := 30.0
# Gap between the lid and the inside edge of the frame.
const _LID_GAP := 6.0

# Colors from doc/ART_DIRECTION.md's palette. The sides reuse the lid's
# texture, tinted darker (front) and darker still (right), as if the light
# came from the top-left like in the frame texture's bevel.
const _FELT := Color("26282a")
const _FRONT_TINT := Color(0.72, 0.72, 0.72)
const _RIGHT_TINT := Color(0.52, 0.52, 0.52)
const _EDGE := Color(0, 0, 0, 0.35)
const _RIM := Color(1, 1, 1, 0.3)
const _SHADOW := Color(0, 0, 0, 0.4)
# The shade inside the closed box, seen through the gap around the lid.
const _CAVITY := Color(0.12, 0.11, 0.09)
const _RIBBON_SIDE := Color("b8551f")

# Directions in the lid's "3D" world (x = right, y = toward the player,
# z = up off the table). `_VIEW` points back at the viewer — exactly the
# direction `Oblique.UP` flattens to nothing: a face whose outward normal points
# toward it (positive dot product) is seen, the others are hidden behind.
const _VIEW := Vector3(0.22, 0.44, 1.0)
# Toward the light: up, from the back-left — the same light as the
# frame's bevel, so the lid's front edge is a bit darker than its top
# and its right edge darker still.
const _LIGHT := Vector3(-0.4, 0.2, 0.9)

# Gap between two empty slots inside the box.
const _SLOT_GAP := 3.0

# The running open/close animation, if any — kept so a new open/close
# can stop a half-finished one instead of both fighting over the nodes.
var _tween: Tween
# How far the lid is open: 0 = closed, 1 = turned over onto its back
# beside the box, 2 = carried off the screen (see `_set_turn`).
var _turn := 0.0
# The lid's current pose, set by `_set_turn` and read by `_lid_point`:
# where the hinge is, and where 1 px along the lid's width and 1 px of
# its thickness (along its top face's normal) land on screen.
var _origin := Vector2.ZERO
var _x_axis := Vector2.RIGHT
var _normal := -Oblique.UP
var _angle := 0.0

# The box's top face (frame + inside + lid), the lid itself, and the
# ribbon tied around both — child Controls from main.tscn, so the menu
# inside the lid is laid out by Godot's normal containers; this script
# only positions them and draws the slanted sides.
@onready var _box: Control = $Box
@onready var _inside: Control = $Box/Inside
# An empty node drawn just under the lid, which the lid's edges and
# shadow are drawn onto (see `_draw_lid_edges`).
@onready var _lid_edges: Control = $Box/LidEdges
# The lid's hinge — a Node2D, Godot's base node for free 2D drawing.
# Unlike a Control it can be skewed and squashed by any 2D transform,
# and everything under it (the lid and its menu) is drawn transformed
# with it: that's what makes the lid look like it turns in 3D.
# One catch: a Theme only passes from Control to Control, so the Node2D
# cuts the lid off from main.tscn's theme — hence the Lid node setting
# that same theme again itself.
@onready var _hinge: Node2D = $Box/Hinge
@onready var _lid: Control = $Box/Hinge/Lid
# The lid's bare-wood back, shown on top once the lid has turned past
# vertical (from then on we're looking at its underside).
@onready var _underside: Control = $Box/Hinge/Lid/Underside
@onready var _ribbon: Control = $Ribbon
# The ribbon band; its height is reused to wrap it down the box's side.
@onready var _band: Control = $Ribbon/Band
# The painted texture, reused to paint the sides.
@onready var _paint: NinePatchRect = $Box/Hinge/Lid/Paint


func _ready() -> void:
	# `item_rect_changed` is a signal (Godot's observer/callback hook)
	# fired whenever the box moves or resizes, e.g. on a phone rotation —
	# the hand-drawn sides then need redrawing to follow it.
	_box.item_rect_changed.connect(queue_redraw)
	# `resized` is fired after a Control's size changes. The lid sits under
	# a Node2D, outside Godot's anchor layout, so it's sized by hand.
	_box.resized.connect(_place_lid)
	_layout()
	_place_lid()
	# The `draw` signal fires while a node is being drawn, letting another
	# script draw onto it (calling its `draw_*` methods) — like overriding
	# its `_draw()` from outside.
	_lid_edges.draw.connect(_draw_lid_edges)
	_ribbon.draw.connect(_draw_ribbon_side)
	_inside.draw.connect(_draw_slots)


# Opens the lid, fades the box away, then hides it (a hidden Control
# also stops catching clicks, so the game becomes playable).
func open() -> void:
	if not visible:
		return
	_start_tween()
	# Steps run one after another: a Tween's tweens are sequential by
	# default. `modulate` is a color every node's drawing (and its
	# children's) is multiplied by — its alpha fades the whole subtree.
	_tween.tween_property(_ribbon, "modulate:a", 0.0, _RIBBON_SECONDS)
	# `tween_method` calls `_set_turn` every frame with a value going from
	# 0 to 1 — for animating something that isn't a single property.
	# TRANS_SINE + EASE_IN_OUT: the lid lifts slowly, swings fastest
	# upright, and settles gently on its back, like a turned page.
	_tween.tween_method(_set_turn, 0.0, 1.0, _TURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	# Then picked up and carried away: EASE_IN = starts slow, speeds up.
	_tween.tween_method(_set_turn, 1.0, 2.0, _CARRY_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	_tween.tween_property(self, "modulate:a", 0.0, _FADE_SECONDS)
	_tween.tween_callback(hide)


# Plays `open()` backwards: the box fades in empty, the lid is carried
# back, turns over onto the box, and the ribbon reappears. Does nothing if
# it's already closed (e.g. at startup, where it starts in place).
func close() -> void:
	if visible and modulate.a == 1.0:
		return
	_start_tween()
	# Start from the "opened" state: invisible, lid carried away.
	modulate.a = 0.0
	_ribbon.modulate.a = 0.0
	_set_turn(2.0)
	show()
	_tween.tween_property(self, "modulate:a", 1.0, _FADE_SECONDS)
	_tween.tween_method(_set_turn, 2.0, 1.0, _CARRY_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	_tween.tween_method(_set_turn, 1.0, 0.0, _TURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	_tween.tween_property(_ribbon, "modulate:a", 1.0, _RIBBON_SECONDS)


func _start_tween() -> void:
	# `is_valid()` is false once a Tween has finished or been killed.
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()


# Places the box, its inside and the lid. `offset_*` are pixel distances
# from a node's anchors — here all anchored to their parent's edges, so
# negative right/bottom offsets mean "inwards".
func _layout() -> void:
	# The box: the screen minus the felt margin, minus the room its
	# slanted sides take on the right and bottom.
	_set_inset(_box, Vector2(_MARGIN, _MARGIN), Vector2(_MARGIN, _MARGIN) + _BOX_DEPTH)
	# The ribbon spans the same rectangle as the box's top face.
	_set_inset(_ribbon, Vector2(_MARGIN, _MARGIN), Vector2(_MARGIN, _MARGIN) + _BOX_DEPTH)
	# The dark inside of the box, within the frame.
	var frame := Vector2(_FRAME_WIDTH, _FRAME_WIDTH)
	_set_inset(_inside, frame, frame)


# Sizes the lid to sit inside the frame with a small gap, leaving room
# for its own slanted sides, and puts it back in its current pose.
func _place_lid() -> void:
	var gap := 2 * (_FRAME_WIDTH + _LID_GAP)
	_lid.size = _box.size - Vector2(gap, gap) + Oblique.UP * _LID_THICKNESS
	_set_turn(_turn)


# Poses the lid for an opening progress `turn` (see `_turn`). The lid
# rotates by `angle` about its left edge, a line along the hinge: a point
# `u` px along the lid's width ends up `u * cos` px to the right of the
# hinge and `u * sin` px above the table — which on screen is `u * cos`
# right plus `u * sin` times `Oblique.UP`. Its other axis, along the hinge,
# doesn't change. Those two axes, as the columns of a 2D transform (like
# a 2x3 affine matrix), give the lid's whole shape.
func _set_turn(turn: float) -> void:
	_turn = turn
	_angle = clampf(turn, 0.0, 1.0) * PI
	_x_axis = Vector2(cos(_angle), 0) + sin(_angle) * Oblique.UP
	# The top face's normal turns along with it: from straight up (on
	# screen: `Oblique.UP`) toward the left.
	_normal = Vector2(-sin(_angle), 0) + cos(_angle) * Oblique.UP
	# Hinge's resting place: the lid's top-left corner, inside the frame.
	_origin = Vector2(_FRAME_WIDTH + _LID_GAP, _FRAME_WIDTH + _LID_GAP)
	# Past 1, slide it left until, at 2, the turned-over lid (lying left
	# of its hinge) is fully off the screen's left edge.
	_origin.x -= maxf(turn - 1.0, 0.0) * (_origin.x + _box.position.x)

	# The same normal in 3D, to tell which side of the board we see.
	var top_normal := Vector3(-sin(_angle), 0, cos(_angle))
	var top_seen := top_normal.dot(_VIEW) > 0
	# Seen from below, it's the bottom face, a thickness further down.
	var face_origin := _origin if top_seen else _origin - _LID_THICKNESS * _normal
	_hinge.transform = Transform2D(_x_axis, Vector2.DOWN, face_origin)
	# The bottom face is drawn mirrored by the transform already (its x
	# axis points left); just swap the painted top for bare wood.
	_underside.visible = not top_seen
	# `modulate` multiplies the colors of a node and its children: shade
	# the visible face by how much it faces the light.
	_lid.modulate = _shade(top_normal if top_seen else -top_normal)
	# Redraw the lid's edges and shadow for this pose.
	_lid_edges.queue_redraw()


# A gray to tint a lid face with, from its outward normal: 1 (untinted)
# for the top face lying flat, darker as it turns away from the light.
func _shade(normal: Vector3) -> Color:
	var flat := 0.6 + 0.4 * _LIGHT.z
	var b := clampf((0.6 + 0.4 * normal.dot(_LIGHT)) / flat, 0.2, 1.0)
	return Color(b, b, b)


# Where the lid's point `u` px along its width, `v` px down its length
# and `w` px up its thickness (0 = top face, negative = into the board)
# is on screen, in Box's coordinates, for the current pose.
func _lid_point(u: float, v: float, w: float) -> Vector2:
	return _origin + u * _x_axis + v * Vector2.DOWN + w * _normal


# Sets `node`'s offsets so it sits `top_left` in from its parent's
# top-left corner and `bottom_right` in from its bottom-right corner.
func _set_inset(node: Control, top_left: Vector2, bottom_right: Vector2) -> void:
	node.offset_left = top_left.x
	node.offset_top = top_left.y
	node.offset_right = -bottom_right.x
	node.offset_bottom = -bottom_right.y


# Godot calls this when this node needs redrawing (like Qt's paintEvent).
# What's drawn here sits *under* this node's children, so the box's top
# face (`Box`) covers the inner edges of its sides.
func _draw() -> void:
	# The felt desk mat behind the box — this node also hides the game
	# underneath while the box is closed.
	draw_rect(Rect2(Vector2.ZERO, size), _FELT)
	var box := _box.get_rect()
	# A soft shadow on the felt, cast down-right like the sides.
	draw_rect(Rect2(box.position + _BOX_DEPTH + Vector2(6, 6), box.size), _SHADOW)
	_draw_sides(self, box, _BOX_DEPTH)


# Draws the lid's shadow and visible edges onto `_lid_edges`, under the
# lid's face — the lid is a box of its own, a thin solid board, so as it
# turns its edges show as strips that widen and narrow.
func _draw_lid_edges() -> void:
	var width := _lid.size.x
	var length := _lid.size.y
	var bottom := -_LID_THICKNESS
	# While the lid is shut, the inside of the box is in shade: only a dark
	# groove shows around the lid. Light floods in as the lid lifts, so
	# the shade fades out over the first quarter of the turn.
	var cavity := _CAVITY
	cavity.a = 1.0 - clampf(_turn * 4.0, 0.0, 1.0)
	_lid_edges.draw_rect(_inside.get_rect(), cavity)
	# The shadow: the lid's outline dropped straight down onto the box
	# (its x axis without the lift), under the lid's bottom face.
	var drop := -Oblique.UP * _LID_THICKNESS + Vector2(2, 2)
	var flat_x := Vector2(cos(_angle), 0)
	var shadow_corners: Array[Vector2] = [
		Vector2.ZERO, width * flat_x, width * flat_x + Vector2(0, length), Vector2(0, length)
	]
	var shadow := PackedVector2Array()
	for corner in shadow_corners:
		shadow.append(_origin + drop + corner)
	_lid_edges.draw_colored_polygon(shadow, _SHADOW)

	# The front end (facing the player): always seen from this viewpoint.
	var front := [
		_lid_point(0, length, 0),
		_lid_point(width, length, 0),
		_lid_point(width, length, bottom),
		_lid_point(0, length, bottom),
	]
	Oblique.fill(_lid_edges, front, _shade(Vector3(0, 1, 0)), _paint.texture)
	# One long edge: the free one while it faces us (closed, then rising),
	# the hinge one once the lid is nearly turned over.
	var free_normal := Vector3(cos(_angle), 0, sin(_angle))
	var u := width if free_normal.dot(_VIEW) > 0 else 0.0
	var side := [
		_lid_point(u, 0, 0),
		_lid_point(u, length, 0),
		_lid_point(u, length, bottom),
		_lid_point(u, 0, bottom),
	]
	var normal := free_normal if u > 0 else -free_normal
	Oblique.fill(_lid_edges, side, _shade(normal), _paint.texture)


# Draws, onto `canvas`, the front and right sides of a box whose top face
# is `top` and whose bottom edge sits `depth` further down-right.
func _draw_sides(canvas: CanvasItem, top: Rect2, depth: Vector2) -> void:
	Oblique.draw_sides(canvas, top, depth, _FRONT_TINT, _RIGHT_TINT, _paint.texture)
	var top_right := Vector2(top.end.x, top.position.y)
	var bottom_right := top.end
	var bottom_left := Vector2(top.position.x, top.end.y)
	# The vertical edge where the two sides meet.
	canvas.draw_line(bottom_right, bottom_right + depth, _EDGE, 1.5, true)
	# A thin light line just outside the top face's bottom and right
	# edges — its lit rim — so the top reads as separate from the sides.
	canvas.draw_polyline(
		PackedVector2Array(
			[bottom_left + Vector2(0, 1), bottom_right + Vector2(1, 1), top_right + Vector2(1, 0)]
		),
		_RIM,
		1.5,
		true
	)


# The inside of the box: the board's empty holes, so lifting the lid
# shows an empty board like the one the game then starts on.
func _draw_slots() -> void:
	# Square slots as big as fit, the grid centred in the inside.
	var cell := minf(_inside.size.x / Board.COLUMNS, _inside.size.y / Board.ROWS)
	var origin := (_inside.size - cell * Vector2(Board.COLUMNS, Board.ROWS)) / 2
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var slot := Rect2(origin + cell * Vector2(col, row), Vector2(cell, cell))
			# `grow(-x)` shrinks a Rect2 by x on every side — the gap.
			TileView.draw_hole(_inside, slot.grow(-_SLOT_GAP / 2))


# The ribbon is tied around the whole box: continue the band down the
# box's right side, slanting with it (in the ribbon node's coordinates,
# where the box's top face spans 0..size).
func _draw_ribbon_side() -> void:
	var band_top := Vector2(_ribbon.size.x, _band.position.y)
	var band_bottom := band_top + Vector2(0, _band.size.y)
	_ribbon.draw_colored_polygon(
		PackedVector2Array(
			[band_top, band_top + _BOX_DEPTH, band_bottom + _BOX_DEPTH, band_bottom]
		),
		_RIBBON_SIDE
	)
