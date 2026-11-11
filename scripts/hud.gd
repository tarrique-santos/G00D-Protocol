
extends CanvasLayer

@onready var controle: Control = $Control
@onready var hp_bar: ProgressBar = $Control/HPBar
@onready var hp_texto: Label = $Control/HP
@onready var barra_dash: ProgressBar = $Control/BarraDash
@onready var texto_dash: Label = $Control/TextoDash

var jogador: Node = null

var cor_vermelha := Color("#E83B4D")
var cor_azul := Color("#22BCEB")
var cor_fundo := Color("#080D16")


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_PAUSABLE

	controle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controle.mouse_filter = Control.MOUSE_FILTER_IGNORE

	criar_painel()
	organizar_elementos()
	estilizar_elementos()

	buscar_jogador()
	atualizar_hud()


func _process(_delta: float) -> void:
	if not is_instance_valid(jogador):
		buscar_jogador()

	if is_instance_valid(jogador):
		atualizar_hud()


func criar_painel() -> void:
	var painel = Panel.new()
	painel.name = "PainelHUD"

	painel.anchor_left = 0.0
	painel.anchor_right = 0.0
	painel.anchor_top = 0.0
	painel.anchor_bottom = 0.0

	painel.offset_left = 24
	painel.offset_right = 390
	painel.offset_top = 24
	painel.offset_bottom = 205

	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.015, 0.025, 0.045, 0.94)
	estilo.border_color = Color("#8D3544")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)

	estilo.content_margin_left = 15
	estilo.content_margin_right = 15
	estilo.content_margin_top = 12
	estilo.content_margin_bottom = 12

	painel.add_theme_stylebox_override("panel", estilo)

	controle.add_child(painel)
	controle.move_child(painel, 0)

	var linha = ColorRect.new()
	linha.color = cor_vermelha
	linha.position = Vector2(12, 0)
	linha.size = Vector2(120, 3)
	painel.add_child(linha)

	var titulo = Label.new()
	titulo.text = "G00D PROTOCOL"
	titulo.position = Vector2(15, 12)
	titulo.add_theme_font_size_override("font_size", 17)
	titulo.add_theme_color_override("font_color", cor_vermelha)
	painel.add_child(titulo)

	var status = Label.new()
	status.text = "SYSTEM ONLINE"
	status.position = Vector2(225, 15)
	status.add_theme_font_size_override("font_size", 10)
	status.add_theme_color_override("font_color", Color("#55DDA0"))
	painel.add_child(status)

	var separador = ColorRect.new()
	separador.color = Color("#74313B")
	separador.position = Vector2(15, 43)
	separador.size = Vector2(320, 1)
	painel.add_child(separador)

	var unidade = Label.new()
	unidade.text = "ZERO UNIT // COMBAT INTERFACE"
	unidade.position = Vector2(15, 48)
	unidade.add_theme_font_size_override("font_size", 10)
	unidade.add_theme_color_override("font_color", Color("#8493A5"))
	painel.add_child(unidade)


func organizar_elementos() -> void:
	# Vida
	hp_texto.anchor_left = 0
	hp_texto.anchor_right = 0
	hp_texto.anchor_top = 0
	hp_texto.anchor_bottom = 0

	hp_texto.offset_left = 42
	hp_texto.offset_right = 355
	hp_texto.offset_top = 84
	hp_texto.offset_bottom = 111

	# Barra de vida
	hp_bar.anchor_left = 0
	hp_bar.anchor_right = 0
	hp_bar.anchor_top = 0
	hp_bar.anchor_bottom = 0

	hp_bar.offset_left = 42
	hp_bar.offset_right = 355
	hp_bar.offset_top = 113
	hp_bar.offset_bottom = 129

	# Dash
	texto_dash.anchor_left = 0
	texto_dash.anchor_right = 0
	texto_dash.anchor_top = 0
	texto_dash.anchor_bottom = 0

	texto_dash.offset_left = 42
	texto_dash.offset_right = 355
	texto_dash.offset_top = 137
	texto_dash.offset_bottom = 156

	barra_dash.anchor_left = 0
	barra_dash.anchor_right = 0
	barra_dash.anchor_top = 0
	barra_dash.anchor_bottom = 0

	barra_dash.offset_left = 42
	barra_dash.offset_right = 355
	barra_dash.offset_top = 159
	barra_dash.offset_bottom = 172


func estilizar_elementos() -> void:
	hp_bar.show_percentage = false
	barra_dash.show_percentage = false

	var fundo = StyleBoxFlat.new()
	fundo.bg_color = Color("#171B29")
	fundo.border_color = Color("#73313D")
	fundo.set_border_width_all(1)
	fundo.set_corner_radius_all(3)

	hp_bar.add_theme_stylebox_override("background", fundo)
	barra_dash.add_theme_stylebox_override("background", fundo)

	var preenchimento = StyleBoxFlat.new()
	preenchimento.bg_color = cor_vermelha
	preenchimento.set_corner_radius_all(3)

	hp_bar.add_theme_stylebox_override("fill", preenchimento)

	var preenchimento_dash = StyleBoxFlat.new()
	preenchimento_dash.bg_color = cor_azul
	preenchimento_dash.set_corner_radius_all(3)

	barra_dash.add_theme_stylebox_override("fill", preenchimento_dash)

	hp_texto.add_theme_color_override("font_color", Color.WHITE)
	hp_texto.add_theme_font_size_override("font_size", 17)

	texto_dash.add_theme_color_override("font_color", cor_azul)
	texto_dash.add_theme_font_size_override("font_size", 14)


func buscar_jogador() -> void:
	jogador = get_tree().get_first_node_in_group("player")


func atualizar_hud() -> void:
	if not is_instance_valid(jogador):
		return

	var vida_maxima = int(jogador.vida_maxima)
	var vida_atual = int(jogador.vida_atual)

	var max_dash = int(jogador.max_dashes_no_ar)
	var usados = int(jogador.dashes_usados_no_ar)

	var disponiveis = max_dash - usados

	# Vida
	hp_bar.max_value = vida_maxima
	hp_bar.value = vida_atual

	hp_texto.text = "INTEGRIDADE    %03d / %03d" % [
		vida_atual,
		vida_maxima
	]

	# Cor dinâmica da vida
	var cor = Color("#E83B4D")

	if vida_atual <= vida_maxima * 0.3:
		cor = Color("#FF4B25")
	elif vida_atual <= vida_maxima * 0.6:
		cor = Color("#FF8A36")

	var estilo_vida = StyleBoxFlat.new()
	estilo_vida.bg_color = cor
	estilo_vida.set_corner_radius_all(3)

	hp_bar.add_theme_stylebox_override("fill", estilo_vida)

	# Dash
	barra_dash.max_value = max_dash
	barra_dash.value = disponiveis

	texto_dash.text = "PROPULSÃO    %d / %d CARGAS" % [
		disponiveis,
		max_dash
	]


func ocultar() -> void:
	controle.hide()


func mostrar() -> void:
	controle.show()
