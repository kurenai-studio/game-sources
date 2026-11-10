shader_type canvas_item;
// Team colours: the sprite sheets paint every sweatband in key colours
// (tools/palette.py BAND_KEY_*); this swaps them for a team's, three shades each.
//
// In fragment(), COLOR already holds the texture's colour, so the tint (the
// vertex colour, which carries modulate) is kept from vertex() instead:
// multiplying by COLOR again would square every colour and turn a white band
// pink.

uniform vec3 key_main[3];
uniform vec3 key_stripe[3];
uniform vec3 main_col[3];
uniform vec3 stripe_col[3];
uniform float flash = 0.0;   // a white flash (a perfect bounce, a record)

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	for (int i = 0; i < 3; i++) {
		if (distance(c.rgb, key_main[i]) < 0.03) { c.rgb = main_col[i]; }
		if (distance(c.rgb, key_stripe[i]) < 0.03) { c.rgb = stripe_col[i]; }
	}
	c.rgb = mix(c.rgb, vec3(1.0, 0.98, 0.94), flash * c.a);
	COLOR = c * tint;
}
