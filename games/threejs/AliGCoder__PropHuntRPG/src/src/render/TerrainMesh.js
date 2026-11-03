import * as THREE from 'three/webgpu';
import { vertexColor, positionWorld, mx_noise_float, float } from 'three/tsl';
import { CONFIG } from '../config.js';

const SAND = new THREE.Color( 0xd8c28a );
const GRASS = new THREE.Color( 0x6aa84f );
const GRASS_DRY = new THREE.Color( 0x9cae5a );
const ROCK = new THREE.Color( 0x8a8478 );
const SEABED = new THREE.Color( 0x6b7d72 );
const PLAZA = new THREE.Color( 0xb9ad98 );

/**
 * Builds the island mesh from the shared Heightfield. Colours are baked per
 * vertex (sand / grass / rock / seabed) and broken up in the shader with
 * MaterialX noise for a hand-painted look.
 */
export function createTerrainMesh( heightfield ) {

	const { size, terrainSegments } = CONFIG.world;
	const geo = new THREE.PlaneGeometry( size, size, terrainSegments, terrainSegments );
	geo.rotateX( - Math.PI / 2 );

	const pos = geo.attributes.position;
	const colors = new Float32Array( pos.count * 3 );
	const c = new THREE.Color();

	for ( let i = 0; i < pos.count; i ++ ) {

		const x = pos.getX( i ), z = pos.getZ( i );
		const h = heightfield.heightAt( x, z );
		pos.setY( i, h );

		const slope = heightfield.slopeAt( x, z );
		const zone = heightfield.zoneAt( x, z );
		const dry = heightfield.noise( x * 0.03 + 7, z * 0.03 ) * 0.5 + 0.5;

		if ( h < CONFIG.world.waterLevel - 0.3 ) c.copy( SEABED ).lerp( SAND, THREE.MathUtils.clamp( ( h + 3 ) / 3, 0, 1 ) );
		else if ( h < CONFIG.world.waterLevel + 0.55 ) c.copy( SAND );
		else c.copy( GRASS ).lerp( GRASS_DRY, dry * 0.7 );

		if ( zone === 'plaza' ) c.lerp( PLAZA, 0.85 );
		if ( zone === 'quarry' ) c.lerp( ROCK, THREE.MathUtils.clamp( slope * 1.2 + 0.25, 0, 0.85 ) );
		else if ( slope > 0.65 ) c.lerp( ROCK, THREE.MathUtils.clamp( ( slope - 0.65 ) * 2, 0, 1 ) );

		c.toArray( colors, i * 3 );

	}

	geo.setAttribute( 'color', new THREE.BufferAttribute( colors, 3 ) );
	geo.computeVertexNormals();

	const material = new THREE.MeshStandardNodeMaterial( { roughness: 0.95, metalness: 0 } );
	const variation = mx_noise_float( positionWorld.xz.mul( 0.45 ) ).mul( 0.08 ).add( mx_noise_float( positionWorld.xz.mul( 2.5 ) ).mul( 0.04 ) );
	material.colorNode = vertexColor().mul( float( 1 ).add( variation ) );

	const mesh = new THREE.Mesh( geo, material );
	mesh.receiveShadow = true;
	mesh.name = 'terrain';
	return mesh;

}
