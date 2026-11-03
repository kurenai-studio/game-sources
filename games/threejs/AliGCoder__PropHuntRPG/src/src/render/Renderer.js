import * as THREE from 'three/webgpu';
import {
	pass, mrt, output, emissive, vec4, normalView, velocity, packNormalToRGB, unpackRGBToNormal,
	sample, screenUV, builtinAOContext, uniform, time, oscSine
} from 'three/tsl';
import { ao } from 'three/addons/tsl/display/GTAONode.js';
import { traa } from 'three/addons/tsl/display/TRAANode.js';
import { bloom } from 'three/addons/tsl/display/BloomNode.js';
import { outline } from 'three/addons/tsl/display/OutlineNode.js';
import { SunLight } from 'three/addons/lights/SunLight.js';
import { SunLightNode } from 'three/addons/lights/SunLightNode.js';
import { CONFIG } from '../config.js';

// SunLight needs its node implementation registered for WebGPURenderer.
SunLight.registerNode( SunLightNode );

/**
 * WebGPURenderer (with automatic WebGL2 fallback) + a TSL RenderPipeline.
 *
 * Pipeline (high):   pre-pass (normals + velocity MRT) ─► GTAO ─► scene pass
 *                    (AO via builtinAOContext, emissive MRT) ─► TRAA
 *                    + selective bloom (emissive only) + outline
 * Pipeline (medium): scene pass (MSAA, emissive MRT) + selective bloom + outline
 * Pipeline (low):    scene pass + outline
 *
 * Outlines are used for gameplay: revealed hiders (red) or your hider team
 * mates (blue).
 */
export class Renderer {

	constructor( container, qualityName = 'high' ) {

		this.container = container;
		this.qualityName = qualityName;
		this.quality = CONFIG.quality[ qualityName ];

		this.renderer = new THREE.WebGPURenderer( { antialias: false } );
		this.renderer.setPixelRatio( Math.min( window.devicePixelRatio, this.quality.pixelRatio ) );
		this.renderer.setSize( container.clientWidth, container.clientHeight );
		this.renderer.shadowMap.enabled = true;
		this.renderer.shadowMap.type = THREE.PCFShadowMap; // soft in r186+
		this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
		this.renderer.toneMappingExposure = 0.72;
		container.appendChild( this.renderer.domElement );

		this.outlined = [];
		this.outlineColor = uniform( new THREE.Color( 0xff4d4d ) );
		this.pipeline = null;

		window.addEventListener( 'resize', () => this.resize() );

	}

	get domElement() {

		return this.renderer.domElement;

	}

	get backendName() {

		return this.renderer.backend?.isWebGPUBackend ? 'WebGPU' : 'WebGL 2';

	}

	async init() {

		await this.renderer.init();

	}

	/** (Re)build the post-processing graph for a scene + camera. */
	buildPipeline( scene, camera ) {

		this.scene = scene;
		this.camera = camera;
		this.pipeline?.dispose();

		const q = this.quality;
		const pipeline = new THREE.RenderPipeline( this.renderer );

		// Main scene pass. With bloom on, it also writes emissive into a second
		// render target (MRT) so only glowing things bloom – not the bright sky.
		const scenePass = pass( scene, camera, { samples: q.ao ? 0 : q.msaa } );
		if ( q.bloom ) {

			const sceneMRT = mrt( { output, emissive: vec4( emissive, output.a ) } );
			sceneMRT.setBlendMode( 'emissive', new THREE.BlendMode( THREE.NormalBlending ) );
			scenePass.setMRT( sceneMRT );
			scenePass.getTexture( 'emissive' ).type = THREE.UnsignedByteType;

		}

		let color = scenePass.getTextureNode( 'output' );

		if ( q.ao ) {

			// Depth/normal/velocity pre-pass feeding GTAO and temporal AA
			const prePass = pass( scene, camera );
			prePass.name = 'Pre-Pass';
			prePass.transparent = false;
			prePass.setMRT( mrt( { output: packNormalToRGB( normalView ), velocity } ) );
			prePass.getTexture( 'output' ).type = THREE.UnsignedByteType;

			const prePassNormal = sample( ( uv ) => unpackRGBToNormal( prePass.getTextureNode().sample( uv ) ) );
			const prePassDepth = prePass.getTextureNode( 'depth' );
			const prePassVelocity = prePass.getTextureNode( 'velocity' );

			const aoPass = ao( prePassDepth, prePassNormal, camera );
			aoPass.resolutionScale = 0.5;
			aoPass.radius.value = 0.6;
			aoPass.scale.value = 0.7;
			scenePass.contextNode = builtinAOContext( aoPass.getTextureNode().sample( screenUV ).r );
			this.aoPass = aoPass;

			const traaPass = traa( color, prePassDepth, prePassVelocity, camera );
			traaPass.useSubpixelCorrection = false;
			color = traaPass;

		}

		if ( q.bloom ) {

			this.bloomPass = bloom( scenePass.getTextureNode( 'emissive' ), 1.6, 0.45, 0 );
			color = color.add( this.bloomPass );

		}

		const outlinePass = outline( scene, camera, {
			selectedObjects: this.outlined,
			edgeThickness: uniform( 1.5 ),
			edgeGlow: uniform( 0.4 )
		} );
		const pulse = oscSine( time.mul( 1.5 ) ).mul( 0.4 ).add( 0.8 );
		const outlineColor = outlinePass.visibleEdge.mul( this.outlineColor ).mul( 3 )
			.add( outlinePass.hiddenEdge.mul( this.outlineColor ).mul( 1.2 ) ).mul( pulse );

		pipeline.outputNode = color.add( outlineColor );
		this.pipeline = pipeline;

	}

	/** Replace the set of outlined objects. */
	setOutlined( objects, hexColor ) {

		this.outlined.length = 0;
		for ( const o of objects ) this.outlined.push( o );
		if ( hexColor !== undefined ) this.outlineColor.value.setHex( hexColor );

	}

	setQuality( name ) {

		if ( ! CONFIG.quality[ name ] ) return;
		this.qualityName = name;
		this.quality = CONFIG.quality[ name ];
		this.renderer.setPixelRatio( Math.min( window.devicePixelRatio, this.quality.pixelRatio ) );
		if ( this.scene ) this.buildPipeline( this.scene, this.camera );

	}

	resize() {

		const w = this.container.clientWidth, h = this.container.clientHeight;
		this.renderer.setSize( w, h );
		if ( this.camera ) {

			this.camera.aspect = w / h;
			this.camera.updateProjectionMatrix();

		}

	}

	render() {

		if ( this.pipeline ) this.pipeline.render();
		else if ( this.scene ) this.renderer.render( this.scene, this.camera );

	}

}
