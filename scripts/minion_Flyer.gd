
extends CharacterBody3D

# --- MOVIMENTO ---

@export var velocidade: float = 5.0
@export_range(0.0, 360.0) var angulo_voo: float = 0.0
@export var distancia_voo: float = 10.0

# --- DISPAROS ---

@export var intervalo_tiro: float = 2.0
@export var cena_projetil: PackedScene

# --- VIDA ---

@export var vida_maxima: int = 50
var vida_atual: int = 50

# --- VARIÁVEIS INTERNAS ---

var direcao: int = 1
var posicao_inicial: Vector3
var vetor_voo: Vector3
var jogador_na_area: bool = false

@onready var timer: Timer = $Timer
@onready var marcador: Marker3D = $Marker3D
@onready var particulas_dano: GPUParticles3D = $ParticulasDano


func _ready() -> void:
	vida_atual = vida_maxima

	posicao_inicial = global_position

	var angulo = deg_to_rad(angulo_voo)
	vetor_voo = Vector3(cos(angulo), sin(angulo), 0.0)

	timer.wait_time = intervalo_tiro
	timer.timeout.connect(atirar)
	timer.stop()


func _physics_process(_delta: float) -> void:
	# --- PATRULHA AÉREA ---

	var deslocamento = global_position - posicao_inicial
	var distancia_percorrida = deslocamento.dot(vetor_voo)

	if distancia_percorrida >= distancia_voo:
		direcao = -1
	elif distancia_percorrida <= 0.0:
		direcao = 1

	velocity = vetor_voo * velocidade * direcao
	move_and_slide()

	# --- OLHAR PARA O JOGADOR ---

	olhar_para_player()


func olhar_para_player() -> void:
	var jogador = get_tree().get_first_node_in_group("player")

	if jogador == null:
		return

	if global_position.distance_squared_to(
		jogador.global_position
	) > 0.001:
		look_at(jogador.global_position, Vector3.UP)


# --- SISTEMA DE DISPARO ---

func atirar() -> void:
	if not jogador_na_area:
		return

	var jogador = get_tree().get_first_node_in_group("player")

	if jogador == null or cena_projetil == null:
		return

	var projetil = cena_projetil.instantiate()
	get_tree().current_scene.add_child(projetil)

	projetil.global_position = marcador.global_position

	var direcao_tiro = (
		jogador.global_position - marcador.global_position
	).normalized()

	projetil.configurar(direcao_tiro, self)


# --- DETECÇÃO DO JOGADOR ---

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_na_area = true
		timer.start()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_na_area = false
		timer.stop()


# --- SISTEMA DE VIDA E PARTÍCULAS ---

func receber_dano(quantidade: int) -> void:
	vida_atual -= quantidade
	vida_atual = max(vida_atual, 0)

	# Emite partículas ao receber dano
	particulas_dano.restart()
	particulas_dano.emitting = true

	print(
		"Inimigo recebeu dano! Vida: ",
		vida_atual,
		"/",
		vida_maxima
	)

	if vida_atual <= 0:
		morrer()


func morrer() -> void:
	queue_free()
