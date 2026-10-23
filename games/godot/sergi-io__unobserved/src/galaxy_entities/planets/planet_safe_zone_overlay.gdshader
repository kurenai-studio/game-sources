shader_type canvas_item;
render_mode unshaded, blend_mix;

const int MAX_SAFE_ZONES = 128;

uniform int safe_zone_count = 0;
uniform vec2 world_bounds_min = vec2(-10000.0, -10000.0);
uniform vec2 world_bounds_max = vec2(10000.0, 10000.0);
uniform vec4 safe_zone_centers[MAX_SAFE_ZONES];
uniform vec4 safe_zone_colors[MAX_SAFE_ZONES];
uniform float ring_softness : hint_range(0.0, 0.5) = 0.12;
uniform float sweep_speed : hint_range(0.0, 4.0) = 0.28;
uniform float sweep_width : hint_range(0.01, 0.5) = 0.08;
uniform float pulse_speed : hint_range(0.0, 4.0) = 0.42;
uniform float pulse_width : hint_range(0.01, 0.5) = 0.08;
uniform float glow_strength : hint_range(0.0, 0.5) = 0.08;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.02;
uniform float reveal_edge_width : hint_range(0.005, 0.2) = 0.045;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 world_position = mix(world_bounds_min, world_bounds_max, UV);

	vec4 best_color = vec4(0.0);
	float best_alpha = 0.0;

	for (int i = 0; i < MAX_SAFE_ZONES; i++) {
		if (i >= safe_zone_count) {
			break;
		}

		vec4 zone = safe_zone_centers[i];
		vec4 zone_color = safe_zone_colors[i];

		float radius = max(zone.z, 0.001);
		float reveal_progress = clamp(zone.w, 0.0, 1.0);
		vec2 offset = world_position - zone.xy;
		float dist = length(offset) / radius;

		float circle_mask = 1.0 - smoothstep(1.0 - ring_softness, 1.0, dist);
		float reveal_mask = 1.0 - smoothstep(max(reveal_progress - ring_softness, 0.0), reveal_progress, dist);
		float reveal_edge = 1.0 - smoothstep(0.0, reveal_edge_width, abs(dist - reveal_progress));
		reveal_edge *= 1.0 - smoothstep(0.96, 1.0, reveal_progress);
		circle_mask *= reveal_mask;
		float angle = atan(offset.y, offset.x);
		float angle01 = (angle + PI) / TAU;
		float sweep_pos = fract(TIME * sweep_speed);
		float sweep_delta = abs(angle01 - sweep_pos);
		sweep_delta = min(sweep_delta, 1.0 - sweep_delta);
		float sweep = 1.0 - smoothstep(0.0, sweep_width, sweep_delta);
		sweep *= 0.6 + 0.4 * (1.0 - dist);

		float pulse_pos = fract(TIME * pulse_speed);
		float pulse_delta = abs(dist - pulse_pos);
		float pulse = 1.0 - smoothstep(pulse_width, pulse_width * 2.5, pulse_delta);
		pulse *= 1.0 - smoothstep(0.82, 1.0, dist);

		float ring_lines = 0.5 + 0.5 * sin(dist * 28.0 - TIME * 1.4);
		ring_lines *= 0.5 + 0.5 * sin(dist * 9.0 + TIME * 0.7);

		float micro_noise = hash(vec2(floor(world_position.x * 140.0), floor(world_position.y * 140.0) + floor(TIME * 4.0)));
		micro_noise = (micro_noise - 0.5) * noise_strength;

		vec3 color = zone_color.rgb;
		color += vec3(0.03, 0.09, 0.03) * sweep * glow_strength * 3.0;
		color += vec3(0.02, 0.07, 0.02) * pulse * glow_strength * 3.5;
		color += vec3(0.01, 0.03, 0.01) * ring_lines * glow_strength;
		color += vec3(0.12, 0.42, 0.12) * reveal_edge;
		color += vec3(0.02, 0.04, 0.02) * micro_noise;

		float alpha = zone_color.a * circle_mask;
		alpha += zone_color.a * sweep * 0.08;
		alpha += zone_color.a * pulse * 0.06;
		alpha += zone_color.a * reveal_edge * 1.9;
		alpha = clamp(alpha, 0.0, 1.0);

		if (alpha > best_alpha) {
			best_alpha = alpha;
			best_color = vec4(color, alpha);
		}
	}

	COLOR = best_color;
}
