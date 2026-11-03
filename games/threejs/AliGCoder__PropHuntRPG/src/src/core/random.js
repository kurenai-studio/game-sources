/**
 * Deterministic randomness. Every peer generates the identical map from the
 * host's seed, so all world generation must go through these helpers and
 * never through Math.random().
 */

/** Mulberry32 PRNG – returns a function producing floats in [0, 1). */
export function createRng( seed ) {

	let a = seed >>> 0;
	const next = () => {

		a = ( a + 0x6D2B79F5 ) >>> 0;
		let t = a;
		t = Math.imul( t ^ ( t >>> 15 ), t | 1 );
		t ^= t + Math.imul( t ^ ( t >>> 7 ), t | 61 );
		return ( ( t ^ ( t >>> 14 ) ) >>> 0 ) / 4294967296;

	};

	next.range = ( min, max ) => min + next() * ( max - min );
	next.int = ( min, max ) => Math.floor( next.range( min, max + 1 ) );
	next.pick = ( arr ) => arr[ Math.floor( next() * arr.length ) ];
	next.chance = ( p ) => next() < p;
	return next;

}

/** Hash a string into a 32-bit seed. */
export function hashString( str ) {

	let h = 2166136261;
	for ( let i = 0; i < str.length; i ++ ) {

		h ^= str.charCodeAt( i );
		h = Math.imul( h, 16777619 );

	}

	return h >>> 0;

}

/**
 * 2D simplex noise (Stefan Gustavson's public-domain algorithm), seeded.
 * Returns values in roughly [-1, 1].
 */
export function createNoise2D( seed ) {

	const rng = createRng( seed );
	const perm = new Uint8Array( 512 );
	const p = new Uint8Array( 256 );
	for ( let i = 0; i < 256; i ++ ) p[ i ] = i;
	for ( let i = 255; i > 0; i -- ) {

		const j = Math.floor( rng() * ( i + 1 ) );
		[ p[ i ], p[ j ] ] = [ p[ j ], p[ i ] ];

	}

	for ( let i = 0; i < 512; i ++ ) perm[ i ] = p[ i & 255 ];

	const grad = [ [ 1, 1 ], [ - 1, 1 ], [ 1, - 1 ], [ - 1, - 1 ], [ 1, 0 ], [ - 1, 0 ], [ 0, 1 ], [ 0, - 1 ] ];
	const F2 = 0.5 * ( Math.sqrt( 3 ) - 1 );
	const G2 = ( 3 - Math.sqrt( 3 ) ) / 6;

	return function noise( xin, yin ) {

		const s = ( xin + yin ) * F2;
		const i = Math.floor( xin + s );
		const j = Math.floor( yin + s );
		const t = ( i + j ) * G2;
		const x0 = xin - ( i - t );
		const y0 = yin - ( j - t );
		const i1 = x0 > y0 ? 1 : 0;
		const j1 = x0 > y0 ? 0 : 1;
		const x1 = x0 - i1 + G2, y1 = y0 - j1 + G2;
		const x2 = x0 - 1 + 2 * G2, y2 = y0 - 1 + 2 * G2;
		const ii = i & 255, jj = j & 255;

		let n = 0;
		const corner = ( x, y, gi ) => {

			let tt = 0.5 - x * x - y * y;
			if ( tt < 0 ) return 0;
			tt *= tt;
			const g = grad[ gi & 7 ];
			return tt * tt * ( g[ 0 ] * x + g[ 1 ] * y );

		};

		n += corner( x0, y0, perm[ ii + perm[ jj ] ] );
		n += corner( x1, y1, perm[ ii + i1 + perm[ jj + j1 ] ] );
		n += corner( x2, y2, perm[ ii + 1 + perm[ jj + 1 ] ] );
		return 70 * n;

	};

}

/** Fractal Brownian motion on top of a noise function. */
export function fbm( noise, x, y, octaves = 4, lacunarity = 2, gain = 0.5 ) {

	let amp = 1, freq = 1, sum = 0, norm = 0;
	for ( let o = 0; o < octaves; o ++ ) {

		sum += amp * noise( x * freq, y * freq );
		norm += amp;
		amp *= gain;
		freq *= lacunarity;

	}

	return sum / norm;

}
