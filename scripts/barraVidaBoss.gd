class_name BarraVidaBoss
extends CanvasLayer
## Barra de vida de chefe no topo da tela (nome em cima, barra larga embaixo,
## com o "rastro" amarelo que some devagar depois de cada dano).
## É criada pelo próprio chefe, não precisa de cena.

@export var nome_boss := "CHEFE"
@export var largura := 720.0
@export var altura := 26.0
@export var cor_vida := Color(0.85, 0.12, 0.12)
@export var cor_fundo := Color(0.25, 0.04, 0.04)
@export var cor_rastro := Color(1.0, 0.85, 0.3)
## Tempo parado antes do rastro começar a descer.
@export var atraso_rastro := 0.45
## Fração da barra por segundo que o rastro desce.
@export var velocidade_rastro := 0.5

@export_group("Posição")
## Desloca a barra em pixels. X positivo = direita, Y positivo = para baixo.
@export var deslocamento := Vector2.ZERO
## true = encosta a barra no canto direito da tela (em vez de centralizar).
@export var ancorar_direita := false
## Distância da borda direita, usada quando ancorar_direita está ligado.
@export var margem_direita := 40.0

var _raiz: Control
var _fill: ColorRect
var _rastro: ColorRect
var _alvo := 1.0
var _rastro_atual := 1.0
var _espera := 0.0


func _init() -> void:
	layer = 5


func _ready() -> void:
	# Grupo "hud": o jogador já esconde esse grupo quando morre.
	add_to_group("hud")

	_raiz = Control.new()
	_raiz.anchor_right = 1.0
	_raiz.anchor_bottom = 1.0
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	# Caixa no topo da tela (centralizada ou encostada na direita)
	var caixa := Control.new()
	if ancorar_direita:
		caixa.anchor_left = 1.0
		caixa.anchor_right = 1.0
		caixa.offset_left = -largura - margem_direita + deslocamento.x
		caixa.offset_right = -margem_direita + deslocamento.x
	else:
		caixa.anchor_left = 0.5
		caixa.anchor_right = 0.5
		caixa.offset_left = -largura * 0.5 + deslocamento.x
		caixa.offset_right = largura * 0.5 + deslocamento.x
	caixa.offset_top = 22.0 + deslocamento.y
	caixa.offset_bottom = 22.0 + 30.0 + altura + deslocamento.y
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(caixa)

	# Nome do chefe
	var nome := Label.new()
	nome.text = nome_boss
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.anchor_right = 1.0
	nome.offset_bottom = 28.0
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nome.add_theme_font_size_override("font_size", 20)
	nome.add_theme_color_override("font_outline_color", Color.BLACK)
	nome.add_theme_constant_override("outline_size", 6)
	caixa.add_child(nome)

	# Moldura escura
	var moldura := _rect(caixa, Color(0.02, 0.02, 0.02, 0.92))
	moldura.offset_top = 30.0

	var interior := Control.new()
	interior.anchor_right = 1.0
	interior.anchor_bottom = 1.0
	interior.offset_left = 3.0
	interior.offset_top = 3.0
	interior.offset_right = -3.0
	interior.offset_bottom = -3.0
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(interior)

	_rect(interior, cor_fundo)
	_rastro = _rect(interior, cor_rastro)
	_fill = _rect(interior, cor_vida)

	# Faixa clara em cima da barra, para dar aspecto de brilho
	var brilho := _rect(_fill, Color(1.0, 1.0, 1.0, 0.18))
	brilho.anchor_bottom = 0.45


func _rect(pai: Control, cor: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = cor
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_right = 1.0
	r.anchor_bottom = 1.0
	pai.add_child(r)
	return r


func _process(delta: float) -> void:
	if _rastro_atual > _alvo:
		if _espera > 0.0:
			_espera -= delta
		else:
			_rastro_atual = maxf(_alvo, _rastro_atual - velocidade_rastro * delta)
	else:
		_rastro_atual = _alvo
	_rastro.anchor_right = _rastro_atual


func atualizar(atual: int, maxima: int) -> void:
	var novo := clampf(float(atual) / float(maxi(maxima, 1)), 0.0, 1.0)
	if novo < _alvo:
		_espera = atraso_rastro
	_alvo = novo
	_fill.anchor_right = novo


func fechar() -> void:
	var tw := create_tween()
	tw.tween_property(_raiz, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)


# Chamado pelo jogador ao morrer (grupo "hud")
func ocultar() -> void:
	hide()
