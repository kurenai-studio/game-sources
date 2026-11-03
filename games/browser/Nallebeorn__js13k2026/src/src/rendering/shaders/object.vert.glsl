#version 300 es
layout(location = 0) in mat4 o; // objectToWorld
layout(location = 4) in vec4 d; // .x = object color, .y = object index, .z = length, .w = bend
layout(location = 5) in vec4 p; // .xyz = local vertex pos, .w = surface ID
uniform mat4 w; //  worldToClip

out vec4 v; // .xyz = local vertex pos, .w = surface ID
flat out vec4 D;

void main() {
	vec3 P = p.xyz;
	P.z *= d.z;
	if (d.w > 0. && P.z > d.w) {
		P.y -= 3. * (1.0 - cos((P.z - d.w) / 3. * 1.57));
		P.x += (P.z - d.w) * .05;
		P.z = d.w + 3. * sin((P.z - d.w) / 3. * 1.57);
	}
	gl_Position = w * o * vec4(P, 1);
	v = p;
	D = d;
}
