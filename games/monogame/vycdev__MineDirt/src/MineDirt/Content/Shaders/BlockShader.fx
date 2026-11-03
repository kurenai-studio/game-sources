#include "Common/EnvironmentCommon.fxh"

//--------------------------------------------------------------------------------------
// Globals
//--------------------------------------------------------------------------------------

float4x4 WorldViewProjection;
texture2D TextureAtlas : register(t0);
float3 ChunkWorldPosition;

sampler2D TextureSampler = sampler_state
{
    texture = <TextureAtlas>;
};

//--------------------------------------------------------------------------------------
// Structs
//--------------------------------------------------------------------------------------
struct VertexInput
{
    float Packed0 : TEXCOORD0;
    float Packed1 : TEXCOORD1;
    //float Packed2 : COLOR0;
};

struct VertexOutput
{
    float4 Position : POSITION;
    float TileIndex : TEXCOORD0;
    float3 Normal : TEXCOORD2;
    float2 UV : TEXCOORD1;
    float Fog : COLOR1;
    //float AO : TEXCOORD2;

};

//--------------------------------------------------------------------------------------
// Vertex Shader Helper Functions
//--------------------------------------------------------------------------------------

float3 UnpackAndOffset(float packedData)
{
    float p = floor(packedData + 0.5);
    float p0_16 = floor(p / 16.0);
    float blockX = p - p0_16 * 16.0;
    float p1_16 = floor(p0_16 / 16.0);
    float blockZ = p0_16 - p1_16 * 16.0;
    float p2_8 = floor(p1_16 / 8.0);
    float cornerF = p1_16 - p2_8 * 8.0;
    float blockY = p2_8 % 256.0;
    float ox = cornerF - floor(cornerF / 2.0) * 2.0;
    float oy = floor(cornerF / 2.0) - floor(cornerF / 4.0) * 2.0;
    float oz = floor(cornerF / 4.0);
    return float3(blockX, blockY, blockZ) + float3(ox, oy, oz);
}

float3 GetNormal(int index){

    /*float p = floor(packedData + 0.5);
    float p0_16 = floor(p / 16.0);
    float p1_16 = floor(p0_16 / 16.0);
    float p2_8 = floor(p1_16 / 8.0);
    float index = floor(p2_8 / 256.0);*/

    if (index == 0) return float3(-1, 0, 0);
    else if (index == 1) return float3(1, 0, 0);
    else if (index == 2) return float3(0, 1, 0);
    else if (index == 3) return float3(0,-1, 0);
    else if (index == 4) return float3(0, 0, 1);
    else return float3(0, 0,-1); // index == 5

}

float GetGlobalCornerID(float packedData)
{
    float p = floor(packedData + 0.5);
    float p0_16 = floor(p / 16.0);
    float p1_16 = floor(p0_16 / 16.0);
    float p2_8 = floor(p1_16 / 8.0);
    return p1_16 - p2_8 * 8.0;
}

float2 GetLocalUV(float globalCornerID, float faceID)
{
    float localCorner = 0.0;

    // 0:Front[2,3,0,1], 1:Back[7,6,5,4], 2:Left[6,2,4,0], 3:Right[3,7,1,5], 4:Top[6,7,2,3], 5:Bottom[0,1,4,5]
    if (faceID == 0.0) { if (globalCornerID == 2.0) localCorner = 0.0; else if (globalCornerID == 3.0) localCorner = 1.0; else if (globalCornerID == 0.0) localCorner = 2.0; else localCorner = 3.0; }
    else if (faceID == 1.0) { if (globalCornerID == 7.0) localCorner = 0.0; else if (globalCornerID == 6.0) localCorner = 1.0; else if (globalCornerID == 5.0) localCorner = 2.0; else localCorner = 3.0; }
    else if (faceID == 2.0) { if (globalCornerID == 6.0) localCorner = 0.0; else if (globalCornerID == 2.0) localCorner = 1.0; else if (globalCornerID == 4.0) localCorner = 2.0; else localCorner = 3.0; }
    else if (faceID == 3.0) { if (globalCornerID == 3.0) localCorner = 0.0; else if (globalCornerID == 7.0) localCorner = 1.0; else if (globalCornerID == 1.0) localCorner = 2.0; else localCorner = 3.0; }
    else if (faceID == 4.0) { if (globalCornerID == 6.0) localCorner = 0.0; else if (globalCornerID == 7.0) localCorner = 1.0; else if (globalCornerID == 2.0) localCorner = 2.0; else localCorner = 3.0; }
    else { if (globalCornerID == 0.0) localCorner = 0.0; else if (globalCornerID == 1.0) localCorner = 1.0; else if (globalCornerID == 4.0) localCorner = 2.0; else localCorner = 3.0; }

    // Convert local quad corner (0,1,2,3) to UVs using float math
    float u = fmod(localCorner, 2.0);
    float v = floor(localCorner / 2.0);
    float2 localUV = float2(u, v);

    return localUV;
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VertexOutput VS_Main(VertexInput input)
{
    VertexOutput output;

    float packedUV = floor(input.Packed0 + 0.5);
    float faceID = packedUV - floor(packedUV / 8.0) * 8.0;
    output.TileIndex = floor(packedUV / 8.0);

    float3 coords = UnpackAndOffset(input.Packed1);

    float3 worldPos = coords + ChunkWorldPosition;
    output.Position = mul(float4(worldPos, 1.0f), WorldViewProjection);

    output.Normal = GetNormal(faceID).yzx; //lazy fix.

    float globalCornerID = GetGlobalCornerID(input.Packed1);
    output.UV = GetLocalUV(globalCornerID, faceID);

    output.Fog = GetFogAt(output.Position);

    return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS_Main(VertexOutput IN) : COLOR0
{
    float tileIndex = floor(IN.TileIndex + 0.5);

    // Tile position in 16x16 atlas
    float tileY = floor(tileIndex / 16.0);
    float tileX = tileIndex - tileY * 16.0;

    // Final UV into atlas
    float2 uv = (float2(tileX, tileY) + IN.UV) / 16.0;

    float4 color = tex2D(TextureSampler, uv);
    //color.rgb *= IN.Normal;

    // Optional vignette
    /*float2 centered = IN.UV - 0.5;
    float dist = length(centered);
    float vig = IN.Light - smoothstep(0.01, 2.5, dist);
    color.rgb *= vig;*/
    //color.rgb *= 1.0-IN.AO;

    ApplySkyLight(color, IN.Normal);
    ApplyFog(color,IN.Fog);

    return color;
}

//--------------------------------------------------------------------------------------
// Technique
//--------------------------------------------------------------------------------------
technique BasicTechnique
{
    pass Pass1
    {
        VertexShader = compile vs_3_0 VS_Main();
        PixelShader = compile ps_3_0 PS_Main();
    }
}