
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
	if jogador == null:
		return

	barra.max_value = jogador.vida_maxima
	barra.value = jogador.vida_atual

	texto_vida.text = str(jogador.vida_atual) + " / " + str(jogador.vida_maxima)


func atualizar_dash() -> void:
	# A barra e o texto do dash são atualizados pelo script do HUD (CanvasLayer).
	# Este script não mexe mais neles, pra não brigar pelo mesmo valor.
	pass
