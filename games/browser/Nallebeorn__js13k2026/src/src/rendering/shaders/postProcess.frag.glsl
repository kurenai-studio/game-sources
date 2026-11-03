#version 300 es
precision highp float;

in vec2 v; // clip-space position position

uniform vec4 p[21]; // palette
// c = color texture, s = surface index texture, d = depth texture
uniform sampler2D c, d;
uniform highp usampler2D s;
uniform vec2 t; // .x = transition progress, .y = transition color

layout(location=0) out vec4 o; // output color

float D(vec2 u) {
	return texture(d, v*.5+.5 + u).r;
}

void main() {
	o = mix(
		p[int(t.y)],
		vec4(
			any(notEqual(texture(s, v*.5+.5 + vec2(2./640., 0)), texture(s, v*.5+.5)))
			|| any(notEqual(texture(s, v*.5+.5 + vec2(0, 2./480.)), texture(s, v*.5+.5)))
			// surface index outlines
			||
			max(
				abs(D(vec2(2./640., 0)) - D(vec2(0, 0))),
				abs(D(vec2(0, 2./480.)) - D(vec2(0, 0)))
			) > .0005 // depth outlines
			?vec3(.467, .2, .067)
			:mix(
				mix(vec3(1), vec3(.698, 1, 1), v.y*0.5+0.3), // sky gradient
				texture(c, v*.5+.5).rgb,
				texture(c, v*.5+.5).a
			),
			1.
		),
		step(t.x*2. + sin((-v.x+v.y)*22.)*.01, (-v.x*.5+.5 - v.y*.5+.5)*.5)
		+ 1. - step(t.x*2. - 1. + sin((v.x+v.y)*22.)*.01, (-v.x*.5+.5 + v.y*.5+.5)*.5)
	);
	// o = vec4(texture(c, v*.5+.5).rgb, 1);
	// o = texture(d, v*.5+.5);
}
