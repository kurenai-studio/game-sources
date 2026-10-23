shader_type spatial;
render_mode
	diffuse_lambert,
	specular_disabled,
	cull_disabled;

uniform sampler2D albedo_texture: source_color,
	filter_nearest_mipmap_anisotropic;

uniform float flow_intensity = 0.15;
uniform float flow_speed = 2.0;


void fragment() {
	vec2 flow_uv = vec2(
		UV.x + flow_intensity * sin(TIME * flow_speed + UV.y),
		UV.y + flow_intensity * sin(TIME * flow_speed + UV.x));
	ALBEDO = texture(albedo_texture, flow_uv).rgb;
	METALLIC = 0.0; SPECULAR = 0.0;
}
