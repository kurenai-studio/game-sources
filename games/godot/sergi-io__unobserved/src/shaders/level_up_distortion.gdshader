shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.12) = 0.062;
uniform float ripple_width : hint_range(0.02, 0.5) = 0.18;
uniform vec4 flash_color : source_color = vec4(0.8, 0.35, 1.0, 1.0);

void fragment() {
	float fade_in = smoothstep(0.0, 0.16, progress);
	float fade_out = 1.0 - smoothstep(0.72, 1.0, progress);
	float intensity = fade_in * fade_out;

	vec2 center = UV - vec2(0.5);
	float radius = length(center);
	float wave_center = mix(0.08, 0.72, progress);
	float wave = smoothstep(ripple_width, 0.0, abs(radius - wave_center));
	float core_flash = smoothstep(0.34, 0.08, abs(progress - 0.34));
	float scan = sin((UV.y - progress * 2.4) * 108.0) * 0.62 + sin((UV.x + progress * 1.8) * 58.0) * 0.38;
	float tear = sin((UV.y * 19.0) + progress * 42.0) * smoothstep(0.58, 0.0, abs(center.y));
	vec2 direction = normalize(center + vec2(0.0001));
	vec2 warp = direction * wave * intensity * strength;
	warp.x += scan * wave * intensity * strength * 0.72;
	warp.x += tear * wave * intensity * strength * 0.42;
	warp.y += sin((UV.x - progress) * 64.0) * wave * intensity * strength * 0.18;

	vec4 distorted = texture(screen_texture, SCREEN_UV + warp);
	float chroma = wave * intensity * 0.006;
	float red = texture(screen_texture, SCREEN_UV + warp + vec2(chroma, 0.0)).r;
	float blue = texture(screen_texture, SCREEN_UV + warp - vec2(chroma, 0.0)).b;
	distorted.r = red;
	distorted.b = blue;

	vec3 flash = flash_color.rgb * wave * intensity * 0.52;
	flash += vec3(1.0, 0.9, 1.0) * core_flash * wave * 0.42;
	COLOR = vec4(distorted.rgb + flash, clamp(wave * intensity * 1.15 + core_flash * wave * 0.35, 0.0, 1.0));
}
