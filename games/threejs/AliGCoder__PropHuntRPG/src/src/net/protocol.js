/**
 * Wire protocol. Every message is a plain JSON object `{ t: <type>, ...payload }`.
 * Events from the host are wrapped as `{ t: 'ev', e: <event>, ...payload }`.
 */

/** Client → Host */
export const C2S = Object.freeze( {
	HELLO: 'hello',         // { profile }
	PROFILE: 'profile',     // { levels }
	TRADE: 'trade',         // { trade }
	READY: 'ready',         // {}
	START: 'start',         // {}            (host only)
	ADD_BOT: 'addBot',      // {}            (host only)
	REMOVE_BOT: 'removeBot',// {}            (host only)
	POS: 'pos',             // { p:[x,y,z], yaw }
	DISGUISE: 'disguise',   // { type, index }
	HIT: 'hit',             // { kind:'player'|'prop'|'decoy'|'miss', id }
	FORAGE: 'forage',       // { index }
	ABILITY: 'ability',     // { origin:[x,y,z], dir:[x,y,z] }
	TAUNT: 'taunt'          // {}
} );

/** Host → Client */
export const S2C = Object.freeze( {
	WELCOME: 'welcome',     // { you, hostId, seed, state }
	SNAPSHOT: 'snap',       // { phase, round, timeLeft, players }
	EVENT: 'ev',            // { e, ... }
	ERROR: 'err'            // { message }
} );

/** Event names carried in S2C.EVENT */
export const EV = Object.freeze( {
	PHASE: 'phase',
	TELEPORT: 'teleport',
	SWING: 'swing',
	DAMAGE: 'damage',
	ELIMINATED: 'eliminated',
	GATHER: 'gather',
	NODE_RESPAWN: 'nodeRespawn',
	FORAGE_FX: 'forageFx',
	REVEAL: 'reveal',
	DECOY: 'decoy',
	DECOY_REMOVED: 'decoyRemoved',
	XP: 'xp',
	COOLDOWN: 'cooldown',
	ROUND_END: 'roundEnd',
	DISGUISED: 'disguised',
	TAUNT: 'taunt',
	ABILITY: 'ability',
	HARPOON: 'harpoon',
	TOAST: 'toast',
	JOINED: 'joined',
	LEFT: 'left'
} );

export const PHASES = Object.freeze( {
	LOBBY: 'lobby',
	PREP: 'prep',
	HUNT: 'hunt',
	RESULTS: 'results'
} );
