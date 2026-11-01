extends SceneTree
## Tile label and score width check for the skins that ship.
##
## Run from the repo root:
##     godot --headless --path . --script res://tools/label_check.gd
##
## For every skin in SkinCatalog.IDS this loads the SkinData resource the game
## uses (through SkinCatalog.get_skin) and checks, in the skin's own fonts:
##
## 1. Game labels. Every label the game's NumberFormat.tile_label gives, sized
##    exactly as the game sizes it (skin.tile_font_size, which shrinks a label
##    until it is no wider than label_fit of the side), on the skin's smallest
##    full spec tile (DESIGN_SYSTEM.md 2.4). Before the 2026-10-21 change that
##    is 2 to 2^49; after it, every exponent up to GameConfig.max_exponent
##    (tools/number_api.gd tells the two apart).
## 2. Worst cases for unlimited numbers (DESIGN_SYSTEM.md 13.1), whatever
##    letter scheme the GDD picks: every leading number 1 to 512 with one
##    named unit (K, M, B, T, Q), with two letters from every pair in three
##    casings (AB, ab, Ab), and with three letters. Checked on the smallest
##    full spec tile and on the smallest 16:9 tile.
## 3. Small tiles: the record row mini tile, the clear notice mini tile and
##    the merge preview with the widest two letter labels. They must fit;
##    their sizes are reported.
## 4. Booster costs and scores on the 1080 px canvas, the narrowest: the
##    widest cost in the label role against its room, and the widest 15
##    character score (10 digits, commas and two letters) in every place a
##    score shows, fitted as the game fits it.
##
## The digit rule by label kind (DESIGN_SYSTEM.md 13.1, GDD A-1):
##   - no letter or one letter: digits at least 12 dp on the skin's smallest
##     full spec tile, and the same share of the side on 16:9 (2.4: 16:9
##     phones get smaller tiles with the same proportions);
##   - two letters: digits at least TWO_LETTER_SHARE of the side, every phone;
##   - three letters (past about 2^6800, only a tampered save): fit only.
## Every label must fit within label_fit of the side.
##
## Exits with code 0 when every check passes and 1 otherwise.
##
## Slate's system font resolves to Segoe UI here (Windows). Roboto, the
## Android system font, has slightly taller digits (cap height 0.711 of the
## size against Segoe UI's 0.700) and sets slightly tighter, so a pass here
## holds on Android too.

const NumberApi: GDScript = preload("res://tools/number_api.gd")

## GDD section 18: MIN_LABEL_DIGIT_HEIGHT_DP.
const MIN_DIGIT_DP: float = 12.0
## Smallest digit height of a two letter label, share of the tile side
## (DESIGN_SYSTEM.md 13.1).
const TWO_LETTER_SHARE: float = 0.15
## Each skin's smallest full spec tile in dp, DESIGN_SYSTEM.md 2.4 (the
## smallest of 20:9, 18:9 and the Fold5 cover screen). Nova: the orb diameter.
const SMALLEST_TILE_DP: Dictionary[StringName, float] = {
	&"gumdrop": 56.9,
	&"slate": 59.6,
	&"nova": 56.3,
}
## Each skin's smallest 16:9 tile in dp (DESIGN_SYSTEM.md 2.4, 48 dp button bar).
const SMALLEST_16_9_DP: Dictionary[StringName, float] = {
	&"gumdrop": 46.9,
	&"slate": 49.3,
	&"nova": 48.0,
}
## Pixels per dp: the game renders at 1080 px wide on a 360 dp screen.
const DENSITY: float = 3.0
## The narrowest canvas: phones taller than 9:20 keep 1080 px (2.1).
const CANVAS_WIDTH: float = 1080.0
## Font size the digit outlines are measured at, then scaled.
const MEASURE_SIZE: int = 400
## Before the 2026-10-21 change: labels from 2^1 to 2^49.
const OLD_HIGHEST_POWER: int = 49
## Record row mini tiles, px (DESIGN_SYSTEM.md 7.9, 96 since 2026-10-21).
const RECORD_MINI_TILE: float = 96.0
## Room for the cost line at 1080 px, px: Gumdrop the 187 px face less
## space_xs each side; Slate the 198 px column less space_s each side; Nova
## the 198 px slot less space_xs each side.
const COST_ROOM: Dictionary[StringName, float] = {
	&"gumdrop": 163.0,
	&"slate": 158.0,
	&"nova": 174.0,
}
## Gumdrop HUD: where the star and free pills end at most at 1080 px, with
## two digit counts (4.7).
const GUMDROP_LEFT_PILLS_END: float = 540.0
## Nova HUD: room the star counter needs left of the best line, and the free
## count right of it, px (a star, a gap and two digits; "9 free").
const NOVA_SIDE_NEED: float = 110.0

## GDD 14.1: the suffix letters, a to z without l and o.
const SUFFIX_LETTERS: String = "abcdefghijkmnpqrstuvwxyz"

var _failed: int = 0
var _checked: int = 0


func _initialize() -> void:
	print("Label and score width check (DESIGN_SYSTEM.md 13).")
	var game_labels: Dictionary[String, PackedStringArray] = _game_labels()
	var worst: Dictionary[String, PackedStringArray] = _worst_labels()
	for skin_id: StringName in SkinCatalog.IDS:
		_check_skin(skin_id, game_labels, worst)
	print("")
	print("%s: %d checks, %d failed." % ["PASS" if _failed == 0 else "FAIL", _checked, _failed])
	quit(0 if _failed == 0 else 1)


## The labels the game shows, grouped by kind.
func _game_labels() -> Dictionary[String, PackedStringArray]:
	var groups: Dictionary[String, PackedStringArray] = {}
	var by_exponent: bool = NumberApi.labels_by_exponent()
	var highest: int = OLD_HIGHEST_POWER
	if by_exponent:
		var ceiling: Variant = GameConfig.new().get("max_exponent")
		highest = int(ceiling) if ceiling != null else NumberApi.OLD_MAX_POWER
	print("Game labels %s, 2^1 to 2^%d." % ["by exponent" if by_exponent else "by value (before the unlimited change)", highest])
	for power: int in range(1, highest + 1):
		var label: String = NumberApi.tile_label(power)
		if label.length() < 1 or label.length() > 6:
			print("  FAIL label for 2^%d is '%s', not 1 to 6 characters" % [power, label])
			_checked += 1
			_failed += 1
			continue
		_add(groups, label)
	return groups


## Every label shape GDD 14.1 gives: the leading numbers 1 to 512 with a
## named unit (K, M, B, T, Q), with every two letter suffix, and with three
## letter suffixes. Suffix letters are lowercase a to z without l and o. For
## three letters only the widest matter: every letter tripled, and every
## triple of m and w.
func _worst_labels() -> Dictionary[String, PackedStringArray]:
	var groups: Dictionary[String, PackedStringArray] = {}
	var pairs: PackedStringArray = PackedStringArray()
	for first: int in SUFFIX_LETTERS.length():
		for second: int in SUFFIX_LETTERS.length():
			pairs.append(SUFFIX_LETTERS[first] + SUFFIX_LETTERS[second])
	var triples: PackedStringArray = PackedStringArray()
	for letter: int in SUFFIX_LETTERS.length():
		triples.append(SUFFIX_LETTERS[letter].repeat(3))
	for first: String in ["m", "w"]:
		for second: String in ["m", "w"]:
			for third: String in ["m", "w"]:
				triples.append(first + second + third)
	for power: int in 10:
		var lead: String = str(1 << power)
		for unit: String in ["K", "M", "B", "T", "Q"]:
			_add(groups, lead + unit)
		for pair: String in pairs:
			_add(groups, lead + pair)
		for triple: String in triples:
			_add(groups, lead + triple)
	return groups


static func _letters(label: String) -> int:
	var letters: int = 0
	for index: int in label.length():
		if not label[index].is_valid_int():
			letters += 1
	return letters


static func _add(groups: Dictionary[String, PackedStringArray], label: String) -> void:
	var letters: int = _letters(label)
	var kind: String = "%d characters, %d letter%s" % [label.length(), letters, "" if letters == 1 else "s"]
	if not groups.has(kind):
		groups[kind] = PackedStringArray()
	groups[kind].append(label)


## Smallest digit height a label must keep, as a share of the tile side; 0
## when it only has to fit. full_spec_dp is the skin's smallest full spec tile.
static func _digit_rule(letters: int, full_spec_dp: float) -> float:
	if letters <= 1:
		return MIN_DIGIT_DP / full_spec_dp
	if letters == 2:
		return TWO_LETTER_SHARE
	return 0.0


func _check_skin(skin_id: StringName, game_labels: Dictionary[String, PackedStringArray], worst: Dictionary[String, PackedStringArray]) -> void:
	print("")
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	if skin == null or skin.id != skin_id:
		_fail_skin(skin_id, "skin resource missing, broken, or not this skin")
		return
	if not skin.type_roles.has(&"tile") or skin.tile_number_scale.size() < 4 or not skin.numbers.has(&"label_fit"):
		_fail_skin(skin_id, "the tile type role, tile_number_scale or label_fit is missing")
		return
	if not skin.font_path.is_empty() and not ResourceLoader.exists(skin.font_path):
		_fail_skin(skin_id, "font file %s is missing" % skin.font_path)
		return
	if not SMALLEST_TILE_DP.has(skin_id) or not SMALLEST_16_9_DP.has(skin_id) or not COST_ROOM.has(skin_id):
		_fail_skin(skin_id, "no tile sizes or cost room for this skin")
		return
	var font: Font = skin.font(&"tile")
	# A variable font reports its default instance name ("Outfit Thin"), so
	# name the file instead; for the system font, name what it resolved to.
	var source: String = skin.font_path
	if source.is_empty():
		source = "system font, here %s" % font.get_font_name()
	var fit: float = skin.num(&"label_fit")
	print("%s: %s, tile weight %d, labels fit within %d%% of the side" % [
		skin.display_name, source, int(skin.type_roles[&"tile"].get("weight", 0)), roundi(fit * 100.0)])
	var digit_share: float = _digit_height(font) / float(MEASURE_SIZE)

	var tile_dp: float = SMALLEST_TILE_DP[skin_id]
	print(" Game labels on the %.1f dp tile:" % tile_dp)
	for kind: String in _sorted(game_labels):
		_check_labels(skin, font, digit_share, game_labels[kind], kind, tile_dp * DENSITY, tile_dp)
	print(" Worst cases on the %.1f dp tile:" % tile_dp)
	for kind: String in _sorted(worst):
		_check_labels(skin, font, digit_share, worst[kind], kind, tile_dp * DENSITY, tile_dp)
	var small_dp: float = SMALLEST_16_9_DP[skin_id]
	print(" Worst cases on the %.1f dp 16:9 tile:" % small_dp)
	for kind: String in _sorted(worst):
		_check_labels(skin, font, digit_share, worst[kind], kind, small_dp * DENSITY, tile_dp)

	# Small tiles take the five character, two letter labels; they must fit.
	var five: PackedStringArray = worst.get("5 characters, 2 letters", PackedStringArray())
	var preview_side: float = tile_dp * DENSITY * skin.num(&"preview_scale")
	var notice_side: float = skin.num(&"notice_height") * skin.num(&"notice_tile_scale")
	print(" Small tiles, 5 characters with 2 letters (fit checked, sizes reported):")
	for item: Array in [["record row mini tile", RECORD_MINI_TILE], ["clear notice mini tile", notice_side], ["merge preview", preview_side]]:
		_check_labels(skin, font, digit_share, five, "%s, %d px" % [item[0], roundi(float(item[1]))], float(item[1]), 0.0)

	var all_costs: PackedStringArray = PackedStringArray()
	for kind: String in worst:
		all_costs.append_array(worst[kind])
	_check_costs(skin, all_costs)
	_check_scores(skin)


## Kinds in reading order: by length, then by letters.
static func _sorted(groups: Dictionary[String, PackedStringArray]) -> Array[String]:
	var kinds: Array[String] = []
	for kind: String in groups:
		kinds.append(kind)
	kinds.sort()
	return kinds


## Sizes every label as the game does; checks the smallest digits against the
## kind's rule (full_spec_dp 0: fit only) and the widest label against
## label_fit.
func _check_labels(skin: SkinData, font: Font, digit_share: float, labels: PackedStringArray, title: String, side_px: float, full_spec_dp: float) -> void:
	if labels.is_empty():
		return
	var fit: float = skin.num(&"label_fit")
	var needed: float = 0.0
	if full_spec_dp > 0.0:
		needed = _digit_rule(_letters(labels[0]), full_spec_dp)
	var smallest: String = ""
	var smallest_share: float = INF
	var smallest_size: int = 0
	var widest: String = ""
	var widest_share: float = 0.0
	for label: String in labels:
		var size_px: int = skin.tile_font_size(side_px, label)
		var share: float = float(size_px) * digit_share / side_px
		if share < smallest_share:
			smallest_share = share
			smallest_size = size_px
			smallest = label
		var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x / side_px
		if width > widest_share:
			widest_share = width
			widest = label
	var digit_ok: bool = smallest_share >= needed - 0.0001
	var fit_ok: bool = widest_share <= fit + 0.0001
	_checked += 2
	if not digit_ok:
		_failed += 1
	if not fit_ok:
		_failed += 1
	var rule: String = "fit only" if needed <= 0.0 else "needs %d%%" % ceili(needed * 100.0 - 0.0001)
	print("  %s %s (%d): smallest '%s' at %d px, digits %.1f px = %.1f dp = %d%% of the side (%s); widest '%s' %d%% of the side%s" % [
		"PASS" if digit_ok and fit_ok else "FAIL", title, labels.size(), smallest, smallest_size,
		smallest_share * side_px, smallest_share * side_px / DENSITY, floori(smallest_share * 100.0), rule,
		widest, roundi(widest_share * 100.0), "" if fit_ok else " (too wide)"])


## The widest cost in the label role against the booster's room.
func _check_costs(skin: SkinData, labels: PackedStringArray) -> void:
	var font: Font = skin.font(&"label")
	var size: int = skin.font_size(&"label")
	var widest: String = ""
	var widest_px: float = 0.0
	for label: String in labels:
		var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if width > widest_px:
			widest_px = width
			widest = label
	var room: float = COST_ROOM[skin.id]
	_report(" Booster cost: widest '%s' is %d px in the label role at %d px; room %d px" % [widest, roundi(widest_px), size, roundi(room)], widest_px <= room)


## The widest scores of GDD 14.2 in every place a score shows, at 1080 px:
## 13 characters (in full), 15 (two letters, the most normal play reaches;
## it must fit at display_fit_min or larger) and 16 (three letters, only a
## tampered save; it must fit, at any size). One letter (14 characters) is
## narrower than two.
func _check_scores(skin: SkinData) -> void:
	var display: Font = skin.font(&"display")
	var body: Font = skin.font(&"body")
	var label_font: Font = skin.font(&"label")
	var display_size: int = skin.font_size(&"display")
	var body_size: int = skin.font_size(&"body")
	var label_size: int = skin.font_size(&"label")
	var floor_size: int = int(skin.num(&"display_fit_min"))
	var margin: float = skin.num(&"board_margin")
	var digit: String = _widest_digit(display, display_size)
	var thirteen: String = "%s,%s,%s,%s" % [digit, digit.repeat(3), digit.repeat(3), digit.repeat(3)]
	var score: String = thirteen + _widest_suffix(display, display_size, 2)
	var sixteen: String = thirteen + _widest_suffix(display, display_size, 3)
	var best_digit: String = _widest_digit(body, body_size)
	var best: String = "%s,%s,%s,%s" % [best_digit, best_digit.repeat(3), best_digit.repeat(3), best_digit.repeat(3)] + _widest_suffix(body, body_size, 2)
	print(" Scores, worst cases '%s' (%d characters) and '%s' (%d), Best '%s':" % [score, score.length(), sixteen, sixteen.length(), best])

	# The HUD score's slot, as each HUD lays it out.
	var slot: float = 0.0
	if skin.id == &"gumdrop":
		slot = CANVAS_WIDTH - margin * 2.0
	elif skin.id == &"slate":
		var caption: float = label_font.get_string_size(skin.cased(&"label", "Best"), HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		var best_width: float = body.get_string_size(best, HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
		slot = CANVAS_WIDTH - margin * 2.0 - maxf(best_width, caption) - skin.num(&"space_s")
	else:
		slot = CANVAS_WIDTH - (margin + skin.num(&"hud_ring") + skin.num(&"space_xs")) * 2.0
	_check_score_slot(skin, display, "HUD score", thirteen, score, sixteen, slot, floor_size)

	# Best on the HUD.
	if skin.id == &"gumdrop":
		var pad: float = skin.num(&"space_s")
		var gap: float = skin.num(&"space_xs")
		var caption_width: float = label_font.get_string_size(skin.cased(&"label", "Best"), HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		var pill_room: float = CANVAS_WIDTH - margin - GUMDROP_LEFT_PILLS_END - skin.num(&"space_s")
		var number_room: float = pill_room - pad * 2.0 - caption_width - gap
		var fitted: int = _fit_size(body, best, body_size, number_room)
		_report(" HUD Best pill: number room %d px between the left pills and the margin; Best fits at %d px (body %d, label %d)" % [
			roundi(number_room), fitted, body_size, label_size], fitted >= label_size)
	elif skin.id == &"slate":
		var best_width_hud: float = body.get_string_size(best, HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
		_report(" HUD BEST column: %d px in the body role at %d px, leaving the score %d px" % [roundi(best_width_hud), body_size, roundi(slot)], slot > 0.0)
	else:
		var line: String = skin.cased(&"label", "Best") + " " + best
		var line_width: float = label_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		var side_room: float = (CANVAS_WIDTH - line_width) * 0.5 - skin.num(&"space_m") - margin
		_report(" HUD best line: '%s' is %d px; %d px each side for the counter and the free count (need %d)" % [
			line, roundi(line_width), roundi(side_room), roundi(NOVA_SIDE_NEED)], side_room >= NOVA_SIDE_NEED)

	# The end of run score: the column less margins and space_m each side.
	var end_slot: float = CANVAS_WIDTH - 2.0 * (margin + skin.num(&"space_m"))
	_check_score_slot(skin, display, "End of run score", thirteen, score, sixteen, end_slot, floor_size)

	# Record rows (splash, end of run, offer): body role, the row less its
	# caption; the end of run row also holds the New best badge.
	var caption_px: float = body.get_string_size(skin.cased(&"body", "Best score"), HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
	var badge_px: float = label_font.get_string_size(skin.cased(&"label", "New best"), HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x + skin.num(&"space_s") * 2.0
	var room_row: float = end_slot - caption_px - skin.num(&"space_s") * 2.0 - badge_px
	var best_px: float = body.get_string_size(best, HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
	_report(" Record row Best score with the New best badge: %d px at %d px; room %d px" % [roundi(best_px), body_size, roundi(room_row)], best_px <= room_row)


## Fits a score in a slot as the HUD does; it must stay at display_fit_min or
## larger.
func _check_score_slot(skin: SkinData, display: Font, title: String, thirteen: String, text: String, sixteen: String, slot: float, floor_size: int) -> void:
	var old_size: int = _fit_size(display, thirteen, skin.font_size(&"display"), slot)
	var new_size: int = _fit_size(display, text, skin.font_size(&"display"), slot)
	var long_size: int = _fit_size(display, sixteen, skin.font_size(&"display"), slot)
	var long_fits: bool = display.get_string_size(sixteen, HORIZONTAL_ALIGNMENT_LEFT, -1, long_size).x <= slot
	_report(" %s: slot %d px, display %d px; 13 characters fit at %d px, 15 at %d px, 16 at %d px; display_fit_min %d" % [
		title, roundi(slot), skin.font_size(&"display"), old_size, new_size, long_size, floor_size], new_size >= floor_size and long_fits)


func _report(text: String, ok: bool) -> void:
	_checked += 1
	if not ok:
		_failed += 1
	print(" %s%s" % ["PASS" if ok else "FAIL", text])


## The largest size up to start at which text is no wider than slot.
func _fit_size(font: Font, text: String, start: int, slot: float) -> int:
	var size: int = start
	while size > 1 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > slot:
		size -= 1
	return size


func _widest_digit(font: Font, size: int) -> String:
	var widest: String = "9"
	var widest_px: float = 0.0
	for digit: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		var width: float = font.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if width > widest_px:
			widest_px = width
			widest = digit
	return widest


## The widest suffix of count lowercase letters: the widest suffix letter
## repeated.
func _widest_suffix(font: Font, size: int, count: int) -> String:
	var widest: String = "m"
	var widest_px: float = 0.0
	for index: int in SUFFIX_LETTERS.length():
		var letter: String = SUFFIX_LETTERS[index]
		var width: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if width > widest_px:
			widest_px = width
			widest = letter
	return widest.repeat(count)


func _fail_skin(skin_id: StringName, problem: String) -> void:
	_checked += 1
	_failed += 1
	print("  FAIL %s: %s" % [skin_id, problem])


## Height of the shortest digit glyph at MEASURE_SIZE, from its outline.
## 0 when a digit cannot be measured, which fails every digit check.
func _digit_height(font: Font) -> float:
	var server: TextServer = TextServerManager.get_primary_interface()
	var shortest: float = INF
	for digit: String in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		var best: float = 0.0
		for rid: RID in font.get_rids():
			var glyph: int = server.font_get_glyph_index(rid, MEASURE_SIZE, digit.unicode_at(0), 0)
			if glyph == 0:
				continue
			var outline: Dictionary = server.font_get_glyph_contours(rid, MEASURE_SIZE, glyph)
			var points: PackedVector3Array = outline.get("points", PackedVector3Array())
			if points.is_empty():
				continue
			var top: float = INF
			var bottom: float = -INF
			for point: Vector3 in points:
				top = minf(top, point.y)
				bottom = maxf(bottom, point.y)
			best = bottom - top
			break
		if best <= 0.0:
			push_error("could not measure digit '%s'" % digit)
			return 0.0
		shortest = minf(shortest, best)
	return shortest
