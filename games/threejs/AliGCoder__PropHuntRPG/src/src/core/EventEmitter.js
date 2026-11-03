/**
 * Minimal typed-by-convention event emitter used across modules so they can
 * talk without importing each other.
 */
export class EventEmitter {

	#listeners = new Map();

	on( type, fn ) {

		if ( ! this.#listeners.has( type ) ) this.#listeners.set( type, new Set() );
		this.#listeners.get( type ).add( fn );
		return () => this.off( type, fn );

	}

	once( type, fn ) {

		const off = this.on( type, ( ...args ) => {

			off();
			fn( ...args );

		} );
		return off;

	}

	off( type, fn ) {

		this.#listeners.get( type )?.delete( fn );

	}

	emit( type, ...args ) {

		const set = this.#listeners.get( type );
		if ( ! set ) return;
		for ( const fn of [ ...set ] ) fn( ...args );

	}

	clear() {

		this.#listeners.clear();

	}

}
