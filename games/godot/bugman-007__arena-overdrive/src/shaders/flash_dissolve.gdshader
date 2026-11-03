shader_type canvas_item;
// Hit flash (mix to white) and pixel-noise dissolve with a hot edge for death effects.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.75, 0.3, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec4 c = COLOR;
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	if (dissolve > 0.0) {
		float n = hash(floor(FRAGCOORD.xy / 3.0));
		if (n < dissolve) {
			discard;
		}
		if (n < dissolve + 0.15) {
			c.rgb = edge_color.rgb * 1.8;
		}
	}
	COLOR = c;
}
