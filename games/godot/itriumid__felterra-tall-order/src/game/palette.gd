class_name Palette
extends RefCounted
## Every color in the game, and nothing else: art, effects and the interface all pick from here.
## A test checks that every sprite uses only these colors.

# Outline, for characters and anything that can be hit or picked up. Warm, never black.
const OUTLINE := Color8(43, 29, 26)
# Shadows cast on the ground.
const GROUND_SHADOW := Color8(24, 22, 20)

# Fur: shadow, base, light, and the cream of muzzle and paws.
const FUR_SHADOW := Color8(170, 92, 42)
const FUR := Color8(226, 138, 62)
const FUR_LIGHT := Color8(248, 190, 116)
const CREAM := Color8(247, 234, 214)
## The other coats a cat comes in: gray, black and cream, each in shadow, base and light; and
## white, Tompel's, with his black markings in the black.
const GRAY_FUR_SHADOW := Color8(100, 102, 110)
const GRAY_FUR := Color8(148, 150, 158)
const GRAY_FUR_LIGHT := Color8(194, 196, 202)
const BLACK_FUR_SHADOW := Color8(52, 46, 50)
const BLACK_FUR := Color8(76, 68, 72)
const BLACK_FUR_LIGHT := Color8(110, 100, 102)
const CREAM_FUR_SHADOW := Color8(196, 164, 122)
const CREAM_FUR := Color8(226, 202, 160)
const CREAM_FUR_LIGHT := Color8(244, 230, 200)
const WHITE_FUR_SHADOW := Color8(184, 186, 196)
const WHITE_FUR := Color8(224, 226, 232)
const WHITE_FUR_LIGHT := Color8(248, 248, 250)
const NOSE := Color8(254, 191, 202)
const EYE := Color8(190, 230, 120)
const EYE_DARK := Color8(56, 90, 38)

# Cloth, leather, brass and steel for gear.
const CLOTH_SHADOW := Color8(44, 58, 90)
const CLOTH := Color8(76, 98, 142)
const CLOTH_LIGHT := Color8(112, 136, 184)
const SCARF_RED := Color8(176, 50, 46)
const LEATHER := Color8(96, 60, 34)
const LEATHER_LIGHT := Color8(140, 92, 50)
const BRASS := Color8(214, 168, 70)
const BRASS_LIGHT := Color8(238, 206, 120)
const STEEL_DARK := Color8(60, 66, 76)
const STEEL := Color8(138, 150, 164)
const STEEL_LIGHT := Color8(226, 232, 238)

# Rats.
const RAT_SHADOW := Color8(104, 84, 74)
const RAT := Color8(146, 122, 104)
const RAT_LIGHT := Color8(186, 164, 140)
const RAT_TAIL := Color8(196, 150, 150)

# The company's guard dogs.
const DOG_SHADOW := Color8(98, 66, 44)
const DOG := Color8(146, 104, 66)
const DOG_LIGHT := Color8(190, 148, 100)

# The cleared ground and the jungle around it.
const MUD_DARK := Color8(62, 44, 32)
const MUD := Color8(92, 66, 44)
const MUD_LIGHT := Color8(124, 92, 60)
const BURNT := Color8(48, 40, 36)
const JUNGLE_DEEP := Color8(16, 36, 24)
const JUNGLE_DARK := Color8(28, 60, 36)
const JUNGLE := Color8(44, 92, 48)
const LEAF := Color8(76, 130, 60)
const LEAF_LIGHT := Color8(128, 170, 80)
const MOSS := Color8(98, 118, 52)
const DRY_GRASS := Color8(154, 146, 78)
const BARK := Color8(86, 74, 62)
const BARK_LIGHT := Color8(128, 112, 92)

# The human company's workers: realistic, and easy to pick out of a crowd.
const HI_VIS := Color8(255, 120, 30)
## Paint for the village's walls, beside the reds, pinks, yellows and blues already here.
const PAINT_TEAL := Color8(52, 150, 142)
const SKIN := Color8(226, 176, 138)
const SKIN_SHADOW := Color8(184, 132, 100)

# Effects.
const BLOOD := Color8(150, 30, 36)
const BLOOD_DRY := Color8(92, 28, 30)
const SPARK := Color8(255, 230, 150)
const SMOKE := Color8(180, 176, 166)

# Interface: Itrium's Rhodonite, and the neutral surfaces around it: a panel's shadow and its lit
# edge.
const GRAPHITE := Color8(43, 43, 43)
const PANEL_DARK := Color8(28, 28, 30)
const PANEL_LIGHT := Color8(70, 70, 74)
const OFF_WHITE := Color8(242, 242, 242)
const PINK := Color8(254, 191, 202)

const ALL: Array[Color] = [
	OUTLINE, GROUND_SHADOW, FUR_SHADOW, FUR, FUR_LIGHT, CREAM, NOSE, EYE, EYE_DARK,
	GRAY_FUR_SHADOW, GRAY_FUR, GRAY_FUR_LIGHT, BLACK_FUR_SHADOW, BLACK_FUR, BLACK_FUR_LIGHT,
	CREAM_FUR_SHADOW, CREAM_FUR, CREAM_FUR_LIGHT, WHITE_FUR_SHADOW, WHITE_FUR, WHITE_FUR_LIGHT,
	CLOTH_SHADOW, CLOTH, CLOTH_LIGHT, SCARF_RED, LEATHER, LEATHER_LIGHT, BRASS, BRASS_LIGHT,
	STEEL_DARK, STEEL, STEEL_LIGHT, RAT_SHADOW, RAT, RAT_LIGHT, RAT_TAIL, DOG_SHADOW, DOG, DOG_LIGHT,
	MUD_DARK, MUD, MUD_LIGHT, BURNT, JUNGLE_DEEP, JUNGLE_DARK, JUNGLE, LEAF, LEAF_LIGHT,
	MOSS, DRY_GRASS, BARK, BARK_LIGHT,
	HI_VIS, PAINT_TEAL, SKIN, SKIN_SHADOW, BLOOD, BLOOD_DRY, SPARK, SMOKE, GRAPHITE, PANEL_DARK, PANEL_LIGHT,
	OFF_WHITE, PINK,
]


static func has(color: Color) -> bool:
	for each in ALL:
		if each.is_equal_approx(color):
			return true
	return false
