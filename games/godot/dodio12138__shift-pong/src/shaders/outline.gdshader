// Full-screen quad inside the low-res SubViewport: draws a 1px dark outline
// wherever a pixel sits noticeably in front of a neighbour (depth silhouette).
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform bool enabled = true;
uniform float depth_threshold = 0.06;
uniform vec3 outline_color : source_color = vec3(0.04, 0.03, 0.07);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 view = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -view.z / view.w;
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	if (enabled) {
		vec2 px = 1.0 / VIEWPORT_SIZE;
		float d = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
		float n = max(
			max(linear_depth(SCREEN_UV + vec2(px.x, 0.0), INV_PROJECTION_MATRIX),
				linear_depth(SCREEN_UV - vec2(px.x, 0.0), INV_PROJECTION_MATRIX)),
			max(linear_depth(SCREEN_UV + vec2(0.0, px.y), INV_PROJECTION_MATRIX),
				linear_depth(SCREEN_UV - vec2(0.0, px.y), INV_PROJECTION_MATRIX)));
		if (n - d > depth_threshold * d) {
			col = mix(col, outline_color, 0.85);
		}
	}
	ALBEDO = col;
}
