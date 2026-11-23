extends Node

signal checkpoint_mudou(indice: int)

var indice_checkpoint: int = 0
var posicao_checkpoint: Vector3 = Vector3.ZERO
var rotacao_checkpoint: float = 0.0


func tem_checkpoint() -> bool:
	return indice_checkpoint > 0


func registrar_checkpoint(indice: int, posicao: Vector3, rotacao: float) -> void:
	if indice <= indice_checkpoint:
		return

	indice_checkpoint = indice
	posicao_checkpoint = posicao
	rotacao_checkpoint = rotacao

	print("Checkpoint ", indice, " salvo!")
	checkpoint_mudou.emit(indice)


func resetar() -> void:
	indice_checkpoint = 0
	posicao_checkpoint = Vector3.ZERO
	rotacao_checkpoint = 0.0
