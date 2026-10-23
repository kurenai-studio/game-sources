shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 core_color : source_color = vec4(1.0, 0.92, 0.46, 1.0);
uniform vec4 outer_color : source_color = vec4(1.0, 0.34, 0.06, 1.0);
uniform float time = 0.0;
uniform float seed = 0.0;
uniform float alpha = 1.0;
uniform float global_fade = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 37.0) * 43758.5453123);
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
		p = p * 2.03 + vec2(17.13, -11.71);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x += sin(time * 5.0 + seed) * 0.035;
	uv.y += cos(time * 6.0 + seed * 1.3) * 0.035;

	float radius = length(uv);
	float angle = atan(uv.y, uv.x);
	vec2 turbulence_uv = uv * 3.6 + vec2(time * 2.1 + seed, -time * 1.4);
	float turbulence = fbm(turbulence_uv);
	float fine_turbulence = fbm(uv * 10.0 + vec2(seed * 1.9, time * 8.0));
	float lobe = 0.08 * sin(angle * 5.0 + seed) + 0.05 * sin(angle * 9.0 - time * 2.0);
	float pulse = 0.08 + 0.06 * sin(time * 11.0 + seed * 3.7);
	float distorted_radius = radius - lobe - turbulence * 0.21 + fine_turbulence * 0.07;

	float shell = 1.0 - smoothstep(0.36 + pulse, 0.96, distorted_radius);
	float hot_core = 1.0 - smoothstep(0.02, 0.46, distorted_radius + turbulence * 0.08);
	float white_center = 1.0 - smoothstep(0.0, 0.23, radius + fine_turbulence * 0.06);
	float orange_bloom = 1.0 - smoothstep(0.2, 0.74, distorted_radius);
	float flicker = 0.82 + fine_turbulence * 0.42;
	float ash_holes = smoothstep(0.56, 0.92, fbm(uv * 7.0 - vec2(time * 1.8, seed * 0.5)));

	vec3 color = mix(outer_color.rgb, core_color.rgb, hot_core);
	color = mix(color, vec3(1.0, 0.86, 0.46), white_center * 0.85);
	color += vec3(1.0, 0.26, 0.02) * orange_bloom * 0.65;
	color *= flicker;

	float edge_mask = 1.0 - smoothstep(0.78, 1.06, radius);
	float out_alpha = shell * edge_mask * alpha * global_fade * flicker;
	out_alpha *= 1.0 - smoothstep(0.58, 1.0, radius) * 0.58;
	out_alpha *= mix(1.0, 0.55, ash_holes * smoothstep(0.18, 0.78, radius));
	if (out_alpha < 0.01) {
		discard;
	}
	COLOR = vec4(color, out_alpha);
}
