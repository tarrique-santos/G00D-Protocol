
extends Control

@export var cena_menu: String = "res://scenes/UI/home.tscn"

var mensagem_morte: String = "CAUSA DA MORTE DESCONHECIDA"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	criar_interface()
	
func definir_causa_morte(causa: String) -> void:
	mensagem_morte = causa


func criar_interface() -> void:
	var fundo = ColorRect.new()
	fundo.color = Color(0.015, 0.01, 0.015, 0.96)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)

	var central = CenterContainer.new()
	central.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	central.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	central.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(central)

	# Painel principal
	var painel = PanelContainer.new()
	painel.custom_minimum_size = Vector2(520, 350)
	central.add_child(painel)

	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.045, 0.035, 0.045, 1.0)
	estilo.border_color = Color(0.65, 0.05, 0.08)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 35
	estilo.content_margin_right = 35
	estilo.content_margin_top = 30
	estilo.content_margin_bottom = 30

	painel.add_theme_stylebox_override("panel", estilo)

	# Conteúdo
	var conteudo = VBoxContainer.new()
	conteudo.add_theme_constant_override("separation", 18)
	painel.add_child(conteudo)

	# Identificação do sistema
	var identificacao = Label.new()
	identificacao.text = "G00D PROTOCOL // SYSTEM FAILURE"
	identificacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identificacao.add_theme_font_size_override("font_size", 13)
	identificacao.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	conteudo.add_child(identificacao)

	# Título
	var titulo = Label.new()
	titulo.text = "GAME OVER"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 48)
	titulo.add_theme_color_override("font_color", Color(0.95, 0.08, 0.12))
	conteudo.add_child(titulo)

	# Separador
	var separador = HSeparator.new()
	conteudo.add_child(separador)

	# Mensagem
	var descricao = Label.new()
	descricao.text = "UNIDADE G00D DESTRUÍDA"
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.add_theme_font_size_override("font_size", 18)
	descricao.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	conteudo.add_child(descricao)

	# Causa da morte
	var causa = Label.new()
	causa.text = mensagem_morte
	causa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	causa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	causa.custom_minimum_size.y = 45
	causa.add_theme_font_size_override("font_size", 15)
	causa.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	conteudo.add_child(causa)

	# Espaçamento
	var espaco = Control.new()
	espaco.custom_minimum_size.y = 5
	conteudo.add_child(espaco)

	# Botão tentar novamente
	var tentar = Button.new()
	tentar.text = "TENTAR NOVAMENTE"
	tentar.custom_minimum_size.y = 45
	conteudo.add_child(tentar)
	tentar.pressed.connect(reiniciar_jogo)

	# Botão sair
	var sair = Button.new()
	sair.text = "VOLTAR AO MENU"
	sair.custom_minimum_size.y = 45
	conteudo.add_child(sair)
	sair.pressed.connect(voltar_menu)

	# Estilo dos botões
	for botao in [tentar, sair]:
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.12, 0.035, 0.045)
		normal.border_color = Color(0.65, 0.08, 0.12)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(4)

		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(0.55, 0.035, 0.06)
		hover.set_corner_radius_all(4)

		botao.add_theme_stylebox_override("normal", normal)
		botao.add_theme_stylebox_override("hover", hover)
		botao.add_theme_color_override("font_color", Color.WHITE)
		botao.add_theme_font_size_override("font_size", 15)


func reiniciar_jogo() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func voltar_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(cena_menu)
