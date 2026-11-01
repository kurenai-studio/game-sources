# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## IconTex: the icons are cheap to build, are drawn where they should be, and every
## one the screens ask for is built when the app starts (a first wave must not pay
## for an icon).
##
## The speed bar is a ratio, like the sim perf tests (ARCHITECTURE 9.2), not milliseconds.
## A fixed piece of plain GDScript (`_reference`) is timed right before and right after each
## first build, and the build's time is divided by their mean, so a busy machine slows the
## build and the reference alike. The test takes the median of all 22 ratios, so one slow
## moment (a thread switch inside one build) cannot fail it. On the dev PC the median is
## about 2 references, the slowest single build (the cup at 73 px) 4 to 6. A drawing that
## is slow for every icon, like the old pixel by pixel one (26 to 95 ms where the slowest
## build now takes 8), or the same code with its blocks cut to one pixel (a trial on
## 2026-10-29: median 9), lands far above MEDIAN_LIMIT.

const KINDS: Array[StringName] = [&"cup", &"gear", &"back", &"lock", &"check", &"arrow", &"close", &"pause", &"play", &"speaker", &"speaker_off"]
const SIZES: Array[int] = [57, 73]
const MEDIAN_LIMIT: float = 5.0
var _sink: float = 0.0


## About 2.5 ms on the dev PC: a few thousand callable calls and some block fills, the kind
## of work IconTex does.
func _reference() -> float:
	var start: int = Time.get_ticks_usec()
	var image: Image = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var distance: Callable = func(x: float, y: float) -> float: return sqrt(x * x + y * y) - 0.4
	for i: int in 3000:
		_sink += float(distance.call(float(i % 64) / 64.0, float(i / 64) / 64.0))
	for i: int in 200:
		image.fill_rect(Rect2i(i % 50, i % 40, 8, 8), Color.WHITE)
	return float(Time.get_ticks_usec() - start) / 1000.0


## A size that no screen uses, so the first build really happens in this test.
func test_first_build_of_every_kind_is_fast() -> void:
	var ratios: Array[float] = []
	for kind: StringName in KINDS:
		for px: int in SIZES:
			var before: float = _reference()
			var start: int = Time.get_ticks_usec()
			var tex: ImageTexture = IconTex.make(kind, px)
			var ms: float = float(Time.get_ticks_usec() - start) / 1000.0
			var after: float = _reference()
			ratios.append(ms / maxf(0.01, (before + after) * 0.5))
			assert_eq(tex.get_width(), px)
			assert_eq(tex.get_height(), px)
	ratios.sort()
	var median: float = (ratios[ratios.size() / 2 - 1] + ratios[ratios.size() / 2]) * 0.5
	assert_true(median < MEDIAN_LIMIT, "the median first build costs %.1f references, more than %.1f (slowest %.1f)" % [median, MEDIAN_LIMIT, ratios[ratios.size() - 1]])


func test_a_second_call_gives_the_same_texture() -> void:
	assert_true(IconTex.make(&"lock", 56) == IconTex.make(&"lock", 56))


func test_prewarm_builds_every_used_icon() -> void:
	IconTex.prewarm()
	for pair: Array in IconTex.USED_ICONS:
		assert_true(IconTex.is_built(pair[0] as StringName, int(pair[1])), "%s %s" % [pair[0], pair[1]])


func test_the_app_builds_the_icons_before_any_screen_needs_them() -> void:
	var made: App = App.new()
	made.build()
	for pair: Array in IconTex.USED_ICONS:
		assert_true(IconTex.is_built(pair[0] as StringName, int(pair[1])))
	made.free()


## Every `IconTex.make(&"kind", size)` and `icon_button(&"kind")` in src/ui/ is in the list
## that is built ahead of time.
func test_every_icon_the_code_asks_for_is_prebuilt() -> void:
	var make_call: RegEx = RegEx.create_from_string("IconTex\\.make\\(&\"(\\w+)\",\\s*(\\d+)\\)")
	var button_call: RegEx = RegEx.create_from_string("icon_button\\(&\"(\\w+)\"\\)")
	var found: int = 0
	for name: String in DirAccess.get_files_at("res://src/ui"):
		if not name.ends_with(".gd"):
			continue
		var text: String = FileAccess.get_file_as_string("res://src/ui/" + name)
		for hit: RegExMatch in make_call.search_all(text):
			found += 1
			assert_true(_listed(StringName(hit.get_string(1)), int(hit.get_string(2))), "%s asks for %s %s" % [name, hit.get_string(1), hit.get_string(2)])
		for hit: RegExMatch in button_call.search_all(text):
			found += 1
			assert_true(_listed(StringName(hit.get_string(1)), 72), "%s icon_button %s" % [name, hit.get_string(1)])
	assert_true(found > 15, "the scan found the calls")
	assert_true(_listed(&"cup", CoffeeButton.ICON_PX))


func _listed(kind: StringName, px: int) -> bool:
	for pair: Array in IconTex.USED_ICONS:
		if pair[0] == kind and int(pair[1]) == px:
			return true
	return false


## The shapes are where they should be: solid inside, clear outside, a hole in the lock.
func test_the_shapes_are_where_they_should_be() -> void:
	var lock: Image = IconTex.make(&"lock", 64).get_image()
	assert_true(lock.get_pixel(32, 50).a > 0.99, "lock body")
	assert_true(lock.get_pixel(32, 41).a < 0.01, "keyhole is clear")
	assert_true(lock.get_pixel(2, 2).a < 0.01, "corner is clear")
	assert_true(lock.get_pixel(32, 12).a > 0.99, "shackle top")
	assert_true(lock.get_pixel(32, 24).a < 0.01, "inside the shackle is clear")
	var pause: Image = IconTex.make(&"pause", 64).get_image()
	assert_true(pause.get_pixel(22, 32).a > 0.99, "left bar")
	assert_true(pause.get_pixel(32, 32).a < 0.01, "gap")
	var gear: Image = IconTex.make(&"gear", 64).get_image()
	assert_true(gear.get_pixel(32, 32).a < 0.01, "gear hole")
	assert_true(gear.get_pixel(32, 12).a > 0.99, "gear ring")
	assert_true(gear.get_pixel(32, 3).a > 0.99, "tooth at the top")
	assert_true(gear.get_pixel(2, 2).a < 0.01, "gear corner")
	var play: Image = IconTex.make(&"play", 64).get_image()
	assert_true(play.get_pixel(24, 32).a > 0.99, "triangle")
	assert_true(play.get_pixel(24, 8).a < 0.01, "above the triangle")
	# Every icon draws something, white, and leaves the corner clear.
	for kind: StringName in KINDS:
		var image: Image = IconTex.make(kind, 64).get_image()
		var solid: int = 0
		for y: int in 64:
			for x: int in 64:
				var c: Color = image.get_pixel(x, y)
				assert_true(c.r > 0.99 and c.g > 0.99 and c.b > 0.99, "%s is white" % kind)
				if c.a > 0.5:
					solid += 1
		assert_true(solid > 200 and solid < 3000, "%s covers a sensible area (%d)" % [kind, solid])


## The speaker has a box, a cone and a sound wave. Crossed out, it gains a slash and loses a
## gap around it, so the two read apart by shape and not by color.
func test_the_speaker_and_its_crossed_out_twin() -> void:
	var plain: Image = IconTex.make(&"speaker", 64).get_image()
	var off: Image = IconTex.make(&"speaker_off", 64).get_image()
	assert_true(plain.get_pixel(14, 32).a > 0.99, "speaker box")
	assert_true(plain.get_pixel(26, 32).a > 0.99, "speaker cone")
	assert_true(plain.get_pixel(48, 32).a > 0.99, "sound wave")
	assert_true(plain.get_pixel(4, 4).a < 0.01, "speaker corner")
	assert_true(plain.get_pixel(13, 13).a < 0.01, "no slash on the plain speaker")
	assert_true(off.get_pixel(13, 13).a > 0.99, "the slash starts top left")
	assert_true(off.get_pixel(51, 51).a > 0.99, "and ends bottom right")
	assert_true(plain.get_pixel(18, 25).a > 0.99, "the box is solid where the gap will be")
	assert_true(off.get_pixel(18, 25).a < 0.01, "the slash keeps a clear gap beside it")
	var count_note: int = 0
	var count_off: int = 0
	for y: int in 64:
		for x: int in 64:
			if plain.get_pixel(x, y).a > 0.5:
				count_note += 1
			if off.get_pixel(x, y).a > 0.5:
				count_off += 1
	assert_ne(count_note, count_off, "the two icons differ in shape")
