shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 camera_position = vec2(0.0);
uniform float camera_zoom = 1.0;
uniform vec2 viewport_size = vec2(1600.0, 900.0);
uniform float seed = 0.0;
uniform float layer_index = 0.0;
uniform float parallax_scale = 0.05;
uniform float noise_scale = 2.0;
uniform float distortion = 0.4;
uniform float opacity = 0.35;
uniform vec4 color_a : source_color = vec4(0.002, 0.014, 0.022, 1.0);
uniform vec4 color_b : source_color = vec4(0.02, 0.32, 0.39, 1.0);
uniform vec4 color_c : source_color = vec4(0.35, 1.0, 0.88, 1.0);
uniform float glow_strength = 0.24;
uniform float edge_softness = 0.24;
uniform float animation_speed = 0.08;
uniform float animation_enabled = 1.0;
uniform int octave_count = 4;

float hash12(vec2 value) {
	vec3 p = fract(vec3(value.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i + seed);
	float b = hash12(i + vec2(1.0, 0.0) + seed);
	float c = hash12(i + vec2(0.0, 1.0) + seed);
	float d = hash12(i + vec2(1.0, 1.0) + seed);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

mat2 rotation2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	mat2 m = mat2(vec2(1.62, -1.12), vec2(1.08, 1.48));
	for (int i = 0; i < 4; i++) {
		if (i >= octave_count) {
			break;
		}
		value += value_noise(p) * amplitude;
		p = m * p + vec2(2.17, -1.43);
		amplitude *= 0.52;
	}
	return value;
}

void fragment() {
	vec2 safe_viewport = max(viewport_size, vec2(1.0));
	vec2 uv = UV - vec2(0.5);
	uv.x *= safe_viewport.x / safe_viewport.y;

	float time_value = TIME * animation_speed * animation_enabled;
	vec2 parallax = camera_position * parallax_scale / safe_viewport.y;
	vec2 p = uv + parallax;
	p = rotation2d(0.22 + layer_index * 0.37) * p;

	vec2 flow = vec2(time_value * 0.07, -time_value * 0.04);
	vec2 warp = vec2(
		fbm(p * noise_scale + flow + vec2(11.7, 4.1)),
		fbm(p * noise_scale - flow + vec2(-3.8, 9.4))
	);
	vec2 domain = p + (warp - vec2(0.5)) * distortion;
	float broad = fbm(domain * noise_scale + layer_index * 1.7);
	float detail = fbm(domain * (noise_scale * 2.4) + warp * 1.8);
	float ridge = 1.0 - abs(2.0 * fbm(domain * (noise_scale * 1.45) + vec2(seed * 0.01)) - 1.0);

	float band = smoothstep(0.95, 0.0, abs(domain.y + sin(domain.x * 2.1 + seed) * 0.18));
	float density = broad * 0.62 + detail * 0.24 + ridge * 0.14;
	float mask = smoothstep(0.34, 0.34 + edge_softness, density) * band;
	float voids = smoothstep(0.15, 0.78, ridge);
	mask *= mix(0.45, 1.0, voids);

	vec3 color = mix(color_a.rgb, color_b.rgb, smoothstep(0.2, 0.78, density));
	color = mix(color, color_c.rgb, smoothstep(0.68, 1.0, density) * glow_strength);
	color += color_c.rgb * pow(max(mask, 0.0), 2.4) * glow_strength;
	COLOR = vec4(color, clamp(mask * opacity, 0.0, 1.0));
}
