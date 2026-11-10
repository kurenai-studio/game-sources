shader_type canvas_item;
// Máscara circular (Fase 6.1, MECANICAS §9.2): descarta tudo fora do
// raio — transforma o minimapa quadrado num minimapa redondo.
void fragment() {
	if (distance(UV, vec2(0.5)) > 0.5) {
		discard;
	}
}
