shader_type spatial;

uniform sampler2D albedo_texture: source_color, hint_default_white,
	filter_nearest_mipmap_anisotropic;

uniform float fade = 0.0;
uniform float fade_index = 0.0;


void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
	METALLIC = 0.0; SPECULAR = 0.0;
	ALPHA = 1.0 - fade;
}
