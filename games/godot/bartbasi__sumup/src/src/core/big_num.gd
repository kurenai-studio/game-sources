class_name BigNum extends RefCounted
## A whole number of 0 or more with no fixed limit (docs/ARCHITECTURE.md
## section 17). The score, points and charged amounts use it.
##
## Immutable: every operation returns a new BigNum and never changes its
## inputs, so one BigNum can be shared freely.
##
## Stored as limbs in base 10^9, least significant first, with no zero limb
## at the top (zero has no limbs). Base 10^9 keeps parse and to_decimal simple
## and linear in the length. Every limb product (below 10^18) plus a limb and
## a carry stays far below 2^63, so plain int math never overflows.

const _BASE: int = 1000000000
const _BASE_DIGITS: int = 9
## log2(10), for the bit_length estimate.
const _LOG2_10: float = 3.321928094887362
## pow2 refuses exponents above this as a programming error. It is far above
## every limit the game uses (max_score_bits is 65600), and it keeps a bad
## caller from building a number that would take minutes.
const _POW2_GUARD: int = 1 << 20
## pow2 keeps at most this many large powers, so repeated costs and points
## on a board of huge tiles are worked out once. When it is full the oldest
## entry goes, so a chain of many different exponents never empties it
## (SEC-06).
const _POW2_CACHE_SIZE: int = 64
## pow2 builds 2^e from a cached power at most this many bits away, by
## shifting it a few bits per pass, before it falls back to squaring. A
## board's tiles and a huge score sit close together, so after the first
## large power the others come from it in a few linear passes (SEC-06).
const _POW2_NEAR: int = 300
## Bits moved per shifting pass. A limb is below 10^9, under 2^30, so a limb
## times 2^30 plus a carry stays far below 2^63.
const _SHIFT_STEP: int = 30
## Squaring splits numbers of at least this many limbs in two (Karatsuba),
## which is much faster than schoolbook squaring for the largest powers.
const _KARATSUBA_MIN: int = 96

static var _pow2_cache: Dictionary[int, BigNum] = {}
## ASCII digits from start to end and nothing else (\z, unlike $, allows no final newline).
static var _digits_only: RegEx = null

var _limbs: PackedInt64Array = PackedInt64Array()
var _bits: int = -1   # bit_length, worked out on first use


static func zero() -> BigNum:
	return BigNum.new()


## value must be 0 or more. A negative value is a programming error: it is
## reported and zero() is returned.
static func from_int(value: int) -> BigNum:
	if value < 0:
		push_error("BigNum.from_int: negative value %d" % value)
		return zero()
	var limbs: PackedInt64Array = PackedInt64Array()
	var rest: int = value
	while rest > 0:
		limbs.append(rest % _BASE)
		@warning_ignore("integer_division")
		rest = rest / _BASE
	return _make(limbs)


## 2^exponent. exponent must be 0 or more (and at most 2^20); anything else
## is a programming error: it is reported and zero() is returned.
static func pow2(exponent: int) -> BigNum:
	if exponent < 0 or exponent > _POW2_GUARD:
		push_error("BigNum.pow2: exponent %d out of range" % exponent)
		return zero()
	if exponent < 63:
		return from_int(1 << exponent)
	if _pow2_cache.has(exponent):
		return _pow2_cache[exponent]
	var result: BigNum = null
	# The closest cached power within _POW2_NEAR bits, shifted to exponent.
	var near: int = -1
	for cached: int in _pow2_cache:
		if absi(cached - exponent) <= _POW2_NEAR and (near < 0 or absi(cached - exponent) < absi(near - exponent)):
			near = cached
	if near >= 0:
		result = _pow2_cache[near]._shifted(exponent - near)
	else:
		# 2^e = (2^(e/2))^2, times 2 when e is odd.
		result = pow2(exponent >> 1)._squared()
		if exponent & 1 == 1:
			result = result.add(result)
	result._bits = exponent + 1
	if _pow2_cache.size() >= _POW2_CACHE_SIZE:
		# Dictionaries keep insertion order, so the first key is the oldest.
		_pow2_cache.erase(_pow2_cache.keys()[0])
	_pow2_cache[exponent] = result
	return result


## Decimal digits only, no sign, no leading zero unless the text is "0", at most max_digits characters. null for anything else.
static func parse(text: String, max_digits: int) -> BigNum:
	var length: int = text.length()
	if length == 0 or length > max_digits:
		return null
	if _digits_only == null:
		_digits_only = RegEx.create_from_string("\\A[0-9]+\\z")
	if _digits_only.search(text) == null:
		return null
	if length > 1 and text.unicode_at(0) == 48:
		return null
	var limbs: PackedInt64Array = PackedInt64Array()
	var end: int = length
	while end > 0:
		var start: int = maxi(0, end - _BASE_DIGITS)
		limbs.append(text.substr(start, end - start).to_int())
		end = start
	return _make(limbs)


func add(other: BigNum) -> BigNum:
	var count: int = maxi(_limbs.size(), other._limbs.size())
	var limbs: PackedInt64Array = PackedInt64Array()
	limbs.resize(count)
	var carry: int = 0
	for position: int in count:
		var total: int = carry
		if position < _limbs.size():
			total += _limbs[position]
		if position < other._limbs.size():
			total += other._limbs[position]
		if total >= _BASE:
			limbs[position] = total - _BASE
			carry = 1
		else:
			limbs[position] = total
			carry = 0
	if carry > 0:
		limbs.append(carry)
	return _make(limbs)


## This number minus other. null when other is larger; callers check affordability first.
func sub(other: BigNum) -> BigNum:
	if compare(other) < 0:
		return null
	var limbs: PackedInt64Array = _limbs.duplicate()
	var borrow: int = 0
	for position: int in limbs.size():
		var taken: int = borrow
		if position < other._limbs.size():
			taken += other._limbs[position]
		if taken == 0:
			if position >= other._limbs.size():
				break
			continue
		var left: int = limbs[position] - taken
		if left < 0:
			limbs[position] = left + _BASE
			borrow = 1
		else:
			limbs[position] = left
			borrow = 0
	return _make(limbs)


## -1, 0 or 1 as this number is smaller than, equal to or larger than other.
func compare(other: BigNum) -> int:
	if _limbs.size() != other._limbs.size():
		return -1 if _limbs.size() < other._limbs.size() else 1
	for position: int in range(_limbs.size() - 1, -1, -1):
		var mine: int = _limbs[position]
		var theirs: int = other._limbs[position]
		if mine != theirs:
			return -1 if mine < theirs else 1
	return 0


func equals(other: BigNum) -> bool:
	return other != null and _limbs == other._limbs


func is_zero() -> bool:
	return _limbs.is_empty()


## The number of binary digits: 0 for zero, and 2^k has bit_length k + 1.
func bit_length() -> int:
	if _bits < 0:
		_bits = _count_bits()
	return _bits


## The number in decimal with no separators: "0", "41286".
func to_decimal() -> String:
	if _limbs.is_empty():
		return "0"
	var parts: PackedStringArray = PackedStringArray()
	parts.resize(_limbs.size())
	var last: int = _limbs.size() - 1
	parts[0] = str(_limbs[last])
	for position: int in range(last - 1, -1, -1):
		parts[last - position] = str(_limbs[position]).pad_zeros(_BASE_DIGITS)
	return "".join(parts)


## True when the number is 2^63 - 1 or less.
func fits_int() -> bool:
	if _limbs.size() < 3:
		return true
	if _limbs.size() > 3:
		return false
	# 2^63 - 1 is 9 223372036 854775807 in base 10^9 limbs.
	var top: int = _limbs[2]
	if top != 9:
		return top < 9
	if _limbs[1] != 223372036:
		return _limbs[1] < 223372036
	return _limbs[0] <= 854775807


## The number as an int. Only when fits_int(); otherwise a programming error
## is reported and 0 is returned.
func to_int() -> int:
	if not fits_int():
		push_error("BigNum.to_int: %s digits do not fit in 64 bits" % to_decimal().length())
		return 0
	var value: int = 0
	for position: int in range(_limbs.size() - 1, -1, -1):
		value = value * _BASE + _limbs[position]
	return value


static func _make(limbs: PackedInt64Array) -> BigNum:
	var top: int = limbs.size()
	while top > 0 and limbs[top - 1] == 0:
		top -= 1
	if top != limbs.size():
		limbs.resize(top)
	var number: BigNum = BigNum.new()
	number._limbs = limbs
	return number


## This number times 2^bits, or divided by 2^-bits (rounded down) when bits
## is negative. Linear passes of at most _SHIFT_STEP bits each, so a shift
## by a few hundred bits costs a few passes. pow2 uses it to build a power
## from a cached neighbour, where the division is always exact.
func _shifted(bits: int) -> BigNum:
	var result: BigNum = self
	var rest: int = bits
	while rest > 0:
		var step: int = mini(rest, _SHIFT_STEP)
		result = result._times_small(1 << step)
		rest -= step
	while rest < 0:
		var step: int = mini(-rest, _SHIFT_STEP)
		result = result._divided_small(1 << step)
		rest += step
	return result


## This number times factor, for 0 < factor <= 2^30. Each limb times factor
## is below 2^60, plus a carry below 2^31, so nothing overflows.
func _times_small(factor: int) -> BigNum:
	var limbs: PackedInt64Array = PackedInt64Array()
	limbs.resize(_limbs.size())
	var carry: int = 0
	for position: int in _limbs.size():
		var total: int = _limbs[position] * factor + carry
		@warning_ignore("integer_division")
		carry = total / _BASE
		limbs[position] = total - carry * _BASE
	while carry > 0:
		limbs.append(carry % _BASE)
		@warning_ignore("integer_division")
		carry = carry / _BASE
	return _make(limbs)


## This number divided by divisor, rounded down, for 0 < divisor <= 2^30.
## The remainder stays below divisor, so remainder times 10^9 plus a limb is
## below 2^60.
func _divided_small(divisor: int) -> BigNum:
	var limbs: PackedInt64Array = PackedInt64Array()
	limbs.resize(_limbs.size())
	var remainder: int = 0
	for position: int in range(_limbs.size() - 1, -1, -1):
		var total: int = remainder * _BASE + _limbs[position]
		@warning_ignore("integer_division")
		var quotient: int = total / divisor
		limbs[position] = quotient
		remainder = total - quotient * divisor
	return _make(limbs)


## This number times other, by schoolbook multiplication: linear when other
## has only a few limbs, which is how CoreRules builds a chain's points
## (a small number times one power of two). Every total is below
## 10^9 + (10^9 - 1)^2 + 10^9, so it fits in 64 bits. Internal to core.
func _times(other: BigNum) -> BigNum:
	if _limbs.is_empty() or other._limbs.is_empty():
		return zero()
	var mine: PackedInt64Array = _limbs
	var theirs: PackedInt64Array = other._limbs
	var limbs: PackedInt64Array = PackedInt64Array()
	limbs.resize(mine.size() + theirs.size())
	limbs.fill(0)
	for j: int in theirs.size():
		var factor: int = theirs[j]
		if factor == 0:
			continue
		var carry: int = 0
		for i: int in mine.size():
			var total: int = limbs[i + j] + mine[i] * factor + carry
			@warning_ignore("integer_division")
			carry = total / _BASE
			limbs[i + j] = total - carry * _BASE
		limbs[j + mine.size()] = carry
	return _make(limbs)


## This number moved up by count whole limbs: times 10^(9 * count).
func _limb_shifted(count: int) -> BigNum:
	if _limbs.is_empty():
		return self
	var limbs: PackedInt64Array = PackedInt64Array()
	limbs.resize(count)
	limbs.fill(0)
	limbs.append_array(_limbs)
	return _make(limbs)


## This number squared. Only pow2 uses it. Large numbers split in two halves,
## low and high, and use (low + high)^2 - low^2 - high^2 = 2 * low * high,
## so three half size squares replace four (Karatsuba). Small ones use
## schoolbook squaring.
func _squared() -> BigNum:
	var count: int = _limbs.size()
	if count < _KARATSUBA_MIN:
		return _squared_schoolbook()
	var half: int = count >> 1
	var low: BigNum = _make(_limbs.slice(0, half))
	var high: BigNum = _make(_limbs.slice(half))
	var low_squared: BigNum = low._squared()
	var high_squared: BigNum = high._squared()
	var middle: BigNum = low.add(high)._squared().sub(low_squared).sub(high_squared)
	return low_squared.add(middle._limb_shifted(half)).add(high_squared._limb_shifted(half * 2))


## This number squared, by schoolbook multiplication.
## Each cross product a[i] * a[j] with i < j is added once, the total is
## doubled, then the squares a[i] * a[i] are added. Every intermediate total
## is below 10^9 + (10^9 - 1)^2 + 2 * 10^9, so it fits in 64 bits.
func _squared_schoolbook() -> BigNum:
	var count: int = _limbs.size()
	if count == 0:
		return zero()
	var digits: PackedInt64Array = _limbs
	var limbs: PackedInt64Array = PackedInt64Array()
	limbs.resize(count * 2)
	limbs.fill(0)
	for i: int in count:
		var factor: int = digits[i]
		if factor == 0:
			continue
		var carry: int = 0
		for j: int in range(i + 1, count):
			var total: int = limbs[i + j] + factor * digits[j] + carry
			@warning_ignore("integer_division")
			carry = total / _BASE
			limbs[i + j] = total - carry * _BASE
		var spot: int = i + count
		while carry > 0:
			var total: int = limbs[spot] + carry
			@warning_ignore("integer_division")
			carry = total / _BASE
			limbs[spot] = total - carry * _BASE
			spot += 1
	var carry_out: int = 0
	for position: int in limbs.size():
		var total: int = limbs[position] * 2 + carry_out
		if position & 1 == 0:
			var digit: int = digits[position >> 1]
			total += digit * digit
		@warning_ignore("integer_division")
		carry_out = total / _BASE
		limbs[position] = total - carry_out * _BASE
	return _make(limbs)


## The exact bit length. Small numbers count bits directly. Larger ones start
## from a floating point estimate of log2, which is off by far less than
## 10^-6. When the estimate is not within 10^-6 of a whole number its floor is
## exact; otherwise the number is compared with the powers of two next to it.
func _count_bits() -> int:
	if _limbs.is_empty():
		return 0
	if fits_int():
		var value: int = to_int()
		var count: int = 0
		while value > 0:
			value >>= 1
			count += 1
		return count
	var top: int = _limbs.size() - 1
	var lead: float = float(_limbs[top]) * 1e18 + float(_limbs[top - 1]) * 1e9 + float(_limbs[top - 2])
	var estimate: float = log(lead) / log(2.0) + float((top - 2) * _BASE_DIGITS) * _LOG2_10
	var low: int = int(floor(estimate))
	var fraction: float = estimate - float(low)
	if fraction > 1e-6 and fraction < 1.0 - 1e-6:
		return low + 1
	if compare(pow2(low + 1)) >= 0:
		return low + 2
	if compare(pow2(low)) >= 0:
		return low + 1
	return low
