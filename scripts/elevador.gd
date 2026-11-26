extends AnimatableBody3D
## Elevador: o jogador entra na cabine, as portas fecham, a cabine sobe (ou desce)
## e as portas abrem. Na viagem seguinte ele volta.
##
## As portas abrem LATERALMENTE: o eixo é descoberto automaticamente pela posição
## das duas portas (cada uma se afasta da outra). Se as duas estiverem na mesma
## posição, use "eixo_manual".

signal viagem_iniciada
signal viagem_concluida


@export_group("Viagem")

## Quanto a cabine sobe (positivo) ou desce (negativo) a cada viagem.
@export var deslocamento_andar: float = 23.5

## Duração do deslocamento da cabine.
@export var duracao_viagem: float = 5.0

## Tempo que o jogador precisa ficar dentro antes da partida.
@export var atraso_partida: float = 0.8

## Se ligado, o elevador nasce travado e só funciona depois de destravar().
@export var comeca_travado: bool = false

@export_group("Portas")

## Se vazias, procura os nós "Elevator_Door2" e "Elevator_Door3".
@export var porta_a: Node3D
@export var porta_b: Node3D

## Distância lateral que cada porta percorre ao abrir.
@export var distancia_abertura: float = 1.5

## Eixo lateral das portas (no espaço do Elevador). Deixe (0,0,0) para automático.
## Exemplo: (0,0,1) para portas que correm em Z.
@export var eixo_manual: Vector3 = Vector3.ZERO

## Inverte individualmente o sentido de cada porta.
@export var inverter_porta_a: bool = false
@export var inverter_porta_b: bool = false

## Duração da animação das portas.
@export var duracao_porta: float = 1.0

## Colisões que bloqueiam a entrada (desligadas com as portas abertas).
@export var colisoes_portas: Array[CollisionShape3D] = []

## Define se o elevador começa com as portas abertas.
@export var comecar_com_portas_abertas: bool = true


@export_group("Gatilho (dentro da cabine)")

@export var tamanho_gatilho: Vector3 = Vector3(2.0, 2.5, 2.0)
@export var posicao_gatilho: Vector3 = Vector3(0.0, 1.25, 0.0)
@export var grupo_jogador: String = "player"


var _origem: Vector3

var _fechada_a: Vector3
var _fechada_b: Vector3

# Deslocamento de cada porta ao abrir (já com eixo, distância e inversão)
var _abertura_a: Vector3 = Vector3.ZERO
var _abertura_b: Vector3 = Vector3.ZERO

var _em_cima: bool = false
var _ocupado: bool = false
var _jogador_dentro: bool = false
var _travado: bool = false
var _portas_abertas: bool = true


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	# Faz o jogador ser carregado junto com a cabine
	sync_to_physics = true

	if porta_a == null:
		porta_a = get_node_or_null("Elevator_Door2") as Node3D

	if porta_b == null:
		porta_b = get_node_or_null("Elevator_Door3") as Node3D

	_origem = position

	if porta_a != null:
		_fechada_a = porta_a.position

	if porta_b != null:
		_fechada_b = porta_b.position

	_calcular_aberturas()

	_definir_portas_instantaneo(comecar_com_portas_abertas)

	_criar_gatilho()
	
	_travado = comeca_travado


## Calcula para onde cada porta vai ao abrir: uma se afasta da outra.
func _calcular_aberturas() -> void:

	var eixo := Vector3.ZERO

	if eixo_manual.length() > 0.001:
		eixo = eixo_manual.normalized()

	elif porta_a != null and porta_b != null:
		# Direção da porta A para a porta B, só no plano horizontal
		var entre := _fechada_b - _fechada_a
		entre.y = 0.0

		if entre.length() > 0.01:
			eixo = entre.normalized()

	if eixo == Vector3.ZERO:
		push_warning("Elevador: não deu para descobrir o eixo das portas, usando Z. Defina 'eixo_manual'.")
		eixo = Vector3(0.0, 0.0, 1.0)

	# A vai para o lado oposto ao de B
	var sentido_a := -1.0
	var sentido_b := 1.0

	if inverter_porta_a:
		sentido_a *= -1.0

	if inverter_porta_b:
		sentido_b *= -1.0

	_abertura_a = eixo * distancia_abertura * sentido_a
	_abertura_b = eixo * distancia_abertura * sentido_b


# ==================================================
# GATILHO
# ==================================================

func _criar_gatilho() -> void:

	var area := Area3D.new()
	area.name = "GatilhoCabine"

	area.position = posicao_gatilho
	area.collision_layer = 0
	area.collision_mask = 1  # camada do jogador (ajuste se for outra)

	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()

	caixa.size = tamanho_gatilho
	forma.shape = caixa

	area.add_child(forma)
	add_child(area)

	area.body_entered.connect(_on_gatilho_entrou)
	area.body_exited.connect(_on_gatilho_saiu)


func _on_gatilho_entrou(corpo: Node3D) -> void:

	if corpo.is_in_group(grupo_jogador):

		_jogador_dentro = true

		_tentar_partir()


func _on_gatilho_saiu(corpo: Node3D) -> void:

	if corpo.is_in_group(grupo_jogador):

		_jogador_dentro = false


func _tentar_partir() -> void:

	if _ocupado or _travado:
		return

	_ocupado = true

	await get_tree().create_timer(atraso_partida).timeout

	# O jogador saiu antes da partida
	if not _jogador_dentro:

		_ocupado = false
		return

	viagem_iniciada.emit()

	await _fechar_portas()
	await _mover()
	await _abrir_portas()

	viagem_concluida.emit()

	_ocupado = false


# ==================================================
# MOVIMENTO DO ELEVADOR
# ==================================================

func _mover() -> void:

	var destino := _origem

	# Alterna entre o andar inferior e o superior
	if not _em_cima:
		destino += Vector3.UP * deslocamento_andar

	var tween := create_tween()

	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position", destino, duracao_viagem)

	await tween.finished

	_em_cima = not _em_cima


# ==================================================
# PORTAS
# ==================================================

func _abrir_portas() -> void:

	# A passagem é liberada assim que as portas começam a abrir
	_ligar_colisao_portas(false)

	await _animar_portas(true)


func _fechar_portas() -> void:

	await _animar_portas(false)

	_ligar_colisao_portas(true)


func _animar_portas(abrir: bool) -> void:
	_portas_abertas = abrir
	if porta_a == null and porta_b == null:

		await get_tree().create_timer(duracao_porta).timeout
		return

	var tween := create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	if porta_a != null:

		var alvo_a := _fechada_a + (_abertura_a if abrir else Vector3.ZERO)

		tween.tween_property(porta_a, "position", alvo_a, duracao_porta)

	if porta_b != null:

		var alvo_b := _fechada_b + (_abertura_b if abrir else Vector3.ZERO)

		tween.tween_property(porta_b, "position", alvo_b, duracao_porta)

	await tween.finished


func _definir_portas_instantaneo(abertas: bool) -> void:

	if porta_a != null:
		porta_a.position = _fechada_a + (_abertura_a if abertas else Vector3.ZERO)

	if porta_b != null:
		porta_b.position = _fechada_b + (_abertura_b if abertas else Vector3.ZERO)

	_portas_abertas = abertas
	_ligar_colisao_portas(not abertas)


# ==================================================
# COLISÕES DAS PORTAS
# ==================================================

func _ligar_colisao_portas(ativa: bool) -> void:

	for colisao in colisoes_portas:

		if colisao != null:
			colisao.set_deferred("disabled", not ativa)

func travar() -> void:
	_travado = true


func destravar() -> void:
	_travado = false

	# Estava travado com as portas fechadas: abre pra liberar a entrada
	if not _portas_abertas:
		_ocupado = true
		await _abrir_portas()
		_ocupado = false

	# Se o jogador já estava dentro da cabine esperando, parte agora
	if _jogador_dentro:
		_tentar_partir()
