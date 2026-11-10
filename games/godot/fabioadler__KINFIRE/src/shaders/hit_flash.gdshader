shader_type canvas_item;
// Pisca o sprite em uma cor sólida ao receber dano; também desenha contorno (elites/hover).
// Fase 7.3 (MECANICAS §14.3): light() adiciona rim light direcional — a borda
// do sprite vira um normal 2D (pixel art tem bordas duras), então cada luz
// pega o lado do personagem voltado para ela: rim dourado perto da fogueira.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 0.2, 0.1, 0.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.9;
uniform float rim_power : hint_range(1.0, 8.0) = 2.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 col = tex * COLOR;
	if (outline_color.a > 0.0 && tex.a < 0.1) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (a > 0.0) {
			col = outline_color;
		}
	}
	col.rgb = mix(col.rgb, flash_color.rgb, flash * step(0.1, tex.a));
	COLOR = col;
}

void light() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float a_l = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float a_r = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float a_u = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float a_d = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	// normal da borda: gradiente do alpha aponta para dentro do sprite
	vec3 n = normalize(vec3((a_r - a_l) * 2.0, (a_d - a_u) * 2.0, 1.25));
	float rim = 0.0;
	vec2 dv = LIGHT_POSITION.xy - LIGHT_VERTEX.xy;
	if (length(dv) > 0.5) {
		float facing = max(dot(n.xy, normalize(dv)), 0.0);
		rim = pow(facing, rim_power) * rim_strength;
	}
	// toque quente no rim (fogueira/lava já são quentes; luzes frias mantêm a própria cor)
	vec3 warm = mix(LIGHT_COLOR.rgb, vec3(1.0, 0.82, 0.5), 0.35);
	LIGHT.rgb += warm * rim * LIGHT_ENERGY;
}
