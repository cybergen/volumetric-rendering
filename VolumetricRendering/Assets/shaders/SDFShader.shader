﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/SDFShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MinDistance("Min Distance", float) = 0.01
		_Color("Sphere Color", Color) = (1, 0, 0)
		_Specular("Specular Power", Range(0, 64)) = 0
		_Gloss("Gloss", Range(0, 10)) = 0
		_CenterOne("Center One", Vector) = (0, 0, 0)
		_RadiusOne("Radius One", float) = 0.25
		_CenterTwo("Center Two", Vector) = (0, 0, 0)
		_RadiusTwo("Radius Two", float) = 0.25
		_CenterTwoDest("Center Two Dest", Vector) = (0, 0, 0)
		_SoftShadowPower("Shadow Edge", float) = 0.0
		_TimeMultiplier("Time Multiplier", float) = 1.0
		_CenterThree("Center Three", Vector) = (0, 0, 0)
		_RadiusThree("Radius Three", float) = 0.25
		_RadiusThreeDest("Radius Three Dest", float) = 0.25
		_TorusInfo("Torus Data", Vector) = (0.5, 0.75, 0)
		_SpecularColor("Spec Color", Color) = (1, 1, 1)
		_ReverseRimPower("Reverse Rim Power", float) = 0
		_ReverseRimColor("Reverse Rim Color", Color) = (1, 1, 1)
		_RimPower("Rim Power", float) = 0
		_RimColor("Rim Color", Color) = (1, 1, 1)
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
				float3 wPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _MinDistance;
			fixed3 _Color;
			float _Specular;
			float _Gloss;
			float3 _CenterOne;
			float _RadiusOne;
			float3 _CenterTwo;
			float3 _CenterTwoDest;
			float _RadiusTwo;
			float _TimeMultiplier;
			float _SoftShadowPower;
			float3 _CenterThree;
			float _RadiusThree;
			float _RadiusThreeDest;
			float3 _TorusInfo;
			float3 _SpecularColor;
			float _ReverseRimPower;
			float3 _ReverseRimColor;
			float _RimPower;
			float3 _RimColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			float unionRound(float a, float b, float r)
			{
				float2 u = max(float2(r - a, r - b), float2(0, 0));
				return max(r, min(a, b)) - length(u);				
			}

			float smoothMin(float a, float b, float k)
			{
				a = pow(a, k);
				b = pow(b, k);
				return pow((a * b) / (a + b), 1.0/k);
			}

			float torus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz)-t.x,p.y);
				return length(q)-t.y;
			}

			float map(float3 p)
			{
				float s = sin(_Time * _TimeMultiplier);
				s = s * 0.5 + 0.5;
				float3 currentCenter = lerp(_CenterTwo, _CenterTwoDest, s);
				float currentRadiusThree = lerp(_RadiusThree, _RadiusThreeDest, 1-s);
				float distOne = distance(p, _CenterOne) - _RadiusOne;
				float distTwo = distance(p, currentCenter) - _RadiusTwo;
				float distThree = distance(p, _CenterThree) - currentRadiusThree;
				float dist = unionRound(distOne, distTwo, 0.1);
				float torusDist = torus(p, _TorusInfo.xy);
				dist = min(dist, torusDist);
				return max(dist, -distThree);
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

			fixed4 simpleLambert(fixed3 position, fixed3 normal, fixed3 viewDir)
			{
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				fixed3 lightCol = _LightColor0.rgb;

				fixed NdotL = max(dot(normal, lightDir), 0);

				//Self-shadow calculation
				fixed3 start = position + lightDir;
				float s = shadow(start, -lightDir, 0, 0.9);
				NdotL *= s;

				fixed3 h = (lightDir - viewDir) / 2;
				fixed spec = pow(dot(normal, h), _Specular) * _Gloss;
				//fixed spec = max(0, dot(normal, -viewDir)) * _Specular;
				if (NdotL <= 0)
				{
					spec = 0;
				}

				fixed4 c;
				//NdotL = NdotL * 0.5 + 0.5;
				c.rgb = _Color * lightCol * NdotL + (spec * _SpecularColor);//rgb;// * lightCol * NdotL + s;//_Color * lightCol * NdotL + s;
				c.a = 1;
				return c;
			}

			fixed4 reverseRimLight(fixed3 norm, fixed3 viewDir, fixed4 c)
			{
				fixed rim = max(0, dot(norm, -viewDir)) * _ReverseRimPower;
				c.rgb += rim * _ReverseRimColor;
				return c;
			}

			fixed4 rimLight(fixed3 norm, fixed3 viewDir, fixed4 c)
			{
				fixed rim = (1 - max(0, dot(norm, -viewDir))) * _RimPower;
				c.rgb += rim * _RimColor;
				return c;
			}

			fixed3 normal(fixed3 p)
			{
				const fixed eps = 0.01;

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
				const float steps = 36;			

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
				float3 worldPos = i.wPos;
				float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);
				float3 rayHitPoint = raymarchHit(worldPos, viewDir);

				if (rayHitPoint.x == -1) 
				{
					return fixed4(0, 0, 0, 0);
				}
				else 
				{
					fixed3 n = normal(rayHitPoint);
					fixed4 c = reverseRimLight(n, viewDir, simpleLambert(rayHitPoint, n, viewDir));
					c = rimLight(n, viewDir, c);					
					return c;
				}
			}
			ENDCG
		}
	}
}
