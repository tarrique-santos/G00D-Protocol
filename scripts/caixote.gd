extends MeshInstance3D
## Caixote destrutível: quebra depois de levar N golpes (tiro, soco, laser refletido).
## Cada golpe solta farpas e faz o caixote tremer; ao quebrar, solta uma explosão
## maior de fragmentos.

@export var golpes_para_quebrar: int = 3

@export_group("Fragmentos")
## Farpas soltas a cada golpe que NÃO quebra o caixote.
@export var farpas_por_golpe: int = 10
## Pedaços soltos quando o caixote quebra.
@export var fragmentos_ao_quebrar: int = 24
## Usa o material do próprio caixote nos fragmentos (se ele tiver um).
@export var usar_material_do_caixote: bool = true
## Cor dos fragmentos se o caixote não tiver material.
@export var cor_fragmentos: Color = Color("#8a5a2b")

@onready var corpo: Node = get_node_or_null("StaticBody3D")

var golpes: int = 0
var destruido: bool = false

var _posicao_original: Vector3
var _tween_tremor: Tween
var _material_fragmentos: Material


func _ready() -> void:
	_posicao_original = position
	_material_fragmentos = _obter_material()
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
	print("Caixote atingido: ", golpes, "/", golpes_para_quebrar)

	if golpes >= golpes_para_quebrar:
		quebrar()
		return

	# Farpas voam na direção de quem atirou
	var direcao := _direcao_do_impacto()
	var origem := _centro_global() + direcao * (_meia_diagonal() * 0.8)

	_emitir_fragmentos(
		farpas_por_golpe, Vector3(0.05, 0.05, 0.22),
		origem, direcao, 55.0, 2.5, 5.5
	)
	_tremer()


func quebrar() -> void:
	destruido = true

	print("Caixote destruído!")

	if corpo != null:
		corpo.set_deferred("collision_layer", 0)
		corpo.set_deferred("collision_mask", 0)

	var centro := _centro_global()

	# Pedaços grandes e farpas, espalhados para cima e para os lados
	_emitir_fragmentos(
		fragmentos_ao_quebrar, Vector3(0.16, 0.16, 0.16),
		centro, Vector3.UP, 180.0, 3.0, 7.0
	)
	_emitir_fragmentos(
		fragmentos_ao_quebrar, Vector3(0.05, 0.05, 0.25),
		centro, Vector3.UP, 180.0, 3.0, 8.0
	)

	queue_free()


# ---------------------------------------------------------------- Efeitos

func _emitir_fragmentos(
	quantidade: int,
	tamanho_peca: Vector3,
	origem: Vector3,
	direcao: Vector3,
	abertura: float,
	velocidade_min: float,
	velocidade_max: float
) -> void:
	var peca := BoxMesh.new()
	peca.size = tamanho_peca
	peca.material = _material_fragmentos

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

	# Rotação inicial aleatória e giro enquanto voam
	processo.particle_flag_rotate_y = true
	processo.angle_min = 0.0
	processo.angle_max = 360.0
	processo.angular_velocity_min = -540.0
	processo.angular_velocity_max = 540.0

	processo.scale_min = 0.6
	processo.scale_max = 1.2
	processo.scale_curve = curva_textura

	processo.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	processo.emission_sphere_radius = 0.15

	# GPUParticles3D: quem desenha as peças
	var particulas := GPUParticles3D.new()
	particulas.process_material = processo
	particulas.draw_pass_1 = peca
	particulas.amount = quantidade
	particulas.lifetime = 0.9
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.randomness = 0.6
	particulas.local_coords = false
	particulas.top_level = true
	# Área de visibilidade grande, para as peças não sumirem ao se afastar
	particulas.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))

	# Fica na cena (e não neste nó), para continuar depois do caixote sumir
	get_tree().current_scene.add_child(particulas)
	particulas.global_position = origem
	particulas.emitting = true

	get_tree().create_timer(particulas.lifetime + 0.5).timeout.connect(particulas.queue_free)


func _tremer() -> void:
	if _tween_tremor != null and _tween_tremor.is_valid():
		_tween_tremor.kill()

	position = _posicao_original

	_tween_tremor = create_tween()

	for i in 4:
		var desvio := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * 0.05
		_tween_tremor.tween_property(self, "position", _posicao_original + desvio, 0.03)

	_tween_tremor.tween_property(self, "position", _posicao_original, 0.03)


# ---------------------------------------------------------------- Utilidades

func _obter_material() -> Material:
	if usar_material_do_caixote:
		var material := get_active_material(0)

		if material != null:
			return material

	var padrao := StandardMaterial3D.new()
	padrao.albedo_color = cor_fragmentos
	padrao.roughness = 0.9

	return padrao


func _centro_global() -> Vector3:
	return global_transform * get_aabb().get_center()


func _meia_diagonal() -> float:
	return (get_aabb().size * global_basis.get_scale()).length() * 0.5


func _direcao_do_impacto() -> Vector3:
	var jogador := get_tree().get_first_node_in_group("player") as Node3D

	if jogador == null:
		return Vector3.UP

	var direcao := jogador.global_position + Vector3.UP - _centro_global()

	if direcao.length() < 0.01:
		return Vector3.UP

	return direcao.normalized()
