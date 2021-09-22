Shader "DistanceFade"
{
    Properties
    {
        [NoScaleOffset] _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (0, 0, 0, 0)
        [NoScaleOffset]_MetallicGlossMap("Metallic Map", 2D) = "white" {}
        _Metallic("Metallic", Range(0, 1)) = 0
        _Smoothness("Smoothness", Range(0, 1)) = 0
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "white" {}
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}
        _EmissionColor("Emissive Color", Color) = (0, 0, 0, 0)
        [ToggleUI]_FadeToggle("Fade Enabled", Float) = 1
        Float_FadeOffset("Fade Offset", Float) = 0
        Float_FadeRange("Fade Range", Float) = 0
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue" = "Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

        // Render State
        ZWrite On
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile _ DOTS_INSTANCING_ON
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
    #pragma multi_compile _ SHADOWS_SHADOWMASK
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float3 normalWS;
        float4 tangentWS;
        float4 texCoord0;
        float3 viewDirectionWS;
        #if defined(LIGHTMAP_ON)
        float2 lightmapUV;
        #endif
        #if !defined(LIGHTMAP_ON)
        float3 sh;
        #endif
        float4 fogFactorAndVertexLight;
        float4 shadowCoord;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 TangentSpaceNormal;
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float3 interp1 : TEXCOORD1;
        float4 interp2 : TEXCOORD2;
        float4 interp3 : TEXCOORD3;
        float3 interp4 : TEXCOORD4;
        #if defined(LIGHTMAP_ON)
        float2 interp5 : TEXCOORD5;
        #endif
        #if !defined(LIGHTMAP_ON)
        float3 interp6 : TEXCOORD6;
        #endif
        float4 interp7 : TEXCOORD7;
        float4 interp8 : TEXCOORD8;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyz = input.normalWS;
        output.interp2.xyzw = input.tangentWS;
        output.interp3.xyzw = input.texCoord0;
        output.interp4.xyz = input.viewDirectionWS;
        #if defined(LIGHTMAP_ON)
        output.interp5.xy = input.lightmapUV;
        #endif
        #if !defined(LIGHTMAP_ON)
        output.interp6.xyz = input.sh;
        #endif
        output.interp7.xyzw = input.fogFactorAndVertexLight;
        output.interp8.xyzw = input.shadowCoord;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.normalWS = input.interp1.xyz;
        output.tangentWS = input.interp2.xyzw;
        output.texCoord0 = input.interp3.xyzw;
        output.viewDirectionWS = input.interp4.xyz;
        #if defined(LIGHTMAP_ON)
        output.lightmapUV = input.interp5.xy;
        #endif
        #if !defined(LIGHTMAP_ON)
        output.sh = input.interp6.xyz;
        #endif
        output.fogFactorAndVertexLight = input.interp7.xyzw;
        output.shadowCoord = input.interp8.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float3 NormalTS;
    float3 Emission;
    float Metallic;
    float Smoothness;
    float Occlusion;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    UnityTexture2D _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0 = UnityBuildTexture2DStructNoScale(_BumpMap);
    float4 _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.tex, _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_R_4 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.r;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_G_5 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.g;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_B_6 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.b;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_A_7 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.a;
    UnityTexture2D _Property_016c2e7779f54743b280f5b81bf56425_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
    float4 _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0 = SAMPLE_TEXTURE2D(_Property_016c2e7779f54743b280f5b81bf56425_Out_0.tex, _Property_016c2e7779f54743b280f5b81bf56425_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_R_4 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.r;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_G_5 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.g;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_B_6 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.b;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_A_7 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.a;
    float4 _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0 = _EmissionColor;
    float4 _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2;
    Unity_Multiply_float(_SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0, _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0, _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2);
    UnityTexture2D _Property_f365b39d3c064951b9c771910c2ff3a7_Out_0 = UnityBuildTexture2DStructNoScale(_MetallicGlossMap);
    float4 _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f365b39d3c064951b9c771910c2ff3a7_Out_0.tex, _Property_f365b39d3c064951b9c771910c2ff3a7_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_R_4 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.r;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_G_5 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.g;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_B_6 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.b;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_A_7 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.a;
    float _Property_7b323a9267d94d9b9d7b0474f2c7ddc3_Out_0 = _Metallic;
    float4 _Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2;
    Unity_Multiply_float(_SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0, (_Property_7b323a9267d94d9b9d7b0474f2c7ddc3_Out_0.xxxx), _Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2);
    float _Property_b707258b3bd842c1b1712a87018f0643_Out_0 = _Smoothness;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.NormalTS = (_SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.xyz);
    surface.Emission = (_Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2.xyz);
    surface.Metallic = (_Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2).x;
    surface.Smoothness = _Property_b707258b3bd842c1b1712a87018f0643_Out_0;
    surface.Occlusion = 1;
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "GBuffer"
    Tags
    {
        "LightMode" = "UniversalGBuffer"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile _ DOTS_INSTANCING_ON
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
    #pragma multi_compile _ _GBUFFER_NORMALS_OCT
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_GBUFFER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float3 normalWS;
        float4 tangentWS;
        float4 texCoord0;
        float3 viewDirectionWS;
        #if defined(LIGHTMAP_ON)
        float2 lightmapUV;
        #endif
        #if !defined(LIGHTMAP_ON)
        float3 sh;
        #endif
        float4 fogFactorAndVertexLight;
        float4 shadowCoord;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 TangentSpaceNormal;
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float3 interp1 : TEXCOORD1;
        float4 interp2 : TEXCOORD2;
        float4 interp3 : TEXCOORD3;
        float3 interp4 : TEXCOORD4;
        #if defined(LIGHTMAP_ON)
        float2 interp5 : TEXCOORD5;
        #endif
        #if !defined(LIGHTMAP_ON)
        float3 interp6 : TEXCOORD6;
        #endif
        float4 interp7 : TEXCOORD7;
        float4 interp8 : TEXCOORD8;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyz = input.normalWS;
        output.interp2.xyzw = input.tangentWS;
        output.interp3.xyzw = input.texCoord0;
        output.interp4.xyz = input.viewDirectionWS;
        #if defined(LIGHTMAP_ON)
        output.interp5.xy = input.lightmapUV;
        #endif
        #if !defined(LIGHTMAP_ON)
        output.interp6.xyz = input.sh;
        #endif
        output.interp7.xyzw = input.fogFactorAndVertexLight;
        output.interp8.xyzw = input.shadowCoord;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.normalWS = input.interp1.xyz;
        output.tangentWS = input.interp2.xyzw;
        output.texCoord0 = input.interp3.xyzw;
        output.viewDirectionWS = input.interp4.xyz;
        #if defined(LIGHTMAP_ON)
        output.lightmapUV = input.interp5.xy;
        #endif
        #if !defined(LIGHTMAP_ON)
        output.sh = input.interp6.xyz;
        #endif
        output.fogFactorAndVertexLight = input.interp7.xyzw;
        output.shadowCoord = input.interp8.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float3 NormalTS;
    float3 Emission;
    float Metallic;
    float Smoothness;
    float Occlusion;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    UnityTexture2D _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0 = UnityBuildTexture2DStructNoScale(_BumpMap);
    float4 _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.tex, _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_R_4 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.r;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_G_5 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.g;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_B_6 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.b;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_A_7 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.a;
    UnityTexture2D _Property_016c2e7779f54743b280f5b81bf56425_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
    float4 _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0 = SAMPLE_TEXTURE2D(_Property_016c2e7779f54743b280f5b81bf56425_Out_0.tex, _Property_016c2e7779f54743b280f5b81bf56425_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_R_4 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.r;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_G_5 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.g;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_B_6 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.b;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_A_7 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.a;
    float4 _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0 = _EmissionColor;
    float4 _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2;
    Unity_Multiply_float(_SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0, _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0, _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2);
    UnityTexture2D _Property_f365b39d3c064951b9c771910c2ff3a7_Out_0 = UnityBuildTexture2DStructNoScale(_MetallicGlossMap);
    float4 _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f365b39d3c064951b9c771910c2ff3a7_Out_0.tex, _Property_f365b39d3c064951b9c771910c2ff3a7_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_R_4 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.r;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_G_5 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.g;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_B_6 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.b;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_A_7 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.a;
    float _Property_7b323a9267d94d9b9d7b0474f2c7ddc3_Out_0 = _Metallic;
    float4 _Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2;
    Unity_Multiply_float(_SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0, (_Property_7b323a9267d94d9b9d7b0474f2c7ddc3_Out_0.xxxx), _Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2);
    float _Property_b707258b3bd842c1b1712a87018f0643_Out_0 = _Smoothness;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.NormalTS = (_SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.xyz);
    surface.Emission = (_Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2.xyz);
    surface.Metallic = (_Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2).x;
    surface.Smoothness = _Property_b707258b3bd842c1b1712a87018f0643_Out_0;
    surface.Occlusion = 1;
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "ShadowCaster"
    Tags
    {
        "LightMode" = "ShadowCaster"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite On
    ColorMask 0

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma multi_compile_instancing
    #pragma multi_compile _ DOTS_INSTANCING_ON
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "DepthOnly"
    Tags
    {
        "LightMode" = "DepthOnly"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite On
    ColorMask 0

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma multi_compile_instancing
    #pragma multi_compile _ DOTS_INSTANCING_ON
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "DepthNormals"
    Tags
    {
        "LightMode" = "DepthNormals"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite On

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma multi_compile_instancing
    #pragma multi_compile _ DOTS_INSTANCING_ON
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float3 normalWS;
        float4 tangentWS;
        float4 texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 TangentSpaceNormal;
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float3 interp1 : TEXCOORD1;
        float4 interp2 : TEXCOORD2;
        float4 interp3 : TEXCOORD3;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyz = input.normalWS;
        output.interp2.xyzw = input.tangentWS;
        output.interp3.xyzw = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.normalWS = input.interp1.xyz;
        output.tangentWS = input.interp2.xyzw;
        output.texCoord0 = input.interp3.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 NormalTS;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0 = UnityBuildTexture2DStructNoScale(_BumpMap);
    float4 _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.tex, _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_R_4 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.r;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_G_5 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.g;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_B_6 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.b;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_A_7 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.a;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.NormalTS = (_SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.xyz);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "Meta"
    Tags
    {
        "LightMode" = "Meta"
    }

        // Render State
        Cull Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        float4 uv2 : TEXCOORD2;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float4 texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float4 interp1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyzw = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.texCoord0 = input.interp1.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float3 Emission;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    UnityTexture2D _Property_016c2e7779f54743b280f5b81bf56425_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
    float4 _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0 = SAMPLE_TEXTURE2D(_Property_016c2e7779f54743b280f5b81bf56425_Out_0.tex, _Property_016c2e7779f54743b280f5b81bf56425_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_R_4 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.r;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_G_5 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.g;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_B_6 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.b;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_A_7 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.a;
    float4 _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0 = _EmissionColor;
    float4 _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2;
    Unity_Multiply_float(_SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0, _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0, _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2);
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.Emission = (_Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2.xyz);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

    ENDHLSL
}
Pass
{
        // Name: <None>
        Tags
        {
            "LightMode" = "Universal2D"
        }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
    #pragma exclude_renderers gles gles3 glcore
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float4 texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float4 interp1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyzw = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.texCoord0 = input.interp1.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

    ENDHLSL
}
    }
        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue" = "Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
    #pragma only_renderers gles gles3 glcore d3d11
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
    #pragma multi_compile _ SHADOWS_SHADOWMASK
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float3 normalWS;
        float4 tangentWS;
        float4 texCoord0;
        float3 viewDirectionWS;
        #if defined(LIGHTMAP_ON)
        float2 lightmapUV;
        #endif
        #if !defined(LIGHTMAP_ON)
        float3 sh;
        #endif
        float4 fogFactorAndVertexLight;
        float4 shadowCoord;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 TangentSpaceNormal;
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float3 interp1 : TEXCOORD1;
        float4 interp2 : TEXCOORD2;
        float4 interp3 : TEXCOORD3;
        float3 interp4 : TEXCOORD4;
        #if defined(LIGHTMAP_ON)
        float2 interp5 : TEXCOORD5;
        #endif
        #if !defined(LIGHTMAP_ON)
        float3 interp6 : TEXCOORD6;
        #endif
        float4 interp7 : TEXCOORD7;
        float4 interp8 : TEXCOORD8;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyz = input.normalWS;
        output.interp2.xyzw = input.tangentWS;
        output.interp3.xyzw = input.texCoord0;
        output.interp4.xyz = input.viewDirectionWS;
        #if defined(LIGHTMAP_ON)
        output.interp5.xy = input.lightmapUV;
        #endif
        #if !defined(LIGHTMAP_ON)
        output.interp6.xyz = input.sh;
        #endif
        output.interp7.xyzw = input.fogFactorAndVertexLight;
        output.interp8.xyzw = input.shadowCoord;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.normalWS = input.interp1.xyz;
        output.tangentWS = input.interp2.xyzw;
        output.texCoord0 = input.interp3.xyzw;
        output.viewDirectionWS = input.interp4.xyz;
        #if defined(LIGHTMAP_ON)
        output.lightmapUV = input.interp5.xy;
        #endif
        #if !defined(LIGHTMAP_ON)
        output.sh = input.interp6.xyz;
        #endif
        output.fogFactorAndVertexLight = input.interp7.xyzw;
        output.shadowCoord = input.interp8.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float3 NormalTS;
    float3 Emission;
    float Metallic;
    float Smoothness;
    float Occlusion;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    UnityTexture2D _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0 = UnityBuildTexture2DStructNoScale(_BumpMap);
    float4 _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.tex, _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_R_4 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.r;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_G_5 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.g;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_B_6 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.b;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_A_7 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.a;
    UnityTexture2D _Property_016c2e7779f54743b280f5b81bf56425_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
    float4 _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0 = SAMPLE_TEXTURE2D(_Property_016c2e7779f54743b280f5b81bf56425_Out_0.tex, _Property_016c2e7779f54743b280f5b81bf56425_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_R_4 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.r;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_G_5 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.g;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_B_6 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.b;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_A_7 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.a;
    float4 _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0 = _EmissionColor;
    float4 _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2;
    Unity_Multiply_float(_SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0, _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0, _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2);
    UnityTexture2D _Property_f365b39d3c064951b9c771910c2ff3a7_Out_0 = UnityBuildTexture2DStructNoScale(_MetallicGlossMap);
    float4 _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f365b39d3c064951b9c771910c2ff3a7_Out_0.tex, _Property_f365b39d3c064951b9c771910c2ff3a7_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_R_4 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.r;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_G_5 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.g;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_B_6 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.b;
    float _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_A_7 = _SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0.a;
    float _Property_7b323a9267d94d9b9d7b0474f2c7ddc3_Out_0 = _Metallic;
    float4 _Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2;
    Unity_Multiply_float(_SampleTexture2D_d886f7b6848a41b28617fd5d6a123d23_RGBA_0, (_Property_7b323a9267d94d9b9d7b0474f2c7ddc3_Out_0.xxxx), _Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2);
    float _Property_b707258b3bd842c1b1712a87018f0643_Out_0 = _Smoothness;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.NormalTS = (_SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.xyz);
    surface.Emission = (_Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2.xyz);
    surface.Metallic = (_Multiply_8a0a297ede254f2ebe4d99bd8c29ebd4_Out_2).x;
    surface.Smoothness = _Property_b707258b3bd842c1b1712a87018f0643_Out_0;
    surface.Occlusion = 1;
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "ShadowCaster"
    Tags
    {
        "LightMode" = "ShadowCaster"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite On
    ColorMask 0

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
    #pragma only_renderers gles gles3 glcore d3d11
    #pragma multi_compile_instancing
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "DepthOnly"
    Tags
    {
        "LightMode" = "DepthOnly"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite On
    ColorMask 0

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
    #pragma only_renderers gles gles3 glcore d3d11
    #pragma multi_compile_instancing
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "DepthNormals"
    Tags
    {
        "LightMode" = "DepthNormals"
    }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite On

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
    #pragma only_renderers gles gles3 glcore d3d11
    #pragma multi_compile_instancing
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float3 normalWS;
        float4 tangentWS;
        float4 texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 TangentSpaceNormal;
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float3 interp1 : TEXCOORD1;
        float4 interp2 : TEXCOORD2;
        float4 interp3 : TEXCOORD3;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyz = input.normalWS;
        output.interp2.xyzw = input.tangentWS;
        output.interp3.xyzw = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.normalWS = input.interp1.xyz;
        output.tangentWS = input.interp2.xyzw;
        output.texCoord0 = input.interp3.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 NormalTS;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0 = UnityBuildTexture2DStructNoScale(_BumpMap);
    float4 _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0 = SAMPLE_TEXTURE2D(_Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.tex, _Property_fab1fb0285494bd2bec5b834b45baf65_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_R_4 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.r;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_G_5 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.g;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_B_6 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.b;
    float _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_A_7 = _SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.a;
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.NormalTS = (_SampleTexture2D_5f005cc2f0014a62bd8e5ea62b06d5dc_RGBA_0.xyz);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

    ENDHLSL
}
Pass
{
    Name "Meta"
    Tags
    {
        "LightMode" = "Meta"
    }

        // Render State
        Cull Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
    #pragma only_renderers gles gles3 glcore d3d11
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        float4 uv2 : TEXCOORD2;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float4 texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float4 interp1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyzw = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.texCoord0 = input.interp1.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float3 Emission;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    UnityTexture2D _Property_016c2e7779f54743b280f5b81bf56425_Out_0 = UnityBuildTexture2DStructNoScale(_EmissionMap);
    float4 _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0 = SAMPLE_TEXTURE2D(_Property_016c2e7779f54743b280f5b81bf56425_Out_0.tex, _Property_016c2e7779f54743b280f5b81bf56425_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_R_4 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.r;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_G_5 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.g;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_B_6 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.b;
    float _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_A_7 = _SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0.a;
    float4 _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0 = _EmissionColor;
    float4 _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2;
    Unity_Multiply_float(_SampleTexture2D_fd3185b86a03461a998d8ed9ed1f0053_RGBA_0, _Property_34df28b6c8c74981b0604e59fd4118f0_Out_0, _Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2);
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.Emission = (_Multiply_0bb1713fa4c4421ab5409f86e8c1253a_Out_2.xyz);
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

    ENDHLSL
}
Pass
{
        // Name: <None>
        Tags
        {
            "LightMode" = "Universal2D"
        }

        // Render State
        Cull Back
    Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
    ZTest LEqual
    ZWrite Off

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
    #pragma only_renderers gles gles3 glcore d3d11
    #pragma multi_compile_instancing
    #pragma vertex vert
    #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>

        // Defines
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 uv0 : TEXCOORD0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : INSTANCEID_SEMANTIC;
        #endif
    };
    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float3 positionWS;
        float4 texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };
    struct SurfaceDescriptionInputs
    {
        float3 WorldSpacePosition;
        float4 ScreenPosition;
        float4 uv0;
    };
    struct VertexDescriptionInputs
    {
        float3 ObjectSpaceNormal;
        float3 ObjectSpaceTangent;
        float3 ObjectSpacePosition;
    };
    struct PackedVaryings
    {
        float4 positionCS : SV_POSITION;
        float3 interp0 : TEXCOORD0;
        float4 interp1 : TEXCOORD1;
        #if UNITY_ANY_INSTANCING_ENABLED
        uint instanceID : CUSTOM_INSTANCE_ID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
        #endif
    };

        PackedVaryings PackVaryings(Varyings input)
    {
        PackedVaryings output;
        output.positionCS = input.positionCS;
        output.interp0.xyz = input.positionWS;
        output.interp1.xyzw = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }
    Varyings UnpackVaryings(PackedVaryings input)
    {
        Varyings output;
        output.positionCS = input.positionCS;
        output.positionWS = input.interp0.xyz;
        output.texCoord0 = input.interp1.xyzw;
        #if UNITY_ANY_INSTANCING_ENABLED
        output.instanceID = input.instanceID;
        #endif
        #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
        output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
        #endif
        #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
        output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        output.cullFace = input.cullFace;
        #endif
        return output;
    }

    // --------------------------------------------------
    // Graph

    // Graph Properties
    CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_TexelSize;
float4 _BaseColor;
float4 _MetallicGlossMap_TexelSize;
float _Metallic;
float _Smoothness;
float4 _BumpMap_TexelSize;
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;
float _FadeToggle;
float Float_FadeOffset;
float Float_FadeRange;
CBUFFER_END

// Object and Global properties
SAMPLER(SamplerState_Linear_Repeat);
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

// Graph Functions

void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
{
    Out = A * B;
}

void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
{
    RGBA = float4(R, G, B, A);
    RGB = float3(R, G, B);
    RG = float2(R, G);
}

void Unity_Subtract_float(float A, float B, out float Out)
{
    Out = A - B;
}

void Unity_Multiply_float(float A, float B, out float Out)
{
    Out = A * B;
}

void Unity_Clamp_float(float In, float Min, float Max, out float Out)
{
    Out = clamp(In, Min, Max);
}

void Unity_Branch_float(float Predicate, float True, float False, out float Out)
{
    Out = Predicate ? True : False;
}

// Graph Vertex
struct VertexDescription
{
    float3 Position;
    float3 Normal;
    float3 Tangent;
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
    VertexDescription description = (VertexDescription)0;
    description.Position = IN.ObjectSpacePosition;
    description.Normal = IN.ObjectSpaceNormal;
    description.Tangent = IN.ObjectSpaceTangent;
    return description;
}

// Graph Pixel
struct SurfaceDescription
{
    float3 BaseColor;
    float Alpha;
};

SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    UnityTexture2D _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
    float4 _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0 = SAMPLE_TEXTURE2D(_Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.tex, _Property_6a5b950cb3e1493d96732893d96d2a57_Out_0.samplerstate, IN.uv0.xy);
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_R_4 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.r;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_G_5 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.g;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_B_6 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.b;
    float _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_A_7 = _SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0.a;
    float4 _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0 = _BaseColor;
    float4 _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2;
    Unity_Multiply_float(_SampleTexture2D_a0ca6127f9624cadbcf36e687cbe7c93_RGBA_0, _Property_e6c1dc10dc084417bb8d0de2fc5afdda_Out_0, _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2);
    float _Split_ed2254b1ac854472bfebc398b73b45aa_R_1 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[0];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_G_2 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[1];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_B_3 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[2];
    float _Split_ed2254b1ac854472bfebc398b73b45aa_A_4 = _Multiply_c8ba895235c94a8cb972c70c69a9293d_Out_2[3];
    float4 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4;
    float3 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    float2 _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6;
    Unity_Combine_float(_Split_ed2254b1ac854472bfebc398b73b45aa_R_1, _Split_ed2254b1ac854472bfebc398b73b45aa_G_2, _Split_ed2254b1ac854472bfebc398b73b45aa_B_3, 0, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGBA_4, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5, _Combine_4c87c8795b9245828c4eefcf90c34e4b_RG_6);
    float _Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0 = _FadeToggle;
    float4 _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0 = IN.ScreenPosition;
    float _Split_93ceb03935df49038a0d0013416902dd_R_1 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[0];
    float _Split_93ceb03935df49038a0d0013416902dd_G_2 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[1];
    float _Split_93ceb03935df49038a0d0013416902dd_B_3 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[2];
    float _Split_93ceb03935df49038a0d0013416902dd_A_4 = _ScreenPosition_72e969e98c3d4d8895b492ef2c30c023_Out_0[3];
    float _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0 = Float_FadeOffset;
    float _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2;
    Unity_Subtract_float(_Split_93ceb03935df49038a0d0013416902dd_A_4, _Property_6187eec88b6246d18c59b2a7fd509b21_Out_0, _Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2);
    float _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0 = Float_FadeRange;
    float _Multiply_04d02f668c67438f8b224599af04fea8_Out_2;
    Unity_Multiply_float(_Subtract_ac1ec4a85ae74edb9bde7a258edec11b_Out_2, _Property_a2e7ba8f9a8b4237a6b2d1e7806ce337_Out_0, _Multiply_04d02f668c67438f8b224599af04fea8_Out_2);
    float _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3;
    Unity_Clamp_float(_Multiply_04d02f668c67438f8b224599af04fea8_Out_2, 0, 1, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3);
    float _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    Unity_Branch_float(_Property_66b0b9e995584bf28eb7f35aa33eb8ea_Out_0, _Clamp_5f5f412522f44ae4bb2598d414b868a6_Out_3, 1, _Branch_386dc66823004c35ae9e589544acd190_Out_3);
    surface.BaseColor = _Combine_4c87c8795b9245828c4eefcf90c34e4b_RGB_5;
    surface.Alpha = _Branch_386dc66823004c35ae9e589544acd190_Out_3;
    return surface;
}

// --------------------------------------------------
// Build Graph Inputs

VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

    output.ObjectSpaceNormal = input.normalOS;
    output.ObjectSpaceTangent = input.tangentOS.xyz;
    output.ObjectSpacePosition = input.positionOS;

    return output;
}
    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





    output.WorldSpacePosition = input.positionWS;
    output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
    output.uv0 = input.texCoord0;
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

    // --------------------------------------------------
    // Main

    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

    ENDHLSL
}
    }
        CustomEditor "ShaderGraph.PBRMasterGUI"
        FallBack "Hidden/Shader Graph/FallbackError"
}