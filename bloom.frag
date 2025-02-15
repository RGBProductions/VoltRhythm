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
        vec2 samplep = tc - zoomDir*(zoomBlurStrength / float(num))*float(i);
        vec4 col = Texel(t,samplep)*c;
        vec4 bloom = Texel(blurred,samplep)*c;
        final += mix(col,bloom,0.5*min(1.0,strength))*1.5 + bloom*max(0.0, strength - 1.0);
    }
    return final/float(num);
}