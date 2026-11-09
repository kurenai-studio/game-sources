
shader_type canvas_item;

varying vec4 custom_modulate; 
void vertex() { 
	custom_modulate = COLOR; 
}

uniform vec4 helmet: source_color;
uniform vec4 shirt: source_color;
uniform vec4 pants: source_color;
uniform vec4 skin;
uniform vec4 nose;
uniform vec4 replace_helmet: source_color;
uniform vec4 replace_shirt: source_color;
uniform vec4 replace_pants: source_color;
uniform vec4 replace_sleeve: source_color;
uniform vec4 replace_skin;
uniform vec4 replace_nose;


const float precision = 0.1;


vec4 swap_color(vec4 color){
	vec4 original_colors[5] = vec4[5] (helmet, shirt, pants, skin, nose);
	vec4 replace_colors[5] = vec4[5] (replace_helmet, replace_shirt, replace_shirt, replace_skin, replace_nose);
	for (int i = 0; i < 5; i ++) {
		if (distance(color, original_colors[i]) <= precision) {
			return replace_colors[i];
		}
	}
	return color;
}



void fragment() {
	// Called for every pixel the material is visible on.
	vec4 me = swap_color(texture(TEXTURE, UV));
	if (distance(texture(TEXTURE, UV), shirt) <= precision) {
		//if (distance(texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(0, 6)), skin) <= precision) me = replace_sleeve;
		//if (distance(texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(0, -6)), skin) <= precision) me = replace_sleeve;
		//if (distance(texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(6,0)), skin) <= precision) me = replace_sleeve;
		//if (distance(texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(-6,0)), skin) <= precision) me = replace_sleeve;
		if (UV.y > 0.64) me = replace_pants;
		if (UV.y < 0.54) me = replace_sleeve;
	}
	float neighbors = max(me.a, max(max(max(
		texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(0,1)).a,
		texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(0,-1)).a
	),
	texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE * vec2(1,0)).a),
	texture(TEXTURE, UV + TEXTURE_PIXEL_SIZE *  vec2(-1,0)).a));
	COLOR = (me*me.a + vec4(0, 0, 0, neighbors)) * custom_modulate;
}
