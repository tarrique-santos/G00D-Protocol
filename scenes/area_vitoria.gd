extends Area3D

## Arraste o boss aqui no Inspector
@export var boss: Node
## Arraste o arquivo .tscn da tela de vitória (do painel FileSystem)
@export var tela_vitoria: PackedScene

@export_group("Marcação")
@export var cor_marcacao: Color = Color(1.0, 0.85, 0.2)
## Altura da seta acima do topo da área.
@export var altura_seta: float = 1.0

func _ready() -> void:
	monitoring = false  # começa desligada
	body_entered.connect(_ao_entrar)

	if boss != null:
		boss.morreu.connect(_ao_boss_morrer)

func _ao_boss_morrer() -> void:
	set_deferred("monitoring", true)
	_criar_marcacao()

func _ao_entrar(corpo: Node3D) -> void:
	if not corpo.is_in_group("player"):
		return
	set_deferred("monitoring", false)
	_mostrar_vitoria()

func _mostrar_vitoria() -> void:
	if tela_vitoria == null:
		push_warning("AreaVitoria: tela_vitoria não foi atribuída.")
		return

	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # caso o jogo prenda o mouse

	var tela := tela_vitoria.instantiate()
	tela.process_mode = Node.PROCESS_MODE_ALWAYS  # funciona com o jogo pausado
	get_tree().current_scene.add_child(tela)

func _criar_marcacao() -> void:
	# Pega o primeiro CollisionShape3D da área
	var colisao: CollisionShape3D = null
	for filho in get_children():
		if filho is CollisionShape3D:
			colisao = filho
			break

	if colisao == null or colisao.shape == null:
		push_warning("AreaVitoria: sem CollisionShape3D com shape, marcação não criada.")
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
		push_warning("AreaVitoria: formato de colisão sem suporte na marcação.")
		return

	# Material transparente que pulsa
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(cor_marcacao, 0.3)
	malha.material = mat

	# Filha da colisão: herda posição, rotação e escala dela
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	colisao.add_child(visual)

	var tw_visual := visual.create_tween().set_loops()
	tw_visual.tween_property(mat, "albedo_color:a", 0.5, 0.8)
	tw_visual.tween_property(mat, "albedo_color:a", 0.2, 0.8)

	# Seta logo acima do topo da área
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
	seta.rotation.x = PI  # ponta pra baixo
	seta.position = Vector3(colisao.position.x, y_base, colisao.position.z)
	seta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(seta)

	var tw_seta := seta.create_tween().set_loops()
	tw_seta.set_trans(Tween.TRANS_SINE)
	tw_seta.tween_property(seta, "position:y", y_base + 0.6, 0.6)
	tw_seta.tween_property(seta, "position:y", y_base, 0.6)
