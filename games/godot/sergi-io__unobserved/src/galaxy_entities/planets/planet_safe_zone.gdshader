shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 barrier_color : source_color = vec4(0.18, 1.0, 0.36, 0.12);
uniform float ring_softness : hint_range(0.0, 0.5) = 0.12;
uniform float sweep_speed : hint_range(0.0, 4.0) = 0.28;
uniform float sweep_width : hint_range(0.01, 0.5) = 0.08;
uniform float pulse_speed : hint_range(0.0, 4.0) = 0.42;
uniform float pulse_width : hint_range(0.01, 0.5) = 0.08;
uniform float glow_strength : hint_range(0.0, 0.5) = 0.08;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.02;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered) * 2.0;
	float circle_mask = 1.0 - smoothstep(1.0 - ring_softness, 1.0, dist);

	float angle = atan(centered.y, centered.x);
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

	float micro_noise = hash(vec2(floor(uv.x * 140.0), floor(uv.y * 140.0) + floor(TIME * 4.0)));
	micro_noise = (micro_noise - 0.5) * noise_strength;

	vec3 color = barrier_color.rgb;
	color += vec3(0.03, 0.09, 0.03) * sweep * glow_strength * 3.0;
	color += vec3(0.02, 0.07, 0.02) * pulse * glow_strength * 3.5;
	color += vec3(0.01, 0.03, 0.01) * ring_lines * glow_strength;
	color += vec3(0.02, 0.04, 0.02) * micro_noise;

	float alpha = barrier_color.a * circle_mask;
	alpha += barrier_color.a * sweep * 0.08;
	alpha += barrier_color.a * pulse * 0.06;

	COLOR = vec4(color, alpha);
}
