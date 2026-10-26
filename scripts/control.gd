
extends Control

@export var jogador: CharacterBody3D

@onready var barra: ProgressBar = $HPBar
@onready var texto_vida: Label = $HP

@onready var barra_dash: ProgressBar = $BarraDash
@onready var texto_dash: Label = $TextoDash


func _ready() -> void:
	if jogador == null:
		jogador = get_tree().get_first_node_in_group("player")

	atualizar_vida()
	atualizar_dash()


func _process(_delta: float) -> void:
	if jogador != null:
		atualizar_vida()
		atualizar_dash()


func atualizar_vida() -> void:
	barra.max_value = jogador.vida_maxima
	barra.value = jogador.vida_atual

	texto_vida.text = str(jogador.vida_atual) + " / " + str(jogador.vida_maxima)


func atualizar_dash() -> void:
	var maximo: int = jogador.max_dashes_no_ar
	var usados: int = jogador.dashes_usados_no_ar
	var restantes: int = maximo - usados

	barra_dash.max_value = maximo

	if usados > 0 and jogador.is_on_floor():
		var intervalo: float = jogador.tempo_recarga_dash_chao

		if intervalo > 0.0:
			var progresso: float = 1.0 - (
				jogador.tempo_recuperacao_dash / intervalo
			)

			barra_dash.value = restantes + clampf(progresso, 0.0, 1.0)
		else:
			barra_dash.value = restantes
	else:
		barra_dash.value = restantes

	texto_dash.text = str(restantes) + " / " + str(maximo)
