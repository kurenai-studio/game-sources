#version 300 es

out vec2 v; // clip-space position

void main() {
	gl_Position = vec4(v = vec2(gl_VertexID*4 & 4, gl_VertexID*4 & 8) - 1., 0, 1);
}
