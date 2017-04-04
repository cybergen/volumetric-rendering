// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SnowShader"
{
	Properties
	{
		_MinDistance("Min Distance", float) = 0.01
		_Color("Sphere Color", Color) = (1, 0, 0)
		_Specular("Specular Power", Range(0, 64)) = 0
		_Gloss("Gloss", Range(0, 10)) = 0
		_SpecularColor("Specular Color", Color) = (1, 1, 1)
		_SoftShadowPower("Shadow Edge", float) = 0.0
		_SnowMap("Volume", 2D) = "" {}

		_SurfaceDetail("Surface Detail", 2D) = "" {}
		_DetailScale("Detail Scale", Range(0, 2)) = 1.0

		_ShadowColor("Shadow Color", Color) = (0, 0, 1)
		_ShadowColorStart("Shadow Color Blend Start", Range(0, 1)) = 0.35
		_ShadowColorEnd("Shadow Color Blend End", Range(0, 1)) = 0.1

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
				float4 lPos : TEXCOORD1;
			};

			float _MinDistance;
			fixed3 _Color;
			fixed3 _SpecularColor;
			float _Specular;
			float _Gloss;
			sampler2D _SnowMap;
			float _SoftShadowPower;
			
			sampler2D _SurfaceDetail;
			float _DetailScale;

			fixed3 _ShadowColor;
			fixed _ShadowColorStart;
			fixed _ShadowColorEnd;

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
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.lPos = v.vertex;
				o.uv = v.uv;
				return o;
			}

			float map(float3 p)
			{
				float x = (p.x - _MinX) * ((_MaxXUV - _MinXUV) / (_MaxX - _MinX)) + _MinXUV;
				float z = (p.z - _MinZ) * ((_MaxZUV - _MinZUV) / (_MaxZ - _MinZ)) + _MinZUV;
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

			//Simple linear blend. Consider reoriented normal map in future
			fixed3 combineNormal(fixed3 base, fixed3 detail)
			{
				return normalize(base + detail);
			}

			fixed4 simpleLambert(fixed3 position, fixed3 normal, fixed3 detailNormal, fixed3 viewDir, fixed4 localPos)
			{
				fixed3 lightDir = normalize(ObjSpaceLightDir(localPos));
				fixed3 lightCol = _LightColor0.rgb;

				fixed NdotL = dot(normal, lightDir);

				//Self-shadow calculation
				//fixed3 start = position + lightDir;
				//float s = shadow(start, -lightDir, 0, 0.9);
				//NdotL *= s;

				fixed3 combined = combineNormal(normal, detailNormal * _DetailScale);
				fixed3 h = (lightDir - viewDir) / 2;
				fixed spec = pow(dot(combined, h), _Specular) * _Gloss;

				//Base color using directionality toward light, albedo, etc.
				fixed4 c;	
				c.rgb = _Color * lightCol * NdotL;

				//0 shadow = -1 NdotL
				//1 shadow = 1 NdotL
				//Add subsurface color for some range, having it ramp up then down again
				//from some start value to some end value
				fixed subsurfaceShadowRange = _ShadowColorEnd - _ShadowColorStart;
				fixed halfRange = subsurfaceShadowRange / 2 + _ShadowColorStart;
				//fixed3 subsurface = smoothstep(_ShadowColorStart, subsurfaceShadowRange / 2 + _ShadowColorStart, NdotL);
				//subsurface = max(subsurface, smoothstep(_ShadowColorStart + halfRange, _ShadowColorEnd, NdotL));
				fixed3 subsurface = smoothstep(_ShadowColorStart, _ShadowColorEnd, NdotL);
				fixed3 color = lerp(_ShadowColor.xyz, fixed3(1, 1, 1), subsurface);
				c.rgb *= color;
				//c.rgb += (1 - smoothstep(_ShadowColorStart, _ShadowColorEnd, magnitude)) * _ShadowColor;

				//Add specular at end
				c.rgb += (spec * _SpecularColor);
				//c.rgb = fixed3(NdotL, NdotL, NdotL);

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
					fixed3 detail = UnpackNormal(tex2D(_SurfaceDetail, i.uv)).xyz;
					return simpleLambert(rayHitPoint, n, detail, viewDir, i.lPos);
				}
			}
			ENDCG
		}
	}
}
