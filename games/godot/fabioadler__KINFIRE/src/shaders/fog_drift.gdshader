shader_type canvas_item;
// Fase 7.6 (MECANICAS §14.4): névoa volumétrica fake — duas camadas de
// ruído sin-based scrollando em direções/velocidades distintas dão a
// paralaxe; o vento empurra a névoa e a densidade sobe à noite.

uniform vec4 fog_color : source_color = vec4(0.75, 0.82, 0.75, 0.16);
uniform float density = 0.16;      // 0..0.5 — mais denso à noite
uniform vec2 drift_dir = vec2(1.0, 0.0);  // rumo do vento
uniform float drift_speed = 12.0;  // px/s (paralaxe lenta)
uniform float layer_seed = 0.0;     // desloca o padrão por camada
uniform float time_sec = 0.0;

// ruído de valor suave 2D (sin-based, estável)
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 s = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, s.x), mix(c, d, s.x), s.y);
}

void fragment() {
	vec2 uv = UV * vec2(3.0, 2.0);          // padrão maior que a tela
	vec2 flow = drift_dir * drift_speed * time_sec;
	// duas oitavas de ruído esférico-scrollando (paralaxe fake)
	float n1 = vnoise(uv + flow * 0.010 + vec2(layer_seed, layer_seed * 1.7));
	float n2 = vnoise(uv * 2.3 - flow * 0.006 + vec2(layer_seed * 2.3, layer_seed));
	float fog = smoothstep(0.35, 0.95, n1 * 0.65 + n2 * 0.35);
	float alpha = fog * density;
	COLOR = vec4(fog_color.rgb, alpha * fog_color.a * 2.0);
}
