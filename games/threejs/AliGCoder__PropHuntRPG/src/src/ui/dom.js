/**
 * Tiny DOM helper: h('div.class#id', { onclick, style, ... }, ...children)
 * Keeps UI modules declarative without pulling in a framework.
 */
export function h( selector, props = {}, ...children ) {

	const [ tag, ...rest ] = selector.split( /(?=[.#])/ );
	const el = document.createElement( tag || 'div' );
	for ( const token of rest ) {

		if ( token[ 0 ] === '.' ) el.classList.add( token.slice( 1 ) );
		else if ( token[ 0 ] === '#' ) el.id = token.slice( 1 );

	}

	if ( props && ( typeof props !== 'object' || props instanceof Node || Array.isArray( props ) ) ) {

		children.unshift( props );
		props = {};

	}

	for ( const [ key, value ] of Object.entries( props ?? {} ) ) {

		if ( value === undefined || value === null || value === false ) continue;
		if ( key.startsWith( 'on' ) && typeof value === 'function' ) el.addEventListener( key.slice( 2 ), value );
		else if ( key === 'style' && typeof value === 'object' ) Object.assign( el.style, value );
		else if ( key === 'class' ) el.className += ' ' + value;
		else if ( key === 'html' ) el.innerHTML = value;
		else if ( key in el && typeof value !== 'string' ) el[ key ] = value;
		else el.setAttribute( key, value === true ? '' : value );

	}

	append( el, children );
	return el;

}

function append( el, children ) {

	for ( const child of children.flat( Infinity ) ) {

		if ( child === null || child === undefined || child === false ) continue;
		el.appendChild( child instanceof Node ? child : document.createTextNode( String( child ) ) );

	}

}

export function clear( el ) {

	while ( el.firstChild ) el.removeChild( el.firstChild );
	return el;

}

export function formatTime( seconds ) {

	const s = Math.max( 0, Math.ceil( seconds ) );
	return `${Math.floor( s / 60 )}:${String( s % 60 ).padStart( 2, '0' )}`;

}

export function escapeText( s ) {

	return String( s ).replace( /[&<>"']/g, ( c ) => ( { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&#39;' }[ c ] ) );

}
