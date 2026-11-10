Shader "Hidden/Black and White" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		_blend ("Original to BW blend", Range(0, 1)) = 0
	}
	SubShader {
		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float _blend;

			float4 frag(v2f_img i) : COLOR {
				float4 col = tex2D(_MainTex, i.uv);
				float lumin = col.r * 0.3 + col.g * 0.59 + col.b * 0.11;

				col.rgb = lerp(float3(lumin, lumin, lumin), col.rgb, _blend);
				return col;
			}
			ENDCG
		}
	}
}
