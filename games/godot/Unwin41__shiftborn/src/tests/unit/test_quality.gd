extends TestCase


func test_desktop_defaults_to_high() -> void:
	assert_eq(Quality.tier_for(false, PackedStringArray()), Quality.Tier.HIGH)


func test_web_defaults_to_low() -> void:
	assert_eq(Quality.tier_for(true, PackedStringArray()), Quality.Tier.LOW)


func test_low_quality_flag_forces_low_on_desktop() -> void:
	assert_eq(Quality.tier_for(false, PackedStringArray([Quality.LOW_FLAG])), Quality.Tier.LOW)
