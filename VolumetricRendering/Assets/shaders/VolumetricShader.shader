Shader "Custom/VolumetricShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MinDistance("Min Distance", float) = 0.01
		_Color("Sphere Color", Color) = (1, 0, 0)
		_Specular("Specular Power", Range(0, 1)) = 0
		_Gloss("Gloss", Range(0, 10)) = 0
		_Volume("Volume", 3D) = "" {}
	}
	SubShader
	{
		Tags { "LightMode" = "ForwardBase" }
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha

		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma alpha
			#pragma enable_d3d11_debug_symbols
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 lPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _MinDistance;
			fixed3 _Color;
			float _Specular;
			float _Gloss;
			sampler3D _Volume;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.lPos = v.vertex.xyz;
				return o;
			}

			float map(float3 p)
			{
				float3 uvw = clamp(p + 0.5, 0, 1);
				return 2 * (tex3D(_Volume, uvw).a - 0.5);
			}

			float shadow(fixed3 rayOrigin, fixed3 rayDir, float min, float max)
			{
				float t = min;
				float maxSteps = 15;

				// for (int count = 0; count < maxSteps && t < max; count++)
				// {
				// 	float h = map(rayOrigin + rayDir * t);
				// 	if (h < _MinDistance) return 0.0;
				// 	t += h;
				// }
				return 1.0;
			}

			fixed4 simpleLambert(fixed3 position, fixed3 normal, fixed3 viewDir)
			{
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				fixed3 lightCol = _LightColor0.rgb;

				fixed NdotL = max(dot(normal, lightDir), 0);

				//Self-shadow calculation
				fixed3 start = position + lightDir;
				float s = shadow(start, -lightDir, 0, 0.3);
				NdotL *= s;

				fixed3 h = (lightDir - viewDir) / 2;
				fixed spec = pow(dot(normal, h), _Specular) * _Gloss;

				fixed4 c;
				NdotL = NdotL * 0.5 + 0.5;
				c.rgb = position.xyz * lightCol * NdotL + spec;//rgb;// * lightCol * NdotL + s;//_Color * lightCol * NdotL + s;
				c.a = 1;
				return c;
			}

			fixed3 normal(fixed3 p)
			{
				const fixed eps = 0.15;

				return normalize
				(
					fixed3
					(
						map(p + fixed3(eps, 0, 0)) - map(p - fixed3(eps, 0, 0)),
						map(p + fixed3(0, eps, 0)) - map(p - fixed3(0, eps, 0)),
						map(p + fixed3(0, 0, eps)) - map(p - fixed3(0, 0, eps))
					)
				);
			}

			float3 raymarchHit(float3 pos, float3 dir)
			{
				const float steps = 32;			

				for (int i = 0; i < steps; i++)
				{
					float dist = map(pos);
					if (dist < _MinDistance) return pos;
					pos += dist * dir;
				}
				return float3(-1,-1,-1);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 localPos = i.lPos;
				float3 viewDir = normalize(localPos - mul(_World2Object, _WorldSpaceCameraPos));
				float3 rayHitPoint = raymarchHit(localPos, viewDir);

				if (rayHitPoint.x == -1) 
				{
					return fixed4(0, 0, 0, -1);
				}
				else 
				{
					fixed3 n = normal(rayHitPoint);
					return simpleLambert(rayHitPoint, n, viewDir);
				}
			}
			ENDCG
		}
	}
}
