struct VertexOutput {
	float4 pos: SV_Position;
	float2 uv;
};

[shader("vertex")]
VertexOutput vertexMain(uint vertexID : SV_VertexID)
{
	VertexOutput out;

    float2 pos[3] = {
        float2( 0.0,  0.5),
        float2(-0.5, -0.5),
        float2( 0.5, -0.5)
    };
    float2 uv[3] = {
        float2(0.5, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };

	out.pos = float4(pos[vertexID], 0.0, 1.0);
	out.uv = uv[vertexID];

	return out;
}

[format("rgba8")]
Texture2D tex;
SamplerState tex_sampler;

[shader("fragment")]
float4 fragmentMain(VertexOutput input) : SV_Target
{
	// return float4(1.0, 0.0, 0.0, 1.0);
	return tex.Sample(tex_sampler, input.uv);
}
