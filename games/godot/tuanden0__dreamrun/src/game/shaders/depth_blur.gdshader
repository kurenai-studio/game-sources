// Depth-of-field blur for everything drawn before this node (sky + far layers). Put it on a huge
// ColorRect right after a BackBufferCopy (copy_mode = Viewport), between two parallax layers.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 6.0) = 3.0;
uniform float radius_px : hint_range(0.0, 24.0) = 5.0;
// Cancels the CanvasModulate that is applied to this rect again: set to 1 / Darkness.color.
uniform vec3 compensate = vec3(1.0);

void fragment() {
	vec2 o = SCREEN_PIXEL_SIZE * radius_px;
	vec3 c = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb * 4.0;
	c += textureLod(screen_tex, SCREEN_UV + vec2(o.x, 0.0), blur_lod).rgb * 2.0;
	c += textureLod(screen_tex, SCREEN_UV - vec2(o.x, 0.0), blur_lod).rgb * 2.0;
	c += textureLod(screen_tex, SCREEN_UV + vec2(0.0, o.y), blur_lod).rgb * 2.0;
	c += textureLod(screen_tex, SCREEN_UV - vec2(0.0, o.y), blur_lod).rgb * 2.0;
	c += textureLod(screen_tex, SCREEN_UV + o, blur_lod).rgb;
	c += textureLod(screen_tex, SCREEN_UV - o, blur_lod).rgb;
	c += textureLod(screen_tex, SCREEN_UV + vec2(o.x, -o.y), blur_lod).rgb;
	c += textureLod(screen_tex, SCREEN_UV + vec2(-o.x, o.y), blur_lod).rgb;
	COLOR = vec4(c / 16.0 * compensate, 1.0);
}
