import * as THREE from 'three/webgpu';
import {
	positionGeometry, positionLocal, time, sin, vec3, float, uniform, smoothstep,
	mix, color, hash, instanceIndex, mx_noise_float, vec2
} from 'three/tsl';
import { createRng } from '../core/random.js';
import { CONFIG } from '../config.js';
import { windStrength } from './materials.js';

const BLADE_HEIGHT = 0.55;

/**
 * Instanced grass clumps with TSL wind and player interaction: blades bend
 * away from the local player (`playerPosition` uniform). Instancing happens
 * before `positionNode`, so `positionLocal` here is already world-space.
 */
export class GrassField {

	constructor( layout, count ) {

		this.playerPosition = uniform( new THREE.Vector3( 1e5, 0, 1e5 ) );
		this.mesh = this.#build( layout, count );

	}

	#build( layout, count ) {

		const geo = clumpGeometry();
		const material = new THREE.MeshStandardNodeMaterial( { side: THREE.DoubleSide, roughness: 0.9 } );

		const h = positionGeometry.y.div( BLADE_HEIGHT ).clamp( 0, 1 );
		const bend = h.mul( h );
		const world = positionLocal;
		const gust = mx_noise_float( vec2( world.x.mul( 0.05 ).add( time.mul( 0.35 ) ), world.z.mul( 0.05 ) ) ).mul( 0.5 ).add( 0.6 );
		const wave = sin( time.mul( 2.2 ).add( world.x.mul( 0.3 ) ).add( world.z.mul( 0.22 ) ).add( hash( instanceIndex ).mul( 2 ) ) );
		const windX = wave.mul( gust ).mul( bend ).mul( 0.16 ).mul( windStrength );

		// Push away from the player
		const away = world.xz.sub( this.playerPosition.xz );
		const dist = away.length().max( 0.001 );
		const push = smoothstep( float( 1.3 ), float( 0.0 ), dist ).mul( bend ).mul( 0.45 );
		const pushXZ = away.div( dist ).mul( push );

		material.positionNode = world.add( vec3( windX.add( pushXZ.x ), push.mul( - 0.25 ), windX.mul( 0.5 ).add( pushXZ.y ) ) );

		const tint = hash( instanceIndex.add( 7 ) ).mul( 0.25 ).add( 0.85 );
		material.colorNode = mix( color( 0x2f6d2a ), color( 0x9ccc5a ), h ).mul( tint );

		const mesh = new THREE.InstancedMesh( geo, material, count );
		mesh.receiveShadow = true;
		mesh.castShadow = false;
		mesh.frustumCulled = false;
		mesh.name = 'grass';

		const rng = createRng( layout.seed ^ 0x6a55 );
		const hf = layout.heightfield;
		const dummy = new THREE.Object3D();
		let placed = 0;

		for ( let tries = 0; tries < count * 6 && placed < count; tries ++ ) {

			const r = Math.sqrt( rng() ) * CONFIG.world.islandRadius;
			const a = rng() * Math.PI * 2;
			const x = Math.cos( a ) * r, z = Math.sin( a ) * r;
			const y = hf.heightAt( x, z );
			if ( y < CONFIG.world.waterLevel + 0.6 ) continue;
			const zone = hf.zoneAt( x, z );
			if ( zone === 'plaza' || ( zone === 'quarry' && rng.chance( 0.85 ) ) ) continue;
			if ( hf.slopeAt( x, z ) > 0.7 ) continue;

			dummy.position.set( x, y - 0.02, z );
			dummy.rotation.set( 0, rng() * Math.PI * 2, 0 );
			const s = rng.range( 0.7, 1.35 );
			dummy.scale.set( s, s * rng.range( 0.8, 1.3 ), s );
			dummy.updateMatrix();
			mesh.setMatrixAt( placed ++, dummy.matrix );

		}

		mesh.count = placed;
		mesh.instanceMatrix.needsUpdate = true;
		return mesh;

	}

	update( playerPos ) {

		if ( playerPos ) this.playerPosition.value.copy( playerPos );

	}

}

/** Three crossed, tapered blades merged into one clump. */
function clumpGeometry() {

	const positions = [];
	const blade = ( angle, lean ) => {

		const w = 0.07, hh = BLADE_HEIGHT;
		const ca = Math.cos( angle ), sa = Math.sin( angle );
		const pt = ( x, y, z ) => [ x * ca - z * sa, y, x * sa + z * ca ];
		const v0 = pt( - w, 0, 0 ), v1 = pt( w, 0, 0 );
		const v2 = pt( - w * 0.6, hh * 0.5, lean * 0.5 ), v3 = pt( w * 0.6, hh * 0.5, lean * 0.5 );
		const v4 = pt( 0, hh, lean );
		positions.push( ...v0, ...v1, ...v3, ...v0, ...v3, ...v2, ...v2, ...v3, ...v4 );

	};

	blade( 0, 0.12 );
	blade( 2.1, 0.08 );
	blade( 4.2, 0.15 );

	const geo = new THREE.BufferGeometry();
	geo.setAttribute( 'position', new THREE.Float32BufferAttribute( positions, 3 ) );
	geo.computeVertexNormals();
	// Point normals up so lighting is soft and consistent on both faces
	const n = geo.attributes.normal;
	for ( let i = 0; i < n.count; i ++ ) n.setXYZ( i, 0, 1, 0 );
	return geo;

}
