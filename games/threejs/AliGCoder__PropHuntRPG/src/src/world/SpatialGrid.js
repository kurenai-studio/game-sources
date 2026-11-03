/**
 * Uniform grid for fast "what is near (x, z)?" queries on circles.
 * Used for player collision, placement and host-side validation.
 */
export class SpatialGrid {

	constructor( cellSize = 4 ) {

		this.cellSize = cellSize;
		this.cells = new Map();

	}

	#key( cx, cz ) {

		return cx * 73856093 ^ cz * 19349663;

	}

	insert( item ) {

		const cx = Math.floor( item.x / this.cellSize ), cz = Math.floor( item.z / this.cellSize );
		const k = this.#key( cx, cz );
		if ( ! this.cells.has( k ) ) this.cells.set( k, [] );
		this.cells.get( k ).push( item );

	}

	remove( item ) {

		const cx = Math.floor( item.x / this.cellSize ), cz = Math.floor( item.z / this.cellSize );
		const list = this.cells.get( this.#key( cx, cz ) );
		if ( ! list ) return;
		const i = list.indexOf( item );
		if ( i >= 0 ) list.splice( i, 1 );

	}

	/** Items whose centre is within `radius` (+ their own radius when `inflate`). */
	query( x, z, radius, out = [] ) {

		const r = radius + 4; // allow for item radii up to ~4 m
		const minX = Math.floor( ( x - r ) / this.cellSize ), maxX = Math.floor( ( x + r ) / this.cellSize );
		const minZ = Math.floor( ( z - r ) / this.cellSize ), maxZ = Math.floor( ( z + r ) / this.cellSize );
		for ( let cx = minX; cx <= maxX; cx ++ ) {

			for ( let cz = minZ; cz <= maxZ; cz ++ ) {

				const list = this.cells.get( this.#key( cx, cz ) );
				if ( ! list ) continue;
				for ( const it of list ) {

					const d = Math.hypot( it.x - x, it.z - z );
					if ( d <= radius + ( it.radius ?? 0 ) ) out.push( it );

				}

			}

		}

		return out;

	}

}
