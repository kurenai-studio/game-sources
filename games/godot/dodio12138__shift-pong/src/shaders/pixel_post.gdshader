// Applied to the upscaled low-res frame.
// mode 0: off   1: snap every pixel to a fixed flat palette   2: posterize + Bayer dither
shader_type canvas_item;

uniform int mode = 1;
uniform vec2 source_size = vec2(320.0, 180.0);
uniform float color_levels = 7.0;
uniform float dither_strength = 0.6;

const int PALETTE_SIZE = 16;
const vec3 PALETTE[16] = vec3[16](
	vec3(0.050, 0.110, 0.290),   // deep navy-blue (table body)
	vec3(0.360, 0.070, 0.085),   // court shadow
	vec3(0.560, 0.120, 0.130),   // court red
	vec3(0.660, 0.190, 0.180),   // court light
	vec3(0.070, 0.230, 0.500),   // table shadow
	vec3(0.100, 0.330, 0.660),   // table: DHS blue
	vec3(0.220, 0.460, 0.780),   // table light
	vec3(0.960, 0.960, 0.940),   // white
	vec3(0.720, 0.780, 0.860),   // pale
	vec3(0.980, 0.800, 0.250),   // yellow (left side spin)
	vec3(0.980, 0.520, 0.150),   // orange (topspin)
	vec3(0.900, 0.080, 0.120),   // DHS red
	vec3(0.070, 0.090, 0.200),   // navy (venue floor, barriers)
	vec3(0.040, 0.050, 0.100),   // ink
	vec3(0.420, 0.820, 0.980),   // sky (backspin)
	vec3(0.780, 0.480, 0.950));  // violet (right side spin)  // violet (right side spin)

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (mode == 1) {
		vec3 best = PALETTE[0];
		float best_d = 1e9;
		for (int i = 0; i < PALETTE_SIZE; i++) {
			vec3 diff = c.rgb - PALETTE[i];
			float d = dot(diff, diff);
			if (d < best_d) {
				best_d = d;
				best = PALETTE[i];
			}
		}
		c.rgb = best;
	} else if (mode == 2) {
		vec2 px = floor(UV * source_size);
		int ix = int(mod(px.x, 4.0));
		int iy = int(mod(px.y, 4.0));
		float threshold = BAYER[iy * 4 + ix] / 16.0 - 0.5;
		vec3 col = c.rgb + threshold * dither_strength / color_levels;
		c.rgb = floor(clamp(col, 0.0, 1.0) * color_levels + 0.5) / color_levels;
	}
	COLOR = c;
}
