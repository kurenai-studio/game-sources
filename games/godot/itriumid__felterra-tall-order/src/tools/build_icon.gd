extends SceneTree
## Draws the game's icon from Tompel himself: his face, from the front view's sprite, enlarged by
## whole pixels onto a jungle-green tile, so the icon is the same pixel art as the game. Run with:
## godot --headless --path . --script tools/build_icon.gd
## and commit icon.png; the exports use it.

const SIZE := 256
const SCALE := 13


func _init() -> void:
	var face := Sprites.image(Sprites.coat(Sprites.cat_body_art("front", 0), "tompel", "front")).get_region(Rect2i(4, 2, 16, 13))
	var icon := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	# A rounded tile: clear at the corners, as icons are shaped.
	var corner := 40.0
	for y in SIZE:
		for x in SIZE:
			var nearest := Vector2(clampf(x, corner, SIZE - 1 - corner), clampf(y, corner, SIZE - 1 - corner))
			if Vector2(x, y).distance_to(nearest) <= corner:
				icon.set_pixel(x, y, Palette.JUNGLE_DARK if y > SIZE * 0.62 else Palette.JUNGLE)
	face.resize(face.get_width() * SCALE, face.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	var at := Vector2i((SIZE - face.get_width()) / 2, (SIZE - face.get_height()) / 2 + 6)
	icon.blend_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), at)
	icon.save_png("res://icon.png")
	print("icon.png written")
	quit()
