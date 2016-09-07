Shader "Custom/SnowShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SnowHeight ("Snow Map", 2D) = "white" {}
		_MinDistance("Min Distance", float) = 0.01
		_SnowScale("Snow Scale", float) = 2.0
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
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 lPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			sampler2D _SnowHeight;
			float4 _MainTex_ST;
			float _MinDistance;
			float _SnowScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.lPos = v.vertex.xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			float map(float3 p)
			{
				float2 temp = p.xy + float2(0.5, 0.5);
				float2 uv = clamp(temp, 0, 1);
				return p.y - tex2D(_SnowHeight, uv).r * _SnowScale;
			}

			float shadow(fixed3 rayOrigin, fixed3 rayDir, float min, float max)
			{
				float t = min;
				float maxSteps = 15;

				for (int count = 0; count < maxSteps && t < max; count++)
				{
					float h = map(rayOrigin + rayDir * t);
					if (h < _MinDistance) return 0.0;
					t += h;
				}
				return 1.0;
			}

			fixed4 simpleLambert(fixed3 position, fixed3 normal, fixed3 viewDir, fixed3 color)
			{
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				fixed3 lightCol = _LightColor0.rgb;

				fixed NdotL = max(dot(normal, lightDir), 0);

				//Self-shadow calculation
				// fixed3 start = position + lightDir;
				// float s = shadow(start, -lightDir, 0, 0.7);
				// NdotL *= s;

				fixed4 c;
				//NdotL = NdotL * 0.5 + 0.5;
				c.rgb = color * lightCol * NdotL;
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
					return simpleLambert(rayHitPoint, n, viewDir, tex2D(_MainTex, rayHitPoint.xy + float2(0.5, 0.5)));
				}
			}
			ENDCG
		}
	}
}
