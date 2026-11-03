import { EventEmitter } from '../core/EventEmitter.js';
import { SKILL_IDS, levelForXp, levelsFromXp, bestTrade } from './skills.js';

const STORAGE_KEY = 'prophunt-rpg.character.v1';

/**
 * The persistent character: name, skill XP and lifetime stats.
 * Stored in localStorage. Emits `xp` and `levelup` events for the UI.
 *
 * Swap this class for a server-backed implementation later without touching
 * gameplay code – everything else only uses the public methods below.
 */
export class CharacterStore extends EventEmitter {

	constructor( storage = safeStorage() ) {

		super();
		this.storage = storage;
		this.data = this.#load();

	}

	get name() {

		return this.data.name;

	}

	set name( value ) {

		this.data.name = String( value || 'Adventurer' ).slice( 0, 16 );
		this.save();

	}

	get xp() {

		return this.data.xp;

	}

	get levels() {

		return levelsFromXp( this.data.xp );

	}

	get preferredTrade() {

		return this.data.preferredTrade ?? bestTrade( this.levels );

	}

	set preferredTrade( trade ) {

		this.data.preferredTrade = trade;
		this.save();

	}

	get stats() {

		return this.data.stats;

	}

	/** Public profile sent to the host when joining a lobby. */
	toProfile() {

		return { name: this.name, levels: this.levels, trade: this.preferredTrade };

	}

	addXp( skill, amount, reason = '' ) {

		if ( ! SKILL_IDS.includes( skill ) || ! ( amount > 0 ) ) return;
		const before = levelForXp( this.data.xp[ skill ] );
		this.data.xp[ skill ] = ( this.data.xp[ skill ] ?? 0 ) + Math.round( amount );
		const after = levelForXp( this.data.xp[ skill ] );
		this.save();
		this.emit( 'xp', { skill, amount: Math.round( amount ), reason, total: this.data.xp[ skill ] } );
		if ( after > before ) this.emit( 'levelup', { skill, level: after } );

	}

	recordStat( key, delta = 1 ) {

		this.data.stats[ key ] = ( this.data.stats[ key ] ?? 0 ) + delta;
		this.save();

	}

	save() {

		try {

			this.storage.setItem( STORAGE_KEY, JSON.stringify( this.data ) );

		} catch { /* storage unavailable – progress is session-only */ }

	}

	reset() {

		this.data = defaultData();
		this.save();

	}

	#load() {

		try {

			const raw = this.storage.getItem( STORAGE_KEY );
			if ( raw ) {

				const parsed = JSON.parse( raw );
				const base = defaultData();
				return { ...base, ...parsed, xp: { ...base.xp, ...parsed.xp }, stats: { ...base.stats, ...parsed.stats } };

			}

		} catch { /* corrupted save – start fresh */ }

		return defaultData();

	}

}

function defaultData() {

	const xp = {};
	for ( const id of SKILL_IDS ) xp[ id ] = 0;
	return {
		name: 'Adventurer' + Math.floor( Math.random() * 900 + 100 ),
		xp,
		preferredTrade: null,
		stats: { rounds: 0, wins: 0, eliminations: 0, survivals: 0 }
	};

}

function safeStorage() {

	try {

		const s = globalThis.localStorage;
		s.getItem( '__probe__' );
		return s;

	} catch {

		const mem = new Map();
		return { getItem: ( k ) => mem.get( k ) ?? null, setItem: ( k, v ) => mem.set( k, v ) };

	}

}
