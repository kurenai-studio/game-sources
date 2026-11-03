sampler2D ScreenTexture : register(s0);

bool IsUnderwater;
float Time;

float4 PS_Main(float4 pos : SV_POSITION, float2 tex : TEXCOORD0) : SV_TARGET
{
    float4 originalColor = tex2D(ScreenTexture, tex);

    if (!IsUnderwater)
    {
        return originalColor;
    }

    float xOffset = sin(tex.y * 20.0 + Time * 1.0) * 0.0005;
    float yOffset = cos(tex.x * 20.0 + Time * 1.5) * 0.0005;
    float2 distortedUV = tex + float2(xOffset, yOffset);
    float4 distortedColor = tex2D(ScreenTexture, distortedUV);

    float3 underwaterColor = float3(0.1, 0.3, 0.7);
    float fogAmount = tex.y * 0.6;
    float3 finalColor = lerp(distortedColor.rgb, underwaterColor, fogAmount);

    return float4(finalColor, originalColor.a);
}

technique PostProcess
{
    pass P0
    {
        PixelShader = compile ps_3_0 PS_Main();
    }
}