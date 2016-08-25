Shader "Custom/VolumetricShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Radius ("Radius", float) = 1
		_Center ("Center", Vector) = (0, 0, 0)
		_Steps ("Steps", int) = 64
		_StepSize ("Step Size", float) = 0.01
		_MinDistance("Min Distance", float) = 0.01
		_Color("Sphere Color", Color) = (1, 0, 0)
		_Specular("Specular Power", Range(0, 1)) = 0
		_Gloss("Gloss", Range(0, 10)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Tags { "LightMode" = "ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float3 _Center;
			float _Radius;
			int _Steps;
			float _StepSize;
			float _MinDistance;
			fixed3 _Color;
			float _Specular;
			float _Gloss;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wPos = mul(_Object2World, v.vertex).xyz;
				return o;
			}

			float map(float3 p)
			{
				return distance(p, _Center) - _Radius;
			}

			fixed4 simpleLambert(fixed3 normal, float3 viewDir)
			{
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				fixed3 lightCol = _LightColor0.rgb;

				fixed NdotL = max(dot(normal, lightDir), 0);

				fixed3 h = (lightDir - viewDir) / 2;
				fixed s = pow(dot(normal, h), _Specular) * _Gloss;

				fixed4 c;
				c.rgb = _Color * lightCol * NdotL + s;
				c.a = 1;
				return c;
			}

			float3 normal(float3 p)
			{
				const float eps = 0.01;

				return normalize
				(
					float3
					(
						map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
						map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
						map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
					)
				);
			}

			fixed4 renderSurface(float3 p, float3 dir)
			{
				float3 n = normal(p);
				return simpleLambert(n, dir);
			}

			fixed4 raymarchHit(float3 pos, float3 dir)
			{
				for (int i = 0; i < _Steps; i++)
				{
					float dist = map(pos);
					if (dist < _MinDistance) return renderSurface(pos, dir);

					pos += dist * dir;
				}
				return fixed4(1,1,1,1);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 worldPos = i.wPos;
				float3 viewDir = normalize(i.wPos - _WorldSpaceCameraPos);

				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);

				return raymarchHit(worldPos, viewDir);
			}
			ENDCG
		}
	}
}
