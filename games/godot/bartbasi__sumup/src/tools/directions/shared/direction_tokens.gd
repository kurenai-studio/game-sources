extends RefCounted
## Design tokens for one skin. Since Phase 2 these mirror docs/DESIGN_SYSTEM.md
## exactly, and they stay the checked source (contrast, label and ramp checks)
## until the production Skin Resources exist. Each skin's tokens.gd extends
## this script and fills every field in _init().
##
## The shared schema: every skin defines every name in SHARED_PALETTE,
## SHARED_SHAPE, TYPE_ROLES and MOTION_NAMES. Anything else is a per skin
## extra, marked as such in its tokens.gd. Phase 1 names that the prototype
## components still read are kept as aliases at the end of each tokens.gd.
##
## Prototype and check code. Nothing under tools/ ships with the game.
## Load it with preload, not class_name, so tools/ adds nothing to the global
## class list that Phase 2 code will use:
##     const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

## Lowest and highest tile values the ramp covers. Ramp index 0 is value 2,
## index 16 is value 131072.
const RAMP_LOW: int = 2
const RAMP_HIGH: int = 131072
const RAMP_SIZE: int = 17

## Text case rules for a type role.
const CASE_NONE: String = "none"
const CASE_UPPER: String = "upper"
const CASE_LOWER: String = "lower"

## The type roles every direction defines. heading and reading came with the
## 2026-10-13 reading screens (DESIGN_SYSTEM.md 3.4, 7.11).
const TYPE_ROLES: PackedStringArray = ["display", "title", "body", "label", "tile", "heading", "reading"]

## The motion names every skin defines. star_earn and star_convert came with
## the 2026-10-13 stars (DESIGN_SYSTEM.md 3.6).
const MOTION_NAMES: PackedStringArray = [
	"spawn", "fall", "chain_add", "chain_remove", "joinable_in",
	"merge_travel", "merge_pop", "clear", "clear_notice", "press",
	"button_press", "button_release", "dialog_in", "dialog_out",
	"screen_fade", "target_pulse", "score_count", "skin_switch",
	"star_earn", "star_convert",
]

## The palette roles every skin defines.
const SHARED_PALETTE: PackedStringArray = [
	"bg", "surface", "surface_raised", "line", "ink", "ink_muted", "ink_dark",
	"accent", "accent_pressed", "disabled_ink", "chain", "target", "joinable",
	"scrim", "badge", "badge_ink",
]

## The shape, layout and size names every skin defines.
const SHARED_SHAPE: PackedStringArray = [
	"board_margin", "board_gap", "board_padding", "tile_radius", "label_fit",
	"display_fit_min", "preview_scale", "special_from", "chain_width",
	"chain_ring", "joinable_ring", "target_ring", "space_xs", "space_s",
	"space_m", "space_l", "space_xl", "touch_min", "radius_button",
	"radius_card", "radius_chip", "hairline", "hud_height", "bar_height",
	"hint_height", "button_height", "row_height", "icon_booster", "icon_hud",
	"icon_stroke", "toggle_w", "toggle_h", "toggle_knob", "notice_height",
	"notice_tile_scale", "notice_strike", "star_icon", "reading_line_spacing",
	"scroll_bar",
]

## Font families a skin can use.
const FAMILY_SYSTEM: String = "system"
const FAMILY_OUTFIT: String = "outfit"

## Absolute path to the Outfit font file outside the repo. When set, skins
## whose font_family is "outfit" use it; system font skins never do. The
## capture tool and the label check set this until the font is in the repo.
static var override_font_path: String = ""
static var _override_font: FontFile = null

## Short id, also the folder name under tools/directions/.
var id: String = ""
## Name shown to the player in the skin picker.
var display_name: String = ""
## FAMILY_SYSTEM or FAMILY_OUTFIT.
var font_family: String = FAMILY_SYSTEM

## Named palette colors, for example "bg", "ink", "accent". Every key is
## documented in the direction's tokens.gd.
var palette: Dictionary[String, Color] = {}

## Tile fill and number color for each value from 2 to 131072, in ramp order.
var tile_fill: Array[Color] = []
var tile_ink: Array[Color] = []
## The color cycle (DESIGN_SYSTEM.md 3.3, 2026-10-15): ramp positions, in
## order, that the values above 131072 walk round. Value 2^k with k of 18 or
## more takes the fill and number of tile_cycle[(k - 18) mod size]. A
## position may be left out so the pairs across the wrap stay far apart.
var tile_cycle: PackedInt32Array = PackedInt32Array()
## Tier of each ramp value, in ramp order. What a tier changes is per skin
## (lip height, shine, slab or block, corona); the skin's tokens.gd says.
var tile_tier: PackedInt32Array = PackedInt32Array()
## Tier of every value above 131072. Tiers go by value, not by color.
var beyond_tier: int = 0

## Every text color on its background, as drawn on screen. Built with pair().
## Text may only be drawn with a pair listed here. The contrast checker holds
## each pair to its minimum ratio.
var text_pairs: Array[Dictionary] = []

## SystemFont preference list. On Windows this resolves to Segoe UI, on
## Android to Roboto. Plain "sans-serif" alone gives Arial on Windows.
var font_names: PackedStringArray = PackedStringArray(["Roboto", "Segoe UI", "sans-serif"])

## Type roles. Each entry holds:
##   size: int, px on the 1080 px wide canvas (not used for "tile")
##   weight: int, 100 to 900
##   tracking: int, extra px between glyphs
##   case: one of CASE_NONE, CASE_UPPER, CASE_LOWER
var type_roles: Dictionary[String, Dictionary] = {}

## Tile number font size as a fraction of the tile side (or orb diameter),
## by label length: index 0 is a 1 character label, index 3 is 4 characters.
var tile_number_scale: PackedFloat32Array = PackedFloat32Array()

## Shape, layout and spacing numbers. Keys are documented in tokens.gd.
## Lengths are px on the 1080 px wide canvas unless the comment says fraction.
var shape: Dictionary[String, float] = {}

## Motion specs. Each entry holds:
##   duration: float seconds (for loops, the period)
##   trans: int, a Tween.TransitionType
##   ease: int, a Tween.EaseType
## plus any extra numbers documented in tokens.gd.
var motion: Dictionary[String, Dictionary] = {}

var _font_cache: Dictionary[String, Font] = {}


## Sets override_font_path. Scripts that hold this file in a const cannot
## assign the static var directly, so they call this.
static func use_font_file(path: String) -> void:
	override_font_path = path
	_override_font = null


## Ramp index for a tile value: 0 for 2, 16 for 131072, RAMP_SIZE for any
## power of two above 131072, and -1 for anything that is not a power of two
## of at least 2.
static func ramp_index(value: int) -> int:
	if value < RAMP_LOW or (value & (value - 1)) != 0:
		return -1
	if value > RAMP_HIGH:
		return RAMP_SIZE
	var index: int = 0
	var v: int = value
	while v > RAMP_LOW:
		v = v >> 1
		index += 1
	return index


## Ramp position whose colors a tile value takes: its ramp index up to
## 131072, then round tile_cycle. -1 for anything that is not a tile value.
func color_position(value: int) -> int:
	var index: int = ramp_index(value)
	if index < RAMP_SIZE:
		return index
	if tile_cycle.is_empty():
		return -1
	var power: int = 0
	var v: int = value
	while v > 1:
		v = v >> 1
		power += 1
	return tile_cycle[(power - 18) % tile_cycle.size()]


## Tile fill color for a value.
func fill_for(value: int) -> Color:
	var position: int = color_position(value)
	if position < 0:
		push_error("%s: %d is not a tile value" % [id, value])
		return Color.MAGENTA
	return tile_fill[position]


## Tier for a value (see tile_tier).
func tier_for(value: int) -> int:
	var index: int = ramp_index(value)
	if index < 0 or tile_tier.size() != RAMP_SIZE:
		return 0
	if index >= RAMP_SIZE:
		return beyond_tier
	return tile_tier[index]


## Number color for a value.
func ink_for(value: int) -> Color:
	var position: int = color_position(value)
	if position < 0:
		push_error("%s: %d is not a tile value" % [id, value])
		return Color.MAGENTA
	return tile_ink[position]


## A named palette color. Logs an error for an unknown name.
func color(token: String) -> Color:
	if not palette.has(token):
		push_error("%s: unknown palette token '%s'" % [id, token])
		return Color.MAGENTA
	return palette[token]


## A shape, layout or spacing number. Logs an error for an unknown key.
func num(key: String) -> float:
	if not shape.has(key):
		push_error("%s: unknown shape token '%s'" % [id, key])
		return 0.0
	return shape[key]


## A motion spec. Logs an error for an unknown name.
func motion_spec(motion_name: String) -> Dictionary:
	if not motion.has(motion_name):
		push_error("%s: unknown motion '%s'" % [id, motion_name])
		return {"duration": 0.2, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT}
	return motion[motion_name]


## Duration in seconds of a motion.
func duration(motion_name: String) -> float:
	var spec: Dictionary = motion_spec(motion_name)
	return float(spec.get("duration", 0.2))


## Font size in px for a type role.
func font_size(role: String) -> int:
	return int(_role(role).get("size", 40))


## Font size in px for a tile number, given the tile side (or orb diameter)
## and the label text.
func tile_font_size(tile_side: float, label: String) -> int:
	if tile_number_scale.is_empty():
		push_error("%s: tile_number_scale is empty" % id)
		return 32
	var length_index: int = clampi(label.length(), 1, tile_number_scale.size()) - 1
	return maxi(1, roundi(tile_side * tile_number_scale[length_index]))


## Applies the role's case rule to a text.
func cased(role: String, text: String) -> String:
	var rule: String = String(_role(role).get("case", CASE_NONE))
	if rule == CASE_UPPER:
		return text.to_upper()
	if rule == CASE_LOWER:
		return text.to_lower()
	return text


## The font for a type role: weight and tracking applied, cached.
func font(role: String) -> Font:
	if _font_cache.has(role):
		return _font_cache[role]
	var spec: Dictionary = _role(role)
	var weight: int = int(spec.get("weight", 400))
	var variation: FontVariation = FontVariation.new()
	var file: FontFile = _load_override_font() if font_family == FAMILY_OUTFIT else null
	if file != null:
		variation.base_font = file
		# The weight axis must be keyed by its integer tag. The string key
		# "wght" is silently ignored in Godot 4.7.
		var weight_tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		variation.variation_opentype = {weight_tag: weight}
	else:
		var system: SystemFont = SystemFont.new()
		system.font_names = font_names
		system.font_weight = weight
		variation.base_font = system
	variation.spacing_glyph = int(spec.get("tracking", 0))
	_font_cache[role] = variation
	return variation


## Builds one entry for text_pairs.
##   pair_name: where this pair appears, for the checker's output
##   fg: palette token for the text color
##   bg: palette token for the background
##   over: only when bg has alpha below 1, the token it sits over (a palette
##     token, or "tile:<value>" for a tile fill). Use the worst case.
##   min_ratio: 4.5 for all text
func pair(pair_name: String, fg: String, bg: String, over: String = "", min_ratio: float = 4.5) -> Dictionary:
	return {"name": pair_name, "fg": fg, "bg": bg, "over": over, "min": min_ratio}


## Resolves a color reference: a palette token, "tile:<value>" for a tile
## fill, or "ink:<value>" for a tile number color. Returns ok = false for an
## unknown reference.
func resolve(ref: String) -> Dictionary:
	if ref.begins_with("tile:") or ref.begins_with("ink:"):
		var parts: PackedStringArray = ref.split(":")
		var value: int = parts[1].to_int()
		if ramp_index(value) < 0:
			return {"ok": false, "color": Color.MAGENTA}
		var picked: Color = fill_for(value) if parts[0] == "tile" else ink_for(value)
		return {"ok": true, "color": picked}
	if palette.has(ref):
		return {"ok": true, "color": palette[ref]}
	return {"ok": false, "color": Color.MAGENTA}


## Checks that every field is filled. Returns a list of problems, empty when
## the tokens are complete.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id.is_empty() or display_name.is_empty():
		problems.append("id and display_name must be set")
	if tile_fill.size() != RAMP_SIZE:
		problems.append("tile_fill has %d colors, needs %d" % [tile_fill.size(), RAMP_SIZE])
	if tile_ink.size() != RAMP_SIZE:
		problems.append("tile_ink has %d colors, needs %d" % [tile_ink.size(), RAMP_SIZE])
	for role: String in TYPE_ROLES:
		if not type_roles.has(role):
			problems.append("missing type role '%s'" % role)
	if tile_number_scale.size() != 4:
		problems.append("tile_number_scale needs 4 entries (1 to 4 characters)")
	if tile_tier.size() != RAMP_SIZE:
		problems.append("tile_tier has %d entries, needs %d" % [tile_tier.size(), RAMP_SIZE])
	if font_family != FAMILY_SYSTEM and font_family != FAMILY_OUTFIT:
		problems.append("unknown font_family '%s'" % font_family)
	for token: String in SHARED_PALETTE:
		if not palette.has(token):
			problems.append("missing shared palette role '%s'" % token)
	for key: String in SHARED_SHAPE:
		if not shape.has(key):
			problems.append("missing shared shape name '%s'" % key)
	for motion_name: String in MOTION_NAMES:
		if not motion.has(motion_name):
			problems.append("missing motion '%s'" % motion_name)
			continue
		var spec: Dictionary = motion[motion_name]
		for key: String in ["duration", "trans", "ease"]:
			if not spec.has(key):
				problems.append("motion '%s' has no %s" % [motion_name, key])
	if text_pairs.is_empty():
		problems.append("text_pairs is empty")
	for entry: Dictionary in text_pairs:
		for key: String in ["fg", "bg"]:
			if not bool(resolve(String(entry[key]))["ok"]):
				problems.append("pair '%s' uses unknown %s token '%s'" % [entry["name"], key, entry[key]])
		var over: String = String(entry["over"])
		if not over.is_empty() and not bool(resolve(over)["ok"]):
			problems.append("pair '%s' uses unknown over token '%s'" % [entry["name"], over])
	return problems


func _role(role: String) -> Dictionary:
	if not type_roles.has(role):
		push_error("%s: unknown type role '%s'" % [id, role])
		return {}
	return type_roles[role]


static func _load_override_font() -> FontFile:
	if override_font_path.is_empty():
		return null
	if _override_font == null:
		var file: FontFile = FontFile.new()
		var err: Error = file.load_dynamic_font(override_font_path)
		if err != OK:
			push_error("could not load font file %s (error %d)" % [override_font_path, err])
			override_font_path = ""
			return null
		_override_font = file
	return _override_font
