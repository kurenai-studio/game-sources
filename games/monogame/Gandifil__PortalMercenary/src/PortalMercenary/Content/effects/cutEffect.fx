#if OPENGL
    #define SV_POSITION POSITION
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

Texture2D SpriteTexture;

//float Angle = 1.0;

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
    float4 color = tex2D(SpriteTextureSampler, input.TextureCoordinates);

    // unpack Color
    float2 p = input.Color.xy;
    float angle = input.Color.z * 2 - 1;
    float cuttingMode = input.Color.a * 2 -1;
    
    float lineY = p.y + (input.TextureCoordinates.x - p.x) * angle;
    float comparisonResult = (input.TextureCoordinates.y - lineY) * cuttingMode; 
    if (comparisonResult > 0) {
        return color;
    } else {
        return float4(0, 0, 0, 0);
    }
}

technique SpriteDrawing
{
    pass P0
    {
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
};
