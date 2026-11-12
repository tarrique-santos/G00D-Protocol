
extends Control

@export_file("*.tscn") var cena_jogo: String = "res://scenes/UI/history.tscn"

# CORES
const FUNDO := Color("#050b14")
const CIANO := Color("#00d9ff")
const CIANO_ESCURO := Color("#087b9c")
const VERMELHO := Color("#ff304f")
const BRANCO := Color("#dcecf5")

# CIRCUITOS
var pontos: Array[Vector2] = []
var conexoes: Array[Vector2i] = []
var grafo: Dictionary = {}
var pulsos: Array[Dictionary] = []

var velocidade_pulso := 0.42

# INTERFACE
var painel_menu: PanelContainer
var painel_extra: PanelContainer
var titulo_extra: Label
var texto_extra: Label


func _ready() -> void:
	randomize()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	criar_circuitos()
	criar_interface()

	for i in range(7):
		criar_pulso()

	queue_redraw()


func _process(delta: float) -> void:
	animar_pulsos(delta)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


# --------------------------------------------------
# CIRCUITOS ELETRONICOS
# --------------------------------------------------

func criar_circuitos() -> void:

	pontos = [
		Vector2(0.04, 0.15),
		Vector2(0.16, 0.15),
		Vector2(0.16, 0.28),
		Vector2(0.29, 0.28),
		Vector2(0.29, 0.12),
		Vector2(0.43, 0.12),
		Vector2(0.43, 0.25),
		Vector2(0.57, 0.25),
		Vector2(0.57, 0.10),
		Vector2(0.72, 0.10),
		Vector2(0.72, 0.25),
		Vector2(0.88, 0.25),
		Vector2(0.96, 0.25),

		Vector2(0.04, 0.48),
		Vector2(0.17, 0.48),
		Vector2(0.17, 0.65),
		Vector2(0.31, 0.65),
		Vector2(0.31, 0.48),
		Vector2(0.45, 0.48),
		Vector2(0.45, 0.67),
		Vector2(0.59, 0.67),
		Vector2(0.59, 0.48),
		Vector2(0.74, 0.48),
		Vector2(0.74, 0.65),
		Vector2(0.91, 0.65),
		Vector2(0.96, 0.65),

		Vector2(0.05, 0.86),
		Vector2(0.20, 0.86),
		Vector2(0.20, 0.76),
		Vector2(0.36, 0.76),
		Vector2(0.36, 0.91),
		Vector2(0.52, 0.91),
		Vector2(0.52, 0.78),
		Vector2(0.68, 0.78),
		Vector2(0.68, 0.91),
		Vector2(0.84, 0.91),
		Vector2(0.84, 0.79),
		Vector2(0.96, 0.79)
	]

	conexoes = [
		Vector2i(0, 1),
		Vector2i(1, 2),
		Vector2i(2, 3),
		Vector2i(3, 4),
		Vector2i(4, 5),
		Vector2i(5, 6),
		Vector2i(6, 7),
		Vector2i(7, 8),
		Vector2i(8, 9),
		Vector2i(9, 10),
		Vector2i(10, 11),
		Vector2i(11, 12),

		Vector2i(13, 14),
		Vector2i(14, 15),
		Vector2i(15, 16),
		Vector2i(16, 17),
		Vector2i(17, 18),
		Vector2i(18, 19),
		Vector2i(19, 20),
		Vector2i(20, 21),
		Vector2i(21, 22),
		Vector2i(22, 23),
		Vector2i(23, 24),
		Vector2i(24, 25),

		Vector2i(26, 27),
		Vector2i(27, 28),
		Vector2i(28, 29),
		Vector2i(29, 30),
		Vector2i(30, 31),
		Vector2i(31, 32),
		Vector2i(32, 33),
		Vector2i(33, 34),
		Vector2i(34, 35),
		Vector2i(35, 36),
		Vector2i(36, 37),

		# CONEXOES ENTRE AS TRILHAS
		Vector2i(2, 14),
		Vector2i(6, 18),
		Vector2i(10, 22),
		Vector2i(15, 28),
		Vector2i(19, 32),
		Vector2i(23, 36)
	]

	# CRIAR GRAFO
	grafo.clear()

	for i in range(pontos.size()):
		grafo[i] = []

	# CONECTAR OS PONTOS
	for conexao in conexoes:

		if conexao.x < 0 or conexao.y < 0:
			continue

		if conexao.x >= pontos.size() or conexao.y >= pontos.size():
			push_warning("Conexão inválida: %s -> %s" % [conexao.x, conexao.y])
			continue

		grafo[conexao.x].append(conexao.y)
		grafo[conexao.y].append(conexao.x)


# --------------------------------------------------
# PULSOS DE ENERGIA
# --------------------------------------------------

func criar_pulso() -> void:

	if pontos.is_empty() or grafo.is_empty():
		return

	var inicio := randi_range(0, pontos.size() - 1)

	if not grafo.has(inicio):
		return

	var vizinhos: Array = grafo[inicio]

	if vizinhos.is_empty():
		return

	var destino: int = vizinhos[randi_range(0, vizinhos.size() - 1)]

	pulsos.append({
		"origem": inicio,
		"destino": destino,
		"anterior": -1,
		"progresso": randf()
	})


func animar_pulsos(delta: float) -> void:

	for pulso in pulsos:

		pulso["progresso"] += delta * velocidade_pulso

		if pulso["progresso"] >= 1.0:

			var anterior: int = pulso["origem"]
			var atual: int = pulso["destino"]

			pulso["anterior"] = anterior
			pulso["origem"] = atual
			pulso["progresso"] = 0.0

			var vizinhos: Array = grafo[atual]
			var opcoes: Array = []

			for vizinho in vizinhos:
				if vizinho != anterior:
					opcoes.append(vizinho)

			if opcoes.is_empty():
				opcoes = vizinhos

			if not opcoes.is_empty():
				pulso["destino"] = opcoes[randi_range(0, opcoes.size() - 1)]


# --------------------------------------------------
# DESENHO DOS CIRCUITOS
# --------------------------------------------------

func desenhar_circuitos() -> void:

	for conexao in conexoes:

		var inicio: Vector2 = pontos[conexao.x] * size
		var fim: Vector2 = pontos[conexao.y] * size

		draw_line(
			inicio,
			fim,
			Color(0.0, 0.55, 0.75, 0.10),
			7.0,
			true
		)

		draw_line(
			inicio,
			fim,
			Color(0.02, 0.35, 0.48, 0.55),
			1.5,
			true
		)

	# TERMINAIS
	for i in range(pontos.size()):

		var posicao: Vector2 = pontos[i] * size

		draw_circle(
			posicao,
			3.0,
			Color(0.0, 0.75, 1.0, 0.35)
		)

	# PULSOS
	for pulso in pulsos:

		var inicio: Vector2 = pontos[pulso["origem"]] * size
		var fim: Vector2 = pontos[pulso["destino"]] * size

		var posicao: Vector2 = inicio.lerp(
			fim,
			pulso["progresso"]
		)

		draw_line(
			inicio,
			posicao,
			Color(0.0, 0.85, 1.0, 0.35),
			5.0,
			true
		)

		draw_circle(
			posicao,
			10.0,
			Color(0.0, 0.8, 1.0, 0.12)
		)

		draw_circle(
			posicao,
			5.0,
			CIANO
		)

		draw_circle(
			posicao,
			2.0,
			Color.WHITE
		)


func _draw() -> void:

	draw_rect(
		Rect2(Vector2.ZERO, size),
		FUNDO
	)

	desenhar_circuitos()

	# TERMINAIS VERMELHOS
	var terminais := [0, 12, 13, 25, 26, 37]

	for indice in terminais:

		if indice >= 0 and indice < pontos.size():

			var posicao: Vector2 = pontos[indice] * size

			draw_circle(
				posicao,
				5.0,
				Color(VERMELHO, 0.25)
			)

			draw_circle(
				posicao,
				2.0,
				VERMELHO
			)


# --------------------------------------------------
# INTERFACE PRINCIPAL
# --------------------------------------------------

func criar_interface() -> void:

	var coluna := VBoxContainer.new()
	coluna.name = "Interface"

	coluna.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER
	)

	coluna.offset_left = -190
	coluna.offset_right = 190
	coluna.offset_top = -210
	coluna.offset_bottom = 210

	coluna.add_theme_constant_override("separation", 18)
	coluna.mouse_filter = Control.MOUSE_FILTER_PASS

	add_child(coluna)

	# TITULO
	var titulo := Label.new()

	titulo.text = "G00D-PROTOCOL"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo.add_theme_font_size_override("font_size", 39)
	titulo.add_theme_color_override("font_color", CIANO)

	coluna.add_child(titulo)

	# SUBTITULO
	var subtitulo := Label.new()

	subtitulo.text = "SYSTEM INITIALIZATION // 4986"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitulo.add_theme_font_size_override("font_size", 11)
	subtitulo.add_theme_color_override("font_color", CIANO_ESCURO)

	coluna.add_child(subtitulo)

	# SEPARADOR
	var separador := ColorRect.new()

	separador.custom_minimum_size = Vector2(280, 2)
	separador.color = CIANO_ESCURO

	coluna.add_child(separador)

	# PAINEL DOS BOTOES
	painel_menu = PanelContainer.new()

	painel_menu.add_theme_stylebox_override(
		"panel",
		criar_estilo_painel()
	)

	coluna.add_child(painel_menu)

	var botoes := VBoxContainer.new()
	botoes.add_theme_constant_override("separation", 10)

	painel_menu.add_child(botoes)

	adicionar_botao(botoes, "NOVO JOGO", iniciar_jogo)
	adicionar_botao(botoes, "CONFIGURAÇÕES", abrir_configuracoes)
	adicionar_botao(botoes, "CRÉDITOS", abrir_creditos)
	adicionar_botao(botoes, "SAIR", sair_jogo)

	# RODAPE
	var rodape := Label.new()

	rodape.text = "G00D SYSTEMS  //  VERSION 1.0"
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	rodape.add_theme_font_size_override("font_size", 10)
	rodape.add_theme_color_override("font_color", Color("#466273"))

	coluna.add_child(rodape)

	criar_painel_extra()


# --------------------------------------------------
# ESTILOS
# --------------------------------------------------

func criar_estilo_painel() -> StyleBoxFlat:

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color(0.015, 0.045, 0.075, 0.88)
	estilo.border_color = Color(0.0, 0.65, 0.85, 0.65)

	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)

	estilo.content_margin_left = 20
	estilo.content_margin_right = 20
	estilo.content_margin_top = 20
	estilo.content_margin_bottom = 20

	return estilo


func criar_estilo_botao(hover: bool = false) -> StyleBoxFlat:

	var estilo := StyleBoxFlat.new()

	if hover:
		estilo.bg_color = Color(0.0, 0.45, 0.58, 0.45)
		estilo.border_color = CIANO
	else:
		estilo.bg_color = Color(0.01, 0.08, 0.13, 0.65)
		estilo.border_color = Color(0.0, 0.45, 0.62, 0.55)

	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(3)

	estilo.content_margin_left = 15
	estilo.content_margin_right = 15
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10

	return estilo


func adicionar_botao(
	container: VBoxContainer,
	texto: String,
	acao: Callable
) -> void:

	var botao := Button.new()

	botao.text = texto
	botao.custom_minimum_size = Vector2(300, 48)
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	botao.add_theme_font_size_override("font_size", 15)

	botao.add_theme_color_override("font_color", BRANCO)
	botao.add_theme_color_override("font_hover_color", CIANO)
	botao.add_theme_color_override("font_pressed_color", Color.WHITE)

	botao.add_theme_stylebox_override(
		"normal",
		criar_estilo_botao()
	)

	botao.add_theme_stylebox_override(
		"hover",
		criar_estilo_botao(true)
	)

	botao.add_theme_stylebox_override(
		"pressed",
		criar_estilo_botao(true)
	)

	botao.add_theme_stylebox_override(
		"focus",
		StyleBoxEmpty.new()
	)

	botao.pressed.connect(acao)

	container.add_child(botao)


# --------------------------------------------------
# PAINEIS SECUNDARIOS
# --------------------------------------------------

func criar_painel_extra() -> void:

	painel_extra = PanelContainer.new()

	painel_extra.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER
	)

	painel_extra.offset_left = -220
	painel_extra.offset_right = 220
	painel_extra.offset_top = -130
	painel_extra.offset_bottom = 130

	painel_extra.add_theme_stylebox_override(
		"panel",
		criar_estilo_painel()
	)

	painel_extra.visible = false

	add_child(painel_extra)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)

	painel_extra.add_child(coluna)

	titulo_extra = Label.new()

	titulo_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_extra.add_theme_font_size_override("font_size", 24)
	titulo_extra.add_theme_color_override("font_color", CIANO)

	coluna.add_child(titulo_extra)

	texto_extra = Label.new()

	texto_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_extra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_extra.custom_minimum_size = Vector2(380, 90)

	texto_extra.add_theme_color_override("font_color", BRANCO)

	coluna.add_child(texto_extra)

	var voltar := Button.new()

	voltar.text = "VOLTAR"
	voltar.custom_minimum_size = Vector2(150, 42)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	voltar.pressed.connect(fechar_painel_extra)

	voltar.add_theme_stylebox_override(
		"normal",
		criar_estilo_botao()
	)

	voltar.add_theme_stylebox_override(
		"hover",
		criar_estilo_botao(true)
	)

	voltar.add_theme_color_override("font_color", BRANCO)
	voltar.add_theme_color_override("font_hover_color", CIANO)

	coluna.add_child(voltar)



func abrir_configuracoes() -> void:
	var caminho := "res://scenes/UI/config.tscn"

	if ResourceLoader.exists(caminho):
		var resultado := get_tree().change_scene_to_file(caminho)

		if resultado != OK:
			push_error("Erro ao abrir configurações: " + str(resultado))
	else:
		push_error("Cena de configurações não encontrada: " + caminho)


func abrir_creditos() -> void:

	titulo_extra.text = "CRÉDITOS"

	texto_extra.text = "G00D-PROTOCOL\n\nDesenvolvimento por:\n\n Tarrique Santos(Tanque), Ataliba(Anibal) e
	 Victória(Vitrola)\n"

	painel_extra.visible = true
	painel_menu.visible = false


func fechar_painel_extra() -> void:

	painel_extra.visible = false
	painel_menu.visible = true


# --------------------------------------------------
# ACOES DOS BOTOES
# --------------------------------------------------

func iniciar_jogo() -> void:

	if ResourceLoader.exists(cena_jogo):
		get_tree().change_scene_to_file(cena_jogo)
	else:
		push_error("Cena do jogo não encontrada: " + cena_jogo)


func sair_jogo() -> void:

	get_tree().quit()
