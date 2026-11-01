
class_name LaserVermelho
extends Area3D

var direcao: Vector3 = Vector3.FORWARD
var velocidade: float = 25.0
var dano: float = 10.0
var ativo: bool = true


func _ready():
	collision_layer = 0
	collision_mask = 1
	monitoring = true

	# Aparencia do laser
	var mesh = MeshInstance3D.new()
	var esfera = SphereMesh.new()

	esfera.radius = 0.12
	esfera.height = 0.24

	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED
	material.emission_energy_multiplier = 5.0

	esfera.material = material
	mesh.mesh = esfera

	add_child(mesh)

	# Colisao
	var shape = CollisionShape3D.new()
	var esfera_colisao = SphereShape3D.new()

	esfera_colisao.radius = 0.25
	shape.shape = esfera_colisao

	add_child(shape)

	body_entered.connect(_ao_atingir)

	# Tempo de vida
	await get_tree().create_timer(5.0).timeout

	if is_instance_valid(self):
		queue_free()


func configurar(dir: Vector3, vel: float, valor_dano: float):
	direcao = dir.normalized()
	velocidade = vel
	dano = valor_dano


func _physics_process(delta):
	if not ativo:
		return

	global_position += direcao * velocidade * delta


func _ao_atingir(corpo: Node3D):
	if not ativo:
		return

	# Atingiu o jogador
	if corpo.is_in_group("player"):
		ativo = false

		if corpo.has_method("receber_dano"):
			corpo.receber_dano(dano)

		queue_free()
		return

	# Atingiu um inimigo
	if corpo is AlienInimigo:
		ativo = false
		corpo.receber_dano(dano)
		queue_free()
		return

	# Atingiu o cenario
	ativo = false
	queue_free()
