// Drifting screen-space fog. Put on a ColorRect in a CanvasLayer (so CanvasModulate does not darken it).
shader_type canvas_item;

uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec4 fog_color : source_color = vec4(0.6, 0.62, 0.67, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.2;
uniform float noise_scale : hint_range(0.2, 6.0) = 1.6;
uniform vec2 drift_speed = vec2(0.01, 0.0);
// 0 = uniform fog, 1 = fog only near the bottom of the screen.
uniform float ground_bias : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	float n = texture(noise, UV * noise_scale + TIME * drift_speed).r;
	float n2 = texture(noise, UV * noise_scale * 2.3 - TIME * drift_speed * 1.7).r;
	float cloud = smoothstep(0.25, 0.85, n * 0.65 + n2 * 0.35);
	float height = mix(1.0, smoothstep(0.1, 1.0, UV.y), ground_bias);
	COLOR = vec4(fog_color.rgb, fog_color.a * density * cloud * height);
}
