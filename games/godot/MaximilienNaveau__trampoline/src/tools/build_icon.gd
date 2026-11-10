# Redraws the game's icon: one tile, its yellow M face up, with a green C
# on its back (shown in its corner), drawn by the game's own tile code
# (see tile_view.gd) so it matches the tiles in play. Needs a window to
# draw in (not --headless):
#   godot4 --path . --script tools/build_icon.gd
#
# Writes, in assets/icon/:
#   desktop_icon.png — the window's icon (project.godot's `config/icon`)
#     and the Linux desktop's (the nixpkgs package): the tile as it looks
#     off the board, a block on its cork base with a lifted tile's soft
#     shadow, filling about 80% of the square like the desktop's other
#     icons — app_icon.png's flat, edge-to-edge square looked out of place
#     in GNOME's dock. Also F-Droid's store icon, written to
#     fastlane/metadata/android/en-US/images/icon.png.
#   app_icon.png — the whole tile, flat: Android's icon before 8.0.
#   icon_background.png, icon_foreground.png — Android's two layers (8.0
#     and later, see export_presets.cfg): the launcher crops them to its
#     own shape (a circle, a rounded square…) keeping only the middle two
#     thirds, so the background is the tile's yellow and the foreground
#     just its M and C, small enough to stay inside any crop.
#   icon_monochrome.png — Android 13's themed icon: only the shapes count
#     (the launcher colors them), so it's just the letters M and C.
#   splash_icon.png — the icon Android 12+ shows while the app starts (see
#     export_presets.cfg's `splash_screen/icon`), on the felt's color: the
#     whole tile, small enough that its corners stay inside the circle the
#     system crops it to (two thirds of the image).
extends SceneTree

const _DIR := "res://assets/icon/"
# F-Droid's store icon, in the layout F-Droid reads an app's store page from
# (fastlane/metadata/android/<language>/).
const _STORE_ICON := "res://fastlane/metadata/android/en-US/images/icon.png"
const _SIZE := 512
# Transparent room left round the whole tile, in pixels.
const _MARGIN := 16
# Android's adaptive layers: 432 px square, the tile's letters drawn on a
# 200 px tile centred in it — its C badge's outer corner then stays inside
# the 288 px wide middle the launcher shows.
const _LAYER_SIZE := 432
const _LAYER_TILE := 200
# desktop_icon.png's tile, in a `_SIZE` px square: the rest is room for the
# cork base and the shadow, and the margin desktop icons keep.
const _DESKTOP_TILE := 400


func _initialize() -> void:
	_draw_all()


func _draw_all() -> void:
	await _draw_desktop()
	await _draw("app_icon.png", _SIZE, _SIZE - 2 * _MARGIN, true, true)
	await _draw("icon_foreground.png", _LAYER_SIZE, _LAYER_TILE, false, true)
	await _draw("icon_monochrome.png", _LAYER_SIZE, _LAYER_TILE, false, false)
	await _draw("splash_icon.png", _LAYER_SIZE, _LAYER_TILE, true, true)
	# The background: the tile's yellow, nothing drawn on it.
	var background := Image.create(_LAYER_SIZE, _LAYER_SIZE, false, Image.FORMAT_RGBA8)
	background.fill(TileView.YELLOW_COLOR)
	background.save_png(_DIR + "icon_background.png")
	print("Wrote ", _DIR, "icon_background.png")
	quit()


# The desktop icon (see this file's header): the tile with its cork base,
# a little up and left of centre, so the block and the shadow (down and to
# the right, the game's oblique view) leave even margins.
func _draw_desktop() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i.ONE * _SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var tile := TileView.build_tile_visual(Tile.new("M", "C", true), Vector2.ONE * _DESKTOP_TILE)
	tile.position = Vector2.ONE * (_SIZE - _DESKTOP_TILE) / 2 + Vector2(-6, -18)
	# A lifted tile's shadow (as tile_view.gd's drag preview), scaled up
	# with the tile: a copy of its style, with the shadow added.
	var style: StyleBoxFlat = tile.get_theme_stylebox("panel").duplicate()
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 28
	style.shadow_offset = Vector2(6, 22)
	tile.add_theme_stylebox_override("panel", style)
	viewport.add_child(tile)
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png(_DIR + "desktop_icon.png")
	image.save_png(_STORE_ICON)
	print("Wrote ", _DIR, "desktop_icon.png and ", _STORE_ICON)
	viewport.queue_free()


# Draws the M/C tile, `tile_side` px wide, centred on a transparent
# `canvas` px square, and saves it as `file_name`. Without `face`, the
# tile's yellow face isn't drawn, only what's on it; without `badge`, the
# corner's green square isn't either, only its C.
func _draw(file_name: String, canvas: int, tile_side: int, face: bool, badge: bool) -> void:
	# A SubViewport is an off-screen drawing surface, like a render target
	# in OpenGL; with a transparent background, only what's drawn shows.
	var viewport := SubViewport.new()
	viewport.size = Vector2i.ONE * canvas
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	# `Tile.new(front, back, back_is_green)`: a yellow M, a green C.
	var tile := TileView.build_tile_visual(Tile.new("M", "C", true), Vector2.ONE * tile_side)
	tile.position = Vector2.ONE * (canvas - tile_side) / 2
	# Flat, without the cork base a tile off the board shows (see
	# tile_view.gd's `add_cork`).
	tile.get_node("Cork").free()
	if not face:
		# StyleBoxEmpty draws nothing: the Panel itself becomes invisible.
		tile.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if not badge:
		# The corner badge, the tile's second child (see tile_view.gd's
		# `build_tile_visual`).
		tile.get_child(1).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	viewport.add_child(tile)
	# Waits until that frame has actually been drawn before reading it.
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(_DIR + file_name)
	print("Wrote ", _DIR, file_name)
	viewport.queue_free()
