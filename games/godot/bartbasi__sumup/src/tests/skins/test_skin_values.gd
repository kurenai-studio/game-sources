extends "res://tests/base_test.gd"
## The shipped skin files hold exactly the values of the checked token files
## in tools/directions/<id>/tokens.gd, which the contrast, label and ramp
## checks prove. So those checks' proof carries over to what ships.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

const OUTFIT_PATH: String = "res://src/design/fonts/Outfit[wght].ttf"

## Names each tokens.gd adds in _add_phase1_aliases() for the Phase 1
## prototypes. They are not part of the schema and do not ship.
const PALETTE_ALIASES: Dictionary = {
	"gumdrop": ["ink_soft", "divider", "lemon", "lemon_lip"],
	"slate": ["rule"],
	"nova": ["ring"],
}
const NUMBER_ALIASES: Dictionary = {
	"gumdrop": [
		"gap", "tray_padding", "lip_depth", "rope_width", "ring_width", "target_ring_width",
		"card_radius", "button_radius", "divider_width", "booster_icon", "hud_icon",
		"toggle_track_w", "toggle_track_h",
	],
	"slate": [
		"gap", "line_width", "chain_frame", "number_knockout", "target_bracket_width",
		"rule_width", "preview_tile", "button_radius", "booster_icon", "hud_icon",
		"toggle_track_w", "toggle_track_h",
	],
	"nova": [
		"beam_width", "chain_rim_width", "orbit_width", "sheet_radius", "booster_icon",
		"hud_icon", "divider_width", "toggle_track_w", "toggle_track_h",
	],
}


func test_every_skin_is_valid() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		assert_true(skin != null, "%s loads" % skin_id)
		if skin != null:
			assert_eq(skin.validate(), PackedStringArray(), "%s validate()" % skin_id)


func test_identity_and_font_match_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		assert_eq(String(skin.id), tokens.id, "%s id" % skin_id)
		assert_eq(skin.display_name, tokens.display_name, "%s display_name" % skin_id)
		var expected_path: String = OUTFIT_PATH if tokens.font_family == DirectionTokens.FAMILY_OUTFIT else ""
		assert_eq(skin.font_path, expected_path, "%s font_path for font family %s" % [skin_id, tokens.font_family])
		assert_eq(skin.system_font_names, tokens.font_names, "%s system_font_names" % skin_id)


func test_palette_matches_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		var aliases: Array = PALETTE_ALIASES[String(skin_id)]
		for key: String in tokens.palette.keys():
			if aliases.has(key):
				assert_false(skin.palette.has(StringName(key)), "%s ships the Phase 1 alias '%s'" % [skin_id, key])
				continue
			if not skin.palette.has(StringName(key)):
				fail("%s palette is missing '%s'" % [skin_id, key])
				continue
			_assert_color(skin.palette[StringName(key)], tokens.palette[key], "%s palette '%s'" % [skin_id, key])
		for key: StringName in skin.palette.keys():
			assert_true(tokens.palette.has(String(key)), "%s palette has '%s', which tokens.gd does not" % [skin_id, key])


func test_ramp_matches_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		assert_eq(skin.tile_fill.size(), tokens.tile_fill.size(), "%s tile_fill size" % skin_id)
		assert_eq(skin.tile_ink.size(), tokens.tile_ink.size(), "%s tile_ink size" % skin_id)
		for i: int in mini(skin.tile_fill.size(), tokens.tile_fill.size()):
			_assert_color(skin.tile_fill[i], tokens.tile_fill[i], "%s tile_fill[%d]" % [skin_id, i])
		for i: int in mini(skin.tile_ink.size(), tokens.tile_ink.size()):
			_assert_color(skin.tile_ink[i], tokens.tile_ink[i], "%s tile_ink[%d]" % [skin_id, i])
		assert_eq(skin.tile_cycle, tokens.tile_cycle, "%s tile_cycle" % skin_id)
		assert_eq(skin.tile_tier, tokens.tile_tier, "%s tile_tier" % skin_id)
		assert_eq(skin.beyond_tier, tokens.beyond_tier, "%s beyond_tier" % skin_id)


func test_text_pairs_match_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		assert_eq(skin.text_pairs.size(), tokens.text_pairs.size(), "%s text pair count" % skin_id)
		for i: int in mini(skin.text_pairs.size(), tokens.text_pairs.size()):
			_assert_same_dictionary(skin.text_pairs[i], tokens.text_pairs[i], "%s text pair %d" % [skin_id, i])


func test_type_matches_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		assert_eq(skin.type_roles.size(), tokens.type_roles.size(), "%s type role count" % skin_id)
		for role: String in tokens.type_roles.keys():
			if not skin.type_roles.has(StringName(role)):
				fail("%s is missing type role '%s'" % [skin_id, role])
				continue
			_assert_same_dictionary(skin.type_roles[StringName(role)], tokens.type_roles[role], "%s type role '%s'" % [skin_id, role])
		assert_eq(skin.tile_number_scale, tokens.tile_number_scale, "%s tile_number_scale" % skin_id)


func test_numbers_match_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		var aliases: Array = NUMBER_ALIASES[String(skin_id)]
		for key: String in tokens.shape.keys():
			if aliases.has(key):
				assert_false(skin.numbers.has(StringName(key)), "%s ships the Phase 1 alias '%s'" % [skin_id, key])
				continue
			if not skin.numbers.has(StringName(key)):
				fail("%s numbers is missing '%s' (tokens.gd has %s)" % [skin_id, key, tokens.shape[key]])
				continue
			assert_eq(skin.numbers[StringName(key)], tokens.shape[key], "%s number '%s'" % [skin_id, key])
		for key: StringName in skin.numbers.keys():
			assert_true(tokens.shape.has(String(key)), "%s numbers has '%s', which tokens.gd does not" % [skin_id, key])


func test_motion_matches_tokens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var tokens: DirectionTokens = _tokens(skin_id)
		assert_eq(skin.motion.size(), tokens.motion.size(), "%s motion count" % skin_id)
		for motion_name: String in tokens.motion.keys():
			if not skin.motion.has(StringName(motion_name)):
				fail("%s is missing motion '%s'" % [skin_id, motion_name])
				continue
			_assert_same_dictionary(skin.motion[StringName(motion_name)], tokens.motion[motion_name], "%s motion '%s'" % [skin_id, motion_name])


func _tokens(skin_id: StringName) -> DirectionTokens:
	return Directions.load_tokens(String(skin_id))


## Colors are compared as 8 bit hex, the precision the design system gives.
func _assert_color(actual: Color, expected: Color, message: String) -> void:
	assert_eq(actual.to_html(true), expected.to_html(true), message)


func _assert_same_dictionary(actual: Dictionary, expected: Dictionary, message: String) -> void:
	for key: Variant in expected.keys():
		if not actual.has(key):
			fail("%s: missing '%s'" % [message, key])
			continue
		assert_eq(actual[key], expected[key], "%s '%s'" % [message, key])
	for key: Variant in actual.keys():
		if not expected.has(key):
			fail("%s: has '%s', which tokens.gd does not" % [message, key])
