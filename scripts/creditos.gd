extends Control

@export_group("Configurações")
@export var cena_menu: String = "res://scenes/UI/home.tscn"
@export var velocidade_eletricidade: float = 0.45

@export_group("Carrossel")
## Tempo que cada cargo fica na tela.
@export var duracao_slide: float = 3.5
## Duração do fade de entrada e de saída.
@export var duracao_fade: float = 0.6
## Quanto o texto desliza (em pixels) ao entrar e sair.
@export var deslize: float = 24.0

var creditos: Array[Dictionary] = [
	{"cargo": "ROTEIRO", "nomes": ["Victória", "Ataliba"]},
	{"cargo": "DESIGN", "nomes": ["Victória", "Tarrique"]},
	{"cargo": "PROGRAMAÇÃO GERAL", "nomes": ["Tarrique", "Ataliba", "Victória"]},
	{"cargo": "ÁUDIO", "nomes": ["Victória", "Tarrique"]},
	{"cargo": "ILUMINAÇÃO", "nomes": ["Victória", "Ataliba"]},
	{"cargo": "TELAS E INTERFACE", "nomes": ["Tarrique", "Ataliba"]},
	{"cargo": "CENÁRIOS E LEVEL DESIGN", "nomes": ["Ataliba", "Victória"]},
	{"cargo": "MODELAGEM 3D", "nomes": ["Tarrique", "Victória"]},
	{"cargo": "INIMIGOS E INTELIGÊNCIA ARTIFICIAL", "nomes": ["Ataliba", "Tarrique"]},
	{"cargo": "CHEFES E COMBATE", "nomes": ["Victória", "Ataliba", "Tarrique"]},
	{"cargo": "EFEITOS VISUAIS", "nomes": ["Tarrique", "Ataliba", "Victória"]},
	{"cargo": "TESTES E BALANCEAMENTO", "nomes": ["Tarrique", "Ataliba", "Victória"]},
	{"cargo": "OBRIGADO POR JOGAR", "nomes": ["G00D-PROTOCOL"]},
]

var tempo: float = 0.0
var indice: int = -1
var retornando_menu: bool = false

var botao_menu: Button
var cargo_label: Label
var nomes_label: Label
var bloco: VBoxContainer
var indicadores: HBoxContainer

var tween_slide: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_criar_interface()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)

	_proximo_slide()


func _process(delta: float) -> void:
	tempo += delta * velocidade_eletricidade
	queue_redraw()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_voltar_menu()
	elif evento.is_action_pressed("ui_right"):
		_proximo_slide()
	elif evento.is_action_pressed("ui_left"):
		indice = posmod(indice - 2, creditos.size())
		_proximo_slide()


# ==================================================
# CARROSSEL
# ==================================================

## Mostra o próximo cargo. Ao chegar ao fim, recomeça do primeiro.
func _proximo_slide() -> void:
	if retornando_menu or creditos.is_empty():
		return

	if tween_slide != null and tween_slide.is_valid():
		tween_slide.kill()

	indice = (indice + 1) % creditos.size()

	var item: Dictionary = creditos[indice]

	cargo_label.text = item["cargo"]
	nomes_label.text = "\n".join(item["nomes"])

	_atualizar_indicadores()

	# Começa transparente e um pouco abaixo
	bloco.modulate.a = 0.0
	bloco.position.y = deslize

	tween_slide = create_tween()
	tween_slide.set_trans(Tween.TRANS_SINE)

	# Entrada
	tween_slide.set_parallel(true)
	tween_slide.tween_property(bloco, "modulate:a", 1.0, duracao_fade)
	tween_slide.tween_property(bloco, "position:y", 0.0, duracao_fade)

	# Permanência
	tween_slide.chain().tween_interval(duracao_slide)

	# Saída (sobe e some)
	tween_slide.chain().set_parallel(true)
	tween_slide.tween_property(bloco, "modulate:a", 0.0, duracao_fade)
	tween_slide.tween_property(bloco, "position:y", -deslize, duracao_fade)

	# Quando termina, chama o próximo
	tween_slide.chain().tween_callback(_proximo_slide)


func _atualizar_indicadores() -> void:
	for i in indicadores.get_child_count():
		var ponto := indicadores.get_child(i) as ColorRect

		ponto.color = Color("#22BCEB") if i == indice else Color("#1A3A4F")


# ==================================================
# FUNDO
# ==================================================

func _draw() -> void:
	var tamanho := get_viewport_rect().size

	draw_rect(Rect2(Vector2.ZERO, tamanho), Color("#050B16"))

	draw_circle(
		tamanho / 2.0,
		minf(tamanho.x, tamanho.y) * 0.32,
		Color(0.0, 0.35, 0.65, 0.035)
	)

	var trilhas: Array[PackedVector2Array] = [
		PackedVector2Array([
			Vector2(0.0, 0.12), Vector2(0.12, 0.12), Vector2(0.16, 0.17),
			Vector2(0.16, 0.30), Vector2(0.22, 0.36)
		]),
		PackedVector2Array([
			Vector2(0.0, 0.83), Vector2(0.10, 0.83), Vector2(0.15, 0.78),
			Vector2(0.15, 0.69), Vector2(0.22, 0.63)
		]),
		PackedVector2Array([
			Vector2(1.0, 0.15), Vector2(0.88, 0.15), Vector2(0.84, 0.20),
			Vector2(0.84, 0.32), Vector2(0.78, 0.38)
		]),
		PackedVector2Array([
			Vector2(1.0, 0.85), Vector2(0.89, 0.85), Vector2(0.84, 0.80),
			Vector2(0.84, 0.69), Vector2(0.78, 0.63)
		]),
		PackedVector2Array([
			Vector2(0.0, 0.48), Vector2(0.08, 0.48), Vector2(0.12, 0.44),
			Vector2(0.18, 0.44)
		]),
		PackedVector2Array([
			Vector2(1.0, 0.52), Vector2(0.92, 0.52), Vector2(0.88, 0.56),
			Vector2(0.82, 0.56)
		]),
	]

	for i in range(trilhas.size()):
		var pontos := PackedVector2Array()

		for ponto in trilhas[i]:
			pontos.append(Vector2(ponto.x * tamanho.x, ponto.y * tamanho.y))

		_desenhar_trilha(pontos, tempo + i * 0.19)

	draw_line(
		Vector2(tamanho.x * 0.30, tamanho.y * 0.09),
		Vector2(tamanho.x * 0.70, tamanho.y * 0.09),
		Color(0.0, 0.65, 1.0, 0.15), 1.0
	)

	draw_line(
		Vector2(tamanho.x * 0.30, tamanho.y * 0.91),
		Vector2(tamanho.x * 0.70, tamanho.y * 0.91),
		Color(0.0, 0.65, 1.0, 0.15), 1.0
	)


func _desenhar_trilha(pontos: PackedVector2Array, fase: float) -> void:
	if pontos.size() < 2:
		return

	draw_polyline(pontos, Color(0.0, 0.55, 1.0, 0.10), 7.0, true)
	draw_polyline(pontos, Color(0.0, 0.65, 1.0, 0.42), 1.5, true)

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
			var posicao := inicio.lerp(fim, (distancia - percorrida) / comprimento)

			draw_circle(posicao, 7.0, Color(0.0, 0.7, 1.0, 0.12))
			draw_circle(posicao, 3.0, Color(0.0, 0.85, 1.0, 0.85))
			draw_circle(posicao, 1.5, Color.WHITE)
			break

		percorrida += comprimento


# ==================================================
# INTERFACE
# ==================================================

func _criar_interface() -> void:
	var layout := VBoxContainer.new()

	layout.anchor_left = 0.5
	layout.anchor_right = 0.5
	layout.anchor_top = 0.5
	layout.anchor_bottom = 0.5

	layout.offset_left = -330
	layout.offset_right = 330
	layout.offset_top = -250
	layout.offset_bottom = 250

	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)

	add_child(layout)

	var identificacao := Label.new()
	identificacao.text = "G00D PROTOCOL  //  CRÉDITOS"
	identificacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identificacao.add_theme_color_override("font_color", Color("#22BCEB"))
	identificacao.add_theme_font_size_override("font_size", 14)
	layout.add_child(identificacao)

	var linha := ColorRect.new()
	linha.custom_minimum_size = Vector2(180, 2)
	linha.color = Color("#22BCEB")
	linha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(linha)

	# Área do carrossel (altura fixa para o botão não pular de lugar)
	var area := Control.new()
	area.custom_minimum_size = Vector2(660, 230)
	area.clip_contents = false
	layout.add_child(area)

	bloco = VBoxContainer.new()
	bloco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bloco.alignment = BoxContainer.ALIGNMENT_CENTER
	bloco.add_theme_constant_override("separation", 16)
	area.add_child(bloco)

	cargo_label = Label.new()
	cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cargo_label.add_theme_color_override("font_color", Color("#22BCEB"))
	cargo_label.add_theme_font_size_override("font_size", 22)
	bloco.add_child(cargo_label)

	nomes_label = Label.new()
	nomes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nomes_label.add_theme_color_override("font_color", Color("#EAFBFF"))
	nomes_label.add_theme_font_size_override("font_size", 38)
	nomes_label.add_theme_constant_override("line_spacing", 8)
	bloco.add_child(nomes_label)

	# Pontinhos que mostram em qual cargo está
	indicadores = HBoxContainer.new()
	indicadores.alignment = BoxContainer.ALIGNMENT_CENTER
	indicadores.add_theme_constant_override("separation", 10)
	layout.add_child(indicadores)

	for i in creditos.size():
		var ponto := ColorRect.new()
		ponto.custom_minimum_size = Vector2(8, 8)
		ponto.color = Color("#1A3A4F")
		indicadores.add_child(ponto)

	var espaco := Control.new()
	espaco.custom_minimum_size.y = 16
	layout.add_child(espaco)

	botao_menu = Button.new()
	botao_menu.text = "VOLTAR AO MENU PRINCIPAL"
	botao_menu.custom_minimum_size = Vector2(300, 55)
	botao_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao_menu.add_theme_font_size_override("font_size", 15)
	botao_menu.add_theme_color_override("font_color", Color("#DDF8FF"))

	var estilo_normal := StyleBoxFlat.new()
	estilo_normal.bg_color = Color("#0A1C2D")
	estilo_normal.border_color = Color("#1689B8")
	estilo_normal.set_border_width_all(1)
	estilo_normal.set_corner_radius_all(4)
	estilo_normal.content_margin_left = 20
	estilo_normal.content_margin_right = 20

	var estilo_hover := StyleBoxFlat.new()
	estilo_hover.bg_color = Color("#103653")
	estilo_hover.border_color = Color("#22BCEB")
	estilo_hover.set_border_width_all(2)
	estilo_hover.set_corner_radius_all(4)

	var estilo_pressionado := StyleBoxFlat.new()
	estilo_pressionado.bg_color = Color("#16739A")
	estilo_pressionado.border_color = Color("#8AEAFF")
	estilo_pressionado.set_border_width_all(2)
	estilo_pressionado.set_corner_radius_all(4)

	botao_menu.add_theme_stylebox_override("normal", estilo_normal)
	botao_menu.add_theme_stylebox_override("hover", estilo_hover)
	botao_menu.add_theme_stylebox_override("pressed", estilo_pressionado)
	botao_menu.add_theme_stylebox_override("focus", estilo_hover)

	botao_menu.pressed.connect(_voltar_menu)
	layout.add_child(botao_menu)

	var rodape := Label.new()
	rodape.text = "←  →  trocam o cargo   //   ESC volta ao menu"
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.add_theme_color_override("font_color", Color("#526A7D"))
	rodape.add_theme_font_size_override("font_size", 11)
	layout.add_child(rodape)


# ==================================================
# SAÍDA
# ==================================================

func _voltar_menu() -> void:
	if retornando_menu:
		return

	retornando_menu = true

	if tween_slide != null and tween_slide.is_valid():
		tween_slide.kill()

	botao_menu.disabled = true
	botao_menu.text = "RETORNANDO AO MENU..."

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	await tween.finished

	var erro := get_tree().change_scene_to_file(cena_menu)

	if erro != OK:
		push_error("Não foi possível carregar o menu: " + cena_menu)

		retornando_menu = false
		botao_menu.disabled = false
		botao_menu.text = "VOLTAR AO MENU PRINCIPAL"
		_proximo_slide()
