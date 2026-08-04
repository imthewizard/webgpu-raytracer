[format("rgba8")]
WTexture2D tex;

[shader("compute")]
[numthreads(16, 16, 1)]
void computeMain(uint3 thread_id : SV_DispatchThreadID)
{
	uint2 pixel = thread_id.xy;

	tex.Store(pixel, float4(0.0, 1.0, 1.0, 1.0));
}
