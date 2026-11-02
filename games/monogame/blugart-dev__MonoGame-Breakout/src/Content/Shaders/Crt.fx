// CRT post-process: barrel curvature, scanlines, vignette. Applied by
// VirtualScreen.Present, so it runs once over the final 800x480 image —
// the game itself never knows it is being drawn "through" a 1978 television.
//
// This is the Content Pipeline's other major asset type: .fx files are HLSL
// source that the EffectProcessor compiles at BUILD time into a platform
// blob (for DesktopGL it is translated to GLSL via MojoShader — which is
// also why effect builds on Linux need Wine: the first step is Direct3D's
// shader compiler). At runtime, Content.Load<Effect> just uploads the blob.
//
// The preprocessor block below is the standard MonoGame header: the same
// source compiles for both backends, it only needs to be told which shader
// model names the target uses.
#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

// SpriteBatch binds the texture it is drawing (for us: the virtual screen's
// render target) to this sampler — the name is the convention its default
// shader uses, so we keep it.
Texture2D SpriteTexture;
sampler2D SpriteTextureSampler = sampler_state
{
    Texture = <SpriteTexture>;
};

// Set once from C# (VirtualScreen). Effect parameters persist on the Effect
// object between frames; only changed values need re-setting.
float2 VirtualSize;      // 800x480 — gives scanlines their per-row spacing
float Curvature;         // 0 = flat glass
float ScanlineStrength;  // 0..1 darkening of alternate rows
float VignetteStrength;  // 0..1 corner falloff

struct VertexShaderOutput
{
    float4 Position : SV_POSITION;
    float4 Color : COLOR0;
    float2 TextureCoordinates : TEXCOORD0;
};

float4 MainPS(VertexShaderOutput input) : COLOR
{
    // Barrel distortion, the classic cheap form: push each point outward in
    // proportion to its squared distance from the center. Sampling *outward*
    // makes the image bow *inward* at the edges — the curved-glass look.
    float2 centered = input.TextureCoordinates * 2.0 - 1.0;
    float r2 = dot(centered, centered);
    centered *= 1.0 + Curvature * r2;

    // Past the curved edge there is no image — mask to black. step() instead
    // of an if/discard: branchless is the native dialect of pixel shaders.
    float inside = step(abs(centered.x), 1.0) * step(abs(centered.y), 1.0);

    float2 uv = centered * 0.5 + 0.5;
    float4 color = tex2D(SpriteTextureSampler, uv) * input.Color;

    // Scanlines: cos(pi * row) alternates sign every virtual row, so even
    // rows keep full brightness and odd rows dim by ScanlineStrength. Using
    // VIRTUAL rows keeps the lines locked to game pixels at any window size.
    float wave = 0.5 + 0.5 * cos(uv.y * VirtualSize.y * 3.14159265);
    color.rgb *= 1.0 - ScanlineStrength * (1.0 - wave);

    // Vignette rides the same r2 the curvature used: corners sit furthest
    // from the electron gun, so they get both the bend and the dimming.
    color.rgb *= 1.0 - VignetteStrength * r2;

    return color * inside;
}

technique CrtPostProcess
{
    pass P0
    {
        // Pixel shader only: SpriteBatch's own vertex shader stays bound,
        // which is exactly what a SpriteBatch post-process wants.
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
};
