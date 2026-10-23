shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 chunk_color : source_color = vec4(0.11, 0.065, 0.055, 1.0);
uniform vec4 rim_color : source_color = vec4(0.95, 0.24, 0.08, 1.0);
uniform float time = 0.0;
uniform float seed = 0.0;
uniform float alpha = 1.0;
uniform float global_fade = 1.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 13.7) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= mix(0.72, 1.25, hash(seed + 4.1));
	uv.y *= mix(0.72, 1.25, hash(seed + 7.3));

	float radius = length(uv);
	float angle = atan(uv.y, uv.x);
	float segment = floor((angle + 3.14159265) * 3.2);
	float jagged = hash(segment + seed * 19.0) * 0.2 - 0.1;
	float chips = hash2(floor(uv * 9.0 + seed));
	float shape = 1.0 - smoothstep(0.46 + jagged, 0.62 + jagged, radius);
	shape *= smoothstep(0.0, 0.18, max(abs(uv.x), abs(uv.y)));
	shape *= step(0.16, chips + 0.76);

	float rim = smoothstep(0.36 + jagged, 0.55 + jagged, radius) * shape;
	float ember = smoothstep(0.84, 1.0, hash2(floor(uv * 6.0 - time) + seed));
	vec3 color = mix(chunk_color.rgb, rim_color.rgb, rim * 0.45 + ember * 0.22);
	float out_alpha = shape * alpha * global_fade * chunk_color.a;

	if (out_alpha < 0.01) {
		discard;
	}

	COLOR = vec4(color, out_alpha);
}
