// CRT post-process — phosphor bloom, scanlines, barrel distortion,
// chromatic aberration, vignette. Stacked on top of the game on a CanvasLayer
// and toggled with the T key. The look is the original 1979 Asteroids
// vector-display CRT, not a generic scanline filter.

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float curvature : hint_range(0.0, 0.5) = 0.16;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.7;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.0018;
uniform vec2 resolution = vec2(1280.0, 720.0);

vec2 curve_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 off = abs(uv.yx) / vec2(6.0, 4.5) * curvature;
	uv = uv + uv * off * off;
	return uv * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.02, 0.02, 0.03, 1.0);
	} else {
		float r = texture(screen_texture, uv + vec2(chromatic_aberration, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(chromatic_aberration, 0.0)).b;
		vec3 col = vec3(r, g, b);

		vec2 ts = 1.0 / resolution;
		vec3 bloom = vec3(0.0);
		bloom += texture(screen_texture, uv + vec2( ts.x * 2.0, 0.0)).rgb;
		bloom += texture(screen_texture, uv + vec2(-ts.x * 2.0, 0.0)).rgb;
		bloom += texture(screen_texture, uv + vec2(0.0,  ts.y * 2.0)).rgb;
		bloom += texture(screen_texture, uv + vec2(0.0, -ts.y * 2.0)).rgb;
		bloom += texture(screen_texture, uv + ts * 3.0).rgb;
		bloom += texture(screen_texture, uv - ts * 3.0).rgb;
		col += bloom * glow_strength * 0.06;

		float scan = sin(uv.y * resolution.y * 1.5) * 0.5 + 0.5;
		col *= 1.0 - scanline_intensity * (1.0 - scan) * 0.6;

		vec2 vuv = SCREEN_UV * (1.0 - SCREEN_UV);
		float vig = clamp(vuv.x * vuv.y * 16.0, 0.0, 1.0);
		col *= mix(1.0, pow(vig, 0.35), vignette_strength);

		COLOR = vec4(col, 1.0);
	}
}
