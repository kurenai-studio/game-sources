shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 shield_color : source_color = vec4(0.08, 0.85, 1.0, 1.0);
uniform sampler2D noise_texture;
uniform float time = 0.0;
uniform float wave_height : hint_range(0.0, 2.0) = 0.2;
uniform vec2 wave_speed = vec2(0.1, 0.05);
uniform float fresnel_power : hint_range(0.5, 10.0) = 2.4;
uniform float center_visibility : hint_range(0.0, 1.0) = 0.035;
uniform vec2 hit_position = vec2(0.5, 0.5);
uniform float hit_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float hit_radius = 0.48;
uniform float hit_ring_width : hint_range(0.0, 1.0, 0.1) = 0.16;
uniform float hit_push_force = 0.5;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.9;
uniform float pulse_speed : hint_range(0.0, 20.0) = 2.2;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.06;
uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float noise_scale : hint_range(0.5, 32.0) = 8.0;
uniform float force_ring_strength : hint_range(0.0, 2.0) = 0.85;
uniform float force_ring_count : hint_range(1.0, 12.0) = 4.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	vec2 aspect = vec2(1.0, 1.0);
	vec2 radial_uv = centered * aspect;
	float dist = length(radial_uv);
	float sphere_mask = 1.0 - smoothstep(0.485, 0.505, dist);
	float perimeter_fade = 1.0 - smoothstep(0.472, 0.492, dist);

	vec2 noise_uv = fract(UV * noise_scale + time * wave_speed);
	float n = texture(noise_texture, noise_uv).r;
	float pulse = 1.0 + sin(time * pulse_speed + dist * 24.0) * pulse_amount;
	float force_phase = time * (pulse_speed * 1.35) - dist * force_ring_count * 6.2831853;
	float force_wave = pow(0.5 + 0.5 * sin(force_phase + n * 2.1), 5.0) * force_ring_strength;
	float counter_wave = pow(0.5 + 0.5 * sin(-time * 1.7 + dist * 34.0), 7.0) * 0.45;
	vec4 tex = texture(TEXTURE, UV);
	float source_luma = dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722));

	float radial = clamp(dist / 0.5, 0.0, 1.0);
	float fresnel = pow(radial, fresnel_power);
	float visibility_mask = mix(center_visibility, 1.0, fresnel);
	float outer_rim = smoothstep(0.47, 0.499, dist) * (1.0 - smoothstep(0.499, 0.505, dist));
	float hot_edge = smoothstep(0.488, 0.501, dist) * (1.0 - smoothstep(0.502, 0.505, dist));
	float inner_haze = (1.0 - smoothstep(0.0, 0.43, dist)) * center_visibility;
	float soft_shell = (outer_rim * 0.64 + inner_haze + force_wave * 0.16) * sphere_mask;

	float center_source_fade = smoothstep(0.24, 0.36, dist);
	float source_shell = smoothstep(0.08, 0.55, source_luma) * center_source_fade * sphere_mask * (1.0 - smoothstep(0.465, 0.505, dist));
	float source_detail = smoothstep(0.38, 0.86, source_luma);
	source_detail *= center_source_fade * smoothstep(0.11, 0.26, dist) * (1.0 - smoothstep(0.455, 0.505, dist));
	float energy_lines = (force_wave + counter_wave) * smoothstep(0.16, 0.32, dist) * (1.0 - smoothstep(0.46, 0.505, dist));

	vec2 hit_center = (hit_position - vec2(0.5)) * aspect;
	float impact_dist = length(radial_uv - hit_center);
	float current_radius = hit_progress * hit_radius;
	float dist_to_ring = abs(impact_dist - current_radius);
	float hit_intensity = smoothstep(hit_ring_width, 0.0, dist_to_ring);
	hit_intensity *= (1.0 - hit_progress);
	hit_intensity *= hit_push_force;

	float shimmer = (0.55 + n * 0.45) * visibility_mask * glow_strength;
	float alpha = soft_shell * base_alpha;
	alpha += source_shell * 0.035;
	alpha += source_detail * 0.13;
	alpha += energy_lines * 0.18;
	alpha += hot_edge * shimmer * 0.28;
	alpha += hit_intensity;
	alpha = clamp(alpha, 0.0, 0.86) * intensity * pulse * shield_color.a;

	vec3 color = shield_color.rgb;
	color += shield_color.rgb * (outer_rim * 1.35 + hot_edge * 0.82 + shimmer * 0.44);
	color += tex.rgb * source_shell * 0.14;
	color += vec3(0.55, 1.0, 1.0) * source_detail * 0.24;
	color += vec3(0.8, 1.0, 1.0) * energy_lines * 0.7;
	color += hit_color.rgb * hit_intensity * 4.0;

	COLOR = vec4(color * alpha * sphere_mask * perimeter_fade, alpha * sphere_mask * perimeter_fade);
}
