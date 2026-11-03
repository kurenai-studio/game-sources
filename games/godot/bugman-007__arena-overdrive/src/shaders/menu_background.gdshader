shader_type canvas_item;
// Synthwave horizon: starfield, striped sun and a scrolling perspective grid.
uniform vec4 top_color : source_color = vec4(0.02, 0.025, 0.07, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.28, 0.05, 0.36, 1.0);
uniform vec4 grid_color : source_color = vec4(0.24, 0.9, 1.0, 1.0);
uniform vec4 sun_top : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform vec4 sun_bottom : source_color = vec4(1.0, 0.3, 0.6, 1.0);
uniform float aspect = 1.7778;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float horizon = 0.6;
	vec3 col = mix(top_color.rgb, horizon_color.rgb, pow(smoothstep(0.0, horizon, uv.y), 1.6));
	vec2 sp = floor(uv * vec2(220.0, 124.0));
	float tw = 0.5 + 0.5 * sin(TIME * 2.5 + hash(sp + 7.0) * 40.0);
	col += vec3(step(0.993, hash(sp)) * tw) * (1.0 - smoothstep(0.2, horizon, uv.y));
	vec2 c = vec2((uv.x - 0.68) * aspect, uv.y - horizon + 0.02);
	float r = length(c);
	if (uv.y < horizon) {
		float body = 1.0 - smoothstep(0.255, 0.26, r);
		float band = (horizon - uv.y) / 0.26;
		float stripes = step(0.35 - band * 0.35, fract(uv.y * 38.0 - TIME * 0.4));
		vec3 sun = mix(sun_bottom.rgb, sun_top.rgb, clamp(band, 0.0, 1.0));
		col = mix(col, sun, body * mix(stripes, 1.0, step(0.55, band)));
		col += sun_bottom.rgb * 0.35 * exp(-max(r - 0.25, 0.0) * 6.0);
	} else {
		float depth = uv.y - horizon;
		float z = 0.12 / depth;
		vec2 gv = vec2((uv.x - 0.5) * z * 5.0, z + TIME * 1.2);
		vec2 gf = abs(fract(gv - 0.5) - 0.5) / fwidth(gv);
		float line = 1.0 - min(min(gf.x, gf.y), 1.0);
		vec3 floor_col = mix(horizon_color.rgb * 0.5, vec3(0.01, 0.01, 0.03), smoothstep(0.0, 0.4, depth));
		col = floor_col + grid_color.rgb * line * smoothstep(0.0, 0.25, depth) * 0.9;
		col += sun_bottom.rgb * exp(-depth * 18.0) * 0.6;
	}
	COLOR = vec4(col, 1.0);
}
