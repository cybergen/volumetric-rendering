Shader "Custom/SnowShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MinDistance("Min Distance", float) = 0.01
		_Color("Sphere Color", Color) = (1, 0, 0)
		_Specular("Specular Power", Range(0, 64)) = 0
		_Gloss("Gloss", Range(0, 10)) = 0
		_SpecularColor("Specular Color", Color) = (1, 1, 1)
		_SoftShadowPower("Shadow Edge", float) = 0.0
		_SnowMap("Volume", 2D) = "" {}
		_MinX("MinX", float) = 0.0
		_MaxX("MaxX", float) = 1.0
		_MinZ("MinY", float) = 0.0
		_MaxZ("MaxZ", float) = 1.0
		_MinXUV("MinXUV", float) = -1.0
		_MaxXUV("MaxXUV", float) = 1.0
		_MinZUV("MinZUV", float) = -1.0
		_MaxZUV("MaxZUV", float) = 1.0
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
				float4 lPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _MinDistance;
			fixed3 _Color;
			fixed3 _SpecularColor;
			float _Specular;
			float _Gloss;
			sampler2D _SnowMap;
			float _SoftShadowPower;
			float _MinX;
			float _MaxX;
			float _MinZ;
			float _MaxZ;

			float _MinXUV;
			float _MaxXUV;
			float _MinZUV;
			float _MaxZUV;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.lPos = v.vertex;
				return o;
			}

			float map(float3 p)
			{
				float3 uvw = p + 0.5;
				float x = (uvw.x - _MinX) * ((_MaxXUV - _MinXUV) / (_MaxX - _MinX)) + _MinXUV;
				float z = (uvw.z - _MinZ) * ((_MaxZUV - _MinZUV) / (_MaxZ - _MinZ)) + _MinZUV;
				return p.y - tex2D(_SnowMap, float2(x, z)).r;
			}

			float shadow(fixed3 rayOrigin, fixed3 rayDir, float minValue, float maxValue)
			{
				float t = minValue;
				float maxSteps = 8;
				float res = 1.0;

				for (int count = 0; count < maxSteps && t < maxValue; count++)
				{
					float h = map(rayOrigin + rayDir * t);
					if (h < _MinDistance) return 0.0;

					res = min(res, _SoftShadowPower * h / t);

					t += h;
				}				
				return res;
			}

			fixed4 simpleLambert(fixed3 position, fixed3 normal, fixed3 viewDir, fixed4 localPos)
			{
				fixed3 lightDir = normalize(ObjSpaceLightDir(localPos));
				fixed3 lightCol = _LightColor0.rgb;

				fixed NdotL = max(dot(normal, lightDir), 0);

				//Self-shadow calculation
				fixed3 start = position + lightDir;
				float s = shadow(start, -lightDir, 0, 0.9);
				//NdotL *= s;

				fixed3 h = (lightDir - viewDir) / 2;
				fixed spec = pow(dot(normal, h), _Specular) * _Gloss;

				fixed4 c;			
				c.rgb = _Color * lightCol * NdotL + (spec * _SpecularColor);

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
				float3 viewDir = -normalize(ObjSpaceViewDir(i.lPos));
				float3 rayHitPoint = raymarchHit(i.lPos.xyz, viewDir);

				if (rayHitPoint.x == -1) 
				{
					return fixed4(0, 0, 0, -1);
				}
				else 
				{
					fixed3 n = normal(rayHitPoint);
					return simpleLambert(rayHitPoint, n, viewDir, i.lPos);
				}
			}
			ENDCG
		}
	}
}
