class_name NumberFormat extends RefCounted
## Number text for tiles and scores (GDD section 14). All static.
## Costs, the merge preview, Best Tile, the run's highest tile and clear
## notice values use tile_label. Score and Best Score use score. Both share
## one suffix sequence: K, M, B, T, Q, then two lowercase letters (aa to zz),
## then three (aaa and on), from LABEL_LETTERS. The case is part of the label.


## TH17, D-31. The label of the tile 2^exponent. Exponents up to
## LABEL_FULL_MAX show the full number (1024). Above that, with u = exponent
## divided by the bits of LABEL_STEP (10) and d the rest, the label is 2^d
## followed by the suffix for u steps: 2K, 128K, 64Q, 8aa, 32kiv. Works for
## every exponent up to max_exponent + 1 (the largest Double cost) and on.
## An exponent of 0 or less is no tile and gives "0". With no config the GDD
## section 18 values are used.
@warning_ignore("integer_division")
static func tile_label(exponent: int, config: GameConfig = null) -> String:
	var settings: GameConfig = config if config != null else GameConfig.new()
	if exponent <= 0:
		return "0"
	var step_bits: int = CoreRules._exponent_of(settings.label_step)
	if exponent < 63 and (exponent <= settings.label_full_max or step_bits <= 0):
		return str(1 << exponent)
	if step_bits <= 0:
		push_error("NumberFormat.tile_label: LABEL_STEP %d has no steps" % settings.label_step)
		return ""
	var steps: int = exponent / step_bits
	var rest: int = exponent - steps * step_bits
	if steps == 0:
		return str(1 << rest)
	return str(1 << rest) + _suffix(steps, settings)


## TH17, D-32. Up to SCORE_FULL_MAX_DIGITS (10) digits, the full number with
## a comma every three digits: 1,234,567. Longer scores drop their last
## digits in whole groups of three, as few as needed, never rounding, and
## show the suffix for the number of groups dropped: 9,221,253,119B. A null
## value is a programming error and shows "0".
@warning_ignore("integer_division")
static func score(value: BigNum) -> String:
	if value == null:
		push_error("NumberFormat.score: no value")
		return "0"
	var settings: GameConfig = GameConfig.new()
	var digits: String = value.to_decimal()
	var limit: int = maxi(3, settings.score_full_max_digits)
	if digits.length() <= limit:
		return _grouped(digits)
	var groups: int = (digits.length() - limit + 2) / 3
	return _grouped(digits.substr(0, digits.length() - groups * 3)) + _suffix(groups, settings)


## The suffix for a number of steps of 1024 (tiles) or 1000 (scores), 1 or
## more (GDD 14.1): the named suffixes first, then two letter suffixes, then
## three letter ones, and so on, each letter position counting through
## LABEL_LETTERS. "" for 0 or less. Internal: tests read it directly (AT-166).
@warning_ignore("integer_division")
static func _suffix(steps: int, config: GameConfig = null) -> String:
	var settings: GameConfig = config if config != null else GameConfig.new()
	if steps <= 0:
		return ""
	if steps <= settings.label_suffixes.size():
		return settings.label_suffixes[steps - 1]
	var letters: PackedStringArray = settings.label_letters
	var base: int = letters.size()
	if base < 2:
		push_error("NumberFormat.suffix: LABEL_LETTERS needs at least 2 letters")
		return ""
	var index: int = steps - settings.label_suffixes.size() - 1
	var length: int = 2
	var block: int = base * base
	while index >= block:
		index -= block
		length += 1
		block *= base
	var text: String = ""
	for position: int in length:
		text = letters[index % base] + text
		index /= base
	return text


## digits with a comma every three digits from the right.
static func _grouped(digits: String) -> String:
	var grouped: String = ""
	var count: int = 0
	for position: int in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = "," + grouped
		grouped = digits[position] + grouped
		count += 1
	return grouped
