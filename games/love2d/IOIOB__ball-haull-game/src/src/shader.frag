extern number intensity;
extern number screenWidth;
extern number screenHeight;
extern number brightness;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	vec4 pixel = vec4(Texel(texture, texture_coords));
	vec4 res = vec4(pixel.r, pixel.g, pixel.b, 1)
		- pow(cos(texture_coords.y * 3.142 * screenHeight), 3) * (.1 * intensity)
		- sin(texture_coords.x * 3.142 * screenWidth * 2) * (.01 * intensity);
	return res * brightness;
}
