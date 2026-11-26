extends Area3D

## Seção da zona: ela some quando o checkpoint com número igual ou maior for ativado.
@export var secao: int = 1
## Porta que abre quando todos os inimigos da zona morrerem (opcional).
@export var porta: Node
## Porta que fecha quando os inimigos aparecem (opcional).
@export var porta_para_fechar: Node
## Elevador que destrava quando todos os inimigos da zona morrerem (opcional).
@export var elevador: Node

@export_group("Efeito de Teleporte")
@export var cor_teleporte: Color = Color(0.2, 0.6, 1.0)
@export var duracao_teleporte: float = 0.4
@export var raio_teleporte: float = 1.2
@export var altura_teleporte: float = 6.0

## Tempo entre o spawn de um inimigo e o próximo.
@export var intervalo_entre_spawns: float = 0.15

var inimigos: Array[Node] = []
var estado_original: Dictionary = {}
var ativada: bool = false


func _ready() -> void:
	# Se o jogador já passou do checkpoint dessa seção, a zona não existe mais
	if Progresso.indice_checkpoint >= secao:
		for filho in get_children():
			if not (filho is CollisionShape3D):
				filho.queue_free()
		monitoring = false

		# Porta já nasce aberta, senão o jogador fica trancado
		if porta != null and porta.has_method("abrir"):
			porta.abrir(true)
		
		
		if elevador != null and elevador.has_method("destravar"):
			elevador.destravar()
		return

	# Guarda os inimigos (todo filho que não é a caixa de colisão) e esconde
	for filho in get_children():
		if filho is CollisionShape3D:
			continue
		inimigos.append(filho)

	for inimigo in inimigos:
		_desligar(inimigo)

	body_entered.connect(_ao_entrar)
	Progresso.checkpoint_mudou.connect(_ao_mudar_checkpoint)


func _desligar(inimigo: Node) -> void:
	var dados := {}

	if inimigo is CollisionObject3D:
		dados["layer"] = inimigo.collision_layer
		dados["mask"] = inimigo.collision_mask
		inimigo.collision_layer = 0
		inimigo.collision_mask = 0

	estado_original[inimigo] = dados

	if inimigo is Node3D:
		inimigo.visible = false

	inimigo.process_mode = Node.PROCESS_MODE_DISABLED
	_parar_filhos(inimigo)


func _parar_filhos(no: Node) -> void:
	for filho in no.get_children():
		if filho is Timer:
			filho.stop()
		elif filho is AnimationPlayer:
			filho.stop()
		elif filho is GPUParticles3D:
			filho.emitting = false

		if filho.process_mode == Node.PROCESS_MODE_ALWAYS:
			filho.process_mode = Node.PROCESS_MODE_INHERIT

		_parar_filhos(filho)


func _ligar(inimigo: Node) -> void:
	if not is_instance_valid(inimigo):
		return

	var dados: Dictionary = estado_original.get(inimigo, {})

	if inimigo is CollisionObject3D and dados.has("layer"):
		inimigo.collision_layer = dados["layer"]
		inimigo.collision_mask = dados["mask"]

	if inimigo is Node3D:
		inimigo.visible = true
		_efeito_teleporte(inimigo.global_position)

	inimigo.process_mode = Node.PROCESS_MODE_INHERIT

	# Boss e outros que precisam de ativação explícita
	if inimigo.has_method("ativar"):
		inimigo.ativar()


func _ao_entrar(corpo: Node3D) -> void:
	if ativada or not corpo.is_in_group("player"):
		return

	ativada = true
	set_deferred("monitoring", false)

	# Tranca a porta assim que os inimigos começam a aparecer
	if porta_para_fechar != null and porta_para_fechar.has_method("fechar"):
		porta_para_fechar.fechar()

	for inimigo in inimigos:
		_ligar(inimigo)

		if intervalo_entre_spawns > 0.0:
			await get_tree().create_timer(intervalo_entre_spawns).timeout


func _ao_mudar_checkpoint(indice: int) -> void:
	# Checkpoint passou dessa seção: remove inimigos que ainda não apareceram
	if indice >= secao and not ativada:
		for inimigo in inimigos:
			if is_instance_valid(inimigo):
				inimigo.queue_free()
		monitoring = false

		if porta != null and porta.has_method("abrir"):
			porta.abrir(true)
			
		if elevador != null and elevador.has_method("destravar"):
			elevador.destravar()
		
func _physics_process(_delta: float) -> void:
	if not ativada or (porta == null and elevador == null):
		return

	for inimigo in inimigos:
		if not is_instance_valid(inimigo):
			continue
		if "morto" in inimigo and inimigo.morto:
			continue
		return  # ainda tem inimigo vivo

	# Todos mortos
	if porta != null and porta.has_method("abrir"):
		porta.abrir()

	if elevador != null and elevador.has_method("destravar"):
		elevador.destravar()

	set_physics_process(false)
	
func _efeito_teleporte(posicao: Vector3) -> void:
	var cilindro := MeshInstance3D.new()
	var malha := CylinderMesh.new()
	malha.top_radius = 1.0
	malha.bottom_radius = 1.0
	malha.height = 1.0
	malha.radial_segments = 24

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(cor_teleporte, 0.9)
	malha.material = mat
	cilindro.mesh = malha

	get_tree().current_scene.add_child(cilindro)

	# Começa largo e baixo, termina fino e alto
	cilindro.global_position = posicao + Vector3.UP * 0.5
	cilindro.scale = Vector3(raio_teleporte, 0.5, raio_teleporte)

	var altura_final := altura_teleporte
	var tween := cilindro.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(cilindro, "scale", Vector3(0.05, altura_final, 0.05), duracao_teleporte)
	tween.tween_property(cilindro, "global_position:y", posicao.y + altura_final * 0.5, duracao_teleporte)
	tween.tween_property(mat, "albedo_color:a", 0.0, duracao_teleporte)
	tween.chain().tween_callback(cilindro.queue_free)
