Shader "Custom/СurvedField"
{
    Properties
    {
        _BaseTex ("Base Texture", 2D) = "white" {}
        _OverlayTex ("Overlay (Hex Grid)", 2D) = "white" {}
        _OverlayTint ("Overlay Tint", Color) = (1,1,1,1)
        _OverlayStrength ("Overlay Strength", Range(0,1)) = 1
        _OverlayScrollSpeed ("Overlay Scroll Speed", Vector) = (0.1, 0.1, 0, 0)

        _EdgeColor ("Edge Color", Color) = (0, 1, 1, 1)
        _EdgeWidth ("Edge Width", Range(0, 1)) = 0.1
        _EdgeFalloffRadius ("Edge Falloff Radius", Range(0, 1)) = 0.25
        _EdgeUVCenter ("Edge UV Center", Vector) = (0.5, 0.5, 0, 0)

        _Transparency ("Transparency", Range(0, 1)) = 0.5

        _BaseTex_ST ("Base Tiling/Offset", Vector) = (1,1,0,0)
        _OverlayTex_ST ("Overlay Tiling/Offset", Vector) = (1,1,0,0)

        _WaveCenter ("Wave Center (World)", Vector) = (0, 0, 0, 0)
        _WaveRadius ("Wave Radius", Range(0,10)) = 2
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Lighting Off
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _BaseTex;
            sampler2D _OverlayTex;
            float4 _BaseTex_ST;
            float4 _OverlayTex_ST;
            float4 _OverlayTint;
            float _OverlayStrength;
            float4 _OverlayScrollSpeed;

            float4 _EdgeColor;
            float _EdgeWidth;
            float _EdgeFalloffRadius;
            float4 _EdgeUVCenter;

            float _Transparency;

            float4 _WaveCenter;
            float _WaveRadius;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 localUV : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.localUV = TRANSFORM_TEX(v.uv, _BaseTex);
                return o;
            }

 fixed4 frag(v2f i) : SV_Target
{
    float2 worldUV = i.worldPos.xz;

    // Base texture
    float2 baseUV = worldUV * _BaseTex_ST.xy + _BaseTex_ST.zw;
    fixed4 baseCol = tex2D(_BaseTex, baseUV);

    // Overlay texture
    float2 overlayUV = worldUV * _OverlayTex_ST.xy + _OverlayTex_ST.zw;
    overlayUV += _Time.y * _OverlayScrollSpeed.xy;
    fixed4 overlayCol = tex2D(_OverlayTex, overlayUV) * _OverlayTint;
    overlayCol.a *= _OverlayStrength;

    // Edge effect: равномерная по дугам и прямым
    float2 edgeDist = min(i.localUV, 1.0 - i.localUV);
    float edgeDistToBorder = length(edgeDist);
    float edgeFactor = smoothstep(_EdgeWidth, _EdgeWidth + _EdgeFalloffRadius, edgeDistToBorder);
    edgeFactor = 1.0 - edgeFactor; // сильнее ближе к краю
    fixed4 edgeCol = _EdgeColor * edgeFactor;

    // Radial wave
    float dist = distance(i.worldPos, _WaveCenter.xyz);
    float radialFactor = 1.0 - smoothstep(0.0, _WaveRadius, dist);
    fixed4 waveCol = lerp(baseCol, overlayCol, overlayCol.a);
    waveCol.rgb = lerp(waveCol.rgb, _EdgeColor.rgb, radialFactor);

    // Combine edge + wave
    waveCol.rgb = lerp(waveCol.rgb, edgeCol.rgb, edgeFactor);

    waveCol.a = _Transparency;
    return waveCol;
}


            ENDCG
        }
    }

    FallBack "Diffuse"
}
