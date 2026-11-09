shader_type canvas_item;

uniform vec2 circle_center;
uniform float radius_squared;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 diff = VERTEX.xy - circle_center;
	if (diff.x * diff.x + diff.y * diff.y >= radius_squared) {
		COLOR.a = 0.0;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
