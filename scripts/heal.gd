extends MeshInstance3D
## Barricada destrutível (sacos de areia): quebra depois de levar N golpes.
## Cada golpe solta pedaços e areia; ao quebrar, solta uma explosão maior.
## Anexe este script ao MeshInstance3D que tem o StaticBody3D como filho (TrenchBags).

@export var golpes_para_quebrar: int = 6

@export_group("Fragmentos")
## Pedaços e grãos soltos a cada golpe que NÃO quebra a barricada.
@export var pedacos_por_golpe: int = 8
@export var graos_por_golpe: int = 16
## Soltos quando a barricada quebra.
@export var pedacos_ao_quebrar: int = 20
@export var graos_ao_quebrar: int = 50
@export var tamanho_pedaco: float = 0.14
@export var cor_fragmentos: Color = Color("#b09a6b")
## Usa o material da barricada nos pedaços grandes (os grãos de areia sempre usam a cor).
@export var usar_material_da_barricada: bool = false

@export_group("Tremor")
@export var intensidade_tremor: float = 0.03

@onready var corpo: Node = get_node_or_null("StaticBody3D")

var golpes: int = 0
var destruido: bool = false

var _posicao_original: Vector3
var _tween_tremor: Tween
var _material_pedacos: Material
var _material_graos: Material


func _ready() -> void:
	_posicao_original = position
	_criar_materiais()

	if corpo != null:
		# Os lasers inimigos usam este grupo para serem bloqueados pela barricada
		corpo.add_to_group("destrutivel")

	_garantir_receptor_de_dano()


## O tiro e o soco do jogador acertam o StaticBody3D (o collider), então é ele
## que precisa responder a "receber_dano". Se não responder, cria um repasse
## automático para este script.
func _garantir_receptor_de_dano() -> void:
	if corpo == null:
		return
	if corpo.has_method("receber_dano") or corpo.get_script() != null:
		return

	var repasse := GDScript.new()
	repasse.source_code = (
		"extends StaticBody3D\n\n"
		+ "func receber_dano(dano = 1.0, _causa = \"\"):\n"
		+ "\tget_parent().receber_dano(dano)\n"
	)
	repasse.reload()
	corpo.set_script(repasse)


# ---------------------------------------------------------------- Dano

## Cada acerto conta como 1 golpe, não importa quanto dano ele tenha.
func receber_dano(_dano: float = 1.0, _causa: String = "") -> void:
	if destruido:
		return

	golpes += 1
	print("Barricada atingida: ", golpes, "/", golpes_para_quebrar)

	if golpes >= golpes_para_quebrar:
		quebrar()
		return

	# Pedaços e areia saem da parte da barricada mais próxima de quem atirou
	var origem := _ponto_mais_proximo_do_jogador()
	var direcao := _direcao_para_o_jogador(origem)

	_emitir_fragmentos(
		_malha_pedaco(), pedacos_por_golpe,
		origem, direcao, 50.0, 2.0, 4.5, 0.12
	)
	_emitir_fragmentos(
		_malha_grao(), graos_por_golpe,
		origem, direcao, 65.0, 2.5, 6.0, 0.15
	)
	_tremer()


func quebrar() -> void:
	destruido = true

	print("Barricada destruída!")

	if corpo != null:
		corpo.set_deferred("collision_layer", 0)
		corpo.set_deferred("collision_mask", 0)

	var centro := _centro_global()
	var raio := _meia_diagonal() * 0.35

	_emitir_fragmentos(
		_malha_pedaco(), pedacos_ao_quebrar,
		centro, Vector3.UP, 180.0, 3.0, 7.0, raio
	)
	_emitir_fragmentos(
		_malha_grao(), graos_ao_quebrar,
		centro, Vector3.UP, 180.0, 3.0, 8.0, raio
	)

	# Remove também o nó raiz da barricada, se este for o único filho dele
	var pai := get_parent()

	if pai is Node3D and pai.get_child_count() == 1:
		pai.queue_free()
	else:
		queue_free()


# ---------------------------------------------------------------- Efeitos

func _emitir_fragmentos(
	malha: Mesh,
	quantidade: int,
	origem: Vector3,
	direcao: Vector3,
	abertura: float,
	velocidade_min: float,
	velocidade_max: float,
	raio_emissao: float
) -> void:
	# As peças encolhem até sumir no fim da vida
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 1.0))
	curva.add_point(Vector2(0.7, 1.0))
	curva.add_point(Vector2(1.0, 0.0))

	var curva_textura := CurveTexture.new()
	curva_textura.curve = curva

	# ParticleProcessMaterial: o "comportamento" dos fragmentos
	var processo := ParticleProcessMaterial.new()
	processo.direction = direcao
	processo.spread = abertura
	processo.initial_velocity_min = velocidade_min
	processo.initial_velocity_max = velocidade_max
	processo.gravity = Vector3(0.0, -14.0, 0.0)
	processo.damping_min = 0.5
	processo.damping_max = 1.5

	processo.particle_flag_rotate_y = true
	processo.angle_min = 0.0
	processo.angle_max = 360.0
	processo.angular_velocity_min = -360.0
	processo.angular_velocity_max = 360.0

	processo.scale_min = 0.6
	processo.scale_max = 1.3
	processo.scale_curve = curva_textura

	processo.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	processo.emission_sphere_radius = maxf(raio_emissao, 0.05)

	# GPUParticles3D: quem desenha as peças
	var particulas := GPUParticles3D.new()
	particulas.process_material = processo
	particulas.draw_pass_1 = malha
	particulas.amount = quantidade
	particulas.lifetime = 0.9
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.randomness = 0.6
	particulas.local_coords = false
	particulas.top_level = true
	particulas.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))

	# Fica na cena (e não neste nó), para continuar depois da barricada sumir
	get_tree().current_scene.add_child(particulas)
	particulas.global_position = origem
	particulas.emitting = true

	get_tree().create_timer(particulas.lifetime + 0.5).timeout.connect(particulas.queue_free)


func _malha_pedaco() -> Mesh:
	var caixa := BoxMesh.new()
	caixa.size = Vector3(tamanho_pedaco, tamanho_pedaco * 0.7, tamanho_pedaco)
	caixa.material = _material_pedacos
	return caixa


func _malha_grao() -> Mesh:
	var esfera := SphereMesh.new()
	esfera.radius = tamanho_pedaco * 0.22
	esfera.height = tamanho_pedaco * 0.44
	esfera.radial_segments = 6
	esfera.rings = 3
	esfera.material = _material_graos
	return esfera


func _tremer() -> void:
	if _tween_tremor != null and _tween_tremor.is_valid():
		_tween_tremor.kill()

	position = _posicao_original

	_tween_tremor = create_tween()

	for i in 4:
		var desvio := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * intensidade_tremor
		_tween_tremor.tween_property(self, "position", _posicao_original + desvio, 0.03)

	_tween_tremor.tween_property(self, "position", _posicao_original, 0.03)


# ---------------------------------------------------------------- Utilidades

func _criar_materiais() -> void:
	var areia := StandardMaterial3D.new()
	areia.albedo_color = cor_fragmentos
	areia.roughness = 1.0

	_material_graos = areia
	_material_pedacos = areia

	if usar_material_da_barricada:
		var material := get_active_material(0)

		if material != null:
			_material_pedacos = material


func _centro_global() -> Vector3:
	return global_transform * get_aabb().get_center()


func _meia_diagonal() -> float:
	return (get_aabb().size * global_basis.get_scale()).length() * 0.5


## Ponto da barricada (na caixa que a envolve) mais perto do jogador:
## onde o tiro provavelmente acertou.
func _ponto_mais_proximo_do_jogador() -> Vector3:
	var jogador := get_tree().get_first_node_in_group("player") as Node3D

	if jogador == null:
		return _centro_global()

	var caixa := get_aabb()
	var local := global_transform.affine_inverse() * (jogador.global_position + Vector3.UP)
	var mais_perto := local.clamp(caixa.position, caixa.end)

	return global_transform * mais_perto


func _direcao_para_o_jogador(origem: Vector3) -> Vector3:
	var jogador := get_tree().get_first_node_in_group("player") as Node3D

	if jogador == null:
		return Vector3.UP

	var direcao := jogador.global_position + Vector3.UP - origem

	if direcao.length() < 0.01:
		return Vector3.UP

	return direcao.normalized()
