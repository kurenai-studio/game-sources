shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 viewport_size = vec2(1600.0, 900.0);
uniform int edge_position = 0;
uniform float radius = 760.0;
uniform vec4 planet_color : source_color = vec4(0.38, 0.68, 0.72, 1.0);
uniform vec4 atmosphere_color : source_color = vec4(0.23, 0.95, 1.0, 1.0);
uniform float brightness = 0.95;

void fragment() {
	vec2 pixel = UV * viewport_size;
	vec2 center = vec2(-radius * 0.72, viewport_size.y * 0.55);
	if (edge_position == 1) {
		center = vec2(viewport_size.x + radius * 0.72, viewport_size.y * 0.5);
	} else if (edge_position == 2) {
		center = vec2(viewport_size.x * 0.45, viewport_size.y + radius * 0.72);
	} else if (edge_position == 3) {
		center = vec2(viewport_size.x * 0.52, -radius * 0.72);
	}

	float d = distance(pixel, center);
	float body = smoothstep(radius, radius - 8.0, d);
	float atmosphere = smoothstep(radius + 74.0, radius - 12.0, d) - body * 0.24;
	vec2 normal = normalize(pixel - center);
	vec2 light_dir = normalize(vec2(0.7, -0.45));
	float light = clamp(dot(normal, light_dir) * 0.5 + 0.5, 0.0, 1.0);
	float limb = smoothstep(radius * 0.78, radius, d);
	vec3 color = planet_color.rgb * mix(0.18, 1.0, light) * brightness;
	color = mix(color, atmosphere_color.rgb * brightness, limb * 0.42);
	color += atmosphere_color.rgb * atmosphere * 0.42;
	float alpha = clamp(body + atmosphere * 0.65, 0.0, 0.92);
	COLOR = vec4(color, alpha);
}
