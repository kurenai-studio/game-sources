extends RefCounted
## Pixel icons for the menus and the coach's tablet, drawn from
## 12x12 character grids and blown up 2x with hard edges, so they sit with the
## pixel font. One letter per colour below; "." is see-through.

const PAL := {
	"w": Color(0.960, 0.960, 0.940), "d": Color(0.720, 0.780, 0.860), "k": Color(0.15, 0.19, 0.32),
	"y": Color(0.980, 0.800, 0.250), "o": Color(0.980, 0.520, 0.150), "r": Color(0.900, 0.080, 0.120),
	"s": Color(0.420, 0.820, 0.980), "g": Color(0.35, 0.92, 0.45), "b": Color(0.55, 0.36, 0.22),
}
const PIX := {
	"home": ["....rrrr....", "...rrrrrr...", "..rrrrrrrr..", ".rrrrrrrrrr.", "..wwwwwwww..", "..wsswwssw..", "..wsswwssw..", "..wwwwwwww..", "..wsswbbww..", "..wsswbbww..", "..wwwwbbww..", "............"],
	"squad": ["............", "..yy....ss..", ".yyyy..ssss.", ".yyyy..ssss.", "..yy....ss..", "............", ".yyyy..ssss.", "yyyyyyssssss", "yyyyyyssssss", "yyyyyyssssss", "yyyyyyssssss", "............"],
	"train": ["............", "............", ".dd......dd.", ".dd......dd.", "dddd....dddd", "ddddwwwwdddd", "ddddwwwwdddd", "dddd....dddd", ".dd......dd.", ".dd......dd.", "............", "............"],
	"gear": ["...rrrr.....", "..rrrrrr....", ".rrrrrrrr...", ".rrrrrrrr...", ".rrrrrrrr...", ".rrrrrrrr...", "..rrrrrr....", "...rrrr..ww.", "....bb...ww.", "....bb......", "....bb......", "....bb......"],
	"league": ["............", "............", ".........yy.", ".........yy.", "......ss.yy.", "......ss.yy.", "...rr.ss.yy.", "...rr.ss.yy.", "...rr.ss.yy.", "...rr.ss.yy.", "..wwwwwwwwww", "............"],
	"cup": ["..yyyyyyyy..", "yyyyyyyyyyyy", "y.yyyyyyyy.y", "y.yyyyyyyy.y", ".yyyyyyyyyy.", "..yyyyyyyy..", "...yyyyyy...", ".....yy.....", ".....yy.....", "....yyyy....", "...bbbbbb...", "...bbbbbb..."],
	"friendly": ["rrr......sss", "rrrr....ssss", "rrrr....ssss", ".rrr....sss.", "...b....b...", "....b..b....", ".....bb.....", ".....bb.....", "....b..b....", "...b....b...", "............", "............"],
	"boss": ["............", "y....y....y.", "yy..yyy..yy.", "yyy.yyy.yyy.", "yyyyyyyyyyy.", "yyyyyyyyyyy.", "yryyysyyyry.", "yyyyyyyyyyy.", "bbbbbbbbbbb.", "............", "............", "............"],
	"quick": ["......yyy...", ".....yyy....", "....yyy.....", "...yyy......", "..yyyyyyy...", "......yyy...", ".....yyy....", "....yyy.....", "...yy.......", "..y.........", "............", "............"],
	"market": ["............", "........y...", "........yy..", "yyyyyyyyyyy.", "........yy..", "........y...", "...s........", "..ss........", ".sssssssssss", "..ss........", "...s........", "............"],
	"staff": ["....kddk....", "..ddkddkdd..", "..dwwwwwwd..", "..dwkkkwwd..", "..dwwwwwwd..", "..dwkkkkwd..", "..dwwwwwwd..", "..dwkkwwwd..", "..dwwwwwwd..", "..dwkkkkwd..", "..dddddddd..", "............"],
	"money": ["...oooooo...", "..oyyyyyyo..", ".oyyyyyyyyo.", ".oyywyyyyyo.", ".oyywyyyyyo.", ".oyywyyyyyo.", ".oyyyyyyyyo.", ".oyyyyyyyyo.", "..oyyyyyyo..", "...oooooo...", "............", "............"],
	"medal": ["..rr....ss..", "...rr..ss...", "....rrss....", ".....rs.....", "....yyyy....", "...yyyyyy...", "..yyywyyyy..", "..yyyyyyyy..", "..yyyyyyyy..", "...yyyyyy...", "....yyyy....", "............"],
	"book": ["............", ".ssssssssss.", ".swwwsswwws.", ".swkksskkws.", ".swwwsswwws.", ".swkksskkws.", ".swwwsswwws.", ".swkksskkws.", ".swwwsswwws.", ".ssssssssss.", "............", "............"],
	"cog": [".....dd.....", "..d..dd..d..", "...dddddd...", "..dddddddd..", "ddddd..ddddd", "dddd....dddd", "dddd....dddd", "ddddd..ddddd", "..dddddddd..", "...dddddd...", "..d..dd..d..", ".....dd....."],
	"exit": ["..dddddddd..", "..d......d..", "..d......d..", "..d...r..d..", "..d..rr..d..", "rrrrrrr..d..", "rrrrrrr..d..", "..d..rr..d..", "..d...r..d..", "..d......d..", "..dddddddd..", "............"],
	"calendar": ["..r....r....", "rrrrrrrrrrr.", "rrrrrrrrrrr.", "wwwwwwwwwww.", "wkwkwkwkwkw.", "wwwwwwwwwww.", "wkwkwrwkwkw.", "wwwwwwwwwww.", "wkwkwkwkwkw.", "wwwwwwwwwww.", "............", "............"],
	"mail": ["............", "wwwwwwwwwwww", "wdwwwwwwwwdw", "wwdwwwwwwdww", "wwwdwwwwdwww", "wwwwdwwdwwww", "wwwwwddwwwww", "wwwwwwwwwwww", "wwwwwwwwwwww", "............", "............", "............"],
	"board": ["............", "....bbbb....", "....b..b....", "bbbbbbbbbbbb", "bbbbbbbbbbbb", "bbbbbyybbbbb", "kkkkkyykkkkk", "bbbbbbbbbbbb", "bbbbbbbbbbbb", "bbbbbbbbbbbb", "............", "............"],
	"ball": ["....oooo....", "..oooooooo..", ".oowwoooooo.", ".owwooooooo.", "oooooooooooo", "oooooooooooo", "oooooooooooo", "oooooooooooo", ".oooooooooo.", ".oooooooooo.", "..oooooooo..", "....oooo...."],
	"flag": ["d...........", "drrrrrrrrr..", "dryyrrrrrr..", "dryyrrrrrr..", "drrrrrrrrr..", "drrrrrrrrr..", "d...........", "d...........", "d...........", "d...........", "d...........", "dd.........."],
	"eye": ["............", "............", "...dddddd...", "..dwwwwwwd..", ".dwwwsswwwd.", "dwwwskkswwwd", "dwwwskkswwwd", ".dwwwsswwwd.", "..dwwwwwwd..", "...dddddd...", "............", "............"],
	"wrench": ["........dd..", ".......d..d.", ".......d..d.", "......dd.d..", ".....ddd....", "....ddd.....", "...ddd......", "..ddd.......", ".ddd........", "ddd.........", "dd..........", "............"],
	"mic": ["....dddd....", "...dwwwwd...", "...dwkwkd...", "...dwwwwd...", "...dwkwkd...", "....dddd....", "..d..dd..d..", "...d.dd.d...", "....dddd....", ".....dd.....", "....dddd....", "............"],
	"cross": ["............", "....rrrr....", "....rrrr....", "....rrrr....", ".rrrrrrrrrr.", ".rrrrrrrrrr.", ".rrrrrrrrrr.", ".rrrrrrrrrr.", "....rrrr....", "....rrrr....", "....rrrr....", "............"],
	"sprout": ["............", "..gg....gg..", ".gggg..gggg.", ".ggggggggg..", "..gg.gg.gg..", ".....gg.....", ".....gg.....", ".....gg.....", "...bbbbbb...", "...bbbbbb...", "....bbbb....", "............"],
	"person": ["............", "....ssss....", "...ssssss...", "...ssssss...", "....ssss....", "............", "..ssssssss..", ".ssssssssss.", ".ssssssssss.", ".ssssssssss.", ".ssssssssss.", "............"],
	"club": ["..wwwwwwww..", ".wrrrrrrrrw.", ".wrrwwwwrrw.", ".wrrwrrrrrw.", ".wrrwrrrrrw.", ".wrrwwwwrrw.", ".wrrrrrrrrw.", "..wrrrrrrw..", "...wrrrrw...", "....wrrw....", ".....ww.....", "............"],
	"door": ["..ssssssss..", "..s......s..", "..s......s..", "..s......s..", "..s......s..", "..s....y.s..", "..s......s..", "..s......s..", "..s......s..", "..s......s..", "..ssssssss..", "............"],
	"bell": ["............", ".....yy.....", "....yyyy....", "...yyyyyy...", "...yyyyyy...", "...yyyyyy...", "..yyyyyyyy..", "..yyyyyyyy..", ".yyyyyyyyyy.", "............", ".....yy.....", "............"],
	"star": [".....yy.....", ".....yy.....", "....yyyy....", "yyyyyyyyyyyy", ".yyyyyyyyyy.", "..yyyyyyyy..", "...yyyyyy...", "...yyyyyy...", "..yyy..yyy..", "..yy....yy..", ".y........y.", "............"],
	"battery": ["............", "............", "............", "dddddddddd..", "d........d..", "d.gg.gg..dd.", "d.gg.gg..dd.", "d........d..", "dddddddddd..", "............", "............", "............"],
	"play": ["............", "..w.........", "..ww........", "..www.......", "..wwww......", "..wwwww.....", "..wwwww.....", "..wwww......", "..www.......", "..ww........", "..w.........", "............"],
	"left": ["............", "......w.....", ".....ww.....", "....www.....", "...wwww.....", "..wwwww.....", "..wwwww.....", "...wwww.....", "....www.....", ".....ww.....", "......w.....", "............"],
	"right": ["............", ".....w......", ".....ww.....", ".....www....", ".....wwww...", ".....wwwww..", ".....wwwww..", ".....wwww...", ".....www....", ".....ww.....", ".....w......", "............"],
	"sw_y": ["............", "............", "............", "...yyyyyy...", "...yyyyyy...", "...yyyyyy...", "...yyyyyy...", "...yyyyyy...", "...yyyyyy...", "............", "............", "............"],
	"sw_s": ["............", "............", "............", "............", "............", "ssssssssssss", "ssssssssssss", "............", "............", "............", "............", "............"],
	"arrow": ["............", "............", "......s.....", "......ss....", "......sss...", "ssssssssss..", "ssssssssss..", "......sss...", "......ss....", "......s.....", "............", "............"],
	"chat": ["............", ".wwwwwwwwww.", "wwwwwwwwwwww", "wwkkwwkkwwkw", "wwwwwwwwwwww", "wwwwwwwwwwww", ".wwwwwwwwww.", "...ww.......", "..ww........", ".w..........", "............", "............"],
	"min": ["............", "............", "............", "............", "............", ".wwwwwwwwww.", ".wwwwwwwwww.", "............", "............", "............", "............", "............"],
}
static var _cache := {}


## The icon `name` at `scale` x (2 = 28 px), finished like pixel art: a dark
## one-pixel outline round the shape, each colour lit along its top / left edge
## and shaded along its bottom / right.
static func get_icon(name: String, scale := 2) -> ImageTexture:
	var key := name + "@" + str(scale)
	if _cache.has(key):
		return _cache[key]
	var rows: Array = PIX.get(name, PIX["star"])
	var n := 14                      # the 12-pixel glyph with room for its outline
	var px := []                     # n * n colours, null = see-through
	px.resize(n * n)
	for y in 12:
		var row: String = rows[y]
		for x in 12:
			if row[x] != ".":
				px[(y + 1) * n + x + 1] = PAL[row[x]]
	var out := px.duplicate()
	var ink := Color(0.03, 0.035, 0.07)
	for y in n:
		for x in n:
			var c = px[y * n + x]
			if c == null:
				# outline: any of the 8 neighbours is part of the shape
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var xx: int = x + dx
						var yy: int = y + dy
						if xx >= 0 and yy >= 0 and xx < n and yy < n and px[yy * n + xx] != null:
							out[y * n + x] = ink
				continue
			var col: Color = c
			var up = px[(y - 1) * n + x] if y > 0 else null
			var left = px[y * n + x - 1] if x > 0 else null
			var down = px[(y + 1) * n + x] if y < n - 1 else null
			var right = px[y * n + x + 1] if x < n - 1 else null
			# light from the top left: an edge of this colour facing up / left is lit,
			# one facing down / right is in shade
			if (down == null or down != c) or (right == null or right != c):
				col = col.darkened(0.22)
			elif (up == null or up != c) or (left == null or left != c):
				col = col.lightened(0.18)
			out[y * n + x] = col
	var img := Image.create(n * scale, n * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in n:
		for x in n:
			if out[y * n + x] != null:
				img.fill_rect(Rect2i(x * scale, y * scale, scale, scale), out[y * n + x])
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## The coach's tablet as a pixel-art nine-patch: a 1-px dark outline, the bezel
## with stepped (not rounded) corners, a lit top-left bevel, a shaded bottom-right,
## and the dark screen inside. Drawn on a 32-px grid at 2x; the bezel is
## FRAME_EDGE grid pixels wide, which is also the nine-patch margin.
const FRAME_EDGE := 11

static func tablet_frame() -> ImageTexture:
	if _cache.has("tablet"):
		return _cache["tablet"]
	var n := 32
	var sc := 2
	var outline := Color(0.02, 0.02, 0.04)
	var body := Color(0.15, 0.16, 0.21)
	var lit := Color(0.27, 0.29, 0.36)
	var shade := Color(0.09, 0.10, 0.13)
	var rim := Color(0.03, 0.035, 0.06)
	var screen := Color(0.045, 0.055, 0.11)
	var img := Image.create(n * sc, n * sc, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in n:
		for x in n:
			var layer := _frame_layer(x, y, n)
			if layer < 0:
				continue
			var ry := mini(y, n - 1 - y)
			var rx := mini(x, n - 1 - x)
			var col := body
			if layer == 0:
				col = outline
			elif layer == 1:
				# light from the top left, shade bottom right
				var top_left := (y < n / 2 and ry <= rx) or (x < n / 2 and rx <= ry)
				col = lit if top_left else shade
			elif layer >= FRAME_EDGE:
				col = screen
			elif layer == FRAME_EDGE - 1:
				col = rim                      # the screen's sunken edge
			img.fill_rect(Rect2i(x * sc, y * sc, sc, sc), col)
	var tex := ImageTexture.create_from_image(img)
	_cache["tablet"] = tex
	return tex


## How many pixels in from the frame's outer edge (x, y) is; -1 outside it. Only
## the outside corners are cut, in steps; the outline and bevel follow the steps.
static func _frame_layer(x: int, y: int, n: int) -> int:
	var cut := [4, 2, 1, 1]
	var ry := mini(y, n - 1 - y)
	var rx := mini(x, n - 1 - x)
	var c := -1
	if ry < cut.size():
		c = int(cut[ry])
	if rx < c:
		return -1
	if ry < cut.size() and rx < int(cut[ry]) + 1:
		return 0                     # the stepped edge of the corner
	if rx < cut.size() and ry < int(cut[rx]) + 1:
		return 0
	if ry < cut.size() and rx < int(cut[ry]) + 2 or rx < cut.size() and ry < int(cut[rx]) + 2:
		return 1
	return mini(rx, ry)
