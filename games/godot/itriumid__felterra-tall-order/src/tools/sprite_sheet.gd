extends SceneTree
## Lays every sprite out on one sheet, magnified, to look the art over without playing.
## Run with: godot --headless --path . --script tools/sprite_sheet.gd -- <output>.png

const SCALE := 6
const GAP := 4


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	var output := arguments[0] if not arguments.is_empty() else "user://sprite_sheet.png"
	var art := Sprites.all_art()
	var pictures: Array[Image] = []
	for name: String in art:
		pictures.append(Sprites.image(art[name]))
	var columns := 8
	var cell := Vector2i(26, 26)
	var rows := ceili(pictures.size() / float(columns))
	var sheet := Image.create_empty(columns * (cell.x + GAP) + GAP, rows * (cell.y + GAP) + GAP, false, Image.FORMAT_RGBA8)
	sheet.fill(Palette.MUD)
	for index in pictures.size():
		var at := Vector2i(GAP + (index % columns) * (cell.x + GAP), GAP + (index / columns) * (cell.y + GAP))
		sheet.blend_rect(pictures[index], Rect2i(Vector2i.ZERO, pictures[index].get_size()), at)
	sheet.resize(sheet.get_width() * SCALE, sheet.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	sheet.save_png(output)
	print("%d sprites on %s" % [pictures.size(), output])
	quit()
