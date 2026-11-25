extends StaticBody3D

## Quanto cada metade desliza (espaço local da porta). A esquerda vai pra um lado, a direita pro oposto.
@export var deslocamento: Vector3 = Vector3(1.5, 0, 0)
@export var duracao: float = 1.0
@export_group("Estado Inicial")
## A porta já nasce aberta (útil como cenário).
@export var comeca_aberta: bool = false
## Se maior que 0, a porta abre sozinha depois desse tempo (em segundos).
@export var abrir_apos_segundos: float = 0.0
## A porta abre sozinha quando o jogador entra na área de sensor.
@export var abrir_ao_aproximar: bool = false

var aberta: bool = false


func abrir(instantaneo: bool = false) -> void:
	if aberta:
		return

	var esquerda: Node3D = get_node_or_null("PortaEsquerda")
	var direita: Node3D = get_node_or_null("PortaDireita")

	if esquerda == null or direita == null:
		push_error("Porta: não achei PortaEsquerda/PortaDireita como filhos diretos de " + name)
		return

	aberta = true

	var destino_esq: Vector3 = esquerda.position - deslocamento
	var destino_dir: Vector3 = direita.position + deslocamento

	if instantaneo:
		esquerda.position = destino_esq
		direita.position = destino_dir
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(esquerda, "position", destino_esq, duracao)
	tween.tween_property(direita, "position", destino_dir, duracao)

func _ready() -> void:
	if abrir_ao_aproximar:
		var sensor: Area3D = get_node_or_null("Sensor")

		if sensor == null:
			push_error("Porta: abrir_ao_aproximar está ligado, mas não achei um Area3D chamado 'Sensor' em " + name)
		else:
			sensor.body_entered.connect(_ao_entrar_no_sensor)

	if comeca_aberta:
		abrir(true)
		return

	if abrir_apos_segundos > 0.0:
		await get_tree().create_timer(abrir_apos_segundos).timeout
		abrir()
		
func _ao_entrar_no_sensor(corpo: Node3D) -> void:
	if corpo.is_in_group("player"):
		abrir()
