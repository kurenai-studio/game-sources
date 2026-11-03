import * as THREE from 'three/webgpu';
import { PROP_TYPES } from '../world/PropCatalog.js';
import { createTerrainMesh } from './TerrainMesh.js';
import { createWaterMesh } from './WaterMesh.js';
import { GrassField } from './GrassField.js';

/** What a depleted node turns into until it respawns. */
const DEPLETED_LOOK = { pine: 'stump', oak: 'stump', birch: 'stump', copper_ore: 'rock_small', crystal: 'rock_small' };

/**
 * Visual representation of a MapLayout: terrain, water, grass, every prop,
 * depleted nodes and decoys. Also owns the raycast target list.
 */
export class WorldView {

	constructor( layout, propFactory, { grassCount } ) {

		this.layout = layout;
		this.factory = propFactory;
		this.group = new THREE.Group();
		this.group.name = 'world';

		this.terrain = createTerrainMesh( layout.heightfield );
		this.terrain.userData.hit = { kind: 'terrain' };
		this.water = createWaterMesh( layout.heightfield );
		this.grass = new GrassField( layout, grassCount );
		this.group.add( this.terrain, this.water, this.grass.mesh );

		this.propMeshes = [];          // index -> Object3D
		this.depletedMeshes = new Map();
		this.decoyMeshes = new Map();
		this.raycastTargets = [ this.terrain ];

		for ( const prop of layout.props ) {

			const mesh = propFactory.createMesh( prop.type );
			mesh.position.set( prop.x, prop.y, prop.z );
			mesh.rotation.y = prop.yaw;
			mesh.userData.hit = { kind: 'prop', id: prop.index, type: prop.type };
			mesh.matrixAutoUpdate = false;
			mesh.updateMatrix();
			this.group.add( mesh );
			this.propMeshes[ prop.index ] = mesh;
			if ( PROP_TYPES[ prop.type ].special !== 'ripples' ) this.raycastTargets.push( mesh );

		}

		// Fishing spots are hittable by harpoons even though they're flat
		for ( const prop of layout.props ) {

			if ( PROP_TYPES[ prop.type ].special === 'ripples' ) this.raycastTargets.push( this.propMeshes[ prop.index ] );

		}

	}

	setDepleted( index, depleted ) {

		const mesh = this.propMeshes[ index ];
		if ( ! mesh ) return;
		mesh.visible = ! depleted;

		const existing = this.depletedMeshes.get( index );
		if ( depleted && ! existing ) {

			const prop = this.layout.props[ index ];
			const look = DEPLETED_LOOK[ prop.type ];
			if ( look ) {

				const stub = this.factory.createMesh( look );
				stub.position.copy( mesh.position );
				stub.rotation.y = prop.yaw;
				stub.userData.hit = { kind: 'prop', id: index, type: prop.type, depleted: true };
				this.group.add( stub );
				this.depletedMeshes.set( index, stub );
				this.raycastTargets.push( stub );

			}

		} else if ( ! depleted && existing ) {

			this.group.remove( existing );
			this.depletedMeshes.delete( index );
			this.#removeTarget( existing );

		}

	}

	resetDepleted() {

		for ( const index of [ ...this.depletedMeshes.keys() ] ) this.setDepleted( index, false );
		for ( const mesh of this.propMeshes ) if ( mesh ) mesh.visible = true;

	}

	addDecoy( decoy ) {

		if ( this.decoyMeshes.has( decoy.id ) ) return;
		const mesh = this.factory.createMesh( decoy.type );
		mesh.position.set( ...decoy.pos );
		mesh.rotation.y = decoy.yaw;
		mesh.userData.hit = { kind: 'decoy', id: decoy.id, type: decoy.type };
		this.group.add( mesh );
		this.decoyMeshes.set( decoy.id, mesh );
		this.raycastTargets.push( mesh );

	}

	removeDecoy( id ) {

		const mesh = this.decoyMeshes.get( id );
		if ( ! mesh ) return;
		this.group.remove( mesh );
		this.decoyMeshes.delete( id );
		this.#removeTarget( mesh );

	}

	clearDecoys() {

		for ( const id of [ ...this.decoyMeshes.keys() ] ) this.removeDecoy( id );

	}

	#removeTarget( obj ) {

		const i = this.raycastTargets.indexOf( obj );
		if ( i >= 0 ) this.raycastTargets.splice( i, 1 );

	}

	update( playerPos ) {

		this.grass.update( playerPos );

	}

}
