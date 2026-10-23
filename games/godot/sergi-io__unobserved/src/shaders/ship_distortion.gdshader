shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float thrust_strength : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.018;
uniform float jitter_frequency : hint_range(0.0, 40.0) = 15.0;
uniform float shimmer_frequency : hint_range(0.0, 40.0) = 7.5;
uniform float engine_focus : hint_range(0.0, 1.0) = 0.58;
uniform float pickup_flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 pickup_flash_color : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform float pickup_flash_hotness : hint_range(0.5, 4.0) = 1.9;
uniform float pickup_flash_glow : hint_range(0.0, 2.0) = 0.52;
uniform float damage_flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 damage_flash_color : source_color = vec4(1.0, 0.25, 0.2, 1.0);
uniform float damage_flash_hotness : hint_range(0.5, 4.0) = 1.8;
uniform float damage_flash_glow : hint_range(0.0, 2.0) = 0.64;
uniform float vortex_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 vortex_direction = vec2(0.0, -1.0);
uniform vec4 holo_edge_color : source_color = vec4(0.13, 0.92, 1.0, 1.0);
uniform float holo_edge_strength : hint_range(0.0, 2.0) = 0.78;
uniform float holo_inner_line_strength : hint_range(0.0, 2.0) = 0.34;
uniform float holo_outer_alpha : hint_range(0.0, 1.0) = 0.34;
uniform float holo_edge_width : hint_range(0.5, 4.0) = 1.45;
uniform float holo_scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float holo_glow_strength : hint_range(0.0, 4.0) = 1.35;
uniform float holo_effect_strength : hint_range(0.0, 1.0) = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float global_fade : hint_range(0.0, 1.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 warp_uv(vec2 uv) {
	float engine_mask = smoothstep(engine_focus, 1.0, uv.y);
	float scanline = uv.y * 26.0 + time * jitter_frequency;
	float wobble_a = sin(scanline + uv.x * 4.0 + hash(vec2(floor(uv.y * 64.0), floor(time * 8.0))) * 6.2831853);
	float wobble_b = sin(scanline * 1.71 + uv.x * 11.0 + time * shimmer_frequency);
	float wobble_c = cos(scanline * 0.73 + uv.y * 13.0 + time * 4.0);
	vec2 distortion = vec2(wobble_a * 0.6 + wobble_b * 0.25, wobble_b * 0.35 + wobble_c * 0.2);
	distortion *= distortion_strength * thrust_strength * engine_mask;
	distortion.x += (uv.x - 0.5) * thrust_strength * distortion_strength * 0.7 * engine_mask;
	distortion.y -= (1.0 - uv.y) * thrust_strength * distortion_strength * 0.4;
	return clamp(uv + distortion, vec2(0.0), vec2(1.0));
}

vec2 apply_vortex_warp(vec2 uv) {
	float strength = smoothstep(0.0, 1.0, vortex_strength);
	if (strength <= 0.0) {
		return uv;
	}

	vec2 direction = normalize(vortex_direction + vec2(0.0001, 0.0001));
	vec2 side_axis = vec2(-direction.y, direction.x);
	vec2 centered = uv - vec2(0.5);
	float toward = dot(centered, direction);
	float side = dot(centered, side_axis);
	float front_mask = smoothstep(-0.5, 0.55, toward);
	float body_mask = 1.0 - smoothstep(0.42, 0.78, length(centered));
	float time_ripple = sin(toward * 26.0 - time * 7.0 + sin(side * 18.0 + time * 2.5) * 0.9);
	float pull = strength * body_mask * (0.035 + front_mask * 0.105) * (0.76 + time_ripple * 0.24);
	float local_twist = strength * body_mask * (0.08 + front_mask * 0.18) * sin(time * 1.8 + length(centered) * 9.0);
	float twist_sine = sin(local_twist);
	float twist_cosine = cos(local_twist);
	vec2 twisted = vec2(
		centered.x * twist_cosine - centered.y * twist_sine,
		centered.x * twist_sine + centered.y * twist_cosine
	);

	toward = dot(twisted, direction) - pull;
	side = dot(twisted, side_axis);
	toward *= 1.0 + strength * (0.08 + front_mask * 0.16);
	side *= 1.0 - strength * (0.07 + front_mask * 0.14);
	side += sin(toward * 30.0 + time * 5.5) * strength * body_mask * 0.014;

	vec2 warped_uv = vec2(0.5) + direction * toward + side_axis * side;
	return clamp(warped_uv, vec2(0.01), vec2(0.99));
}

vec3 apply_flash(vec3 base_rgb, vec2 uv, float flash_strength, vec4 flash_color, float flash_hotness, float flash_glow) {
	float strength = smoothstep(0.0, 1.0, flash_strength);
	if (strength <= 0.0) {
		return base_rgb;
	}

	float tex_luma = dot(base_rgb, vec3(0.2126, 0.7152, 0.0722));
	float flash_mask = mix(0.45, 1.0, pow(clamp(tex_luma, 0.0, 1.0), flash_hotness));
	float core_mask = smoothstep(0.0, 0.85, 1.0 - abs(uv.x - 0.5) * 1.75) * smoothstep(0.0, 0.88, 1.0 - abs(uv.y - 0.5) * 1.55);
	float flash_mix = strength * flash_mask;
	vec3 flashed_rgb = mix(base_rgb, flash_color.rgb, flash_mix * 0.72);
	flashed_rgb += flash_color.rgb * flash_mix * flash_glow;
	flashed_rgb += vec3(1.0) * flash_mix * core_mask * 0.18;
	return flashed_rgb;
}

float texture_luma(vec3 rgb) {
	return dot(rgb, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 warped_uv = apply_vortex_warp(warp_uv(UV));
	vec4 tex = texture(TEXTURE, warped_uv);
	vec4 original_tex = texture(TEXTURE, UV);
	float engine_mask = smoothstep(engine_focus, 1.0, UV.y);
	float pulse = smoothstep(0.15, 0.9, thrust_strength) * engine_mask;
	tex.rgb += vec3(0.05, 0.14, 0.20) * pulse;
	tex.rgb += vec3(0.03, 0.05, 0.06) * pulse * sin(time * 18.0 + UV.y * 40.0);
	tex.rgb = apply_flash(tex.rgb, UV, pickup_flash_strength, pickup_flash_color, pickup_flash_hotness, pickup_flash_glow);
	tex.rgb = apply_flash(tex.rgb, UV, damage_flash_strength, damage_flash_color, damage_flash_hotness, damage_flash_glow);

	float vortex = smoothstep(0.0, 1.0, vortex_strength);
	if (vortex > 0.0) {
		vec2 direction = normalize(vortex_direction + vec2(0.0001, 0.0001));
		vec2 centered = UV - vec2(0.5);
		float toward = dot(centered, direction);
		float body_mask = 1.0 - smoothstep(0.34, 0.82, length(centered));
		float front_mask = smoothstep(-0.48, 0.58, toward);
		float temporal_wave = sin(toward * 32.0 - time * 8.0 + hash(floor(UV * 18.0)) * 2.4);
		float shimmer = temporal_wave * vortex * body_mask * (0.04 + front_mask * 0.05);
		tex.rgb = mix(original_tex.rgb, tex.rgb, 0.82);
		tex.rgb += original_tex.rgb * shimmer;
		tex.rgb += vec3(0.025, 0.045, 0.07) * vortex * body_mask * front_mask;
		tex.a = original_tex.a;
	}

	vec2 holo_pixel = TEXTURE_PIXEL_SIZE * holo_edge_width;
	vec4 center_sample = texture(TEXTURE, UV);
	float center_alpha = center_sample.a;
	float neighbor_alpha = 0.0;
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV + vec2(holo_pixel.x, 0.0), vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV - vec2(holo_pixel.x, 0.0), vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV + vec2(0.0, holo_pixel.y), vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV - vec2(0.0, holo_pixel.y), vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV + holo_pixel, vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV - holo_pixel, vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV + vec2(holo_pixel.x, -holo_pixel.y), vec2(0.0), vec2(1.0))).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, clamp(UV + vec2(-holo_pixel.x, holo_pixel.y), vec2(0.0), vec2(1.0))).a);

	vec2 line_pixel = TEXTURE_PIXEL_SIZE * max(holo_edge_width * 1.4, 1.0);
	float center_luma = texture_luma(center_sample.rgb) * center_alpha;
	float luma_delta = 0.0;
	vec4 line_sample = texture(TEXTURE, clamp(UV + vec2(line_pixel.x, 0.0), vec2(0.0), vec2(1.0)));
	luma_delta = max(luma_delta, abs(center_luma - texture_luma(line_sample.rgb) * line_sample.a));
	line_sample = texture(TEXTURE, clamp(UV - vec2(line_pixel.x, 0.0), vec2(0.0), vec2(1.0)));
	luma_delta = max(luma_delta, abs(center_luma - texture_luma(line_sample.rgb) * line_sample.a));
	line_sample = texture(TEXTURE, clamp(UV + vec2(0.0, line_pixel.y), vec2(0.0), vec2(1.0)));
	luma_delta = max(luma_delta, abs(center_luma - texture_luma(line_sample.rgb) * line_sample.a));
	line_sample = texture(TEXTURE, clamp(UV - vec2(0.0, line_pixel.y), vec2(0.0), vec2(1.0)));
	luma_delta = max(luma_delta, abs(center_luma - texture_luma(line_sample.rgb) * line_sample.a));

	float alpha_edge = smoothstep(0.02, 0.85, abs(neighbor_alpha - center_alpha));
	float inner_edge = smoothstep(0.08, 0.38, luma_delta) * smoothstep(0.05, 0.35, center_alpha);
	float outer_edge = alpha_edge * (1.0 - smoothstep(0.02, 0.5, center_alpha));
	float rim_edge = alpha_edge * smoothstep(0.03, 0.5, center_alpha);
	float scanline = sin(UV.y * 170.0 + time * 3.6) * 0.5 + 0.5;
	float holo_activation = smoothstep(0.0, 1.0, holo_effect_strength);
	float shimmer = 1.0 + holo_scanline_strength * holo_activation * (scanline - 0.5);
	float edge_amount = clamp((rim_edge * holo_edge_strength + inner_edge * holo_inner_line_strength) * shimmer * holo_activation, 0.0, 2.0);
	vec3 holo = holo_edge_color.rgb;
	float glow_amount = edge_amount * holo_glow_strength;

	tex.rgb = mix(tex.rgb, holo, clamp(edge_amount * 0.55, 0.0, 0.82));
	tex.rgb += holo * glow_amount * 0.62;
	tex.rgb += holo * outer_edge * holo_activation * holo_glow_strength * 0.34;
	tex.a = max(tex.a, outer_edge * holo_outer_alpha * holo_edge_color.a * shimmer * holo_activation * (1.0 + holo_glow_strength * 0.18));
	tex.a *= alpha * global_fade;
	COLOR = tex;
}
