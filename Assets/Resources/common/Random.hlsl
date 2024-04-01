#ifndef RANDOM_HLSL
#define RANDOM_HLSL

#include "HelperFunctions.hlsl"

// Source
// http://www.gamedev.net/topic/592001-random-number-generation-based-on-time-in-hlsl/
// Supposedly from the NVidia Direct3D10 SDK
#define RANDOM_IA 16807u
#define RANDOM_IM 2147483647u
#define RANDOM_AM (1.0f/float(RANDOM_IM))
#define RANDOM_IQ 127773u
#define RANDOM_IR 2836u
#define RANDOM_MASK 123459876u
int random_x;

float random()
{
    random_x ^= RANDOM_MASK;
    const int k = random_x / RANDOM_IQ;
    random_x = RANDOM_IA * (random_x - k * RANDOM_IQ) - RANDOM_IR * k;
    if (random_x < 0) random_x += RANDOM_IM;
    const float ans = RANDOM_AM * random_x;
    random_x ^= RANDOM_MASK;
    return ans;
}

float random(const float low, const float high)
{
    const float v = random();
    return low * (1.0f - v) + high * v;
}

float2 random(const float2 low, const float2 high)
{
    const float2 v = float2(random(), random());
    return low * (1.0f - v) + high * v;
}

float3 random(const float3 low, const float3 high)
{
    const float3 v = float3(random(), random(), random());
    return low * (1.0f - v) + high * v;
}

float random_f_between_0_1()
{
    return random(0, 1);
}

float2 random_f2_between_0_1()
{
    return random(float2(0, 0), float2(1, 1));
}

float3 random_f3_between_0_1()
{
    return random(float3(0, 0, 0), float3(1, 1, 1));
}

float3 random_unit_sphere()
{
    float3 vec;
    do
    {
        vec = 2.0 * random_f3_between_0_1() - 1;
    }
    while (square_length(vec) >= 1.0);

    return vec;
}

float2 random_unit_circle()
{
    float2 vec;
    do
    {
        vec = 2.0 * random_f2_between_0_1() - 1;
    }
    while (square_length(vec) >= 1.0);

    return vec;
}

void set_seed(const int value)
{
    random_x = value;
    random();
}

#endif
