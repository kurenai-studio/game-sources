shader_type canvas_item;
render_mode unshaded;

uniform float slice_min = 0.0;
uniform float slice_max = 1.0;
uniform float slice_softness = 0.06;
uniform float left_edge_jaggedness = 0.04;
uniform float right_edge_jaggedness = 0.04;
uniform float jagged_frequency = 18.0;
uniform float left_edge_seed = 0.0;
uniform float right_edge_seed = 0.0;
uniform float slice_is_horizontal = 0.0;
uniform float fade = 1.0;
uniform float global_fade = 1.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

float value_noise(float x) {
	float i = floor(x);
	float f = fract(x);
	float a = hash1(i);
	float b = hash1(i + 1.0);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u);
}

float jagged_profile(float y, float seed) {
	float freq = max(jagged_frequency, 0.0001);
	float sample = y * freq;
	float coarse = value_noise(sample + seed * 0.173);
	float fine = value_noise(sample * 2.37 + seed * 1.719);
	float stepped = hash1(floor(sample * 1.83 + seed * 11.37) + seed * 3.11);
	float profile = mix(coarse, fine, 0.55);
	profile = mix(profile, stepped, 0.28);
	return profile * 2.0 - 1.0;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float softness = max(slice_softness, 0.0001);
	float horizontal = clamp(slice_is_horizontal, 0.0, 1.0);
	float slice_coord = mix(UV.x, UV.y, horizontal);
	float profile_coord = mix(UV.y, UV.x, horizontal);
	float left_offset = jagged_profile(profile_coord, left_edge_seed) * left_edge_jaggedness;
	float right_offset = jagged_profile(profile_coord, right_edge_seed) * right_edge_jaggedness;
	float left_edge = clamp(slice_min + left_offset, 0.0, 1.0);
	float right_edge = clamp(slice_max + right_offset, 0.0, 1.0);
	right_edge = clamp(max(right_edge, left_edge + softness * 1.5), 0.0, 1.0);
	left_edge = clamp(min(left_edge, right_edge - softness * 1.5), 0.0, 1.0);
	float left_mask = smoothstep(left_edge, left_edge + softness, slice_coord);
	float right_mask = 1.0 - smoothstep(right_edge - softness, right_edge, slice_coord);
	float mask = clamp(left_mask * right_mask, 0.0, 1.0);
	float alpha = tex.a * mask * fade * global_fade * tint.a;
	vec3 color = tex.rgb * tint.rgb;
	COLOR = vec4(color, alpha);
}
