uniform vec3 color1;
uniform vec3 color2;

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
    vec4 col = Texel(t,tc);
    if (col.r == 1.0 && col.g == 0.0 && col.b == 0.0) {
        return vec4(color1,1)*c;
    }
    if (col.r == 0.0 && col.g == 0.0 && col.b == 1.0) {
        return vec4(color2,1)*c;
    }
    return col*c;
}