extends SceneTree
## Tile ramp distinctness check for the skins that ship.
##
## Run from the repo root:
##     godot --headless --path . --script res://tools/ramp_check.gd
##
## Small tile clearing (GDD D-38) keeps about ten consecutive values on the
## board, up to 13 right after a long chain, and the four values of the spawn
## window are the common ones. So any four consecutive tiles must look
## clearly different at a glance, and no two of any 13 consecutive values may
## share a fill. Up to 131072 a value takes its own ramp position; above, it
## walks round the skin's color cycle (DESIGN_SYSTEM.md 3.3, tile_cycle in
## tools/directions/<id>/tokens.gd).
##
## For every skin in SkinCatalog.IDS this loads the SkinData resource the game
## uses (through SkinCatalog.get_skin) and measures the OKLab distance between
## the fills that rule gives, over every tile from 2 to 2^62 (after the
## 2026-10-21 change, every exponent up to GameConfig.max_exponent; see
## tools/number_api.gd):
##   - neighbors (one value and its double) at least 0.17
##   - two steps apart (times 4) at least 0.12
##   - three steps apart (times 8) at least 0.09
##   - four to twelve steps apart: never the same fill (at least 0.02)
##   - every tile fill against the background at least 0.15
## It also checks that the skin's own fill_for and ink_for follow the rule
## for every value, so the game draws what was measured.
## OKLab distance is close to how different two colors look; 0.02 is about
## the smallest visible step. Prints every neighbor pair up to 131072, the
## pairs that cross from the ramp into the cycle or wrap round the cycle the
## first time, and every failure. Exits with code 0 when all pass and 1
## otherwise.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const NumberApi: GDScript = preload("res://tools/number_api.gd")

const MIN_BY_STEP: PackedFloat32Array = [0.17, 0.12, 0.09]
## Further apart than three steps, two fills only need to differ visibly.
const MIN_DIFFERENT: float = 0.02
## Values on the board at once, at most (floor H/512 to H plus a long chain).
const WINDOW: int = 13
const MIN_AGAINST_BG: float = 0.15

var _checked: int = 0
var _failed: int = 0


func _initialize() -> void:
	print("Ramp distinctness check, OKLab distance between tile fills, from 2 up to each skin's highest tile.")
	print("Needed: neighbors %.2f, times 4 %.2f, times 8 %.2f, 4 to %d steps apart %.2f, against the background %.2f." % [MIN_BY_STEP[0], MIN_BY_STEP[1], MIN_BY_STEP[2], WINDOW - 1, MIN_DIFFERENT, MIN_AGAINST_BG])
	for skin_id: StringName in SkinCatalog.IDS:
		_check(skin_id)
	print("")
	print("%s: %d pairs checked, %d failed." % ["PASS" if _failed == 0 else "FAIL", _checked, _failed])
	quit(0 if _failed == 0 else 1)


static func label(power: int) -> String:
	return NumberApi.tile_label(power)


func _check(skin_id: StringName) -> void:
	print("")
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	if skin == null or skin.id != skin_id:
		_record(false, "  %s: skin resource missing, broken, or not this skin" % skin_id, true)
		return
	if skin.tile_fill.size() != SkinData.RAMP_SIZE or skin.tile_ink.size() != SkinData.RAMP_SIZE or not skin.palette.has(&"bg"):
		_record(false, "  %s: tile_fill and tile_ink need %d colors and the palette needs bg" % [skin_id, SkinData.RAMP_SIZE], true)
		return
	var tokens: DirectionTokens = Directions.load_tokens(String(skin_id))
	if tokens == null or tokens.tile_cycle.size() < WINDOW:
		_record(false, "  %s: the color cycle in tokens.gd is missing or shorter than %d" % [skin_id, WINDOW], true)
		return
	var max_power: int = NumberApi.highest_power(skin)
	print("%s (%s), color cycle %s, tiles 2 to 2^%d" % [skin.display_name, skin.resource_path, tokens.tile_cycle, max_power])
	var positions: PackedInt32Array = PackedInt32Array()
	positions.resize(max_power + 1)
	for power: int in range(1, max_power + 1):
		positions[power] = NumberApi.rule_position(power, SkinData.RAMP_SIZE, tokens.tile_cycle)
	# The rule as written here agrees with the token mirror's own lookup.
	for power: int in range(1, NumberApi.OLD_MAX_POWER + 1):
		_record(positions[power] == tokens.color_position(1 << power), "  %s: the token mirror gives ramp position %d" % [label(power), tokens.color_position(1 << power)], false)
	var bg: Vector3 = oklab(skin.color(&"bg"))
	for i: int in skin.tile_fill.size():
		var a: Vector3 = oklab(skin.tile_fill[i])
		_record(a.distance_to(bg) >= MIN_AGAINST_BG, "  %s against the background: %.3f" % [label(i + 1), a.distance_to(bg)], false)
	var worst: PackedFloat32Array = [INF, INF, INF, INF]
	var first_wrap: int = SkinData.RAMP_SIZE + tokens.tile_cycle.size()
	for power: int in range(1, max_power + 1):
		var a: Vector3 = oklab(skin.tile_fill[positions[power]])
		for step: int in range(1, WINDOW):
			var other: int = power + step
			if other > max_power:
				break
			var distance: float = a.distance_to(oklab(skin.tile_fill[positions[other]]))
			var needed: float = MIN_BY_STEP[step - 1] if step <= 3 else MIN_DIFFERENT
			var slot: int = mini(step, 4) - 1
			worst[slot] = minf(worst[slot], distance)
			var neighbor_in_ramp: bool = step == 1 and other <= SkinData.RAMP_SIZE
			var crossing: bool = step <= 3 and ((power <= SkinData.RAMP_SIZE and other > SkinData.RAMP_SIZE) or (power <= first_wrap and other > first_wrap))
			_record(distance >= needed, "  %s and %s (%d steps): %.3f" % [label(power), label(other), step, distance], neighbor_in_ramp or crossing)
	print("  closest: neighbors %.3f, times 4 %.3f, times 8 %.3f, 4 to %d steps %.3f" % [worst[0], worst[1], worst[2], WINDOW - 1, worst[3]])
	# The game's own lookups must follow the rule.
	var off: int = 0
	for power: int in range(1, max_power + 1):
		var position: int = positions[power]
		var value: int = NumberApi.skin_arg(skin, power)
		var same: bool = skin.fill_for(value) == skin.tile_fill[position] and skin.ink_for(value) == skin.tile_ink[position]
		_record(same, "  %s: fill_for and ink_for give ramp position %d" % [label(power), position], false)
		if not same:
			off += 1
	print("  fill_for and ink_for follow the rule for %d of %d tiles" % [max_power - off, max_power])


## Counts a check. Shown pairs and failures are printed; the rest only count.
func _record(ok: bool, text: String, always_print: bool) -> void:
	_checked += 1
	if not ok:
		_failed += 1
	if always_print or not ok:
		print("%s%s" % ["PASS" if ok else "FAIL", text])


## sRGB color to OKLab (L, a, b).
static func oklab(c: Color) -> Vector3:
	var r: float = _linear(c.r)
	var g: float = _linear(c.g)
	var b: float = _linear(c.b)
	var l: float = pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m: float = pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s: float = pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


static func _linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)
