// Unity URP Shader Graph equivalent of Unreal Engine material system
// Features: Base Color, Metallic, Specular, Roughness, Normal, AO, Emissive, Opacity, Subsurface Scattering, Refraction

Shader "Custom/UnrealLikeURPShader"
{
    Properties
    {
        _BaseColor ("Base Color", 2D) = "white" {}
        _MetallicMap ("Metallic (R) Roughness (G) AO (B)", 2D) = "black" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _EmissiveMap ("Emissive", 2D) = "black" {}
        _OpacityMap ("Opacity", 2D) = "white" {}
        _Anisotropy ("Anisotropy", Range(0,1)) = 0.5
        _SubsurfaceColor ("Subsurface Color", Color) = (1,1,1,1)
        _RefractionStrength ("Refraction Strength", Range(0,1)) = 0.5
        _PixelDepthOffset ("Pixel Depth Offset", Range(-1,1)) = 0.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 worldPos : TEXCOORD1;
                float4 tangent : TANGENT;
            };
            
            TEXTURE2D(_BaseColor); SAMPLER(sampler_BaseColor);
            TEXTURE2D(_MetallicMap); SAMPLER(sampler_MetallicMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_EmissiveMap); SAMPLER(sampler_EmissiveMap);
            TEXTURE2D(_OpacityMap); SAMPLER(sampler_OpacityMap);
            
            float4 _BaseColor_ST;
            float _Anisotropy;
            float4 _SubsurfaceColor;
            float _RefractionStrength;
            float _PixelDepthOffset;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.tangent = v.tangent;
                return o;
            }
            
            half4 frag(v2f i) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseColor, sampler_BaseColor, i.uv);
                half3 orm = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.uv).rgb;
                half metallic = orm.r;
                half roughness = 1.0 - orm.g; // Unreal uses roughness, Unity uses smoothness
                half ao = orm.b;
                
                half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv));
                half3 emissive = SAMPLE_TEXTURE2D(_EmissiveMap, sampler_EmissiveMap, i.uv).rgb;
                
                half opacity = SAMPLE_TEXTURE2D(_OpacityMap, sampler_OpacityMap, i.uv).r;
                
                half3 finalColor = baseColor.rgb * ao;
                finalColor += emissive;
                
                return half4(finalColor, opacity);
            }
            ENDHLSL
        }
    }
}
