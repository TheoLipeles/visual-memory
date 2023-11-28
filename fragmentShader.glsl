
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

#define MemHeight 20.0
#define NeighborCount 1
#define PI 3.14159265
#define uv (gl_FragCoord.xy/u_resolution.xy)
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

// cosine based palette, 4 vec3 params
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec4 getPixel(vec2 loc)
{
    return texture2D(u_buffer0, (loc.xy));
}
vec4 getRelPixel(vec2 rel_loc)
{
    return texture2D(u_buffer0, (uv + rel_loc.xy/(u_resolution - vec2(0.,MemHeight))));
}

vec4 getMem(vec2 loc)
{
    return getPixel(normalize(loc)*u_resolution);
}

vec2 memLocAdd(vec2 loc, int i)
{
    return vec2(mod(loc.x, u_resolution.x), loc.y + floor(loc.x / u_resolution.x));
}

vec2 getDnaLoc(vec4 org)
{
    vec2 dnaLoc = abs(vec2(cos(org.r)-sin(org.g), sin(org.b)-cos(org.a)));
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

bool isOrg(vec4 pixel)
{
    if (length(pixel) < 0.5) return bool(0);
    Dna dna = getDna(getDnaLoc(pixel));
    return (length(abs(pixel - dna.divisionCondition)) < length(dna.divisionMargin));
}

// Pixel operations

vec4 memory(vec4 pixel)
{
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    return randomColor(st);
    float dist = distance(st, vec2(0.,0.8));
    vec3 c1 = vec3(0.5,0.4,0.5);
    vec3 c2 = vec3(0.5,0.5,0.3);
    vec3 c3 = vec3(0.76, 1.0, 0.01);
    vec3 c4 = vec3(0.4353, 0.7176, 0.0941);
    vec3 gradient = palette(dist, c1, c2, c3, c4);
    return vec4(gradient, dist);
}

vec4 emptySpace(vec4 pixel)
{
    vec4 sum = pixel.rgba;
    Dna pdna = getDna(getDnaLoc(pixel));
    if(length(pixel) <= length(pdna.waste-pdna.sampleMod))
        return randomColor(gl_FragCoord.xy);
    float angle;
    vec4 neighbor;
    vec4 minNeighbor = vec4(1.0);
    angle = (pdna.sampleMod.x / float(NeighborCount)) *2.0* PI;
    angle = (angle+XYtoA(pdna.sample2)-XYtoA(pdna.sample3))*XYtoA(pdna.sample0)/XYtoA(pdna.sample1)*2.0*PI;
    angle /= radians(length(sum));
    neighbor = getRelPixel(AtoXY(angle)*(length(pdna.sample3/pdna.sample2))*sqrt(2.));
    sum += neighbor.rgba;
    return sum / 2.0;
}

vec4 organism(vec4 pixel) {
    Dna dna = getDna(getDnaLoc(pixel));
    vec4 sum = pixel.rgba;
    sum += getRelPixel(dna.sample0) * dna.sampleMod;
    sum += getRelPixel(dna.sample1) * dna.sampleMod;
    sum += getRelPixel(dna.sample2) * dna.sampleMod;
    sum += getRelPixel(dna.sample3) * dna.sampleMod;
    return sum-max(dna.waste*2.0, dna.sampleMod*dna.waste);
}

void main()
{
    vec4 color = getPixel(uv);
    if(gl_FragCoord.y < u_resolution.y-(u_memscale * MemHeight))
    {
        color = (isOrg(color) ? organism(color) : emptySpace(color));
    }
    else
    {
        color = memory(color);
    }
    gl_FragColor = color;
}
