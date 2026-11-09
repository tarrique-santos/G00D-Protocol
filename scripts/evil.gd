
extends CharacterBody3D

@export var vida: int = 3
@export var velocidade: float = 2.0
@export var gravidade: float = 20.0

@export var velocidade_rotacao: float = 3.0
@export var ajuste_rotacao_graus: float = 180.0
@export var velocidade_animacao_corrida: float = 0.75

@export var distancia_ataque: float = 2.5
@export var dano: int = 1
@export var intervalo_ataque: float = 2.0
@export var tempo_ate_dano: float = 0.35

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var espada: Area3D = find_child("Area3D", true, false) as Area3D

var jogador: Node3D

var tempo_recarga: float = 0.0
var tempo_ataque: float = 0.0

var atacando: bool = false
var dano_aplicado: bool = false
var morto: bool = false


func _ready():
	if animation_player == null:
		push_error("AnimationPlayer não encontrado!")
		set_physics_process(false)
		return

	if espada == null:
		push_error("Area3D da espada não encontrado!")
		set_physics_process(false)
		return

	jogador = get_tree().get_first_node_in_group("player")

	espada.monitoring = false

	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

	tocar_corrida()


func _physics_process(delta):
	if morto:
		return

	# Gravidade
	if not is_on_floor():
		velocity.y -= gravidade * delta
	else:
		velocity.y = 0.0

	# Tempo de recarga
	if tempo_recarga > 0:
		tempo_recarga -= delta

	# Procurar jogador
	if jogador == null or not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("player")

		velocity.x = 0
		velocity.z = 0

		move_and_slide()
		return

	var direcao = jogador.global_position - global_position
	direcao.y = 0

	var distancia = direcao.length()

	if atacando:
		executar_ataque(delta)

	elif distancia <= distancia_ataque:
		velocity.x = 0
		velocity.z = 0

		olhar_para_jogador(delta)

		if tempo_recarga <= 0:
			iniciar_ataque()

	else:
		perseguir_jogador(direcao, delta)

	move_and_slide()


func olhar_para_jogador(delta: float):
	var direcao = jogador.global_position - global_position
	direcao.y = 0

	if direcao.length_squared() > 0.001:
		var angulo_alvo = atan2(-direcao.x, -direcao.z)
		angulo_alvo += deg_to_rad(ajuste_rotacao_graus)

		rotation.y = lerp_angle(
			rotation.y,
			angulo_alvo,
			min(velocidade_rotacao * delta, 1.0)
		)


func perseguir_jogador(direcao: Vector3, delta: float):
	direcao = direcao.normalized()

	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade

	olhar_para_jogador(delta)

	if animation_player.current_animation != "custom/run":
		tocar_corrida()


func tocar_corrida():
	animation_player.play(
		"custom/run",
		-1,
		velocidade_animacao_corrida
	)


func iniciar_ataque():
	atacando = true
	dano_aplicado = false
	tempo_ataque = 0.0

	velocity.x = 0
	velocity.z = 0

	espada.monitoring = true

	animation_player.play("custom/attack")


func executar_ataque(delta):
	tempo_ataque += delta

	if tempo_ataque >= tempo_ate_dano and not dano_aplicado:
		aplicar_dano()
		dano_aplicado = true

	var animacao = animation_player.get_animation("custom/attack")

	if animacao == null:
		push_error("Animação custom/attack não encontrada!")
		finalizar_ataque()
		return

	if tempo_ataque >= animacao.length:
		finalizar_ataque()


func aplicar_dano():
	if jogador == null or not is_instance_valid(jogador):
		return

	var corpos = espada.get_overlapping_bodies()

	for corpo in corpos:
		if corpo == jogador or corpo.is_in_group("player"):

			if corpo.has_method("take_damage"):
				corpo.take_damage(dano)

			elif corpo.has_method("receber_dano"):
				corpo.receber_dano(dano)

			else:
				push_warning("O jogador não possui uma função para receber dano!")


func finalizar_ataque():
	atacando = false

	espada.monitoring = false

	tempo_recarga = intervalo_ataque

	if not morto:
		tocar_corrida()


func receber_dano(valor: int):
	if morto:
		return

	vida -= valor

	if vida <= 0:
		morrer()


func morrer():
	if morto:
		return

	morto = true
	atacando = false

	espada.monitoring = false

	velocity = Vector3.ZERO

	animation_player.play("custom/die")


func _on_animation_player_animation_finished(animacao: StringName):
	if animacao == "custom/die":
		queue_free()
