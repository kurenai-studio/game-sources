shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 smoke_color : source_color = vec4(0.16, 0.15, 0.17, 1.0);
uniform float time = 0.0;
uniform float seed = 0.0;
uniform float alpha = 1.0;
uniform float global_fade = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.0, 289.0)) + seed * 21.0) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p = p * 2.01 + vec2(-13.1, 19.7);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= 1.08;
	uv.y *= 0.92;
	vec2 noise_uv = uv;
	noise_uv.y += time * 0.18;
	noise_uv.x += sin(time * 1.7 + seed) * 0.09;

	float radius = length(uv);
	float angle = atan(uv.y, uv.x);
	float lobe = 0.11 * sin(angle * 4.0 + seed * 1.7) + 0.07 * sin(angle * 7.0 - time * 0.55);
	float cloud_noise = fbm(noise_uv * 3.4 + vec2(seed * 0.27, time * 0.24));
	float pore_noise = fbm(noise_uv * 10.5 - vec2(time * 0.22, seed * 0.14));
	float distorted_radius = radius - lobe - cloud_noise * 0.18;
	float radial_mask = 1.0 - smoothstep(0.52, 1.02, distorted_radius);
	float edge_distance = 1.0 - max(abs(uv.x), abs(uv.y));
	float edge_guard = smoothstep(0.0, 0.18, edge_distance);
	float center_cut = smoothstep(0.04, 0.34, radius + pore_noise * 0.05);
	float smoke_shape = radial_mask * (0.55 + cloud_noise * 0.75) * (0.72 + pore_noise * 0.35);
	float soot = smoothstep(0.2, 0.9, pore_noise + radius * 0.35);
	float out_alpha = min(smoke_shape * center_cut * edge_guard * alpha * global_fade * smoke_color.a * 1.35, 0.95);

	if (out_alpha < 0.015) {
		discard;
	}

	float edge_soot = smoothstep(0.22, 0.88, radius + pore_noise * 0.12);
	vec3 color = mix(vec3(0.14, 0.13, 0.14), smoke_color.rgb * 0.35, max(soot, edge_soot));
	color *= 0.5 + 0.22 * cloud_noise;

	COLOR = vec4(color, out_alpha);
}
