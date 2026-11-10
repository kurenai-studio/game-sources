class_name QRReader
extends RefCounted
## Reads a QR code out of a camera picture, so a second tablet can join a
## game by pointing its camera at the code on the host's PLAY TOGETHER screen
## (ui/qr_scanner.gd). Plain GDScript, so the same code runs on the tablet and
## in the tests. (Reggie's Neon Adventure's reader, as is.)
##
## The steps are the standard's, and the usual readers' (zxing):
##   1. light and dark: each pixel against the average round it, so uneven
##      light, glare and a screen's own glow don't matter;
##   2. the three finder squares, by their 1:1:3:1:1 stripes across and down;
##   3. which corner is which, how many modules across, and (from version 2)
##      where the small alignment square is, for a perspective map from
##      modules to pixels;
##   4. the format bits (error level and mask), the codewords, Reed-Solomon
##      to mend the ones the camera got wrong, and the text.
## Versions 1 to 6 at error level M (what ui/qr.gd makes); byte,
## alphanumeric and numeric text.

const MAX_SIDE := 480            ## pictures are shrunk to this first: plenty for a code that fills a fair part of it

## version -> [data codewords, error correction codewords per block, blocks] (level M)
const BLOCKS := QR.BLOCKS


## The text in the code in this picture, or "" if there isn't one it can read.
static func read(img: Image) -> String:
	if img == null or img.is_empty() or img.is_compressed():
		return ""
	var gray: Image
	if img.get_format() == Image.FORMAT_R8:
		# a camera's light-and-dark picture comes as red only: that is the brightness
		gray = Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_L8, img.get_data())
	else:
		gray = img.duplicate()
		gray.convert(Image.FORMAT_L8)
	var side := maxi(gray.get_width(), gray.get_height())
	var text := _read_at(gray, mini(side, MAX_SIDE))
	if text == "" and _small and side > MAX_SIDE:
		# a code far off: look again, closer up
		text = _read_at(gray, mini(side, MAX_SIDE * 2))
	return text


static var _small := false       ## the last look found finder squares, but tiny ones


static func _read_at(gray: Image, side: int) -> String:
	var g: Image = gray.duplicate()
	var w := g.get_width()
	var h := g.get_height()
	var k := float(side) / float(maxi(w, h))
	if k < 1.0:
		w = maxi(8, int(w * k))
		h = maxi(8, int(h * k))
		g.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var bits := binarize(g)
	_small = false
	var text := _find(bits, w, h)
	if text == "":
		# a camera facing you sees the code back to front
		var flipped := PackedByteArray()
		flipped.resize(bits.size())
		for y in h:
			var row := y * w
			for x in w:
				flipped[row + x] = bits[row + w - 1 - x]
		text = _find(flipped, w, h)
	return text


# -- 1. light and dark ------------------------------------------------------------------------

## 1 for dark, 0 for light: darker than the average of the patch round it.
## The averages come from the engine (halving the picture again and again,
## each time averaging squares of four, then stretching it back smoothly),
## which is much quicker than adding them up here.
static func binarize(g: Image) -> PackedByteArray:
	var w := g.get_width()
	var h := g.get_height()
	var m: Image = g.duplicate()
	while maxi(m.get_width(), m.get_height()) > 16 and mini(m.get_width(), m.get_height()) > 4:
		m.shrink_x2()
	m.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var lum := g.get_data()
	var mean := m.get_data()
	var out := PackedByteArray()
	out.resize(w * h)
	for i in w * h:
		out[i] = 1 if lum[i] * 100 < mean[i] * 88 else 0
	return out


# -- 2. the finder squares ------------------------------------------------------------------

## Stripes of dark, light, dark, light, dark in the ratio 1:1:3:1:1?
static func _ratio_ok(c: Array) -> bool:
	var total := 0
	for v in c:
		if int(v) == 0:
			return false
		total += int(v)
	if total < 7:
		return false
	var m := total / 7.0
	var slack := m * 0.7
	return absf(m - c[0]) < slack and absf(m - c[1]) < slack and absf(3.0 * m - c[2]) < 3.0 * slack \
		and absf(m - c[3]) < slack and absf(m - c[4]) < slack


## Walk from (cx, cy) both ways along (dx, dy) through the stripes. Returns
## [centre along the line, total length] or [] if it isn't a finder there.
static func _cross(bits: PackedByteArray, w: int, h: int, cx: int, cy: int, dx: int, dy: int, most: int) -> Array:
	var c := [0, 0, 0, 0, 0]
	var x := cx
	var y := cy
	var dark := func(px: int, py: int) -> bool: return bits[py * w + px] == 1
	if x < 0 or y < 0 or x >= w or y >= h or not dark.call(x, y):
		return []
	while x >= 0 and y >= 0 and x < w and y < h and dark.call(x, y):
		c[2] += 1
		x -= dx
		y -= dy
	if x < 0 or y < 0 or x >= w or y >= h:
		return []
	while x >= 0 and y >= 0 and x < w and y < h and not dark.call(x, y) and c[1] <= most:
		c[1] += 1
		x -= dx
		y -= dy
	if x < 0 or y < 0 or x >= w or y >= h or c[1] > most:
		return []
	while x >= 0 and y >= 0 and x < w and y < h and dark.call(x, y) and c[0] <= most:
		c[0] += 1
		x -= dx
		y -= dy
	if c[0] > most:
		return []
	x = cx + dx
	y = cy + dy
	while x >= 0 and y >= 0 and x < w and y < h and dark.call(x, y):
		c[2] += 1
		x += dx
		y += dy
	if x < 0 or y < 0 or x >= w or y >= h:
		return []
	while x >= 0 and y >= 0 and x < w and y < h and not dark.call(x, y) and c[3] < most:
		c[3] += 1
		x += dx
		y += dy
	if x < 0 or y < 0 or x >= w or y >= h or c[3] >= most:
		return []
	while x >= 0 and y >= 0 and x < w and y < h and dark.call(x, y) and c[4] < most:
		c[4] += 1
		x += dx
		y += dy
	if c[4] >= most or not _ratio_ok(c):
		return []
	var end := (x if dx != 0 else y)
	var total: int = c[0] + c[1] + c[2] + c[3] + c[4]
	return [float(end) - c[4] - c[3] - c[2] / 2.0, total]


## Every finder square in the picture: [x, y, module size, times seen].
static func finders(bits: PackedByteArray, w: int, h: int) -> Array:
	var found: Array = []
	for y in range(0, h, 2):   # every other row is plenty: a finder's middle is three modules tall
		var c := [0, 0, 0, 0, 0]
		var state := 0
		var row := y * w
		for x in w + 1:
			var dark := x < w and bits[row + x] == 1
			if dark:
				if state & 1 == 1:
					state += 1
				c[state] += 1
			elif state & 1 == 0:
				if state == 4:
					if _ratio_ok(c):
						var total: int = c[0] + c[1] + c[2] + c[3] + c[4]
						var cx: float = float(x) - c[4] - c[3] - c[2] / 2.0
						_confirm(bits, w, h, cx, y, total, found)
					# slide on two stripes: the end of this could start the next
					c = [c[2], c[3], c[4], 1, 0]
					state = 3
				elif c[state] > 0:
					state += 1
					c[state] += 1
			else:
				c[state] += 1
	return found


## Check a possible finder down and then across again; keep it if it holds.
static func _confirm(bits: PackedByteArray, w: int, h: int, cx: float, cy: int, total: int, found: Array) -> void:
	var down := _cross(bits, w, h, int(cx), cy, 0, 1, total)
	if down.is_empty() or absf(float(down[1]) - total) * 5.0 >= total * 3.0:
		return
	var y: float = down[0]
	var across := _cross(bits, w, h, int(cx), int(y), 1, 0, total)
	if across.is_empty():
		return
	var x: float = across[0]
	var module := (float(across[1]) + float(down[1])) / 14.0
	for f in found:
		if absf(f[0] - x) <= module * 2.0 and absf(f[1] - y) <= module * 2.0 and absf(f[2] - module) <= maxf(1.0, module * 0.6):
			var n: int = f[3]
			f[0] = (f[0] * n + x) / (n + 1)
			f[1] = (f[1] * n + y) / (n + 1)
			f[2] = (f[2] * n + module) / (n + 1)
			f[3] = n + 1
			return
	found.append([x, y, module, 1])


## Try the likeliest three finders as a code's corners.
static func _find(bits: PackedByteArray, w: int, h: int) -> String:
	var all := finders(bits, w, h)
	for f in all:
		if float(f[2]) < 3.2:
			_small = true
	if all.size() < 3:
		return ""
	all.sort_custom(func(a, b): return int(a[3]) > int(b[3]))
	all = all.slice(0, 6)
	var tries: Array = []
	for i in all.size():
		for j in range(i + 1, all.size()):
			for k in range(j + 1, all.size()):
				var t := [all[i], all[j], all[k]]
				var ms: Array = t.map(func(f): return float(f[2]))
				var mmax: float = ms.max()
				var mmin: float = ms.min()
				if mmin <= 0.0 or mmax / mmin > 1.6:
					continue
				tries.append([_shape_score(t), t])
	tries.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	for t in tries.slice(0, 6):
		var text := _read_three(bits, w, h, t[1])
		if text != "":
			return text
	return ""


## How unlike a right-angled corner with equal arms these three are (0 is perfect).
static func _shape_score(t: Array) -> float:
	var p: Array = t.map(func(f): return Vector2(f[0], f[1]))
	var best := INF
	for i in 3:
		var a: Vector2 = p[i]
		var b: Vector2 = p[(i + 1) % 3]
		var c: Vector2 = p[(i + 2) % 3]
		var u := b - a
		var v := c - a
		if u.length() < 1.0 or v.length() < 1.0:
			continue
		var cosang := absf(u.normalized().dot(v.normalized()))
		var arms := absf(u.length() - v.length()) / maxf(u.length(), v.length())
		best = minf(best, cosang + arms)
	return best


# -- 3. corners, size and the map from modules to pixels -----------------------------------

static func _read_three(bits: PackedByteArray, w: int, h: int, t: Array) -> String:
	var p: Array = t.map(func(f): return Vector2(f[0], f[1]))
	# the corner one is opposite the longest side
	var d01: float = (p[0] as Vector2).distance_to(p[1])
	var d12: float = (p[1] as Vector2).distance_to(p[2])
	var d02: float = (p[0] as Vector2).distance_to(p[2])
	var a: Vector2
	var b: Vector2
	var c: Vector2
	if d12 >= d01 and d12 >= d02:
		a = p[0]; b = p[1]; c = p[2]
	elif d02 >= d01:
		a = p[1]; b = p[0]; c = p[2]
	else:
		a = p[2]; b = p[0]; c = p[1]
	if (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x) < 0.0:
		var s := b
		b = c
		c = s
	var module := (float(t[0][2]) + float(t[1][2]) + float(t[2][2])) / 3.0
	# the module size measured along the code's own edges (straight across a
	# finder would be too wide if the code is turned)
	var mab := _module_between(bits, w, h, a, b)
	var mac := _module_between(bits, w, h, a, c)
	if mab > 0.0 and mac > 0.0:
		module = (mab + mac) / 2.0
	var est := int(round((a.distance_to(b) / (mab if mab > 0.0 else module) + a.distance_to(c) / (mac if mac > 0.0 else module)) / 2.0)) + 7
	var dims: Array = []
	match est % 4:
		1: dims = [est, est - 4, est + 4]
		0: dims = [est + 1, est - 3]
		2: dims = [est - 1, est + 3]
		3: dims = [est - 2, est + 2]
	for dim in dims:
		var version := (int(dim) - 17) / 4
		if version < 1 or version > 6:
			continue
		var text := _read_grid(bits, w, h, a, b, c, int(dim), module)
		if text != "":
			return text
	return ""


## A module's size, from the finder squares at p and q: from each centre out
## through dark, light, dark to the edge is three and a half modules.
static func _module_between(bits: PackedByteArray, w: int, h: int, p: Vector2, q: Vector2) -> float:
	var d := (q - p).normalized()
	var sizes: Array = []
	for pair in [[p, d], [p, -d], [q, -d], [q, d]]:
		var r := _edge_run(bits, w, h, pair[0], pair[1])
		if r > 0.0:
			sizes.append(r / 3.5)
	if sizes.size() < 2:
		return -1.0
	var total := 0.0
	for v in sizes:
		total += float(v)
	return total / sizes.size()


static func _edge_run(bits: PackedByteArray, w: int, h: int, from: Vector2, dir: Vector2) -> float:
	var state := 0       # 0 the dark middle, 1 the light ring, 2 the dark ring
	var t := 0.0
	while t < 200.0:
		var pt := from + dir * t
		var x := int(round(pt.x))
		var y := int(round(pt.y))
		if x < 0 or y < 0 or x >= w or y >= h:
			return -1.0
		var dark := bits[y * w + x] == 1
		if state == 0 and not dark:
			state = 1
		elif state == 1 and dark:
			state = 2
		elif state == 2 and not dark:
			return t
		t += 0.5
	return -1.0


static func _read_grid(bits: PackedByteArray, w: int, h: int, a: Vector2, b: Vector2, c: Vector2, dim: int, module: float) -> String:
	var span := float(dim - 7)
	var ex := (b - a) / span
	var ey := (c - a) / span
	var affine := func(u: float, v: float) -> Vector2: return a + (u - 3.5) * ex + (v - 3.5) * ey
	var src := [Vector2(3.5, 3.5), Vector2(dim - 3.5, 3.5), Vector2(3.5, dim - 3.5)]
	var dst := [a, b, c]
	var fourth_m := Vector2(dim - 3.5, dim - 3.5)
	var fourth: Vector2 = affine.call(dim - 3.5, dim - 3.5)
	if dim >= 25:
		# the alignment square near the far corner pins the perspective
		var am := Vector2(dim - 6.5, dim - 6.5)
		var guess: Vector2 = affine.call(am.x, am.y)
		var found := _alignment(bits, w, h, guess, ex, ey, module)
		if found != Vector2.INF:
			fourth_m = am
			fourth = found
	src.append(fourth_m)
	dst.append(fourth)
	var hm := _homography(src, dst)
	if hm.is_empty():
		return ""
	var grid: Array = []
	for y in dim:
		var row: Array = []
		row.resize(dim)
		for x in dim:
			var q := _apply(hm, x + 0.5, y + 0.5)
			row[x] = _sample(bits, w, h, q, module < 4.5)
		grid.append(row)
	return decode_grid(grid)


## Dark if most of the pixels at and round p are dark.
const AROUND := [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]


static func _sample(bits: PackedByteArray, w: int, h: int, p: Vector2, small := false) -> bool:
	var px := int(round(p.x))
	var py := int(round(p.y))
	var n := 0
	var dark := 0
	# small modules: the middle pixel and the four touching it; bigger, the 3 x 3
	for k in (5 if small else 9):
		var o: Vector2i = AROUND[k]
		var x: int = px + o.x
		var y: int = py + o.y
		if x < 0 or y < 0 or x >= w or y >= h:
			continue
		n += 1
		dark += bits[y * w + x]
	return n > 0 and dark * 2 > n


## The alignment square (dark centre, light ring, dark ring) near guess.
static func _alignment(bits: PackedByteArray, w: int, h: int, guess: Vector2, ex: Vector2, ey: Vector2, module: float) -> Vector2:
	var r := int(ceil(module * 4.0))
	var best := Vector2.INF
	var best_score := 21
	for oy in range(-r, r + 1):
		for ox in range(-r, r + 1):
			var q := guess + Vector2(ox, oy)
			var score := 0
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var s := q + ex * dx + ey * dy
					var x := int(round(s.x))
					var y := int(round(s.y))
					if x < 0 or y < 0 or x >= w or y >= h:
						continue
					var want := 0 if maxi(absi(dx), absi(dy)) == 1 else 1
					if bits[y * w + x] == want:
						score += 1
			if score > best_score or (score == best_score and best != Vector2.INF and q.distance_to(guess) < best.distance_to(guess)):
				best_score = score
				best = q
	return best


## The perspective map taking four points to four others (3 x 3, h[8] = 1).
static func _homography(src: Array, dst: Array) -> PackedFloat64Array:
	var m: Array = []
	for i in 4:
		var s: Vector2 = src[i]
		var d: Vector2 = dst[i]
		m.append([s.x, s.y, 1.0, 0.0, 0.0, 0.0, -d.x * s.x, -d.x * s.y, d.x])
		m.append([0.0, 0.0, 0.0, s.x, s.y, 1.0, -d.y * s.x, -d.y * s.y, d.y])
	# Gaussian elimination with partial pivoting on the 8 x 9 system
	for col in 8:
		var piv := col
		for r in range(col + 1, 8):
			if absf(m[r][col]) > absf(m[piv][col]):
				piv = r
		if absf(m[piv][col]) < 1e-9:
			return PackedFloat64Array()
		var tmp: Array = m[col]
		m[col] = m[piv]
		m[piv] = tmp
		for r in 8:
			if r == col:
				continue
			var f: float = m[r][col] / m[col][col]
			if f == 0.0:
				continue
			for k in range(col, 9):
				m[r][k] -= f * m[col][k]
	var out := PackedFloat64Array()
	for r in 8:
		out.append(m[r][8] / m[r][r])
	out.append(1.0)
	return out


static func _apply(hm: PackedFloat64Array, u: float, v: float) -> Vector2:
	var z := hm[6] * u + hm[7] * v + hm[8]
	return Vector2((hm[0] * u + hm[1] * v + hm[2]) / z, (hm[3] * u + hm[4] * v + hm[5]) / z)


# -- 4. format, codewords, mending and text -------------------------------------------------

## Read a grid of modules (rows of bools, true is dark) that's the right way
## up. Returns the text, or "".
static func decode_grid(grid: Array) -> String:
	var size := grid.size()
	var version := (size - 17) / 4
	if version < 1 or version > 6 or size != version * 4 + 17:
		return ""
	var g := func(x: int, y: int) -> int: return 1 if grid[y][x] else 0
	var f1 := 0
	for i in 6:
		f1 |= g.call(8, i) << i
	f1 |= g.call(8, 7) << 6
	f1 |= g.call(8, 8) << 7
	f1 |= g.call(7, 8) << 8
	for i in range(9, 15):
		f1 |= g.call(14 - i, 8) << i
	var f2 := 0
	for i in 8:
		f2 |= g.call(size - 1 - i, 8) << i
	for i in range(8, 15):
		f2 |= g.call(8, size - 15 + i) << i
	var best := -1
	var best_d := 99
	for f in 32:
		var rem := f
		for i in 10:
			rem = (rem << 1) ^ ((rem >> 9) * 0x537)
		var code := ((f << 10) | rem) ^ 0x5412
		var d := mini(_bit_count(code ^ f1), _bit_count(code ^ f2))
		if d < best_d:
			best_d = d
			best = f
	if best < 0 or best_d > 3 or (best >> 3) != QR.LEVEL_M:
		return ""
	var mask := best & 7
	var q := QR._blank(size)
	QR._draw_patterns(q[0], q[1], version)
	var fixed: Array = q[1]
	var spec: Array = BLOCKS[version]
	var n_blocks: int = spec[2]
	var ecc_len: int = spec[1]
	var data_len: int = spec[0]
	var total := data_len + ecc_len * n_blocks
	# the codewords, in the order the code lays them down, unmasked
	var cw := PackedByteArray()
	cw.resize(total)
	cw.fill(0)
	var i := 0
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var upward := ((right + 1) & 2) == 0
				var y := size - 1 - vert if upward else vert
				if fixed[y][x] or i >= total * 8:
					continue
				var bit: int = g.call(x, y)
				if _masked(mask, x, y):
					bit ^= 1
				if bit == 1:
					cw[i >> 3] |= 1 << (7 - (i & 7))
				i += 1
		right -= 2
	# untangle the blocks, mend each, and join their data back up
	var per := data_len / n_blocks
	var data := PackedByteArray()
	for b in n_blocks:
		var block := PackedByteArray()
		for k in per:
			block.append(cw[k * n_blocks + b])
		for k in ecc_len:
			block.append(cw[data_len + k * n_blocks + b])
		var fixed_block := rs_correct(block, ecc_len)
		if fixed_block.is_empty():
			return ""
		data.append_array(fixed_block.slice(0, per))
	return _text(data, version)


static func _masked(mask: int, x: int, y: int) -> bool:
	match mask:
		0: return (x + y) % 2 == 0
		1: return y % 2 == 0
		2: return x % 3 == 0
		3: return (x + y) % 3 == 0
		4: return (x / 3 + y / 2) % 2 == 0
		5: return x * y % 2 + x * y % 3 == 0
		6: return (x * y % 2 + x * y % 3) % 2 == 0
		7: return ((x + y) % 2 + x * y % 3) % 2 == 0
	return false


static func _bit_count(v: int) -> int:
	var n := 0
	while v != 0:
		n += v & 1
		v >>= 1
	return n


## The text from the data codewords: byte, alphanumeric or numeric segments.
static func _text(data: PackedByteArray, version: int) -> String:
	var pos := [0]
	var nbits := data.size() * 8
	var take := func(n: int) -> int:
		var v := 0
		for k in n:
			var p: int = pos[0]
			v = (v << 1) | ((data[p >> 3] >> (7 - (p & 7))) & 1)
			pos[0] = p + 1
		return v
	var out := PackedByteArray()
	const ALNUM := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
	while int(pos[0]) + 4 <= nbits:
		var mode: int = take.call(4)
		if mode == 0:
			break
		if mode == 4:
			if int(pos[0]) + 8 > nbits:
				return ""
			var n: int = take.call(8)
			if int(pos[0]) + n * 8 > nbits:
				return ""
			for k in n:
				out.append(take.call(8))
		elif mode == 2:
			var n: int = take.call(9)
			while n >= 2:
				var v: int = take.call(11)
				out.append(ALNUM.unicode_at(v / 45))
				out.append(ALNUM.unicode_at(v % 45))
				n -= 2
			if n == 1:
				out.append(ALNUM.unicode_at(take.call(6)))
		elif mode == 1:
			var n: int = take.call(10)
			while n >= 3:
				var s := "%03d" % take.call(10)
				out.append_array(s.to_utf8_buffer())
				n -= 3
			if n == 2:
				out.append_array(("%02d" % take.call(7)).to_utf8_buffer())
			elif n == 1:
				out.append_array(str(take.call(4)).to_utf8_buffer())
		elif mode == 7:
			take.call(8)   # an ECI marker: the text's character set; it's UTF-8 or close enough
		else:
			break
	return out.get_string_from_utf8()


# -- Reed-Solomon over GF(256), the QR way (0x11D, first root 1) -----------------------------

static var _exp := PackedInt32Array()
static var _log := PackedInt32Array()


static func _tables() -> void:
	if not _exp.is_empty():
		return
	_exp.resize(512)
	_log.resize(256)
	var x := 1
	for i in 255:
		_exp[i] = x
		_log[x] = i
		x <<= 1
		if x & 0x100:
			x ^= 0x11D
	for i in range(255, 512):
		_exp[i] = _exp[i - 255]


static func _mul(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return _exp[_log[a] + _log[b]]


static func _div(a: int, b: int) -> int:
	if a == 0:
		return 0
	return _exp[(_log[a] + 255 - _log[b]) % 255]


static func _pow(a: int, n: int) -> int:
	return _exp[posmod(_log[a] * n, 255)]


static func _inv(a: int) -> int:
	return _exp[255 - _log[a]]


static func _poly_eval(p: Array, x: int) -> int:
	var y: int = p[0]
	for i in range(1, p.size()):
		y = _mul(y, x) ^ int(p[i])
	return y


static func _poly_scale(p: Array, x: int) -> Array:
	return p.map(func(c): return _mul(int(c), x))


static func _poly_add(p: Array, q: Array) -> Array:
	var n := maxi(p.size(), q.size())
	var r: Array = []
	r.resize(n)
	r.fill(0)
	for i in p.size():
		r[i + n - p.size()] = int(p[i])
	for i in q.size():
		r[i + n - q.size()] ^= int(q[i])
	return r


static func _poly_mul(p: Array, q: Array) -> Array:
	var r: Array = []
	r.resize(p.size() + q.size() - 1)
	r.fill(0)
	for j in q.size():
		for i in p.size():
			r[i + j] ^= _mul(int(p[i]), int(q[j]))
	return r


## Mend up to ecc/2 wrong codewords in a block (data then error codewords).
## Returns the mended block, or an empty one if it's beyond mending.
static func rs_correct(block: PackedByteArray, ecc: int) -> PackedByteArray:
	_tables()
	var msg: Array = Array(block)
	var synd: Array = [0]
	var clean := true
	for i in ecc:
		var s := _poly_eval(msg, _pow(2, i))
		synd.append(s)
		if s != 0:
			clean = false
	if clean:
		return block
	# Berlekamp-Massey: the error locator
	var err_loc: Array = [1]
	var old_loc: Array = [1]
	for i in ecc:
		var k := i + 1
		var delta: int = synd[k]
		for j in range(1, err_loc.size()):
			delta ^= _mul(int(err_loc[err_loc.size() - 1 - j]), int(synd[k - j]))
		old_loc.append(0)
		if delta != 0:
			if old_loc.size() > err_loc.size():
				var new_loc := _poly_scale(old_loc, delta)
				old_loc = _poly_scale(err_loc, _inv(delta))
				err_loc = new_loc
			err_loc = _poly_add(err_loc, _poly_scale(old_loc, delta))
	while not err_loc.is_empty() and int(err_loc[0]) == 0:
		err_loc.remove_at(0)
	var errs := err_loc.size() - 1
	if errs * 2 > ecc:
		return PackedByteArray()
	# where they are (Chien search)
	var rev := err_loc.duplicate()
	rev.reverse()
	var n := msg.size()
	var pos: Array = []
	for i in n:
		if _poly_eval(rev, _pow(2, i)) == 0:
			pos.append(n - 1 - i)
	if pos.size() != errs:
		return PackedByteArray()
	# how big they are (Forney)
	var coef: Array = pos.map(func(p): return n - 1 - int(p))
	var loc: Array = [1]
	for c in coef:
		loc = _poly_mul(loc, _poly_add([1], [_pow(2, int(c)), 0]))
	var s_rev := synd.duplicate()
	s_rev.reverse()
	var prod := _poly_mul(s_rev, loc)
	var keep := loc.size()             # remainder mod x^(errs+1)
	var ev: Array = prod.slice(prod.size() - keep) if prod.size() >= keep else prod
	var xs: Array = coef.map(func(c): return _pow(2, posmod(-(255 - int(c)), 255)))
	var e: Array = []
	e.resize(n)
	e.fill(0)
	for i in xs.size():
		var xi: int = xs[i]
		var xi_inv := _inv(xi)
		var prime := 1
		for j in xs.size():
			if j != i:
				prime = _mul(prime, 1 ^ _mul(xi_inv, int(xs[j])))
		if prime == 0:
			return PackedByteArray()
		var y := _poly_eval(ev, xi_inv)
		y = _mul(xi, y)
		e[int(pos[i])] = _div(y, prime)
	var fixed := PackedByteArray()
	fixed.resize(n)
	for i in n:
		fixed[i] = int(msg[i]) ^ int(e[i])
	# check the mending worked
	for i in ecc:
		if _poly_eval(Array(fixed), _pow(2, i)) != 0:
			return PackedByteArray()
	return fixed
