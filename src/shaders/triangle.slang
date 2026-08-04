struct VertexOutput {
	float4 pos: SV_Position;
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

	out.pos = float4(pos[vertexID], 0.0, 1.0);

	return out;
}

[shader("fragment")]
float4 fragmentMain(VertexOutput input) : SV_Target
{
	return float4(1.0, 0.0, 0.0, 1.0);
}
