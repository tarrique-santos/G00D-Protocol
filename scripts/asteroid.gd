
extends CharacterBody3D


# ==========================================
# VIDA
# ==========================================

@export_group("Vida")
@export var vida_maxima: float = 60.0

var vida_atual: float
var destruido: bool = false


# ==========================================
# MOVIMENTAÇÃO
# ==========================================

@export_group("Movimentacao")
@export var velocidade_minima: float = 1.0
@export var velocidade_maxima: float = 3.0

@export var intervalo_mudanca_direcao_min: float = 4.0
@export var intervalo_mudanca_direcao_max: float = 8.0

@export var suavidade_direcao: float = 0.5

var direcao: Vector3
var direcao_alvo: Vector3
var velocidade: float
var tempo_mudanca_direcao: float = 0.0


# ==========================================
# ROTAÇÃO
# ==========================================

@export_group("Rotacao")
@export var rotacao_minima: float = 0.02
@export var rotacao_maxima: float = 0.08

var eixo_rotacao: Vector3
var velocidade_rotacao: float


# ==========================================
# EFEITOS DE DESTRUIÇÃO
# ==========================================

@export_group("Destruicao")
@export var quantidade_fragmentos: int = 35
@export var quantidade_poeira: int = 60
@export var duracao_fragmentos: float = 3.0
@export var duracao_poeira: float = 4.0

@export var forca_explosao_minima: float = 2.5
@export var forca_explosao_maxima: float = 8.0


# ==========================================
# VARIÁVEIS INTERNAS
# ==========================================

var rng := RandomNumberGenerator.new()


func _ready():
	rng.randomize()

	vida_atual = vida_maxima

	# Velocidade aleatória
	velocidade = rng.randf_range(
		velocidade_minima,
		velocidade_maxima
	)

	# Direção horizontal inicial
	direcao = sortear_direcao()
	direcao_alvo = direcao

	sortear_tempo_direcao()

	# Eixo aleatório de rotação
	eixo_rotacao = Vector3(
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(-1.0, 1.0)
	).normalized()

	# Velocidade de rotação muito lenta
	velocidade_rotacao = rng.randf_range(
		rotacao_minima,
		rotacao_maxima
	)

	# Sorteia o sentido da rotação
	if rng.randf() > 0.5:
		velocidade_rotacao *= -1.0


func _physics_process(delta):
	if destruido:
		return

	# ==================================
	# MUDANÇA DE DIREÇÃO
	# ==================================

	tempo_mudanca_direcao -= delta

	if tempo_mudanca_direcao <= 0.0:
		direcao_alvo = sortear_direcao()
		sortear_tempo_direcao()

	# Suavizar mudança de direção
	var suavizacao = 1.0 - exp(-suavidade_direcao * delta)

	direcao = direcao.lerp(
		direcao_alvo,
		suavizacao
	).normalized()

	# ==================================
	# MOVIMENTO HORIZONTAL
	# ==================================

	velocity = direcao * velocidade

	move_and_slide()

	# ==================================
	# ROTAÇÃO SUAVE
	# ==================================

	rotate_object_local(
		eixo_rotacao,
		velocidade_rotacao * delta
	)


# ==========================================
# ALEATORIEDADE
# ==========================================

func sortear_direcao() -> Vector3:
	var angulo = rng.randf_range(0.0, TAU)

	return Vector3(
		cos(angulo),
		0.0,
		sin(angulo)
	).normalized()


func sortear_tempo_direcao():
	tempo_mudanca_direcao = rng.randf_range(
		intervalo_mudanca_direcao_min,
		intervalo_mudanca_direcao_max
	)


# ==========================================
# RECEBER DANO
# ==========================================

func receber_dano(quantidade: float):
	if destruido or quantidade <= 0:
		return

	vida_atual = maxf(
		vida_atual - quantidade,
		0.0
	)

	print(
		"Asteroide atingido! Vida: ",
		vida_atual,
		"/",
		vida_maxima
	)

	if vida_atual <= 0:
		destruir()


# ==========================================
# DESTRUIÇÃO
# ==========================================

func destruir():
	if destruido:
		return

	destruido = true

	velocity = Vector3.ZERO

	collision_layer = 0
	collision_mask = 0

	var colisao = get_node_or_null("CollisionShape3D")

	if colisao:
		colisao.set_deferred("disabled", true)

	criar_efeito_destruicao()

	print("Asteroide despedaçado!")

	queue_free()


# ==========================================
# EFEITO DE DESTRUIÇÃO
# ==========================================

func criar_efeito_destruicao():

	var efeito = Node3D.new()
	efeito.name = "EfeitoDestruicao"

	get_tree().current_scene.add_child(efeito)

	efeito.global_position = global_position


	# ==================================
	# FRAGMENTOS DE ROCHA
	# ==================================

	var fragmentos = GPUParticles3D.new()

	fragmentos.name = "Fragmentos"
	fragmentos.amount = quantidade_fragmentos
	fragmentos.lifetime = duracao_fragmentos
	fragmentos.one_shot = true
	fragmentos.explosiveness = 1.0
	fragmentos.local_coords = false

	fragmentos.visibility_aabb = AABB(
		Vector3(-15, -15, -15),
		Vector3(30, 30, 30)
	)

	var material_fragmentos = ParticleProcessMaterial.new()

	material_fragmentos.direction = Vector3.UP
	material_fragmentos.spread = 180.0

	material_fragmentos.initial_velocity_min = forca_explosao_minima
	material_fragmentos.initial_velocity_max = forca_explosao_maxima

	material_fragmentos.gravity = Vector3.ZERO

	material_fragmentos.damping_min = 0.3
	material_fragmentos.damping_max = 1.5

	material_fragmentos.scale_min = 0.5
	material_fragmentos.scale_max = 1.5

	material_fragmentos.angular_velocity_min = -180.0
	material_fragmentos.angular_velocity_max = 180.0

	fragmentos.process_material = material_fragmentos

	# Aparência dos fragmentos
	var mesh_rocha = SphereMesh.new()

	mesh_rocha.radius = 0.13
	mesh_rocha.height = 0.22
	mesh_rocha.radial_segments = 5
	mesh_rocha.rings = 3

	var material_rocha = StandardMaterial3D.new()

	material_rocha.albedo_color = Color(0.32, 0.29, 0.25)
	material_rocha.roughness = 1.0

	mesh_rocha.material = material_rocha

	fragmentos.draw_pass_1 = mesh_rocha

	efeito.add_child(fragmentos)

	fragmentos.emitting = true


	# ==================================
	# NUVEM DE POEIRA
	# ==================================

	var poeira = GPUParticles3D.new()

	poeira.name = "Poeira"
	poeira.amount = quantidade_poeira
	poeira.lifetime = duracao_poeira
	poeira.one_shot = true
	poeira.explosiveness = 1.0
	poeira.local_coords = false

	poeira.visibility_aabb = AABB(
		Vector3(-15, -15, -15),
		Vector3(30, 30, 30)
	)

	var material_poeira = ParticleProcessMaterial.new()

	material_poeira.direction = Vector3.UP
	material_poeira.spread = 180.0

	material_poeira.initial_velocity_min = 0.5
	material_poeira.initial_velocity_max = 3.0

	material_poeira.gravity = Vector3.ZERO

	material_poeira.damping_min = 0.5
	material_poeira.damping_max = 1.5

	material_poeira.scale_min = 0.5
	material_poeira.scale_max = 2.0

	poeira.process_material = material_poeira

	# Gradiente de poeira
	var gradiente = Gradient.new()

	gradiente.set_color(
		0,
		Color(0.75, 0.72, 0.65, 0.4)
	)

	gradiente.set_color(
		1,
		Color(0.75, 0.72, 0.65, 0.0)
	)

	var textura = GradientTexture2D.new()

	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(0.5, 0.0)

	var visual_poeira = StandardMaterial3D.new()

	visual_poeira.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visual_poeira.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual_poeira.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES

	visual_poeira.albedo_texture = textura
	visual_poeira.albedo_color = Color.WHITE

	var mesh_poeira = QuadMesh.new()

	mesh_poeira.size = Vector2(0.6, 0.6)
	mesh_poeira.material = visual_poeira

	poeira.draw_pass_1 = mesh_poeira

	efeito.add_child(poeira)

	poeira.emitting = true


	# ==================================
	# REMOVER EFEITOS APÓS TERMINAREM
	# ==================================

	var limpeza = Timer.new()

	limpeza.one_shot = true
	limpeza.wait_time = maxf(
		duracao_fragmentos,
		duracao_poeira
	) + 0.5

	efeito.add_child(limpeza)

	limpeza.timeout.connect(
		efeito.queue_free
	)

	limpeza.start()
