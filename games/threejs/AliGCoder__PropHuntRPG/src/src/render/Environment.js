import * as THREE from 'three/webgpu';
import { SkyMesh } from 'three/addons/objects/SkyMesh.js';
import { SunLight } from 'three/addons/lights/SunLight.js';

/**
 * Sky, sun and image-based lighting.
 *  - SkyMesh: physically-based TSL sky with animated clouds.
 *  - SunLight (r186+): directional sun with cascaded shadow maps.
 *  - The sky is baked into a PMREM so every PBR material is lit by it.
 */
export class Environment {

	constructor( renderer, scene, { shadowMapSize = 2048 } = {} ) {

		this.renderer = renderer;
		this.scene = scene;
		this.elevation = 28;
		this.azimuth = 140;

		this.sky = new SkyMesh();
		this.sky.scale.setScalar( 4000 );
		this.sky.turbidity.value = 2.5;
		this.sky.rayleigh.value = 1.6;
		this.sky.mieCoefficient.value = 0.004;
		this.sky.mieDirectionalG.value = 0.85;
		this.sky.cloudCoverage.value = 0.35;
		this.sky.cloudSpeed.value = 0.00003;
		this.sky.showSunDisc.value = 1;
		scene.add( this.sky );

		this.sun = new SunLight( 0xfff2e3, 3.4 );
		this.sun.castShadow = true;
		this.sun.shadow.camera.far = 220;
		this.sun.shadow.mapSize.setScalar( shadowMapSize );
		this.sun.shadow.normalBias = 0.04;
		scene.add( this.sun );

		this.fill = new THREE.HemisphereLight( 0xcfe8ff, 0x4a5a3a, 0.2 );
		scene.add( this.fill );

		scene.fog = new THREE.Fog( 0xbfd3e0, 110, 420 );
		scene.environmentIntensity = 0.38;

		this.pmrem = new THREE.PMREMGenerator( renderer );
		this.envScene = new THREE.Scene();
		this.envTarget = null;

	}

	/** Call after `renderer.init()`. Re-bakes the environment from the sky. */
	update() {

		const sunDir = new THREE.Vector3().setFromSphericalCoords(
			1, THREE.MathUtils.degToRad( 90 - this.elevation ), THREE.MathUtils.degToRad( this.azimuth )
		);
		this.sun.position.copy( sunDir );
		this.sky.sunPosition.value.copy( sunDir );

		const daylight = Math.min( 1, this.elevation / 30 );
		this.sun.color.lerpColors( new THREE.Color( 0xff9a5a ), new THREE.Color( 0xfff2e3 ), daylight );
		this.scene.fog.color.lerpColors( new THREE.Color( 0xd9a273 ), new THREE.Color( 0xbfd3e0 ), daylight );

		this.envTarget?.dispose();
		this.envScene.add( this.sky );
		this.envTarget = this.pmrem.fromScene( this.envScene );
		this.scene.add( this.sky );
		this.scene.environment = this.envTarget.texture;

	}

	setShadowMapSize( size ) {

		this.sun.shadow.mapSize.setScalar( size );
		this.sun.shadow.map?.dispose?.();
		this.sun.shadow.map = null;

	}

}
