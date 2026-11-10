shader_type canvas_item;
// Fase 7.4 (MECANICAS §14.5.2): o mundo respira — chamas e vegetação curvam-se
// com o vento. Vertex offset horizontal: quanto mais alto o pixel (topo da
// chama, copas), mais ele se curva na direção do vento (§14.5.4: "a chama da
// fogueira inclina no shader"). Phase por posição para nada sincronizar.

uniform vec2 wind = vec2(0.0);
uniform float flexibility : hint_range(0.0, 1.0) = 0.35;
uniform float speed : hint_range(0.5, 4.0) = 2.2;

void vertex() {
	float h = clamp(-VERTEX.y / 16.0, 0.0, 1.0);
	float gust = 0.6 + 0.4 * sin(TIME * speed + VERTEX.x * 0.7 + VERTEX.y * 0.3);
	VERTEX += wind * flexibility * h * gust * 4.0;
}
