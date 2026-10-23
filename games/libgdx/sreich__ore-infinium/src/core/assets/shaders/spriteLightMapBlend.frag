#ifdef GL_ES
#define LOWP lowp
    precision mediump float;
#else
    #define LOWP
#endif

varying LOWP vec4 v_color;
varying vec2 v_texCoords;
uniform sampler2D u_texture;
uniform sampler2D u_lightmap;

void main()
{
    //gl_FragColor = v_color * texture2D(u_texture, v_texCoords);
    //gl_FragColor = v_color * texture2D(u_texture, v_texCoords) * vec4(1.0, 0.0, 0.0, 1.0);
    vec2 v2 = vec2(gl_FragCoord.x/1600.0, gl_FragCoord.y/900.0);
    gl_FragColor = (v_color * vec4(0.0001)) + (texture2D(u_texture, v_texCoords) ) * (texture2D(u_lightmap, v2));
}
