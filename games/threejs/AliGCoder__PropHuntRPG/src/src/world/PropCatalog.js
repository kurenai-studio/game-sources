/**
 * Every object that can exist on the map, described as pure data.
 *
 *  - `skill` / `level`: requirement for a hider to disguise as it.
 *  - `disguisable`: false for scenery (houses, lamp posts, fishing spots).
 *  - `node`: makes it a gatherable resource node.
 *  - `parts`: low-poly primitives that PropFactory merges into one geometry.
 *    s = shape, a = args, p = position, r = rotation, sc = scale,
 *    c = colour, g = glow (emissive strength), w = wind-sway weight, j = jitter.
 *
 * Parts must be deterministic (no randomness) so a disguised hider looks
 * identical to the real thing.
 */

const WOOD = 0x8a5a36, WOOD_DARK = 0x5e3b22, WOOD_LIGHT = 0xc89a64, BARK = 0x6b4a2f;
const LEAF = 0x4f8f3a, LEAF_DARK = 0x3b7030, PINE = 0x2f6b45, BIRCH_LEAF = 0x9fbf3f;
const STONE = 0x9a958c, STONE_DARK = 0x75716a, COPPER = 0xd27a3c, CRYSTAL = 0x5fe3ff;
const ROPE = 0xc9b48a, RED = 0xd4473b, WHITE = 0xf1ede4, ROOF = 0xa34a3a, PLASTER = 0xe8dcc4;

const H = Math.PI / 2;

export const PROP_TYPES = {

	// ── General (no requirement) ────────────────────────────────────────────
	bucket: {
		name: 'Bucket', skill: 'general', level: 1, radius: 0.35, height: 0.5,
		parts: [
			{ s: 'cyl', a: [ 0.3, 0.24, 0.48, 10 ], p: [ 0, 0.24, 0 ], c: WOOD },
			{ s: 'torus', a: [ 0.29, 0.03, 4, 12 ], p: [ 0, 0.4, 0 ], r: [ H, 0, 0 ], c: STONE_DARK },
			{ s: 'torus', a: [ 0.25, 0.03, 4, 12 ], p: [ 0, 0.1, 0 ], r: [ H, 0, 0 ], c: STONE_DARK }
		]
	},
	hay_bale: {
		name: 'Hay Bale', skill: 'general', level: 1, radius: 0.7, height: 0.9,
		parts: [ { s: 'cyl', a: [ 0.45, 0.45, 1.1, 12 ], p: [ 0, 0.45, 0 ], r: [ 0, 0, H ], c: 0xd9b75a } ]
	},
	lantern: {
		name: 'Lantern', skill: 'general', level: 1, radius: 0.3, height: 0.6,
		parts: [
			{ s: 'box', a: [ 0.32, 0.06, 0.32 ], p: [ 0, 0.03, 0 ], c: STONE_DARK },
			{ s: 'box', a: [ 0.22, 0.3, 0.22 ], p: [ 0, 0.21, 0 ], c: 0xffc46b, g: 3 },
			{ s: 'cone', a: [ 0.22, 0.16, 4 ], p: [ 0, 0.44, 0 ], r: [ 0, Math.PI / 4, 0 ], c: STONE_DARK }
		]
	},

	// ── Woodcutting ─────────────────────────────────────────────────────────
	log_pile: {
		name: 'Log Pile', skill: 'woodcutting', level: 1, radius: 0.8, height: 0.8,
		parts: [
			{ s: 'cyl', a: [ 0.2, 0.2, 1.4, 8 ], p: [ - 0.22, 0.2, 0 ], r: [ H, 0, 0 ], c: BARK },
			{ s: 'cyl', a: [ 0.2, 0.2, 1.4, 8 ], p: [ 0.22, 0.2, 0 ], r: [ H, 0, 0 ], c: WOOD },
			{ s: 'cyl', a: [ 0.2, 0.2, 1.4, 8 ], p: [ 0, 0.55, 0 ], r: [ H, 0, 0 ], c: BARK }
		]
	},
	stump: {
		name: 'Tree Stump', skill: 'woodcutting', level: 1, radius: 0.5, height: 0.6,
		parts: [
			{ s: 'cyl', a: [ 0.38, 0.5, 0.55, 9 ], p: [ 0, 0.27, 0 ], c: BARK },
			{ s: 'cyl', a: [ 0.36, 0.36, 0.04, 9 ], p: [ 0, 0.56, 0 ], c: WOOD_LIGHT }
		]
	},
	bush: {
		name: 'Bush', skill: 'woodcutting', level: 5, radius: 0.7, height: 1.0,
		parts: [
			{ s: 'ico', a: [ 0.55, 1 ], p: [ 0, 0.45, 0 ], c: LEAF, w: 0.5, j: 0.08 },
			{ s: 'ico', a: [ 0.42, 1 ], p: [ 0.4, 0.35, 0.15 ], c: LEAF_DARK, w: 0.5, j: 0.08 },
			{ s: 'ico', a: [ 0.4, 1 ], p: [ - 0.35, 0.33, - 0.1 ], c: LEAF, w: 0.5, j: 0.08 }
		]
	},
	pine: {
		name: 'Pine Tree', skill: 'woodcutting', level: 12, radius: 0.55, height: 5.2,
		node: { skill: 'woodcutting', xp: 18, hits: 4 },
		parts: [
			{ s: 'cyl', a: [ 0.16, 0.26, 1.6, 7 ], p: [ 0, 0.8, 0 ], c: BARK },
			{ s: 'cone', a: [ 1.4, 1.9, 8 ], p: [ 0, 2.2, 0 ], c: PINE, w: 0.4 },
			{ s: 'cone', a: [ 1.1, 1.7, 8 ], p: [ 0, 3.2, 0 ], c: PINE, w: 0.7 },
			{ s: 'cone', a: [ 0.75, 1.5, 8 ], p: [ 0, 4.2, 0 ], c: PINE, w: 1 }
		]
	},
	oak: {
		name: 'Oak Tree', skill: 'woodcutting', level: 20, radius: 0.6, height: 5,
		node: { skill: 'woodcutting', xp: 25, hits: 5 },
		parts: [
			{ s: 'cyl', a: [ 0.25, 0.38, 2.4, 8 ], p: [ 0, 1.2, 0 ], c: BARK },
			{ s: 'ico', a: [ 1.5, 1 ], p: [ 0, 3.3, 0 ], c: LEAF, w: 0.8, j: 0.12 },
			{ s: 'ico', a: [ 1.0, 1 ], p: [ 0.9, 2.9, 0.3 ], c: LEAF_DARK, w: 0.8, j: 0.1 },
			{ s: 'ico', a: [ 1.0, 1 ], p: [ - 0.8, 3.0, - 0.4 ], c: LEAF, w: 0.8, j: 0.1 },
			{ s: 'ico', a: [ 0.9, 1 ], p: [ 0.1, 4.2, 0.2 ], c: LEAF_DARK, w: 1, j: 0.1 }
		]
	},
	birch: {
		name: 'Birch Tree', skill: 'woodcutting', level: 30, radius: 0.45, height: 5.5,
		node: { skill: 'woodcutting', xp: 32, hits: 5 },
		parts: [
			{ s: 'cyl', a: [ 0.14, 0.2, 3.4, 7 ], p: [ 0, 1.7, 0 ], c: WHITE },
			{ s: 'cyl', a: [ 0.18, 0.18, 0.08, 7 ], p: [ 0, 0.9, 0 ], c: 0x333333 },
			{ s: 'cyl', a: [ 0.16, 0.16, 0.06, 7 ], p: [ 0, 2.1, 0 ], c: 0x333333 },
			{ s: 'ico', a: [ 1.1, 1 ], p: [ 0, 4.0, 0 ], sc: [ 1, 1.4, 1 ], c: BIRCH_LEAF, w: 1, j: 0.1 }
		]
	},

	// ── Mining ──────────────────────────────────────────────────────────────
	rock_small: {
		name: 'Small Rock', skill: 'mining', level: 1, radius: 0.5, height: 0.6,
		parts: [ { s: 'ico', a: [ 0.5, 0 ], p: [ 0, 0.3, 0 ], sc: [ 1, 0.7, 1 ], c: STONE, j: 0.12 } ]
	},
	rock_large: {
		name: 'Large Rock', skill: 'mining', level: 8, radius: 1.0, height: 1.3,
		parts: [
			{ s: 'ico', a: [ 1.0, 0 ], p: [ 0, 0.65, 0 ], sc: [ 1.1, 0.8, 1 ], c: STONE, j: 0.15 },
			{ s: 'ico', a: [ 0.5, 0 ], p: [ 0.8, 0.3, 0.3 ], c: STONE_DARK, j: 0.1 }
		]
	},
	copper_ore: {
		name: 'Copper Ore', skill: 'mining', level: 15, radius: 0.9, height: 1.1,
		node: { skill: 'mining', xp: 20, hits: 4 },
		parts: [
			{ s: 'ico', a: [ 0.9, 0 ], p: [ 0, 0.55, 0 ], sc: [ 1, 0.8, 1 ], c: STONE_DARK, j: 0.12 },
			{ s: 'ico', a: [ 0.22, 0 ], p: [ 0.45, 0.75, 0.4 ], c: COPPER },
			{ s: 'ico', a: [ 0.18, 0 ], p: [ - 0.5, 0.6, 0.35 ], c: COPPER },
			{ s: 'ico', a: [ 0.2, 0 ], p: [ 0.1, 1.05, - 0.3 ], c: COPPER }
		]
	},
	crystal: {
		name: 'Crystal Cluster', skill: 'mining', level: 30, radius: 0.8, height: 1.6,
		node: { skill: 'mining', xp: 32, hits: 5 },
		parts: [
			{ s: 'ico', a: [ 0.7, 0 ], p: [ 0, 0.3, 0 ], sc: [ 1.2, 0.5, 1.2 ], c: STONE_DARK, j: 0.1 },
			{ s: 'cone', a: [ 0.18, 1.2, 5 ], p: [ 0, 1.0, 0 ], c: CRYSTAL, g: 1.6 },
			{ s: 'cone', a: [ 0.14, 0.8, 5 ], p: [ 0.32, 0.8, 0.1 ], r: [ 0, 0, - 0.4 ], c: CRYSTAL, g: 1.6 },
			{ s: 'cone', a: [ 0.12, 0.7, 5 ], p: [ - 0.28, 0.75, - 0.12 ], r: [ 0.2, 0, 0.45 ], c: CRYSTAL, g: 1.6 }
		]
	},
	boulder: {
		name: 'Boulder', skill: 'mining', level: 40, radius: 1.5, height: 2.2,
		parts: [ { s: 'ico', a: [ 1.5, 1 ], p: [ 0, 1.1, 0 ], sc: [ 1, 0.75, 0.9 ], c: STONE, j: 0.18 } ]
	},

	// ── Fishing ─────────────────────────────────────────────────────────────
	crate: {
		name: 'Crate', skill: 'fishing', level: 1, radius: 0.55, height: 0.9,
		parts: [
			{ s: 'box', a: [ 0.85, 0.85, 0.85 ], p: [ 0, 0.425, 0 ], c: WOOD_LIGHT },
			{ s: 'box', a: [ 0.9, 0.12, 0.9 ], p: [ 0, 0.8, 0 ], c: WOOD },
			{ s: 'box', a: [ 0.9, 0.12, 0.9 ], p: [ 0, 0.06, 0 ], c: WOOD }
		]
	},
	barrel: {
		name: 'Barrel', skill: 'fishing', level: 1, radius: 0.45, height: 1.0,
		parts: [
			{ s: 'cyl', a: [ 0.38, 0.38, 0.95, 12 ], p: [ 0, 0.475, 0 ], sc: [ 1, 1, 1 ], c: WOOD },
			{ s: 'torus', a: [ 0.4, 0.035, 4, 14 ], p: [ 0, 0.2, 0 ], r: [ H, 0, 0 ], c: STONE_DARK },
			{ s: 'torus', a: [ 0.4, 0.035, 4, 14 ], p: [ 0, 0.75, 0 ], r: [ H, 0, 0 ], c: STONE_DARK }
		]
	},
	lobster_pot: {
		name: 'Lobster Pot', skill: 'fishing', level: 8, radius: 0.6, height: 0.6,
		parts: [
			{ s: 'box', a: [ 1.0, 0.08, 0.6 ], p: [ 0, 0.04, 0 ], c: WOOD_DARK },
			{ s: 'cyl', a: [ 0.3, 0.3, 1.0, 8, true ], p: [ 0, 0.1, 0 ], r: [ 0, 0, H ], sc: [ 1, 1, 1 ], c: ROPE },
			{ s: 'torus', a: [ 0.3, 0.03, 4, 10 ], p: [ 0.3, 0.1, 0 ], r: [ 0, H, 0 ], c: WOOD_DARK },
			{ s: 'torus', a: [ 0.3, 0.03, 4, 10 ], p: [ - 0.3, 0.1, 0 ], r: [ 0, H, 0 ], c: WOOD_DARK }
		]
	},
	fish_rack: {
		name: 'Fish Drying Rack', skill: 'fishing', level: 15, radius: 0.8, height: 1.6,
		parts: [
			{ s: 'box', a: [ 0.08, 1.6, 0.08 ], p: [ - 0.7, 0.8, 0 ], c: WOOD_DARK },
			{ s: 'box', a: [ 0.08, 1.6, 0.08 ], p: [ 0.7, 0.8, 0 ], c: WOOD_DARK },
			{ s: 'box', a: [ 1.5, 0.06, 0.06 ], p: [ 0, 1.5, 0 ], c: WOOD_DARK },
			{ s: 'cone', a: [ 0.1, 0.45, 4 ], p: [ - 0.35, 1.22, 0 ], r: [ Math.PI, 0, 0 ], c: 0x9fb4c0, w: 0.3 },
			{ s: 'cone', a: [ 0.1, 0.45, 4 ], p: [ 0, 1.22, 0 ], r: [ Math.PI, 0, 0 ], c: 0xc0a69f, w: 0.3 },
			{ s: 'cone', a: [ 0.1, 0.45, 4 ], p: [ 0.35, 1.22, 0 ], r: [ Math.PI, 0, 0 ], c: 0x9fb4c0, w: 0.3 }
		]
	},
	buoy: {
		name: 'Buoy', skill: 'fishing', level: 25, radius: 0.45, height: 1.2,
		parts: [
			{ s: 'cyl', a: [ 0.35, 0.42, 0.5, 12 ], p: [ 0, 0.25, 0 ], c: RED },
			{ s: 'cyl', a: [ 0.25, 0.35, 0.35, 12 ], p: [ 0, 0.67, 0 ], c: WHITE },
			{ s: 'cone', a: [ 0.25, 0.35, 12 ], p: [ 0, 1.02, 0 ], c: RED },
			{ s: 'sphere', a: [ 0.07, 8, 6 ], p: [ 0, 1.22, 0 ], c: 0xfff1a0, g: 4 }
		]
	},
	rowboat: {
		name: 'Rowboat', skill: 'fishing', level: 40, radius: 1.3, height: 0.8,
		parts: [
			{ s: 'box', a: [ 2.2, 0.45, 1.1 ], p: [ 0, 0.3, 0 ], c: WOOD },
			{ s: 'cyl', a: [ 0.55, 0.55, 0.45, 3 ], p: [ 1.25, 0.3, 0 ], r: [ 0, Math.PI, 0 ], sc: [ 0.9, 1, 1 ], c: WOOD },
			{ s: 'box', a: [ 0.25, 0.06, 1.0 ], p: [ - 0.3, 0.45, 0 ], c: WOOD_LIGHT },
			{ s: 'box', a: [ 2.3, 0.07, 1.16 ], p: [ - 0.05, 0.53, 0 ], c: WOOD_DARK }
		]
	},

	// ── Scenery (not disguisable) ───────────────────────────────────────────
	cottage: {
		name: 'Cottage', skill: 'general', level: 1, radius: 3.2, height: 5.5, disguisable: false,
		parts: [
			{ s: 'box', a: [ 5, 3, 4 ], p: [ 0, 1.5, 0 ], c: PLASTER },
			{ s: 'box', a: [ 5.2, 0.3, 4.2 ], p: [ 0, 0.15, 0 ], c: STONE_DARK },
			{ s: 'cyl', a: [ 2.6, 2.6, 5.6, 3 ], p: [ 0, 3.85, 0 ], r: [ 0, 0, H ], sc: [ 1, 1, 0.95 ], c: ROOF },
			{ s: 'box', a: [ 0.9, 1.6, 0.1 ], p: [ 0, 0.8, 2.02 ], c: WOOD_DARK },
			{ s: 'box', a: [ 0.8, 0.7, 0.1 ], p: [ 1.6, 1.8, 2.02 ], c: 0xffd27a, g: 1.2 },
			{ s: 'box', a: [ 0.8, 0.7, 0.1 ], p: [ - 1.6, 1.8, 2.02 ], c: 0xffd27a, g: 1.2 },
			{ s: 'box', a: [ 0.6, 1.6, 0.6 ], p: [ 1.6, 5.0, - 0.8 ], c: STONE }
		]
	},
	well: {
		name: 'Well', skill: 'general', level: 1, radius: 1.1, height: 2.6, disguisable: false,
		parts: [
			{ s: 'cyl', a: [ 0.95, 1.0, 0.8, 12, true ], p: [ 0, 0.4, 0 ], c: STONE },
			{ s: 'cyl', a: [ 0.8, 0.8, 0.1, 12 ], p: [ 0, 0.3, 0 ], c: 0x2a4a5a },
			{ s: 'box', a: [ 0.12, 1.8, 0.12 ], p: [ 0.85, 1.3, 0 ], c: WOOD_DARK },
			{ s: 'box', a: [ 0.12, 1.8, 0.12 ], p: [ - 0.85, 1.3, 0 ], c: WOOD_DARK },
			{ s: 'cyl', a: [ 1.0, 1.0, 1.9, 3 ], p: [ 0, 2.45, 0 ], r: [ 0, 0, H ], sc: [ 0.5, 1, 0.8 ], c: ROOF }
		]
	},
	lamp_post: {
		name: 'Lamp Post', skill: 'general', level: 1, radius: 0.25, height: 3.2, disguisable: false,
		parts: [
			{ s: 'cyl', a: [ 0.07, 0.1, 3, 6 ], p: [ 0, 1.5, 0 ], c: 0x2b2b30 },
			{ s: 'box', a: [ 0.3, 0.35, 0.3 ], p: [ 0, 3.1, 0 ], c: 0xffcf7a, g: 5 },
			{ s: 'cone', a: [ 0.28, 0.2, 4 ], p: [ 0, 3.37, 0 ], r: [ 0, Math.PI / 4, 0 ], c: 0x2b2b30 }
		]
	},
	fence: {
		name: 'Fence', skill: 'general', level: 1, radius: 0.6, height: 1.0, disguisable: false,
		parts: [
			{ s: 'box', a: [ 0.1, 1.0, 0.1 ], p: [ - 1, 0.5, 0 ], c: WOOD },
			{ s: 'box', a: [ 0.1, 1.0, 0.1 ], p: [ 1, 0.5, 0 ], c: WOOD },
			{ s: 'box', a: [ 2.1, 0.08, 0.06 ], p: [ 0, 0.75, 0 ], c: WOOD_LIGHT },
			{ s: 'box', a: [ 2.1, 0.08, 0.06 ], p: [ 0, 0.4, 0 ], c: WOOD_LIGHT }
		]
	},
	fishing_spot: {
		name: 'Fishing Spot', skill: 'fishing', level: 1, radius: 0, height: 0.2, disguisable: false, special: 'ripples',
		node: { skill: 'fishing', xp: 22, hits: 6 },
		parts: []
	}

};

export const PROP_IDS = Object.keys( PROP_TYPES );

export const DISGUISE_IDS = PROP_IDS.filter( ( id ) => PROP_TYPES[ id ].disguisable !== false );

export function getPropType( id ) {

	return PROP_TYPES[ id ] ?? null;

}

export function isNode( id ) {

	return !! PROP_TYPES[ id ]?.node;

}
