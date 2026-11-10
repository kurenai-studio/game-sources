shader_type canvas_item;
// Névoa/fumaça animada procedural para o fundo do menu.

uniform vec4 fog_color : source_color = vec4(0.6, 0.15, 0.05, 1.0);
uniform float density = 0.45;
uniform float speed = 0.04;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * vec2(3.0, 2.0);
	float t = TIME * speed;
	float n = fbm(uv + vec2(t, -t * 0.6) + fbm(uv * 0.8 - vec2(t * 0.7, t)));
	// Mais denso na parte de baixo da tela
	float grad = smoothstep(0.1, 1.0, UV.y);
	float a = smoothstep(0.35, 0.9, n) * density * (0.35 + grad);
	COLOR = vec4(fog_color.rgb, a);
}
