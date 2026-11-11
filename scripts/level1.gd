extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Mensagem.mostrar_mensagem(
	"SETOR DE CONTENÇÃO",
	"ELIMINE TODAS AS AMEAÇAS",
	"Sua nave realizou um pouso de emergência em uma estrutura ocupada por aliens e robôs. Elimine todos os inimigos para continuar sua jornada contra Evil.",
	10.0
)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
