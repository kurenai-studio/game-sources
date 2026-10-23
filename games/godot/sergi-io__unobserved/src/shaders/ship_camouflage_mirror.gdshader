shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float time = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.38;
uniform float global_fade : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(0.16, 0.72, 1.0, 1.0);
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.018;
uniform float wave_frequency : hint_range(1.0, 24.0) = 7.0;
uniform float wave_speed : hint_range(0.0, 12.0) = 1.7;
uniform float mirror_mix : hint_range(0.0, 1.0) = 0.72;
uniform float edge_strength : hint_range(0.0, 2.0) = 1.25;
uniform float edge_sample_offset : hint_range(0.001, 0.05) = 0.012;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.38;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.73, 289.19))) * 29137.473);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	float mask = texture(TEXTURE, UV).a;
	vec2 centered_uv = UV * 2.0 - 1.0;
	float body_focus = 1.0 - clamp(length(centered_uv * vec2(0.76, 0.94)), 0.0, 1.0);
	body_focus = smoothstep(0.0, 0.92, body_focus);

	float wave_time = time * wave_speed;
	float wave_a = sin((UV.y * wave_frequency + UV.x * 2.15 + wave_time) * 6.2831853);
	float wave_b = cos((UV.x * wave_frequency * 0.84 - UV.y * 1.65 - wave_time * 1.21) * 6.2831853);
	float wave_c = noise(UV * wave_frequency * 2.35 + vec2(wave_time * 0.42, -wave_time * 0.31)) * 2.0 - 1.0;
	vec2 refract_vector = vec2(wave_b + wave_c * 0.42, wave_a - wave_c * 0.36);
	refract_vector *= refraction_strength * (0.36 + body_focus * 0.64);

	vec3 refracted_screen = texture(screen_texture, clamp(SCREEN_UV + refract_vector, vec2(0.0), vec2(1.0))).rgb;
	vec3 counter_screen = texture(screen_texture, clamp(SCREEN_UV - refract_vector * 0.72, vec2(0.0), vec2(1.0))).rgb;
	vec3 mirror_color = mix(refracted_screen, counter_screen.bgr, mirror_mix * 0.45);

	vec2 pixel = vec2(edge_sample_offset);
	float left_alpha = texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a;
	float right_alpha = texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a;
	float up_alpha = texture(TEXTURE, UV - vec2(0.0, pixel.y)).a;
	float down_alpha = texture(TEXTURE, UV + vec2(0.0, pixel.y)).a;
	float raw_edge = max(max(abs(mask - left_alpha), abs(mask - right_alpha)), max(abs(mask - up_alpha), abs(mask - down_alpha)));
	float edge = smoothstep(0.02, 0.45, raw_edge);
	float shimmer = smoothstep(0.18, 1.0, abs(wave_a * 0.55 + wave_b * 0.35 + wave_c * 0.10));
	vec3 tint = tint_color.rgb * (0.16 + shimmer * shimmer_strength * 0.34 + edge * edge_strength * 0.36);
	vec3 final_rgb = mix(mirror_color, mirror_color + tint, 0.42);

	float visible_alpha = alpha * global_fade * mask;
	visible_alpha *= 0.62 + body_focus * 0.18 + shimmer * 0.10 + edge * edge_strength * 0.18;
	COLOR = vec4(final_rgb, clamp(visible_alpha, 0.0, 1.0));
}
