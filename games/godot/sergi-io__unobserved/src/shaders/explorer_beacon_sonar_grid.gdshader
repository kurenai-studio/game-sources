shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 grid_color : source_color = vec4(0.28, 0.78, 1.0, 0.36);
uniform float ring_spacing : hint_range(0.04, 0.35, 0.005) = 0.105;
uniform float ring_width : hint_range(0.001, 0.04, 0.001) = 0.007;
uniform float radial_count : hint_range(4.0, 32.0, 1.0) = 16.0;
uniform float radial_width : hint_range(0.002, 0.06, 0.001) = 0.014;
uniform float sweep_width : hint_range(0.04, 1.4, 0.01) = 0.42;
uniform float sweep_speed : hint_range(-8.0, 8.0, 0.05) = 1.6;
uniform float pulse_speed : hint_range(-4.0, 4.0, 0.05) = 0.7;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.82;

const float SONAR_TAU = 6.28318530718;

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	float aspect = texture_size.x / max(texture_size.y, 0.001);
	vec2 position = UV - vec2(0.5);
	position.x *= aspect;

	float distance_from_center = length(position);
	float outer_radius = 0.485;
	float edge_mask = 1.0 - smoothstep(outer_radius * 0.94, outer_radius, distance_from_center);
	float inner_mask = step(distance_from_center, outer_radius);

	float moving_ring_distance = abs(fract((distance_from_center / ring_spacing) - TIME * pulse_speed) - 0.5) * ring_spacing;
	float ring_grid = 1.0 - smoothstep(ring_width, ring_width * 2.4, moving_ring_distance);

	float angle = atan(position.y, position.x);
	float radial_phase = fract((angle + 3.14159265359) / SONAR_TAU * radial_count);
	float radial_distance = min(radial_phase, 1.0 - radial_phase);
	float radial_grid = 1.0 - smoothstep(radial_width, radial_width * 2.0, radial_distance);

	float sweep_angle = mod(TIME * sweep_speed, SONAR_TAU);
	float sweep_delta = abs(mod(angle - sweep_angle + 3.14159265359, SONAR_TAU) - 3.14159265359);
	float sweep = 1.0 - smoothstep(sweep_width, sweep_width * 1.7, sweep_delta);

	float outer_ring = 1.0 - smoothstep(0.003, 0.014, abs(distance_from_center - outer_radius * 0.92));
	float center_ping = 1.0 - smoothstep(0.0, 0.04, distance_from_center);
	float grid_alpha = (
		ring_grid * 0.36
		+ radial_grid * 0.22
		+ outer_ring * 0.58
		+ sweep * 0.34
		+ center_ping * 0.18
	) * edge_mask * inner_mask * opacity;

	COLOR = vec4(grid_color.rgb, grid_color.a * clamp(grid_alpha, 0.0, 1.0));
}
