
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform vec4 cor_eletrica : source_color = vec4(0.0, 0.45, 1.0, 1.0);
uniform vec4 cor_nucleo : source_color = vec4(0.75, 0.95, 1.0, 1.0);

uniform float intensidade : hint_range(1.0, 20.0) = 8.0;
uniform float velocidade : hint_range(0.1, 10.0) = 2.5;
uniform float espessura : hint_range(0.005, 0.15) = 0.035;
uniform float irregularidade : hint_range(0.0, 0.2) = 0.06;
uniform float quantidade : hint_range(8.0, 100.0) = 45.0;

float hash(float n) {
    return fract(sin(n * 127.1) * 43758.5453);
}

float linha(float distancia, float largura) {
    return 1.0 - smoothstep(largura * 0.2, largura, distancia);
}

void fragment() {
    // UV centralizado: o centro do círculo fica em (0, 0)
    vec2 p = UV * 2.0 - 1.0;

    float angulo = atan(p.y, p.x);
    float raio = length(p);

    float tempo = TIME * velocidade;

    // Variações aleatórias ao longo da circunferência
    float setor = floor((angulo + PI) / (2.0 * PI) * quantidade);
    float aleatorio = hash(setor + floor(tempo * 5.0) * 91.7);

    float distorcao = sin(angulo * quantidade * 0.7 + tempo * 5.0)
        * irregularidade;

    distorcao += (hash(setor + floor(tempo * 9.0)) - 0.5)
        * irregularidade;

    float raio_alvo = 0.75 + distorcao;

    // Linha elétrica principal
    float distancia = abs(raio - raio_alvo);
    float principal = linha(distancia, espessura);

    // Descargas secundárias
    float ramo = sin(angulo * quantidade * 1.8 + tempo * 8.0)
        * irregularidade * 1.5;

    float secundaria = linha(
        abs(raio - raio_alvo - ramo),
        espessura * 0.45
    );

    // Atividade aleatória, sem apagar o círculo inteiro
    float ativo = step(0.22, aleatorio);
    float pulso = 0.4 + 0.6 * abs(sin(tempo * 12.0 + aleatorio * 20.0));

    float energia = (principal + secundaria * 0.7) * ativo * pulso;

    // Núcleo branco-azulado
    float nucleo = linha(distancia, espessura * 0.25);

    vec3 cor = cor_eletrica.rgb * energia;
    cor += cor_nucleo.rgb * nucleo * energia * 1.5;

    ALBEDO = cor * intensidade;
    EMISSION = cor * intensidade * 2.5;

    // Descarta os pixels fora das descargas
    ALPHA = clamp(energia, 0.0, 1.0);
}
