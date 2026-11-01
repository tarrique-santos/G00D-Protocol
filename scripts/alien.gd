
class_name AlienInimigo
extends CharacterBody3D

@export_group("Atributos")
@export var vida_maxima: float = 100.0
@export var dano: float = 25.0

@export_group("Movimentacao")
@export var velocidade_corrida: float = 8.5
@export var velocidade_andar: float = 3.4
@export var distancia_corrida: float = 40.0
@export var distancia_parada: float = 30.0
@export var aceleracao: float = 15.0
@export var desaceleracao: float = 12.0
@export var gravidade: float = 20.0

@export_group("Combate")
@export var alcance_tiro: float = 35.0
@export var intervalo_tiro: float = 1.5
@export var velocidade_laser: float = 25.0

@export_group("Animacoes")
@export var animacao_parado: String = "idle"
@export var animacao_andar: String = "walk"
@export var animacao_correr: String = "run"
@export var animacao_morte: String = "die"
@export var remover_movimento_raiz: bool = true
@export var nome_osso_raiz: String = "Hips"

@export_group("Referencias")
@export var jogador: Node3D
@export var animation_player: AnimationPlayer

@export_group("Orientacao")
@export_range(-360.0, 360.0) var rotacao_modelo: float = 180.0

var vida: float
var tempo_tiro: float = 0.0
var morto: bool = false
var animacao_atual: String = ""


func _ready():
	vida = vida_maxima

	if jogador == null:
		jogador = get_tree().get_first_node_in_group("player")

	if animation_player == null:
		animation_player = get_node_or_null("Alien/AnimationPlayer")

	$Alien.rotation.y = deg_to_rad(rotacao_modelo)

	configurar_animacoes()
	trocar_animacao(animacao_parado)


func configurar_animacoes():
	if animation_player == null:
		return

	for nome in [animacao_parado, animacao_andar, animacao_correr]:
		var anim = obter_animacao(nome)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR

	var anim_morte = obter_animacao(animacao_morte)
	if anim_morte:
		anim_morte.loop_mode = Animation.LOOP_NONE

	if remover_movimento_raiz:
		for nome in [animacao_parado, animacao_andar, animacao_correr, animacao_morte]:
			var anim = obter_animacao(nome)
			if anim:
				remover_posicao_raiz(anim)


func remover_posicao_raiz(anim: Animation):
	for i in range(anim.get_track_count()):
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue

		var caminho = str(anim.track_get_path(i))

		if not nome_osso_raiz in caminho:
			continue

		var total = anim.track_get_key_count(i)

		if total == 0:
			continue

		var inicio = anim.track_get_key_value(i, 0)

		if typeof(inicio) != TYPE_VECTOR3:
			continue

		for k in range(total):
			var valor = anim.track_get_key_value(i, k)

			if typeof(valor) != TYPE_VECTOR3:
				continue

			valor.x = inicio.x
			valor.z = inicio.z

			anim.track_set_key_value(i, k, valor)


func obter_nome_animacao(nome: String) -> String:
	if animation_player == null:
		return ""

	if animation_player.has_animation(nome):
		return nome

	if animation_player.has_animation("custom/" + nome):
		return "custom/" + nome

	for anim in animation_player.get_animation_list():
		if nome.to_lower() in String(anim).to_lower():
			return anim

	print("Animacao nao encontrada: ", nome)
	return ""


func obter_animacao(nome: String) -> Animation:
	var nome_real = obter_nome_animacao(nome)

	if nome_real == "":
		return null

	return animation_player.get_animation(nome_real)


func trocar_animacao(nome: String):
	if animation_player == null or animacao_atual == nome:
		return

	var nome_real = obter_nome_animacao(nome)

	if nome_real != "":
		animation_player.play(nome_real, 0.2)
		animacao_atual = nome

func _physics_process(delta):
	if morto:
		return

	if jogador == null or not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("player")
		return

	tempo_tiro -= delta

	var direcao = jogador.global_position - global_position
	direcao.y = 0

	var distancia = direcao.length()

	if distancia > 0.1:
		direcao = direcao.normalized()

		var alvo = Vector3(
			jogador.global_position.x,
			global_position.y,
			jogador.global_position.z
		)

		look_at(alvo, Vector3.UP)

	var movimento = Vector3.ZERO
	var velocidade_desejada = 0.0
	var esta_parado = false

	if distancia > distancia_parada:
		# Sempre corre em direcao ao jogador
		movimento = direcao
		velocidade_desejada = velocidade_corrida
		trocar_animacao(animacao_correr)

	else:
		# Para e atira quando chega perto
		movimento = Vector3.ZERO
		velocidade_desejada = 0.0
		esta_parado = true
		trocar_animacao(animacao_parado)

	# Movimento horizontal
	var velocidade_atual = Vector3(velocity.x, 0, velocity.z)
	var velocidade_alvo = movimento * velocidade_desejada

	var taxa = aceleracao if velocidade_desejada > 0.0 else desaceleracao

	velocidade_atual = velocidade_atual.move_toward(
		velocidade_alvo,
		taxa * delta
	)

	velocity.x = velocidade_atual.x
	velocity.z = velocidade_atual.z

	# Gravidade
	if not is_on_floor():
		velocity.y -= gravidade * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	# Atira somente quando estiver parado
	if esta_parado and distancia <= alcance_tiro and tempo_tiro <= 0.0:
		atirar()
		
func atirar():
	if jogador == null or morto:
		return

	tempo_tiro = intervalo_tiro

	var origem = global_position + Vector3(0, 3.8, 0)
	var destino = jogador.global_position + Vector3(0, 1.0, 0)
	var direcao = (destino - origem).normalized()

	var laser = LaserVermelho.new()

	get_tree().current_scene.add_child(laser)

	laser.global_position = origem + direcao * 0.8
	laser.configurar(direcao, velocidade_laser, dano)


func receber_dano(valor: float):
	if morto:
		return

	vida -= valor

	print("Alien recebeu dano! Vida: ", vida, "/", vida_maxima)

	if vida <= 0:
		morrer()


func morrer():
	if morto:
		return

	morto = true
	velocity = Vector3.ZERO

	collision_layer = 0
	collision_mask = 0

	var colisao = get_node_or_null("CollisionShape3D")

	if colisao:
		colisao.set_deferred("disabled", true)

	if animation_player:
		animacao_atual = ""

		var nome_real = obter_nome_animacao(animacao_morte)

		if nome_real != "":
			animation_player.play(nome_real)
			await animation_player.animation_finished

	queue_free()
