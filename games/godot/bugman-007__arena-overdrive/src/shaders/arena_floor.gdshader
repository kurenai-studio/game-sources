shader_type canvas_item;
// Animated arena floor: fine + major grid, radial energy pulse and glowing wall edge.
uniform vec4 bg_color : source_color = vec4(0.035, 0.045, 0.085, 1.0);
uniform vec4 grid_color : source_color = vec4(0.2, 0.75, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(0.25, 0.9, 1.0, 1.0);
uniform vec2 arena_size = vec2(2400.0, 1600.0);
uniform float cell = 64.0;

void fragment() {
	vec2 p = UV * arena_size;
	vec2 gv = p / cell;
	vec2 gf = abs(fract(gv - 0.5) - 0.5) / fwidth(gv);
	float line = 1.0 - min(min(gf.x, gf.y), 1.0);
	vec2 mv = p / (cell * 4.0);
	vec2 mf = abs(fract(mv - 0.5) - 0.5) / fwidth(mv);
	float major = 1.0 - min(min(mf.x, mf.y) * 0.5, 1.0);
	float d = length(p - arena_size * 0.5);
	float pulse = pow(0.5 + 0.5 * sin(d * 0.012 - TIME * 1.6), 6.0);
	vec3 col = bg_color.rgb;
	col += grid_color.rgb * line * (0.10 + 0.22 * pulse);
	col += accent_color.rgb * major * 0.22;
	vec2 e = min(UV, 1.0 - UV) * arena_size;
	float edge = min(e.x, e.y);
	col += accent_color.rgb * exp(-edge / 40.0) * 0.45;
	float vig = smoothstep(1.25, 0.35, length(UV - 0.5) * 1.4);
	COLOR = vec4(col * (0.65 + 0.35 * vig), 1.0);
}
