extends CharacterBody3D

# --- MOVIMENTO (PATRULHA) ---

@export var velocidade: float = 5.0
@export_range(0.0, 360.0) var angulo_voo: float = 0.0
@export var distancia_voo: float = 10.0


# --- PERSEGUIÇÃO ---

@export_group("Perseguição")


@export var perseguir_jogador: bool = true
## Distância em que ele percebe o jogador e começa a persegui-lo.
@export var raio_perseguicao: float = 25.0
## Ele só desiste se o jogador passar de raio_perseguicao * este fator.
@export var fator_perder_jogador: float = 1.5
@export var velocidade_perseguicao: float = 7.0
## Distância que ele tenta manter do jogador (não chega mais perto que isso).
@export var distancia_ideal: float = 10.0
## Folga em torno da distância ideal, evita ficar tremendo indo e voltando.
@export var margem_distancia: float = 1.5
## Altura acima dos pés do jogador em que ele paira.
@export var altura_sobre_jogador: float = 2.0
## Quão rápido ele acelera, freia e muda de direção.
@export var aceleracao: float = 12.0
## Se ligado, ele persegue o jogador desde o início e nunca volta a patrulhar.
@export var sempre_perseguir: bool = true
## Altura acima do chão em que ele voa enquanto contorna paredes.
@export var altura_voo_nav: float = 2.5
## Distância em que ele começa a se afastar de outros inimigos.
@export var raio_separacao: float = 4.0
## Força do afastamento (maior = desvia mais forte).
@export var forca_separacao: float = 1.5
## Variação de altura entre voadores, pra uns passarem por cima dos outros.
@export var variacao_altura: float = 2.5

# --- DISPAROS ---

@export_group("Disparos")

@export var intervalo_tiro: float = 1.3
## Ele só atira se o jogador estiver a esta distância ou menos.
@export var distancia_tiro: float = 20.0
@export var cena_projetil: PackedScene
@export var dano_laser: float = 20.0
@export var velocidade_laser: float = 40.0
@export var tamanho_laser: float = 1.0


# --- VIDA ---

@export_group("Vida")

@export var vida_maxima: int = 50
var vida_atual: int = 50
var morto: bool = false


# --- BARRA DE VIDA ---

@export_group("Barra de Vida")
@export var altura_barra_vida: float = 4.0
@export var largura_barra_vida: float = 2
@export var espessura_barra_vida: float = 0.32

var barra_vida: Node3D
var barra_preenchimento: MeshInstance3D
var material_barra: StandardMaterial3D


# --- VARIÁVEIS INTERNAS ---

var direcao: int = 1
var posicao_inicial: Vector3
var vetor_voo: Vector3
var jogador_na_area: bool = false
var perseguindo: bool = false
var caminho_nav: PackedVector3Array = PackedVector3Array()
var tempo_caminho: float = 0.0
var angulo_posicao: float = 0.0
var altura_extra: float = 0.0

@onready var timer: Timer = $Timer
@onready var marcador: Marker3D = $Marker3D
@onready var particulas_dano: GPUParticles3D = $ParticulasDano


func _ready() -> void:
	add_to_group("inimigo")
	vida_atual = vida_maxima
		# Cada voador escolhe um lado e uma altura próprios ao redor do jogador
	angulo_posicao = randf() * TAU
	altura_extra = randf() * variacao_altura

	posicao_inicial = global_position

	var angulo = deg_to_rad(angulo_voo)
	vetor_voo = Vector3(cos(angulo), sin(angulo), 0.0)

	timer.wait_time = intervalo_tiro
	timer.timeout.connect(atirar)
	timer.stop()

	criar_barra_vida()


func _process(_delta: float) -> void:
	# Manter a barra acima do inimigo,
	# independentemente da rotação dele.
	if barra_vida != null:
		barra_vida.global_position = (
			global_position + Vector3.UP * altura_barra_vida
		)


func _physics_process(delta: float) -> void:
	if morto:
		return

	var jogador := obter_jogador()

	atualizar_estado_perseguicao(jogador)
	atualizar_disparo(jogador)

	if perseguindo and jogador != null:
		perseguir(jogador, delta)
	else:
		patrulhar(delta)

	move_and_slide()

	# --- OLHAR PARA O JOGADOR ---

	olhar_para_player()


func obter_jogador() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


# ==========================================
# PATRULHA E PERSEGUIÇÃO
# ==========================================

func patrulhar(delta: float) -> void:
	var deslocamento = global_position - posicao_inicial
	var distancia_percorrida = deslocamento.dot(vetor_voo)

	if distancia_percorrida >= distancia_voo:
		direcao = -1
	elif distancia_percorrida <= 0.0:
		direcao = 1

	var velocidade_alvo: Vector3 = vetor_voo * velocidade * direcao
	velocity = velocity.move_toward(velocidade_alvo, aceleracao * delta)


func atualizar_estado_perseguicao(jogador: Node3D) -> void:
	if not perseguir_jogador or jogador == null:
		parar_perseguicao()
		return

	# Sem patrulha: persegue o jogador de onde estiver
	if sempre_perseguir:
		perseguindo = true
		return

	var distancia := global_position.distance_to(jogador.global_position)

	if not perseguindo:
		# Percebeu o jogador (por distância ou pela Area3D)
		if distancia <= raio_perseguicao or jogador_na_area:
			perseguindo = true
	elif distancia > raio_perseguicao * fator_perder_jogador and not jogador_na_area:
		# O jogador fugiu longe demais: volta a patrulhar
		parar_perseguicao()


func parar_perseguicao() -> void:
	if not perseguindo:
		return

	perseguindo = false

	# A patrulha recomeça a partir de onde ele está agora
	posicao_inicial = global_position
	direcao = 1


func perseguir(jogador: Node3D, delta: float) -> void:
	var distancia := global_position.distance_to(jogador.global_position)
	var velocidade_alvo := Vector3.ZERO

	# Ponto de espera próprio: um lado e uma altura diferentes por voador
	var lado := Vector3(cos(angulo_posicao), 0.0, sin(angulo_posicao)) * distancia_ideal * 0.5
	var ponto_alvo: Vector3 = (
		jogador.global_position
		+ Vector3.UP * (altura_sobre_jogador + altura_extra)
		+ lado
	)

	if distancia > distancia_ideal + margem_distancia:
		var destino: Vector3 = ponto_alvo

		# Parede no meio: segue o caminho da malha de navegação
		if not tem_linha_livre(ponto_alvo):
			destino = proximo_ponto_caminho(jogador, delta)

		velocidade_alvo = (
			(destino - global_position).normalized() * velocidade_perseguicao
		)
	elif distancia < distancia_ideal - margem_distancia:
		# Perto demais: recua devagar
		velocidade_alvo = (
			(global_position - jogador.global_position).normalized()
			* velocidade_perseguicao * 0.6
		)

	# Afasta de quem estiver colado (voadores e aliens)
	velocidade_alvo += calcular_separacao() * velocidade_perseguicao

	velocity = velocity.move_toward(velocidade_alvo, aceleracao * delta)

func calcular_separacao() -> Vector3:
	var empurrao := Vector3.ZERO

	# Afasta de outros voadores e de aliens próximos
	var outros: Array = []
	outros.append_array(get_tree().get_nodes_in_group("inimigo"))

	for outro in outros:
		if outro == self or not is_instance_valid(outro) or not (outro is Node3D):
			continue

		var diferenca: Vector3 = global_position - outro.global_position
		var dist := diferenca.length()

		if dist > 0.01 and dist < raio_separacao:
			# Quanto mais perto, mais forte
			empurrao += diferenca.normalized() * (1.0 - dist / raio_separacao)

	return empurrao * forca_separacao


func olhar_para_player() -> void:
	var jogador = get_tree().get_first_node_in_group("player")

	if jogador == null:
		return

	if global_position.distance_squared_to(
		jogador.global_position
	) > 0.001:
		look_at(jogador.global_position, Vector3.UP)


# ==========================================
# BARRA DE VIDA
# ==========================================

func criar_barra_vida():
	# Nó independente da rotação do inimigo
	barra_vida = Node3D.new()
	barra_vida.name = "BarraVida"

	add_child(barra_vida)

	# Independente da transformação do pai
	barra_vida.top_level = true

	barra_vida.global_position = (
		global_position + Vector3.UP * altura_barra_vida
	)

	# Barra colorida
	barra_preenchimento = MeshInstance3D.new()
	barra_preenchimento.name = "Preenchimento"

	var mesh = QuadMesh.new()
	mesh.size = Vector2(
		largura_barra_vida,
		espessura_barra_vida
	)

	barra_preenchimento.mesh = mesh

	# Material
	material_barra = StandardMaterial3D.new()

	material_barra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_barra.albedo_color = Color.GREEN

	# Sempre voltada para a câmera
	material_barra.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	# Não deixar o modelo esconder a barra
	material_barra.no_depth_test = true

	barra_preenchimento.material_override = material_barra

	barra_vida.add_child(barra_preenchimento)

	atualizar_barra_vida()


func atualizar_barra_vida():
	if barra_preenchimento == null:
		return

	var porcentagem = 0.0

	if vida_maxima > 0:
		porcentagem = clampf(
			float(vida_atual) / float(vida_maxima),
			0.0,
			1.0
		)

	# Reduzir a barra
	barra_preenchimento.scale.x = porcentagem

	# Manter alinhamento à esquerda
	barra_preenchimento.position.x = (
		-(largura_barra_vida / 2.0) * (1.0 - porcentagem)
	)

	# Alterar cor conforme a vida
	if porcentagem > 0.5:
		material_barra.albedo_color = Color.GREEN

	elif porcentagem > 0.25:
		material_barra.albedo_color = Color.YELLOW

	else:
		material_barra.albedo_color = Color.RED


# ==========================================
# SISTEMA DE DISPARO
# ==========================================

func atualizar_disparo(jogador: Node3D) -> void:
	var pode_atirar := (
		jogador != null
		and global_position.distance_to(jogador.global_position) <= distancia_tiro
	)

	if pode_atirar:
		if timer.is_stopped():
			timer.start()
	elif not timer.is_stopped():
		timer.stop()


func atirar() -> void:
	if morto:
		return

	var jogador = get_tree().get_first_node_in_group("player")

	if jogador == null:
		return

	var origem: Vector3 = marcador.global_position
	var destino: Vector3 = jogador.global_position + Vector3(0, 1.0, 0)
	var direcao_tiro: Vector3 = (destino - origem).normalized()

	var laser := LaserVermelho.new()
	get_tree().current_scene.add_child(laser)

	laser.global_position = origem
	laser.configurar(direcao_tiro, velocidade_laser, dano_laser, self, tamanho_laser)


# ==========================================
# DETECÇÃO DO JOGADOR (Area3D)
# ==========================================
# Agora a Area3D só serve para "avisar" o minion de que o jogador está por perto
# (ele passa a perseguir). O tiro é controlado pela distância (distancia_tiro).

func _on_area_3d_body_entered(body: Node3D) -> void:
	if morto:
		return

	if body.is_in_group("player"):
		jogador_na_area = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_na_area = false


# ==========================================
# SISTEMA DE VIDA E PARTÍCULAS
# ==========================================

func receber_dano(quantidade: int) -> void:
	if morto or quantidade <= 0:
		return

	vida_atual = max(vida_atual - quantidade, 0)

	atualizar_barra_vida()

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


# ==========================================
# MORTE
# ==========================================

func morrer() -> void:
	if morto:
		return

	morto = true
	jogador_na_area = false
	perseguindo = false

	timer.stop()

	if barra_vida:
		barra_vida.queue_free()

	queue_free()
	
func tem_linha_livre(destino: Vector3) -> bool:
	var consulta := PhysicsRayQueryParameters3D.create(global_position, destino)
	consulta.exclude = [get_rid()]

	return get_world_3d().direct_space_state.intersect_ray(consulta).is_empty()


func proximo_ponto_caminho(jogador: Node3D, delta: float) -> Vector3:
	# Recalcula o caminho 3x por segundo, não todo frame
	tempo_caminho -= delta

	if tempo_caminho <= 0.0:
		tempo_caminho = 0.3

		var mapa := get_world_3d().navigation_map
		var de := NavigationServer3D.map_get_closest_point(mapa, global_position)
		var para := NavigationServer3D.map_get_closest_point(mapa, jogador.global_position)
		caminho_nav = NavigationServer3D.map_get_path(mapa, de, para, true)

	# Primeiro ponto do caminho que ainda não alcançou (na horizontal)
	for ponto in caminho_nav:
		var plano := Vector2(ponto.x - global_position.x, ponto.z - global_position.z)

		if plano.length() > 1.5:
			return ponto + Vector3.UP * altura_voo_nav

	# Sem caminho (malha não gerada, por exemplo): vai direto
	return jogador.global_position + Vector3.UP * altura_sobre_jogador
