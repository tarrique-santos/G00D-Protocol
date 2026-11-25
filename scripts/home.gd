
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
var segmento_hover := -1
var posicao_mouse := Vector2.ZERO
var tempo_hover := 0.0
var particulas_hover: Array[Dictionary] = []

# Nó AudioStreamPlayer filho direto do Control, chamado "soundtrack".
@onready var soundtrack: AudioStreamPlayer = $soundtrack
var tempo_soundtrack := 0.0
const INTERVALO_SOUNDTRACK := 65.0

# INTERFACE
var painel_menu: PanelContainer
var painel_extra: PanelContainer
var titulo_extra: Label
var texto_extra: Label


func _ready() -> void:
	randomize()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	criar_circuitos()
	criar_interface()

	for i in range(12):
		criar_pulso()

	if soundtrack:
		soundtrack.play()
		tempo_soundtrack = 0.0
	else:
		push_warning("Nó 'soundtrack' não encontrado. Adicione um AudioStreamPlayer como filho do Control.")

	queue_redraw()


func _process(delta: float) -> void:
	animar_pulsos(delta)
	animar_hover(delta)
	animar_soundtrack(delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		posicao_mouse = get_local_mouse_position()
		atualizar_segmento_hover()


func animar_soundtrack(delta: float) -> void:
	if not soundtrack:
		return

	tempo_soundtrack += delta
	if tempo_soundtrack >= INTERVALO_SOUNDTRACK:
		tempo_soundtrack = 0.0
		soundtrack.stop()
		soundtrack.play()


func atualizar_segmento_hover() -> void:
	segmento_hover = -1
	var menor_distancia := 999999.0

	for i in range(conexoes.size()):
		var conexao := conexoes[i]
		var inicio := pontos[conexao.x] * size
		var fim := pontos[conexao.y] * size
		var mais_proximo := Geometry2D.get_closest_point_to_segment(posicao_mouse, inicio, fim)
		var distancia := posicao_mouse.distance_to(mais_proximo)

		if distancia < 18.0 and distancia < menor_distancia:
			menor_distancia = distancia
			segmento_hover = i

	if segmento_hover >= 0:
		tempo_hover = 0.0
		for i in range(3):
			particulas_hover.append({
				"posicao": posicao_mouse + Vector2(randf_range(-8, 8), randf_range(-8, 8)),
				"velocidade": Vector2(randf_range(-55, 55), randf_range(-55, 55)),
				"vida": randf_range(0.18, 0.4)
			})


func animar_hover(delta: float) -> void:
	tempo_hover += delta

	for i in range(particulas_hover.size() - 1, -1, -1):
		var particula: Dictionary = particulas_hover[i]
		particula["vida"] -= delta
		particula["posicao"] += particula["velocidade"] * delta
		particula["velocidade"] *= 0.94
		if particula["vida"] <= 0.0:
			particulas_hover.remove_at(i)

	if particulas_hover.size() > 45:
		particulas_hover = particulas_hover.slice(particulas_hover.size() - 45)


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
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 8),
		Vector2i(8, 9), Vector2i(9, 10), Vector2i(10, 11), Vector2i(11, 12),

		Vector2i(13, 14), Vector2i(14, 15), Vector2i(15, 16), Vector2i(16, 17),
		Vector2i(17, 18), Vector2i(18, 19), Vector2i(19, 20), Vector2i(20, 21),
		Vector2i(21, 22), Vector2i(22, 23), Vector2i(23, 24), Vector2i(24, 25),

		Vector2i(26, 27), Vector2i(27, 28), Vector2i(28, 29), Vector2i(29, 30),
		Vector2i(30, 31), Vector2i(31, 32), Vector2i(32, 33), Vector2i(33, 34),
		Vector2i(34, 35), Vector2i(35, 36), Vector2i(36, 37),

		# Ramificações entre as trilhas, mantendo o desenho original.
		Vector2i(2, 14), Vector2i(6, 18), Vector2i(10, 22),
		Vector2i(15, 28), Vector2i(19, 32), Vector2i(23, 36),

	]

	grafo.clear()
	for i in range(pontos.size()):
		grafo[i] = []

	for conexao in conexoes:
		if conexao.x < 0 or conexao.y < 0:
			continue
		if conexao.x >= pontos.size() or conexao.y >= pontos.size():
			continue
		grafo[conexao.x].append(conexao.y)
		grafo[conexao.y].append(conexao.x)


func proximo_ponto_carrossel(atual: int, anterior: int) -> int:
	var opcoes: Array[int] = []
	for vizinho in grafo[atual]:
		var indice_vizinho: int = int(vizinho)
		if indice_vizinho == anterior:
			continue
		if indice_vizinho > atual:
			opcoes.append(indice_vizinho)

	if opcoes.is_empty():
		for vizinho in grafo[atual]:
			var indice_vizinho: int = int(vizinho)
			if indice_vizinho != anterior:
				opcoes.append(indice_vizinho)

	if opcoes.is_empty():
		return anterior

	return opcoes[randi_range(0, opcoes.size() - 1)]

# --------------------------------------------------
# PULSOS DE ENERGIA
# --------------------------------------------------

func criar_pulso() -> void:

	if pontos.is_empty() or grafo.is_empty():
		return

	var inicio: int = randi_range(0, pontos.size() - 1)
	if inicio == 12:
		inicio = 13
	elif inicio == 25:
		inicio = 26
	elif inicio == 37:
		inicio = 0

	if not grafo.has(inicio):
		return

	var vizinhos: Array = grafo[inicio]

	if vizinhos.is_empty():
		return

	var destino: int = proximo_ponto_carrossel(inicio, -1)

	pulsos.append({
		"origem": inicio,
		"destino": destino,
		"anterior": -1,
		"progresso": randf(),
		"raio": 5.0,
		"energia": 1.0
	})


func animar_pulsos(delta: float) -> void:
	for i in range(pulsos.size()):
		var pulso: Dictionary = pulsos[i]
		var velocidade_atual := velocidade_pulso

		if segmento_hover >= 0:
			var conexao_hover := conexoes[segmento_hover]
			var esta_na_trilha_hover: bool = (
				(pulso["origem"] == conexao_hover.x and pulso["destino"] == conexao_hover.y)
				or (pulso["origem"] == conexao_hover.y and pulso["destino"] == conexao_hover.x)
			)
			if esta_na_trilha_hover:
				velocidade_atual *= 3.2

		pulso["progresso"] += delta * velocidade_atual

		while pulso["progresso"] >= 1.0:
			pulso["progresso"] -= 1.0
			var anterior: int = pulso["origem"]
			var atual: int = pulso["destino"]
			pulso["anterior"] = anterior
			pulso["origem"] = atual

			# Ao alcançar a extremidade direita, reaparece imediatamente no início da próxima trilha.
			if atual == 12:
				pulso["origem"] = 13
				pulso["destino"] = proximo_ponto_carrossel(13, -1)
				pulso["anterior"] = -1
			elif atual == 25:
				pulso["origem"] = 26
				pulso["destino"] = proximo_ponto_carrossel(26, -1)
				pulso["anterior"] = -1
			elif atual == 37:
				pulso["origem"] = 0
				pulso["destino"] = proximo_ponto_carrossel(0, -1)
				pulso["anterior"] = -1
			else:
				var proximo: int = proximo_ponto_carrossel(atual, anterior)
				if proximo != anterior:
					pulso["destino"] = proximo

	# Quando duas esferas se encontram, uma absorve a outra.
	var removidos: Array[int] = []

	for i in range(pulsos.size()):
		if removidos.has(i):
			continue

		var pos_a := _posicao_pulso(pulsos[i])

		for j in range(i + 1, pulsos.size()):
			if removidos.has(j):
				continue

			var pos_b := _posicao_pulso(pulsos[j])
			if pos_a.distance_to(pos_b) < 13.0:
				pulsos[i]["raio"] = minf(float(pulsos[i].get("raio", 5.0)) + 1.8, 10.0)
				pulsos[i]["energia"] = minf(float(pulsos[i].get("energia", 1.0)) + 0.35, 3.0)
				removidos.append(j)

	for i in range(removidos.size() - 1, -1, -1):
		pulsos.remove_at(removidos[i])

	while pulsos.size() < 12:
		criar_pulso()


func _posicao_pulso(pulso: Dictionary) -> Vector2:
	var inicio: Vector2 = pontos[pulso["origem"]] * size
	var fim: Vector2 = pontos[pulso["destino"]] * size
	return inicio.lerp(fim, float(pulso["progresso"]))

# --------------------------------------------------
# DESENHO DOS CIRCUITOS
# --------------------------------------------------

func desenhar_circuitos() -> void:
	for i in range(conexoes.size()):
		var conexao := conexoes[i]
		var inicio: Vector2 = pontos[conexao.x] * size
		var fim: Vector2 = pontos[conexao.y] * size
		var esta_em_hover := i == segmento_hover

		# Halo da trilha.
		draw_line(
			inicio,
			fim,
			Color(0.0, 0.55, 0.95, 0.35 if esta_em_hover else 0.12),
			10.0 if esta_em_hover else 6.0,
			true
		)

		# Linha principal.
		draw_line(
			inicio,
			fim,
			CIANO if esta_em_hover else Color(0.02, 0.35, 0.48, 0.72),
			2.4 if esta_em_hover else 1.5,
			true
		)

		if esta_em_hover:
			for marca in range(1, 5):
				var ponto_marca := inicio.lerp(fim, float(marca) / 5.0)
				var brilho := 0.5 + 0.5 * sin(tempo_hover * 18.0 + marca)
				draw_circle(ponto_marca, 3.0 + brilho * 2.0, Color(0.5, 0.95, 1.0, 0.8))

	# Terminais.
	for i in range(pontos.size()):
		var posicao: Vector2 = pontos[i] * size
		draw_circle(posicao, 5.0, Color(0.0, 0.75, 1.0, 0.15))
		draw_circle(posicao, 2.4, CIANO)

	# Pulsos de energia.
	for pulso in pulsos:
		var posicao := _posicao_pulso(pulso)
		var raio := float(pulso.get("raio", 5.0))
		var energia := float(pulso.get("energia", 1.0))

		draw_circle(posicao, raio * 2.2, Color(0.0, 0.8, 1.0, 0.10 * energia))
		draw_circle(posicao, raio, Color(0.0, 0.85, 1.0, 0.85))
		draw_circle(posicao, maxf(2.0, raio * 0.42), Color.WHITE)

	# Faíscas que saltam quando o mouse toca numa trilha.
	for particula in particulas_hover:
		var alpha := clampf(float(particula["vida"]) / 0.4, 0.0, 1.0)
		draw_circle(particula["posicao"], 2.0, Color(0.55, 0.95, 1.0, alpha))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FUNDO)
	desenhar_circuitos()

	# Terminais de entrada e saída em ambos os lados.
	var terminais: Array[int] = [0, 12, 13, 25, 26, 37]

	for indice in terminais:
		if indice >= 0 and indice < pontos.size():
			var posicao: Vector2 = pontos[indice] * size
			draw_circle(posicao, 7.0, Color(VERMELHO, 0.12))
			draw_circle(posicao, 2.8, VERMELHO)

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

	texto_extra.text = "G00D-PROTOCOL\n\nDesenvolvimento por:\n\nTarrique Santos (Tanque), Ataliba (Anibal) e Victória (Vitrola)\n"

	painel_extra.visible = true
	painel_menu.visible = false


func fechar_painel_extra() -> void:

	painel_extra.visible = false
	painel_menu.visible = true


# --------------------------------------------------
# ACOES DOS BOTOES
# --------------------------------------------------

func iniciar_jogo() -> void:

	# Partida nova começa do zero, sem checkpoint da anterior
	Progresso.resetar()

	if ResourceLoader.exists(cena_jogo):
		get_tree().change_scene_to_file(cena_jogo)
	else:
		push_error("Cena do jogo não encontrada: " + cena_jogo)


func sair_jogo() -> void:

	get_tree().quit()
