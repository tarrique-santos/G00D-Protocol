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


func parry(nova_direcao: Vector3) -> void:
	if refletido or not ativo:
		return

	refletido = true
	direcao = nova_direcao.normalized()
	velocidade *= 1.5
	dano *= 3.0

	# Evita parry duplo
	remove_from_group("projetil")

	# Feedback visual: muda a cor pra ciano
	material.albedo_color = Color.CYAN
	material.emission = Color.CYAN


func _physics_process(delta):
	if not ativo:
		return

	global_position += direcao * velocidade * delta


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
		corpo.receber_dano(int(dano))
		queue_free()
		return

	# Atingiu o cenario
	ativo = false
	queue_free()
