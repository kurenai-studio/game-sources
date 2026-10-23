shader_type canvas_item;
render_mode unshaded;

uniform vec2 camera_position = vec2(0.0);
uniform float camera_zoom = 1.0;
uniform vec2 viewport_size = vec2(1600.0, 900.0);

uniform float reference_zoom = 1.0;
uniform float zoomed_out_parallax_strength = 0.35;

uniform float far_enabled = 1.0;
uniform float far_scroll_scale = 0.1;
uniform float far_cell_size = 38.0;
uniform float far_min_size = 0.15;
uniform float far_max_size = 0.55;
uniform float far_zoom_size_influence = 0.3;
uniform vec4 far_color : source_color = vec4(0.72, 0.8, 1.0, 0.64);

uniform float mid_enabled = 1.0;
uniform float mid_scroll_scale = 0.3;
uniform float mid_cell_size = 86.0;
uniform float mid_min_size = 0.35;
uniform float mid_max_size = 0.9;
uniform float mid_zoom_size_influence = 0.45;
uniform vec4 mid_color : source_color = vec4(0.88, 0.92, 1.0, 0.84);

uniform float near_enabled = 1.0;
uniform float near_scroll_scale = 1.0;
uniform float near_cell_size = 220.0;
uniform float near_min_size = 0.7;
uniform float near_max_size = 1.55;
uniform float near_zoom_size_influence = 0.65;
uniform vec4 near_color : source_color = vec4(1.0, 1.0, 1.0, 0.97);

uniform vec4 background_color : source_color = vec4(0.07450980392156863, 0.08235294117647059, 0.10980392156862745, 1.0);

uniform float nebula_enabled = 1.0;
uniform float nebula_time = 0.0;
uniform float nebula_animation_enabled = 1.0;
uniform float nebula_animation_speed = 0.18;
uniform float nebula_scroll_scale = 0.08;
uniform float nebula_scale = 2.25;
uniform float nebula_detail_scale = 5.2;
uniform float nebula_warp_strength = 0.62;
uniform float nebula_detail_strength = 0.9;
uniform float nebula_density = 0.82;
uniform float nebula_cutoff = 0.3;
uniform float nebula_softness = 0.32;
uniform float nebula_opacity = 0.72;
uniform float nebula_saturation = 1.0;
uniform float nebula_brightness = 0.82;
uniform float nebula_shadow_strength = 1.1;
uniform float nebula_glow_strength = 0.34;
uniform float nebula_twist = 0.9;
uniform float nebula_flow = 0.08;
uniform float nebula_pulse_speed = 0.22;
uniform float nebula_pulse_amount = 0.08;
uniform float nebula_vignette_strength = 0.5;
uniform vec2 nebula_offset = vec2(0.0);
uniform vec4 nebula_background_color : source_color = vec4(0.07450980392156863, 0.08235294117647059, 0.10980392156862745, 1.0);
uniform vec4 nebula_dark_color : source_color = vec4(0.005, 0.006, 0.014, 1.0);
uniform vec4 nebula_primary_color : source_color = vec4(0.31, 0.14, 0.56, 1.0);
uniform vec4 nebula_secondary_color : source_color = vec4(0.12, 0.24, 0.64, 1.0);
uniform vec4 nebula_accent_color : source_color = vec4(0.06, 0.05, 0.14, 1.0);
uniform vec4 nebula_halo_color : source_color = vec4(0.48, 0.34, 0.94, 1.0);
uniform float nebula_halo_strength = 0.26;

float hash12(vec2 value) {
	vec3 p = fract(vec3(value.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

vec2 hash22(vec2 value) {
	vec3 p = fract(vec3(value.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33);
	return fract((p.xx + p.yz) * p.zy);
}

mat2 rotation2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	mat2 transform = mat2(vec2(1.62, -1.22), vec2(1.18, 1.56));

	for (int i = 0; i < 3; i++) {
		value += value_noise(p) * amplitude;
		p = transform * p + vec2(0.71, 0.47);
		amplitude *= 0.5;
	}

	return value;
}

float ridged_fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	mat2 transform = mat2(vec2(1.38, -1.15), vec2(1.05, 1.42));

	for (int i = 0; i < 2; i++) {
		float n = 1.0 - abs(2.0 * value_noise(p) - 1.0);
		value += n * n * amplitude;
		p = transform * p + vec2(2.61, -1.73);
		amplitude *= 0.55;
	}

	return value;
}

float effective_scroll_scale(float scroll_scale) {
	float zoom_ratio = clamp(camera_zoom / max(reference_zoom, 0.001), 0.0, 1.0);
	float strength = mix(zoomed_out_parallax_strength, 1.0, zoom_ratio);
	return mix(1.0, scroll_scale, strength);
}

float star_size_scale(float zoom_size_influence) {
	return mix(1.0, camera_zoom, clamp(zoom_size_influence, 0.0, 1.0));
}

float star_layer(vec2 screen_offset, float scroll_scale, float cell_size, float min_size, float max_size, float zoom_size_influence, float seed) {
	vec2 layer_position = camera_position * scroll_scale + screen_offset;
	vec2 cell = floor(layer_position / cell_size);
	vec2 cell_uv = fract(layer_position / cell_size);
	vec2 random_position = hash22(cell + seed);
	float random_size = hash12(cell + seed + 17.0);
	float radius_world = mix(min_size, max_size, random_size);
	float radius = max(radius_world * star_size_scale(zoom_size_influence) / cell_size, 0.0001);
	float distance_to_star = length(cell_uv - random_position);
	float core = smoothstep(radius, radius * 0.35, distance_to_star);
	float glow = smoothstep(radius * 3.0, radius, distance_to_star) * 0.25;
	float twinkle = mix(0.65, 1.0, hash12(cell + seed + 43.0));
	return clamp((core + glow) * twinkle, 0.0, 1.0);
}

float nebula_field(vec2 p, float time_value) {
	vec2 animated_flow = vec2(time_value * nebula_flow, -time_value * nebula_flow * 0.73);
	float twist_angle = sin(time_value * 0.13) * nebula_twist * 0.2;
	vec2 warped = rotation2d(twist_angle) * (p + animated_flow + nebula_offset);

	vec2 warp_a = vec2(
		fbm(warped * 0.72 + vec2(1.7, 9.2)),
		fbm(warped * 0.72 + vec2(7.9, -3.1))
	);
	vec2 warp_b = vec2(
		fbm(warped * nebula_scale * 1.18 + warp_a * 1.7),
		fbm(warped * nebula_scale * 1.18 - warp_a * 1.4 + vec2(11.9, -6.4))
	);

	vec2 domain = warped + warp_a * nebula_warp_strength * 0.6 + warp_b * nebula_warp_strength * 0.35;
	float broad = fbm(domain * nebula_scale);
	float detail = fbm(domain * nebula_detail_scale + warp_b * nebula_detail_strength * 0.5);
	float ridged = ridged_fbm(domain * (nebula_scale * 0.72) + warp_a * 0.8);
	float banding = fbm(rotation2d(0.35) * domain * (nebula_scale * 0.55) + time_value * 0.06);

	float density = broad * 0.65 + detail * 0.35;
	density += (ridged - 0.45) * 0.25;
	density += (banding - 0.5) * 0.2;
	density = clamp(density * nebula_density, 0.0, 1.0);

	float mask = smoothstep(nebula_cutoff, nebula_cutoff + max(nebula_softness, 0.001), density);
	float voids = 1.0 - smoothstep(0.18, 0.88, ridged);
	float pulse = 1.0 + sin(time_value * nebula_pulse_speed + broad * TAU) * nebula_pulse_amount;

	return clamp(mask * pulse * (1.0 - voids * nebula_shadow_strength * 0.6), 0.0, 1.0);
}

vec3 apply_saturation(vec3 color, float saturation) {
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(gray), color, saturation);
}

void fragment() {
	vec2 viewport_safe = max(viewport_size, vec2(1.0));
	vec2 screen_offset = (UV - vec2(0.5)) * viewport_safe / max(camera_zoom, 0.001);
	vec2 screen_uv = UV - vec2(0.5);
	vec3 color = background_color.rgb;

	float time_value = nebula_time * nebula_animation_enabled * nebula_animation_speed;
	vec2 nebula_uv = screen_offset / max(viewport_safe.y, 1.0);
	nebula_uv.x *= viewport_safe.x / max(viewport_safe.y, 1.0);

	float nebula_mask = nebula_field(nebula_uv + camera_position * nebula_scroll_scale / max(viewport_safe.y, 1.0), time_value);
	vec3 nebula_color = nebula_background_color.rgb;
	nebula_color = mix(nebula_color, nebula_dark_color.rgb, 0.35);
	nebula_color = mix(nebula_color, nebula_primary_color.rgb, nebula_mask);
	nebula_color = mix(nebula_color, nebula_secondary_color.rgb, smoothstep(0.18, 0.95, nebula_mask));
	nebula_color += nebula_accent_color.rgb * smoothstep(0.5, 0.95, nebula_mask) * nebula_glow_strength;
	nebula_color += nebula_halo_color.rgb * smoothstep(0.72, 1.0, nebula_mask) * nebula_halo_strength;
	nebula_color *= nebula_brightness;
	nebula_color = apply_saturation(nebula_color, nebula_saturation);
	nebula_color = mix(color, nebula_color, clamp(nebula_enabled * nebula_mask * nebula_opacity, 0.0, 1.0));

	float vignette = 1.0 - smoothstep(0.18, 0.95, length(screen_uv * vec2(viewport_safe.x / max(viewport_safe.y, 1.0), 1.0)));
	color = mix(color, nebula_color, nebula_enabled);
	color *= mix(1.0, vignette, nebula_vignette_strength * nebula_enabled);

	float far_stars = star_layer(
		screen_offset,
		effective_scroll_scale(far_scroll_scale),
		far_cell_size,
		far_min_size,
		far_max_size,
		far_zoom_size_influence,
		11.0
	);
	float mid_stars = star_layer(
		screen_offset,
		effective_scroll_scale(mid_scroll_scale),
		mid_cell_size,
		mid_min_size,
		mid_max_size,
		mid_zoom_size_influence,
		29.0
	);
	float near_stars = star_layer(
		screen_offset,
		near_scroll_scale,
		near_cell_size,
		near_min_size,
		near_max_size,
		near_zoom_size_influence,
		47.0
	);

	color.rgb += far_color.rgb * far_color.a * far_stars * far_enabled;
	color.rgb += mid_color.rgb * mid_color.a * mid_stars * mid_enabled;
	color.rgb += near_color.rgb * near_color.a * near_stars * near_enabled;
	COLOR = vec4(color.rgb, 1.0);
}
