#version 140

uniform sampler2D texture_sampler;
uniform f_uniform
{
    vec4 tint;
};

in vec2 var_texcoord0;
in vec4 new_color;
in vec4 new_outline;
out vec4 final_color;

void main()
{
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    lowp vec4 sprite = texture(texture_sampler, var_texcoord0.xy);

    lowp float combine = (sprite.r + sprite.g);
    lowp float greenmul = sprite.g * 2;
    
    if(combine == greenmul){
        sprite = vec4(sprite.rgb*new_color.rgb,sprite.a);
    }

    if(new_outline.w >= 1.0 && sprite.g >= 1.0){
        sprite = vec4(new_outline.rgb,1.0);
    }
    else if (sprite.g >= 1.0){
        sprite = vec4(0.0, 0.0, 0.0, 0.0);
    }
    
    final_color = vec4(sprite * tint);
}
