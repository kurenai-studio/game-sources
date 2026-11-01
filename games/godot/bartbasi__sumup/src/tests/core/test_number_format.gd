extends "res://tests/base_test.gd"
## Tile labels (D-31) and score text (D-32) through NumberFormat, as
## rewritten on 2026-10-21: tiles by exponent, scores as BigNum, one suffix
## sequence K, M, B, T, Q, aa to zz, aaa and on.

const LETTERS: String = "abcdefghijkmnpqrstuvwxyz"
const NAMED: PackedStringArray = ["K", "M", "B", "T", "Q"]

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _score(text: String) -> String:
	return NumberFormat.score(BigNum.parse(text, 20000))


## The step count a suffix stands for, worked out on its own (GDD 14.1), or
## -1 for anything that is not a suffix.
func _steps_of(suffix: String) -> int:
	if NAMED.has(suffix):
		return NAMED.find(suffix) + 1
	if suffix.length() < 2:
		return -1
	var index: int = 0
	for character: String in suffix:
		var position: int = LETTERS.find(character)
		if position < 0:
			return -1
		index = index * 24 + position
	var offset: int = 0
	var block: int = 576
	for length: int in range(2, suffix.length()):
		offset += block
		block *= 24
	return index + offset + 6


func test_at_85_tile_labels() -> void:
	var table: Array[Array] = [
		[1, "2"], [9, "512"], [10, "1024"], [11, "2K"], [12, "4K"], [16, "64K"],
		[17, "128K"], [19, "512K"], [20, "1M"], [21, "2M"], [30, "1B"], [40, "1T"],
		[49, "512T"], [50, "1Q"], [56, "64Q"], [59, "512Q"], [60, "1aa"], [62, "4aa"],
		[63, "8aa"], [64, "16aa"], [67, "128aa"], [69, "512aa"], [70, "1ab"], [100, "1ae"],
		[290, "1az"], [300, "1ba"], [1000, "1dy"], [5819, "512zz"], [5820, "1aaa"],
		[5827, "128aaa"], [65535, "32kiv"], [65536, "64kiv"],
	]
	for row: Array in table:
		assert_eq(NumberFormat.tile_label(row[0]), row[1], "label for 2^%d" % row[0])


func test_at_162_tile_label_examples() -> void:
	var table: Array[Array] = [
		[10, "1024"], [11, "2K"], [49, "512T"], [50, "1Q"], [56, "64Q"], [59, "512Q"],
		[60, "1aa"], [62, "4aa"], [63, "8aa"], [69, "512aa"], [70, "1ab"], [100, "1ae"],
		[290, "1az"], [300, "1ba"], [1000, "1dy"], [5819, "512zz"], [5820, "1aaa"],
		[5827, "128aaa"], [65535, "32kiv"], [65536, "64kiv"],
	]
	for row: Array in table:
		assert_eq(NumberFormat.tile_label(row[0], config), row[1], "label for 2^%d" % row[0])


func test_at_86_label_lengths() -> void:
	for exponent: int in range(1, 65537):
		var label: String = NumberFormat.tile_label(exponent, config)
		var problem: String = ""
		if label.contains("l") or label.contains("o"):
			problem = "contains l or o"
		elif exponent <= 59:
			if label.length() > 4:
				problem = "longer than 4"
		elif exponent <= 5819:
			var ends: bool = _steps_of(label.right(2)) >= 6 and not LETTERS.contains(label.right(3).left(1))
			var five: bool = exponent % 10 >= 7
			if label.length() < 3 or label.length() > 5 or not ends or (label.length() == 5) != five:
				problem = "not 3 to 5 characters ending in two letters"
		elif label.length() < 4 or label.length() > 6 or _steps_of(label.right(3)) < 582:
			problem = "not 4 to 6 characters ending in three letters"
		if not problem.is_empty():
			fail("2^%d gives %s: %s" % [exponent, label, problem])
			return


func test_at_163_every_label_is_different_and_reads_back() -> void:
	var seen: Dictionary[String, int] = {}
	for exponent: int in range(1, 65537):
		var label: String = NumberFormat.tile_label(exponent, config)
		if seen.has(label):
			fail("2^%d and 2^%d both give %s" % [seen[label], exponent, label])
			return
		seen[label] = exponent
		var digits: int = 0
		while digits < label.length() and "0123456789".contains(label[digits]):
			digits += 1
		var number: int = label.left(digits).to_int()
		var suffix: String = label.substr(digits)
		var power: int = 0
		while (1 << power) < number:
			power += 1
		var steps: int = 0 if suffix.is_empty() else _steps_of(suffix)
		var mixed: bool = suffix.length() > 1 and suffix != suffix.to_lower()
		if (1 << power) != number or steps < 0 or mixed or steps * 10 + power != exponent:
			fail("%s does not read back to 2^%d" % [label, exponent])
			return
	assert_eq(seen.size(), 65536, "65,536 different labels")


func test_at_88_score_format() -> void:
	assert_eq(NumberFormat.score(BigNum.zero()), "0", "0")
	assert_eq(NumberFormat.score(BigNum.from_int(999)), "999", "999")
	assert_eq(NumberFormat.score(BigNum.from_int(1000)), "1,000", "1000")
	assert_eq(NumberFormat.score(BigNum.from_int(75000)), "75,000", "75000")
	assert_eq(NumberFormat.score(BigNum.from_int(1234567)), "1,234,567", "1234567")
	assert_eq(NumberFormat.score(BigNum.from_int(9999999999)), "9,999,999,999", "the 13 character score")
	assert_eq(_score("9999999999999"), "9,999,999,999K", "14 characters")
	assert_eq(_score("9".repeat(28)), "9,999,999,999aa", "28 nines, 15 characters")
	assert_eq(_score("9".repeat(1756)), "9,999,999,999aaa", "1,756 nines, 16 characters")


func test_at_164_score_display_examples() -> void:
	var table: Array[Array] = [
		["0", "0"],
		["999", "999"],
		["1234567", "1,234,567"],
		["9999999999", "9,999,999,999"],
		["10000000000", "10,000,000K"],
		["12345678901", "12,345,678K"],
		["999999999999", "999,999,999K"],
		["9999999999999", "9,999,999,999K"],
		["12345678901234", "12,345,678M"],
		["9221253119629040934", "9,221,253,119B"],
		["9223372036854775808", "9,223,372,036B"],
		["18446744073709551616", "18,446,744T"],
		["1" + "0".repeat(24), "1,000,000,000Q"],
		["1" + "0".repeat(25), "10,000,000aa"],
		["1267650600228229401496703205376", "1,267,650,600ab"],
		["99999999999", "99,999,999K"],
		["1000000000000", "1,000,000,000K"],
		["9223372036854775807", "9,223,372,036B"],
	]
	for row: Array in table:
		assert_eq(_score(row[0]), row[1], "score %s" % row[0])
	assert_eq(NumberFormat.score(BigNum.pow2(63)), "9,223,372,036B", "2^63")
	assert_eq(NumberFormat.score(BigNum.pow2(64)), "18,446,744T", "2^64")
	assert_eq(NumberFormat.score(BigNum.pow2(100)), "1,267,650,600ab", "2^100")
	var top: BigNum = BigNum.pow2(65600).sub(BigNum.from_int(1))
	assert_eq(top.to_decimal().length(), 19748, "2^65600 - 1 has 19,748 digits")
	assert_eq(NumberFormat.score(top), "36,958,603kjy", "the largest score: 8 digits, then kjy")


## Bart's score before and after the 2^50 pair (AT-159, AT-160).
func test_bart_scores() -> void:
	assert_eq(_score("9221253119629040934"), "9,221,253,119B", "before")
	assert_eq(_score("9223504919442726182"), "9,223,504,919B", "after")


func test_at_165_a_shown_score_never_exceeds_the_real_one() -> void:
	var texts: PackedStringArray = PackedStringArray()
	for n: int in range(1, 61):
		texts.append("9".repeat(n))
		texts.append("1" + "0".repeat(n))
	var top: BigNum = BigNum.pow2(65600)
	for seed_value: int in range(1, 1001):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value
		var length: int = rng.randi_range(1, 19748)
		var text: String = _random_digits(rng, length)
		# A 19,748 digit draw can land above 2^65600; draw again until below.
		while BigNum.parse(text, 20000).compare(top) >= 0:
			text = _random_digits(rng, length)
		texts.append(text)
	for text: String in texts:
		var value: BigNum = BigNum.parse(text, 20000)
		if value == null or value.bit_length() > 65600:
			fail("bad test score of %d digits" % text.length())
			return
		var shown: String = NumberFormat.score(value)
		var digits: int = 0
		while digits < shown.length() and "0123456789,".contains(shown[digits]):
			digits += 1
		var grouped: String = shown.left(digits)
		var number: String = grouped.replace(",", "")
		var suffix: String = shown.substr(digits)
		var steps: int = 0 if suffix.is_empty() else _steps_of(suffix)
		var problem: bool = not text.begins_with(number) or number.length() > 10 or steps < 0
		problem = problem or (steps > 0 and number.length() < 8) or text.length() - number.length() != steps * 3
		problem = problem or (text.length() <= 10 and not suffix.is_empty())
		problem = problem or grouped != _with_commas(number)
		if problem:
			fail("%d digits starting %s gave %s" % [text.length(), text.left(12), shown])
			return


## length random decimal digits with no leading zero.
func _random_digits(rng: RandomNumberGenerator, length: int) -> String:
	var parts: PackedStringArray = PackedStringArray([str(rng.randi_range(1, 9))])
	var written: int = 1
	while written < length:
		var chunk: String = str(rng.randi_range(0, 999999999)).pad_zeros(9)
		parts.append(chunk.left(mini(9, length - written)))
		written += mini(9, length - written)
	return "".join(parts)


## Digits with a comma between each group of three, counted from the right.
func _with_commas(number: String) -> String:
	var groups: PackedStringArray = PackedStringArray()
	var end: int = number.length()
	while end > 3:
		groups.insert(0, number.substr(end - 3, 3))
		end -= 3
	groups.insert(0, number.left(end))
	return ",".join(groups)


func test_at_166_tiles_and_scores_share_one_suffix_sequence() -> void:
	for steps: int in range(1, 6554):
		# Exponent 10 shows in full (1024), so step 1 is read from 2^11, "2K".
		var tile: String = NumberFormat.tile_label(11, config).substr(1) if steps == 1 else NumberFormat.tile_label(steps * 10, config).substr(1)
		var shown: String = _score("1" + "0".repeat(3 * steps + 9))
		var score: String = shown.trim_prefix("1,000,000,000") if shown.begins_with("1,000,000,000") else "(%s)" % shown
		if tile != score or tile.is_empty() or tile.contains("l") or tile.contains("o"):
			fail("step %d: tile suffix %s, score suffix %s" % [steps, tile, score])
			return
		if tile != NumberFormat._suffix(steps, config):
			fail("step %d: suffix %s, sequence %s" % [steps, tile, NumberFormat._suffix(steps, config)])
			return
	var named: PackedStringArray = PackedStringArray()
	for steps: int in range(1, 6):
		named.append(NumberFormat._suffix(steps))
	assert_eq(named, PackedStringArray(["K", "M", "B", "T", "Q"]), "1 to 5 steps")
	assert_eq(NumberFormat._suffix(6), "aa", "6 steps")
	assert_eq(NumberFormat._suffix(581), "zz", "581 steps")
	assert_eq(NumberFormat._suffix(582), "aaa", "582 steps")
	assert_eq(NumberFormat._suffix(6553), "kiv", "the ceiling tile")
	assert_eq(NumberFormat._suffix(6580), "kjy", "the largest score")
	assert_eq(_score("1" + "0".repeat(3 * 6580 + 9)), "1,000,000,000kjy", "the score side at 6,580 steps")
	assert_eq(NumberFormat._suffix(0), "", "no steps, no suffix")


func test_at_89_labels_for_preview_costs_and_best_tile() -> void:
	var preview: int = CoreRules.merge_result(PackedInt64Array([9, 9, 10, 10]))
	assert_eq(NumberFormat.tile_label(preview), "2K", "preview 2K")
	assert_eq(NumberFormat.tile_label(16), "64K", "Undo at H 131072")
	assert_eq(NumberFormat.tile_label(18), "256K", "Double at H 131072")
	assert_eq(NumberFormat.tile_label(17), "128K", "Hammer at H 131072")
	assert_eq(NumberFormat.tile_label(14), "16K", "Best Tile 16384")
	assert_eq(NumberFormat.tile_label(11), "2K", "Double at H 1024 (AT-47)")
	assert_eq(NumberFormat.tile_label(10), "1024", "Hammer at H 1024 (AT-47)")
	assert_eq(NumberFormat.tile_label(53), "8Q", "the AT-161 notice value 2^53")


func test_tile_label_of_no_tile() -> void:
	assert_eq(NumberFormat.tile_label(0), "0", "exponent 0 is no tile")
	assert_eq(NumberFormat.tile_label(-3), "0", "nor is a negative exponent")


func test_tile_label_follows_config_overrides() -> void:
	config.label_full_max = 12
	assert_eq(NumberFormat.tile_label(12, config), "4096", "LABEL_FULL_MAX 4096")
	assert_eq(NumberFormat.tile_label(13, config), "8K", "above it")
	config.label_suffixes = PackedStringArray(["k", "m"])
	assert_eq(NumberFormat.tile_label(20, config), "1m", "two named suffixes")
	assert_eq(NumberFormat.tile_label(30, config), "1aa", "then the letters")
	assert_eq(NumberFormat.tile_label(11, null), "2K", "null means the GDD values")
