extends Area3D
## Fio descapado: quem estiver dentro da área leva dano elétrico.
##
## Estrutura da cena:
##   FioDescapado (Area3D)          <- este script
##   ├─ CollisionShape3D            <- a área de dano (caixa ou cilindro em volta do fio)
##   ├─ Malha (MeshInstance3D)      <- o visual do fio (opcional)
##   ├─ Faiscas (GPUParticles3D)    <- faíscas (opcional)
##   ├─ Luz (OmniLight3D)           <- brilho que pisca (opcional)
##   └─ Som (AudioStreamPlayer3D)   <- zumbido/choque (opcional)

@export_group("Dano")
@export var dano: int = 10
## Intervalo entre um dano e o próximo enquanto o jogador continua na área.
## (O jogador também tem a própria imunidade, que pode ser maior que isso.)
@export var intervalo_dano: float = 0.5
@export var grupo_alvo: String = "player"
@export var causa_morte: String = "ELETROCUTADO POR UM FIO DESCAPADO"

@export_group("Funcionamento")
@export var ligado: bool = true
## Se ligado, o fio alterna entre ativo e desligado (dá para atravessar sem dano).
@export var intermitente: bool = false
@export var tempo_ligado: float = 1.5
@export var tempo_desligado: float = 1.0

@export_group("Efeitos")
## Faz a luz oscilar enquanto o fio está ligado.
@export var piscar_luz: bool = true

@onready var luz: Light3D = get_node_or_null("Luz")
@onready var faiscas: GPUParticles3D = get_node_or_null("Faiscas")
@onready var som: AudioStreamPlayer3D = get_node_or_null("Som")

var _tempo_dano: float = 0.0
var _tempo_ciclo: float = 0.0
var _energia_luz: float = 1.0


func _ready() -> void:
	# O fio só precisa detectar corpos (o jogador), não ser detectado.
	collision_layer = 0
	collision_mask = 1  # ajuste para a camada do seu jogador, se for outra
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

	# Luz oscilando, como um curto-circuito
	if luz and ligado and piscar_luz:
		luz.light_energy = _energia_luz * randf_range(0.4, 1.5)


func _physics_process(delta: float) -> void:
	_tempo_dano = maxf(_tempo_dano - delta, 0.0)

	if not ligado or _tempo_dano > 0.0:
		return

	for corpo in get_overlapping_bodies():
		if corpo.is_in_group(grupo_alvo) and corpo.has_method("receber_dano"):
			corpo.receber_dano(dano, causa_morte)
			_tempo_dano = intervalo_dano

			if som:
				som.play()

			break


func _aplicar_estado() -> void:
	if luz:
		luz.visible = ligado

	if faiscas:
		faiscas.emitting = ligado

	if not ligado and som:
		som.stop()


## Liga/desliga o fio por outro script (por exemplo, uma alavanca ou um botão).
func definir_ligado(valor: bool) -> void:
	ligado = valor
	intermitente = false
	_aplicar_estado()
