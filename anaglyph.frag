uniform Image left;

vec4 effect(vec4 c, Image right, vec2 tc, vec2 sc) {
    return vec4(Texel(right,tc).r, Texel(left,tc).gb, 1);
}