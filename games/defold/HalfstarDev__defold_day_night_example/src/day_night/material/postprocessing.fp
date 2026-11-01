#version 140

in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;

uniform fs_uniforms
{
    mediump vec4 sun;
    mediump vec4 tint;
};

#define EXPOSURE   sun.x
#define CONTRAST   sun.y
#define SATURATION sun.z
#define TINT       tint.rgb

// Standard Rec. 709 luminance weights
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

void main()
{
    vec3 color = texture(tex0, var_texcoord0.xy).rgb;
    
    // 1) exposure
    color *= EXPOSURE;

    // 2) tint
    color *= TINT;

    // 3) saturation
    float luma = dot(color, LUMA);
    color = mix(vec3(luma), color, SATURATION);
    
    // 4) contrast
    color = (color - 0.5) * CONTRAST + 0.5;

    color = clamp(color, 0.0, 1.0);

    out_fragColor = vec4(color, 1.0);
}
