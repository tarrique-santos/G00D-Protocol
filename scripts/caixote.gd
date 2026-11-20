
extends MeshInstance3D

@export var vida: float = 50.0

@onready var corpo = $StaticBody3D

var destruido: bool = false


func receber_dano(dano: float) -> void:
	if destruido:
		return

	vida -= dano

	print("Vida do caixote: ", vida)

	if vida <= 0:
		quebrar()


func quebrar() -> void:
	destruido = true

	print("Caixote destruído!")

	queue_free()
