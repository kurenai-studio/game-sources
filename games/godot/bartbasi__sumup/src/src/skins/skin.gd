class_name SkinData extends Resource
## The Skin of docs/ARCHITECTURE.md section 6. Godot 4.7 has a native class
## named Skin (the skeleton skin resource), and a script class may not hide a
## native class, so this one is named SkinData.
##
## Every visual value of one built in skin: palette, tile ramp, type, sizes and
## motion, as docs/DESIGN_SYSTEM.md specifies them. One .tres per skin lives in
## src/skins/<id>/. The senior-graphic-designer specifies the values, the
## tile-board-artist writes the files, the senior-graphic-designer reviews them.
##
## Read values only through the methods below. A missing token is a bug: the
## getter reports it once with push_error and returns a visible fallback
## (magenta for colors, 0 for numbers). validate() lets tests catch it first.

## Lowest and highest value the ramp lists. Index 0 is value 2, index 16 is
## value 131072. Tiles are passed to the methods below by exponent k (the
## tile is 2^k, docs/ARCHITECTURE.md 17): k from 1 to 17 is the ramp, and
## every k above 17 takes its colors from tile_cycle (DESIGN_SYSTEM.md 3.3)
## and its tier from beyond_tier, up to GameConfig.max_exponent.
const RAMP_LOW: int = 2
const RAMP_HIGH: int = 131072
const RAMP_SIZE: int = 17
## Shortest color cycle allowed: no two of any 13 consecutive values may
## share a fill (DESIGN_SYSTEM.md 3.3).
const CYCLE_MIN: int = 13
## Exponent of the first tile that walks the color cycle (2^18, 256K).
const CYCLE_FIRST_POWER: int = 18

## Case rules a type role can carry.
const CASE_NONE: String = "none"
const CASE_UPPER: String = "upper"
const CASE_LOWER: String = "lower"

## The shared schema (DESIGN_SYSTEM.md section 3). Every skin defines every
## name below; anything else in a dictionary is that skin's extra.
const TYPE_ROLES: Array[StringName] = [&"display", &"title", &"body", &"label", &"tile", &"heading", &"reading"]
const SHARED_PALETTE: Array[StringName] = [
	&"bg", &"surface", &"surface_raised", &"line", &"ink", &"ink_muted", &"ink_dark",
	&"accent", &"accent_pressed", &"disabled_ink", &"chain", &"target", &"joinable",
	&"scrim", &"badge", &"badge_ink",
]
const SHARED_NUMBERS: Array[StringName] = [
	&"board_margin", &"board_gap", &"board_padding", &"tile_radius", &"label_fit",
	&"display_fit_min", &"preview_scale", &"special_from", &"chain_width",
	&"chain_ring", &"joinable_ring", &"target_ring", &"space_xs", &"space_s",
	&"space_m", &"space_l", &"space_xl", &"touch_min", &"radius_button",
	&"radius_card", &"radius_chip", &"hairline", &"hud_height", &"bar_height",
	&"hint_height", &"button_height", &"row_height", &"icon_booster", &"icon_hud",
	&"icon_stroke", &"toggle_w", &"toggle_h", &"toggle_knob", &"notice_height",
	&"notice_tile_scale", &"notice_strike", &"star_icon", &"reading_line_spacing",
	&"scroll_bar",
]
const MOTION_NAMES: Array[StringName] = [
	&"spawn", &"fall", &"chain_add", &"chain_remove", &"joinable_in",
	&"merge_travel", &"merge_pop", &"clear", &"clear_notice", &"press",
	&"button_press", &"button_release", &"dialog_in", &"dialog_out",
	&"screen_fade", &"target_pulse", &"score_count", &"skin_switch", &"star_earn",
	&"star_convert",
]

## Shown where a token is missing, so the bug is visible on screen.
const MISSING_COLOR: Color = Color.MAGENTA
## Used when the tile font has no label scale at all.
const FALLBACK_TILE_SIZE: int = 1

@export var id: StringName = &""
## Shown in the skin picker.
@export var display_name: String = ""
## Named colors: the shared roles plus this skin's extras.
@export var palette: Dictionary[StringName, Color] = {}
## Fill and number color for 2, 4, 8 ... 131072, 17 entries each.
@export var tile_fill: PackedColorArray = PackedColorArray()
@export var tile_ink: PackedColorArray = PackedColorArray()
## Ramp positions, in order, that the values above 131072 walk round:
## the tile 2^k with k of 18 or more takes the fill and number color of
## tile_cycle[(k - 18) mod size] (DESIGN_SYSTEM.md 3.3).
@export var tile_cycle: PackedInt32Array = PackedInt32Array()
## Tier per value 2 to 131072, 17 entries. What a tier changes is per skin.
@export var tile_tier: PackedInt32Array = PackedInt32Array()
@export var beyond_tier: int = 0
## Every text color on background pair the screens may use. Each entry:
##   name: where the pair appears
##   fg, bg: palette tokens
##   over: when bg has alpha, what it sits over in the worst case (a palette
##     token or "tile:<value>"); "" otherwise
##   min: minimum contrast ratio
@export var text_pairs: Array[Dictionary] = []
## "" for the system font, else a res:// font file.
@export var font_path: String = ""
## SystemFont preference list, used when font_path is "".
@export var system_font_names: PackedStringArray = PackedStringArray()
## display, title, body, label, tile, heading, reading. Each holds size (px,
## not for tile), weight (100 to 900), tracking (px between glyphs) and case.
@export var type_roles: Dictionary[StringName, Dictionary] = {}
## Tile label size by label length (1 to 4 characters), share of the tile side.
## Labels of 5 and 6 characters start from the 4 character size (2.5).
@export var tile_number_scale: PackedFloat32Array = PackedFloat32Array()
## Spacing, radii, sizes and shares: the shared names plus this skin's extras.
@export var numbers: Dictionary[StringName, float] = {}
## Motion name to {duration, trans, ease} plus the extras the skin lists.
@export var motion: Dictionary[StringName, Dictionary] = {}

static var _max_exponent: int = 0

var _font_cache: Dictionary[StringName, Font] = {}
var _base_font: Font = null
var _reported: Dictionary[String, bool] = {}


## Ramp index for a tile value (not an exponent): 0 for 2, 16 for 131072,
## RAMP_SIZE for any power of two above 131072, and -1 for anything that is
## not a power of two of at least 2. Value tokens such as special_from and
## "tile:<value>" references name values; exponent_of turns them into k.
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


## The exponent of a value token: 1 for 2, 17 for 131072, 62 for 2^62. -1 for
## anything that is not a power of two of at least 2.
static func exponent_of(value: int) -> int:
	if value < RAMP_LOW or (value & (value - 1)) != 0:
		return -1
	var power: int = 0
	var v: int = value
	while v > 1:
		v = v >> 1
		power += 1
	return power


## Highest exponent a tile may hold (GameConfig.max_exponent), read once.
static func max_exponent() -> int:
	if _max_exponent <= 0:
		_max_exponent = GameConfig.new().max_exponent
	return _max_exponent


## True for the exponent of a tile: 1 to max_exponent().
static func is_tile(exponent: int) -> bool:
	return exponent >= 1 and exponent <= max_exponent()


## Ramp position whose fill and number color the tile 2^exponent takes
## (DESIGN_SYSTEM.md 3.3): exponent - 1 from 1 to 17, then round tile_cycle.
## Plain int math, so it holds up to max_exponent. -1 for anything that is
## not a tile, or when the cycle is missing or holds a position outside the
## ramp.
func color_position(exponent: int) -> int:
	if not _checked_tile(exponent):
		return -1
	if exponent <= RAMP_SIZE:
		return exponent - 1
	if tile_cycle.is_empty():
		_report("tile_cycle", "%s: tile_cycle is empty" % id)
		return -1
	var position: int = tile_cycle[(exponent - CYCLE_FIRST_POWER) % tile_cycle.size()]
	if position < 0 or position >= RAMP_SIZE:
		_report("tile_cycle", "%s: tile_cycle holds %d, outside the ramp" % [id, position])
		return -1
	return position


## Tile fill for the tile 2^exponent.
func fill_for(exponent: int) -> Color:
	var position: int = color_position(exponent)
	if position < 0 or tile_fill.size() != RAMP_SIZE:
		return MISSING_COLOR
	return tile_fill[position]


## Number color for the tile 2^exponent.
func ink_for(exponent: int) -> Color:
	var position: int = color_position(exponent)
	if position < 0 or tile_ink.size() != RAMP_SIZE:
		return MISSING_COLOR
	return tile_ink[position]


## Tier for the tile 2^exponent: tile_tier up to 17, beyond_tier above. 0 for
## anything that is not a tile.
func tier_for(exponent: int) -> int:
	if not _checked_tile(exponent) or tile_tier.size() != RAMP_SIZE:
		return 0
	if exponent > RAMP_SIZE:
		return beyond_tier
	return tile_tier[exponent - 1]


## The exponent of a value token of this skin (special_from, Nova's
## dark_rim_from): the token keeps its written value and the code compares
## exponents (DESIGN_SYSTEM.md 14.3). -1 when the token is missing or not a
## power of two.
func token_exponent(token: StringName) -> int:
	var power: int = exponent_of(int(num(token)))
	if power < 0:
		_report("exponent:%s" % token, "%s: %s is not a tile value" % [id, token])
	return power


## A named palette color.
func color(token: StringName) -> Color:
	if not palette.has(token):
		_report("color:%s" % token, "%s: unknown palette token '%s'" % [id, token])
		return MISSING_COLOR
	return palette[token]


## A spacing, radius, size or share.
func num(token: StringName) -> float:
	if not numbers.has(token):
		_report("num:%s" % token, "%s: unknown number token '%s'" % [id, token])
		return 0.0
	return numbers[token]


## A motion spec: duration, trans, ease and its extras.
func motion_spec(motion_name: StringName) -> Dictionary:
	if not motion.has(motion_name):
		_report("motion:%s" % motion_name, "%s: unknown motion '%s'" % [id, motion_name])
		return {"duration": 0.0, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT}
	return motion[motion_name]


## Duration of a motion in seconds. For loops, the period; 0 means still.
func duration(motion_name: StringName) -> float:
	return float(motion_spec(motion_name).get("duration", 0.0))


## The font for a type role: the skin's font with the role's weight (on the
## wght axis for a font file) and tracking. Made once per role and cached.
func font(role: StringName) -> Font:
	if _font_cache.has(role):
		return _font_cache[role]
	var spec: Dictionary = _role(role)
	var weight: int = int(spec.get("weight", 400))
	var variation: FontVariation = FontVariation.new()
	var file: Font = _font_file()
	if file != null:
		variation.base_font = file
		# The weight axis must be keyed by its integer tag. The string key
		# "wght" is ignored in Godot 4.7.
		var weight_tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		variation.variation_opentype = {weight_tag: weight}
	else:
		var system: SystemFont = SystemFont.new()
		system.font_names = system_font_names
		system.font_weight = weight
		variation.base_font = system
	variation.spacing_glyph = int(spec.get("tracking", 0))
	_font_cache[role] = variation
	return variation


## Font size in px for a type role. The tile role has no fixed size; use
## tile_font_size() for tile labels.
func font_size(role: StringName) -> int:
	return int(_role(role).get("size", 0))


## Font size in px for a tile label: the label scale for its length times the
## tile side (Nova: the orb diameter), shrunk until the label is no wider than
## label_fit of the side (DESIGN_SYSTEM.md 2.5).
func tile_font_size(tile_side: float, label: String) -> int:
	if tile_number_scale.is_empty():
		_report("tile_number_scale", "%s: tile_number_scale is empty" % id)
		return FALLBACK_TILE_SIZE
	var length_index: int = clampi(label.length(), 1, tile_number_scale.size()) - 1
	var size: int = maxi(1, roundi(tile_side * tile_number_scale[length_index]))
	var limit: float = num(&"label_fit") * tile_side
	var tile_font: Font = font(&"tile")
	var width: float = _text_width(tile_font, label, size)
	if width <= limit:
		return size
	size = maxi(1, floori(float(size) * limit / width))
	width = _text_width(tile_font, label, size)
	while width > limit and size > 1:
		size -= 1
		width = _text_width(tile_font, label, size)
	return size


## Font size in px for the score: the display size, shrunk until text fits
## max_width, never below display_fit_min (DESIGN_SYSTEM.md 2.6).
func score_font_size(text: String, max_width: float) -> int:
	var size: int = font_size(&"display")
	var smallest: int = int(num(&"display_fit_min"))
	var display_font: Font = font(&"display")
	var width: float = _text_width(display_font, text, size)
	if width <= max_width or size <= smallest:
		return size
	size = clampi(floori(float(size) * max_width / width), smallest, size)
	width = _text_width(display_font, text, size)
	while width > max_width and size > smallest:
		size -= 1
		width = _text_width(display_font, text, size)
	return size


## Applies the role's case rule to a text. Never use it on tile labels.
func cased(role: StringName, text: String) -> String:
	var rule: String = String(_role(role).get("case", CASE_NONE))
	if rule == CASE_UPPER:
		return text.to_upper()
	if rule == CASE_LOWER:
		return text.to_lower()
	return text


## Checks that every schema token is present and well formed. Returns the
## problems, empty when the skin is valid.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"" or display_name.is_empty():
		problems.append("id and display_name must be set")
	if tile_fill.size() != RAMP_SIZE:
		problems.append("tile_fill has %d colors, needs %d" % [tile_fill.size(), RAMP_SIZE])
	if tile_ink.size() != RAMP_SIZE:
		problems.append("tile_ink has %d colors, needs %d" % [tile_ink.size(), RAMP_SIZE])
	if tile_tier.size() != RAMP_SIZE:
		problems.append("tile_tier has %d entries, needs %d" % [tile_tier.size(), RAMP_SIZE])
	if tile_cycle.size() < CYCLE_MIN:
		problems.append("tile_cycle has %d entries, needs at least %d" % [tile_cycle.size(), CYCLE_MIN])
	var seen: Dictionary[int, bool] = {}
	for position: int in tile_cycle:
		if position < 0 or position >= RAMP_SIZE:
			problems.append("tile_cycle holds %d, needs 0 to %d" % [position, RAMP_SIZE - 1])
		elif seen.has(position):
			problems.append("tile_cycle holds %d twice" % position)
		seen[position] = true
	for token: StringName in SHARED_PALETTE:
		if not palette.has(token):
			problems.append("missing palette role '%s'" % token)
	for token: StringName in SHARED_NUMBERS:
		if not numbers.has(token):
			problems.append("missing number '%s'" % token)
	for role: StringName in TYPE_ROLES:
		if not type_roles.has(role):
			problems.append("missing type role '%s'" % role)
			continue
		var spec: Dictionary = type_roles[role]
		for key: String in ["size", "weight", "tracking", "case"]:
			if key == "size" and role == &"tile":
				continue
			if not spec.has(key):
				problems.append("type role '%s' has no %s" % [role, key])
		var rule: String = String(spec.get("case", ""))
		if rule != CASE_NONE and rule != CASE_UPPER and rule != CASE_LOWER:
			problems.append("type role '%s' has unknown case '%s'" % [role, rule])
	if tile_number_scale.size() != 4:
		problems.append("tile_number_scale needs 4 entries (1 to 4 characters)")
	for motion_name: StringName in MOTION_NAMES:
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
			if not _is_color_ref(String(entry.get(key, ""))):
				problems.append("pair '%s' uses unknown %s token '%s'" % [entry.get("name", ""), key, entry.get(key, "")])
		var over: String = String(entry.get("over", ""))
		if not over.is_empty() and not _is_color_ref(over):
			problems.append("pair '%s' uses unknown over token '%s'" % [entry.get("name", ""), over])
	if font_path.is_empty():
		if system_font_names.is_empty():
			problems.append("system_font_names is empty and there is no font_path")
	elif not ResourceLoader.exists(font_path):
		problems.append("font_path '%s' does not exist" % font_path)
	return problems


func _role(role: StringName) -> Dictionary:
	if not type_roles.has(role):
		_report("role:%s" % role, "%s: unknown type role '%s'" % [id, role])
		return {}
	return type_roles[role]


func _checked_tile(exponent: int) -> bool:
	if is_tile(exponent):
		return true
	_report("exponent:%d" % exponent, "%s: %d is not a tile exponent" % [id, exponent])
	return false


## The font file, loaded once. null for the system font, or when the file is
## missing (reported once).
func _font_file() -> Font:
	if font_path.is_empty():
		return null
	if _base_font == null:
		_base_font = load(font_path) as Font
		if _base_font == null:
			_report("font", "%s: could not load font '%s', using the system font" % [id, font_path])
	return _base_font


## A palette token, or "tile:<value>" for a tile fill.
func _is_color_ref(ref: String) -> bool:
	if ref.begins_with("tile:"):
		return ramp_index(ref.substr(5).to_int()) >= 0
	return palette.has(StringName(ref))


static func _text_width(text_font: Font, text: String, size: int) -> float:
	return text_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


func _report(key: String, message: String) -> void:
	if _reported.has(key):
		return
	_reported[key] = true
	push_error(message)
