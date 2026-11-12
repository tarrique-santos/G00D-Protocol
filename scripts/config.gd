
extends Control

@export_file("*.tscn") var cena_retorno: String = "res://scenes/UI/home.tscn"

const ARQUIVO_CONFIG := "user://g00d_config.cfg"

const FUNDO := Color("#050b14")
const PAINEL := Color("#0b1927")
const CIANO := Color("#00d9ff")
const CIANO_ESCURO := Color("#087b9c")
const VERMELHO := Color("#ff304f")
const BRANCO := Color("#dcecf5")

var configuracao := ConfigFile.new()

var resolucao: OptionButton
var modo_tela: OptionButton
var vsync: OptionButton

var volume_geral: HSlider
var volume_musica: HSlider
var volume_efeitos: HSlider

var sensibilidade: HSlider
var inverter_vertical: CheckButton

var texto_sensibilidade: Label
var texto_volume_geral: Label
var texto_volume_musica: Label
var texto_volume_efeitos: Label

var resolucoes := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]


func _ready() -> void:
	randomize()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	criar_buses_audio()
	carregar_configuracoes()

	# A tela de configurações sempre abre em tela cheia.
	# O jogador ainda pode escolher "Janela" ou "Tela cheia exclusiva".
	configuracao.set_value("video", "modo", 1)

	criar_interface()
	aplicar_configuracoes()


# --------------------------------------------------
# CONFIGURACAO DE AUDIO
# --------------------------------------------------

func criar_buses_audio() -> void:
	criar_bus_se_nao_existir("Music")
	criar_bus_se_nao_existir("SFX")


func criar_bus_se_nao_existir(nome: String) -> void:
	if AudioServer.get_bus_index(nome) != -1:
		return

	var indice := AudioServer.bus_count

	AudioServer.add_bus(indice)
	AudioServer.set_bus_name(indice, nome)
	AudioServer.set_bus_send(indice, "Master")


func aplicar_volume(nome: String, valor: float) -> void:
	var indice := AudioServer.get_bus_index(nome)

	if indice == -1:
		return

	if valor <= 0.0:
		AudioServer.set_bus_volume_db(indice, -80.0)
	else:
		AudioServer.set_bus_volume_db(
			indice,
			linear_to_db(valor / 100.0)
		)


# --------------------------------------------------
# CARREGAR E SALVAR
# --------------------------------------------------

func carregar_configuracoes() -> void:
	var erro := configuracao.load(ARQUIVO_CONFIG)

	if erro != OK:
		configuracao = ConfigFile.new()

		configuracao.set_value("video", "resolucao", 1920)
		configuracao.set_value("video", "altura", 1080)
		configuracao.set_value("video", "modo", 1)
		configuracao.set_value("video", "vsync", 1)

		configuracao.set_value("audio", "geral", 100.0)
		configuracao.set_value("audio", "musica", 80.0)
		configuracao.set_value("audio", "efeitos", 100.0)

		configuracao.set_value("gameplay", "sensibilidade", 50.0)
		configuracao.set_value("gameplay", "inverter_vertical", false)


func salvar_configuracoes() -> void:
	configuracao.set_value(
		"video",
		"resolucao",
		resolucoes[resolucao.selected].x
	)

	configuracao.set_value(
		"video",
		"altura",
		resolucoes[resolucao.selected].y
	)

	configuracao.set_value(
		"video",
		"modo",
		modo_tela.get_selected_id()
	)

	configuracao.set_value(
		"video",
		"vsync",
		vsync.get_selected_id()
	)

	configuracao.set_value("audio", "geral", volume_geral.value)
	configuracao.set_value("audio", "musica", volume_musica.value)
	configuracao.set_value("audio", "efeitos", volume_efeitos.value)

	configuracao.set_value("gameplay", "sensibilidade", sensibilidade.value)
	configuracao.set_value(
		"gameplay",
		"inverter_vertical",
		inverter_vertical.button_pressed
	)

	var erro := configuracao.save(ARQUIVO_CONFIG)

	if erro != OK:
		push_error("Não foi possível salvar as configurações.")
	else:
		print("Configurações salvas!")


# --------------------------------------------------
# APLICAR CONFIGURACOES
# --------------------------------------------------

func aplicar_configuracoes() -> void:
	aplicar_video()
	aplicar_audio()


func aplicar_video() -> void:
	var largura: int = int(
		configuracao.get_value("video", "resolucao", 1920)
	)

	var altura: int = int(
		configuracao.get_value("video", "altura", 1080)
	)

	var modo: int = int(
		configuracao.get_value("video", "modo", 0)
	)

	var sincronizacao: int = int(
		configuracao.get_value("video", "vsync", 1)
	)

	var tamanho := Vector2i(largura, altura)

	if modo == 0:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)

		DisplayServer.window_set_size(tamanho)

	elif modo == 1:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)

	elif modo == 2:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)

	match sincronizacao:
		0:
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_DISABLED
			)
		1:
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED
			)
		2:
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ADAPTIVE
			)


func aplicar_audio() -> void:
	var geral := float(
		configuracao.get_value("audio", "geral", 100.0)
	)

	var musica := float(
		configuracao.get_value("audio", "musica", 80.0)
	)

	var efeitos := float(
		configuracao.get_value("audio", "efeitos", 100.0)
	)

	aplicar_volume("Master", geral)
	aplicar_volume("Music", musica)
	aplicar_volume("SFX", efeitos)


# --------------------------------------------------
# INTERFACE
# --------------------------------------------------

func criar_interface() -> void:
	var fundo := ColorRect.new()
	fundo.color = FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	margem.add_theme_constant_override("margin_left", 45)
	margem.add_theme_constant_override("margin_right", 45)
	margem.add_theme_constant_override("margin_top", 25)
	margem.add_theme_constant_override("margin_bottom", 25)

	add_child(margem)

	var estrutura := VBoxContainer.new()
	estrutura.add_theme_constant_override("separation", 15)
	margem.add_child(estrutura)

	criar_cabecalho(estrutura)

	var separador := ColorRect.new()
	separador.custom_minimum_size.y = 2
	separador.color = CIANO_ESCURO
	estrutura.add_child(separador)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	estrutura.add_child(scroll)

	var conteudo := VBoxContainer.new()
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 16)
	scroll.add_child(conteudo)

	criar_secao_video(conteudo)
	criar_secao_audio(conteudo)
	criar_secao_gameplay(conteudo)
	criar_secao_controles(conteudo)

	criar_rodape(estrutura)

	carregar_valores_interface()


func criar_cabecalho(container: VBoxContainer) -> void:
	var linha := HBoxContainer.new()
	container.add_child(linha)

	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "CONFIGURAÇÕES"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", CIANO)
	coluna.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "G00D SYSTEMS // SYSTEM PREFERENCES"
	subtitulo.add_theme_font_size_override("font_size", 11)
	subtitulo.add_theme_color_override("font_color", CIANO_ESCURO)
	coluna.add_child(subtitulo)

	var versao := Label.new()
	versao.text = "G00D // 4986"
	versao.add_theme_color_override("font_color", BRANCO)
	versao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(versao)


# --------------------------------------------------
# SECAO DE VIDEO
# --------------------------------------------------

func criar_secao_video(container: VBoxContainer) -> void:
	var painel := criar_secao(container, "01 // VÍDEO")

	resolucao = OptionButton.new()

	for tamanho in resolucoes:
		resolucao.add_item(
			"%d x %d" % [tamanho.x, tamanho.y],
			tamanho.x
		)

	resolucao.item_selected.connect(
		func(_indice: int) -> void:
			aplicar_video_atual()
	)

	adicionar_opcao(painel, "Resolução", resolucao)

	modo_tela = OptionButton.new()
	modo_tela.add_item("Janela", 0)
	modo_tela.add_item("Tela cheia", 1)
	modo_tela.add_item("Tela cheia exclusiva", 2)

	modo_tela.item_selected.connect(
		func(_indice: int) -> void:
			aplicar_video_atual()
	)

	adicionar_opcao(painel, "Modo de exibição", modo_tela)

	vsync = OptionButton.new()
	vsync.add_item("Desativado", 0)
	vsync.add_item("Ativado", 1)
	vsync.add_item("Adaptativo", 2)

	vsync.item_selected.connect(
		func(_indice: int) -> void:
			aplicar_video_atual()
	)

	adicionar_opcao(painel, "Sincronização vertical", vsync)


func aplicar_video_atual() -> void:
	configuracao.set_value(
		"video",
		"resolucao",
		resolucoes[resolucao.selected].x
	)

	configuracao.set_value(
		"video",
		"altura",
		resolucoes[resolucao.selected].y
	)

	configuracao.set_value(
		"video",
		"modo",
		modo_tela.get_selected_id()
	)

	configuracao.set_value(
		"video",
		"vsync",
		vsync.get_selected_id()
	)

	aplicar_video()


# --------------------------------------------------
# SECAO DE AUDIO
# --------------------------------------------------

func criar_secao_audio(container: VBoxContainer) -> void:
	var painel := criar_secao(container, "02 // ÁUDIO")

	volume_geral = criar_slider(0, 100, 1)
	volume_geral.value_changed.connect(
		func(valor: float) -> void:
			texto_volume_geral.text = "%d%%" % roundi(valor)
			aplicar_volume("Master", valor)
	)

	texto_volume_geral = Label.new()
	adicionar_slider(painel, "Volume geral", volume_geral, texto_volume_geral)

	volume_musica = criar_slider(0, 100, 1)
	volume_musica.value_changed.connect(
		func(valor: float) -> void:
			texto_volume_musica.text = "%d%%" % roundi(valor)
			aplicar_volume("Music", valor)
	)

	texto_volume_musica = Label.new()
	adicionar_slider(painel, "Música", volume_musica, texto_volume_musica)

	volume_efeitos = criar_slider(0, 100, 1)
	volume_efeitos.value_changed.connect(
		func(valor: float) -> void:
			texto_volume_efeitos.text = "%d%%" % roundi(valor)
			aplicar_volume("SFX", valor)
	)

	texto_volume_efeitos = Label.new()
	adicionar_slider(painel, "Efeitos sonoros", volume_efeitos, texto_volume_efeitos)


# --------------------------------------------------
# SECAO DE GAMEPLAY
# --------------------------------------------------

func criar_secao_gameplay(container: VBoxContainer) -> void:
	var painel := criar_secao(container, "03 // JOGABILIDADE")

	sensibilidade = criar_slider(1, 100, 1)

	sensibilidade.value_changed.connect(
		func(valor: float) -> void:
			texto_sensibilidade.text = "%d%%" % roundi(valor)
	)

	texto_sensibilidade = Label.new()

	adicionar_slider(
		painel,
		"Sensibilidade do mouse",
		sensibilidade,
		texto_sensibilidade
	)

	inverter_vertical = CheckButton.new()
	inverter_vertical.text = "Ativar inversão vertical"
	inverter_vertical.add_theme_color_override("font_color", BRANCO)

	painel.add_child(inverter_vertical)


# --------------------------------------------------
# SECAO DE CONTROLES
# --------------------------------------------------

func criar_secao_controles(container: VBoxContainer) -> void:
	var painel := criar_secao(container, "04 // CONTROLES")

	var comandos := [
		["W A S D", "Movimentação"],
		["ESPAÇO", "Pular / Pulo duplo"],
		["SHIFT", "Dash"],
		["BOTÃO ESQUERDO", "Atirar"],
		["BOTÃO DIREITO", "Parry / Ataque físico"],
		["MOUSE", "Movimentar câmera"],
		["ESC", "Pausar jogo"],
	]

	for comando in comandos:
		var linha := HBoxContainer.new()
		painel.add_child(linha)

		var tecla := Label.new()
		tecla.text = comando[0]
		tecla.custom_minimum_size.x = 180
		tecla.add_theme_color_override("font_color", CIANO)
		linha.add_child(tecla)

		var descricao := Label.new()
		descricao.text = comando[1]
		descricao.add_theme_color_override("font_color", BRANCO)
		linha.add_child(descricao)


# --------------------------------------------------
# COMPONENTES
# --------------------------------------------------

func criar_secao(container: VBoxContainer, titulo: String) -> VBoxContainer:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", estilo_painel())
	container.add_child(painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)

	var texto := Label.new()
	texto.text = titulo
	texto.add_theme_font_size_override("font_size", 17)
	texto.add_theme_color_override("font_color", CIANO)
	coluna.add_child(texto)

	var separador := ColorRect.new()
	separador.custom_minimum_size.y = 1
	separador.color = CIANO_ESCURO
	coluna.add_child(separador)

	return coluna


func adicionar_opcao(
	container: VBoxContainer,
	nome: String,
	opcao: OptionButton
) -> void:
	var linha := HBoxContainer.new()
	container.add_child(linha)

	var texto := Label.new()
	texto.text = nome
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.add_theme_color_override("font_color", BRANCO)
	linha.add_child(texto)

	opcao.custom_minimum_size.x = 230
	linha.add_child(opcao)


func criar_slider(
	minimo: float,
	maximo: float,
	passo: float
) -> HSlider:
	var slider := HSlider.new()

	slider.min_value = minimo
	slider.max_value = maximo
	slider.step = passo
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 200

	return slider


func adicionar_slider(
	container: VBoxContainer,
	nome: String,
	slider: HSlider,
	valor_texto: Label
) -> void:
	var linha := HBoxContainer.new()
	container.add_child(linha)

	var titulo := Label.new()
	titulo.text = nome
	titulo.custom_minimum_size.x = 180
	titulo.add_theme_color_override("font_color", BRANCO)
	linha.add_child(titulo)

	linha.add_child(slider)

	valor_texto.custom_minimum_size.x = 55
	valor_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valor_texto.add_theme_color_override("font_color", CIANO)

	linha.add_child(valor_texto)


func estilo_painel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color(0.025, 0.065, 0.10, 0.92)
	estilo.border_color = Color(0.0, 0.55, 0.75, 0.55)

	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)

	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 15
	estilo.content_margin_bottom = 15

	return estilo


# --------------------------------------------------
# VALORES DA INTERFACE
# --------------------------------------------------

func carregar_valores_interface() -> void:
	var largura := int(
		configuracao.get_value("video", "resolucao", 1920)
	)

	var altura := int(
		configuracao.get_value("video", "altura", 1080)
	)

	var indice_resolucao := 3

	for i in range(resolucoes.size()):
		if resolucoes[i] == Vector2i(largura, altura):
			indice_resolucao = i
			break

	resolucao.select(indice_resolucao)

	modo_tela.select(
		int(configuracao.get_value("video", "modo", 0))
	)

	vsync.select(
		int(configuracao.get_value("video", "vsync", 1))
	)

	volume_geral.value = float(
		configuracao.get_value("audio", "geral", 100.0)
	)

	volume_musica.value = float(
		configuracao.get_value("audio", "musica", 80.0)
	)

	volume_efeitos.value = float(
		configuracao.get_value("audio", "efeitos", 100.0)
	)

	sensibilidade.value = float(
		configuracao.get_value("gameplay", "sensibilidade", 50.0)
	)

	inverter_vertical.button_pressed = bool(
		configuracao.get_value("gameplay", "inverter_vertical", false)
	)

	texto_volume_geral.text = "%d%%" % roundi(volume_geral.value)
	texto_volume_musica.text = "%d%%" % roundi(volume_musica.value)
	texto_volume_efeitos.text = "%d%%" % roundi(volume_efeitos.value)
	texto_sensibilidade.text = "%d%%" % roundi(sensibilidade.value)


# --------------------------------------------------
# RODAPE E BOTOES
# --------------------------------------------------

func criar_rodape(container: VBoxContainer) -> void:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 15)
	container.add_child(linha)

	var salvar := criar_botao("SALVAR", CIANO)
	salvar.pressed.connect(salvar_configuracoes)
	linha.add_child(salvar)

	var padrao := criar_botao("RESTAURAR PADRÕES", BRANCO)
	padrao.pressed.connect(restaurar_padrao)
	linha.add_child(padrao)

	var voltar := criar_botao("VOLTAR", VERMELHO)
	voltar.pressed.connect(voltar_menu)
	linha.add_child(voltar)


func criar_botao(nome: String, cor: Color) -> Button:
	var botao := Button.new()

	botao.text = nome
	botao.custom_minimum_size = Vector2(175, 45)
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	botao.add_theme_color_override("font_color", BRANCO)
	botao.add_theme_color_override("font_hover_color", cor)
	botao.add_theme_font_size_override("font_size", 12)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.01, 0.06, 0.10, 0.95)
	normal.border_color = cor
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.0, 0.30, 0.42, 0.85)
	hover.border_color = cor
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(3)

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", hover)
	botao.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	return botao


func restaurar_padrao() -> void:
	configuracao = ConfigFile.new()

	configuracao.set_value("video", "resolucao", 1920)
	configuracao.set_value("video", "altura", 1080)
	configuracao.set_value("video", "modo", 1)
	configuracao.set_value("video", "vsync", 1)

	configuracao.set_value("audio", "geral", 100.0)
	configuracao.set_value("audio", "musica", 80.0)
	configuracao.set_value("audio", "efeitos", 100.0)

	configuracao.set_value("gameplay", "sensibilidade", 50.0)
	configuracao.set_value("gameplay", "inverter_vertical", false)

	carregar_valores_interface()
	aplicar_configuracoes()

	salvar_configuracoes()


func voltar_menu() -> void:
	salvar_configuracoes()

	if ResourceLoader.exists(cena_retorno):
		get_tree().change_scene_to_file(cena_retorno)
	else:
		push_error("Cena de retorno não encontrada: " + cena_retorno)
