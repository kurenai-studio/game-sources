# A piece of felt, like the dark desk mat the real game sits on (see
# doc/ART_DIRECTION.md's `felt`): a base color with a
# fine grain, round corners, and optionally a padded rim.
#
# Used in main.tscn as the whole page's background (Background: the dark
# desk felt, edge to edge), under the hand, the "À rendre" tray and the
# buttons below them (HandArea: a brighter mat with a padded rim, setting
# the player's tiles apart from the board), and as the background of the
# screens drawn over the game (HandoffScreen, and end_screen.gd and
# how_to_play_view.gd, which build on this script: `extends PlayMat`). A Control
# draws itself before its children, so the mat lies under them. Purely
# visual. `extends Control`: it fits any Control node, here a Panel and a
# VBoxContainer.
class_name PlayMat
extends Control

# The grain, made once and shared by every mat: a NoiseTexture2D is an
# image Godot computes from a noise function (like Perlin noise), here
# white fibres on transparent, repeating seamlessly so it can be tiled.
# Each mat tints it (see `grain`). A `static var` is shared by every
# instance of this script, like a C++ static member.
static var _grain_texture: NoiseTexture2D

# `@export` makes a variable editable per node in the scene (main.tscn),
# like a constructor argument each instance gets its own value for.
# The felt's color.
@export var felt_color := Color("26282a")
# How strongly its grain shows: 0 none, 1 full white fibres.
@export var grain := 0.06
# Its round corners' radius, in px.
@export var corner_radius := 0
# How far it reaches past the node's own rectangle (left/right,
# top/bottom), in px, so its children don't touch its edge.
@export var bleed := Vector2.ZERO
# Its padded edge: a rim this wide (0: none), this color at the very
# edge, blending into the felt inwards, like a rolled, stuffed border.
@export var rim_width := 0.0
@export var rim_color := Color(0.08, 0.085, 0.09)

# The mat's own shape: its color, with round corners.
var _base := StyleBoxFlat.new()


func _ready() -> void:
	_base.bg_color = felt_color
	_base.set_corner_radius_all(corner_radius)
	if _grain_texture == null:
		_grain_texture = NoiseTexture2D.new()
		_grain_texture.width = 128
		_grain_texture.height = 128
		_grain_texture.seamless = true
		var noise := FastNoiseLite.new()
		# High frequency: fine fibres, not blotches.
		noise.frequency = 0.25
		_grain_texture.noise = noise
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 0))
		ramp.set_color(1, Color.WHITE)
		_grain_texture.color_ramp = ramp
	# The texture is computed in the background: redraw once it's ready.
	_grain_texture.changed.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size).grow_individual(bleed.x, bleed.y, bleed.x, bleed.y)
	_draw_rim(rect)
	# The grain, tiled across the mat (`true`: repeat rather than stretch),
	# kept inside the round corners, faint (`modulate`'s alpha).
	draw_texture_rect(_grain_texture, rect.grow(-corner_radius / 2.0), true, Color(1, 1, 1, grain))


# The mat's shape, `rect`: the felt, and its padded edge — one rounded
# shape per pixel of the rim, from the rim's color at the very edge
# inwards to the felt's, each a little smaller (its corners a little
# tighter), so the edge looks rolled.
func _draw_rim(rect: Rect2) -> void:
	var steps := ceili(rim_width)
	for i in range(steps + 1):
		var weight := float(i) / maxf(steps, 1)
		var style: StyleBoxFlat = _base.duplicate()
		# `lerp` mixes two colors: 0 gives the first, 1 the second. Eased
		# (`ease` with 0.5) so the edge darkens quickly, like a curve.
		style.bg_color = rim_color.lerp(felt_color, ease(weight, 0.5))
		style.set_corner_radius_all(maxi(corner_radius - i, 0))
		draw_style_box(style, rect.grow(-i))
