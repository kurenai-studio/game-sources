/** Soft round points sized in world units: `aSize` metres → pixels via `uScale` (screen height / tan(fov / 2)). */
export const PARTICLE_VERTEX = /* glsl */ `
attribute float aSize;
attribute vec3 aColor;
attribute float aAlpha;
uniform float uScale;
varying vec3 vC;
varying float vA;

void main() {
	vC = aColor;
	vA = aAlpha;
	vec4 mv = modelViewMatrix * vec4(position, 1.0);
	gl_PointSize = aSize * uScale / max(1.0, -mv.z);
	gl_Position = projectionMatrix * mv;
}
`

export const PARTICLE_FRAGMENT = /* glsl */ `
varying vec3 vC;
varying float vA;

void main() {
	float d = length(gl_PointCoord - 0.5);
	float a = smoothstep(0.5, 0.12, d) * vA;
	if (a < 0.01) discard;
	gl_FragColor = vec4(vC, a);
	#include <colorspace_fragment>
}
`
