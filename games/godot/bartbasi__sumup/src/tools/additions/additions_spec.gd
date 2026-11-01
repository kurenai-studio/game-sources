extends RefCounted
## The values the 2026-10-13 additions add to each skin, for the mockups in
## tools/additions/ only. The tokens (the heading and reading roles,
## star_icon, reading_line_spacing, scroll_bar) are read from the checked
## token files tools/directions/<skin>/tokens.gd, which mirror
## DESIGN_SYSTEM.md; the shipped code reads the same values from the SkinData
## resources, which hold them since the 2026-10-13 build. The star geometry and the
## fixed sizes below are drawing facts from DESIGN_SYSTEM.md 4.7, 5.7, 6.7 and
## 7.9. If this file and DESIGN_SYSTEM.md disagree, DESIGN_SYSTEM.md wins.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

## Star geometry on the 24 unit grid, per skin: center, outer radius, inner
## radius as a share of the outer, corner rounding at the points and in the
## valleys, and the outline width.
const STAR: Dictionary[StringName, Dictionary] = {
	&"gumdrop": {"center": Vector2(12.0, 12.9), "outer": 11.0, "inner_share": 0.50, "round_point": 1.8, "round_valley": 1.0, "outline": 2.5},
	&"slate": {"center": Vector2(12.0, 12.9), "outer": 11.0, "inner_share": 0.42, "round_point": 0.0, "round_valley": 0.0, "outline": 2.0},
	&"nova": {"center": Vector2(12.0, 12.9), "outer": 11.0, "inner_share": 0.40, "round_point": 0.5, "round_valley": 0.3, "outline": 1.5},
}

## How to play example tiles and the reading screen frame (7.9).
const EXAMPLE_TILE: float = 112.0
const ARROW_ICON: float = 56.0
## The scroll deadzone: Android's touch slop, 8 dp.
const SCROLL_DEADZONE: int = 24
## Shortest scroll indicator.
const SCROLL_BAR_MIN: float = 96.0

static var _tokens: Dictionary[StringName, DirectionTokens] = {}


static func tokens(skin: SkinData) -> DirectionTokens:
	if not _tokens.has(skin.id):
		_tokens[skin.id] = Directions.load_tokens(String(skin.id))
	return _tokens[skin.id]


## For the mockups only: copies the checked token values (the new tokens, the
## QA6-05 touch_min and button_height, and Nova's orb_scale and board_gap)
## onto the loaded skin in memory. The resources now hold the same values, so
## this changes nothing; it keeps the mockups tied to the token files. Nothing
## is saved.
const PREVIEW_NEW: PackedStringArray = ["star_icon", "reading_line_spacing", "scroll_bar"]
const PREVIEW_CHANGED: PackedStringArray = ["touch_min", "button_height", "orb_scale", "board_gap"]


static func preview_on(skin: SkinData) -> void:
	var source: DirectionTokens = tokens(skin)
	for key: String in PREVIEW_NEW:
		skin.numbers[StringName(key)] = float(source.shape[key])
	for key: String in PREVIEW_CHANGED:
		if skin.numbers.has(StringName(key)) and source.shape.has(key):
			skin.numbers[StringName(key)] = float(source.shape[key])
	for role_name: String in ["heading", "reading"]:
		skin.type_roles[StringName(role_name)] = source.type_roles[role_name]


static func role(skin: SkinData, role_name: StringName) -> Dictionary:
	return tokens(skin).type_roles[String(role_name)]


static func num(skin: SkinData, token: StringName) -> float:
	return float(tokens(skin).shape[String(token)])


static func star(skin: SkinData) -> Dictionary:
	return STAR[skin.id]


## A font for a role, built the way SkinData.font() builds its roles.
static func font(skin: SkinData, role_name: StringName) -> Font:
	var spec: Dictionary = role(skin, role_name)
	var variation: FontVariation = FontVariation.new()
	if not skin.font_path.is_empty():
		variation.base_font = load(skin.font_path) as Font
		var weight_tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		variation.variation_opentype = {weight_tag: int(spec["weight"])}
	else:
		var system: SystemFont = SystemFont.new()
		system.font_names = skin.system_font_names
		system.font_weight = int(spec["weight"])
		variation.base_font = system
	variation.spacing_glyph = int(spec["tracking"])
	return variation


static func font_size(skin: SkinData, role_name: StringName) -> int:
	return int(role(skin, role_name)["size"])


static func cased(skin: SkinData, role_name: StringName, text: String) -> String:
	var rule: String = String(role(skin, role_name)["case"])
	if rule == DirectionTokens.CASE_UPPER:
		return text.to_upper()
	if rule == DirectionTokens.CASE_LOWER:
		return text.to_lower()
	return text
