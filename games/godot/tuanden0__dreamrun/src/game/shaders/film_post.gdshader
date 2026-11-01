// Full-screen film grain + vignette. Put on a ColorRect inside a high CanvasLayer.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.05;
uniform float grain_fps : hint_range(1.0, 60.0) = 24.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.8;
// Distance from screen centre (0..~0.7) where the darkening reaches full strength.
uniform float vignette_radius : hint_range(0.2, 1.0) = 0.75;

// Hash without sin(): sin-based hashes show diagonal/grid patterns on large coordinates.
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float frame = floor(TIME * grain_fps);
	// Two taps average to a softer, bell-shaped grain instead of harsh uniform noise.
	float g = hash12(FRAGCOORD.xy + frame * 61.0) + hash12(FRAGCOORD.xy * 1.37 + frame * 17.0) - 1.0;
	// Grain is stronger in midtones so black silhouettes stay clean.
	float lum = dot(c, vec3(0.333));
	c += g * grain_strength * (0.4 + smoothstep(0.0, 0.4, lum));
	float d = distance(SCREEN_UV, vec2(0.5));
	c *= 1.0 - vignette_strength * smoothstep(vignette_radius * 0.4, vignette_radius, d);
	COLOR = vec4(c, 1.0);
}
