shader_type canvas_item;

uniform vec4 original_0;
uniform vec4 original_1;
uniform vec4 original_2;
uniform vec4 original_3;
uniform vec4 original_4;
uniform vec4 original_5;
uniform vec4 original_6;

uniform vec4 replace_0;
uniform vec4 replace_1;
uniform vec4 replace_2;
uniform vec4 replace_3;
uniform vec4 replace_4;
uniform vec4 replace_5;
uniform vec4 replace_6;

const float precision = 0.01;

vec4 swap_color(vec4 color){
	vec4 original_colors[7] = vec4[7] (original_0, original_1, original_2, original_3, original_4, original_5, original_6);
	vec4 replace_colors[7] = vec4[7] (replace_0, replace_1, replace_2, replace_3, replace_4, replace_5, replace_6);
	for (int i = 0; i < 7; i ++) {
		if (distance(color, original_colors[i]) <= precision){
			return replace_colors[i];
		}
	}
	return color;
}

void fragment() {
	COLOR = swap_color(texture(TEXTURE, UV));
}
