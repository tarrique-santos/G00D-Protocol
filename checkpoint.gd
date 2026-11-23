extends Area3D

## Número do checkpoint. O primeiro é 1, o segundo é 2, e assim por diante.
@export var indice: int = 1


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node3D) -> void:
	if not corpo.is_in_group("player"):
		return

	Progresso.registrar_checkpoint(
		indice,
		global_position,
		corpo.rotation.y
	)
