
extends CharacterBody3D

@export var velocidade: float = 5.0
@export_range(0.0, 360.0) var angulo_voo: float = 0.0
@export var distancia_voo: float = 10.0
@export var intervalo_tiro: float = 2.0

var direcao: int = 1
var posicao_inicial: Vector3
var vetor_voo: Vector3

@export var cena_projetil: PackedScene

@onready var timer: Timer = $Timer
@onready var aparencia: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	posicao_inicial = global_position

	var angulo = deg_to_rad(angulo_voo)
	vetor_voo = Vector3(cos(angulo), sin(angulo), 0.0)

	timer.wait_time = intervalo_tiro
	timer.timeout.connect(atirar)
	timer.start()


func _physics_process(delta: float) -> void:
	var deslocamento = global_position - posicao_inicial
	var distancia_percorrida = deslocamento.dot(vetor_voo)

	if distancia_percorrida >= distancia_voo:
		direcao = -1
	elif distancia_percorrida <= 0.0:
		direcao = 1

	velocity = vetor_voo * velocidade * direcao
	move_and_slide()

	olhar_para_player()




func olhar_para_player() -> void:
	var jogador = get_tree().get_first_node_in_group("player")

	if jogador == null:
		return

	var direcao_alvo = jogador.global_position - global_position

	if direcao_alvo.length_squared() > 0.001:
		look_at(jogador.global_position, Vector3.UP)




func atirar() -> void:
	var jogador = get_tree().get_first_node_in_group("player")

	if jogador == null or cena_projetil == null:
		return

	var projetil = cena_projetil.instantiate()
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = global_position

	if projetil.has_method("definir_direcao"):
		projetil.definir_direcao(
			(jogador.global_position - global_position).normalized()
		)
