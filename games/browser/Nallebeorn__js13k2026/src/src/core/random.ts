
// Source - https://stackoverflow.com/a/12996028
// Posted by Thomas Mueller, modified by community. See post 'Timeline' for change history
// Retrieved 2026-09-03, License - CC BY-SA 4.0
// (edited)
export function srand(seed: number) {
	seed = Math.imul(((seed) >>> 16) ^ seed, 0x45d9f3b);
	seed = Math.imul(((seed) >>> 16) ^ seed, 0x45d9f3b);
	seed = (seed >>> 16) ^ seed;
	return seed >>> 0;
}

// Range: -1..1
export function srandf(seed: number) {
	return (srand(seed) / 2 ** 32) * 2 - 1;
}
