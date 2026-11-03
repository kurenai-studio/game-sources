shader_type canvas_item;
// Full-screen overlay: vignette, damage-flash tint, subtle scanlines.
uniform vec4 flash_color : source_color = vec4(1.0, 0.2, 0.3, 1.0);
uniform float flash_amount = 0.0;
uniform float low_health = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = length(uv - 0.5);
	float vig = smoothstep(0.45, 0.85, d);
	float scan = 0.03 * sin(uv.y * 900.0);
	float pulse = low_health * (0.55 + 0.45 * sin(TIME * 6.0));
	float a = vig * 0.55 + scan * 0.3 + flash_amount * (0.25 + vig) + pulse * vig * 0.8;
	vec3 col = mix(vec3(0.0), flash_color.rgb, clamp(flash_amount + pulse, 0.0, 1.0));
	COLOR = vec4(col, clamp(a, 0.0, 0.85));
}
