Shader "Skybox/Fisheye"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Texture", 2D) = "white" {}
        [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
        _NullColor("Null Color", Color) = (.0, .0, .0, .0)
        
        _RotationX("Rotation X", Range(0, 360)) = 0
        _RotationY("Rotation Y", Range(0, 360)) = 0
        _RotationZ("Rotation Z", Range(0, 360)) = 0
        
        _FOV("FOV", Range(0, 360)) = 180.0
        _ScaleX("Scale X", Range(0, 1)) = 0.5
        _ScaleY("Scale Y", Range(0, 1)) = 0.5
        _CenterX("Center X", Range(0, 1)) = 0.5
        _CenterY("Center Y", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass {
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            half _Exposure;
            half4 _NullColor;
            float _RotationX;
            float _RotationY;
            float _RotationZ;
            float _FOV;
            float _ScaleX;
            float _ScaleY;
            float _CenterX;
            float _CenterY;
            
            float3 RotateAroundXYZInDegrees (float3 vertex, float3 degrees)
            {
                float3 alpha = degrees * UNITY_PI / 180.0;
                float3 sina, cosa;
                sincos(alpha, sina, cosa);
                
                float3x3 rx = float3x3(
                    1.0,    0.0,     0.0,
                    0.0, cosa.x, -sina.x,
                    0.0, sina.x,  cosa.x);
                float3x3 ry = float3x3(
                    cosa.y,  0.0, sina.y,
                    0.0,     1.0,    0.0,
                    -sina.y, 0.0, cosa.y);
                float3x3 rz = float3x3(
                    cosa.z, -sina.z,  0.0,
                    sina.z,  cosa.z,  0.0,
                    0.0,        0.0,  1.0); 
                
                float3x3 m = mul(ry, mul(rx, rz));
                return mul(m, vertex);
            }
		
            struct appdata_t {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct v2f {
                float4 vertex : SV_POSITION;
                float3 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            v2f vert(appdata_t v) {
                v2f o;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 rotated = RotateAroundXYZInDegrees(v.vertex, float3(_RotationX, _RotationY, _RotationZ));
                o.vertex = UnityObjectToClipPos(rotated);
                o.texcoord = v.vertex.xyz;
                return o;
            }
            
            half4 frag(v2f i) : SV_Target {
                
                float invTmax = 1 / (UNITY_PI / 360 * _FOV);
                float3 direction = normalize(-i.texcoord);
                
                // Out of FOV
                float theta = acos(dot(float3(.0, .0, -1.0), direction));
                if ( ((theta * 180.0) / UNITY_PI) > _FOV / 2) {
                    return _NullColor;
                }
                
                float2 st = normalize(i.texcoord.xy) * acos(-direction.z) * invTmax;
                st.x *= _ScaleX;
                st.y *= _ScaleY;
                st.x += _CenterX;
                st.y += _CenterY;
                
                #if !defined(SHADER_API_OPENGL)
                half4 tex = tex2Dlod(_MainTex, float4(st, 0.0, 0.0));
                #else // Memo: OpenGL not supported tex2Dlod.( Texture should be setting to generateMipMap = off. )
                half4 tex = tex2D(_MainTex, st);
                #endif

                half3 c = tex.rgb;
                c *= _Exposure;
                return half4(c, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack Off
}
