shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float twinkle_strength = 0.06;

void fragment() {
	vec4 instance_color = COLOR;
	vec2 p = UV * 2.0 - vec2(1.0);
	float d = length(p);
	float core = smoothstep(0.42, 0.0, d);
	float halo = smoothstep(1.0, 0.08, d) * 0.32;
	float sparkle = smoothstep(0.88, 0.0, abs(p.x)) * smoothstep(0.18, 0.0, abs(p.y)) * 0.12;
	sparkle += smoothstep(0.88, 0.0, abs(p.y)) * smoothstep(0.18, 0.0, abs(p.x)) * 0.12;
	float twinkle = 1.0 + sin(TIME * 0.8 + instance_color.r * 41.0 + instance_color.g * 17.0) * twinkle_strength;
	float intensity = clamp((core + halo + sparkle) * twinkle, 0.0, 1.4);
	COLOR = vec4(instance_color.rgb * intensity, instance_color.a * intensity);
}
