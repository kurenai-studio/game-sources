class_name QR
extends RefCounted
## QR codes, for the PLAY TOGETHER screen: a phone's camera reads the game's
## address off the tablet and opens the buttons page.
##
## Byte mode, error correction level M, versions 1 to 6 (up to 106
## characters, plenty for an address on the home Wi-Fi). The mask is the one
## with the lowest penalty, as the standard asks. Follows the layout in ISO/IEC
## 18004; tests/run_tests.gd holds a code checked against a real decoder.

## version -> [data codewords, error correction codewords per block, blocks]
const BLOCKS := {1: [16, 10, 1], 2: [28, 16, 1], 3: [44, 26, 1], 4: [64, 18, 2], 5: [86, 24, 2], 6: [108, 16, 4]}
const ALIGN := {1: [], 2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30], 6: [6, 34]}
const LEVEL_M := 0               ## the format's two bits for level M


## The modules, row by row (true is dark), or [] if the text is too long.
static func encode(text: String) -> Array:
	var data := text.to_utf8_buffer()
	var version := 0
	for v in range(1, 7):
		if data.size() <= int(BLOCKS[v][0]) - 2:
			version = v
			break
	if version == 0:
		return []
	var codewords := _with_ecc(_data_codewords(data, version), version)
	var size := version * 4 + 17
	var best: Array = []
	var best_score := -1
	for mask in 8:
		var q := _blank(size)
		var dark: Array = q[0]
		var fixed: Array = q[1]
		_draw_patterns(dark, fixed, version)
		_place(dark, fixed, codewords)
		_mask(dark, fixed, mask)
		_draw_format(dark, fixed, mask)
		var score := penalty(dark)
		if best_score < 0 or score < best_score:
			best_score = score
			best = dark
	return best


## A picture of the code: black on white, `scale` pixels a module, with the
## quiet margin round it the standard asks for (four modules).
static func image(text: String, scale := 4, quiet := 4) -> Image:
	var m := encode(text)
	if m.is_empty():
		return null
	var n := m.size()
	var side := (n + quiet * 2) * scale
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	for y in n:
		var row: Array = m[y]
		for x in n:
			if row[x]:
				img.fill_rect(Rect2i((x + quiet) * scale, (y + quiet) * scale, scale, scale), Color("24152e"))
	return img


static func _blank(size: int) -> Array:
	var dark: Array = []
	var fixed: Array = []
	for y in size:
		var a: Array = []
		var b: Array = []
		a.resize(size)
		a.fill(false)
		b.resize(size)
		b.fill(false)
		dark.append(a)
		fixed.append(b)
	return [dark, fixed]


static func _put(dark: Array, fixed: Array, x: int, y: int, on: bool) -> void:
	dark[y][x] = on
	fixed[y][x] = true


# -- the data ------------------------------------------------------------------------------

static func _data_codewords(data: PackedByteArray, version: int) -> PackedByteArray:
	var cap: int = BLOCKS[version][0]
	var bits: Array[int] = []
	_bits(bits, 0b0100, 4)                   # byte mode
	_bits(bits, data.size(), 8)
	for b in data:
		_bits(bits, b, 8)
	_bits(bits, 0, mini(4, cap * 8 - bits.size()))   # the terminator
	while bits.size() % 8 != 0:
		bits.append(0)
	var out := PackedByteArray()
	for i in range(0, bits.size(), 8):
		var v := 0
		for k in 8:
			v = (v << 1) | bits[i + k]
		out.append(v)
	var pad := [0xEC, 0x11]
	var k2 := 0
	while out.size() < cap:
		out.append(pad[k2 % 2])
		k2 += 1
	return out


static func _bits(bits: Array[int], value: int, n: int) -> void:
	for i in range(n - 1, -1, -1):
		bits.append((value >> i) & 1)


## Split into blocks, add each block's Reed-Solomon codewords, interleave.
## (Every block is the same length at level M up to version 6.)
static func _with_ecc(data: PackedByteArray, version: int) -> PackedByteArray:
	var spec: Array = BLOCKS[version]
	var n_blocks: int = spec[2]
	var ecc_len: int = spec[1]
	var per := data.size() / n_blocks
	var divisor := _rs_divisor(ecc_len)
	var blocks: Array = []
	var eccs: Array = []
	for i in n_blocks:
		var d := data.slice(i * per, (i + 1) * per)
		blocks.append(d)
		eccs.append(_rs_remainder(d, divisor))
	var out := PackedByteArray()
	for k in per:
		for b in blocks:
			out.append((b as PackedByteArray)[k])
	for k in ecc_len:
		for e in eccs:
			out.append((e as PackedByteArray)[k])
	return out


static func _gf_mul(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z & 0xFF


static func _rs_divisor(degree: int) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(degree)
	r.fill(0)
	r[degree - 1] = 1
	var root := 1
	for i in degree:
		for j in degree:
			r[j] = _gf_mul(r[j], root)
			if j + 1 < degree:
				r[j] ^= r[j + 1]
		root = _gf_mul(root, 0x02)
	return r


static func _rs_remainder(data: PackedByteArray, divisor: PackedByteArray) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(divisor.size())
	r.fill(0)
	for b in data:
		var factor := b ^ r[0]
		r.remove_at(0)
		r.append(0)
		for i in r.size():
			r[i] ^= _gf_mul(divisor[i], factor)
	return r


# -- the picture -----------------------------------------------------------------------------

static func _draw_patterns(dark: Array, fixed: Array, version: int) -> void:
	var size := dark.size()
	for i in size:
		_put(dark, fixed, 6, i, i % 2 == 0)
		_put(dark, fixed, i, 6, i % 2 == 0)
	for c in [Vector2i(3, 3), Vector2i(size - 4, 3), Vector2i(3, size - 4)]:
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var x: int = c.x + dx
				var y: int = c.y + dy
				if x >= 0 and x < size and y >= 0 and y < size:
					var d := maxi(absi(dx), absi(dy))
					_put(dark, fixed, x, y, d != 2 and d != 4)
	var al: Array = ALIGN[version]
	for i in al.size():
		for j in al.size():
			if (i == 0 and j == 0) or (i == 0 and j == al.size() - 1) or (i == al.size() - 1 and j == 0):
				continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					_put(dark, fixed, int(al[i]) + dx, int(al[j]) + dy, maxi(absi(dx), absi(dy)) != 1)
	_draw_format(dark, fixed, 0)             # reserve the format areas


static func _draw_format(dark: Array, fixed: Array, mask: int) -> void:
	var size := dark.size()
	var data := (LEVEL_M << 3) | mask
	var rem := data
	for i in 10:
		rem = (rem << 1) ^ ((rem >> 9) * 0x537)
	var bits := ((data << 10) | rem) ^ 0x5412
	var bit := func(i: int) -> bool: return ((bits >> i) & 1) == 1
	for i in 6:
		_put(dark, fixed, 8, i, bit.call(i))
	_put(dark, fixed, 8, 7, bit.call(6))
	_put(dark, fixed, 8, 8, bit.call(7))
	_put(dark, fixed, 7, 8, bit.call(8))
	for i in range(9, 15):
		_put(dark, fixed, 14 - i, 8, bit.call(i))
	for i in 8:
		_put(dark, fixed, size - 1 - i, 8, bit.call(i))
	for i in range(8, 15):
		_put(dark, fixed, 8, size - 15 + i, bit.call(i))
	_put(dark, fixed, 8, size - 8, true)     # the dark module


## The codewords zigzag up and down in two-module columns from the right.
static func _place(dark: Array, fixed: Array, codewords: PackedByteArray) -> void:
	var size := dark.size()
	var i := 0
	var total := codewords.size() * 8
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var upward := ((right + 1) & 2) == 0
				var y := size - 1 - vert if upward else vert
				if not fixed[y][x] and i < total:
					dark[y][x] = ((codewords[i >> 3] >> (7 - (i & 7))) & 1) == 1
					i += 1
		right -= 2


static func _mask(dark: Array, fixed: Array, mask: int) -> void:
	var size := dark.size()
	for y in size:
		for x in size:
			if fixed[y][x]:
				continue
			var flip := false
			match mask:
				0: flip = (x + y) % 2 == 0
				1: flip = y % 2 == 0
				2: flip = x % 3 == 0
				3: flip = (x + y) % 3 == 0
				4: flip = (x / 3 + y / 2) % 2 == 0
				5: flip = x * y % 2 + x * y % 3 == 0
				6: flip = (x * y % 2 + x * y % 3) % 2 == 0
				7: flip = ((x + y) % 2 + x * y % 3) % 2 == 0
			if flip:
				dark[y][x] = not dark[y][x]


## The standard's four penalties: long runs, 2x2 blocks, things that look
## like a finder, and too much or too little dark.
static func penalty(dark: Array) -> int:
	var size := dark.size()
	var score := 0
	for horizontal in [true, false]:
		for a in size:
			var run := 1
			var line: Array[bool] = []
			for b in size:
				line.append(dark[a][b] if horizontal else dark[b][a])
			for b in range(1, size):
				if line[b] == line[b - 1]:
					run += 1
				else:
					if run >= 5:
						score += run - 2
					run = 1
			if run >= 5:
				score += run - 2
			# a finder's 1:1:3:1:1 with four light on one side
			for b in range(0, size - 6):
				if line[b] and not line[b + 1] and line[b + 2] and line[b + 3] and line[b + 4] \
						and not line[b + 5] and line[b + 6]:
					var before := true
					for k in range(b - 4, b):
						if k >= 0 and line[k]:
							before = false
					var after := true
					for k in range(b + 7, b + 11):
						if k < size and line[k]:
							after = false
					if before:
						score += 40
					if after:
						score += 40
	var n_dark := 0
	for y in size:
		for x in size:
			if dark[y][x]:
				n_dark += 1
			if x < size - 1 and y < size - 1:
				var c: bool = dark[y][x]
				if dark[y][x + 1] == c and dark[y + 1][x] == c and dark[y + 1][x + 1] == c:
					score += 3
	var total := size * size
	var k2 := (absi(n_dark * 20 - total * 10) + total - 1) / total - 1
	score += k2 * 10
	return score
