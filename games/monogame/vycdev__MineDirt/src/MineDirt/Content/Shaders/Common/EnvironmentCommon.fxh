//Everything related to the environment
//Again, it would be better to do this with a struct/constant buffer instead of these ugly uniforms.
//

//=====================
//Fog
//=====================

extern float FogDensity;
extern float4 FogColor;
static const float FogGradient = 1.5; 

void ApplyFog(inout float4 color, float intensity){
    color.rgb = lerp(FogColor.rgb,color.rgb,intensity);
    color.a = lerp(1.0,color.a,intensity); //Semi-transparent materials appear a shade lighter otherwise
}

float GetFogAt(float4 position){
    float fogdist = length(position.xyz);
    float fog = exp(-pow(fogdist*FogDensity,FogGradient));
    fog = clamp(fog,0.0,1.0);
    return fog;
}

//=====================
//Lighting
//=====================
extern float4 SkyLightColor;
extern float3 SunDirection;

void ApplySkyLight(inout float4 color, inout float3 normal){
    color.rgb *= SkyLightColor * max(dot(SunDirection,normal),0.5);
}