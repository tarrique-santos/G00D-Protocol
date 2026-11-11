
extends Node3D

@export var valor_cura: int = 25
@export var velocidade_piscar: float = 1.5

@export var luz_minima: float = 0.5
@export var luz_maxima: float = 2.5

@export var tamanho_minimo_aura: float = 1.0
@export var tamanho_maximo_aura: float = 1.15

@onready var area: Area3D = get_node_or_null("Area3D") as Area3D

var luz: OmniLight3D
var aura: MeshInstance3D

var tempo: float = 0.0
var coletada: bool = false

var material_aura: StandardMaterial3D


func _ready():
	# Verificar Area3D
	if area == null:
		push_error("Area3D não encontrada na caixa de cura!")
		set_process(false)
		return

	area.body_entered.connect(_on_area_body_entered)

	# Criar luz automaticamente
	luz = find_child("OmniLight3D", true, false) as OmniLight3D

	if luz == null:
		luz = OmniLight3D.new()
		luz.name = "OmniLight3D"
		add_child(luz)

	# Configurar iluminação
	luz.position.y = 0.8
	luz.light_color = Color(0.55, 0.85, 1.0)
	luz.omni_range = 3.5

	# Criar aura automaticamente
	aura = find_child("Aura", true, false) as MeshInstance3D

	if aura == null:
		aura = MeshInstance3D.new()
		aura.name = "Aura"
		add_child(aura)

	# Criar esfera da aura
	if aura.mesh == null:
		var esfera = SphereMesh.new()
		esfera.radius = 1.0
		esfera.height = 2.0
		aura.mesh = esfera

	aura.position.y = 0.8

	# Criar material da aura
	material_aura = StandardMaterial3D.new()

	material_aura.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_aura.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	material_aura.albedo_color = Color(0.55, 0.9, 1.0, 0.12)

	material_aura.emission_enabled = true
	material_aura.emission = Color(0.4, 0.8, 1.0)
	material_aura.emission_energy_multiplier = 1.2

	aura.material_override = material_aura


func _process(delta):
	if coletada:
		return

	tempo += delta

	# Oscilação entre 0 e 1
	var pulso = (sin(tempo * velocidade_piscar * TAU) + 1.0) / 2.0

	# Intensidade da luz
	luz.light_energy = lerpf(
		luz_minima,
		luz_maxima,
		pulso
	)

	# Tamanho da aura
	var tamanho = lerpf(
		tamanho_minimo_aura,
		tamanho_maximo_aura,
		pulso
	)

	aura.scale = Vector3.ONE * tamanho

	# Transparência da aura
	var transparencia = lerpf(0.05, 0.18, pulso)

	material_aura.albedo_color = Color(
		0.55,
		0.9,
		1.0,
		transparencia
	)

	# Intensidade do brilho
	material_aura.emission_energy_multiplier = lerpf(0.7, 2.0, pulso)


func _on_area_body_entered(body: Node3D):
	if coletada:
		return

	if body.is_in_group("player"):

		if body.has_method("curar"):
			body.curar(valor_cura)

			coletada = true
			queue_free()

		else:
			push_warning("O jogador não possui a função curar()!")
