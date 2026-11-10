shader_type canvas_item;

const float DITHER_PIXEL_SIZE = 6.0;
uniform float dither_alpha;

void vertex() {
}

void fragment() {
	if (COLOR.a > 0.0) {
		if ((int(VERTEX.x / DITHER_PIXEL_SIZE) + int(VERTEX.y / DITHER_PIXEL_SIZE)) % 2 == 1) {
			COLOR.a = dither_alpha;
		} else {
			COLOR.a = 0.25;
		}
	}
}
