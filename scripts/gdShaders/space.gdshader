shader_type sky;

uniform vec3 space_color = vec3(0.015, 0.025, 0.07);

// Estrelas
uniform vec3 star_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float star_density : hint_range(40.0, 300.0) = 120.0;
uniform float star_brightness : hint_range(0.0, 3.0) = 1.5;
uniform float star_twinkle : hint_range(0.0, 1.0) = 0.5;

// Via Láctea
uniform vec3 mw_normal = vec3(0.35, 0.9, 0.25);          // inclinação da faixa no céu
uniform float mw_center_angle : hint_range(0.0, 6.28) = 1.0; // onde fica o núcleo mais brilhante
uniform float mw_intensity : hint_range(0.0, 1.0) = 0.45;
uniform float mw_width : hint_range(0.05, 0.6) = 0.2;
uniform float mw_dust : hint_range(0.0, 1.0) = 0.7;      // faixas escuras de poeira
uniform float mw_stars : hint_range(0.0, 1.0) = 0.6;     // estrelas minúsculas dentro da faixa
uniform vec3 mw_color_core : source_color = vec3(1.0, 0.82, 0.6);
uniform vec3 mw_color_edge : source_color = vec3(0.45, 0.55, 0.95);

// Nebulosas (bem sutis)
uniform float nebula_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float nebula_scale : hint_range(0.5, 6.0) = 2.0;
uniform vec3 nebula_color_a : source_color = vec3(0.35, 0.10, 0.55);
uniform vec3 nebula_color_b : source_color = vec3(0.05, 0.30, 0.50);

// Planetas (raros)
uniform float planet_amount : hint_range(0.0, 0.1) = 0.02;
uniform float planet_brightness : hint_range(0.0, 2.0) = 0.7;

const float PLANET_DENSITY = 8.0;

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float hash31(vec3 p) {
	return hash33(p).x;
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			   mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 5; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return s;
}

// smax deve ser <= 0.109 para o brilho não ser cortado pela borda da célula.
vec3 star_layer(vec3 dir, float density, float chance, float bright, float smin, float smax, float seed) {
	vec3 p = dir * density;
	vec3 cell = floor(p);
	vec3 h = hash33(cell + seed);
	if (h.x > chance) return vec3(0.0);

	vec3 h2 = hash33(cell + seed + 41.7);
	vec3 h3 = hash33(cell + seed + 97.3);

	vec3 pos = 0.25 + 0.5 * h2;
	float d = length(fract(p) - pos);

	float size = mix(smin, smax, h.y * h.y);
	float core = 1.0 - smoothstep(0.0, size, d);
	float halo = (1.0 - smoothstep(0.0, size * 2.2, d)) * 0.25;

	float mag = mix(0.25, 1.0, h.z * h.z) * bright;

	vec3 tint = mix(vec3(1.0, 0.78, 0.6), vec3(0.65, 0.8, 1.0), h3.z);
	vec3 col = mix(star_color, tint, 0.6);

	float speed = mix(1.5, 5.0, h3.x);
	float phase = h3.y * 6.2831853;
	float s = sin(TIME * speed + phase) * sin(TIME * speed * 0.43 + phase * 1.7);
	float tw = 1.0 - star_twinkle * (0.5 + 0.5 * s);

	return col * (core + halo) * mag * tw;
}

// Retorna a cor da Via Láctea (rgb) e a densidade da faixa (a)
vec4 milky_way(vec3 dir) {
	vec3 n = normalize(mw_normal);
	vec3 ref = abs(n.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 u = normalize(cross(n, ref));
	vec3 v = cross(n, u);
	vec3 center = u * cos(mw_center_angle) + v * sin(mw_center_angle);

	// núcleo: região da faixa mais próxima do centro galáctico
	float core = smoothstep(0.0, 1.0, dot(dir, center));
	core = core * core;

	// distância ao plano galáctico, deformada por ruído para a faixa não ser perfeita
	float lat = dot(dir, n);
	lat += (fbm(dir * 2.5 + vec3(5.0)) - 0.5) * 0.3;

	// a faixa fica mais larga perto do núcleo
	float w = mw_width * (1.0 + 0.9 * core);
	float band = exp(-(lat * lat) / (w * w));

	// nuvens de estrelas distantes dentro da faixa
	float cloud = fbm(dir * 6.0 + vec3(2.0));
	float fine = fbm(dir * 18.0 + vec3(13.0));
	float glow = band * (0.35 + 0.65 * cloud) * (0.8 + 0.4 * fine);

	// poeira escura concentrada perto do centro da faixa
	float dust = smoothstep(0.5, 0.78, fbm(dir * 9.0 + vec3(40.0)));
	float lane = exp(-(lat * lat) / (w * w * 0.12));
	glow *= 1.0 - dust * lane * mw_dust * 0.9;

	// núcleo quente, bordas azuladas
	vec3 col = mix(mw_color_edge, mw_color_core, clamp(core * 1.2 + band * 0.15, 0.0, 1.0));
	glow *= 1.0 + 1.2 * core;

	return vec4(col * glow * mw_intensity, band * (1.0 - dust * lane * mw_dust));
}

vec3 nebula(vec3 dir) {
	vec3 p = dir * nebula_scale;
	float broad = smoothstep(0.35, 0.75, vnoise(dir * 1.6 + vec3(7.0)));
	float dens = smoothstep(0.45, 0.85, fbm(p + vec3(3.0))) * broad;
	float cmix = smoothstep(0.3, 0.7, vnoise(p * 0.8 + vec3(20.0)));
	vec3 col = mix(nebula_color_a, nebula_color_b, cmix);
	return col * dens * nebula_intensity;
}

// Retorna rgb + máscara (alpha) do planeta
vec4 planet(vec3 dir) {
	vec3 p = dir * PLANET_DENSITY;
	vec3 cell = floor(p);
	vec3 h = hash33(cell + 71.0);
	if (h.x > planet_amount) return vec4(0.0);

	vec3 h2 = hash33(cell + 19.0);
	vec3 q = cell + 0.3 + 0.4 * h2;
	float R = mix(0.05, 0.2, h.y);

	vec3 dv = p - q;
	float w = dot(dv, dir);
	float rr2 = R * R - w * w;
	if (rr2 <= 0.0) return vec4(0.0);

	vec3 inpl = dv - w * dir;
	float rr = sqrt(rr2);
	float rho = length(inpl);
	if (rho > rr) return vec4(0.0);

	vec3 up = abs(dir.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 t = normalize(cross(up, dir));
	vec3 b = cross(dir, t);
	vec2 uv = vec2(dot(inpl, t), dot(inpl, b)) / rr;
	float z = sqrt(max(1.0 - dot(uv, uv), 0.0));
	vec3 n = t * uv.x + b * uv.y - dir * z;

	vec3 L = normalize(hash33(cell + 5.0) * 2.0 - 1.0);
	float diff = clamp(dot(n, L), 0.0, 1.0);

	vec3 c1 = 0.3 + 0.6 * hash33(cell + 3.0);
	vec3 c2 = 0.3 + 0.6 * hash33(cell + 8.0);
	float bands = 0.5 + 0.5 * sin(uv.y * mix(5.0, 14.0, h.z) + 3.0 * vnoise(vec3(uv * 2.5, h.x * 40.0)));
	vec3 surf = mix(c1, c2, bands);

	float rim = pow(1.0 - z, 3.0);
	vec3 atmo = mix(c1, vec3(0.6, 0.8, 1.0), 0.5) * rim * smoothstep(-0.2, 0.6, dot(n, L)) * 0.6;

	vec3 col = surf * (diff + 0.02) + atmo;
	float edge = 1.0 - smoothstep(0.9, 1.0, rho / rr);
	return vec4(col * planet_brightness, edge);
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	vec3 col = space_color;
	col += nebula(dir);

	vec4 mw = milky_way(dir);
	col += mw.rgb;

	vec3 stars = star_layer(dir, star_density, 0.07, 1.0, 0.05, 0.109, 0.0);
	stars += star_layer(dir, star_density * 0.4, 0.05, 2.0, 0.07, 0.109, 100.0);

	// estrelas minúsculas extras, só dentro da faixa
	if (mw.a > 0.03) {
		stars += star_layer(dir, star_density * 2.5, 0.35 * mw.a, 0.5 * mw_stars, 0.03, 0.07, 200.0);
	}

	vec4 pl = planet(dir);
	col += stars * star_brightness * (1.0 - pl.a);
	col = mix(col, pl.rgb, pl.a);

	COLOR = col;
}