#version 140


in mediump vec2 var_texcoord0;
in mediump vec2 var_texcoord1;

uniform mediump sampler2D tex0;

out vec4 color_out;

void main()
{
    float speed = 0.5;
    vec2 uv0 = var_texcoord0;
    vec2 uv1 = fract(var_texcoord1);
    vec3 light_range = vec3(2.0,2.0,2.0);
    vec3 dark_range = vec3(0.9,0.9,0.9);

    vec4 tex = texture(tex0, uv0.xy);

    vec3 gleem = mix(light_range,dark_range,abs(uv1.y * uv1.y * 2.0 - 1.0));

    vec4 final = vec4(tex.rgb*(gleem.rgb-speed/tex.a),tex.a);

    color_out = final;

}