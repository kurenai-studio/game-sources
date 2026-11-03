#version 300 es
precision highp float;

in vec4 v; // .xyz = local vertex pos, .w = surface ID
flat in vec4 D; // .x = object color, .y = object index, .z = length, .w = bend

uniform vec4 p[32]; // palette

layout(location=0) out vec4 o; // output color
layout(location=1) out uvec2 s; // surface index

void main() {
	s = uvec2(round(v.w), D.y);
	o = D.x > 60. ? p[int((21. + (-v.w) * 7.))] : p[int(D.x)];// + v * vec4(-.5, 1, .5, 0) * .1;
	if (D.w > 0. && length(o.rgb) == 0.) {
		discard;
	}
	// o = vec4(0, 0, 0, 0);
}
