shader_type canvas_item;

const float DITHER_PIXEL_SIZE = 6.0;
uniform float dither_alpha;
uniform vec2 circle_center;
uniform float radius_squared;

void vertex() {
}

void fragment() {
	vec2 diff = VERTEX.xy - circle_center;
	if (diff.x * diff.x + diff.y * diff.y < radius_squared) {
		COLOR.a = 0.0;
	} else if ((int(VERTEX.x / DITHER_PIXEL_SIZE) + int(VERTEX.y / DITHER_PIXEL_SIZE)) % 2 == 1) {
		COLOR.a = dither_alpha;
	} else {
		COLOR.a = 1.0;
	}
}
