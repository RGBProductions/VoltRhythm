uniform float curveStrength;
uniform float scanlineStrength;
uniform vec2 textureSize;
uniform float tearStrength;
uniform float tearTime;
uniform float horizBlurStrength;

float rand(float n){return fract(sin(n) * 43758.5453123);}

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
    vec2 centered = 2.0 * tc - 1.0;
    vec2 curved = vec2(
        centered.x * sqrt(1.0 + curveStrength * pow(length(centered),2.0)) / sqrt(1.0 + curveStrength),
        centered.y * sqrt(1.0 + curveStrength * pow(length(centered),2.0)) / sqrt(1.0 + curveStrength)
    );
    vec2 sample = (curved + 1.0) * 0.5;
    float scanline = 1.0 - mod(floor(sample.y*textureSize.y+0.5),2.0)*scanlineStrength;
    float tearing = (rand(tearTime+floor(sample.y*textureSize.y/8.0))*2.0-1.0)*tearStrength;
    sample.x += tearing;
    if (curved.x < -1.0 || curved.x > 1.0 || curved.y < -1.0 || curved.y > 1.0) discard;
    vec4 main = Texel(t, sample)*c;
    vec4 blur = Texel(t, sample+vec2(1.0/textureSize.x, 0.0))*c;
    vec4 col = mix(main,blur,horizBlurStrength*0.5);
    return vec4(col.rgb*scanline, col.a);
}