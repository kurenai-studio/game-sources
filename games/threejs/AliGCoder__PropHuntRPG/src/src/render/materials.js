import * as THREE from 'three/webgpu';
import {
	attribute, vertexColor, positionGeometry, positionLocal, modelPosition, time,
	sin, vec3, float, uniform, mix
} from 'three/tsl';

/**
 * Shared TSL node materials. One material serves every prop: colour comes
 * from vertex colours, glow from a per-vertex `glow` attribute (feeds bloom)
 * and wind sway from a per-vertex `sway` weight – so the entire world uses
 * a handful of materials and pipelines.
 */

export const windStrength = uniform( 1 );

let propMaterial = null;

export function getPropMaterial() {

	if ( propMaterial ) return propMaterial;

	const m = new THREE.MeshStandardNodeMaterial( { flatShading: true, roughness: 0.82, metalness: 0 } );
	const glow = attribute( 'glow', 'float' );
	const sway = attribute( 'sway', 'float' );

	m.colorNode = vertexColor();
	m.emissiveNode = vertexColor().mul( glow );

	// Each object sways with its own phase (from its world position)
	const phase = modelPosition.x.mul( 0.35 ).add( modelPosition.z.mul( 0.27 ) );
	const wave = sin( time.mul( 1.6 ).add( phase ) ).add( sin( time.mul( 2.7 ).add( phase.mul( 1.7 ) ) ).mul( 0.35 ) );
	const bend = sway.mul( positionGeometry.y ).mul( 0.03 ).mul( windStrength ).mul( wave );
	m.positionNode = positionLocal.add( vec3( bend, float( 0 ), bend.mul( 0.6 ) ) );

	propMaterial = m;
	return m;

}

/** A ghostly variant used for the local hider's own prop and previews. */
export function createGhostMaterial( color = 0x9fe7ff ) {

	const m = new THREE.MeshStandardNodeMaterial( { flatShading: true, transparent: true, roughness: 0.4 } );
	const tint = uniform( new THREE.Color( color ) );
	m.colorNode = mix( vertexColor(), tint, 0.55 );
	m.emissiveNode = tint.mul( sin( time.mul( 4 ) ).mul( 0.15 ).add( 0.3 ) );
	m.opacity = 0.55;
	m.depthWrite = false;
	return m;

}
