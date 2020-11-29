Texture2D myTexture : register(t0);
SamplerState samLinear : register(s0);

cbuffer cbp : register(b1)
{
	float4 fColor;
};

float4 PShader(float4 position : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET
{
	float4 frag= fColor; // float4(1,0,0,1);
	return frag;
}
