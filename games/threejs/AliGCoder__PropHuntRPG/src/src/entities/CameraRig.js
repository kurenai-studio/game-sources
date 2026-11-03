import * as THREE from 'three/webgpu';
import { CONFIG } from '../config.js';

const _target = new THREE.Vector3();
const _dir = new THREE.Vector3();
const _right = new THREE.Vector3();

/**
 * Over-the-shoulder third-person camera driven by mouse look. Also handles
 * the spectator orbit and the hunters' "blindfold" pose during prep.
 */
export class CameraRig {

	constructor( camera, layout ) {

		this.camera = camera;
		this.layout = layout;
		this.yaw = Math.PI;
		this.pitch = - 0.15;
		this.distance = CONFIG.camera.distance;
		this.currentDistance = this.distance;

	}

	applyMouse( delta ) {

		this.yaw -= delta.x;
		this.pitch = THREE.MathUtils.clamp( this.pitch - delta.y, - 1.2, 0.9 );

	}

	/** Forward direction on the ground plane (used for movement). */
	get forwardYaw() {

		return this.yaw;

	}

	/**
	 * @param {THREE.Vector3} focus point to follow (player feet)
	 * @param {number} focusHeight height of the look target above `focus`
	 */
	update( dt, focus, focusHeight = CONFIG.camera.height, extraDistance = 0 ) {

		const want = this.distance + extraDistance;
		this.currentDistance = THREE.MathUtils.damp( this.currentDistance, want, 8, dt );

		_target.copy( focus );
		_target.y += focusHeight;

		_dir.set(
			Math.sin( this.yaw ) * Math.cos( this.pitch ),
			Math.sin( this.pitch ),
			Math.cos( this.yaw ) * Math.cos( this.pitch )
		);
		_right.set( - Math.cos( this.yaw ), 0, Math.sin( this.yaw ) );

		const cam = this.camera.position;
		cam.copy( _target )
			.addScaledVector( _dir, - this.currentDistance )
			.addScaledVector( _right, CONFIG.camera.shoulder );

		const floor = this.layout.groundAt( cam.x, cam.z ) + 0.35;
		if ( cam.y < floor ) cam.y = floor;

		this.camera.lookAt( _target.addScaledVector( _right, CONFIG.camera.shoulder ) );

	}

	/** Ray from the screen centre (crosshair). */
	getAimRay( raycaster ) {

		raycaster.setFromCamera( new THREE.Vector2( 0, 0 ), this.camera );
		return raycaster.ray;

	}

}
