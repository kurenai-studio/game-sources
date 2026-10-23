shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 spark_color : source_color = vec4(1.0, 0.92, 0.62, 1.0);
uniform float time = 0.0;
uniform float seed = 0.0;
uniform float alpha = 1.0;
uniform float global_fade = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float radius = length(uv);
	float angle = atan(uv.y, uv.x);
	float spoke_count = 17.0;
	float spoke_phase = angle * spoke_count + seed * 2.0 + time * 8.5;
	float spoke_wave = pow(max(0.0, cos(spoke_phase)), 20.0);
	float streak = spoke_wave * smoothstep(1.0, 0.0, radius) * smoothstep(0.08, 0.0, radius) * 0.12;
	float core = smoothstep(0.32, 0.0, radius) * 0.06;
	float ember = pow(max(0.0, sin(angle * 41.0 + seed * 9.0)), 28.0) * smoothstep(1.0, 0.18, radius);
	float flicker = 0.9 + 0.1 * sin(time * 35.0 + seed * 17.0);
	float edge_mask = 1.0 - smoothstep(0.82, 1.02, radius);
	float out_alpha = (streak + core + ember * 0.22) * edge_mask * alpha * global_fade * flicker;
	if (out_alpha < 0.01) {
		discard;
	}
	COLOR = vec4(spark_color.rgb, out_alpha);
}
