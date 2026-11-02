
extends Control

@export var proxima_cena: String = "res://scenes/main.tscn"

var imagens: Array[Texture2D] = []
var quadro_atual: int = 0

@onready var imagem: TextureRect = $Imagem
@onready var indicador: Label = $Indicador
@onready var avancar: Button = $Avancar


func _ready():
	carregar_imagens()

	avancar.pressed.connect(avancar_quadro)

	if imagens.is_empty():
		indicador.text = "Nenhuma imagem encontrada!"
		avancar.disabled = true
		return

	mostrar_quadro()


func carregar_imagens():
	var diretorio = DirAccess.open("res://history/")

	if diretorio == null:
		push_error("Pasta history não encontrada!")
		return

	var arquivos = diretorio.get_files()

	var arquivos_validos: Array[String] = []

	for arquivo in arquivos:
		var nome = arquivo.get_basename()
		var extensao = arquivo.get_extension().to_lower()

		if not nome.begins_with("q"):
			continue

		var numero = nome.trim_prefix("q")

		if not numero.is_valid_int():
			continue

		if extensao not in ["png", "jpg", "jpeg", "webp"]:
			continue

		arquivos_validos.append(arquivo)

	arquivos_validos.sort_custom(func(a, b):
		return int(a.get_basename().trim_prefix("q")) < int(b.get_basename().trim_prefix("q"))
	)

	for arquivo in arquivos_validos:
		var textura = load("res://history/" + arquivo) as Texture2D

		if textura != null:
			imagens.append(textura)


func mostrar_quadro():
	imagem.texture = imagens[quadro_atual]

	indicador.text = "QUADRO %d / %d" % [
		quadro_atual + 1,
		imagens.size()
	]

	if quadro_atual == imagens.size() - 1:
		avancar.text = "INICIAR JOGO >>"
	else:
		avancar.text = "AVANÇAR >>"


func avancar_quadro():
	quadro_atual += 1

	if quadro_atual >= imagens.size():
		get_tree().change_scene_to_file(proxima_cena)
		return

	mostrar_quadro()


func _input(event):
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		if not imagens.is_empty():
			avancar_quadro()
