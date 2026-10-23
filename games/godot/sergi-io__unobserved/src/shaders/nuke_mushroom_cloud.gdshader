shader_type canvas_item;
render_mode blend_mix;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float global_fade : hint_range(0.0, 1.0) = 1.0;
uniform float expansion_duration_ratio : hint_range(0.0, 1.0) = 0.36;
uniform float seed = 0.0;
uniform bool use_fog_visibility_mask = false;
uniform sampler2D fog_visibility_mask : filter_linear, repeat_disable;
uniform vec2 fog_world_bounds_min = vec2(-1.0, -1.0);
uniform vec2 fog_world_bounds_max = vec2(1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.42, 1.0);
uniform vec4 fire_color : source_color = vec4(1.0, 0.32, 0.08, 1.0);
uniform vec4 smoke_color : source_color = vec4(0.2, 0.18, 0.24, 1.0);
uniform vec4 rim_color : source_color = vec4(0.72, 0.9, 1.0, 1.0);

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32 + seed);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p = p * 2.03 + vec2(17.7, 9.2);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float t = clamp(progress, 0.0, 1.0);
	float fade_in = smoothstep(0.0, 0.045, t);
	float fade_out = 1.0 - smoothstep(0.82, 1.0, t);
	float life = fade_in * fade_out * global_fade;

	float safe_expansion_duration_ratio = max(expansion_duration_ratio, 0.001);
	float expansion = expansion_duration_ratio <= 0.0 ? 1.0 : smoothstep(0.0, safe_expansion_duration_ratio, t);
	vec2 warp_a = vec2(
		fbm(p * 2.1 + vec2(seed * 0.013 + t * 0.08, 5.1)),
		fbm(p * 2.1 + vec2(7.4, seed * 0.019 - t * 0.06))
	) - vec2(0.5);
	vec2 warp_b = vec2(
		fbm(p * 4.7 + vec2(2.0, seed * 0.031)),
		fbm(p * 4.7 + vec2(seed * 0.027, 8.0))
	) - vec2(0.5);
	vec2 q = p + warp_a * (0.28 + t * 0.16) + warp_b * 0.08;
	float r = length(q);
	float n = fbm(q * (3.0 - expansion * 0.9) + vec2(seed * 0.017, t * 0.1));
	float fine = fbm(q * 9.0 + vec2(seed * 0.011, -t * 0.18));
	float high = fbm(q * 18.0 + vec2(seed * 0.023 + t * 0.38, seed * 0.014));

	float cloud_radius = mix(0.08, 0.62, expansion);
	float edge_noise = (n - 0.5) * 0.36 + (fine - 0.5) * 0.09 + (high - 0.5) * 0.04;
	float primary_flash = (1.0 - smoothstep(0.0, 0.36, r + edge_noise * 0.22)) * (1.0 - smoothstep(0.1, 0.32, t));
	float white_flash = (1.0 - smoothstep(0.0, 0.16, r + edge_noise * 0.12)) * (1.0 - smoothstep(0.035, 0.16, t));
	float thermal_shell = 1.0 - smoothstep(0.0, 0.045, abs(r - mix(0.14, 0.48, smoothstep(0.02, 0.42, t))) + edge_noise * 0.05);
	thermal_shell *= 1.0 - smoothstep(0.12, 0.52, t);
	float outer_fire_shell = 1.0 - smoothstep(0.0, 0.052, abs(r - mix(0.28, 0.66, expansion)) + edge_noise * 0.07);
	outer_fire_shell *= smoothstep(0.04, 0.18, t) * (1.0 - smoothstep(0.28, 0.72, t));
	float dense_core = (1.0 - smoothstep(0.0, cloud_radius * 0.56, r + edge_noise * 0.12)) * smoothstep(0.04, 0.22, t);
	float cloud = smoothstep(cloud_radius + 0.24, cloud_radius - 0.1, r + edge_noise);

	vec2 offset_one = q - vec2(0.14, -0.1);
	vec2 offset_two = q - vec2(-0.18, 0.12);
	vec2 offset_three = q - vec2(0.02, 0.2);
	float plume_one = smoothstep(0.42, 0.04, length(offset_one) + (fbm(offset_one * 6.0 + seed) - 0.5) * 0.18);
	float plume_two = smoothstep(0.46, 0.05, length(offset_two) + (fbm(offset_two * 5.3 + seed * 0.7) - 0.5) * 0.2);
	float plume_three = smoothstep(0.38, 0.03, length(offset_three) + (fbm(offset_three * 7.1 - seed * 0.3) - 0.5) * 0.16);
	float smoke_age = smoothstep(0.22, 0.76, t);
	float lingering_smoke = max(max(plume_one, plume_two), plume_three) * smoke_age;
	cloud = max(cloud, lingering_smoke * 0.8);
	cloud = max(cloud, dense_core * 0.7);

	float fissure_noise = fbm(q * 12.0 + vec2(seed * 0.021, 4.0));
	float fissures = smoothstep(0.72, 0.92, fissure_noise) * smoothstep(0.08, 0.42, r);
	fissures *= 1.0 - smoothstep(0.2, 0.4, t);
	fissures *= smoothstep(0.16, 0.34, cloud);

	float shock_radius = mix(0.05, 0.72, smoothstep(0.0, 0.24, t));
	float shock = 1.0 - smoothstep(0.0, 0.038, abs(r - shock_radius));
	shock *= 1.0 - smoothstep(0.1, 0.34, t);
	float secondary_shock = 1.0 - smoothstep(0.0, 0.052, abs(r - mix(0.22, 0.82, smoothstep(0.08, 0.44, t))));
	secondary_shock *= smoothstep(0.08, 0.2, t) * (1.0 - smoothstep(0.32, 0.68, t));
	float ember_layer = smoothstep(0.72, 0.95, high) * smoothstep(0.16, 0.5, r) * (1.0 - smoothstep(0.64, 0.88, r));
	ember_layer *= smoothstep(0.12, 0.32, t) * (1.0 - smoothstep(0.58, 0.9, t));

	float connected_mask = 1.0 - smoothstep(0.72, 0.86, length(p));
	cloud *= connected_mask;
	fissures *= connected_mask;
	primary_flash *= connected_mask;
	white_flash *= connected_mask;
	thermal_shell *= connected_mask;
	outer_fire_shell *= connected_mask;
	shock *= connected_mask;
	secondary_shock *= connected_mask;
	ember_layer *= connected_mask;

	float hot_core = clamp(primary_flash * 1.35 + white_flash * 1.6 + thermal_shell * 0.7 + outer_fire_shell * 0.42 + fissures * 0.9, 0.0, 1.0);
	float rim = clamp(shock + secondary_shock * 0.76 + fissures * 0.55 + smoothstep(0.5, 0.82, cloud) * (1.0 - smoothstep(0.3, 0.58, t)) * 0.18, 0.0, 1.0);
	float smoke_mix = smoothstep(0.12, 0.82, t) * clamp(cloud + fine * 0.28, 0.0, 1.0);

	vec3 color = mix(fire_color.rgb, smoke_color.rgb, smoke_mix);
	color = mix(color, core_color.rgb, hot_core);
	color = mix(color, rim_color.rgb, rim * 0.62);
	color += fire_color.rgb * (fissures * 0.45 + outer_fire_shell * 0.42 + ember_layer * 0.24);
	color += core_color.rgb * (white_flash * 0.5 + thermal_shell * 0.25);

	float alpha = clamp(cloud * 0.8 + shock * 0.48 + secondary_shock * 0.24 + hot_core * 0.45 + outer_fire_shell * 0.3 + ember_layer * 0.18 + fissures * 0.25, 0.0, 1.0);
	if (use_fog_visibility_mask) {
		vec2 fog_bounds_size = fog_world_bounds_max - fog_world_bounds_min;
		vec2 fog_uv = (world_position - fog_world_bounds_min) / max(fog_bounds_size, vec2(0.0001));
		float fog_visible_alpha = 1.0 - texture(fog_visibility_mask, clamp(fog_uv, vec2(0.0), vec2(1.0))).a;
		alpha *= clamp(fog_visible_alpha, 0.0, 1.0);
	}
	alpha *= life;
	COLOR = vec4(color, alpha);
}
