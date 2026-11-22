
extends Area3D

@export_group("Dano")
@export var dano: int = 10
@export var intervalo_dano: float = 0.5
@export var grupo_alvo: String = "player"
@export var causa_morte: String = "ELETROCUTADO POR UM FIO DESCAPADO"

@export_group("Funcionamento")
@export var ligado: bool = true
@export var intermitente: bool = false
@export var tempo_ligado: float = 1.5
@export var tempo_desligado: float = 1.0

@export_group("Efeitos")
@export var piscar_luz: bool = true
@export var intervalo_som: float = 9.0

@onready var luz: Light3D = get_node_or_null("Luz")
@onready var faiscas: GPUParticles3D = get_node_or_null("Faiscas")
@onready var som: AudioStreamPlayer3D = $CollisionShape3D2/Som

var _tempo_dano: float = 0.0
var _tempo_ciclo: float = 0.0
var _tempo_som: float = 0.0
var _energia_luz: float = 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false

	if luz:
		_energia_luz = luz.light_energy

	_tempo_ciclo = tempo_ligado if ligado else tempo_desligado

	_aplicar_estado()


func _process(delta: float) -> void:
	if intermitente:
		_tempo_ciclo -= delta

		if _tempo_ciclo <= 0.0:
			ligado = not ligado
			_tempo_ciclo = tempo_ligado if ligado else tempo_desligado
			_aplicar_estado()

	if luz and ligado and piscar_luz:
		luz.light_energy = _energia_luz * randf_range(0.4, 1.5)

	if som and ligado:
		_tempo_som += delta

		if _tempo_som >= intervalo_som:
			_tempo_som = 0.0
			som.stop()
			som.play()


func _physics_process(delta: float) -> void:
	_tempo_dano = maxf(_tempo_dano - delta, 0.0)

	if not ligado or _tempo_dano > 0.0:
		return

	for corpo in get_overlapping_bodies():
		if corpo.is_in_group(grupo_alvo) and corpo.has_method("receber_dano"):
			corpo.receber_dano(dano, causa_morte)
			_tempo_dano = intervalo_dano
			break


func _aplicar_estado() -> void:
	if luz:
		luz.visible = ligado

	if faiscas:
		faiscas.emitting = ligado

	if som:
		if ligado:
			_tempo_som = 0.0
			som.play()
		else:
			_tempo_som = 0.0
			som.stop()


func definir_ligado(valor: bool) -> void:
	ligado = valor
	intermitente = false
	_aplicar_estado()
