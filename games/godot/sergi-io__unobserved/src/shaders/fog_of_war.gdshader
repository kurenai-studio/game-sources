shader_type canvas_item;
render_mode unshaded;

uniform sampler2D fog_mask_previous : filter_linear, repeat_disable;
uniform sampler2D fog_mask_current : filter_linear, repeat_disable;
uniform float fog_blend_progress = 1.0;
uniform vec4 outside_fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 camera_position = vec2(0.0, 0.0);
uniform vec2 camera_zoom = vec2(1.0, 1.0);
uniform vec2 viewport_size = vec2(1600.0, 900.0);
uniform vec2 world_bounds_min = vec2(-10000.0, -10000.0);
uniform vec2 world_bounds_max = vec2(10000.0, 10000.0);

void fragment() {
	vec2 world_position = camera_position + ((SCREEN_UV * viewport_size) - (viewport_size * 0.5)) / max(camera_zoom, vec2(0.001));
	bool outside_bounds = world_position.x < world_bounds_min.x || world_position.x > world_bounds_max.x || world_position.y < world_bounds_min.y || world_position.y > world_bounds_max.y;
	if (outside_bounds) {
		COLOR = outside_fog_color;
	} else {
		vec2 world_size = max(world_bounds_max - world_bounds_min, vec2(1.0));
		vec2 uv = clamp((world_position - world_bounds_min) / world_size, vec2(0.0), vec2(1.0));
		vec4 previous_fog = texture(fog_mask_previous, uv);
		vec4 current_fog = texture(fog_mask_current, uv);
		COLOR = mix(previous_fog, current_fog, clamp(fog_blend_progress, 0.0, 1.0));
	}
}
