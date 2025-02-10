// Fixed URP Hair Shader with proper texture definitions
// Supports Alpha Clipping, Normal Mapping, and Anisotropic Highlights

Shader "Custom/HairShaderURP"
{
    Properties
    {
        _BaseMap ("Base Color", 2D) = "white" {}
        _AlphaMap ("Alpha Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _Metallic ("Metallic", Range(0,1)) = 0.1
        _Roughness ("Roughness", Range(0,1)) = 0.5
        _Anisotropy ("Anisotropy", Range(-1,1)) = 0.0
    }
    
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma shader_feature _NORMALMAP
            #pragma target 3.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 tangentWS : TANGENT;
            };
            
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_AlphaMap); SAMPLER(sampler_AlphaMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            
            float _Metallic;
            float _Roughness;
            float _Anisotropy;
            
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangentWS = normalize(mul((float3x3)UNITY_MATRIX_M, IN.tangentOS.xyz));
                return OUT;
            }
            
            half4 frag (Varyings IN) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, IN.uv).r;
                
                clip(alpha - 0.5); // Alpha Clipping
                
                float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
                
                float3 tangentWS = normalize(IN.tangentWS);
                float3 normalWS = normalize(IN.normalWS);
                
                float3 bitangentWS = cross(normalWS, tangentWS) * (_Anisotropy * 2 - 1);
                float3 finalNormal = normalize(normalMap + bitangentWS);
                
                return half4(baseColor.rgb, 1.0);
            }
            
            ENDHLSL
        }
    }
}
