extends RefCounted
## Bridges the tools over the 2026-10-21 change (ARCHITECTURE.md 17), when
## NumberFormat.tile_label and the SkinData tile methods move from a tile's
## value to its exponent k (the tile is 2^k). Core and the skins change in
## different waves, so each side is detected on its own:
##   - NumberFormat takes an exponent when the label of 10 is "1024";
##   - a skin takes an exponent when color_position(2) is ramp position 1
##     (the tile 4), not 0 (the tile 2).
## Once both have changed, the tools check every exponent up to
## GameConfig.max_exponent; before, up to 2^62.

## Highest exponent before the change (GDD D-37 then).
const OLD_MAX_POWER: int = 62


static func labels_by_exponent() -> bool:
	return NumberFormat.tile_label(10) == "1024"


## The game's label for the tile 2^power.
static func tile_label(power: int) -> String:
	if labels_by_exponent():
		return NumberFormat.tile_label(power)
	if power > OLD_MAX_POWER:
		return "2^%d" % power
	return NumberFormat.tile_label(1 << power)


static func skin_by_exponent(skin: SkinData) -> bool:
	return skin.color_position(2) == 1


## What to pass a skin's tile methods for the tile 2^power.
static func skin_arg(skin: SkinData, power: int) -> int:
	return power if skin_by_exponent(skin) else 1 << power


## The highest exponent the tools check: GameConfig.max_exponent once both
## sides take exponents, else 62.
static func highest_power(skin: SkinData) -> int:
	if not skin_by_exponent(skin):
		return OLD_MAX_POWER
	var ceiling: Variant = GameConfig.new().get("max_exponent")
	return int(ceiling) if ceiling != null else OLD_MAX_POWER


## The ramp position DESIGN_SYSTEM.md 3.3 gives the tile 2^power, worked out
## from the rule itself: k - 1 up to 17, then round the cycle.
static func rule_position(power: int, ramp_size: int, cycle: PackedInt32Array) -> int:
	if power <= ramp_size:
		return power - 1
	return cycle[(power - ramp_size - 1) % cycle.size()]
