shader_type canvas_item;

varying vec4 custom_modulate; 
void vertex() { 
	custom_modulate = COLOR; 
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 me = texture(TEXTURE, UV);
	float neighbors = max(me.a, max(max(max(
		texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(0,1)).a,
		texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(0,-1)).a
	),
	texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(1,0)).a),
	texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE *  vec2(-1,0)).a));
	COLOR = (me*me.a + vec4(0, 0, 0, neighbors)) * custom_modulate;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
