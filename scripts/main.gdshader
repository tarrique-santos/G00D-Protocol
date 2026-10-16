
shader_type sky;

uniform vec3 star_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float star_density : hint_range(20.0, 300.0) = 180.0;
uniform float star_brightness : hint_range(0.0, 3.0) = 1.5;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}

void sky() {
    vec3 dir = normalize(EYEDIR);
    vec3 cell = floor(dir * star_density);
    float rnd = hash(cell);

    float star = step(0.992, rnd);
    float brightness = star * star_brightness;

    COLOR = vec3(0.015, 0.025, 0.07);
    COLOR += star_color * brightness;
}
