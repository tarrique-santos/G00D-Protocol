extends Control
## Tela de vitória (sem botão): quem chama (AreaVitoria) decide quando ir para os créditos.

@export_group("Configurações")
@export var velocidade_eletricidade: float = 0.45

var tempo: float = 0.0
var titulo: Label
var subtitulo: Label
var descricao: Label

func _ready() -> void:
	# A tela precisa continuar funcionando com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_criar_interface()

	modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	tempo += delta * velocidade_eletricidade
	queue_redraw()


func _draw() -> void:
	var tamanho := get_viewport_rect().size

	draw_rect(
		Rect2(Vector2.ZERO, tamanho),
		Color("#050B16")
	)

	draw_circle(
		tamanho / 2.0,
		minf(tamanho.x, tamanho.y) * 0.32,
		Color(0.0, 0.35, 0.65, 0.035)
	)

	var trilhas: Array[PackedVector2Array] = [
		PackedVector2Array([
			Vector2(0.0, 0.12),
			Vector2(0.12, 0.12),
			Vector2(0.16, 0.17),
			Vector2(0.16, 0.30),
			Vector2(0.22, 0.36)
		]),
		PackedVector2Array([
			Vector2(0.0, 0.83),
			Vector2(0.10, 0.83),
			Vector2(0.15, 0.78),
			Vector2(0.15, 0.69),
			Vector2(0.22, 0.63)
		]),
		PackedVector2Array([
			Vector2(1.0, 0.15),
			Vector2(0.88, 0.15),
			Vector2(0.84, 0.20),
			Vector2(0.84, 0.32),
			Vector2(0.78, 0.38)
		]),
		PackedVector2Array([
			Vector2(1.0, 0.85),
			Vector2(0.89, 0.85),
			Vector2(0.84, 0.80),
			Vector2(0.84, 0.69),
			Vector2(0.78, 0.63)
		]),
		PackedVector2Array([
			Vector2(0.0, 0.48),
			Vector2(0.08, 0.48),
			Vector2(0.12, 0.44),
			Vector2(0.18, 0.44)
		]),
		PackedVector2Array([
			Vector2(1.0, 0.52),
			Vector2(0.92, 0.52),
			Vector2(0.88, 0.56),
			Vector2(0.82, 0.56)
		])
	]

	for i in range(trilhas.size()):
		var pontos := PackedVector2Array()

		for ponto in trilhas[i]:
			pontos.append(Vector2(
				ponto.x * tamanho.x,
				ponto.y * tamanho.y
			))

		_desenhar_trilha(pontos, tempo + i * 0.19)

	draw_line(
		Vector2(tamanho.x * 0.30, tamanho.y * 0.09),
		Vector2(tamanho.x * 0.70, tamanho.y * 0.09),
		Color(0.0, 0.65, 1.0, 0.15),
		1.0
	)

	draw_line(
		Vector2(tamanho.x * 0.30, tamanho.y * 0.91),
		Vector2(tamanho.x * 0.70, tamanho.y * 0.91),
		Color(0.0, 0.65, 1.0, 0.15),
		1.0
	)


func _desenhar_trilha(
	pontos: PackedVector2Array,
	fase: float
) -> void:
	if pontos.size() < 2:
		return

	draw_polyline(
		pontos,
		Color(0.0, 0.55, 1.0, 0.10),
		7.0,
		true
	)

	draw_polyline(
		pontos,
		Color(0.0, 0.65, 1.0, 0.42),
		1.5,
		true
	)

	var comprimento_total := 0.0

	for i in range(pontos.size() - 1):
		comprimento_total += pontos[i].distance_to(pontos[i + 1])

	if comprimento_total <= 0.0:
		return

	var distancia := fposmod(fase, 1.0) * comprimento_total
	var percorrida := 0.0

	for i in range(pontos.size() - 1):
		var inicio := pontos[i]
		var fim := pontos[i + 1]
		var comprimento := inicio.distance_to(fim)

		if distancia <= percorrida + comprimento:
			var fator := (distancia - percorrida) / comprimento
			var posicao := inicio.lerp(fim, fator)

			draw_circle(
				posicao,
				7.0,
				Color(0.0, 0.7, 1.0, 0.12)
			)

			draw_circle(
				posicao,
				3.0,
				Color(0.0, 0.85, 1.0, 0.85)
			)

			draw_circle(
				posicao,
				1.5,
				Color.WHITE
			)

			break

		percorrida += comprimento


func _criar_interface() -> void:
	var layout := VBoxContainer.new()

	layout.anchor_left = 0.5
	layout.anchor_right = 0.5
	layout.anchor_top = 0.5
	layout.anchor_bottom = 0.5

	layout.offset_left = -310
	layout.offset_right = 310
	layout.offset_top = -205
	layout.offset_bottom = 205

	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)

	add_child(layout)

	var identificacao := Label.new()
	identificacao.text = "G00D PROTOCOL  //  SYSTEM REPORT"
	identificacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identificacao.add_theme_color_override(
		"font_color",
		Color("#22BCEB")
	)
	identificacao.add_theme_font_size_override("font_size", 14)
	layout.add_child(identificacao)

	var espaco1 := Control.new()
	espaco1.custom_minimum_size.y = 12
	layout.add_child(espaco1)

	titulo = Label.new()
	titulo.text = "MISSION COMPLETE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override(
		"font_color",
		Color("#EAFBFF")
	)
	titulo.add_theme_font_size_override("font_size", 42)
	layout.add_child(titulo)

	subtitulo = Label.new()
	subtitulo.text = "OBJETIVO CONCLUÍDO"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_color_override(
		"font_color",
		Color("#22BCEB")
	)
	subtitulo.add_theme_font_size_override("font_size", 21)
	layout.add_child(subtitulo)

	descricao = Label.new()
	descricao.text = "TODAS AS AMEAÇAS FORAM NEUTRALIZADAS."
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.add_theme_color_override(
		"font_color",
		Color("#899EAF")
	)
	descricao.add_theme_font_size_override("font_size", 13)
	layout.add_child(descricao)

	var espaco2 := Control.new()
	espaco2.custom_minimum_size.y = 30
	layout.add_child(espaco2)

	var linha := ColorRect.new()
	linha.custom_minimum_size = Vector2(180, 2)
	linha.color = Color("#22BCEB")
	linha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(linha)

	var espaco3 := Control.new()
	espaco3.custom_minimum_size.y = 25
	layout.add_child(espaco3)

	var rodape := Label.new()
	rodape.text = "G00D PROTOCOL  //  OPERATION SUCCESSFUL"
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.add_theme_color_override(
		"font_color",
		Color("#526A7D")
	)
	rodape.add_theme_font_size_override("font_size", 11)
	layout.add_child(rodape)
