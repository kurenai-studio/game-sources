import * as THREE from 'three/webgpu';
import { CONFIG } from '../config.js';
import { Environment } from './Environment.js';
import { PropFactory } from './PropFactory.js';
import { WorldView } from './WorldView.js';
import { Effects } from '../fx/Effects.js';

/**
 * Assembles a complete, renderable scene for a MapLayout. Shared by the
 * main-menu backdrop and the live game so both look identical.
 */
export function buildScene( renderer, layout ) {

	const quality = renderer.quality;
	const scene = new THREE.Scene();
	const camera = new THREE.PerspectiveCamera(
		CONFIG.camera.fov, renderer.container.clientWidth / renderer.container.clientHeight, 0.1, 1500
	);

	const environment = new Environment( renderer.renderer, scene, { shadowMapSize: quality.shadowMap } );
	const factory = new PropFactory();
	const world = new WorldView( layout, factory, { grassCount: quality.grass } );
	scene.add( world.group );
	const effects = new Effects( scene );

	environment.update();
	renderer.buildPipeline( scene, camera );

	return { scene, camera, environment, factory, world, effects };

}
