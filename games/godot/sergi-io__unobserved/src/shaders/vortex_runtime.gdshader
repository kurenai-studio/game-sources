shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float life_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float lens_strength : hint_range(0.0, 0.16) = 0.086;
uniform float swirl_strength : hint_range(-1.0, 1.0) = -0.62;
uniform float texture_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float mirror_strength : hint_range(0.0, 1.0) = 0.78;
uniform float lightning_opacity : hint_range(0.0, 2.0) = 0.92;
uniform float edge_opacity : hint_range(0.0, 1.0) = 0.72;
uniform float core_opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 tint_color : source_color = vec4(0.22, 0.82, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(0.66, 0.24, 1.0, 1.0);
uniform vec4 lightning_color : source_color = vec4(0.82, 0.95, 1.0, 1.0);

vec2 rotate_uv(vec2 value, float amount) {
	float sine = sin(amount);
	float cosine = cos(amount);
	return vec2(
		value.x * cosine - value.y * sine,
		value.x * sine + value.y * cosine
	);
}

float hash11(float value) {
	return fract(sin(value * 127.1) * 43758.5453123);
}

float noise11(float value) {
	float cell = floor(value);
	float local = fract(value);
	float curve = local * local * (3.0 - 2.0 * local);
	return mix(hash11(cell), hash11(cell + 1.0), curve);
}

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float radius = length(centered_uv);

	if (radius > 1.0) {
		discard;
	}

	float age = 1.0 - life_ratio;
	float fade_in = smoothstep(0.0, 0.01, age);
	float fade_out = smoothstep(0.0, 0.018, life_ratio);
	float fade = fade_in * fade_out;

	vec2 direction = centered_uv / max(radius, 0.001);
	vec2 tangent = vec2(-direction.y, direction.x);
	float angle = atan(centered_uv.y, centered_uv.x);

	float soft_edge = 1.0 - smoothstep(0.66, 0.98, radius);
	float active_area = smoothstep(0.045, 0.16, radius) * soft_edge;
	float center_mask = 1.0 - smoothstep(0.0, 0.19, radius);
	float lens_mask = smoothstep(0.98, 0.08, radius);
	float pull_mask = pow(1.0 - smoothstep(0.1, 0.88, radius), 1.2) * soft_edge;

	vec2 texture_uv = rotate_uv(centered_uv * 0.5, TIME * swirl_strength * 0.22) + vec2(0.5);
	vec3 texture_color = texture(TEXTURE, texture_uv).rgb;
	float texture_luma = luminance(texture_color);
	float texture_detail = smoothstep(0.14, 0.86, texture_luma);

	float spiral_phase = angle * 5.0 - log(max(radius, 0.026)) * 8.4 + TIME * swirl_strength * 5.2;
	float broad_arm = pow(0.5 + 0.5 * sin(spiral_phase + texture_detail * 2.4), 2.4);
	float sharp_arm = pow(0.5 + 0.5 * sin(spiral_phase * 1.18 + 1.7), 9.0);
	float arm_mask = (broad_arm * 0.46 + sharp_arm * 0.72) * active_area;
	arm_mask *= 0.38 + texture_detail * 0.62;

	float lightning_noise = noise11(radius * 24.0 + TIME * 9.0);
	float lightning_line = pow(0.5 + 0.5 * sin(spiral_phase * 1.42 + lightning_noise * 5.6), 24.0);
	float lightning_breakup = smoothstep(
		0.58,
		0.92,
		noise11(floor(angle * 10.0) * 3.1 + floor(radius * 20.0) * 1.7 + floor(TIME * 16.0))
	);
	float lightning_mask = lightning_line * lightning_breakup * active_area * (0.25 + sharp_arm * 0.9);

	vec2 warp = direction * pull_mask * lens_strength * (1.85 - radius);
	warp += tangent * lens_mask * swirl_strength * 0.032 * (0.28 + arm_mask * 1.3);
	warp += direction * (texture_luma - 0.5) * 0.018 * active_area;
	warp *= fade;

	vec2 chroma_offset = tangent * 0.0028 * active_area;
	vec2 mirror_warp = warp + direction * pull_mask * lens_strength * 0.52 * fade;
	vec3 mirrored_scene = vec3(
		texture(screen_texture, SCREEN_UV + mirror_warp * 1.18 + chroma_offset).r,
		texture(screen_texture, SCREEN_UV + mirror_warp).g,
		texture(screen_texture, SCREEN_UV + mirror_warp * 0.84 - chroma_offset).b
	);

	vec3 scene_color = texture(screen_texture, SCREEN_UV).rgb;
	float mirror_mix = clamp((pull_mask * 0.72 + arm_mask * 0.36 + center_mask * 0.5) * mirror_strength * fade, 0.0, 1.0);
	vec3 color = mix(scene_color, mirrored_scene, mirror_mix);

	float glass_highlight = pow(max(0.0, 1.0 - abs(radius - 0.36) * 3.8), 3.2) * soft_edge;
	vec3 energy_color = mix(tint_color.rgb, accent_color.rgb, smoothstep(0.2, 0.78, radius) + sharp_arm * 0.22);
	color += energy_color * arm_mask * edge_opacity * fade;
	color += texture_color * texture_opacity * 0.18 * arm_mask * fade;
	color += tint_color.rgb * center_mask * core_opacity * fade;
	color += tint_color.rgb * glass_highlight * 0.16 * fade;
	color += lightning_color.rgb * lightning_mask * lightning_opacity * fade;
	color += accent_color.rgb * lightning_mask * 0.22 * fade;
	color = mix(color, color * 0.48, center_mask * fade * 0.32);

	float alpha = pull_mask * 0.11;
	alpha += arm_mask * edge_opacity;
	alpha += center_mask * core_opacity;
	alpha += glass_highlight * 0.16;
	alpha += lightning_mask * lightning_opacity * 0.72;
	alpha *= soft_edge * fade * COLOR.a;
	alpha = min(alpha, 0.74);

	if (alpha < 0.01) {
		discard;
	}

	COLOR = vec4(color, alpha);
}
