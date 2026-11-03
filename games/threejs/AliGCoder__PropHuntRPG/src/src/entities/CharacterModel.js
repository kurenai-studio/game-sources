import * as THREE from 'three/webgpu';
import { buildPartsGeometry } from '../render/PropFactory.js';
import { getPropMaterial } from '../render/materials.js';

const SKIN = 0xf1c7a0;

/** Low-poly adventurer bodies, built from the same part format as props. */
const BODIES = {
	hunter: [
		{ s: 'cyl', a: [ 0.32, 0.36, 0.75, 8 ], p: [ 0, 0.95, 0 ], c: 0x7a3b2e },       // tunic
		{ s: 'cyl', a: [ 0.37, 0.37, 0.1, 8 ], p: [ 0, 0.7, 0 ], c: 0x3b2a1e },         // belt
		{ s: 'box', a: [ 0.16, 0.6, 0.18 ], p: [ - 0.14, 0.3, 0 ], c: 0x3d3a44 },       // legs
		{ s: 'box', a: [ 0.16, 0.6, 0.18 ], p: [ 0.14, 0.3, 0 ], c: 0x3d3a44 },
		{ s: 'sphere', a: [ 0.27, 10, 8 ], p: [ 0, 1.58, 0 ], c: SKIN },               // head
		{ s: 'cone', a: [ 0.36, 0.42, 8 ], p: [ 0, 1.86, 0 ], c: 0x4a3426 },           // hood
		{ s: 'box', a: [ 0.06, 0.06, 0.02 ], p: [ - 0.09, 1.62, 0.25 ], c: 0x1a1a1a }, // eyes
		{ s: 'box', a: [ 0.06, 0.06, 0.02 ], p: [ 0.09, 1.62, 0.25 ], c: 0x1a1a1a },
		{ s: 'box', a: [ 0.12, 0.55, 0.14 ], p: [ - 0.42, 1.05, 0 ], r: [ 0, 0, 0.15 ], c: 0x7a3b2e }, // left arm
		{ s: 'box', a: [ 0.4, 0.5, 0.18 ], p: [ 0, 1.05, - 0.32 ], c: 0x5b4632 }        // backpack
	],
	hider: [
		{ s: 'cyl', a: [ 0.3, 0.34, 0.7, 8 ], p: [ 0, 0.92, 0 ], c: 0x3f7f5a },
		{ s: 'box', a: [ 0.15, 0.58, 0.17 ], p: [ - 0.13, 0.29, 0 ], c: 0x5a4a3a },
		{ s: 'box', a: [ 0.15, 0.58, 0.17 ], p: [ 0.13, 0.29, 0 ], c: 0x5a4a3a },
		{ s: 'sphere', a: [ 0.26, 10, 8 ], p: [ 0, 1.52, 0 ], c: SKIN },
		{ s: 'sphere', a: [ 0.28, 10, 6 ], p: [ 0, 1.6, - 0.03 ], sc: [ 1, 0.7, 1 ], c: 0xb5793e },
		{ s: 'box', a: [ 0.06, 0.06, 0.02 ], p: [ - 0.09, 1.55, 0.24 ], c: 0x1a1a1a },
		{ s: 'box', a: [ 0.06, 0.06, 0.02 ], p: [ 0.09, 1.55, 0.24 ], c: 0x1a1a1a },
		{ s: 'box', a: [ 0.12, 0.5, 0.14 ], p: [ - 0.4, 1.0, 0 ], r: [ 0, 0, 0.15 ], c: 0x3f7f5a }
	],
	spectator: [
		{ s: 'sphere', a: [ 0.3, 10, 8 ], p: [ 0, 1.4, 0 ], c: 0xbfe9ff, g: 0.8 }
	]
};

/** Hunter tools – held in the right hand, pointing forward (+Z). */
const TOOLS = {
	axe: [
		{ s: 'cyl', a: [ 0.035, 0.035, 0.9, 6 ], p: [ 0, 0, 0.35 ], r: [ Math.PI / 2, 0, 0 ], c: 0x8a5a36 },
		{ s: 'box', a: [ 0.05, 0.28, 0.22 ], p: [ 0, 0.1, 0.72 ], c: 0xb8c0c8 }
	],
	pickaxe: [
		{ s: 'cyl', a: [ 0.035, 0.035, 0.9, 6 ], p: [ 0, 0, 0.35 ], r: [ Math.PI / 2, 0, 0 ], c: 0x8a5a36 },
		{ s: 'cone', a: [ 0.05, 0.3, 4 ], p: [ 0, 0.16, 0.76 ], c: 0x9aa3ad },
		{ s: 'cone', a: [ 0.05, 0.3, 4 ], p: [ 0, - 0.16, 0.76 ], r: [ Math.PI, 0, 0 ], c: 0x9aa3ad }
	],
	harpoon: [
		{ s: 'cyl', a: [ 0.03, 0.03, 1.4, 6 ], p: [ 0, 0, 0.55 ], r: [ Math.PI / 2, 0, 0 ], c: 0x6b4a2f },
		{ s: 'cone', a: [ 0.07, 0.25, 6 ], p: [ 0, 0, 1.35 ], r: [ Math.PI / 2, 0, 0 ], c: 0xd0d8de }
	]
};

const cache = new Map();

function geometry( key, parts ) {

	if ( ! cache.has( key ) ) cache.set( key, buildPartsGeometry( parts, key ) );
	return cache.get( key );

}

/**
 * A character: body mesh + right-hand pivot holding a tool.
 * `swing()` plays a quick chop animation.
 */
export class CharacterModel {

	constructor( kind = 'hider' ) {

		this.group = new THREE.Group();
		this.body = new THREE.Mesh( geometry( 'body-' + kind, BODIES[ kind ] ), getPropMaterial() );
		this.body.castShadow = true;
		this.group.add( this.body );

		this.hand = new THREE.Group();
		this.hand.position.set( 0.42, 1.05, 0.05 );
		this.group.add( this.hand );

		const arm = new THREE.Mesh( geometry( 'arm-' + kind, [
			{ s: 'box', a: [ 0.12, 0.5, 0.14 ], p: [ 0, - 0.05, 0 ], c: kind === 'hunter' ? 0x7a3b2e : 0x3f7f5a }
		] ), getPropMaterial() );
		arm.castShadow = true;
		this.hand.add( arm );

		this.tool = null;
		this.swingTime = 0;
		this.walkPhase = 0;

	}

	setTool( toolId ) {

		if ( this.tool ) this.hand.remove( this.tool );
		this.tool = null;
		if ( ! toolId || ! TOOLS[ toolId ] ) return;
		this.tool = new THREE.Mesh( geometry( 'tool-' + toolId, TOOLS[ toolId ] ), getPropMaterial() );
		this.tool.position.set( 0, - 0.25, 0 );
		this.tool.castShadow = true;
		this.hand.add( this.tool );

	}

	swing() {

		this.swingTime = 0.35;

	}

	update( dt, speed ) {

		this.walkPhase += dt * speed * 2.2;
		const bob = Math.abs( Math.sin( this.walkPhase ) ) * Math.min( 1, speed / 4 ) * 0.06;
		this.body.position.y = bob;

		if ( this.swingTime > 0 ) {

			this.swingTime = Math.max( 0, this.swingTime - dt );
			const t = 1 - this.swingTime / 0.35;
			this.hand.rotation.x = - Math.sin( t * Math.PI ) * 1.8 + 0.6 * Math.sin( t * Math.PI * 2 );

		} else {

			this.hand.rotation.x = Math.sin( this.walkPhase ) * 0.4 * Math.min( 1, speed / 4 );

		}

	}

}
