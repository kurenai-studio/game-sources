import * as THREE from 'three/webgpu';
import {
	positionGeometry, positionLocal, positionWorld, time, sin, vec3, vec2, float,
	texture, smoothstep, mix, color, mx_noise_float, uniform
} from 'three/tsl';
import { CONFIG } from '../config.js';

/**
 * Stylised low-poly water written entirely in TSL:
 *  - vertex waves (sum of sines) + flat shading for faceted highlights
 *  - depth colour + shoreline foam from a baked terrain height texture
 *  - reflections from the sky environment map (low roughness)
 */
export function createWaterMesh( heightfield ) {

	const { size, waterLevel } = CONFIG.world;
	const extent = size * 3;
	const geo = new THREE.PlaneGeometry( extent, extent, 220, 220 );
	geo.rotateX( - Math.PI / 2 );

	// Bake terrain height into an 8-bit texture so the shader knows water depth
	const res = heightfield.resolution;
	const data = new Uint8Array( res * res * 4 );
	const range = heightfield.max - heightfield.min;
	for ( let i = 0; i < res * res; i ++ ) {

		const v = Math.round( ( ( heightfield.grid[ i ] - heightfield.min ) / range ) * 255 );
		data[ i * 4 ] = v;
		data[ i * 4 + 3 ] = 255;

	}

	const heightTex = new THREE.DataTexture( data, res, res, THREE.RGBAFormat );
	heightTex.magFilter = THREE.LinearFilter;
	heightTex.minFilter = THREE.LinearFilter;
	heightTex.wrapS = heightTex.wrapT = THREE.ClampToEdgeWrapping;
	heightTex.needsUpdate = true;

	const uMin = uniform( heightfield.min ), uRange = uniform( range ), uSize = uniform( size );

	const material = new THREE.MeshStandardNodeMaterial( {
		flatShading: true, transparent: true, roughness: 0.12, metalness: 0.05
	} );

	// Waves
	const p = positionGeometry;
	const wave = sin( p.x.mul( 0.35 ).add( time.mul( 1.2 ) ) ).mul( 0.12 )
		.add( sin( p.z.mul( 0.42 ).add( time.mul( 0.9 ) ) ).mul( 0.1 ) )
		.add( sin( p.x.add( p.z ).mul( 0.9 ).add( time.mul( 2.1 ) ) ).mul( 0.04 ) );
	material.positionNode = positionLocal.add( vec3( 0, wave, 0 ) );

	// Depth from the baked height texture
	const terrainUv = positionWorld.xz.div( uSize ).add( 0.5 );
	const terrainH = texture( heightTex, vec2( terrainUv.x, terrainUv.y ) ).r.mul( uRange ).add( uMin );
	const depth = float( waterLevel ).sub( terrainH ).max( 0 );

	const shallow = color( 0x4fd1c5 ), deep = color( 0x10506e );
	const foamNoise = mx_noise_float( positionWorld.xz.mul( 0.9 ).add( vec2( time.mul( 0.3 ), time.mul( 0.2 ) ) ) ).mul( 0.5 ).add( 0.5 );
	const foam = smoothstep( float( 0.7 ), float( 0.0 ), depth ).mul( foamNoise.mul( 0.6 ).add( 0.5 ) ).clamp( 0, 1 );

	material.colorNode = mix( mix( shallow, deep, smoothstep( float( 0 ), float( 5 ), depth ) ), color( 0xffffff ), foam );
	material.opacityNode = mix( float( 0.55 ), float( 0.93 ), smoothstep( float( 0 ), float( 2.5 ), depth ) ).max( foam );

	const mesh = new THREE.Mesh( geo, material );
	mesh.position.y = waterLevel;
	mesh.receiveShadow = true;
	mesh.name = 'water';
	return mesh;

}
