//
//  Shaders.metal
//  metaltest
//




#include <metal_stdlib>
using namespace metal;

#define lightDirection float3(1/1.73, 1/1.73, 1/1.73)

struct VertexUniforms {
    float4x4    projectionViewMatrix;
    float3x3    normalMatrix;
};

struct VertexInput {
    float3      position    [[ attribute(0) ]];
    float3      normal      [[ attribute(1) ]];
    float2      texcoord    [[ attribute(2) ]];
};
struct VertexOut {
    float4      position    [[ position ]];
    float3      normal;
    float2      texcoord;
};

vertex VertexOut lambertVertex(VertexInput in [[ stage_in ]],
                               constant VertexUniforms& uniforms [[ buffer(1) ]]) {
    VertexOut out;
    out.position = uniforms.projectionViewMatrix * float4(in.position, 1);
    out.texcoord = float2(in.texcoord.x, in.texcoord.y);
    out.normal = uniforms.normalMatrix * in.normal;
    return out;
}
fragment half4 fragmentLight(VertexOut in [[stage_in]], texture2d<half>  diffuseTexture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    float lt = saturate(dot(in.normal, lightDirection));
//    if (lt < 0.2) lt = 0.2;
    lt = lt * 0.8 + 0.2;
    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord))*lt;
    return color;
}
fragment half4 fragmentLightAdd(VertexOut in [[stage_in]], texture2d<half>  diffuseTexture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord));
    if (color.a < 0.5)
        discard_fragment();
    return color;
}
fragment half4 fragmentLightNonl(VertexOut in [[stage_in]], texture2d<half>  diffuseTexture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord));
    if (color.a < 0.5)
        discard_fragment();
    return color;
}

struct FragmentOut {
    half4 color0 [[ color(0) ]];
    half4 color1 [[ color(1) ]];
};
fragment FragmentOut fragmentShader(VertexOut in [[stage_in]],
                                    texture2d<half>  diffuseTexture [[ texture(0) ]],
                                    texture2d<half>  bloomTexture [[ texture(1) ]])
{
    constexpr sampler defaultSampler;
    FragmentOut out;
    float lt = saturate(dot(in.normal, lightDirection));
    if (lt < 0.5) lt = 0.5;
    half4 color =  half4(diffuseTexture.sample(defaultSampler, float2(in.texcoord))*lt);
    out.color0 = color;
    if (is_null_texture(bloomTexture)) {
        out.color1 = half4(0,0,0,0);
    } else {
        out.color1 = half4(1,0,0,1);
    }
    return out;
}



struct VertexInExplosion
{
    float4  position [[ position ]];
    float  size;
    float  len;
    float  gain;
    float  dummy;
};
struct VertexOutExplosion
{
    float4  position [[ position ]];
    float   size   [[ point_size ]];
    float   gain;
    float2  option;
};
vertex VertexOutExplosion lambertVertexExplosion(uint vid [[ vertex_id ]],
                                                 constant VertexInExplosion* vin  [[ buffer(0) ]],
                                                 constant VertexUniforms& uniforms [[ buffer(1) ]])
{
    VertexOutExplosion outVertex;
    float4 _p = vin[0].len * vin[vid].position;
    _p.w = 1;
    outVertex.position = uniforms.projectionViewMatrix * _p;
    float _s = vin[vid].size;
    outVertex.size = _s / outVertex.position.z * vin[0].gain;
    outVertex.gain = vin[0].gain;
    return outVertex;
};

fragment half4 fragmentLightExplosion(VertexOutExplosion vert [[stage_in]], float2 uv[[point_coord]], texture2d<half>  diffuseTexture [[ texture(0) ]])
{
    float2 uvPos = uv;
    constexpr sampler defaultSampler;
    half4 color =  diffuseTexture.sample(defaultSampler, float2(uvPos));
    color *= vert.gain;
    return color;
};


//bloom
kernel void computeShader(texture2d<float, access::read> source [[ texture(0) ]],
                          texture2d<float, access::read> mask [[ texture(1) ]],
                          texture2d<float, access::write> dest [[ texture(2) ]],
                          uint2 gid [[ thread_position_in_grid ]])
{
    float4 mk = mask.read(gid);
    if( mk.a > 0 ) {
//        mk.a = 0;
//        dest.write(source.read(gid) + mk, gid);
        dest.write(source.read(gid), gid);
    } else {
        dest.write(source.read(gid), gid);
    }
}
















