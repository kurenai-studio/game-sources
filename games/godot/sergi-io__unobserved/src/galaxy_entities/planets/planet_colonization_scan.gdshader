shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec4 grid_color : source_color = vec4(0.24, 1.0, 0.42, 1.0);
uniform float longitude_count : hint_range(4.0, 32.0) = 13.0;
uniform float latitude_count : hint_range(4.0, 32.0) = 10.0;
uniform float line_width : hint_range(0.002, 0.08) = 0.018;
uniform float reveal_softness : hint_range(0.01, 0.35) = 0.16;
uniform float edge_glow_width : hint_range(0.005, 0.18) = 0.055;
uniform float time = 0.0;

float line_from_coord(float coord, float count, float width) {
	float cell = abs(fract(coord * count + 0.5) - 0.5);
	return 1.0 - smoothstep(width, width * 2.2, cell);
}

void fragment() {
	vec2 sphere_uv = UV * 2.0 - vec2(1.0);
	float radius = length(sphere_uv);
	vec4 final_color = vec4(0.0);

	if (radius <= 1.0) {
		float sphere_z = sqrt(max(1.0 - radius * radius, 0.0));
		float longitude = atan(sphere_uv.x, sphere_z) / PI + 0.5;
		float latitude = asin(clamp(sphere_uv.y, -1.0, 1.0)) / PI + 0.5;

		float reveal_radius = clamp(progress, 0.0, 1.0);
		float reveal_inner = max(reveal_radius - reveal_softness, 0.0);
		float reveal_outer = max(reveal_radius, reveal_inner + 0.001);
		float reveal_mask = 1.0 - smoothstep(reveal_inner, reveal_outer, radius);
		float edge = 1.0 - smoothstep(0.0, edge_glow_width, abs(radius - reveal_radius));
		edge *= 1.0 - smoothstep(0.96, 1.0, reveal_radius);

		float meridians = line_from_coord(longitude + time * 0.05, longitude_count, line_width);
		float parallels = line_from_coord(latitude - time * 0.025, latitude_count, line_width * 1.2);
		float grid = max(meridians, parallels) * reveal_mask;
		float rim = smoothstep(0.62, 1.0, radius) * reveal_mask * 0.35;
		float center_hot = (1.0 - smoothstep(0.0, 0.35, radius)) * (1.0 - smoothstep(0.15, 0.45, progress));

		float lighting = 0.58 + sphere_z * 0.42;
		float final_alpha = alpha * (grid * 0.82 + edge * 0.9 + rim + center_hot * 0.5);
		vec3 color = grid_color.rgb * lighting;
		color += vec3(0.55, 1.0, 0.42) * (edge * 0.8 + center_hot * 0.55);
		final_color = vec4(color, final_alpha * grid_color.a);
	}

	COLOR = final_color;
}
