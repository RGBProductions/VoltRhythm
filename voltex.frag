uniform Image layers[3];
uniform vec3 colors[16];
uniform float dither[16];
uniform float ditherSize;

vec4 getClosest(vec4 base) {
    float dist1 = 16.0;
    int col1 = 0;
    for (int i = 0; i < 16; i++) {
        float d1 = length(colors[i] - base.rgb);
        if (d1 < dist1) {
            dist1 = d1;
            col1 = i;
        }
    }
    return vec4(colors[col1], dist1);
}

vec4 getSecondClosest(vec4 base) {
    float dist1 = 16.0;
    int col1 = 0;
    float dist2 = 16.0;
    int col2 = 0;
    for (int i = 0; i < 16; i++) {
        float d1 = length(colors[i] - base.rgb);
        if (d1 < dist1) {
            dist1 = d1;
            col1 = i;
        } else if (d1 < dist2) {
            dist2 = d1;
            col2 = i;
        }
    }
    return vec4(colors[col2], dist2);
}

float lerpT(float a,float b,float v) {
    return (v-a)/(b-a);
}

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {
    vec4 base =
        Texel(layers[0],tc) +
        Texel(layers[1],tc) +
        Texel(layers[2],tc);
    
    base = vec4(mix(vec3(0,0,0),base.xyz,c.a),1);
    
    float d = dither[int(mod(int(sc.y/ditherSize),4)*4+mod(int(sc.x/ditherSize),4))];
    vec4 a = getClosest(base);
    vec4 b = getSecondClosest(base);
    float threshold = lerpT(0,1,a.w);
    if (d < threshold) {
        return vec4(b.xyz,1);
    } else {
        return vec4(a.xyz,1);
    }
}