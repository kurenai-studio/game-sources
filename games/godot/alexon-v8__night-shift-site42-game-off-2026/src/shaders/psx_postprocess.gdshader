shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float color_depth : hint_range(4.0, 64.0) = 16.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.25;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform vec2 target_resolution = vec2(480.0, 360.0);

// 4x4 Bayer Dithering Matrix
const float bayer_matrix[16] = float[](
	0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
	3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
	15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

float uv_distance_from_center(vec2 uv) {
	vec2 delta = uv - vec2(0.5);
	return dot(delta, delta);
}

void fragment() {
	// Pixelation / downsampling
	vec2 pixel_coord = floor(UV * target_resolution) / target_resolution;
	vec4 base_color = texture(screen_texture, pixel_coord);
	
	// Dithering
	ivec2 screen_pos = ivec2(FRAGCOORD.xy);
	int dither_idx = (screen_pos.x % 4) + (screen_pos.y % 4) * 4;
	float dither = (bayer_matrix[dither_idx] - 0.5) * dither_strength;
	
	// Quantize colors
	vec3 quantized = floor((base_color.rgb + vec3(dither)) * color_depth) / color_depth;
	
	// Scanlines
	float scanline = sin(UV.y * target_resolution.y * PI) * 0.5 + 0.5;
	quantized -= scanline * scanline_strength * 0.1;
	
	// Vignette
	float vignette = uv_distance_from_center(UV);
	quantized *= (1.0 - vignette * 0.35);
	
	COLOR = vec4(clamp(quantized, 0.0, 1.0), base_color.a);
}
