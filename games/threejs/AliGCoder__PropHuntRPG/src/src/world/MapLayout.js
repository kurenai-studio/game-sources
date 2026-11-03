import { createRng } from '../core/random.js';
import { CONFIG } from '../config.js';
import { Heightfield } from './Heightfield.js';
import { PROP_TYPES } from './PropCatalog.js';
import { SpatialGrid } from './SpatialGrid.js';

/**
 * Deterministic, three.js-free description of a map generated from a seed:
 * the heightfield plus every placed prop. Host, clients and bots all build
 * the exact same layout, so props are referenced over the network by index.
 */
export class MapLayout {

	constructor( seed ) {

		this.seed = seed;
		this.heightfield = new Heightfield( seed );
		this.props = [];          // { index, type, x, y, z, yaw, radius }
		this.grid = new SpatialGrid( 4 );
		this.hunterSpawn = { x: 0, z: 5 };
		this.#generate();

	}

	heightAt( x, z ) {

		return this.heightfield.heightAt( x, z );

	}

	/** Ground height a prop or player stands on (floats on water). */
	groundAt( x, z ) {

		return Math.max( this.heightAt( x, z ), CONFIG.world.waterLevel - 0.35 );

	}

	nearby( x, z, radius ) {

		return this.grid.query( x, z, radius );

	}

	// ── generation ──────────────────────────────────────────────────────────

	#generate() {

		const rng = createRng( this.seed ^ 0x51ed270b );
		const hf = this.heightfield;
		const water = CONFIG.world.waterLevel;

		// Plaza: well + ring of lamp posts
		this.#place( 'well', 0, 0, 0, true );
		for ( let i = 0; i < 6; i ++ ) {

			const a = ( i / 6 ) * Math.PI * 2 + 0.3;
			this.#place( 'lamp_post', Math.cos( a ) * 9, Math.sin( a ) * 9, 0, true );

		}

		// Village: cottages facing the plaza, with clutter around each one
		const cottages = 6;
		for ( let i = 0; i < cottages; i ++ ) {

			const a = ( i / cottages ) * Math.PI * 2 + rng.range( - 0.15, 0.15 );
			const r = rng.range( 18, 22 );
			const x = Math.cos( a ) * r, z = Math.sin( a ) * r;
			const yaw = Math.atan2( - x, - z ); // door (+Z) faces the plaza
			if ( ! this.#place( 'cottage', x, z, yaw ) ) continue;

			const clutter = [ 'crate', 'barrel', 'bucket', 'hay_bale', 'lantern', 'log_pile', 'crate', 'barrel' ];
			for ( let k = 0; k < 7; k ++ ) {

				const ca = a + rng.range( - 0.5, 0.5 );
				const cr = r + rng.range( - 5, 5 );
				this.#place( rng.pick( clutter ), Math.cos( ca ) * cr, Math.sin( ca ) * cr, rng.range( 0, Math.PI * 2 ) );

			}

			// a short fence line behind the house
			for ( let f = - 1; f <= 1; f ++ ) {

				const fa = a + f * 0.1;
				this.#place( 'fence', Math.cos( fa ) * ( r + 4.2 ), Math.sin( fa ) * ( r + 4.2 ), - a + Math.PI / 2 );

			}

		}

		// Zone tables: [type, weight]
		const tables = {
			forest: [ [ 'pine', 6 ], [ 'oak', 4 ], [ 'birch', 3 ], [ 'bush', 5 ], [ 'stump', 3 ], [ 'log_pile', 2 ], [ 'rock_small', 1 ] ],
			quarry: [ [ 'rock_small', 6 ], [ 'rock_large', 5 ], [ 'copper_ore', 4 ], [ 'crystal', 2 ], [ 'boulder', 2 ], [ 'crate', 1 ], [ 'bucket', 1 ] ],
			docks: [ [ 'crate', 5 ], [ 'barrel', 5 ], [ 'lobster_pot', 4 ], [ 'fish_rack', 3 ], [ 'rowboat', 2 ], [ 'lantern', 1 ], [ 'rock_small', 1 ] ],
			meadow: [ [ 'bush', 5 ], [ 'hay_bale', 3 ], [ 'oak', 2 ], [ 'rock_small', 3 ], [ 'rock_large', 1 ], [ 'stump', 2 ], [ 'bucket', 1 ] ]
		};

		const attempts = 5200;
		for ( let i = 0; i < attempts; i ++ ) {

			const r = Math.sqrt( rng() ) * CONFIG.world.islandRadius;
			const a = rng() * Math.PI * 2;
			const x = Math.cos( a ) * r, z = Math.sin( a ) * r;
			const zone = hf.zoneAt( x, z );
			const table = tables[ zone ];
			if ( ! table ) continue;
			const h = hf.heightAt( x, z );
			if ( h < water + 0.3 ) continue;
			if ( hf.slopeAt( x, z ) > 0.9 ) continue;
			const density = { forest: 0.55, quarry: 0.32, docks: 0.3, meadow: 0.07 }[ zone ];
			if ( ! rng.chance( density ) ) continue;
			this.#place( weightedPick( rng, table ), x, z, rng.range( 0, Math.PI * 2 ) );

		}

		// Water props: buoys & fishing spots off the docks shoreline
		for ( let i = 0; i < 900 && this.#count( 'fishing_spot' ) < 7; i ++ ) {

			const a = rng.range( - 150, - 70 ) * Math.PI / 180;
			const r = rng.range( 50, 85 );
			const x = Math.cos( a ) * r, z = Math.sin( a ) * r;
			const h = hf.heightAt( x, z );
			if ( h > water - 0.4 || h < water - 2.5 ) continue;
			this.#place( 'fishing_spot', x, z, 0, false, 3 );

		}

		for ( let i = 0; i < 900 && this.#count( 'buoy' ) < 9; i ++ ) {

			const a = rng() * Math.PI * 2;
			const r = rng.range( 55, 90 );
			const x = Math.cos( a ) * r, z = Math.sin( a ) * r;
			const h = hf.heightAt( x, z );
			if ( h > water - 0.5 || h < water - 3 ) continue;
			this.#place( 'buoy', x, z, rng.range( 0, 6.28 ) );

		}

	}

	#count( type ) {

		let n = 0;
		for ( const p of this.props ) if ( p.type === type ) n ++;
		return n;

	}

	#place( type, x, z, yaw, force = false, spacing = 0.6 ) {

		const def = PROP_TYPES[ type ];
		const radius = def.radius;
		if ( ! force ) {

			const hits = this.grid.query( x, z, radius + spacing );
			if ( hits.length ) return null;
			if ( Math.hypot( x - this.hunterSpawn.x, z - this.hunterSpawn.z ) < 4 ) return null;

		}

		const prop = {
			index: this.props.length,
			type,
			x, z,
			y: def.special === 'ripples' ? CONFIG.world.waterLevel + 0.02 : this.groundAt( x, z ),
			yaw,
			radius: Math.max( radius, def.special ? 1.2 : 0 )
		};
		this.props.push( prop );
		this.grid.insert( prop );
		return prop;

	}

	/** A random land position away from the plaza (for hider/bot spawns). */
	randomLandPoint( rng, minR = 12, maxR = CONFIG.world.islandRadius - 8 ) {

		for ( let i = 0; i < 200; i ++ ) {

			const r = rng.range( minR, maxR ), a = rng() * Math.PI * 2;
			const x = Math.cos( a ) * r, z = Math.sin( a ) * r;
			if ( ! this.heightfield.isLand( x, z ) ) continue;
			if ( this.grid.query( x, z, 0.8 ).length ) continue;
			return { x, z };

		}

		return { x: 0, z: 12 };

	}

}

function weightedPick( rng, table ) {

	let total = 0;
	for ( const [ , w ] of table ) total += w;
	let roll = rng() * total;
	for ( const [ type, w ] of table ) {

		roll -= w;
		if ( roll <= 0 ) return type;

	}

	return table[ 0 ][ 0 ];

}
