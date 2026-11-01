# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Draws the Android launcher icons with IconArt and writes them to icons/.
## It needs a rendering display, so run it without --headless, from the repo
## root:
##     godot --path . --script res://tools/icon/make_icon.gd
## It opens a small window for a moment and exits 0 when every file is written.
##
## Files, for the export preset (release engineer):
##     launcher_icons/main_192x192                 res://icons/icon_192.png
##     launcher_icons/adaptive_foreground_432x432  res://icons/icon_foreground_432.png
##     launcher_icons/adaptive_background_432x432  res://icons/icon_background_432.png
##     launcher_icons/adaptive_monochrome_432x432  res://icons/icon_monochrome_432.png

const OUT_DIR: String = "res://icons"
const FILES: Array[Array] = [
	["icon_192.png", 192, IconArt.Layer.FULL],
	["icon_foreground_432.png", 432, IconArt.Layer.FOREGROUND],
	["icon_background_432.png", 432, IconArt.Layer.BACKGROUND],
	["icon_monochrome_432.png", 432, IconArt.Layer.MONOCHROME],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("make_icon.gd needs a display. Run it without --headless.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var failed: int = 0
	for entry: Array in FILES:
		var file_name: String = entry[0]
		var size: int = entry[1]
		var layer: IconArt.Layer = entry[2]
		var img: Image = await IconArt.draw_layer(size, layer)
		if layer == IconArt.Layer.MONOCHROME:
			_whiten(img)
		elif layer != IconArt.Layer.FOREGROUND:
			_opaque(img)
		var path: String = OUT_DIR.path_join(file_name)
		var err: Error = img.save_png(path)
		print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(err)])
		if err != OK:
			failed += 1
	quit(1 if failed > 0 else 0)


## The monochrome layer is a mask: white, with the shape in the alpha.
func _whiten(img: Image) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var a: float = img.get_pixel(x, y).a
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))


## The full icon and the background have no see-through pixels.
func _opaque(img: Image) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a < 1.0:
				img.set_pixel(x, y, Color(c, 1.0))
