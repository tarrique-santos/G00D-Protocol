@tool
extends Node3D

@export_group("Dimensoes")
@export var largura: float = 3.0:
	set(valor):
		largura = maxf(valor, 0.1)
		atualizar_vidro()

@export var altura: float = 2.0:
	set(valor):
		altura = maxf(valor, 0.1)
		atualizar_vidro()

@export var espessura: float = 0.08:
	set(valor):
		espessura = maxf(valor, 0.01)
		atualizar_vidro()


@export_group("Aparencia")
@export var cor_vidro: Color = Color(0.1, 0.75, 1.0, 0.22):
	set(valor):
		cor_vidro = valor
		atualizar_vidro()

@export_range(0.0, 1.0) var transparencia: float = 0.22:
	set(valor):
		transparencia = clampf(valor, 0.0, 1.0)
		atualizar_vidro()

@export_range(0.0, 1.0) var metalico: float = 0.35:
	set(valor):
		metalico = clampf(valor, 0.0, 1.0)
		atualizar_vidro()

@export_range(0.0, 1.0) var rugosidade: float = 0.12:
	set(valor):
		rugosidade = clampf(valor, 0.0, 1.0)
		atualizar_vidro()

@export_group("Iluminacao")
@export var brilho: float = 0.4:
	set(valor):
		brilho = maxf(valor, 0.0)
		atualizar_vidro()

@export_group("Colisao")
@export var bloquear_passagem: bool = true:
	set(valor):
		bloquear_passagem = valor
		atualizar_vidro()


func _ready() -> void:
	atualizar_vidro()


func atualizar_vidro() -> void:
	if not is_inside_tree():
		return

	var mesh_instance = get_node_or_null("MeshInstance3D")

	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		mesh_instance.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null

	var malha = BoxMesh.new()
	malha.size = Vector3(largura, altura, espessura)

	mesh_instance.mesh = malha

	var material = StandardMaterial3D.new()

	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(
		cor_vidro.r,
		cor_vidro.g,
		cor_vidro.b,
		transparencia
	)

	material.metallic = metalico
	material.roughness = rugosidade
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	material.emission_enabled = brilho > 0.0
	material.emission = cor_vidro
	material.emission_energy_multiplier = brilho

	mesh_instance.material_override = material

	atualizar_colisao()


func atualizar_colisao() -> void:
	var corpo = get_node_or_null("StaticBody3D")

	if not bloquear_passagem:
		if corpo:
			corpo.queue_free()
		return

	if corpo == null:
		corpo = StaticBody3D.new()
		corpo.name = "StaticBody3D"
		add_child(corpo)
		corpo.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null

	var colisao = corpo.get_node_or_null("CollisionShape3D")

	if colisao == null:
		colisao = CollisionShape3D.new()
		colisao.name = "CollisionShape3D"
		corpo.add_child(colisao)
		colisao.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null

	var forma = BoxShape3D.new()
	forma.size = Vector3(largura, altura, espessura)

	colisao.shape = forma
