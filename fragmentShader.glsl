
// Feature checks
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

// Uniforms

uniform float u_time;
uniform vec2 u_resolution;
uniform sampler2D u_buffer0;
uniform float u_memscale;

// Definitions

#define uv gl_FragCoord.xy/u_resolution.xy
#define MemHeight u_resolution.y/log(u_resolution.y)
#define NeighborCount 3
#define PI 3.14159265
#if defined(BUFFER_0)
#endif

// Structs

struct Dna
{
    vec4 divisionCondition;
    vec4 divisionMargin;
    vec2 sample0;
    vec2 sample1;
    vec2 sample2;
    vec2 sample3;
    vec4 sampleMod;
    vec4 waste;
};

// Functions

float random(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) *
        43758.5453123);
}

vec4 randomColor(vec2 st)
{
    return vec4(random(fract(sin(st)) * 71.), random(fract(sin(st)) * 93.), random(fract(sin(st)) * 29.), random(fract(sin(st)) * 61.));
}

vec2 AtoXY(float r)
{
    return vec2(cos(r), sin(r));
}

float XYtoA(vec2 xy)
{
    return atan(xy.y, xy.x);
}

vec4 getPixel(vec2 loc)
{
    return texture2D(u_buffer0, (loc.xy));
}
vec4 getRelPixel(vec2 rel_loc)
{
    return texture2D(u_buffer0, (uv + rel_loc.xy/(u_resolution - vec2(0.,MemHeight))));
}

bool isOrg(vec4 pixel)
{
    return pixel.a >= 0.5;
}

vec4 memory()
{
    return randomColor(uv);
}

vec4 getMem(vec2 loc)
{
    return getPixel(vec2(loc.x, MemHeight * loc.y));
}

vec2 memLocAdd(vec2 loc, int i)
{
    return vec2(mod(loc.x, u_resolution.x), loc.y + floor(loc.x / u_resolution.x));
}

vec2 getDnaLoc(vec4 org)
{
    vec2 dnaLoc = org.rg;
    return dnaLoc;
}

Dna getDna(vec2 loc)
{
    vec4 samples = getMem(memLocAdd(loc, 2));
    return Dna(
        getMem(loc),
        getMem(memLocAdd(loc, 1)),
        AtoXY(samples.x),
        AtoXY(samples.y),
        AtoXY(samples.z),
        AtoXY(samples.w),
        getMem(memLocAdd(loc, 3)),
        getMem(memLocAdd(loc, 4))
    );

}

vec4 emptySpace(vec4 pixel)
{
    vec4 sum = pixel.rgba;
    if(length(pixel) <= pixel.a)
        return randomColor(gl_FragCoord.xy);
    float angle;
    vec4 neighbor;
    vec4 minNeighbor = vec4(1.0);
    for(int i = 0; i < NeighborCount; i++)
    {
        angle = (float(i) / float(NeighborCount)) * 2. * PI;
        neighbor = getRelPixel(AtoXY(angle)*sqrt(2.));
        sum += neighbor.rgba;
        if(isOrg(neighbor))
        {
            Dna dna = getDna(getDnaLoc(neighbor));
            if(all(lessThan(abs(neighbor - dna.divisionCondition), dna.divisionMargin)))
            {
                return pixel.rgba * neighbor.rgba;
            }
        }
    }
    return sum / float(NeighborCount+1);
}

vec4 organism(vec4 pixel) {
    Dna dna = getDna(getDnaLoc(pixel));
    vec4 sum = pixel.rgba;
    sum += getRelPixel(dna.sample0) * dna.sampleMod;
    sum += getRelPixel(dna.sample1) * dna.sampleMod;
    sum += getRelPixel(dna.sample2) * dna.sampleMod;
    sum += getRelPixel(dna.sample3) * dna.sampleMod;
    return sum-dna.waste;
}

void main()
{
    vec4 color = getPixel(uv);
    if(gl_FragCoord.y > u_memscale * MemHeight)
    {
        if (isOrg(color))
        {
            color = organism(color);
        } else {
            color = emptySpace(color);
        }
    }
    else
    {
        color = memory();
    }
    gl_FragColor = color;
}
