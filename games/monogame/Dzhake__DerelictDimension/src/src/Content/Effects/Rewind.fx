#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

Texture2D SpriteTexture;
sampler s0;
float SaturationChange;

sampler2D SpriteTextureSampler = sampler_state
{
    Texture = <SpriteTexture>;
};

struct VertexShaderOutput
{
    float4 Position : SV_POSITION;
    float4 Color : COLOR0;
    float2 TextureCoordinates : TEXCOORD0;
};


float4 MainPS(VertexShaderOutput input) : COLOR
{
    float2 coords = input.TextureCoordinates;
    float4 color = tex2D(s0, coords) * input.Color;
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    // -1 => grayscale, 1 => double saturation.
    float saturation = 1.0 + SaturationChange;
    color.rgb = gray + (color.rgb - gray) * saturation;
    return color;
}

technique SpriteDrawing
{
    pass P0
    {
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
};