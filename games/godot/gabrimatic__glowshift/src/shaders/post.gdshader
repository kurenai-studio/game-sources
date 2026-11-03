shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float aberration = 0.0;
uniform float flash = 0.0;
uniform float grain = 0.012;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - 0.5;
	float off = 0.003 + aberration * 0.03;
	vec3 c;
	c.r = texture(screen_tex, uv + d * off).r;
	c.g = texture(screen_tex, uv).g;
	c.b = texture(screen_tex, uv - d * off).b;
	c *= 1.0 - dot(d, d) * 0.8;
	c += (fract(sin(dot(uv * 1000.0 + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * grain;
	c = mix(c, vec3(1.0), flash);
	COLOR = vec4(c, 1.0);
}
