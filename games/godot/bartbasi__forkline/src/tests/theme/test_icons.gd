# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The committed launcher icons from tools/icon/make_icon.gd: the files the
## export preset needs, at their sizes, with the right kind of transparency.

const ICONS: Dictionary[String, int] = {
	"res://icons/icon_192.png": 192,
	"res://icons/icon_foreground_432.png": 432,
	"res://icons/icon_background_432.png": 432,
	"res://icons/icon_monochrome_432.png": 432,
}


func test_every_icon_exists_at_its_size() -> void:
	for path: String in ICONS:
		var img: Image = _load(path)
		assert_not_null(img, "%s exists" % path)
		if img != null:
			assert_eq(img.get_width(), ICONS[path], "%s width" % path)
			assert_eq(img.get_height(), ICONS[path], "%s height" % path)


func test_full_icon_and_background_are_opaque() -> void:
	for path: String in ["res://icons/icon_192.png", "res://icons/icon_background_432.png"]:
		var img: Image = _load(path)
		if img == null:
			fail("%s missing" % path)
			continue
		for p: Vector2i in _samples(img):
			assert_eq(img.get_pixelv(p).a, 1.0, "%s pixel %s is opaque" % [path, p])


func test_foreground_leaves_the_corners_clear() -> void:
	var img: Image = _load("res://icons/icon_foreground_432.png")
	if img == null:
		fail("foreground missing")
		return
	for p: Vector2i in [Vector2i(2, 2), Vector2i(429, 2)]:
		assert_eq(img.get_pixelv(p).a, 0.0, "corner %s is see-through" % p)


func test_monochrome_is_one_color() -> void:
	var img: Image = _load("res://icons/icon_monochrome_432.png")
	if img == null:
		fail("monochrome missing")
		return
	var shown: int = 0
	for y: int in range(0, 432, 3):
		for x: int in range(0, 432, 3):
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				shown += 1
				if c.r < 0.99 or c.g < 0.99 or c.b < 0.99:
					fail("monochrome pixel (%d, %d) is not white" % [x, y])
					return
	assert_true(shown > 500, "the monochrome icon shows a shape")


func _load(path: String) -> Image:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path):
		return null
	return Image.load_from_file(abs_path)


func _samples(img: Image) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(0, img.get_height(), 7):
		for x: int in range(0, img.get_width(), 7):
			out.append(Vector2i(x, y))
	return out
