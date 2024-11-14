uniform float curveStrength;
uniform float scanlineStrength;
uniform vec2 textureSize;
uniform float tearStrength;
uniform float tearTime;
uniform float horizBlurStrength;
uniform float chromaticStrength;

float rand(float n){return fract(sin(n) * 43758.5453123);}

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
    vec2 centered = 2.0 * tc - 1.0;
    vec2 curved = vec2(
        centered.x * sqrt(1.0 + curveStrength * pow(length(centered),2.0)) / sqrt(1.0 + curveStrength),
        centered.y * sqrt(1.0 + curveStrength * pow(length(centered),2.0)) / sqrt(1.0 + curveStrength)
    );
    vec2 samplePos = (curved + 1.0) * 0.5;
    float tearing = (rand(tearTime+floor(samplePos.y*textureSize.y/8.0))*2.0-1.0)*tearStrength;
    samplePos.x += tearing;
    if (curved.x < -1.0 || curved.x > 1.0 || curved.y < -1.0 || curved.y > 1.0) discard;
    vec2 samplePos_r = ((samplePos*2.0-1.0)*(1.0 + 0.0125*chromaticStrength) + 1.0) * 0.5;
    vec2 samplePos_g = samplePos;
    vec2 samplePos_b = ((samplePos*2.0-1.0)*(1.0 - 0.0125*chromaticStrength) + 1.0) * 0.5;
    vec3 scanlineVisibility = vec3(
        abs(mod(samplePos_r.y*textureSize.y+0.5, 2.0) - 1.0),
        abs(mod(samplePos_g.y*textureSize.y+0.5, 2.0) - 1.0),
        abs(mod(samplePos_b.y*textureSize.y+0.5, 2.0) - 1.0)
    );
    vec3 scanline = vec3(
        mix(scanlineStrength,1.0,scanlineVisibility.r),
        mix(scanlineStrength,1.0,scanlineVisibility.g),
        mix(scanlineStrength,1.0,scanlineVisibility.b)
    );
    vec4 main = vec4(
        (Texel(t, samplePos_r)*c).r,
        (Texel(t, samplePos_g)*c).g,
        (Texel(t, samplePos_b)*c).b,
        1.0
    );
    vec4 blur = vec4(
        (Texel(t, samplePos_r+vec2(1.0/textureSize.x, 0.0))*c).r,
        (Texel(t, samplePos_g+vec2(1.0/textureSize.x, 0.0))*c).g,
        (Texel(t, samplePos_b+vec2(1.0/textureSize.x, 0.0))*c).b,
        1.0
    );
    vec4 col = mix(main,blur,horizBlurStrength*0.5);
    return vec4(col.rgb*scanline, col.a);
}