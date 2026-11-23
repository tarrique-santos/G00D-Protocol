class_name LaserVermelho
extends Area3D

var direcao: Vector3 = Vector3.FORWARD
var velocidade: float = 25.0
var dano: float = 10.0
var ativo: bool = true
var refletido: bool = false
var atirador: Node3D = null
var tamanho: float = 1.0

var material: StandardMaterial3D
var esfera_visual: SphereMesh
var esfera_colisao: SphereShape3D

var explosivo: bool = false
var raio_explosao: float = 10.0
var multiplicador_velocidade_perfeito: float = 4.0
var multiplicador_dano_perfeito: float = 5.0
var rids_ignorados: Array[RID] = []

func _ready():
	# Camada 3: só pro soco/parry detectar o laser.
	collision_layer = 1 << 2
	collision_mask = 1
	monitoring = true

	add_to_group("projetil")

	# Aparencia do laser
	var mesh = MeshInstance3D.new()
	esfera_visual = SphereMesh.new()

	material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED
	material.emission_energy_multiplier = 5.0

	esfera_visual.material = material
	mesh.mesh = esfera_visual

	add_child(mesh)

	# Colisao
	var shape = CollisionShape3D.new()
	esfera_colisao = SphereShape3D.new()
	shape.shape = esfera_colisao

	add_child(shape)

	# Aplica o tamanho padrao (1.0). O configurar() pode mudar depois.
	_aplicar_tamanho()

	body_entered.connect(_ao_atingir)

	# Tempo de vida
	await get_tree().create_timer(5.0).timeout

	if is_instance_valid(self):
		queue_free()


func configurar(
	dir: Vector3,
	vel: float,
	valor_dano: float,
	quem_atirou: Node3D = null,
	novo_tamanho: float = 1.0
):
	direcao = dir.normalized()
	velocidade = vel
	dano = valor_dano
	atirador = quem_atirou
	tamanho = novo_tamanho

	_aplicar_tamanho()


func _aplicar_tamanho() -> void:
	if esfera_visual == null or esfera_colisao == null:
		return

	esfera_visual.radius = 0.12 * tamanho
	esfera_visual.height = 0.24 * tamanho
	esfera_colisao.radius = 0.25 * tamanho


func parry(nova_direcao: Vector3, perfeito: bool = false) -> void:
	if refletido or not ativo:
		return

	refletido = true
	direcao = nova_direcao.normalized()

	# Evita parry duplo
	remove_from_group("projetil")

	if perfeito:
		explosivo = true
		velocidade *= multiplicador_velocidade_perfeito
		dano *= multiplicador_dano_perfeito
		tamanho *= 1.5
		_aplicar_tamanho()

		# O raio de colisão ignora o jogador
		for p in get_tree().get_nodes_in_group("player"):
			if p is CollisionObject3D:
				rids_ignorados.append(p.get_rid())

		material.albedo_color = Color(1.0, 0.85, 0.2)
		material.emission = Color(1.0, 0.85, 0.2)
	else:
		velocidade *= 1.5
		dano *= 3.0

		material.albedo_color = Color.CYAN
		material.emission = Color.CYAN


func _physics_process(delta):
	if not ativo:
		return

	var passo: Vector3 = direcao * velocidade * delta

	# Laser perfeito é rápido demais: confere o caminho com um raio
	if explosivo:
		var consulta := PhysicsRayQueryParameters3D.create(
			global_position,
			global_position + passo + direcao * 0.3
		)
		consulta.exclude = rids_ignorados

		var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)

		if not resultado.is_empty():
			global_position = resultado["position"]
			_ao_atingir(resultado["collider"])
			return

	global_position += passo


func _ao_atingir(corpo: Node3D):
	if not ativo:
		return

	# Nunca machuca quem atirou (a não ser depois de refletido)
	if corpo == atirador and not refletido:
		return

	# Depois do parry, o laser passa pelo jogador
	if refletido and corpo.is_in_group("player"):
		return

	# Atingiu o jogador
	if corpo.is_in_group("player"):
		# Se o soco está na janela de parry, vira parry em vez de dano
		if corpo.has_method("tentar_parry_em_cima") and corpo.tentar_parry_em_cima(self):
			return

		ativo = false

		if corpo.has_method("receber_dano"):
			corpo.receber_dano(int(dano))

		queue_free()
		return

	# Atingiu um inimigo (qualquer um que tenha receber_dano)
	if corpo.has_method("receber_dano"):
		if not refletido:
			return  # passa direto, sem desativar o laser

		ativo = false

		if explosivo:
			_explodir()
		else:
			corpo.receber_dano(int(dano))

		queue_free()
		return

	# Atingiu o cenario
	ativo = false

	if explosivo:
		_explodir()

	queue_free()
	
func _explodir() -> void:
	var cena := get_tree().current_scene
	var centro := global_position

	# Dano em área (o jogador não leva dano)
	var forma := SphereShape3D.new()
	forma.radius = raio_explosao

	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = forma
	consulta.transform = Transform3D(Basis.IDENTITY, centro)
	consulta.exclude = rids_ignorados

	var atingidos: Array = []

	for r in get_world_3d().direct_space_state.intersect_shape(consulta, 32):
		var alvo = r["collider"]

		if alvo in atingidos or alvo.is_in_group("player"):
			continue

		if alvo.has_method("receber_dano"):
			atingidos.append(alvo)
			alvo.receber_dano(int(dano))

	_criar_efeito_explosao(cena, centro)


func _criar_efeito_explosao(cena: Node, centro: Vector3) -> void:
	# Bola de fogo que cresce e some
	var bola := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.8, 0.2, 0.9)
	esfera.material = mat
	bola.mesh = esfera

	cena.add_child(bola)
	bola.global_position = centro
	bola.scale = Vector3.ONE * 0.3

	var tween := bola.create_tween()
	tween.set_parallel(true)
	tween.tween_property(bola, "scale", Vector3.ONE * raio_explosao, 0.25)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.chain().tween_callback(bola.queue_free)

	# Faíscas
	var mesh_faisca := SphereMesh.new()
	mesh_faisca.radius = 0.08
	mesh_faisca.height = 0.16

	var mat_faisca := StandardMaterial3D.new()
	mat_faisca.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_faisca.albedo_color = Color(1.0, 0.6, 0.1)
	mesh_faisca.material = mat_faisca

	var faiscas := CPUParticles3D.new()
	faiscas.mesh = mesh_faisca
	faiscas.amount = 40
	faiscas.lifetime = 0.7
	faiscas.one_shot = true
	faiscas.explosiveness = 1.0
	faiscas.direction = Vector3.UP
	faiscas.spread = 180.0
	faiscas.initial_velocity_min = 6.0
	faiscas.initial_velocity_max = 14.0
	faiscas.gravity = Vector3(0, -9.8, 0)

	cena.add_child(faiscas)
	faiscas.global_position = centro
	faiscas.emitting = true
	get_tree().create_timer(1.5).timeout.connect(faiscas.queue_free)

	# Flash de luz
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.7, 0.2)
	luz.light_energy = 8.0
	luz.omni_range = raio_explosao * 2.0

	cena.add_child(luz)
	luz.global_position = centro

	var tween_luz := luz.create_tween()
	tween_luz.tween_property(luz, "light_energy", 0.0, 0.3)
	tween_luz.tween_callback(luz.queue_free)
