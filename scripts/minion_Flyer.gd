
extends CharacterBody3D

# --- MOVIMENTO ---

@export var velocidade: float = 5.0
@export_range(0.0, 360.0) var angulo_voo: float = 0.0
@export var distancia_voo: float = 10.0


# --- DISPAROS ---

@export var intervalo_tiro: float = 1.3
@export var cena_projetil: PackedScene


# --- VIDA ---

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

	criar_barra_vida()


func _process(_delta: float) -> void:
	# Manter a barra acima do inimigo,
	# independentemente da rotação dele.
	if barra_vida != null:
		barra_vida.global_position = (
			global_position + Vector3.UP * altura_barra_vida
		)


func _physics_process(_delta: float) -> void:
	if morto:
		return

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

func atirar() -> void:
	if morto or not jogador_na_area:
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


# ==========================================
# DETECÇÃO DO JOGADOR
# ==========================================

func _on_area_3d_body_entered(body: Node3D) -> void:
	if morto:
		return

	if body.is_in_group("player"):
		jogador_na_area = true
		timer.start()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_na_area = false
		timer.stop()


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

	timer.stop()

	if barra_vida:
		barra_vida.queue_free()

	queue_free()
