/**
 * Skill definitions and the XP curve. Pure data + pure functions so it can be
 * used by the host simulation, the UI and unit tests alike.
 */

export const MAX_LEVEL = 50;

export const SKILLS = Object.freeze( {
	woodcutting: { id: 'woodcutting', name: 'Woodcutting', icon: '🪓', color: '#7bc96f', tool: 'axe', toolName: 'Axe' },
	mining: { id: 'mining', name: 'Mining', icon: '⛏️', color: '#c9a36f', tool: 'pickaxe', toolName: 'Pickaxe' },
	fishing: { id: 'fishing', name: 'Fishing', icon: '🎣', color: '#6fb3c9', tool: 'harpoon', toolName: 'Harpoon' },
	agility: { id: 'agility', name: 'Agility', icon: '🏃', color: '#c96fae', tool: null, toolName: null }
} );

export const SKILL_IDS = Object.keys( SKILLS );

/** Skills that can be chosen as a round "trade" (decides tool & ability). */
export const TRADES = [ 'woodcutting', 'mining', 'fishing' ];

/** Total XP required to *reach* `level`. */
export function xpForLevel( level ) {

	const l = Math.max( 1, Math.min( MAX_LEVEL, level ) );
	return 40 * ( l - 1 ) * ( l - 1 );

}

/** Level for a total XP amount. */
export function levelForXp( xp ) {

	const l = Math.floor( Math.sqrt( Math.max( 0, xp ) / 40 ) ) + 1;
	return Math.min( MAX_LEVEL, l );

}

/** Progress (0–1) through the current level. */
export function levelProgress( xp ) {

	const level = levelForXp( xp );
	if ( level >= MAX_LEVEL ) return 1;
	const a = xpForLevel( level ), b = xpForLevel( level + 1 );
	return ( xp - a ) / ( b - a );

}

/** Convert a `{ skill: xp }` map into `{ skill: level }`. */
export function levelsFromXp( xpMap ) {

	const out = {};
	for ( const id of SKILL_IDS ) out[ id ] = levelForXp( xpMap[ id ] ?? 0 );
	return out;

}

/** Sanitise levels coming from an untrusted peer. */
export function clampLevels( levels ) {

	const out = {};
	for ( const id of SKILL_IDS ) {

		const v = Math.floor( Number( levels?.[ id ] ) );
		out[ id ] = Number.isFinite( v ) ? Math.min( MAX_LEVEL, Math.max( 1, v ) ) : 1;

	}

	return out;

}

/** The trade a player is best at – used as a sensible default. */
export function bestTrade( levels ) {

	return TRADES.reduce( ( best, t ) => ( ( levels[ t ] ?? 1 ) > ( levels[ best ] ?? 1 ) ? t : best ), TRADES[ 0 ] );

}
