@binding(0) @group(0) var tex_0 : texture_2d<f32>;

@binding(1) @group(0) var tex_sampler_0 : sampler;

struct VertexOutput_0
{
    @builtin(position) pos_0 : vec4<f32>,
    @location(0) uv_0 : vec2<f32>,
};

@vertex
fn vertexMain(@builtin(vertex_index) vertexID_0 : u32) -> VertexOutput_0
{
    const _S1 : vec2<f32> = vec2<f32>(1.0f, -1.0f);
    const _S2 : vec2<f32> = vec2<f32>(-1.0f, 1.0f);
    const _S3 : vec2<f32> = vec2<f32>(1.0f, 1.0f);
    var pos_1 : array<vec2<f32>, i32(6)> = array<vec2<f32>, i32(6)>( vec2<f32>(-1.0f, -1.0f), _S1, _S2, _S2, _S1, _S3 );
    const _S4 : vec2<f32> = vec2<f32>(1.0f, 0.0f);
    const _S5 : vec2<f32> = vec2<f32>(0.0f, 1.0f);
    var uv_1 : array<vec2<f32>, i32(6)> = array<vec2<f32>, i32(6)>( vec2<f32>(0.0f, 0.0f), _S4, _S5, _S5, _S4, _S3 );
    var out_0 : VertexOutput_0;
    out_0.pos_0 = vec4<f32>(pos_1[vertexID_0], 0.0f, 1.0f);
    out_0.uv_0 = uv_1[vertexID_0];
    return out_0;
}

struct pixelOutput_0
{
    @location(0) output_0 : vec4<f32>,
};

struct pixelInput_0
{
    @location(0) uv_2 : vec2<f32>,
};

@fragment
fn fragmentMain( _S6 : pixelInput_0, @builtin(position) pos_2 : vec4<f32>) -> pixelOutput_0
{
    var _S7 : pixelOutput_0 = pixelOutput_0( (textureSample((tex_0), (tex_sampler_0), (_S6.uv_2))) );
    return _S7;
}

