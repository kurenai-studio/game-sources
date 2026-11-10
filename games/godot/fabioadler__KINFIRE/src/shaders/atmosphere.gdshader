shader_type canvas_item;
render_mode unshaded;
// Fase 7.3 (MECANICAS §14.3): vinheta e temperatura por bioma — shader
// fullscreen numa ColorRect em CanvasLayer acima do mundo e abaixo da HUD.
// Tundra fria-azul, Areias quente, Pântano esverdeado, Terras Corrompidas
// dessaturadas com vinheta roxa; masmorras ganham vinheta mais fechada.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
uniform vec3 vignette_color : source_color = vec3(0.01, 0.0, 0.03);

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	// Terras Corrompidas: mundo desbotado, "luz sem laço" (LORE §16)
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), desat);
	// temperatura do bioma
	col = mix(col, col * tint, tint_amount);
	// vinheta radial suave
	vec2 d = SCREEN_UV - vec2(0.5);
	float v = smoothstep(0.35, 1.05, length(d) * 1.414) * vignette;
	col = mix(col, vignette_color, v);
	COLOR = vec4(col, 1.0);
}
