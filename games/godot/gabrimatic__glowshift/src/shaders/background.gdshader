shader_type canvas_item;

uniform vec2 cam = vec2(640.0, 360.0);
uniform float slow = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
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

float stars(vec2 uv, float scale, float thresh) {
	vec2 g = uv * scale;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id);
	if (h < thresh) {
		return 0.0;
	}
	vec2 o = vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5;
	float d = length(f - o * 0.7);
	float twinkle = 0.6 + 0.4 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
	return smoothstep(0.09, 0.0, d) * twinkle;
}

void fragment() {
	vec2 uv = UV * vec2(1280.0 / 720.0, 1.0);
	vec2 par = (cam - vec2(640.0, 360.0)) / 720.0;
	vec2 n_uv = uv * 1.6 - par * 0.04 + vec2(TIME * 0.008, 0.0);
	float n = fbm(n_uv + fbm(n_uv * 1.3 + TIME * 0.02));
	vec3 col = vec3(0.012, 0.012, 0.035);
	col += vec3(0.13, 0.03, 0.20) * smoothstep(0.45, 0.95, n);
	col += vec3(0.02, 0.09, 0.18) * smoothstep(0.35, 0.85, fbm(n_uv * 0.7 + 5.0));
	col += vec3(0.8, 0.85, 1.0) * stars(uv - par * 0.08, 70.0, 0.93) * 0.5;
	col += vec3(0.9, 0.95, 1.0) * stars(uv - par * 0.2, 32.0, 0.965) * 0.9;
	col *= mix(0.55, 1.0, smoothstep(1.1, 0.25, length(UV - 0.5) * 1.6));
	col = mix(col, vec3(dot(col, vec3(0.33))) * vec3(0.9, 0.6, 1.4), slow * 0.7);
	COLOR = vec4(col, 1.0);
}
