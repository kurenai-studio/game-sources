shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting;

uniform vec4 albedo_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float jitter_amount : hint_range(0.0, 1.0) = 0.4;

void vertex() {
	// PSX vertex snapping in clip space
	vec4 snap_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (snap_pos.w != 0.0) {
		vec2 grid = vec2(320.0, 240.0) * (1.0 - jitter_amount * 0.4);
		snap_pos.xy = floor(snap_pos.xy / snap_pos.w * grid) / grid * snap_pos.w;
	}
	POSITION = snap_pos;
}

void fragment() {
	ALBEDO = albedo_color.rgb;
}
