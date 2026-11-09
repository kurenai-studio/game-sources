extends TestCase


func test_format_drops_trailing_zero() -> void:
	assert_eq(DamageNumbers.format_amount(2.0), "2")
	assert_eq(DamageNumbers.format_amount(1.35), "1.4")
	assert_eq(DamageNumbers.format_amount(12.6), "13")


func test_numbers_expire_after_lifetime() -> void:
	var numbers := DamageNumbers.new()
	numbers.spawn(Vector2.ZERO, 1.0)
	numbers.advance(DamageNumbers.LIFETIME * 0.5)
	assert_eq(numbers.count(), 1)
	numbers.advance(DamageNumbers.LIFETIME)
	assert_eq(numbers.count(), 0)
	numbers.free()


func test_cap_drops_the_oldest_number() -> void:
	var numbers := DamageNumbers.new()
	numbers.max_active = 3
	for i in 5:
		numbers.spawn(Vector2(i, 0), 1.0)
	assert_eq(numbers.count(), 3)
	assert_eq(numbers.oldest_position(), Vector2(2, 0))
	numbers.free()


func test_zero_damage_is_not_shown() -> void:
	var numbers := DamageNumbers.new()
	numbers.spawn(Vector2.ZERO, 0.0)
	assert_eq(numbers.count(), 0)
	numbers.free()


func test_text_lines_are_cached_per_string() -> void:
	var numbers := DamageNumbers.new()
	var first := numbers._line_for("2")
	assert_true(first == numbers._line_for("2"), "same text should reuse its TextLine")
	assert_false(first == numbers._line_for("3"), "different text needs its own TextLine")
	numbers.free()


func test_resisted_hits_are_grey() -> void:
	var numbers := DamageNumbers.new()
	numbers.spawn(Vector2.ZERO, 1.0, true)
	assert_eq(numbers.color_of_newest(), DamageNumbers.RESISTED_COLOR)
	numbers.spawn(Vector2.ZERO, 1.0)
	assert_eq(numbers.color_of_newest(), DamageNumbers.COLOR)
	numbers.free()
