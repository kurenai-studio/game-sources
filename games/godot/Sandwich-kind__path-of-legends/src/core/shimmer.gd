class_name Shimmer
# ---------- Перелив самоцветов и кристаллов ----------
# Мягкий блик бежит по цветным (насыщенным) пикселям, когда камера движется:
# он зависит от места на экране, поэтому, пока герой идёт, камни «играют» светом,
# а когда стоит — блик почти неподвижен (никакой ряби). Серый камень не трогается.

static var _mats := {}

const CODE := """
shader_type canvas_item;
uniform float strength = 0.16;
uniform float hue_mix = 0.45;
uniform float speed = 0.05;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 0.001);
	float gem = smoothstep(0.22, 0.55, sat) * step(0.01, c.a);
	// полоса блика бежит по диагонали экрана; чуть-чуть живёт и сама (очень медленно)
	float band = SCREEN_UV.x * 2.6 + SCREEN_UV.y * 1.3 + TIME * speed;
	float s = pow(max(0.0, sin(band * 6.2831)), 8.0);
	vec3 hue = 0.5 + 0.5 * cos(6.2831 * (band * 0.35 + vec3(0.0, 0.33, 0.67)));
	vec3 add = (s * strength + 0.025) * mix(vec3(1.0), hue, hue_mix);
	c.rgb += add * gem;
	COLOR = c;
}
"""

static func material(strength := 0.16, hue_mix := 0.45) -> ShaderMaterial:
	var key := "%.2f_%.2f" % [strength, hue_mix]
	if _mats.has(key):
		return _mats[key]
	var sh := Shader.new()
	sh.code = CODE
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("hue_mix", hue_mix)
	_mats[key] = m
	return m

# Наложить перелив на объект и все его части (клетки разрушаемых блоков)
static func apply(n: CanvasItem, strength := 0.16, hue_mix := 0.45) -> void:
	n.material = material(strength, hue_mix)
	for c in n.get_children():
		if c is CanvasItem:
			c.use_parent_material = true
