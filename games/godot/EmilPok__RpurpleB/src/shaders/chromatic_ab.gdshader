shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float aberration_x : hint_range(-1.0, 1.0) = 0.0;
uniform float aberration_y : hint_range(-1.0, 1.0) = 0.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 offset = vec2(aberration_x * pixel_size.x, aberration_y * pixel_size.y) * 100.0;
	
	vec3 final_color;
	final_color.r = texture(SCREEN_TEXTURE, SCREEN_UV + offset).r;
	final_color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	final_color.b = texture(SCREEN_TEXTURE, SCREEN_UV - offset).b;
	
	float gray = dot(final_color, vec3(0.299, 0.587, 0.114));
	final_color = mix(final_color, vec3(gray), desaturation);
	
	COLOR.rgb = final_color;
}