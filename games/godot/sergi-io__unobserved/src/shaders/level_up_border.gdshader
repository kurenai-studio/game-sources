shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 panel_size = vec2(960.0, 170.0);
uniform float border_margin : hint_range(0.0, 80.0) = 28.0;
uniform float corner_radius : hint_range(0.0, 80.0) = 26.0;
uniform float border_thickness : hint_range(1.0, 12.0) = 3.0;
uniform float glow_size : hint_range(2.0, 80.0) = 30.0;
uniform float electric_speed : hint_range(0.0, 4.0) = 0.72;
uniform float sparkle_density : hint_range(0.0, 1.0) = 0.36;
uniform vec4 core_color : source_color = vec4(0.98, 0.72, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.64, 0.12, 1.0, 1.0);
uniform vec4 spark_color : source_color = vec4(0.92, 0.45, 1.0, 1.0);

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

float rounded_box_sdf(vec2 point, vec2 half_size, float radius) {
	vec2 q = abs(point) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

float perimeter_position(vec2 point, vec2 half_size) {
	vec2 normalized = abs(point) / max(half_size, vec2(1.0));
	float top_bottom = step(normalized.x, normalized.y);
	float p = 0.0;

	if (top_bottom > 0.5) {
		p = (point.x + half_size.x) / max(half_size.x * 2.0, 1.0);
		if (point.y > 0.0) {
			p = 0.5 - p * 0.25;
		} else {
			p = 0.5 + p * 0.25;
		}
	} else {
		p = (point.y + half_size.y) / max(half_size.y * 2.0, 1.0);
		if (point.x > 0.0) {
			p = 0.25 + p * 0.25;
		} else {
			p = 1.0 - p * 0.25;
		}
	}

	return fract(p);
}

float circular_pulse(float position, float center, float width) {
	float distance_to_center = abs(fract(position - center + 0.5) - 0.5);
	return smoothstep(width, 0.0, distance_to_center);
}

float corner_proximity(vec2 point, vec2 half_size, float radius) {
	vec2 corner_start = max(half_size - vec2(radius + 28.0), vec2(0.0));
	vec2 corner_full = max(half_size - vec2(radius * 0.72), corner_start + vec2(1.0));
	vec2 corner_mask = smoothstep(corner_start, corner_full, abs(point));
	return clamp(corner_mask.x * corner_mask.y, 0.0, 1.0);
}

float sparkle_field(vec2 pixel, float edge_distance, float time_value) {
	float band = smoothstep(54.0, 0.0, abs(edge_distance) - 4.0);
	vec2 cell = floor(pixel / 30.0);
	vec2 cell_uv = fract(pixel / 30.0);
	vec2 star_position = hash22(cell) * 0.86 + vec2(0.07);
	float seed = hash12(cell + 19.7);
	float star_gate = step(1.0 - sparkle_density, seed);
	float distance_to_star = length((cell_uv - star_position) * vec2(1.0, 1.55));
	float core = smoothstep(0.075, 0.0, distance_to_star);
	float cross = smoothstep(0.032, 0.0, abs(cell_uv.x - star_position.x)) * smoothstep(0.25, 0.0, abs(cell_uv.y - star_position.y));
	cross += smoothstep(0.032, 0.0, abs(cell_uv.y - star_position.y)) * smoothstep(0.25, 0.0, abs(cell_uv.x - star_position.x));
	float twinkle = 0.45 + 0.55 * sin(time_value * (2.2 + seed * 4.0) + seed * 37.0);
	return (core + cross * 0.6) * star_gate * band * twinkle;
}

void fragment() {
	vec2 size = max(panel_size, vec2(1.0));
	vec2 pixel = UV * size;
	vec2 rect_min = vec2(border_margin);
	vec2 rect_max = size - vec2(border_margin);
	vec2 center = (rect_min + rect_max) * 0.5;
	vec2 half_size = max((rect_max - rect_min) * 0.5, vec2(1.0));
	vec2 local = pixel - center;
	float dist = rounded_box_sdf(local, half_size, corner_radius);
	float edge_position = perimeter_position(local, half_size);
	float time_value = TIME * electric_speed;
	float corner = corner_proximity(local, half_size, corner_radius);
	float corner_quiet = 1.0 - smoothstep(0.05, 0.72, corner);

	float edge_noise = value_noise(vec2(edge_position * 54.0 - time_value * 6.0, time_value * 1.35));
	float edge_offset = (edge_noise - 0.5) * mix(2.6, 0.65, corner);
	float jagged_edge = smoothstep(0.42, 0.95, edge_noise) * smoothstep(8.0, 0.0, abs(dist)) * mix(1.0, 0.22, corner);
	float border = smoothstep(border_thickness + 1.4, border_thickness - 0.8, abs(dist));
	float fine_core = smoothstep(1.35, 0.0, abs(dist + edge_offset)) * mix(1.0, 0.48, corner);
	float outer_glow = exp(-max(dist, 0.0) / max(glow_size, 0.001)) * smoothstep(48.0, 0.0, abs(dist));
	float inner_glow = exp(-abs(min(dist, 0.0)) / 16.0) * smoothstep(22.0, 0.0, abs(dist));

	float sweep_a = circular_pulse(edge_position, fract(time_value * 0.18), 0.022);
	float sweep_b = circular_pulse(edge_position, fract(time_value * 0.18 + 0.47), 0.016);
	float flare_band = smoothstep(border_thickness * 1.35, border_thickness * 0.12, abs(dist));
	float flare_corner_fade = pow(corner_quiet, 1.8);
	float flare = (sweep_a + sweep_b * 0.8) * flare_band * flare_corner_fade;
	float sparkles = sparkle_field(pixel + vec2(time_value * 16.0, -time_value * 9.0), dist, TIME);

	vec3 color = glow_color.rgb * outer_glow * 0.86;
	color += glow_color.rgb * inner_glow * 0.3;
	color += mix(glow_color.rgb, core_color.rgb, 0.8) * border;
	color += core_color.rgb * fine_core * 1.35;
	color += core_color.rgb * jagged_edge * 0.75;
	color += vec3(1.0, 0.92, 1.0) * flare * 1.8;
	color += spark_color.rgb * sparkles * 1.7;

	float alpha = outer_glow * 0.46 + inner_glow * 0.22 + border * 0.92 + fine_core * 0.8 + jagged_edge * 0.46 + flare * 0.72 + sparkles * 0.9;
	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
