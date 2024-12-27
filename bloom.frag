uniform Image blurred;
uniform float strength;

uniform bool enableZoomBlur;
uniform float zoomBlurStrength;
uniform vec2 zoomBlurFocus;

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
    int num = 1;
    if (enableZoomBlur) {
        num = 32;
    }
    vec4 final = vec4(0,0,0,0);
    vec2 zoomDir = (tc*2.0)-1.0 - zoomBlurFocus;
    for (int i = 0; i < num; i++) {
        vec2 sample = tc - zoomDir*(zoomBlurStrength/num)*float(i);
        vec4 col = Texel(t,sample)*c;
        vec4 bloom = Texel(blurred,sample)*c;
        final += mix(col,bloom,0.5*strength)*1.5;
    }
    return final/float(num);
}