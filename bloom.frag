uniform Image blurred;
uniform float strength;

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
    vec4 col = Texel(t,tc)*c;
    vec4 bloom = Texel(blurred,tc)*c;
    return mix(col,bloom,0.5*strength)*1.5;
}