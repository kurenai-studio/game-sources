# Redraws the image shown while the game loads (Godot's "boot splash",
# see project.godot's `application/boot_splash/*`): the game's own tiles
# spelling TRAMPOLINE, bouncing off a trampoline — drawn by the game's
# tile code (see tile_view.gd), so they match the tiles in play — and, in
# the bottom-right corner, the Godot logo with "Fait avec Godot", to
# credit the engine (see assets/textures/README.md). Phone-shaped, so that
# corner is the screen's. Needs a window to draw in (not --headless):
#   godot4 --path . --script tools/build_splash.gd
extends SceneTree

const _PATH := "res://assets/splash.png"
const _SIZE := Vector2i(1000, 2160)
# The trampoline and its tiles fit a 1000 x 760 picture, placed in the
# middle of the image this far down.
const _SCENE_TOP := (2160 - 760) / 2.0
const _LOGO := preload("res://assets/textures/godot_logo.svg")
# The credit's logo side, its text size, and its margin to the corner.
const _LOGO_SIDE := 84.0
const _CREDIT_SIZE := 30
const _CREDIT_MARGIN := 48.0
const _CREDIT_COLOR := Color(0.953, 0.937, 0.847, 0.7)
const _WORD := "TRAMPOLINE"
# A tile's side, and the room between two, in px.
const _TILE := 80.0
const _STEP := 88.0
# How high the tiles fly at most above their lowest, in px: they rise from
# the trampoline's left end and fall back towards its right one, like
# letters thrown up one after another.
const _FLIGHT := 190.0
# The trampoline: its centre, half its width and height, in px.
const _CENTER := Vector2(500, 600)
const _RADIUS := Vector2(400, 62)
# Its colors: the painted green of the board's frame (`frame_paint`,
# `frame_shade` in doc/ART_DIRECTION.md), and the dark bed.
const _FRAME := Color("5fa373")
const _FRAME_SHADE := Color("3c7f5c")
const _BED := Color(0.1, 0.105, 0.11)
const _SPRING := Color(0.75, 0.76, 0.74)


func _initialize() -> void:
	_draw_splash()


func _draw_splash() -> void:
	# An off-screen drawing surface (like a render target in OpenGL), with
	# a transparent background: Godot fills the rest of the screen with
	# `boot_splash/bg_color`.
	var viewport := SubViewport.new()
	viewport.size = _SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := Control.new()
	scene.position = Vector2(0, _SCENE_TOP)
	viewport.add_child(scene)
	var trampoline := Control.new()
	trampoline.size = Vector2(_SIZE)
	trampoline.draw.connect(_draw_trampoline.bind(trampoline))
	scene.add_child(trampoline)
	_add_tiles(scene)
	var credit := Control.new()
	credit.size = Vector2(_SIZE)
	credit.draw.connect(_draw_credit.bind(credit))
	viewport.add_child(credit)
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(_PATH)
	print("Wrote ", _PATH)
	quit()


# The 10 tiles of TRAMPOLINE, each a real tile of the game (its corner
# showing its real other face), along an arc over the trampoline, tilted
# with the arc — the first just leaving it, the last coming back down.
func _add_tiles(parent: Node) -> void:
	var pool := TilePool.new().tiles
	var left := _CENTER.x - _STEP * (_WORD.length() - 1) / 2.0
	for i in range(_WORD.length()):
		var tile: Tile = pool.filter(func(t: Tile) -> bool: return t.front_letter() == _WORD[i])[0]
		pool.erase(tile)
		var visual := TileView.build_tile_visual(tile, Vector2.ONE * _TILE)
		# 0 at the first letter, 1 at the last: the arc's height is a sine
		# hump, its slope gives each tile's tilt.
		var t := float(i) / (_WORD.length() - 1)
		var lowest := _CENTER.y - _RADIUS.y - _TILE * 1.25
		var center := Vector2(left + i * _STEP, lowest - _FLIGHT * sin(PI * t))
		visual.pivot_offset = visual.size / 2
		visual.position = center - visual.size / 2
		visual.rotation = -0.35 * cos(PI * t)
		parent.add_child(visual)


# The trampoline under the tiles: its legs, its green frame ring, the
# springs around it, and the dark bed, slightly sunk in the middle where
# the letters bounce.
func _draw_trampoline(canvas: Control) -> void:
	for x in [-0.75, 0.0, 0.75]:
		var top := _CENTER + Vector2(x * _RADIUS.x, _RADIUS.y * 0.8)
		canvas.draw_line(top, top + Vector2(0, 70), _FRAME_SHADE, 16.0)
	canvas.draw_colored_polygon(_ellipse(_CENTER + Vector2(0, 10), _RADIUS * 1.05), _FRAME_SHADE)
	canvas.draw_colored_polygon(_ellipse(_CENTER, _RADIUS * 1.05), _FRAME)
	var bed_radius := _RADIUS * Vector2(0.86, 0.72)
	# The springs: short strokes from the frame ring to the bed's edge.
	for k in range(36):
		var angle := TAU * k / 36.0
		var direction := Vector2(cos(angle), sin(angle))
		canvas.draw_line(
			_CENTER + direction * bed_radius, _CENTER + direction * _RADIUS * 0.99, _SPRING, 2.0
		)
	canvas.draw_colored_polygon(_ellipse(_CENTER + Vector2(0, 6), bed_radius), _BED)


# The points of an ellipse centred on `center`, `radius` its half-width
# and half-height.
func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in range(64):
		var angle := TAU * k / 64.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


# The Godot logo in the bottom-right corner, "Fait avec Godot" left of it,
# both vertically centred on the same line.
func _draw_credit(canvas: Control) -> void:
	var logo := Rect2(
		Vector2(_SIZE) - Vector2.ONE * (_CREDIT_MARGIN + _LOGO_SIDE), Vector2.ONE * _LOGO_SIDE
	)
	canvas.draw_texture_rect(_LOGO, logo, false)
	var font := TileView.LETTER_FONT
	var text := "Fait avec Godot"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _CREDIT_SIZE).x
	# `draw_string` places the text by its baseline: a little below the
	# logo's middle reads as centred.
	var baseline := Vector2(logo.position.x - 16 - width, logo.get_center().y + _CREDIT_SIZE * 0.35)
	canvas.draw_string(
		font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, _CREDIT_SIZE, _CREDIT_COLOR
	)
