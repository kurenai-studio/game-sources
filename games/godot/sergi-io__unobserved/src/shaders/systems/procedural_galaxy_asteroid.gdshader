shader_type canvas_item;
render_mode unshaded, blend_mix;

float hash12(vec2 value) {
	vec3 p = fract(vec3(value.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void fragment() {
	vec4 instance_color = COLOR;
	vec2 p = UV * 2.0 - vec2(1.0);
	float d = length(p);
	float chip = hash12(floor((p + vec2(1.0)) * 5.0));
	float edge = 0.74 + chip * 0.2;
	float mask = smoothstep(edge, edge - 0.16, d);
	float highlight = smoothstep(0.85, 0.05, length(p + vec2(0.28, 0.24)));
	float shade = mix(0.48, 1.0, highlight);
	COLOR = vec4(instance_color.rgb * shade, instance_color.a * mask);
}
