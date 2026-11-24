extends Area3D

## Número do checkpoint. O primeiro é 1, o segundo é 2, e assim por diante.
@export var indice: int = 1
@export_group("Holograma")
@export var cor_inativo: Color = Color(0.0, 0.85, 1.0)
@export var cor_ativo: Color = Color(0.2, 1.0, 0.4)
@export var altura_texto: float = 2.2

var texto: Label3D
var coluna: MeshInstance3D
var material_coluna: StandardMaterial3D
var tempo: float = 0.0
var salvo: bool = false
var raiz_holograma: Node3D


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	criar_holograma()

	# Se esse checkpoint já foi pego antes (jogador renasceu aqui), nasce como "salvo"
	if Progresso.indice_checkpoint >= indice:
		salvo = true
		_aplicar_cor(cor_ativo, "SALVO")


func _ao_entrar(corpo: Node3D) -> void:
	if not corpo.is_in_group("player"):
		return

	Progresso.registrar_checkpoint(
		indice,
		global_position,
		corpo.rotation.y
	)

	if salvo:
		return

	salvo = true
	_aplicar_cor(cor_ativo, "SALVO")

	# Pulinho de escala pra dar feedback
	var tween := create_tween()
	texto.scale = Vector3.ONE * 1.6
	tween.tween_property(texto, "scale", Vector3.ONE, 0.3)

func criar_holograma() -> void:
	# Nó independente: não herda a escala nem a rotação do checkpoint
	raiz_holograma = Node3D.new()
	add_child(raiz_holograma)
	raiz_holograma.top_level = true
	raiz_holograma.global_position = global_position

	# Texto flutuante, sempre virado pra câmera
	texto = Label3D.new()
	texto.text = "CHECKPOINT"
	texto.font_size = 64
	texto.pixel_size = 0.005
	texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texto.no_depth_test = false
	texto.shaded = false
	texto.outline_size = 8
	texto.position = Vector3(0, altura_texto, 0)
	raiz_holograma.add_child(texto)

	# Coluna de luz fina
	coluna = MeshInstance3D.new()
	var malha := CylinderMesh.new()
	malha.top_radius = 0.2
	malha.bottom_radius = 0.2
	malha.height = 3.0
	coluna.mesh = malha

	material_coluna = StandardMaterial3D.new()
	material_coluna.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_coluna.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_coluna.cull_mode = BaseMaterial3D.CULL_DISABLED
	coluna.material_override = material_coluna
	coluna.position = Vector3(0, 0.5, 0)
	raiz_holograma.add_child(coluna)

	_aplicar_cor(cor_inativo, "CHECKPOINT")


func _aplicar_cor(cor: Color, mensagem: String) -> void:
	texto.text = mensagem
	texto.modulate = cor
	texto.outline_modulate = Color(cor, 0.35)
	material_coluna.albedo_color = Color(cor, 0.18)


func _process(delta: float) -> void:
	if texto == null:
		return

	# Sobe e desce devagar
	tempo += delta
	texto.position.y = altura_texto + sin(tempo * 2.0) * 0.1
