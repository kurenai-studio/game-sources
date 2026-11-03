import * as THREE from 'three/webgpu';
import { CharacterModel } from './CharacterModel.js';
import { toolForTrade } from '../game/rules.js';

/**
 * The visual for one player (local or remote). Shows a character, a disguised
 * prop, or nothing (dead / spectating). Remote players are smoothed toward
 * their latest snapshot position.
 */
export class PlayerView {

	constructor( player, propFactory, isLocal ) {

		this.id = player.id;
		this.factory = propFactory;
		this.isLocal = isLocal;
		this.root = new THREE.Group();
		this.root.name = 'player-' + player.id;
		this.target = new THREE.Vector3( ...player.pos );
		this.root.position.copy( this.target );
		this.targetYaw = player.yaw ?? 0;
		this.speed = 0;

		this.lookKey = null;
		this.character = null;
		this.disguiseMesh = null;
		this.apply( player );

	}

	/** Pick the right look for the current player state. */
	apply( player ) {

		let key;
		if ( ! player.alive ) key = 'none';
		else if ( player.disguise ) key = 'prop:' + player.disguise;
		else if ( player.team === 'hunter' ) key = 'hunter:' + player.trade;
		else key = 'hider';

		if ( key === this.lookKey ) return;
		this.lookKey = key;

		this.root.clear();
		this.character = null;
		this.disguiseMesh = null;
		if ( key === 'none' ) return;

		if ( player.disguise ) {

			this.disguiseMesh = this.factory.createMesh( player.disguise );
			this.disguiseMesh.userData.hit = { kind: 'player', id: this.id };
			this.root.add( this.disguiseMesh );

		} else {

			const kind = player.team === 'hunter' ? 'hunter' : 'hider';
			this.character = new CharacterModel( kind );
			if ( kind === 'hunter' ) this.character.setTool( toolForTrade( player.trade ) );
			this.character.group.traverse( ( o ) => {

				if ( o.isMesh ) o.userData.hit = { kind: 'player', id: this.id };

			} );
			this.root.add( this.character.group );

		}

	}

	setTarget( pos, yaw ) {

		this.target.set( pos[ 0 ], pos[ 1 ], pos[ 2 ] );
		this.targetYaw = yaw;

	}

	snap() {

		this.root.position.copy( this.target );
		this.root.rotation.y = this.targetYaw;

	}

	swing() {

		this.character?.swing();

	}

	update( dt ) {

		const before = this.root.position.clone();
		if ( ! this.isLocal ) {

			const k = 1 - Math.exp( - dt * 12 );
			if ( this.root.position.distanceToSquared( this.target ) > 100 ) this.root.position.copy( this.target );
			else this.root.position.lerp( this.target, k );
			let dy = this.targetYaw - this.root.rotation.y;
			dy = Math.atan2( Math.sin( dy ), Math.cos( dy ) );
			this.root.rotation.y += dy * k;

		}

		const moved = before.distanceTo( this.root.position );
		this.speed = THREE.MathUtils.lerp( this.speed, dt > 0 ? moved / dt : 0, 0.2 );
		this.character?.update( dt, this.speed );

	}

	/** Meshes that hit-scans can hit. */
	get hitMeshes() {

		const out = [];
		this.root.traverse( ( o ) => {

			if ( o.isMesh ) out.push( o );

		} );
		return out;

	}

}
