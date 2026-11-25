extends Node3D
## Caixa de cura: ao ser tocada pelo jogador, cura e some.
## Gera por código uma cruz verde vertical, que pisca, flutuando acima da caixa.

@onready var som: AudioStreamPlayer3D = get_node_or_null("som")

@export var valor_cura: int = 25
@export var velocidade_piscar: float = 1.5

@export_group("Luz")
@export var luz_minima: float = 0.5
@export var luz_maxima: float = 2.5
@export var cor_luz: Color = Color(0.3, 1.0, 0.45)

@export_group("Cruz verde")
@export var cor_cruz: Color = Color(0.2, 1.0, 0.35)
## Largura e altura totais da cruz (em metros).
@export var tamanho_cruz: float = 1.3
## Espessura dos braços da cruz.
@export var espessura_cruz: float = 0.42
## Altura da cruz em relação à caixa.
@export var altura_cruz: float = 3.8
## A cruz cresce e encolhe entre esses dois tamanhos ao piscar.
@export var tamanho_minimo_aura: float = 1.0
@export var tamanho_maximo_aura: float = 1.15
## Transparência da cruz entre apagada e acesa.
@export_range(0.0, 1.0) var alfa_minimo: float = 0.25
@export_range(0.0, 1.0) var alfa_maximo: float = 0.95
## Quanto a cruz sobe e desce, flutuando.
@export var amplitude_flutuacao: float = 0.06
## true = a cruz sempre gira (só na vertical) para ficar de frente para a câmera.
@export var sempre_de_frente_para_camera: bool = true
## Direção fixa da cruz (graus), usada se a opção acima estiver desligada.
@export_range(-180.0, 180.0) var rotacao_cruz_y: float = 0.0

@onready var area: Area3D = get_node_or_null("Area3D") as Area3D

var luz: OmniLight3D
var cruz: Node3D

var tempo: float = 0.0
var coletada: bool = false

var material_cruz: StandardMaterial3D
var material_halo: StandardMaterial3D


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
	luz.position.y = altura_cruz
	luz.light_color = cor_luz
	luz.omni_range = 3.5

	# A aura antiga em esfera (se existir na cena) deixa de ser usada
	var aura_antiga := find_child("Aura", true, false) as Node3D

	if aura_antiga != null:
		aura_antiga.visible = false

	criar_cruz()


# ==========================================
# CRUZ VERDE
# ==========================================

func criar_cruz() -> void:
	cruz = Node3D.new()
	cruz.name = "CruzVerde"
	cruz.position.y = altura_cruz
	add_child(cruz)

	# Cruz principal e um brilho maior e mais fraco atrás dela
	material_cruz = criar_material(1)
	material_halo = criar_material(0)

	montar_cruz(cruz, tamanho_cruz, espessura_cruz, material_cruz, 0.0)
	montar_cruz(cruz, tamanho_cruz * 1.45, espessura_cruz * 1.8, material_halo, -0.01)

	atualizar_cruz()


func criar_material(prioridade: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = prioridade
	material.albedo_color = cor_cruz

	return material


## Monta a cruz com 3 retângulos que não se sobrepõem (a barra horizontal inteira
## e as duas metades da vertical), para a transparência ficar uniforme.
func montar_cruz(
	pai: Node3D,
	tamanho: float,
	espessura: float,
	material: StandardMaterial3D,
	profundidade: float
) -> void:
	var braco := (tamanho - espessura) * 0.5
	var deslocamento := espessura * 0.5 + braco * 0.5

	adicionar_retangulo(
		pai, Vector2(tamanho, espessura),
		Vector3(0.0, 0.0, profundidade), material
	)

	adicionar_retangulo(
		pai, Vector2(espessura, braco),
		Vector3(0.0, deslocamento, profundidade), material
	)

	adicionar_retangulo(
		pai, Vector2(espessura, braco),
		Vector3(0.0, -deslocamento, profundidade), material
	)


func adicionar_retangulo(
	pai: Node3D,
	tamanho: Vector2,
	posicao: Vector3,
	material: StandardMaterial3D
) -> void:
	var malha := MeshInstance3D.new()
	var quadrado := QuadMesh.new()

	quadrado.size = tamanho

	malha.mesh = quadrado
	malha.material_override = material
	malha.position = posicao
	malha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	pai.add_child(malha)


func _process(delta):
	if coletada:
		return

	tempo += delta

	atualizar_cruz()


func atualizar_cruz() -> void:
	# Oscilação entre 0 e 1
	var pulso := (sin(tempo * velocidade_piscar * TAU) + 1.0) / 2.0

	# Intensidade da luz
	luz.light_energy = lerpf(luz_minima, luz_maxima, pulso)

	# Brilho (acima de 1 faz a cruz "estourar" se o Glow estiver ligado) e transparência
	var brilho := lerpf(1.0, 2.2, pulso)
	var alfa := lerpf(alfa_minimo, alfa_maximo, pulso)

	material_cruz.albedo_color = Color(
		cor_cruz.r * brilho,
		cor_cruz.g * brilho,
		cor_cruz.b * brilho,
		alfa
	)

	material_halo.albedo_color = Color(
		cor_cruz.r * brilho,
		cor_cruz.g * brilho,
		cor_cruz.b * brilho,
		alfa * 0.35
	)

	# Tamanho e flutuação
	cruz.scale = Vector3.ONE * lerpf(
		tamanho_minimo_aura,
		tamanho_maximo_aura,
		pulso
	)

	cruz.position.y = altura_cruz + sin(tempo * 1.6) * amplitude_flutuacao

	# Orientação: sempre na vertical, só gira em volta do eixo Y
	if sempre_de_frente_para_camera:
		var camera := get_viewport().get_camera_3d()

		if camera != null:
			var alvo := camera.global_position
			alvo.y = cruz.global_position.y

			if alvo.distance_squared_to(cruz.global_position) > 0.0001:
				# true = usa a frente do modelo (+Z), que é onde a cruz é desenhada
				cruz.look_at(alvo, Vector3.UP, true)
	else:
		cruz.rotation.y = deg_to_rad(rotacao_cruz_y)


# ==========================================
# COLETA
# ==========================================

func _on_area_body_entered(body: Node3D):
	if coletada:
		return

	if body.is_in_group("player"):

		if body.has_method("curar"):
			body.curar(valor_cura)

			coletada = true

			if som:
				som.play()

				# Espera o som terminar antes de remover a caixa.
				await som.finished

			queue_free()

		else:
			push_warning("O jogador não possui a função curar()!")
