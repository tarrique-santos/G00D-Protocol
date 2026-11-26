extends Node
## Autoload "Config": carrega o g00d_config.cfg assim que o jogo abre e aplica
## vídeo e áudio em QUALQUER cena (não só na tela de configurações).
##
## Project > Project Settings > Globals (Autoload):
##     Path: res://scripts/config_global.gd    Name: Config
##
## No jogo, leia as opções assim:
##     Config.fator_sensibilidade()   # multiplica a sensibilidade do mouse
##     Config.fator_vertical()        # 1.0 normal, -1.0 invertido
##     Config.mostrar_fps

const ARQUIVO_CONFIG := "user://g00d_config.cfg"

var configuracao := ConfigFile.new()

var sensibilidade: float = 50.0
var inverter_vertical: bool = false
var mostrar_fps: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	criar_bus("Music")
	criar_bus("SFX")

	recarregar()


## Lê o arquivo de novo e aplica tudo. A tela de configurações chama ao salvar.
func recarregar() -> void:
	if configuracao.load(ARQUIVO_CONFIG) != OK:
		configuracao = ConfigFile.new()

	sensibilidade = float(configuracao.get_value("gameplay", "sensibilidade", 50.0))
	inverter_vertical = bool(configuracao.get_value("gameplay", "inverter_vertical", false))
	mostrar_fps = bool(configuracao.get_value("video", "mostrar_fps", false))

	aplicar_video()
	aplicar_audio()

	get_tree().call_group("fps_label", "definir_visivel", mostrar_fps)

	print("[Config] aplicado -> sens: %.0f | invertido: %s | FPS: %s" % [
		sensibilidade, inverter_vertical, mostrar_fps
	])


# ---------------------------------------------------------------- Gameplay

## 1.0 na sensibilidade 50 (padrão). Multiplique pela velocidade da câmera.
func fator_sensibilidade() -> float:
	return sensibilidade / 50.0


func fator_vertical() -> float:
	return -1.0 if inverter_vertical else 1.0


# ---------------------------------------------------------------- Vídeo

func aplicar_video() -> void:
	var largura := int(configuracao.get_value("video", "resolucao", 1920))
	var altura := int(configuracao.get_value("video", "altura", 1080))
	var modo := int(configuracao.get_value("video", "modo", 1))
	var sincronizacao := int(configuracao.get_value("video", "vsync", 1))

	match modo:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(largura, altura))
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	match sincronizacao:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)


# ---------------------------------------------------------------- Áudio

func aplicar_audio() -> void:
	aplicar_volume("Master", float(configuracao.get_value("audio", "geral", 100.0)))
	aplicar_volume("Music", float(configuracao.get_value("audio", "musica", 80.0)))
	aplicar_volume("SFX", float(configuracao.get_value("audio", "efeitos", 100.0)))


func criar_bus(nome: String) -> void:
	if AudioServer.get_bus_index(nome) != -1:
		return

	var indice := AudioServer.bus_count

	AudioServer.add_bus(indice)
	AudioServer.set_bus_name(indice, nome)
	AudioServer.set_bus_send(indice, "Master")


func aplicar_volume(nome: String, valor: float) -> void:
	var indice := AudioServer.get_bus_index(nome)

	if indice == -1:
		return

	if valor <= 0.0:
		AudioServer.set_bus_volume_db(indice, -80.0)
	else:
		AudioServer.set_bus_volume_db(indice, linear_to_db(valor / 100.0))
