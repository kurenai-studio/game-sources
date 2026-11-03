import * as THREE from 'three/webgpu';
import { CONFIG } from '../config.js';
import { PROP_TYPES } from '../world/PropCatalog.js';

const _move = new THREE.Vector3();

/**
 * Kinematic character controller for the local player: WASD relative to the
 * camera, gravity, jumping, swimming, and circle-vs-circle collision with
 * props (via the layout's spatial grid). Movement is client-authoritative;
 * the host sanity-checks speed.
 */
export class LocalController {

	constructor( layout, input ) {

		this.layout = layout;
		this.input = input;
		this.position = new THREE.Vector3();
		this.velocityY = 0;
		this.yaw = 0;               // facing of the body / prop
		this.onGround = true;
		this.radius = CONFIG.player.radius;
		this.rotationLocked = false;
		this.speed = 0;

	}

	teleport( pos, yaw ) {

		this.position.set( pos[ 0 ], pos[ 1 ], pos[ 2 ] );
		this.velocityY = 0;
		if ( yaw !== undefined ) this.yaw = yaw;

	}

	/**
	 * @param {number} dt
	 * @param {object} opts { cameraYaw, canMove, speedMultiplier, faceCamera }
	 */
	update( dt, { cameraYaw, canMove, speedMultiplier = 1, faceCamera = false } ) {

		const p = CONFIG.player;
		const input = this.input;

		_move.set( 0, 0, 0 );
		if ( canMove ) {

			if ( input.isDown( 'forward' ) ) _move.z += 1;
			if ( input.isDown( 'back' ) ) _move.z -= 1;
			if ( input.isDown( 'left' ) ) _move.x += 1;
			if ( input.isDown( 'right' ) ) _move.x -= 1;

		}

		const ground = this.layout.heightAt( this.position.x, this.position.z );
		const swimming = ground < CONFIG.world.waterLevel - 0.6;

		let speed = p.walkSpeed * speedMultiplier;
		if ( input.isDown( 'sprint' ) ) speed *= p.sprintMultiplier;
		if ( swimming ) speed *= p.swimSpeedMultiplier;

		if ( _move.lengthSq() > 0 ) {

			_move.normalize().applyAxisAngle( THREE.Object3D.DEFAULT_UP, cameraYaw );
			this.position.x += _move.x * speed * dt;
			this.position.z += _move.z * speed * dt;
			if ( ! faceCamera && ! this.rotationLocked ) this.yaw = dampAngle( this.yaw, Math.atan2( _move.x, _move.z ), dt * 12 );
			this.speed = speed;

		} else {

			this.speed = 0;

		}

		if ( faceCamera && ! this.rotationLocked ) this.yaw = cameraYaw;

		this.#collide();
		this.#keepOnIsland();

		// Vertical
		const floor = swimming ? CONFIG.world.waterLevel - 0.45 : this.layout.heightAt( this.position.x, this.position.z );
		if ( canMove && this.onGround && input.wasPressed( 'jump' ) && ! swimming ) {

			this.velocityY = p.jumpVelocity;
			this.onGround = false;

		}

		this.velocityY -= p.gravity * dt;
		this.position.y += this.velocityY * dt;
		if ( this.position.y <= floor ) {

			this.position.y = floor;
			this.velocityY = 0;
			this.onGround = true;

		}

	}

	#collide() {

		const nearby = this.layout.nearby( this.position.x, this.position.z, this.radius + 0.5 );
		for ( const prop of nearby ) {

			const def = PROP_TYPES[ prop.type ];
			if ( def.special ) continue;
			// Low props can be jumped onto / over
			if ( this.position.y > prop.y + def.height * 0.9 ) continue;
			const dx = this.position.x - prop.x, dz = this.position.z - prop.z;
			const d = Math.hypot( dx, dz );
			const min = this.radius + def.radius * 0.85;
			if ( d < min && d > 1e-4 ) {

				const push = ( min - d ) / d;
				this.position.x += dx * push;
				this.position.z += dz * push;

			}

		}

	}

	#keepOnIsland() {

		const max = CONFIG.world.size * 0.5 - 4;
		const r = Math.hypot( this.position.x, this.position.z );
		if ( r > max ) {

			this.position.x *= max / r;
			this.position.z *= max / r;

		}

	}

}

function dampAngle( a, b, t ) {

	let d = b - a;
	d = Math.atan2( Math.sin( d ), Math.cos( d ) );
	return a + d * Math.min( 1, t );

}
