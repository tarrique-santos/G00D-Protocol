
extends CanvasLayer

@export_group("Configuracao")
@export var largura_janela: float = 680.0
@export var altura_janela: float = 190.0
@export var distancia_topo: float = 24.0

@export var tempo_entrada: float = 0.4
@export var tempo_saida: float = 0.8

var painel: PanelContainer
var cabecalho_label: Label
var titulo_label: Label
var objetivo_label: Label
var descricao_label: Label
var rodape_label: Label

var animacao: Tween


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	criar_interface()


# ==========================================
# CRIAR INTERFACE
# ==========================================

func criar_interface():

	painel = PanelContainer.new()
	painel.name = "PainelMissao"

	painel.anchor_left = 0.5
	painel.anchor_right = 0.5
	painel.anchor_top = 0.0
	painel.anchor_bottom = 0.0

	painel.offset_left = -largura_janela / 2.0
	painel.offset_right = largura_janela / 2.0
	painel.offset_top = distancia_topo
	painel.offset_bottom = distancia_topo + altura_janela

	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.visible = false

	add_child(painel)

	# Estilo do painel
	var estilo = StyleBoxFlat.new()

	estilo.bg_color = Color(0.025, 0.045, 0.07, 0.94)

	estilo.set_border_width_all(2)
	estilo.border_color = Color(0.1, 0.65, 0.85, 0.9)

	estilo.set_corner_radius_all(8)

	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 14
	estilo.content_margin_bottom = 14

	estilo.shadow_color = Color(0.0, 0.5, 0.8, 0.2)
	estilo.shadow_size = 10

	painel.add_theme_stylebox_override("panel", estilo)

	# Organização dos textos
	var coluna = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)

	painel.add_child(coluna)

	# Cabeçalho
	cabecalho_label = criar_label(
		13,
		Color(0.3, 0.8, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)

	coluna.add_child(cabecalho_label)

	# Título
	titulo_label = criar_label(
		23,
		Color(0.95, 0.97, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)

	coluna.add_child(titulo_label)

	# Objetivo
	objetivo_label = criar_label(
		15,
		Color(0.3, 0.8, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)

	coluna.add_child(objetivo_label)

	# Descrição
	descricao_label = criar_label(
		14,
		Color(0.8, 0.85, 0.9),
		HORIZONTAL_ALIGNMENT_CENTER
	)

	descricao_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	coluna.add_child(descricao_label)

	# Rodapé
	rodape_label = criar_label(
		12,
		Color(0.3, 0.8, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)

	coluna.add_child(rodape_label)


func criar_label(
	tamanho: int,
	cor: Color,
	alinhamento: HorizontalAlignment
) -> Label:

	var label = Label.new()

	label.horizontal_alignment = alinhamento
	label.add_theme_color_override("font_color", cor)
	label.add_theme_font_size_override("font_size", tamanho)

	return label


# ==========================================
# MOSTRAR MENSAGEM
# ==========================================

func mostrar_mensagem(
	titulo: String,
	objetivo: String,
	descricao: String,
	duracao: float = 8.0,
	cabecalho: String = "G00D PROTOCOL // TRANSMISSAO",
	rodape: String = "BOA SORTE, G00D."
):

	# Interromper mensagem anterior, caso exista
	if animacao and animacao.is_running():
		animacao.kill()

	# Atualizar os textos
	cabecalho_label.text = cabecalho
	titulo_label.text = titulo
	objetivo_label.text = objetivo
	descricao_label.text = descricao
	rodape_label.text = rodape

	# Exibir painel
	painel.visible = true
	painel.modulate.a = 0.0

	# Animação de entrada
	animacao = create_tween()

	animacao.tween_property(
		painel,
		"modulate:a",
		1.0,
		tempo_entrada
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Tempo de exibição
	if duracao > 0.0:

		animacao.tween_interval(duracao)

		# Desaparecimento
		animacao.tween_property(
			painel,
			"modulate:a",
			0.0,
			tempo_saida
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

		animacao.tween_callback(esconder_mensagem)


# ==========================================
# ESCONDER MENSAGEM
# ==========================================

func esconder_mensagem():

	if animacao and animacao.is_running():
		animacao.kill()

	painel.visible = false
