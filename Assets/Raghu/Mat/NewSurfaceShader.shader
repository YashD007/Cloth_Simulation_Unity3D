Shader "Custom/URP_ShirtMaterial"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _OpacityMask ("Opacity Mask", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _ORMMap ("ORM Map", 2D) = "white" {} // Stores Occlusion (R), Roughness (G), Metallic (B)
        _EmissiveColor ("Emissive Color", Color) = (0,0,0,1)
        _AlphaCutoff ("Alpha Cutoff", Range(0,1)) = 0.3
        _StrandThickness ("Strand Thickness", Range(0.1,1)) = 0.5
        _SpecularTint ("Specular Tint", Color) = (1,1,1,1)
        _AnisotropicStrength ("Anisotropic Strength", Range(0,1)) = 0.5
        _DoubleSided ("Double Sided", Float) = 0
        _Transmission ("Transmission", Range(0,1)) = 0.5
        _Brightness ("Brightness", Range(0,2)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        LOD 300
        Cull [_DoubleSided]
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 tangentWS : TANGENT;
                float3 bitangentWS : BITANGENT;
                float3 viewDirWS : TEXCOORD1;
            };
            
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_OpacityMask); SAMPLER(sampler_OpacityMask);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_ORMMap); SAMPLER(sampler_ORMMap);
            
            float4 _EmissiveColor;
            float _AlphaCutoff;
            float _StrandThickness;
            float4 _SpecularTint;
            float _AnisotropicStrength;
            float _DoubleSided;
            float _Transmission;
            float _Brightness;
            
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS) * (_DoubleSided * 2 - 1);
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz);
                OUT.bitangentWS = cross(OUT.normalWS, OUT.tangentWS) * IN.tangentOS.w;
                OUT.viewDirWS = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(IN.positionOS));
                return OUT;
            }
            
            half4 frag (Varyings IN) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Brightness;
                half alpha = SAMPLE_TEXTURE2D(_OpacityMask, sampler_OpacityMask, IN.uv).r;
                alpha = smoothstep(_AlphaCutoff - _StrandThickness * 0.1, _AlphaCutoff + _StrandThickness * 0.1, alpha);
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
                half3 ORM = SAMPLE_TEXTURE2D(_ORMMap, sampler_ORMMap, IN.uv).rgb;
                
                float3x3 tangentToWorld = float3x3(IN.tangentWS, IN.bitangentWS, IN.normalWS);
                half3 normalWS = normalize(mul(normalTS, tangentToWorld));
                
                half occlusion = ORM.r;
                half roughness = ORM.g;
                half metallic = ORM.b;
                
                half3 reflectance = lerp(half3(0.04, 0.04, 0.04), baseColor.rgb, metallic);
                half3 specular = reflectance * (1.0 - roughness) * _SpecularTint.rgb;
                
                float anisotropicEffect = dot(normalWS, IN.tangentWS) * _AnisotropicStrength;
                specular *= anisotropicEffect;
                
                half3 transmissionEffect = baseColor.rgb * _Transmission * saturate(dot(normalWS, IN.viewDirWS));
                
                half3 finalColor = ((baseColor.rgb * occlusion) + specular + _EmissiveColor.rgb + transmissionEffect) * _Brightness;
                
                clip(alpha - _AlphaCutoff);
                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }
}
