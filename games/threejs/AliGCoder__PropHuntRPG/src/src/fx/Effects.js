import * as THREE from 'three/webgpu';
import { color, uniform, float } from 'three/tsl';

const MAX_PARTICLES = 600;
const _m = new THREE.Matrix4();
const _q = new THREE.Quaternion();
const _s = new THREE.Vector3();
const _c = new THREE.Color();

const SKILL_COLORS = {
	woodcutting: [ 0x8a5a36, 0x6aa84f, 0xc89a64 ],
	mining: [ 0x9aa3ad, 0xd27a3c, 0x5fe3ff ],
	fishing: [ 0x6fd3ff, 0xffffff, 0x2f8fb8 ],
	hit: [ 0xffe08a, 0xffffff, 0xff9a3c ],
	elim: [ 0xffffff, 0xff6b6b, 0xffd27a ],
	taunt: [ 0xff7ad9, 0xffd27a, 0x9ad0ff ]
};

/**
 * Lightweight world-space effects: pooled instanced particles, expanding
 * ability rings and harpoon lines.
 */
export class Effects {

	constructor( scene ) {

		this.scene = scene;
		const geo = new THREE.BoxGeometry( 1, 1, 1 );
		const mat = new THREE.MeshBasicNodeMaterial();
		this.points = new THREE.InstancedMesh( geo, mat, MAX_PARTICLES );
		this.points.frustumCulled = false;
		this.points.count = 0;
		this.points.instanceMatrix.setUsage( THREE.DynamicDrawUsage );
		for ( let i = 0; i < MAX_PARTICLES; i ++ ) this.points.setColorAt( i, _c.set( 0xffffff ) );
		scene.add( this.points );
		this.particles = [];
		this.transient = [];   // rings, lines: { obj, life, max, update }

	}

	burst( pos, kind = 'hit', count = 14, speed = 3 ) {

		const palette = SKILL_COLORS[ kind ] ?? SKILL_COLORS.hit;
		for ( let i = 0; i < count; i ++ ) {

			if ( this.particles.length >= MAX_PARTICLES ) this.particles.shift();
			const a = Math.random() * Math.PI * 2, up = Math.random();
			this.particles.push( {
				p: new THREE.Vector3( pos[ 0 ], pos[ 1 ], pos[ 2 ] ),
				v: new THREE.Vector3( Math.cos( a ) * speed * ( 0.3 + Math.random() ), speed * ( 0.6 + up ), Math.sin( a ) * speed * ( 0.3 + Math.random() ) ),
				life: 0.6 + Math.random() * 0.5,
				max: 1.1,
				size: 0.06 + Math.random() * 0.08,
				color: palette[ i % palette.length ],
				spin: Math.random() * 6
			} );

		}

	}

	/** Expanding ring on the ground (ability pulses). */
	ring( pos, radius, hex = 0x9fe7ff, duration = 0.8 ) {

		const mat = new THREE.MeshBasicNodeMaterial( { transparent: true, depthWrite: false, side: THREE.DoubleSide } );
		const opacity = uniform( 1 );
		mat.colorNode = color( hex ).mul( float( 2 ) );
		mat.opacityNode = opacity;
		mat.blending = THREE.AdditiveBlending;
		const mesh = new THREE.Mesh( new THREE.RingGeometry( 0.92, 1, 64 ), mat );
		mesh.rotation.x = - Math.PI / 2;
		mesh.position.set( pos[ 0 ], pos[ 1 ] + 0.15, pos[ 2 ] );
		this.scene.add( mesh );
		this.transient.push( {
			obj: mesh, life: duration, max: duration,
			update: ( t ) => {

				mesh.scale.setScalar( 0.5 + t * radius );
				opacity.value = 1 - t;

			}
		} );

	}

	line( from, to, hex = 0xd0f4ff, duration = 0.5 ) {

		const geo = new THREE.BufferGeometry().setFromPoints( [ new THREE.Vector3( ...from ), new THREE.Vector3( ...to ) ] );
		const mat = new THREE.LineBasicNodeMaterial( { color: hex, transparent: true } );
		const line = new THREE.Line( geo, mat );
		this.scene.add( line );
		this.transient.push( { obj: line, life: duration, max: duration, update: ( t ) => ( mat.opacity = 1 - t ) } );

	}

	update( dt ) {

		let n = 0;
		for ( let i = this.particles.length - 1; i >= 0; i -- ) {

			const pt = this.particles[ i ];
			pt.life -= dt;
			if ( pt.life <= 0 ) {

				this.particles.splice( i, 1 );
				continue;

			}

			pt.v.y -= 9 * dt;
			pt.p.addScaledVector( pt.v, dt );
			pt.spin += dt * 5;

		}

		for ( const pt of this.particles ) {

			const k = Math.min( 1, pt.life / 0.3 );
			_q.setFromAxisAngle( THREE.Object3D.DEFAULT_UP, pt.spin );
			_s.setScalar( pt.size * k );
			_m.compose( pt.p, _q, _s );
			this.points.setMatrixAt( n, _m );
			this.points.setColorAt( n, _c.setHex( pt.color ) );
			n ++;

		}

		this.points.count = n;
		this.points.instanceMatrix.needsUpdate = true;
		if ( this.points.instanceColor ) this.points.instanceColor.needsUpdate = true;

		for ( let i = this.transient.length - 1; i >= 0; i -- ) {

			const t = this.transient[ i ];
			t.life -= dt;
			t.update( 1 - Math.max( 0, t.life ) / t.max );
			if ( t.life <= 0 ) {

				this.scene.remove( t.obj );
				t.obj.geometry.dispose();
				t.obj.material.dispose();
				this.transient.splice( i, 1 );

			}

		}

	}

}
