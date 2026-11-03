import { createNoise2D, fbm } from '../core/random.js';
import { CONFIG } from '../config.js';

const DEG = Math.PI / 180;

/** Angular zones of the island (degrees, measured with atan2(z, x)). */
export const ZONES = Object.freeze( {
	forest: { from: 95, to: 205 },
	quarry: { from: - 55, to: 45 },
	docks: { from: - 150, to: - 70 }
} );

function angleIn( deg, zone ) {

	return deg >= zone.from && deg <= zone.to;

}

const smoothstep = ( a, b, x ) => {

	const t = Math.min( 1, Math.max( 0, ( x - a ) / ( b - a ) ) );
	return t * t * ( 3 - 2 * t );

};

/**
 * Pure (three.js-free) height function for the island. Shared by the
 * renderer (terrain mesh), local physics, and the host (bots, validation).
 * Heights are cached into a grid and bilinearly sampled for speed.
 */
export class Heightfield {

	constructor( seed ) {

		this.seed = seed;
		this.size = CONFIG.world.size;
		this.radius = CONFIG.world.islandRadius;
		this.resolution = CONFIG.world.terrainSegments + 1;
		this.noise = createNoise2D( seed );
		this.detail = createNoise2D( seed ^ 0x9e3779b9 );
		this.grid = new Float32Array( this.resolution * this.resolution );
		this.min = Infinity;
		this.max = - Infinity;

		const step = this.size / ( this.resolution - 1 );
		for ( let iz = 0; iz < this.resolution; iz ++ ) {

			for ( let ix = 0; ix < this.resolution; ix ++ ) {

				const x = - this.size / 2 + ix * step;
				const z = - this.size / 2 + iz * step;
				const h = this.#compute( x, z );
				this.grid[ iz * this.resolution + ix ] = h;
				this.min = Math.min( this.min, h );
				this.max = Math.max( this.max, h );

			}

		}

	}

	zoneAt( x, z ) {

		const r = Math.hypot( x, z );
		if ( r < 11 ) return 'plaza';
		if ( r < 27 ) return 'village';
		const deg = Math.atan2( z, x ) / DEG;
		if ( angleIn( deg, ZONES.forest ) ) return 'forest';
		if ( angleIn( deg, ZONES.quarry ) ) return 'quarry';
		if ( angleIn( deg, ZONES.docks ) ) return 'docks';
		return 'meadow';

	}

	#compute( x, z ) {

		// Wobbly island outline
		const ang = Math.atan2( z, x );
		const edgeNoise = this.noise( Math.cos( ang ) * 1.3 + 10, Math.sin( ang ) * 1.3 + 10 ) * 0.12;
		const d = Math.hypot( x, z ) / ( this.radius * ( 1 + edgeNoise ) );
		const land = 1 - smoothstep( 0.78, 1.04, d );

		let h = 1.4 + fbm( this.noise, x * 0.018, z * 0.018, 4 ) * 2.4 + this.detail( x * 0.12, z * 0.12 ) * 0.15;

		// Quarry: rocky hills
		const deg = ang / DEG;
		if ( angleIn( deg, ZONES.quarry ) ) {

			const ridge = 1 - Math.abs( this.noise( x * 0.04 + 50, z * 0.04 ) );
			h += ridge * ridge * 5.5 * smoothstep( 25, 45, Math.hypot( x, z ) ) * land;

		}

		// Docks: gentle slope to the sea
		if ( angleIn( deg, ZONES.docks ) ) h *= 0.6;

		// Flatten the plaza and village
		const r = Math.hypot( x, z );
		const flat = 1 - smoothstep( 9, 22, r );
		h = h * ( 1 - flat ) + 1.5 * flat;
		if ( r < 36 ) h = Math.max( h, 0.9 * ( 1 - smoothstep( 30, 36, r ) ) + h * smoothstep( 30, 36, r ) ); // no ponds in the village

		// Sea floor
		return h * land + ( 1 - land ) * - 5;

	}

	/** Bilinear terrain height at world (x, z). */
	heightAt( x, z ) {

		const res = this.resolution;
		const fx = ( x / this.size + 0.5 ) * ( res - 1 );
		const fz = ( z / this.size + 0.5 ) * ( res - 1 );
		const ix = Math.max( 0, Math.min( res - 2, Math.floor( fx ) ) );
		const iz = Math.max( 0, Math.min( res - 2, Math.floor( fz ) ) );
		const tx = Math.min( 1, Math.max( 0, fx - ix ) );
		const tz = Math.min( 1, Math.max( 0, fz - iz ) );
		const g = this.grid;
		const a = g[ iz * res + ix ], b = g[ iz * res + ix + 1 ];
		const c = g[ ( iz + 1 ) * res + ix ], d = g[ ( iz + 1 ) * res + ix + 1 ];
		return ( a * ( 1 - tx ) + b * tx ) * ( 1 - tz ) + ( c * ( 1 - tx ) + d * tx ) * tz;

	}

	/** Approximate slope (0 = flat) used for placement and terrain colouring. */
	slopeAt( x, z ) {

		const e = 0.6;
		const dx = this.heightAt( x + e, z ) - this.heightAt( x - e, z );
		const dz = this.heightAt( x, z + e ) - this.heightAt( x, z - e );
		return Math.hypot( dx, dz ) / ( 2 * e );

	}

	isLand( x, z ) {

		return this.heightAt( x, z ) > CONFIG.world.waterLevel + 0.25;

	}

}
