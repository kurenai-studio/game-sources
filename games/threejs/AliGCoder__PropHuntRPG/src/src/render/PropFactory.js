import * as THREE from 'three/webgpu';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { color, positionGeometry, time, sin, length, smoothstep, float } from 'three/tsl';
import { PROP_TYPES } from '../world/PropCatalog.js';
import { getPropMaterial } from './materials.js';

/**
 * Turns part lists (see PropCatalog) into single merged, flat-shaded
 * geometries with `color`, `glow` and `sway` vertex attributes. Geometries are
 * cached per type and shared by every instance (including disguised hiders).
 */
export class PropFactory {

	constructor() {

		this.cache = new Map();
		this.material = getPropMaterial();
		this.rippleMaterial = null;

	}

	geometryFor( typeId ) {

		if ( ! this.cache.has( typeId ) ) {

			const def = PROP_TYPES[ typeId ];
			this.cache.set( typeId, def?.parts?.length ? buildPartsGeometry( def.parts, typeId ) : null );

		}

		return this.cache.get( typeId );

	}

	/** A new Mesh for a prop type (shares geometry + material). */
	createMesh( typeId ) {

		const def = PROP_TYPES[ typeId ];
		if ( def?.special === 'ripples' ) return this.createRipples();
		const geo = this.geometryFor( typeId );
		if ( ! geo ) return new THREE.Group();
		const mesh = new THREE.Mesh( geo, this.material );
		mesh.castShadow = true;
		mesh.receiveShadow = true;
		return mesh;

	}

	/** Animated rings on the water marking a fishing spot (pure TSL). */
	createRipples() {

		if ( ! this.rippleMaterial ) {

			const m = new THREE.MeshBasicNodeMaterial( { transparent: true, depthWrite: false } );
			const r = length( positionGeometry.xy );
			const rings = sin( r.mul( 9 ).sub( time.mul( 3.5 ) ) ).mul( 0.5 ).add( 0.5 ).pow( 6 );
			const fade = smoothstep( float( 1.3 ), float( 0.2 ), r );
			m.colorNode = color( 0xeafcff );
			m.opacityNode = rings.mul( fade ).mul( 0.85 );
			this.rippleMaterial = m;

		}

		const mesh = new THREE.Mesh( new THREE.CircleGeometry( 1.3, 32 ), this.rippleMaterial );
		mesh.rotation.x = - Math.PI / 2;
		return mesh;

	}

}

/** Shared helper so characters and tools can use the same part format. */
export function buildPartsGeometry( parts, seedKey = '' ) {

	const geos = [];
	const m = new THREE.Matrix4();
	const q = new THREE.Quaternion();
	const e = new THREE.Euler();
	const s = new THREE.Vector3();
	const p = new THREE.Vector3();
	const c = new THREE.Color();

	parts.forEach( ( part, i ) => {

		let g = createShape( part.s, part.a );
		if ( g.index ) g = g.toNonIndexed();
		if ( part.j ) jitter( g, part.j * ( part.a[ 0 ] ?? 1 ), hashKey( seedKey + i ) );

		e.set( ...( part.r ?? [ 0, 0, 0 ] ) );
		q.setFromEuler( e );
		s.set( ...( part.sc ?? [ 1, 1, 1 ] ) );
		p.set( ...( part.p ?? [ 0, 0, 0 ] ) );
		m.compose( p, q, s );
		g.applyMatrix4( m );

		const count = g.attributes.position.count;
		const colors = new Float32Array( count * 3 );
		c.setHex( part.c ?? 0xffffff, THREE.SRGBColorSpace );
		for ( let v = 0; v < count; v ++ ) c.toArray( colors, v * 3 );
		g.setAttribute( 'color', new THREE.BufferAttribute( colors, 3 ) );
		g.setAttribute( 'glow', new THREE.BufferAttribute( new Float32Array( count ).fill( part.g ?? 0 ), 1 ) );
		g.setAttribute( 'sway', new THREE.BufferAttribute( new Float32Array( count ).fill( part.w ?? 0 ), 1 ) );
		g.deleteAttribute( 'uv' );
		geos.push( g );

	} );

	const merged = mergeGeometries( geos, false );
	merged.computeVertexNormals();
	merged.computeBoundingBox();
	merged.computeBoundingSphere();
	for ( const g of geos ) g.dispose();
	return merged;

}

function createShape( shape, a ) {

	switch ( shape ) {

		case 'box': return new THREE.BoxGeometry( a[ 0 ], a[ 1 ], a[ 2 ] );
		case 'cyl': return new THREE.CylinderGeometry( a[ 0 ], a[ 1 ], a[ 2 ], a[ 3 ] ?? 8, 1, a[ 4 ] ?? false );
		case 'cone': return new THREE.ConeGeometry( a[ 0 ], a[ 1 ], a[ 2 ] ?? 8 );
		case 'ico': return new THREE.IcosahedronGeometry( a[ 0 ], a[ 1 ] ?? 0 );
		case 'sphere': return new THREE.SphereGeometry( a[ 0 ], a[ 1 ] ?? 8, a[ 2 ] ?? 6 );
		case 'torus': return new THREE.TorusGeometry( a[ 0 ], a[ 1 ], a[ 2 ] ?? 4, a[ 3 ] ?? 12 );
		default: throw new Error( `Unknown shape "${shape}"` );

	}

}

/** Deterministic vertex jitter: identical positions move identically (no cracks). */
function jitter( geo, amount, seed ) {

	const pos = geo.attributes.position;
	for ( let i = 0; i < pos.count; i ++ ) {

		const x = pos.getX( i ), y = pos.getY( i ), z = pos.getZ( i );
		const h = hash3( Math.round( x * 1000 ), Math.round( y * 1000 ), Math.round( z * 1000 ), seed );
		const k = 1 + ( h - 0.5 ) * 2 * amount;
		pos.setXYZ( i, x * k, y * k, z * k );

	}

}

function hashKey( str ) {

	let h = 2166136261;
	for ( let i = 0; i < str.length; i ++ ) h = Math.imul( h ^ str.charCodeAt( i ), 16777619 );
	return h >>> 0;

}

function hash3( x, y, z, seed ) {

	let h = seed ^ Math.imul( x, 374761393 ) ^ Math.imul( y, 668265263 ) ^ Math.imul( z, 2147483647 );
	h = Math.imul( h ^ ( h >>> 13 ), 1274126177 );
	return ( ( h ^ ( h >>> 16 ) ) >>> 0 ) / 4294967296;

}
