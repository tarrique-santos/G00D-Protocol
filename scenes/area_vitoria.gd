extends Area3D

## Arraste o boss aqui no Inspector
@export var boss: Node

## Tela de vitória (sem botão). Aparece primeiro.
@export var tela_vitoria: PackedScene

## Tela de créditos (com botão de voltar ao menu). Aparece depois da vitória.
@export var tela_creditos: PackedScene

## Usado se "tela_creditos" estiver vazia. Ajuste para o caminho da sua cena.
@export_file("*.tscn") var caminho_creditos: String = "res://scenes/UI/creditos.tscn"

@export_group("Sequência")
## Tempo que a tela de vitória fica na tela antes dos créditos.
@export var duracao_vitoria: float = 3.0
## Duração do fade ao trocar de tela.
@export var duracao_fade: float = 0.8

@export_group("Marcação")
@export var cor_marcacao: Color = Color(1.0, 0.85, 0.2)
@export var altura_seta: float = 1.0

var vitoria_ativada: bool = false

var _visual_marcacao: MeshInstance3D
var _seta_marcacao: MeshInstance3D


func _ready() -> void:
	monitoring = false
	body_entered.connect(_ao_entrar)

	if boss != null:
		if boss.has_signal("morreu"):
			if not boss.morreu.is_connected(_ao_boss_morrer):
				boss.morreu.connect(_ao_boss_morrer)
		else:
			push_warning("AreaVitoria: o boss não possui o sinal 'morreu'.")


func _ao_boss_morrer() -> void:
	if vitoria_ativada:
		return

	set_deferred("monitoring", true)
	_criar_marcacao()


func _ao_entrar(corpo: Node3D) -> void:
	if vitoria_ativada:
		return

	if not corpo.is_in_group("player"):
		return

	vitoria_ativada = true

	set_deferred("monitoring", false)

	_remover_marcacao()
	_ocultar_hud()

	_sequencia_final()


# ==================================================
# SEQUÊNCIA: VITÓRIA -> CRÉDITOS
# ==================================================

func _sequencia_final() -> void:
	if tela_vitoria == null:
		push_warning("AreaVitoria: tela_vitoria não foi atribuída.")
		return

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Pausa o jogo; as telas continuam funcionando (process_mode ALWAYS)
	get_tree().paused = true

	# Este nó precisa continuar rodando com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Descobre a cena de créditos ANTES de começar (campo ou caminho)
	var cena_creditos: PackedScene = tela_creditos

	if cena_creditos == null and ResourceLoader.exists(caminho_creditos):
		cena_creditos = load(caminho_creditos) as PackedScene

	if cena_creditos == null:
		push_error("AreaVitoria: créditos não encontrados. Atribua 'Tela Creditos' no Inspector.")

	var camada_vitoria := _abrir_tela(tela_vitoria)

	print("[AreaVitoria] vitória aberta, créditos em ", duracao_vitoria, " s")

	# Espera mesmo com o jogo pausado (segundo parâmetro = ignora a pausa)
	await get_tree().create_timer(duracao_vitoria, true).timeout

	if cena_creditos == null:
		return

	# Fade out da vitória (se o fade falhar, segue direto para os créditos)
	var tela := camada_vitoria.get_child(0) as CanvasItem

	if tela != null:
		var tween := tela.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(tela, "modulate:a", 0.0, duracao_fade)

		await get_tree().create_timer(duracao_fade, true).timeout

	camada_vitoria.queue_free()

	print("[AreaVitoria] abrindo créditos")

	# Créditos: o botão "Voltar ao menu" fica na própria tela de créditos
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_abrir_tela(cena_creditos)


## Instancia a tela dentro de uma CanvasLayer alta, para ficar acima de qualquer HUD.
func _abrir_tela(cena: PackedScene) -> CanvasLayer:
	var camada := CanvasLayer.new()
	camada.layer = 100
	camada.process_mode = Node.PROCESS_MODE_ALWAYS

	var tela := cena.instantiate()
	tela.process_mode = Node.PROCESS_MODE_ALWAYS

	camada.add_child(tela)
	get_tree().current_scene.add_child(camada)

	return camada


func _ocultar_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")

	if hud != null:
		hud.hide()


# ==================================================
# MARCAÇÃO DA ÁREA
# ==================================================

func _remover_marcacao() -> void:
	if is_instance_valid(_visual_marcacao):
		_visual_marcacao.queue_free()

	if is_instance_valid(_seta_marcacao):
		_seta_marcacao.queue_free()


func _criar_marcacao() -> void:
	var colisao: CollisionShape3D = null

	for filho in get_children():
		if filho is CollisionShape3D:
			colisao = filho
			break

	if colisao == null or colisao.shape == null:
		push_warning("AreaVitoria: sem CollisionShape3D com shape.")
		return

	var forma := colisao.shape
	var malha: Mesh = null

	if forma is BoxShape3D:
		var m := BoxMesh.new()
		m.size = forma.size
		malha = m

	elif forma is SphereShape3D:
		var m := SphereMesh.new()
		m.radius = forma.radius
		m.height = forma.radius * 2.0
		malha = m

	elif forma is CylinderShape3D:
		var m := CylinderMesh.new()
		m.top_radius = forma.radius
		m.bottom_radius = forma.radius
		m.height = forma.height
		malha = m

	elif forma is CapsuleShape3D:
		var m := CapsuleMesh.new()
		m.radius = forma.radius
		m.height = forma.height
		malha = m

	else:
		push_warning("AreaVitoria: formato de colisão sem suporte.")
		return

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(cor_marcacao, 0.3)

	malha.material = mat

	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	colisao.add_child(visual)
	_visual_marcacao = visual

	var tw_visual := visual.create_tween().set_loops()
	tw_visual.tween_property(mat, "albedo_color:a", 0.5, 0.8)
	tw_visual.tween_property(mat, "albedo_color:a", 0.2, 0.8)

	var topo: float = colisao.position.y + malha.get_aabb().end.y * colisao.scale.y
	var y_base := topo + altura_seta

	var mat_seta := StandardMaterial3D.new()
	mat_seta.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_seta.albedo_color = cor_marcacao

	var malha_seta := CylinderMesh.new()
	malha_seta.top_radius = 0.0
	malha_seta.bottom_radius = 0.7
	malha_seta.height = 1.4
	malha_seta.material = mat_seta

	var seta := MeshInstance3D.new()
	seta.mesh = malha_seta
	seta.rotation.x = PI
	seta.position = Vector3(colisao.position.x, y_base, colisao.position.z)
	seta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(seta)
	_seta_marcacao = seta

	var tw_seta := seta.create_tween().set_loops()
	tw_seta.set_trans(Tween.TRANS_SINE)
	tw_seta.tween_property(seta, "position:y", y_base + 0.6, 0.6)
	tw_seta.tween_property(seta, "position:y", y_base, 0.6)
