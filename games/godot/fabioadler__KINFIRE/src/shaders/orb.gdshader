shader_type canvas_item;
// Globo de vida/recurso estilo Diablo: líquido com ondas dentro de uma esfera de vidro.

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform vec4 liquid_color : source_color = vec4(0.8, 0.05, 0.05, 1.0);
uniform vec4 empty_color : source_color = vec4(0.04, 0.02, 0.02, 1.0);
uniform vec4 rim_color : source_color = vec4(0.55, 0.42, 0.22, 1.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	if (d > 1.0) {
		discard;
	}
	float t = TIME;
	float wave = sin(uv.x * 6.0 + t * 2.2) * 0.025 + sin(uv.x * 11.0 - t * 3.1) * 0.012;
	float level = 1.0 - fill * 2.0;
	vec4 col = empty_color;
	if (uv.y > level + wave && fill > 0.001) {
		float depth = clamp((uv.y - level) * 0.5, 0.0, 1.0);
		vec3 c = liquid_color.rgb * mix(1.25, 0.55, depth);
		// Turbulência interna
		float swirl = sin(uv.x * 9.0 + uv.y * 7.0 + t * 1.5) * 0.5 + 0.5;
		c += liquid_color.rgb * swirl * 0.12;
		// Linha brilhante da superfície
		float surface = smoothstep(0.06, 0.0, abs(uv.y - (level + wave)));
		c += vec3(surface * 0.35);
		col = vec4(c, 1.0);
	}
	// Sombreamento esférico
	col.rgb *= mix(1.0, 0.35, smoothstep(0.55, 1.0, d));
	// Reflexo do vidro
	float hl = smoothstep(0.42, 0.0, length(uv - vec2(-0.35, -0.45)));
	col.rgb += vec3(hl * 0.35);
	// Aro dourado
	float rim = smoothstep(0.88, 0.94, d);
	col.rgb = mix(col.rgb, rim_color.rgb * (0.7 + 0.3 * sin(atan(uv.y, uv.x) * 2.0 + 1.0)), rim);
	col.a *= smoothstep(1.0, 0.97, d);
	COLOR = col;
}
