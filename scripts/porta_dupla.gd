extends StaticBody3D

## Quanto cada metade desliza (espaço local da porta). A esquerda vai pra um lado, a direita pro oposto.
@export var deslocamento: Vector3 = Vector3(1.5, 0, 0)
@export var duracao: float = 1.0


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
