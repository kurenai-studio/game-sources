shader_type canvas_item;
// The season's palette (docs/engine-and-art.md A6): the green in the art is shifted towards
// `leaf_color` by `strength`, and trees can go `bare` (grey-brown twigs). Colours that are not
// green are left alone, so water, wood, skin and stone keep their look. Set from SeasonLook.

uniform vec3 leaf_color : source_color = vec3(1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float bare : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = COLOR;
	float greenness = clamp((c.g - max(c.r, c.b)) * 4.0, 0.0, 1.0);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 shifted = leaf_color * (0.35 + lum * 1.3);
	vec3 twig = vec3(0.42, 0.36, 0.34) * (0.5 + lum);
	shifted = mix(shifted, twig, bare);
	float amount = max(strength, bare) * greenness;
	c.rgb = mix(c.rgb, shifted, amount);
	COLOR = c;
}
