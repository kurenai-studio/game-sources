#include "Card.fxh"

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
float Lean;
float HalfSideX;
float HalfSideY;
float CardRadius;

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

float2 DeModifyCoords(float2 coords)
{
    return float2(coords.x - Lean * 0.25, coords.y);
}

float Distance(float2 coords)
{
    return sdBevelBox(coords, float2(HalfSideX, HalfSideY), CardRadius);
}

float4 MainPS(VertexShaderOutput input) : COLOR
{
    float2 coords = input.TextureCoordinates;
    if (Distance(coords) <= 0)
    {
        return tex2D(s0, coords);
    }
    return float4(0, 0, 0, 0);
}

technique SpriteDrawing
{
    pass P0
    {
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
};