import * as THREE from 'three'
import type { Weather } from '../config'

/** Drops live in a box that travels with the camera; the shader wraps them around it, so the CPU never moves one. */
const BOX = new THREE.Vector3(70, 34, 70)
const STYLE = {
	rain: { count: 2600, fall: 16, sway: 0, size: 0.7, color: '#c7d3dc', alpha: 0.42, streak: 1 },
	snow: { count: 2200, fall: 1.6, sway: 0.9, size: 0.12, color: '#f6f8fb', alpha: 0.9, streak: 0 },
} as const
const MAX_POINT_PX = 48

const VERTEX = /* glsl */ `
attribute float aSeed;
uniform float uTime;
uniform float uFall;
uniform float uSway;
uniform float uSize;
uniform float uScale;
uniform vec3 uCentre;
uniform vec3 uBox;
varying float vA;

void main() {
	vec3 p = position;
	p.y -= uTime * uFall * (0.75 + 0.5 * aSeed);
	p.x += sin(uTime * 0.8 + aSeed * 40.0) * uSway;
	p.z += cos(uTime * 0.6 + aSeed * 25.0) * uSway;
	vec3 rel = mod(p - uCentre, uBox) - 0.5 * uBox;
	vec4 mv = viewMatrix * vec4(uCentre + rel, 1.0);
	float d = max(1.0, -mv.z);
	gl_PointSize = min(${MAX_POINT_PX}.0, uSize * uScale / d);
	// Thin out toward the box walls (no hard edge), and nothing right in the lens
	vA = (1.0 - smoothstep(0.3, 0.5, length(rel.xz) / uBox.x)) * smoothstep(1.5, 4.0, d);
	gl_Position = projectionMatrix * mv;
}
`

const FRAGMENT = /* glsl */ `
uniform vec3 uColor;
uniform float uAlpha;
uniform float uStreak;
varying float vA;

void main() {
	vec2 c = gl_PointCoord - 0.5;
	float a = uStreak > 0.5
		? (1.0 - smoothstep(0.03, 0.07, abs(c.x))) * (1.0 - abs(c.y) * 2.0)
		: smoothstep(0.5, 0.2, length(c));
	a *= uAlpha * vA;
	if (a < 0.01) discard;
	gl_FragColor = vec4(uColor, a);
	#include <colorspace_fragment>
}
`

/** Rain streaks or snowflakes around the camera: one draw call, no per-frame buffer uploads. */
export class Precipitation {
	readonly points: THREE.Points
	private readonly mat: THREE.ShaderMaterial
	private time = 0

	constructor() {
		const n = Math.max(STYLE.rain.count, STYLE.snow.count)
		const pos = new Float32Array(n * 3)
		const seed = new Float32Array(n)
		for (let i = 0; i < n; i++) {
			pos[i * 3] = Math.random() * BOX.x
			pos[i * 3 + 1] = Math.random() * BOX.y
			pos[i * 3 + 2] = Math.random() * BOX.z
			seed[i] = Math.random()
		}
		const geo = new THREE.BufferGeometry()
		geo.setAttribute('position', new THREE.BufferAttribute(pos, 3))
		geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1))
		this.mat = new THREE.ShaderMaterial({
			vertexShader: VERTEX,
			fragmentShader: FRAGMENT,
			transparent: true,
			depthWrite: false,
			uniforms: {
				uTime: { value: 0 },
				uFall: { value: 0 },
				uSway: { value: 0 },
				uSize: { value: 0 },
				uScale: { value: 1 },
				uCentre: { value: new THREE.Vector3() },
				uBox: { value: BOX },
				uColor: { value: new THREE.Color() },
				uAlpha: { value: 0 },
				uStreak: { value: 0 },
			},
		})
		this.points = new THREE.Points(geo, this.mat)
		this.points.frustumCulled = false
		this.points.visible = false
	}

	/** Rain or snow for this map's weather; anything else switches it off. */
	setWeather(weather: Weather) {
		const s = weather === 'rain' ? STYLE.rain : weather === 'snow' ? STYLE.snow : null
		this.points.visible = !!s
		if (!s) return
		const u = this.mat.uniforms
		u.uFall.value = s.fall
		u.uSway.value = s.sway
		u.uSize.value = s.size
		;(u.uColor.value as THREE.Color).set(s.color)
		u.uAlpha.value = s.alpha
		u.uStreak.value = s.streak
		this.points.geometry.setDrawRange(0, s.count)
	}

	setScale(bufferHeight: number, fovDeg: number) {
		this.mat.uniforms.uScale.value = bufferHeight / (2 * Math.tan((fovDeg * Math.PI) / 360))
	}

	/** Per frame: the box follows the camera; the satellite view looks down from far above it, so it is hidden there. */
	update(dt: number, camera: THREE.Camera, overhead: boolean) {
		this.time += dt
		const u = this.mat.uniforms
		u.uTime.value = this.time
		;(u.uCentre.value as THREE.Vector3).copy(camera.position)
		this.mat.visible = !overhead
	}
}
