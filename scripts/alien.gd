
class_name AlienInimigo
extends CharacterBody3D
enum Visao { LIVRE, ALIADO, PAREDE }


@export_group("Atributos")
@export var vida_maxima: float = 100.0
@export var dano: float = 25.0


@export_group("Movimentacao")
@export var velocidade_corrida: float = 8.5
@export var velocidade_andar: float = 3.4
@export var distancia_corrida: float = 40.0
@export var distancia_parada: float = 45.0
@export var aceleracao: float = 15.0
@export var desaceleracao: float = 12.0
@export var gravidade: float = 20.0

@export_group("Combate")
@export var alcance_tiro: float = 48.0
@export var intervalo_tiro: float = 1.5
@export var velocidade_laser: float = 25.0
@export var altura_disparo: float = 3.8
@export var distancia_saida_laser: float = 1.5
@export var tamanho_laser: float = 1.0
## Velocidade ao andar de lado pra liberar a linha de tiro.
@export var velocidade_strafe: float = 4.0
## Usada só se o player não tiver o nó "camera". Ajuste se o tiro ainda sair baixo.
@export var altura_mira: float = 1.6
## Distância em que ele começa a se afastar de outros inimigos.
@export var raio_separacao: float = 3.0
## Força do afastamento.
@export var forca_separacao: float = 1.2
## Folga lateral da checagem de visão (evita enxergar por quina).
@export var folga_visao: float = 0.5


@export_group("Voz")
@export var intervalo_voz: float = 11.0


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


@export_group("Barra de Vida")
@export var altura_barra_vida: float = 5.8
@export var largura_barra_vida: float = 2.0
@export var espessura_barra_vida: float = 0.32


var vida: float
var tempo_tiro: float = 0.0
var tempo_voz: float = 0.0
var morto: bool = false
var animacao_atual: String = ""
var lado_strafe: float = 1.0


var barra_vida: Node3D
var barra_preenchimento: MeshInstance3D
var material_barra: StandardMaterial3D

@onready var voz: AudioStreamPlayer3D = $Voz
@onready var agente_nav: NavigationAgent3D = $NavigationAgent3D

func _ready():
	add_to_group("inimigo")
	vida = vida_maxima

	if jogador == null:
		jogador = get_tree().get_first_node_in_group("player")

	if animation_player == null:
		animation_player = get_node_or_null("Alien/AnimationPlayer")

	$Alien.rotation.y = deg_to_rad(rotacao_modelo)

	criar_barra_vida()
	configurar_animacoes()
	trocar_animacao(animacao_parado)

	# Iniciar voz do alien
	if voz:
		tempo_voz = 0.0
		voz.play()


# ==========================================
# BARRA DE VIDA
# ==========================================

func criar_barra_vida():
	barra_vida = Node3D.new()
	barra_vida.name = "BarraVida"
	barra_vida.position.y = altura_barra_vida

	add_child(barra_vida)

	barra_preenchimento = MeshInstance3D.new()
	barra_preenchimento.name = "Preenchimento"

	var mesh_preenchimento = QuadMesh.new()
	mesh_preenchimento.size = Vector2(
		largura_barra_vida,
		espessura_barra_vida
	)

	barra_preenchimento.mesh = mesh_preenchimento

	material_barra = StandardMaterial3D.new()
	material_barra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_barra.albedo_color = Color.GREEN
	material_barra.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	barra_preenchimento.material_override = material_barra

	barra_vida.add_child(barra_preenchimento)

	atualizar_barra_vida()


func atualizar_barra_vida():
	if barra_preenchimento == null:
		return

	var porcentagem = 0.0

	if vida_maxima > 0.0:
		porcentagem = clampf(vida / vida_maxima, 0.0, 1.0)

	var malha := barra_preenchimento.mesh as QuadMesh
	var largura_atual := maxf(largura_barra_vida * porcentagem, 0.001)

	malha.size = Vector2(largura_atual, espessura_barra_vida)
	# Mantém a ponta esquerda fixa enquanto a barra encolhe
	malha.center_offset = Vector3(
		-(largura_barra_vida - largura_atual) / 2.0, 0.0, 0.0
	)

	if porcentagem > 0.5:
		material_barra.albedo_color = Color.GREEN
	elif porcentagem > 0.25:
		material_barra.albedo_color = Color.YELLOW
	else:
		material_barra.albedo_color = Color.RED

	if porcentagem > 0.5:
		material_barra.albedo_color = Color.GREEN
	elif porcentagem > 0.25:
		material_barra.albedo_color = Color.YELLOW
	else:
		material_barra.albedo_color = Color.RED


# ==========================================
# ANIMACOES
# ==========================================

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
		for nome in [
			animacao_parado,
			animacao_andar,
			animacao_correr,
			animacao_morte
		]:
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


# ==========================================
# MOVIMENTACAO
# ==========================================

func _physics_process(delta):
	if morto:
		return

	if jogador == null or not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("player")
		return

	tempo_tiro -= delta

	var direcao_reta = jogador.global_position - global_position
	direcao_reta.y = 0

	var distancia = direcao_reta.length()

	# Sempre olha pro jogador
	if distancia > 0.1:
		var alvo_olhar = Vector3(
			jogador.global_position.x,
			global_position.y,
			jogador.global_position.z
		)

		look_at(alvo_olhar, Vector3.UP)

	var visao := checar_visao()

	var movimento = Vector3.ZERO
	var velocidade_desejada = 0.0
	var pode_atirar = false

	if distancia > distancia_parada or visao == Visao.PAREDE:
		# Longe, ou sem ver o jogador por causa de parede: segue o caminho
		agente_nav.target_position = jogador.global_position

		if not agente_nav.is_navigation_finished():
			var proximo_ponto = agente_nav.get_next_path_position()
			var direcao_caminho = proximo_ponto - global_position
			direcao_caminho.y = 0

			if direcao_caminho.length() > 0.05:
				movimento = direcao_caminho.normalized()

		velocidade_desejada = velocidade_corrida
		trocar_animacao(animacao_correr)

	elif visao == Visao.ALIADO:
		# Outro inimigo na frente: anda de lado pra liberar o tiro
		var lado = direcao_reta.normalized().cross(Vector3.UP) * lado_strafe

		movimento = lado
		velocidade_desejada = velocidade_strafe
		trocar_animacao(animacao_andar)

	else:
		# Linha de tiro livre: para e atira
		pode_atirar = true
		trocar_animacao(animacao_parado)

	# Movimento horizontal
	var velocidade_atual = Vector3(
		velocity.x,
		0,
		velocity.z
	)

	var velocidade_alvo = movimento * velocidade_desejada
	velocidade_alvo += calcular_separacao() * velocidade_corrida

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

	# Bateu em algo andando de lado: troca de lado
	if visao == Visao.ALIADO and is_on_wall():
		lado_strafe *= -1.0

	if pode_atirar and distancia <= alcance_tiro and tempo_tiro <= 0.0:
		atirar()


# ==========================================
# COMBATE
# ==========================================

func atirar():
	if jogador == null or morto:
		return

	tempo_tiro = intervalo_tiro

	var origem = global_position + Vector3(0, altura_disparo, 0)
	var destino = obter_ponto_mira()

	var direcao = (destino - origem).normalized()

	var laser = LaserVermelho.new()

	get_tree().current_scene.add_child(laser)

	laser.global_position = origem + direcao * distancia_saida_laser
	laser.configurar(direcao, velocidade_laser, dano, self)


func obter_ponto_mira() -> Vector3:
	# Mira na altura da câmera do player (a "cara" dele)
	var cam = jogador.get("camera")

	if cam != null and is_instance_valid(cam):
		return cam.global_position

	return jogador.global_position + Vector3(0, altura_mira, 0)


func checar_visao() -> Visao:
	var origem = global_position + Vector3(0, altura_disparo, 0)
	var destino = obter_ponto_mira()

	var frente: Vector3 = (destino - origem).normalized()
	var lado: Vector3 = frente.cross(Vector3.UP).normalized() * folga_visao

	var pior := Visao.LIVRE

	# Centro, esquerda e direita: todos precisam passar
	for deslocamento in [Vector3.ZERO, lado, -lado]:
		var consulta = PhysicsRayQueryParameters3D.create(
			origem + deslocamento, destino
		)
		consulta.exclude = [get_rid()]

		var resultado = get_world_3d().direct_space_state.intersect_ray(consulta)

		if resultado.is_empty():
			continue

		var alvo = resultado["collider"]

		if alvo.is_in_group("player"):
			continue

		if alvo.has_method("receber_dano"):
			if pior == Visao.LIVRE:
				pior = Visao.ALIADO
		else:
			return Visao.PAREDE

	return pior


func calcular_separacao() -> Vector3:
	var empurrao := Vector3.ZERO

	for outro in get_tree().get_nodes_in_group("inimigo"):
		if outro == self or not is_instance_valid(outro) or not (outro is Node3D):
			continue

		var diferenca: Vector3 = global_position - outro.global_position
		diferenca.y = 0.0
		var dist := diferenca.length()

		if dist > 0.01 and dist < raio_separacao:
			empurrao += diferenca.normalized() * (1.0 - dist / raio_separacao)

	return empurrao * forca_separacao

func receber_dano(valor: float):
	if morto:
		return

	vida = maxf(vida - valor, 0.0)

	atualizar_barra_vida()

	print("Alien recebeu dano! Vida: ", vida, "/", vida_maxima)

	if vida <= 0:
		morrer()


# ==========================================
# MORTE
# ==========================================

func morrer():
	if morto:
		return

	morto = true
	velocity = Vector3.ZERO

	# Parar a voz
	if voz:
		voz.stop()

	collision_layer = 0
	collision_mask = 0

	var colisao = get_node_or_null("CollisionShape3D")

	if colisao:
		colisao.set_deferred("disabled", true)

	if barra_vida:
		barra_vida.visible = false

	if animation_player:
		animacao_atual = ""

		var nome_real = obter_nome_animacao(animacao_morte)

		if nome_real != "":
			animation_player.play(nome_real)
			await animation_player.animation_finished

	queue_free()
