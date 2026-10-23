shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_texture: source_color, hint_default_white,
	filter_nearest_mipmap_anisotropic;


void fragment() {
	vec4 color = texture(albedo_texture, UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
