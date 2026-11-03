//TODO: procedural skyboxes can be expansive, optimise with a G-Buffer
#define PI 3.14159

#include "Common/Voronoi.fxh"

static const float AstroRadius = 0.2;
static const float AstroRadiusRising = 0.62; //Rising sun and moon are bigger
static const float SunBlur = 0.4;

extern float3 DayColor = float3(0.518, 0.918, 1);
extern float3 DayBottomColor = float3(0.314, 0.6, 0.78);
extern const float3 SunsetColor = float3(1, 0.753, 0.365);
extern const float3 SunsetBottomColor = float3(0.988, 0.871, 0.329);
extern const float3 NightColor = float3(0.149, 0, 0.329);
extern const float3 NightBottomColor = float3(0.082, 0, 0.2);

extern float4x4 WorldViewProjection;
extern int DisplayMode; //debug only

extern float3 SunDirection;

float AstroSize(float3 astral_dir){
    return max(AstroRadius + cos(astral_dir.y * PI) * AstroRadius * AstroRadiusRising,AstroRadius);
}

float3x3 direction_to_matrix(float3 direction) {
	float3 x_axis = normalize(cross(float3(0.0, 1.0, 0.0), direction));
	float3 y_axis = normalize(cross(direction, x_axis));
	return float3x3(float3(x_axis.x, y_axis.x, direction.x),
				float3(x_axis.y, y_axis.y, direction.y),
				float3(x_axis.z, y_axis.z, direction.z));
}

struct PixelInput{
    float4 Position : SV_POSITION;
    float3 Position3D : TEXCOORD0; //already normalized, the skydome has radius 1
};

PixelInput VS_Main( float3 Position : POSITION0){
    PixelInput output;

    output.Position = mul(float4(Position,1.0), WorldViewProjection);
    output.Position3D = Position;

    return output;
}


float4 PS_Main(PixelInput input) : SV_TARGET{

    //minor additions and a moon can be included too.
    float3 dir = mul(input.Position3D,direction_to_matrix(SunDirection));
	float2 astro_uv = (-(dir.xy / dir.z) / AstroSize(SunDirection)) + float2(0.5,0.5);

    if(DisplayMode == 1){ //Position
        return float4(input.Position3D.rgb,1.0);

    }else if(DisplayMode == 2){ //x
        return float4(input.Position3D.xxx,1);

    }else if(DisplayMode == 3){ //y
        return float4(input.Position3D.yyy,1);

    }else if(DisplayMode == 4){ //z
        return float4(input.Position3D.zzz,1);

    }else if(DisplayMode == 5){ //Astro UV
        return float4(float3(astro_uv,0.0),1.0);
    }

    float3 final = 0.0;

    if(SunDirection.y < 0.0){
		float2 stars = voronoi(input.Position3D * 25.0).xz;
		final += smoothstep(0.025 + ((1.0 + sin(stars.y)) / 2.0) * 0.05, 0.0, stars.x) * abs(SunDirection.y);
	}

	float astro_mask = ceil(
		clamp(astro_uv.x * (1.0 - astro_uv.x), 0.0, 1.0) *
		clamp(astro_uv.y * (1.0 - astro_uv.y), 0.0, 1.0)
		) * ceil(dir.z);
	float3 astro = (1.0 - smoothstep(AstroRadius -(SunBlur+0.1), AstroRadius +SunBlur, length(astro_uv - float2(0.5,0.5)))) * astro_mask; //nothing stops you from using a texture.

    float3 gradient_day = lerp(DayBottomColor, DayColor, clamp((input.Position3D.y), 0.0, 1.0)) * clamp(SunDirection.y, 0.0, 1.0);
    float3 gradient_sunset = lerp(SunsetBottomColor, SunsetColor, clamp((input.Position3D.y), 0.0, 1.0)) * clamp(1.0 - abs(SunDirection.y), 0.0, 1.0);
    float3 gradient_night = lerp(NightBottomColor, NightColor, clamp((input.Position3D.y), 0.0, 1.0)) * clamp(-SunDirection.y, 0.0, 1.0);
    
    final += astro + gradient_day + gradient_night + gradient_sunset;

    return float4(
        final,
        1.0
    );
}

technique SkyboxTechnique
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS_Main();
        PixelShader = compile ps_3_0 PS_Main();
    }
}