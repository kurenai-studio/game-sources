shader_type canvas_item;
// What the camera sees, for cameras that send brightness (in red) and colour
// (in a second picture) separately: put back together as colour, or shown as
// grey when there's no colour picture.

uniform sampler2D cbcr_tex;
uniform bool has_cbcr = false;

void fragment() {
	float y = texture(TEXTURE, UV).r;
	if (has_cbcr) {
		vec2 c = texture(cbcr_tex, UV).rg - vec2(0.5);
		COLOR = vec4(y + 1.402 * c.y, y - 0.344 * c.x - 0.714 * c.y, y + 1.772 * c.x, 1.0);
	} else {
		COLOR = vec4(vec3(y), 1.0);
	}
}
