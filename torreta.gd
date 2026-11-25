class_name Torreta
extends StaticBody3D

@export_group("Vida")
@export var vida_maxima: int = 50
## Se ligado, só toma dano de laser refletido (parry). Tiro e soco são ignorados.
@export var so_dano_de_parry: bool = false

@export_group("Disparo")
## Tiros por rajada.
@export var tiros_por_rajada: int = 1
## Tempo entre um tiro e outro dentro da rajada.
@export var intervalo_na_rajada: float = 0.15
## Tempo de descanso entre rajadas.
@export var intervalo_rajadas: float = 1.8
@export var alcance_tiro: float = 45.0
@export var dano_laser: float = 15.0
@export var velocidade_laser: float = 30.0
@export var tamanho_laser: float = 1.0

@export_group("Mira")
@export var velocidade_giro: float = 4.0

@export_group("Barra de Vida")
@export var altura_barra_vida: float = 3.4
@export var largura_barra_vida: float = 1.6
@export var espessura_barra_vida: float = 0.25

var vida_atual: int
var morto: bool = false
var atirando: bool = false
var tempo_descanso: float = 1.0

var barra_vida: Node3D
var barra_preenchimento: MeshInstance3D
var material_barra: StandardMaterial3D

@onready var cabeca: Node3D = $Head
@onready var ponta_cano: Marker3D = $Head/PontaCano


func _ready() -> void:
	vida_atual = vida_maxima
	add_to_group("inimigo")

	criar_barra_vida()


func _physics_process(delta: float) -> void:
	if morto:
		return

	var jogador := get_tree().get_first_node_in_group("player") as Node3D

	if jogador == null:
		return

	var alvo: Vector3 = obter_ponto_mira(jogador)

	# Gira só a cabeça, suavemente
	var direcao: Vector3 = alvo - cabeca.global_position

	if direcao.length() > 0.1:
		var olhar := cabeca.global_transform.looking_at(
			cabeca.global_position + direcao, Vector3.UP
		)
		cabeca.global_transform.basis = cabeca.global_transform.basis.slerp(
			olhar.basis, clampf(velocidade_giro * delta, 0.0, 1.0)
		)

	# Controle da rajada
	if atirando:
		return

	tempo_descanso -= delta

	if tempo_descanso <= 0.0 and pode_atirar(alvo):
		disparar_rajada(jogador)


func obter_ponto_mira(jogador: Node3D) -> Vector3:
	var cam = jogador.get("camera")

	if cam != null and is_instance_valid(cam):
		return cam.global_position

	return jogador.global_position + Vector3(0, 1.6, 0)


func pode_atirar(alvo: Vector3) -> bool:
	var origem := ponta_cano.global_position

	if origem.distance_to(alvo) > alcance_tiro:
		return false

	var consulta := PhysicsRayQueryParameters3D.create(origem, alvo)
	consulta.exclude = [get_rid()]
	var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)

	if resultado.is_empty():
		return true

	return resultado["collider"].is_in_group("player")


func disparar_rajada(jogador: Node3D) -> void:
	atirando = true

	for i in range(tiros_por_rajada):
		if morto or not is_instance_valid(jogador):
			break

		atirar(obter_ponto_mira(jogador))

		if i < tiros_por_rajada - 1:
			await get_tree().create_timer(intervalo_na_rajada).timeout

	tempo_descanso = intervalo_rajadas
	atirando = false


func atirar(alvo: Vector3) -> void:
	if morto:
		return

	var origem := ponta_cano.global_position
	var direcao := (alvo - origem).normalized()

	var laser := LaserVermelho.new()
	get_tree().current_scene.add_child(laser)

	laser.global_position = origem
	laser.configurar(direcao, velocidade_laser, dano_laser, self, tamanho_laser)


# ==========================================
# VIDA
# ==========================================

func receber_dano(quantidade: int) -> void:
	# Tiro e soco caem aqui. Com a opção ligada, são ignorados.
	if so_dano_de_parry:
		return

	_aplicar_dano(quantidade)

func receber_dano_parry(quantidade: int) -> void:
	# Laser refletido e explosão do parry perfeito sempre causam dano
	_aplicar_dano(quantidade)


func _aplicar_dano(quantidade: int) -> void:
	if morto or quantidade <= 0:
		return

	vida_atual = max(vida_atual - quantidade, 0)
	atualizar_barra_vida()

	if vida_atual <= 0:
		morrer()

func morrer() -> void:
	if morto:
		return

	morto = true

	if barra_vida:
		barra_vida.queue_free()

	queue_free()


func criar_barra_vida() -> void:
	barra_vida = Node3D.new()
	barra_vida.name = "BarraVida"
	barra_vida.position.y = altura_barra_vida
	add_child(barra_vida)

	barra_preenchimento = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(largura_barra_vida, espessura_barra_vida)
	barra_preenchimento.mesh = mesh

	material_barra = StandardMaterial3D.new()
	material_barra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_barra.albedo_color = Color.GREEN
	material_barra.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	barra_preenchimento.material_override = material_barra

	barra_vida.add_child(barra_preenchimento)
	atualizar_barra_vida()


func atualizar_barra_vida() -> void:
	if barra_preenchimento == null:
		return

	var p := clampf(float(vida_atual) / float(vida_maxima), 0.0, 1.0)

	barra_preenchimento.scale.x = p
	barra_preenchimento.position.x = -(largura_barra_vida / 2.0) * (1.0 - p)

	if p > 0.5:
		material_barra.albedo_color = Color.GREEN
	elif p > 0.25:
		material_barra.albedo_color = Color.YELLOW
	else:
		material_barra.albedo_color = Color.RED
