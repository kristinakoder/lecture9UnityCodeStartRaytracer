#ifndef HELPER_FUNCTIONS_HLSL
#define HELPER_FUNCTIONS_HLSL

float3 unit_vector(const float3 vec)
{
    return vec / length(vec);
}

float3 reflect(const float3 v, const float3 n)
{
    return v - 2.f * dot(v, n) * n;
}

bool refract(const float3 v, const float3 n, const float ni_over_nt, out float3 refracted)
{
    const float3 uv = unit_vector(v);
    const float dt = dot(uv, n);
    const float discriminant = 1.0f - ni_over_nt * ni_over_nt * (1.f - dt * dt);
    if (discriminant > 0)
    {
        refracted = ni_over_nt * (uv - n * dt) - n * sqrt(discriminant);
        return true;
    }

    return false;
}

float schlick(const float cosine, const float ref_idx)
{
    float rx = (1.f - ref_idx) / (1.f + ref_idx);
    rx *= rx;
    return rx + (1.f - rx) * pow(1.f - cosine, 5);
}

float square_length(float3 vec)
{
    return vec.x * vec.x
        + vec.y * vec.y
        + vec.z * vec.z;
}

float square_length(float2 vec)
{
    return vec.x * vec.x
        + vec.y * vec.y;
}

float fract(const float x)
{
    return x - floor(x);
}

float2 fract(const float2 f)
{
    return float2(f.x - floor(f.x), f.y - floor(f.y));
}

float3 fract(const float3 f)
{
    return float3(f.x - floor(f.x), f.y - floor(f.y), f.z - floor(f.z));
}

float4 fract(const float4 f)
{
    return float4(f.x - floor(f.x), f.y - floor(f.y), f.z - floor(f.z), f.w - floor(f.w));
}

#endif
