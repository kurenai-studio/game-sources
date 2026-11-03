import { COLOR_MASK } from "./binformatHelpers.ts";

export const colors: number[] = [];

export const unlockedColors: boolean[] = [];

export function unlockColor(color: Color) {
	for (let i = 0; i < 3; i++) {
		colors[color * 4 + i] = colors[color * 4 + 40 + i]!;
	}
	unlockedColors[color] = true;
}

export const palette = [
	0x000000, // COLOR_BLACK
	0x5F574F, // COLOR_DARKGREY
	0xC2C3C7, // COLOR_LIGHTGREY
	0xFFF1E8, // COLOR_WHITE

	// Unlockble rainbow colors
	0x000000, // COLOR_RED,
	0x000000, // COLOR_ORANGE
	0x000000, // COLOR_YELLOW
	0x000000, // COLOR_GREEN
	0x000000, // COLOR_CYAN
	0x000000, // COLOR_BLUE
	0x000000, // COLOR_VIOLET

	0xFF77A8, // COLOR_PINK
	0xFFCCAA, // COLOR_PEACH
	0x773311, // COLOR_OUTLINE

	0xFF004D, // COLOR_FIXED_RED,
	0xFFA300, // COLOR_FIXED_ORANGE
	0xFFEC27, // COLOR_FIXED_YELLOW
	0x00E436, // COLOR_FIXED_GREEN
	0x29ADFF, // COLOR_FIXED_CYAN
	0x294BE7, // COLOR_FIXED_BLUE
	0x9548FA, // COLOR_FIXED_VIOLET

	0x000000, // COLOR_CONSUMABLE_RED,
	0x000000, // COLOR_CONSUMABLE_ORANGE
	0x000000, // COLOR_CONSUMABLE_YELLOW
	0x000000, // COLOR_CONSUMABLE_GREEN
	0x000000, // COLOR_CONSUMABLE_CYAN
	0x000000, // COLOR_CONSUMABLE_BLUE
	0x000000, // COLOR_CONSUMABLE_VIOLET
];

export const COLOR_BLACK = 0;
export const COLOR_DARKGREY = 1;
export const COLOR_LIGHTGREY = 2;
export const COLOR_WHITE = 3;
export const COLOR_RED = 4;
export const COLOR_ORANGE = 5;
export const COLOR_YELLOW = 6;
export const COLOR_GREEN = 7;
export const COLOR_CYAN = 8;
export const COLOR_BLUE = 9;
export const COLOR_VIOLET = 10;
export const COLOR_PINK = 11;
export const COLOR_PEACH = 12;
export const COLOR_OUTLINE = 13;
export const COLOR_FIXED_RED = 14;
export const COLOR_FIXED_ORANGE = 15;
export const COLOR_FIXED_YELLOW = 16;
export const COLOR_FIXED_GREEN = 17;
export const COLOR_FIXED_CYAN = 18;
export const COLOR_FIXED_BLUE = 19;
export const COLOR_FIXED_VIOLET = 20;
export const COLOR_CONSUMABLE_RED = 21;
export const COLOR_CONSUMABLE_ORANGE = 22;
export const COLOR_CONSUMABLE_YELLOW = 23;
export const COLOR_CONSUMABLE_GREEN = 24;
export const COLOR_CONSUMABLE_CYAN = 25;
export const COLOR_CONSUMABLE_BLUE = 26;
export const COLOR_CONSUMABLE_VIOLET = 27;
export const COLOR_COUNT = 28;

export const COLOR_RAINBOW = COLOR_MASK; // sentinel value for bindata

export type Color =
	| typeof COLOR_BLACK
	| typeof COLOR_DARKGREY
	| typeof COLOR_LIGHTGREY
	| typeof COLOR_WHITE
	| typeof COLOR_RED
	| typeof COLOR_ORANGE
	| typeof COLOR_YELLOW
	| typeof COLOR_GREEN
	| typeof COLOR_CYAN
	| typeof COLOR_BLUE
	| typeof COLOR_VIOLET
	| typeof COLOR_PINK
	| typeof COLOR_PEACH
	| number; // negative numbers represent radius of rainbow color
